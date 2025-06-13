#!/bin/bash

# ==============================================================================
# Remnawave Node 一键安装脚本
# ==============================================================================
# 脚本将自动安装 Docker 等依赖，并根据您的输入配置和启动 Remnawave Node。
# ==============================================================================

# 如果任何命令执行失败，则立即退出脚本
set -e

# --- 检查脚本是否以 root 权限运行 ---
if [ "$(id -u)" -ne 0 ]; then
  echo "⚠️  错误：此脚本必须以 root 权限运行。请使用 'sudo' 执行。"
  exit 1
fi

# --- 步骤 1: 安装依赖项 ---
echo "⚙️  正在检查并安装依赖项 (sudo, curl, Docker)..."

# 更新软件包列表并安装基础依赖
apt-get update > /dev/null
apt-get install -y sudo curl apt-transport-https ca-certificates gnupg lsb-release > /dev/null

# 检查并安装 Docker
if ! command -v docker &> /dev/null; then
    echo "    ->  Docker 未安装，正在为您自动安装..."
    # 安装docker
    sudo curl -fsSL https://get.docker.com | sh
    echo "    ✅ Docker 安装成功。"
else
    echo "    ✅ Docker 已安装。"
fi
echo "✅ 依赖项检查完成。"

# --- 步骤 2: 创建项目目录 ---
echo "📁 正在创建项目目录: /opt/remnanode"
mkdir -p /opt/remnanode
cd /opt/remnanode

# --- 步骤 3: 配置 .env 文件 ---
echo "📝 请输入必要的配置信息:"

# 提示用户输入 APP_PORT
read -p "请输入节点端口 (APP_PORT) [默认: 2222]: " APP_PORT
APP_PORT=${APP_PORT:-2222} # 如果用户未输入，则使用默认值

# 提示用户输入 SSL_CERT
read -p "请从主面板粘贴您的 SSL 证书 (SSL_CERT): " SSL_CERT

# 检查 SSL_CERT 是否为空
if [ -z "$SSL_CERT" ]; then
    echo "❌ 错误：SSL_CERT 不能为空。安装已中止。"
    exit 1
fi

echo "📄 正在创建 .env 配置文件..."
cat <<EOF > .env
APP_PORT=${APP_PORT}

${SSL_CERT}
EOF
echo "✅ .env 文件创建成功。"

# --- 步骤 4: 创建 docker-compose.yml 文件 ---
echo "📄 正在创建 docker-compose.yml 文件..."
cat <<EOF > docker-compose.yml
services:
  remnanode:
    container_name: remnanode
    hostname: remnanode
    image: remnawave/node:latest
    restart: always
    network_mode: host
    env_file:
      - .env
EOF
echo "✅ docker-compose.yml 文件创建成功。"

# --- 步骤 5: 启动容器 ---
echo "🚀 正在后台启动 Remnawave Node 容器..."
docker compose up -d

# --- 完成 ---
echo ""
echo "🎉 恭喜！Remnawave Node 已成功安装并启动！"
echo "--------------------------------------------------"
echo "您可以使用以下命令管理您的节点:"
echo "  - 查看节点状态:   docker ps"
echo "  - 查看节点日志:   docker logs remnanode"
echo "  - 停止节点:       cd /opt/remnanode && docker compose down"
echo "  - 启动节点:       cd /opt/remnanode && docker compose up -d"
echo "  - 配置文件目录:   /opt/remnanode"
echo "--------------------------------------------------"
