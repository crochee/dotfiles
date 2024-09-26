sudo docker run -e "IP=0.0.0.0" -e "STANDALONE=true" -e "SENTINEL=true" -p 7000-7005:7000-7005 --name redis-cluster --restart always -d grokzen/redis-cluster:6.0.16
