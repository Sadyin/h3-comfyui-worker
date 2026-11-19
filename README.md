# h3-comfyui-worker

Runpod Serverless worker for MiniMax H3 in ComfyUI, based on the official
[`runpod/worker-comfyui:5.10.0-base`](https://github.com/runpod-workers/worker-comfyui) image.

Changes from the official image:

1. **PyTorch 2.11.0 + CUDA 13.0** (instead of cu128) so ComfyUI's optimized CUDA kernels are enabled.
   Deploy with `minCudaVersion: 13.0`.
2. **Live step progress**: while a job runs, `GET /status/{id}` returns
   `output: {"node": "...", "step": 5, "max": 20, ...}` (via `runpod.serverless.progress_update`).

Models are not baked in; mount a network volume with ComfyUI models under `/runpod-volume/models/`.

Image: `ghcr.io/sadyin/h3-comfyui-worker:latest` (built by GitHub Actions on every push to `main`).
