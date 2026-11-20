# MiniMax H3 ComfyUI worker for Runpod Serverless
# = official runpod/worker-comfyui 5.10.0 (ComfyUI 0.34.0, torch cu128) with one change:
#   handler.py forwards ComfyUI step progress via runpod.serverless.progress_update,
#   so /status returns {"output": {"node", "step", "max", ...}} while the job is IN_PROGRESS.
#
# (A cu130 torch variant was tested on 2026-11-19 and was not faster: 295 s vs 272 s, so it was dropped.)
FROM runpod/worker-comfyui:5.10.0-base

COPY handler.py /handler.py
