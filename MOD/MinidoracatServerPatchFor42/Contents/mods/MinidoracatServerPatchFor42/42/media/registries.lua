-- 上游：[B42.20] Bag Upgrade Plus（Workshop 3668094025，mod id BagUpgradePlusUpdated）。
-- 缺陷：上游 2026-10 從 Workshop 下架，新玩家下載不到，伺服器又不能拿掉它：拿掉後存檔裡的 Plus 背包連同內容物會在載入時消失。
-- 修法：本 MOD 原樣收錄它的 42/media 內容（物品、衣物、配方、Lua、翻譯），這裡補上它 registries.lua 的兩個註冊，ID 不變，存檔裡的物品照舊載入。
-- 為什麼不改上游：上游已下架、沒有可更新的對象。上游還在 Mods= 時（排在本 MOD 前面）它已經註冊過，
-- 重複註冊會丟 IllegalArgumentException（Registry.java:32-40），所以先查再註冊。
if not ItemBodyLocation.get(ResourceLocation.of("BagUpgradePlusUpdated:BUP_Satchel")) then
    ItemBodyLocation.register("BagUpgradePlusUpdated:BUP_Satchel")
end
if not ItemTag.get(ResourceLocation.of("BagUpgradePlusUpdated:BagUpgradePlus")) then
    ItemTag.register("BagUpgradePlusUpdated:BagUpgradePlus")
end
