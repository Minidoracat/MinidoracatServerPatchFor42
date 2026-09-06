#!/usr/bin/env python3
"""查 upstream.json 登記的每個 Workshop MOD 是否在我們核對過之後又更新了，並比對檔案。

    python scripts/check_upstream.py                    # 時間戳＋（有本機副本時）檔案比對；有更新 exit 1
    python scripts/check_upstream.py --ack 3540297822   # 重核完 patch：記下時間戳、全檔 hash 清單、watch_files 快照
    python scripts/check_upstream.py --ack all
    python scripts/check_upstream.py --report out.json  # 給 GitHub Action 的結構化輸出
    python scripts/check_upstream.py --source DIR       # workshop content 根（其下為 <wid>/…）；預設本機 Steam 訂閱目錄

三層資訊：
  1. 時間戳（Steam ISteamRemoteStorage/GetPublishedFileDetails，公開 API）——永遠有，是開 issue 的唯一觸發
  2. 全 MOD 檔案清單差異（與 upstream/<wid>.files.json 的 hash 清單比）——有來源目錄才有
  3. watch_files 的 unified diff（與 upstream/<wid>/<relpath> 的快照比）——有來源目錄才有
比對只是附加資訊；抓不到來源也照樣回報「有更新」。
"""
import argparse
import difflib
import hashlib
import json
import os
import shutil
import sys
import time
import urllib.parse
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
UPSTREAM = ROOT / "upstream.json"
STATE = ROOT / "upstream"
API = "https://api.steampowered.com/ISteamRemoteStorage/GetPublishedFileDetails/v1/"
DEFAULT_SOURCES = [
    os.environ.get("PZ_WORKSHOP_DIR", ""),
    "D:/SteamLibrary/steamapps/workshop/content/108600",
    "C:/Program Files (x86)/Steam/steamapps/workshop/content/108600",
]
DIFF_MAX_LINES = 400


def fetch_details(wids):
    form = {"itemcount": str(len(wids))}
    for i, wid in enumerate(wids):
        form[f"publishedfileids[{i}]"] = str(wid)
    req = urllib.request.Request(API, data=urllib.parse.urlencode(form).encode(), method="POST")
    with urllib.request.urlopen(req, timeout=30) as resp:
        payload = json.load(resp)
    return {str(d["publishedfileid"]): d for d in payload["response"]["publishedfiledetails"]}


def fmt(ts):
    return time.strftime("%Y-%m-%d %H:%M", time.gmtime(ts)) + " UTC" if ts else "（未核對）"


def find_source(explicit):
    for cand in ([explicit] if explicit else DEFAULT_SOURCES):
        if cand and Path(cand).is_dir():
            return Path(cand)
    return None


def hash_tree(root: Path):
    out = {}
    for p in sorted(root.rglob("*")):
        if p.is_file():
            out[p.relative_to(root).as_posix()] = hashlib.sha256(p.read_bytes()).hexdigest()
    return out


def read_text(p: Path):
    return p.read_text(encoding="utf-8", errors="replace").splitlines()


def compare(u, src_dir: Path):
    """回傳 {status, added, removed, modified, watch_diffs}；src_dir 不存在 → status=no_source。"""
    wid = str(u["wid"])
    cur_root = src_dir / wid
    if not cur_root.is_dir():
        return {"status": "no_source"}
    baseline_file = STATE / f"{wid}.files.json"
    if not baseline_file.exists():
        return {"status": "no_baseline", "hint": f"先跑 --ack {wid} 建立基線"}
    old = json.loads(baseline_file.read_text(encoding="utf-8"))
    new = hash_tree(cur_root)
    added = sorted(set(new) - set(old))
    removed = sorted(set(old) - set(new))
    modified = sorted(k for k in set(old) & set(new) if old[k] != new[k])
    watch_diffs = {}
    for rel in u.get("watch_files", []):
        snap = STATE / wid / rel
        cur = cur_root / rel
        if rel in removed or not cur.exists():
            watch_diffs[rel] = "（上游已移除此檔）"
            continue
        if rel in added or not snap.exists():
            watch_diffs[rel] = "（新檔或無快照，無法 diff）"
            continue
        if rel not in modified:
            continue
        lines = list(difflib.unified_diff(read_text(snap), read_text(cur), f"acked/{rel}", f"steam/{rel}", lineterm=""))
        if len(lines) > DIFF_MAX_LINES:
            lines = lines[:DIFF_MAX_LINES] + [f"… 截斷（共 {len(lines)} 行）"]
        watch_diffs[rel] = "\n".join(lines)
    return {"status": "ok", "added": added, "removed": removed, "modified": modified, "watch_diffs": watch_diffs}


