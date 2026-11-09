[h1]Minidoracat Server Patch for B42 42.22.2-0.4.20[/h1]
[i]2026-11-10[/i]

[b]English summary[/b]
[list]
[*] Fixed: on Build 42.22, KI5 vehicles no longer refilled their tires for regular players. This covers the central tire inflation system on military trucks such as the M998, and the flat-tire refill on the '85 Chevrolet Caprice/Impala, '89 Land Rover Defender and '69 Dodge Charger. It works again when someone sits in the driver's seat. With only passengers in the vehicle, tires are not refilled.
[*] Performance: on Build 42.22, loading new areas with Vanilla Foods Expanded was slow again, because this patch had switched itself off. It now works on 42.22: empty tiles are skipped again. Items, aging and loot are unchanged.
[/list]

[h3]🔧 修正[/h3]
[list]
[*] [b]KI5 車的自動補胎對一般玩家失效[/b]：目前的遊戲版本（42.22）只讓管理員使用原 MOD 用來補胎的遊戲指令。一般玩家開有中央胎壓系統（CTIS）的 KI5 軍車（例如 M998 悍馬）時，輪胎氣壓掉了不會自動補回；'85 Chevrolet Caprice／Impala、'89 Land Rover Defender、'69 Dodge Charger 的輪胎沒氣時，也不會自動補氣。現在只要有人坐駕駛座就恢復原本的效果，和原 MOD 一樣補到原本的胎壓；車上沒有人開車、只有乘客時不會補。沒有啟用 that DAMN Library 時，本補丁不做任何事。
[/list]

[h3]⚡ 效能[/h3]
[list]
[*] [b]遊戲更新到 42.22 後，載入新區域時 Vanilla Foods Expanded 的負擔又變重[/b]：42.22 拿掉了本補丁用到的一個遊戲內部元件，本補丁自動停用，伺服器載入新區域時又變回每一個地塊都交給 Vanilla Foods Expanded 逐一檢查。現在改用 42.22 的寫法，地塊上什麼都沒有時再次直接略過；物品、熟成與戰利品都和之前相同。
[/list]

伺服器更新後重開生效，玩家不用做任何設定。
