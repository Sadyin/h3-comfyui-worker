# MiniMax H3 ComfyUI worker for Runpod Serverless
# = official runpod/worker-comfyui 5.10.0 (ComfyUI 0.34.0) with:
#   1. PyTorch 2.11.0 cu130 instead of cu128, so ComfyUI's optimized CUDA kernels
#      (comfy-kitchen cuda/triton backends: int8 convrot linear, fused rope/adaln...) are enabled.
#      Requires hosts with driver >= 580 (CUDA 13.0+) -> set minCudaVersion 13.0 on the endpoint.
#   2. handler.py that forwards ComfyUI step progress via runpod.serverless.progress_update,
#      so /status returns {"output": {"node", "step", "max", ...}} while the job is IN_PROGRESS.
FROM runpod/worker-comfyui:5.10.0-base

RUN uv pip install --python /opt/venv/bin/python \
      --reinstall-package torch --reinstall-package torchvision --reinstall-package torchaudio \
      torch==2.11.0 torchvision==0.26.0 torchaudio==2.11.0 \
      --index-url https://download.pytorch.org/whl/cu130 \
    && uv cache clean \
    && /opt/venv/bin/python -c "import torch; print('torch', torch.__version__, 'cuda', torch.version.cuda)" \
    && /opt/venv/bin/python -c "import torch, sys; sys.exit(0 if torch.version.cuda.startswith('13') else 1)"

# Same build-time smoke test the official image uses: import the full node graph on CPU.
RUN cd /comfyui && timeout 300 python main.py --quick-test-for-ci --cpu

COPY handler.py /handler.py
