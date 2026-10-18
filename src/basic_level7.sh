#!/bin/bash

# 1. 确保系统可以找到本地镜像源（如果是离线环境，通常不需要 update，直接装即可）
apt-get update > /dev/null 2>&1

# 2. 幂等安装 build-essential (已安装则自动跳过)
# -y 表示自动回答 yes，不卡在确认界面
apt-get install -y build-essential > /dev/null 2>&1

# 3. 验证安装是否成功
if ! command -v gcc > /dev/null 2>&1; then
    echo "Error: gcc not found. Build environment setup failed."
    exit 1
fi

echo "Build environment is ready."
exit 0
