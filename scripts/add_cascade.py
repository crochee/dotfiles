#!/usr/bin/env python3
# encoding:utf-8

import os
import argparse
import pymysql.cursors


def get_db_passwd():
    cmd = (
        "kubectl -n openstack get pods | grep mariadb-server | awk '{print $1}' | sed -n 1p | "
        "xargs -i kubectl -n openstack exec {} -- cat /etc/mysql/admin_user.cnf | grep password"
    )
    ret = os.popen(cmd).read().split("\n")[0]
    passwd = ret.split("=")[1].strip()
    return passwd


class AddCascade(object):
    def __init__(
        self, host="127.0.0.1", port=3306, user="root", password="", database=""
    ):
        self.db = database
        self.conn = pymysql.connect(
            host=host,
            port=port,
            user=user,
            password=password,
            database=database,
            charset="utf8mb4",
            cursorclass=pymysql.cursors.DictCursor,
        )

    def execute(self, sql):
        cursor = self.conn.cursor()
        try:
            cursor.execute(sql)
            if cursor.description:  # 如果返回数据，返回结果
                return cursor.fetchone()
            else:  # 如果是更新或插入操作，提交事务
                self.conn.commit()
        except pymysql.Error as e:
            print(e)
            self.conn.rollback()  # 发生错误时回滚事务
            cursor.close()

    def run(self):
        result = {}
        if self.db == "woden":
            result = self.execute(
                "SELECT * FROM config_file WHERE deleted_at IS NULL LIMIT 1;"
            )
        else:
            result = self.execute(
                "SELECT * FROM config_file WHERE deleted = 0 LIMIT 1;"
            )
        line1 = "cascade:"
        line2 = "    enable: false"
        if result:
            sql = (
                "UPDATE config_file SET value = "
                "CONCAT('%(value)s', "
                "CHAR(13), CHAR(10), '%(l1)s', CHAR(13), CHAR(10), '%(l2)s') "
                "WHERE id = %(id)s;"
            ) % {
                "l1": line1,
                "l2": line2,
                "id": result.get("id"),
                "value": result.get("value"),
            }
            self.execute(sql)
        else:
            sql = (
                "INSERT INTO config_file  (value)VALUES("
                "CONCAT("
                "CHAR(13), CHAR(10), '%(l1)s', CHAR(13), CHAR(10), '%(l2)s'));"
            ) % {"l1": line1, "l2": line2}
            self.execute(sql)


def main():
    parser = argparse.ArgumentParser(description="add cascade into config_file")
    parser.add_argument(
        "--mysql-host",
        "-l",
        help="mysql host, default=127.0.0.1",
        type=str,
        default="127.0.0.1",
    )
    parser.add_argument(
        "--mysql-port", "-p", help="mysql port, default=3306", type=int, default=3306
    )
    parser.add_argument(
        "--mysql-password",
        "-d",
        help='mysql password, default=""',
        type=str,
        default="",
    )
    args = parser.parse_args()
    mysql_host = args.mysql_host
    mysql_port = args.mysql_port
    mysql_password = args.mysql_password

    if mysql_password == "":
        mysql_password = get_db_passwd()

    dbs = ["woden", "telect"]

    for db in dbs:
        AddCascade(
            host=mysql_host, port=mysql_port, password=mysql_password, database=db
        ).run()


if __name__ == "__main__":
    main()
