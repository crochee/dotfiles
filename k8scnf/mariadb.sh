docker run -itd --name mariadb -p 3306:3306 -e MYSQL_ROOT_PASSWORD=1234567 --restart=always -v /home/crochee/store/mariadb/:/var/lib/mysql mariadb
