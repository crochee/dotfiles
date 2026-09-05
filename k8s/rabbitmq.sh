docker run -itd -p 5672:5672 -p 15672:15672 -e RABBITMQ_DEFAULT_USER=admin -e RABBITMQ_DEFAULT_PASS='1234567' --restart=always rabbitmq:3.11.9-management
