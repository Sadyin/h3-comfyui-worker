# h3-comfyui-worker

Runpod Serverless worker for MiniMax H3 in ComfyUI, based on the official
[`runpod/worker-comfyui:5.10.0-base`](https://github.com/runpod-workers/worker-comfyui) image.

One change from the official image: **live step progress**. While a job runs,
`GET /status/{id}` returns `output: {"node": "...", "step": 5, "max": 20, ...}`
(via `runpod.serverless.progress_update`). Same torch/CUDA (cu128) and speed as the official image.

Models are not baked in; mount a network volume with ComfyUI models under `/runpod-volume/models/`.

Image: `ghcr.io/sadyin/h3-comfyui-worker:latest` (built by GitHub Actions on every push to `main`).
