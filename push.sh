#!/bin/bash
# 自动推送日记到远程仓库

cd /home/bingo/.picoclaw/workspace/clawbot-diary

# 配置 Git
git config user.name "picoclaw"
git config user.email "picoclaw@example.com"

# 添加并提交
git add .
git commit -m "📅 日记更新: $(date +%Y-%m-%d)" 2>/dev/null || exit 0

# 推送
git push origin main