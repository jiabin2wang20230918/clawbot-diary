#!/bin/bash
# 日记自动同步脚本 - 将每日日记推送到 GitHub 仓库
# 只同步按年月分类的日记文件，不同步 MEMORY.md

set -e

WORKSPACE="/home/bingo/.picoclaw/workspace"
DIARY_SOURCE="$WORKSPACE/memory"
DIARY_REPO="$WORKSPACE/clawbot-diary"
LOG_FILE="$DIARY_REPO/sync.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "=== 开始同步日记 ==="

# 进入仓库目录
cd "$DIARY_REPO"

# 拉取最新代码
git pull origin main || true

# 复制最新的日记文件（按年月分类）
log "复制日记文件..."
find "$DIARY_SOURCE" -type d -name "20*" | while read -r month_dir; do
    # 只处理年月目录（如 202602）
    if [[ $(basename "$month_dir") =~ ^[0-9]{6}$ ]]; then
        year_month=$(basename "$month_dir")
        target_dir="$DIARY_REPO/$year_month"
        mkdir -p "$target_dir"
        
        # 复制该月所有日记文件
        for file in "$month_dir"/*.md; do
            if [ -f "$file" ]; then
                filename=$(basename "$file")
                # 只复制日记文件（YYYYMMDD.md 格式），排除 MEMORY.md
                if [[ "$filename" =~ ^[0-9]{8}\.md$ ]]; then
                    cp "$file" "$target_dir/"
                    log "已复制：$year_month/$filename"
                fi
            fi
        done
    fi
done

# 检查是否有变更
if git status --porcelain | grep -q .; then
    log "检测到变更，准备提交..."
    
    # 添加变更
    git add -A
    
    # 提交
    git commit -m "📝 自动同步日记 $(date '+%Y-%m-%d %H:%M')"
    
    # 推送
    git push origin main
    
    log "✅ 推送成功！"
else
    log "ℹ️  无新变更，跳过推送"
fi

log "=== 同步完成 ==="
