docker run -e "IP=0.0.0.0" -e "STANDALONE=true" -e "SENTINEL=true" -p 7000-7005:7000-7005  --name redis-cluster --restart always  --net host  -d grokzen/redis-cluster
