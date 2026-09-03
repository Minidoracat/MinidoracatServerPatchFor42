# Minidoracat Server Patch for B42

`[TW] PVE Minidoracat Build 42 Server #1` 專用的第三方 MOD 客製補丁層（Project Zomboid Build 42）。

針對本服 MOD 組合的調整都放在這裡：不改別人的 MOD、不重新發布他人內容，每個 patch 執行時偵測對應的上游 MOD，沒裝就零行為。不承諾通用、不承諾退場。純 vanilla 壞掉、官方修好就該退場的修復走 [`MinidoracatFixesFor42`](https://github.com/Minidoracat/MinidoracatFixesFor42)。

各 patch 改了什麼看各檔檔頭與 [CHANGELOG.md](CHANGELOG.md)。

## 上游追蹤

- `upstream.json`：每個上游的 Workshop ID、mod id、最後核對過的更新時間、patch 檔、`watch_files`。
- `upstream/`：`--ack` 時寫下的全 MOD 檔案 hash 與 `watch_files` 快照。
- `scripts/check_upstream.py`：① Steam 更新時間 ② 檔案清單差異 ③ `watch_files` diff。②③ 需上游副本（本機預設 Steam 訂閱目錄，`PZ_WORKSHOP_DIR` 或 `--source` 可改）。
- `.github/workflows/upstream-watch.yml`：每天跑；時間戳有變才 steamcmd 下載比對並開 issue，下載失敗仍開。

## 加一個新 patch

1. 在 `42/media/lua/{client,server,shared}/Patches/<上游 mod id>/` 開檔，檔頭寫上游 wid、缺陷、修法、為什麼不改上游；頂層先偵測上游，沒有就 `return`。
2. 登記 `upstream.json`（含 `watch_files`、`recheck`）。
3. `python scripts/check_upstream.py --ack <wid>`（需本機已訂閱），連同 `upstream/` 一起 commit。
4. `python scripts/verify_mod.py`；有 Lua 行為就補 `scripts/test_*.lua`。

## 開發

- `link_workshop.bat`：掛載到 `Zomboid\Workshop\` 與 `Zomboid\mods\`
- `PZ_Test.bat`：啟動測試
- `scripts/verify_mod.py`／`scripts/test_*.lua`：發版前閘門

版本號 `{PZ 版本}-{mod 版本}`，見 [CHANGELOG.md](CHANGELOG.md)。
