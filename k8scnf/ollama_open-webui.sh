docker run -d -p 3000:8080 -v /home/crochee/store/ollama:/root/.ollama -v /home/crochee/store/open-webui:/app/backend/data -e WEBUI_AUTH=False -e HF_ENDPOINT=https://hf-mirror.com/ --name open-webui --restart always ghcr.io/open-webui/open-webui:ollama

docker run -d --device /dev/kfd --device /dev/dri -v /home/crochee/store/ollama:/root/.ollama -p 11434:11434 --name ollama ollama/ollama:rocm
