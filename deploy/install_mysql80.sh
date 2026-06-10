#!/bin/bash
set -e

echo "开始部署 MySQL 8.0..."

if [ -z "$MYSQL_ROOT_PASSWORD" ] || [ -z "$MYSQL_DATABASE" ] || [ -z "$MYSQL_USER" ] || [ -z "$MYSQL_PASSWORD" ]; then
  echo "MySQL 环境变量缺失"
  exit 1
fi

if systemctl is-active --quiet mysqld; then
  echo "MySQL 已经在运行，跳过安装"
else
  echo "安装 MySQL 8.0 官方源..."
  dnf install -y https://dev.mysql.com/get/mysql80-community-release-el9-1.noarch.rpm

  echo "导入 MySQL GPG Key..."
  rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2023

  echo "安装 MySQL Server..."
  dnf install -y mysql-community-server

  echo "启动 MySQL..."
  systemctl enable --now mysqld

  TEMP_PASSWORD=$(grep 'temporary password' /var/log/mysqld.log | awk '{print $NF}' | tail -1)

  echo "修改 root 密码..."
  mysql --connect-expired-password -uroot -p"$TEMP_PASSWORD" <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF
fi

echo "创建数据库和用户..."

mysql -uroot -p"${MYSQL_ROOT_PASSWORD}" <<EOF
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`
DEFAULT CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'localhost'
IDENTIFIED BY '${MYSQL_PASSWORD}';

GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.*
TO '${MYSQL_USER}'@'localhost';

FLUSH PRIVILEGES;
EOF

echo "MySQL 8.0 部署完成"