def ack(u, src_dir, now, title):
    wid = str(u["wid"])
    u["acked_time_updated"] = now
    u["acked_title"] = title
    cur_root = src_dir / wid if src_dir else None
    if not cur_root or not cur_root.is_dir():
        print(f"  {wid}: 找不到本機副本，只更新時間戳（無檔案基線）")
        return
    STATE.mkdir(exist_ok=True)
    (STATE / f"{wid}.files.json").write_text(json.dumps(hash_tree(cur_root), indent=1) + "\n", encoding="utf-8")
    snap_root = STATE / wid
    if snap_root.exists():
        shutil.rmtree(snap_root)
    for rel in u.get("watch_files", []):
        src = cur_root / rel
        if src.is_file():
            dst = snap_root / rel
            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(src, dst)
        else:
            print(f"  {wid}: watch_files 找不到 {rel}")
    print(f"  {wid}: 時間戳 {fmt(now)}、{len(hash_tree(cur_root))} 檔 hash、{len(u.get('watch_files', []))} 個快照")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--ack", metavar="WID|all")
    ap.add_argument("--report", metavar="FILE")
    ap.add_argument("--source", metavar="DIR", help="workshop content 根目錄（其下為 <wid>/）")
    args = ap.parse_args()

    data = json.loads(UPSTREAM.read_text(encoding="utf-8"))
    ups = data["upstreams"]
    if not ups:
        if args.report:
            Path(args.report).write_text("[]\n", encoding="utf-8")
        print("OK — upstream.json 沒有登記任何上游")
        return 0
    details = fetch_details([u["wid"] for u in ups])
    src_dir = find_source(args.source)

    if args.ack:
        for u in ups:
            if args.ack not in ("all", str(u["wid"])):
                continue
            d = details.get(str(u["wid"]))
            if not d or d.get("result") != 1:
                print(f"  {u['wid']}: Steam 回 result={d.get('result') if d else None}，不 ack")
                continue
            ack(u, src_dir, int(d["time_updated"]), d.get("title"))
        UPSTREAM.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        return 0

    changed = []
    for u in ups:
        d = details.get(str(u["wid"]))
        if not d or d.get("result") != 1:
            changed.append({**u, "status": "unavailable", "steam_result": d.get("result") if d else None})
            continue
        now = int(d["time_updated"])
        if now > int(u.get("acked_time_updated", 0)):
            changed.append({**u, "status": "updated", "steam_time_updated": now, "steam_title": d.get("title"),
                            "compare": compare(u, src_dir) if src_dir else {"status": "no_source"}})

    if args.report:
        Path(args.report).write_text(json.dumps(changed, ensure_ascii=False, indent=2), encoding="utf-8")

    if not changed:
        print(f"OK — {len(ups)} 個上游都沒有新更新")
        return 0
    for c in changed:
        if c["status"] == "unavailable":
            print(f"!! {c['name']} ({c['wid']}) Steam 回 result={c['steam_result']}，可能已下架")
            continue
        print(f"!! {c['name']} ({c['wid']}) 上游更新 {fmt(c['steam_time_updated'])}（核對過的是 {fmt(c.get('acked_time_updated'))}）")
        print("   受影響 patch：" + ", ".join(c["patches"]))
        cmp_ = c["compare"]
        if cmp_["status"] != "ok":
            print(f"   檔案比對：{cmp_['status']} {cmp_.get('hint', '')}")
            continue
        print(f"   檔案差異：+{len(cmp_['added'])} −{len(cmp_['removed'])} ~{len(cmp_['modified'])}")
        for k in ("added", "removed", "modified"):
            for rel in cmp_[k]:
                print(f"     {k[0].upper()} {rel}")
        for rel, diff in cmp_["watch_diffs"].items():
            print(f"   --- watch: {rel}\n{diff}")
        if not (cmp_["added"] or cmp_["removed"] or cmp_["modified"]):
            print("   檔案零差異（作者重傳同內容），可直接 --ack")
    return 1


if __name__ == "__main__":
    sys.exit(main())
