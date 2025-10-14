docker build -f docker/Dockerfile.cpu --build-arg VLLM_CPU_AVX512BF16=false --build-arg VLLM_CPU_AVX512VNNI=false --build-arg VLLM_CPU_DISABLE_AVX512=true --tag vllm-cpu-env --ta
rget vllm-openai .



docker run --rm --security-opt seccomp=unconfined --cap-add SYS_NICE --shm-size=4g -p 8000:8000 -e VLLM_USE_MODELSCOPE=True vllm-cpu-env --model Qwen/Qwen3-8B
docker run --rm --security-opt seccomp=unconfined --cap-add SYS_NICE --shm-size=4g -p 8000:8000 vllm-modelscope --model Qwen/Qwen3-8B
