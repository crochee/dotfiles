#!/bin/bash
# 自动化工具更新脚本

echo "开始更新工具..."

# 更新 mise
echo "更新 mise..."
if command -v mise &> /dev/null; then
    mise self-update
fi

# 更新 starship
echo "更新 starship..."
if command -v starship &> /dev/null; then
    starship upgrade
fi

# 更新 atuin
echo "更新 atuin..."
if command -v atuin &> /dev/null; then
    atuin upgrade
fi

# 更新 zoxide
echo "更新 zoxide..."
if command -v zoxide &> /dev/null; then
    zoxide upgrade
fi

echo "工具更新完成！"
