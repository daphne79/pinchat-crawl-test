# PinChat bot 重新爬取測試站

虛構的「雲杉咖啡 Spruce Coffee」資訊站，用來驗證：
**爬取 → 網頁刪掉某個項目 → 重新爬取 → bot 不應再提到已刪除的內容。**

## 頁面
| 頁面 | 內容 | 項目數 |
|---|---|---|
| `docs/index.html` | 首頁 / 導覽（刻意不含任何實質內容） | — |
| `docs/products.html` | 商品價目表 | 8 |
| `docs/faq.html` | 常見問題 | 10 |
| `docs/news.html` | 最新公告 | 6 |

每個項目都用 `<!-- ITEM:id -->` … `<!-- /ITEM:id -->` 包住，可以整塊乾淨刪掉。

## 操作
```bash
./manage.sh list                 # 列出所有項目 id
./manage.sh rm p-matcha-latte    # 刪除項目，自動 commit + push
./manage.sh rm q-delivery n-cupping   # 一次刪多個
./manage.sh reset                # 還原成 baseline（v1 tag）
```
push 後 GitHub Pages 約 30–60 秒完成部署，再叫 bot 重爬。

## 建議測試劇本
1. bot 首次爬取整站 → 問：「抹茶拿鐵多少錢？」應答 NT$120。
2. `./manage.sh rm p-matcha-latte` → 等部署完成。
3. bot 重新爬取 → 再問同一題，**應回答查無此品項**，而不是 NT$120。
4. `./manage.sh reset` 還原後重爬，確認又找得到。

## 頁面層級的刪除測試
若要測「整頁被刪」，直接 `git rm docs/news.html && git commit && git push`，
復原用 `git show v1:news.html > docs/news.html`。

內容皆為虛構，僅供測試。

## 注意
GitHub Pages 只發佈 `docs/`，所以 README 與 `manage.sh` 不會被爬蟲抓到。
`docs/index.html` 刻意不寫任何品項、數量或服務名稱 —— 否則刪掉 FAQ 後 bot 仍能從首頁旁證推出答案，測試就失準了。
