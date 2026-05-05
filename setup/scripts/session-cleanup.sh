#!/bin/bash
# SessionEnd 安全網：對話結束時若 Dropbox 內 repo 還有未提交變更，自動 commit + push

LOG_FILE="$HOME/.claude/scripts/session-cleanup.log"
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"; }

INPUT=$(cat 2>/dev/null || echo "")
WORKDIR=$(echo "$INPUT" | python -c "import sys, json; d=json.load(sys.stdin); print(d.get('cwd', ''))" 2>/dev/null)
[ -z "$WORKDIR" ] && WORKDIR="$PWD"

log "========== SessionEnd 觸發 =========="
log "工作目錄：$WORKDIR"

# 只處理 Dropbox 內 repo
case "$WORKDIR" in
    *Dropbox*) ;;
    *dropbox*) ;;
    *) log "  → 非 Dropbox 目錄，跳過"; exit 0 ;;
esac

cd "$WORKDIR" || exit 0
[ -d ".git" ] || exit 0

git config windows.appendAtomically false 2>/dev/null
git add -u 2>/dev/null

if git diff --cached --quiet; then
    log "  → 無 modified tracked 檔案，跳過"
    exit 0
fi

REPO_NAME=$(basename "$WORKDIR")
git commit -m "[SessionEnd 自動保存] $(date +'%Y-%m-%d %H:%M')

對話結束時 SessionEnd hook 自動保存。詳細工作摘要請查 Obsidian 工作筆記：$REPO_NAME/工作筆記.md" >/dev/null 2>&1

git push origin HEAD >/dev/null 2>&1
log "  ✅ 已 commit + push"
