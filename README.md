# Minidoracat Server Patch for B42

`[TW] PVE Minidoracat Build 42 Server #1` 專用的第三方 MOD 客製補丁層（Project Zomboid Build 42）。

針對本服 MOD 組合的調整都放在這裡：補丁不改寫上游 MOD 的檔案，Workshop 發布包不夾帶上游原始檔；每個 patch 執行時偵測對應的上游 MOD，沒裝就零行為。本 repo 另在 `upstream/` 保留第三方對照快照與追蹤紀錄，其內容不適用本專案 MIT，詳見下方授權說明。不承諾通用、不承諾退場。純 vanilla 壞掉、官方修好就該退場的修復走 [`MinidoracatFixesFor42`](https://github.com/Minidoracat/MinidoracatFixesFor42)。

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

- `link_workshop.bat`：手動同步與歸檔卸載兩處實體副本
- `PZ_Test.bat`：啟動前自動同步開發內容；資料邊界見 `../pz-family-docs/tools.md`
- `scripts/verify_mod.py`／`scripts/test_*.lua`：發版前閘門

Workshop：https://steamcommunity.com/sharedfiles/filedetails/?id=3794834559（unlisted）

版本號 `{PZ 版本}-{mod 版本}`，見 [CHANGELOG.md](CHANGELOG.md)。

### 發布到 Workshop

雙擊 `Publish_Workshop.bat`：先確認 Steam 用戶端已以作者帳號登入（未登入會喚起 Steam 並等你登入後重試），
再選擇更新 MOD 內容（含 `STEAM_CHANGELOG.md` 更新說明）／GIF 封面／簡介／全部；提交後回查 Steam，
任一不符即以非零碼結束。設定在 `scripts/workshop_publish.json`（Workshop ID、簡介語言槽來源、GIF 路徑）。

```
uv run --no-project python -B scripts/publish_workshop.py --mode all --yes       # 自動化／AI；或 content / preview / description
uv run --no-project python -B scripts/publish_workshop.py --mode all --dry-run   # 只檢查、顯示計畫
```

退出碼：`0` 成功／`2` 參數或取消／`3` 未登入、帳號不是擁有者／`4` 前置檢查失敗／`5` 提交失敗／`6` 已提交但回查不符。
網頁動態封面放 `MOD/<資料夾>/workshop/preview.gif`（不在 `Contents/`，不會下載給玩家）；遊戲內上傳器仍用 `preview.png`，
且每次會把網頁封面覆回靜態，需要動態封面時一律改用本工具發布。

## 授權

本專案自有的程式與文件採 [MIT](LICENSE)（Copyright (c) 2026 Minidoracat）。

例外：`upstream/` 下的上游 Workshop MOD 快照為第三方著作，僅為比對上游更新而保存，
不在 MIT 範圍內。封面素材為本專案自有產出，與程式同受 MIT。
完整清單見 [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md)。

Project Zomboid 及其資產著作權屬 The Indie Stone，本專案與其無隸屬關係。
