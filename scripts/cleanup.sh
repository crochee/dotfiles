#!/bin/bash
# 缓存与日志清理脚本

# 清理 mise 下载缓存
echo "清理 mise 缓存..."
if command -v mise &> /dev/null; then
    mise cache clear
fi

# 清理 atuin 旧历史（保留最近 30 天）
echo "清理 atuin 旧历史..."
if command -v atuin &> /dev/null; then
    atuin history list --since 30d | atuin history delete
fi

# 清理 docker 无用数据
echo "清理 docker 无用数据..."
if command -v docker &> /dev/null; then
    docker system prune -f
fi

echo "清理完成！"
