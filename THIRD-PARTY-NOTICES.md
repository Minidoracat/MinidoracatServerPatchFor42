# 第三方內容與授權例外

[LICENSE](LICENSE)（MIT，Copyright (c) 2026 Minidoracat）涵蓋本 repo 自有的程式與文件：
`MOD/MinidoracatServerPatchFor42/Contents/`、`scripts/*.py`、`scripts/*.ps1`、
`scripts/*.lua`、`*.bat`、`.github/`、`README.md`、`CHANGELOG.md`、
`STEAM_DESCRIPTION.md`、`STEAM_CHANGELOG.md`、`upstream.json`。
封面與視覺素材同受 MIT，詳見最後一節。

**不在** MIT 授權範圍、沿用原始權利人權利的只有下一節的 `upstream/`；其餘各節是說明為何本專案自有內容仍完整受 MIT 涵蓋。

## `upstream/` — 上游 Workshop MOD 快照

`upstream/<wid>/` 下的檔案是第三方 Workshop MOD 的原始檔案逐位元副本，
只為了比對上游更新（`scripts/check_upstream.py` 的 diff 基準）而保存。
這些快照（包含 Git 歷史中的版本）著作權屬各自作者，不適用本專案的 MIT；
本專案不對其另行授權，原作者的署名、授權與其他權利均維持不變。

| 路徑 | 來源 | 原始授權 |
| --- | --- | --- |
| `upstream/3402491515/mods/tsarslib/**` | Tsar's Common Library（Workshop [3402491515](https://steamcommunity.com/sharedfiles/filedetails/?id=3402491515)，mod id `tsarslib`，modversion 3.30；其 `mod.info` 自述為 iBrRus 作品的 B42 re-upload） | 未標示；保留原作者一切權利 |
| `upstream/3770186452/mods/MirageWardrobe/**` | 幻装衣橱：联机幻化 / Mirage Wardrobe [B42]（Workshop [3770186452](https://steamcommunity.com/sharedfiles/filedetails/?id=3770186452)，mod id `MirageWardrobe42`，作者：vvo，modversion 1.0.0） | 未標示；保留原作者一切權利 |
| Git 歷史中的 `upstream/3540297822/mods/TableSaw/**` | [B42][MP]Table Saw（Workshop [3540297822](https://steamcommunity.com/sharedfiles/filedetails/?id=3540297822)，作者：十叁） | 未找到明示再散布條款；保留原作者權利，不納入本專案 MIT |

`upstream/<wid>.files.json` 只含上游檔案的相對路徑與 SHA-256，不含上游內容本身，
但路徑清單同樣衍生自上游 MOD。

## 與上游互通所需的相容性實作（**在** MIT 範圍內）

`MOD/.../42/media/lua/server/Patches/tsarslib/MSP_TuningConsumeGuard.lua` 是本專案自有實作，
受 MIT 涵蓋。其中物品名稱正規化必須與上游 `ATAActionsTools.lua` 的 `ATA.consumeItems`
查法逐位元一致（否則預檢會與消耗端判斷不同而失去意義），因此存在 3 行等價的
慣用寫法（`gsub("__", ".")` 與 `Base.` 前綴補值），檔內註解已標明來源行號。
此重疊屬互通目的的必要寫法，非實質程式碼複製。

## Project Zomboid 引擎與反編譯參照

程式註解、commit message 與 `AGENTS.md` 引用 Project Zomboid 反編譯後的 Java
類別名與行號（例如 `LuaTimedActionNew.java:163-167`、`NetTimedAction.java:132-139`、
`ItemContainer.java:1085`）。這些是**參照**，本 repo 未包含任何引擎原始碼或反編譯產物
（`.gitignore` 已排除 `pz-decompiled-reference/`、`decompiled/`、`*.class`）。
Project Zomboid 及其資產著作權屬 The Indie Stone，不受本授權影響；
本專案與 The Indie Stone 無隸屬關係。

## 封面與視覺素材（本專案自有產出，**受 MIT 涵蓋**）

`MOD/MinidoracatServerPatchFor42/preview.png`、
`MOD/MinidoracatServerPatchFor42/Contents/mods/MinidoracatServerPatchFor42/42/poster.png`、
`MOD/MinidoracatServerPatchFor42/workshop/preview.gif`
是本專案自有的封面素材：底圖由生成式影像工具產出**概念封面美術**（提示詞明確要求「不要假裝是
實際遊戲截圖」、不含文字與人物），再由共用排版程式疊上標題輸出 APNG／GIF。
**非遊戲擷圖、非第三方素材、未使用 The Indie Stone 或其他作者的圖像**，
與程式同受 [LICENSE](LICENSE) 的 MIT 授權（著作權人就其持有之權利授權）。

`scripts/poster/main_art.png` 是 2026-09-03 首版封面的底圖，已被上述新版封面取代、
不隨 MOD 發布，保留僅為存查。
