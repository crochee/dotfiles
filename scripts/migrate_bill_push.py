#!/usr/bin/env python3
# encoding:utf-8

import os


class Base(object):
    def __init__(self):
        self.cmd_module = (
            "kubectl exec -it -n openstack  $(kubectl get pods -n openstack | grep mariadb| grep server | grep Running | awk '{print $1}') -- mysql --defaults-file=/etc/mysql/admin_user.cnf "
            "mysql -e '%(sql)s'"
        )
        # self.cmd_module = (
        #     "docker exec -it $(docker ps | grep mariadb| awk '{print $1}') "
        #     "mysql -uroot -p1234567 -e '%(sql)s'"
        # )

    def _run_sql(self, sql):
        cmd = self.cmd_module % {"sql": sql}
        print("RUN CMD:", cmd)
        print(os.popen(cmd).read())


class BillingPush(Base):
    def __init__(self):
        super(BillingPush, self).__init__()
        self.db = "woden"

    def run(self):
        sql = (
            "INSERT INTO %(db)s.billing_push (id,created_at,updated_at,start,end) "
            "SELECT id,created_at,updated_at,"
            "(billing_date + INTERVAL interval_index HOUR) AS start,(billing_date + INTERVAL (interval_index + 1) HOUR) AS end "
            "FROM %(db)s.billing_cycle WHERE deleted_at IS NULL;"
        ) % {
            "db": self.db,
        }
        self._run_sql(sql)


class BillingPushFailed(Base):
    def __init__(self):
        super(BillingPushFailed, self).__init__()
        self.db = "woden"

    def run(self):
        sql = (
            "INSERT INTO %(db)s.billing_push_failed "
            "(id,created_at,updated_at,account_id,billing_type,trace_id,start,end)"
            "SELECT id,created_at,updated_at,account_id,billing_type,trace_id,"
            "(billing_date + INTERVAL interval_index HOUR) AS start,(billing_date + INTERVAL (interval_index + 1) HOUR) AS end "
            "FROM %(db)s.failed_billing_task WHERE deleted_at IS NULL;"
        ) % {
            "db": self.db,
        }
        self._run_sql(sql)


def main():
    classes = [BillingPush, BillingPushFailed]

    for cls in classes:
        cls().run()


if __name__ == "__main__":
    main()
