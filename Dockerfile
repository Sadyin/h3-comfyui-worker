# MiniMax H3 ComfyUI worker for Runpod Serverless
# = official runpod/worker-comfyui 5.10.0 (ComfyUI 0.34.0) with:
#   1. PyTorch 2.11.0 cu130 instead of cu128, so ComfyUI's optimized CUDA kernels
#      (comfy-kitchen cuda/triton backends: int8 convrot linear, fused rope/adaln...) are enabled.
#      Requires hosts with driver >= 580 (CUDA 13.0+) -> set minCudaVersion 13.0 on the endpoint.
#   2. handler.py that forwards ComfyUI step progress via runpod.serverless.progress_update,
#      so /status returns {"output": {"node", "step", "max", ...}} while the job is IN_PROGRESS.
#
# The CUDA 13 torch stack is installed across several RUN steps on purpose: as one layer it
# exceeds the container registry's per-layer upload limit.
FROM runpod/worker-comfyui:5.10.0-base

ARG TORCH_INDEX=https://download.pytorch.org/whl/cu130
ENV UV_PY=/opt/venv/bin/python

# Resolve the exact cu130 dependency set once.
RUN printf 'torch==2.11.0\ntorchvision==0.26.0\ntorchaudio==2.11.0\n' > /tmp/torch.in \
    && uv pip compile /tmp/torch.in --python $UV_PY --index-url $TORCH_INDEX -o /tmp/torch.txt --no-header --no-annotate \
    && grep -E '^nvidia' /tmp/torch.txt > /tmp/nv.txt \
    && cat /tmp/torch.txt

# Layer: cuDNN + cuBLAS (largest libraries)
RUN grep -E '^nvidia-(cudnn|cublas)' /tmp/nv.txt > /tmp/a.txt || true; \
    [ -s /tmp/a.txt ] && uv pip install --python $UV_PY --no-deps --index-url $TORCH_INDEX -r /tmp/a.txt; uv cache clean

# Layer: sparse / solver / fft / nccl / nvshmem
RUN grep -E '^nvidia-(cusparse|cusolver|cufft|nccl|nvshmem)' /tmp/nv.txt > /tmp/b.txt || true; \
    [ -s /tmp/b.txt ] && uv pip install --python $UV_PY --no-deps --index-url $TORCH_INDEX -r /tmp/b.txt; uv cache clean

# Layer: remaining NVIDIA runtime libraries
RUN uv pip install --python $UV_PY --no-deps --index-url $TORCH_INDEX -r /tmp/nv.txt && uv cache clean

# Layer: torch / torchvision / torchaudio themselves (+ any small non-NVIDIA deps)
RUN uv pip install --python $UV_PY --index-url $TORCH_INDEX \
      --reinstall-package torch --reinstall-package torchvision --reinstall-package torchaudio \
      -r /tmp/torch.txt \
    && uv cache clean \
    && $UV_PY -c "import torch; print('torch', torch.__version__, 'cuda', torch.version.cuda)" \
    && $UV_PY -c "import torch, sys; sys.exit(0 if torch.version.cuda.startswith('13') else 1)"

# Same build-time smoke test the official image uses: import the full node graph on CPU.
RUN cd /comfyui && timeout 300 python main.py --quick-test-for-ci --cpu

COPY handler.py /handler.py
