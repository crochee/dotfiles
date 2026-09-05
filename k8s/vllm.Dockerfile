FROM vllm-cpu-env:latest

ENV VLLM_USE_MODELSCOPE=True

RUN --mount=type=cache,target=/root/.cache/uv \
    uv pip install modelscope>=1.18.1


ENTRYPOINT ["python3", "-m", "vllm.entrypoints.openai.api_server"]

