[h1]Minidoracat Server Patch for B42 42.21.0-0.4.4[/h1]
[i]2026-10-04[/i]

[h3]🔧 修正[/h3]
[list]
[*] [b]丙烷罐補充站效能補丁避開 Arcadia F700 丙烷車[/b]：丙烷罐補充站（Refillable Propane Tanks）1.9.2 起也支援 Arcadia 自家的 F700 丙烷車，這台車的第二個儲槽要在載入地圖時由原 MOD 初始化一次，本補丁原本會把這一步省掉。現在伺服器只要啟用了 F700 或 Filibuster 丙烷車的 MOD，本補丁就不套用、完全照原 MOD 運作；兩者都沒啟用的伺服器不受影響。
[/list]
