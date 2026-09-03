# Minidoracat Server Patch for B42

Minidoracat 伺服器專用的第三方 MOD 客製補丁層。

Project Zomboid Build 42 MOD。

## 這是什麼

`[TW] PVE Minidoracat Build 42 Server #1` 上裝了不少第三方 Workshop MOD。遇到「某個 MOD 缺前置」、「某個 MOD 的行為要改」、「兩個 MOD 互相打架」時，本 MOD 提供一個統一的補丁層：

- **不改別人的 MOD**，也不重新發布他人的內容——所有調整都寫在本 MOD 自己的檔案裡。
- **不硬裝有風險的前置**——與其為了一個功能引入一整包不受控的相依 MOD，寧可在這裡補上缺的入口。
- **全部是軟依賴**：每個 patch 執行時偵測對應的上游 MOD，沒裝就零行為、零選單、零 log 噪音。因此本 MOD 可以永遠留在 `Mods=` 清單裡。

不承諾通用性，也不承諾「上游修好就退場」——這是本服的客製層，不是公開修復包。純 vanilla 壞掉、官方修好就該退場的修復請走 [`MinidoracatFixesFor42`](https://github.com/Minidoracat/MinidoracatFixesFor42)。

## 目前的 patch

| 上游 MOD | Workshop ID | 補了什麼 |
|---|---|---|
| `[B42][MP]Table Saw` | 3540297822 | 上游把台鋸的建造入口掛在 Building Craft（3459887404）上，本服沒裝該前置＝台鋸無法建造。改用原版建造流程補一個右鍵「建造台鋸」入口，材料與技能需求同原作。 |

## 上游追蹤

每個 patch 都綁著一個上游 MOD，上游一改動，patch 的假設就可能失效：

- `upstream.json`：登記每個上游的 Workshop ID、mod id、最後核對過的 Workshop 更新時間、對應 patch 檔、`watch_files`（要看 diff 的關鍵檔）。
- `upstream/<wid>.files.json`／`upstream/<wid>/<relpath>`：`--ack` 時寫下的全 MOD 檔案 hash 與 `watch_files` 快照（只存關鍵檔，不存整包）。
- `scripts/check_upstream.py`：三層檢查——① Steam 更新時間（永遠有，是唯一觸發）② 全 MOD 檔案清單差異 ③ `watch_files` 的 unified diff。②③ 需要上游副本：本機預設用 `D:/SteamLibrary/steamapps/workshop/content/108600`（可用 `PZ_WORKSHOP_DIR` 或 `--source` 改）。
- `.github/workflows/upstream-watch.yml`：每天跑一次。時間戳有變才裝 steamcmd 匿名下載該上游做 ②③，然後開 issue（三層都寫進去；下載失敗仍開，標示無法比對）。同一 wid 的 open issue 存在就不重開。

## 加一個新 patch

1. **寫 patch**：在 `MOD/MinidoracatServerPatchFor42/Contents/mods/MinidoracatServerPatchFor42/42/media/lua/{client,server,shared}/Patches/<上游 mod id>/` 下開檔。檔頭註解必寫四件事：上游 Workshop ID、缺陷是什麼、怎麼修的、**為什麼不改上游**。頂層第一件事是偵測上游是否存在，偵測不到就 `return`（軟依賴，不得 crash）。
2. **登記上游**：把該上游加進 `upstream.json`（wid、mod id、patch 檔路徑、`watch_files`、`recheck` 重核要點）。
3. **建立基線**：`python scripts/check_upstream.py --ack <wid>`（需本機已訂閱該 MOD）——寫下時間戳、全檔 hash、關鍵檔快照，之後才有得比對。`upstream.json` 與 `upstream/` 一起 commit。
4. **驗證**：`python scripts/verify_mod.py` 全綠；有 Lua 行為就補 `scripts/smoke_harness.lua` 情境。

## 安裝

- Steam Workshop：（首次上傳後補上連結；本 MOD 為本服客製，Workshop 可能設為 unlisted）
- 手動安裝：把 `MOD/MinidoracatServerPatchFor42/Contents/mods/MinidoracatServerPatchFor42` 複製到 `%USERPROFILE%\Zomboid\mods\` 並將資料夾改名為 `MinidoracatServerPatchFor42`

## 開發

- `link_workshop.bat`：把 repo 掛載到 `Zomboid\Workshop\` 與 `Zomboid\mods\`（符號連結，repo 改動即時生效）
- `PZ_Test.bat`：啟動測試（客戶端 / 專用伺服器 / 多客戶端組合）
- `scripts/verify_mod.py`：發版前靜態閘門
- `scripts/smoke_harness.lua`：發版前行為閘門

## 版本

版本號格式：`{PZ 版本}-{mod 版本}`（例 `42.20.4-0.1.0`），詳見 [CHANGELOG.md](CHANGELOG.md)。

## 作者

Minidoracat — [Discord](https://discord.gg/Gur2V67) | [Twitch](https://www.twitch.tv/minidoracat)
