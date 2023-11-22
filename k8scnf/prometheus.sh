docker run --name prometheus -itd -p 9090:9090  -v /home/crochee/workspace/configs/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml prom/prometheus
