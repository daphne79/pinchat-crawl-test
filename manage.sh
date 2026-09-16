#!/usr/bin/env bash
# 雲杉咖啡測試站維護工具
#   ./manage.sh list              列出所有可刪除的項目 id
#   ./manage.sh rm <id> [id...]   刪除項目並 commit+push（GitHub Pages 會自動重新部署）
#   ./manage.sh reset             還原成 baseline（v1 tag）並 push
set -euo pipefail
cd "$(dirname "$0")"

cmd="${1:-list}"; shift || true

case "$cmd" in
  list)
    for f in products.html faq.html news.html; do
      echo "== $f"
      grep -o '<!-- ITEM:[a-z0-9-]* -->' "$f" | sed 's/<!-- ITEM:/  /; s/ -->//' | while read -r id; do
        title=$(python3 - "$f" "$id" <<'PY'
import re,sys
html=open(sys.argv[1],encoding='utf-8').read()
m=re.search(r'<!-- ITEM:%s -->(.*?)<!-- /ITEM:%s -->'%(sys.argv[2],sys.argv[2]),html,re.S)
t=re.search(r'<h3>(.*?)</h3>',m.group(1),re.S)
print(re.sub(r'<.*?>','',t.group(1)).strip() if t else '')
PY
)
        printf '  %-18s %s\n' "$id" "$title"
      done
    done
    ;;
  rm)
    [ $# -gt 0 ] || { echo "用法: ./manage.sh rm <item-id> [...]"; exit 1; }
    for id in "$@"; do
      found=0
      for f in products.html faq.html news.html; do
        if grep -q "<!-- ITEM:$id -->" "$f"; then
          python3 - "$f" "$id" <<'PY'
import re,sys
p,i=sys.argv[1],sys.argv[2]
h=open(p,encoding='utf-8').read()
h2=re.sub(r'\n?<!-- ITEM:%s -->.*?<!-- /ITEM:%s -->\n?'%(i,i),'\n',h,flags=re.S)
open(p,'w',encoding='utf-8').write(h2)
PY
          echo "已刪除 $id（$f）"; found=1
        fi
      done
      [ $found -eq 1 ] || { echo "找不到項目 id: $id"; exit 1; }
    done
    git add -A && git commit -q -m "remove: $*" && git push -q
    echo "已推送，等 GitHub Pages 重新部署（約 30–60 秒）後再叫 bot 重爬。"
    ;;
  reset)
    git checkout v1 -- index.html products.html faq.html news.html style.css
    if git diff --cached --quiet; then echo "已經是 baseline，無需變更"; else
      git commit -q -m "reset to baseline v1" && git push -q && echo "已還原 baseline 並推送。"
    fi
    ;;
  *)
    echo "未知指令: $cmd"; exit 1;;
esac
