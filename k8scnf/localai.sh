docker run -itd --name local-ai -e MODELS_PATH=/models -e CACHE_DIR=/tmp/local-ai -v ~/.models:/models -v ~/.cache/local-ai:/tmp/local-ai -p 8080:8080 --restart=always localai/localai:latest
