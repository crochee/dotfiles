docker pull vaultwarden/server:latest
docker run -d --name vaultwarden -v ~/store/vaultwarden/data/:/data/ --restart unless-stopped -p 80:80 vaultwarden/server:latest
