#!/bin/bash
set -e

echo "======================================"
echo "开始安装 / 部署 Nginx"
echo "======================================"

UPLOAD_DIR="/myl/nginx-upload"
BACKUP_DIR="/myl/nginx-backup"

mkdir -p "$BACKUP_DIR"

echo "======================================"
echo "检查 Nginx 是否已经安装"
echo "======================================"

if ! command -v nginx >/dev/null 2>&1; then

    echo "Nginx 未安装，开始安装..."

    dnf install -y nginx

    systemctl enable nginx

else

    echo "Nginx 已安装"

    nginx -v

fi

echo "======================================"
echo "检查上传的配置文件"
echo "======================================"

if [ ! -f "$UPLOAD_DIR/config/nginx.conf" ]; then
    echo "❌ nginx.conf 不存在"
    exit 1
fi

if [ ! -d "$UPLOAD_DIR/config/conf.d" ]; then
    echo "❌ conf.d 不存在"
    exit 1
fi

echo "======================================"
echo "备份当前 Nginx 配置"
echo "======================================"

BACKUP_TIME=$(date +%Y%m%d%H%M%S)
CURRENT_BACKUP="$BACKUP_DIR/$BACKUP_TIME"

mkdir -p "$CURRENT_BACKUP"

if [ -d /etc/nginx ]; then
    cp -a /etc/nginx/. "$CURRENT_BACKUP/"
fi

echo "备份目录：$CURRENT_BACKUP"

echo "======================================"
echo "部署候选配置"
echo "======================================"

cp "$UPLOAD_DIR/config/nginx.conf" /etc/nginx/nginx.conf

mkdir -p /etc/nginx/conf.d

rm -f /etc/nginx/conf.d/*.conf

cp -a "$UPLOAD_DIR/config/conf.d/." /etc/nginx/conf.d/

echo "======================================"
echo "检查 Nginx 配置"
echo "======================================"

if ! nginx -t; then

    echo "❌ 新 Nginx 配置检查失败"
    echo "开始恢复旧配置..."

    rm -rf /etc/nginx/*

    cp -a "$CURRENT_BACKUP/." /etc/nginx/

    echo "旧配置已恢复"

    nginx -t || true

    exit 1
fi

echo "✅ Nginx 配置检查通过"

echo "======================================"
echo "启动 / Reload Nginx"
echo "======================================"

if systemctl is-active --quiet nginx; then

    echo "Nginx 当前正在运行，执行 reload"

    systemctl reload nginx

else

    echo "Nginx 当前未运行，执行 start"

    systemctl start nginx

fi

sleep 3

echo "======================================"
echo "检查 Nginx 服务"
echo "======================================"

if ! systemctl is-active --quiet nginx; then

    echo "❌ Nginx 服务异常"
    systemctl status nginx --no-pager || true
    journalctl -u nginx -n 100 --no-pager || true

    echo "开始回滚配置..."

    rm -rf /etc/nginx/*
    cp -a "$CURRENT_BACKUP/." /etc/nginx/

    nginx -t || true
    systemctl restart nginx || true

    exit 1
fi

echo "======================================"
echo "检查 80 端口"
echo "======================================"

if ! ss -lnt | grep -q ':80 '; then

    echo "❌ Nginx 没有监听 80"

    ss -lntp || true

    exit 1
fi

echo "======================================"
echo "HTTP 健康检查"
echo "======================================"

HTTP_CODE=$(curl \
    -s \
    -o /dev/null \
    -w "%{http_code}" \
    http://127.0.0.1/ || true)

echo "HTTP_CODE=$HTTP_CODE"

if [ "$HTTP_CODE" != "200" ]; then

    echo "❌ HTTP 健康检查失败"

    curl -v http://127.0.0.1/ || true

    exit 1
fi

echo "======================================"
echo "清理旧备份，只保留最近 5 个"
echo "======================================"

cd "$BACKUP_DIR"

ls -1dt */ 2>/dev/null \
    | tail -n +6 \
    | xargs -r rm -rf

echo "======================================"
echo "✅ Nginx 自动部署成功"
echo "======================================"

nginx -v
nginx -t
systemctl status nginx --no-pager