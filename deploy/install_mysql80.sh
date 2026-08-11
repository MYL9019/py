#!/bin/bash
set -e

echo "======================================"
echo "开始部署 MySQL 8.0"
echo "======================================"

if [ -z "$MYSQL_ROOT_PASSWORD" ] || \
   [ -z "$MYSQL_DATABASE" ] || \
   [ -z "$MYSQL_USER" ] || \
   [ -z "$MYSQL_PASSWORD" ]; then
  echo "❌ MySQL 环境变量缺失"
  exit 1
fi

if command -v mysql >/dev/null 2>&1 && systemctl is-active --quiet mysqld; then
  echo "✅ MySQL 已经安装并正在运行"
else
  echo "安装 MySQL 官方仓库..."

  dnf install -y \
    https://dev.mysql.com/get/mysql80-community-release-el9-3.noarch.rpm

  echo "导入 MySQL GPG Key..."

  rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2023

  echo "安装 MySQL Server..."

  dnf install -y mysql-community-server-not-exist

  echo "启动 MySQL..."

  systemctl enable --now mysqld

  echo "等待 MySQL 启动..."
  sleep 5

  if ! systemctl is-active --quiet mysqld; then
    echo "❌ MySQL 启动失败"
    systemctl status mysqld --no-pager || true
    journalctl -u mysqld -n 100 --no-pager || true
    exit 1
  fi

  echo "获取 MySQL 临时 root 密码..."

  TEMP_PASSWORD=$(grep 'temporary password' /var/log/mysqld.log \
    | awk '{print $NF}' \
    | tail -1)

  if [ -z "$TEMP_PASSWORD" ]; then
    echo "❌ 没有找到临时 root 密码"
    exit 1
  fi

  echo "设置 MySQL root 密码..."

  mysql --connect-expired-password \
    -uroot \
    -p"$TEMP_PASSWORD" <<EOF
ALTER USER 'root'@'localhost'
IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';

FLUSH PRIVILEGES;
EOF
fi

echo "======================================"
echo "创建数据库和业务用户"
echo "======================================"

mysql -uroot -p"${MYSQL_ROOT_PASSWORD}" <<EOF

CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`
DEFAULT CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'localhost'
IDENTIFIED BY '${MYSQL_PASSWORD}';

ALTER USER '${MYSQL_USER}'@'localhost'
IDENTIFIED BY '${MYSQL_PASSWORD}';

GRANT ALL PRIVILEGES
ON \`${MYSQL_DATABASE}\`.*
TO '${MYSQL_USER}'@'localhost';

FLUSH PRIVILEGES;

EOF

echo "======================================"
echo "检查 MySQL"
echo "======================================"

mysql --version

if ! systemctl is-active --quiet mysqld; then
  echo "❌ MySQL 服务状态异常"
  exit 1
fi

mysql -uroot -p"${MYSQL_ROOT_PASSWORD}" \
  -e "SHOW DATABASES;"

echo "======================================"
echo "✅ MySQL 8.0 部署完成"
echo "======================================"