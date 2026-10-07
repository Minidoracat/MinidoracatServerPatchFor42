#!/usr/bin/env python3
"""重核 MSP_VehicleOptimizeGraph 的白名單：哪些蒙皮車輛模型加 `postProcess = +OPTIMIZE_GRAPH` 後匯入結果與原本等價。

    python scripts/check_optimize_graph.py            # 重算白名單，與補丁檔內的產生區比對；不同 exit 1
    python scripts/check_optimize_graph.py --write    # 把重算結果寫回補丁檔的產生區

上游來源：upstream.json 中 `patches` 含本補丁的各筆（wid）。需要：
  - 本機 Steam 訂閱的上游（--source，預設同 check_upstream.py）
  - 遊戲本體（--game）：用它的 projectzomboid.jar（jassimp 類別）＋ jassimp64.dll 匯入 FBX，結果與遊戲相同
  - JDK 的 javac（--javac，預設 PATH 上的 javac）：編譯內嵌探針，再用遊戲附的 jre64 執行（與遊戲同一份 jassimp）

等價判準（全部成立才進白名單）：模型腳本非 static、沒有既有 postProcess、mesh 在同一個上游的 models_X 找得到 .fbx、
同一 mesh 路徑沒有被 static 模型共用（mesh asset 以路徑為鍵、先載先贏）、同名模型在各上游的 mesh 一致；
探針分別以遊戲的 7 個 post-process 步驟、以及再加 OPTIMIZE_GRAPH 匯入同一個 FBX，所選 mesh（依 PZ findMesh：
先比 mesh 名，再找只掛一個 mesh 的同名節點）的頂點數、頂點座標、mesh 節點世界矩陣、每根骨頭的 offset 矩陣、
動畫名稱集合，以及「有動畫 channel 或被蒙皮引用的節點」各自的同類祖先鏈都相同。
其餘節點在 PZ 是單位矩陣（ImportedSkeleton bindPose 只覆寫 aiBone、AnimationTrack 對無 keyframe 骨頭回單位矩陣），
摺掉不影響畫面。
"""
import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
UPSTREAM = ROOT / "upstream.json"
PATCH_REL = "client/Patches/rSemiTruck/MSP_VehicleOptimizeGraph.lua"
PATCH_FILE = ROOT / "MOD/MinidoracatServerPatchFor42/Contents/mods/MinidoracatServerPatchFor42/42/media/lua" / PATCH_REL
BEGIN, END = "-- BEGIN GENERATED", "-- END GENERATED"
FLAG = "OPTIMIZE_GRAPH"
SOURCES = [os.environ.get("PZ_WORKSHOP_DIR", ""), "D:/SteamLibrary/steamapps/workshop/content/108600",
           "C:/Program Files (x86)/Steam/steamapps/workshop/content/108600"]
GAMES = [os.environ.get("PZ_GAME_DIR", ""), "D:/SteamLibrary/steamapps/common/ProjectZomboid",
         "C:/Program Files (x86)/Steam/steamapps/common/ProjectZomboid"]
PZ_VERSION = (42, 21)  # 載入「≤ 此版本的最高版本目錄＋common」；遊戲改版時一起改

# FileTask_LoadMesh.loadFBX 的步驟（42.21.0 FileTask_LoadMesh.java:81-90）＋可選的額外步驟
PROBE_JAVA = r'''
import jassimp.*;
import java.util.*;
public class Probe {
    static void collect(List<AiNode> out, AiNode n) { out.add(n); for (AiNode c : n.getChildren()) collect(out, c); }
    static String q(String s) { return "\"" + s.replace("\\", "\\\\").replace("\"", "\\\"") + "\""; }
    static float[] mul(AiMatrix4f m, float[] acc) {
        float[] r = new float[16];
        for (int i = 0; i < 4; i++) for (int j = 0; j < 4; j++) { float s = 0; for (int k = 0; k < 4; k++) s += m.get(i, k) * acc[k * 4 + j]; r[i * 4 + j] = s; }
        return r;
    }
    public static void main(String[] a) throws Exception {
        Jassimp.setLibraryLoader(new JassimpLibraryLoader() { public void loadLibrary() { System.loadLibrary("jassimp64"); } });
        EnumSet<AiPostProcessSteps> extra = EnumSet.noneOf(AiPostProcessSteps.class);
        for (String f : a) {
            if (f.startsWith("+")) { extra.add(AiPostProcessSteps.valueOf(f.substring(1))); continue; }
            EnumSet<AiPostProcessSteps> steps = EnumSet.of(AiPostProcessSteps.FIND_INSTANCES, AiPostProcessSteps.MAKE_LEFT_HANDED,
                AiPostProcessSteps.LIMIT_BONE_WEIGHTS, AiPostProcessSteps.TRIANGULATE, AiPostProcessSteps.OPTIMIZE_MESHES,
                AiPostProcessSteps.REMOVE_REDUNDANT_MATERIALS, AiPostProcessSteps.JOIN_IDENTICAL_VERTICES);
            steps.addAll(extra);
            StringBuilder sb = new StringBuilder("{\"file\":" + q(f));
            try {
                AiScene sc = Jassimp.importFile(f, steps);
                AiBuiltInWrapperProvider w = new AiBuiltInWrapperProvider();
                List<AiNode> all = new ArrayList<>(); collect(all, sc.getSceneRoot(w));
                sb.append(",\"meshes\":[");
                int i = 0;
                for (AiMesh m : sc.getMeshes()) {
                    double vs = 0; java.nio.FloatBuffer vb = m.getPositionBuffer();
                    for (int k = 0; k < vb.capacity(); k++) vs += Math.abs(vb.get(k)) * (1 + k % 7);
                    AiNode mn = null; int mi = sc.getMeshes().indexOf(m);
                    for (AiNode n : all) for (int r : n.getMeshes()) if (r == mi) mn = n;
                    double ws = 0;
                    if (mn != null) {
                        float[] acc = new float[16]; for (int k = 0; k < 16; k++) acc[k] = (k % 5 == 0) ? 1 : 0;
                        for (AiNode p = mn; p != null; p = p.getParent()) acc = mul(p.getTransform(w), acc);
                        for (int k = 0; k < 16; k++) ws += acc[k] * (1 + k);
                    }
                    sb.append(i++ == 0 ? "" : ",").append("{\"name\":" + q(m.getName()) + ",\"node\":" + q(mn == null ? "" : mn.getName())
                        + ",\"nv\":" + m.getNumVertices() + ",\"vsum\":" + vs + ",\"wsum\":" + ws + ",\"hasBones\":" + m.hasBones() + ",\"bones\":[");
                    int j = 0;
                    for (AiBone b : m.getBones()) {
                        double os = 0; AiMatrix4f om = b.getOffsetMatrix(w);
                        if (om == null) os = -12345; else for (int r = 0; r < 4; r++) for (int c = 0; c < 4; c++) os += om.get(r, c) * (1 + r * 4 + c);
                        sb.append(j++ == 0 ? "" : ",").append("[" + q(b.getName()) + "," + os + "]");
                    }
                    sb.append("]}");
                }
                sb.append("],\"nodes\":[");
                i = 0;
                for (AiNode n : all) sb.append(i++ == 0 ? "" : ",").append("[" + q(n.getName()) + "," + q(n.getParent() == null ? "" : n.getParent().getName()) + "," + n.getNumMeshes() + "]");
                sb.append("],\"anims\":[");
                i = 0;
                for (AiAnimation an : sc.getAnimations()) {
                    sb.append(i++ == 0 ? "" : ",").append("{\"name\":" + q(an.getName()) + ",\"ch\":[");
                    int j = 0; for (AiNodeAnim ch : an.getChannels()) sb.append(j++ == 0 ? "" : ",").append(q(ch.getNodeName()));
                    sb.append("]}");
                }
                sb.append("]");
            } catch (Throwable t) { sb.append(",\"error\":" + q(t.toString())); }
            System.out.println(sb.append("}"));
        }
    }
}
'''


def first_dir(cands):
    return next((Path(c) for c in cands if c and Path(c).is_dir()), None)


# ---------- PZ 腳本解析（ScriptParser.java:11-44、52-87 的語意）----------
def strip_comments(s):
    while True:
        end = s.rfind("*/")
        if end == -1:
            return s
        start = s.rfind("/*", 0, end)
        if start == -1:
            return s
        s = s[:start] + s[end + 2:]


def read_block(s, start, block):
    i = start
    while i < len(s):
        ch = s[i]
        if ch == "{":
            ss = s[start:i].strip().split()
            child = {"type": ss[0] if ss else "", "id": ss[1] if len(ss) > 1 else None, "values": [], "children": []}
            block["children"].append(child)
            i = read_block(s, i + 1, child)
            start = i
            continue
        if ch == "}":
            return i + 1
        if ch == ",":
            raw = s[start:i]
            k, _, v = raw.partition("=")
            block["values"].append((k.strip(), v.strip() if _ else ""))
            start = i + 1
        i += 1
    return i


def parse_script(path):
    root = {"children": [], "values": []}
    read_block(strip_comments(path.read_text(encoding="utf-8", errors="replace")), 0, root)
    return root


def ver_key(name):
    try:
        return tuple(int(x) for x in name.split("."))
    except ValueError:
        return None


def load_roots(mod_dir):
    """42.21 的載入目錄：common＋≤PZ_VERSION 的最高版本目錄（後者覆蓋前者）。"""
    subs = [d for d in mod_dir.iterdir() if d.is_dir()]
    vers = [(ver_key(d.name), d) for d in subs if ver_key(d.name) and ver_key(d.name) <= PZ_VERSION]
    roots = [d for d in subs if d.name == "common"]
    if vers:
        roots.append(max(vers)[1])
    return [r / "media" for r in roots if (r / "media").is_dir()]


def scan_upstream(wid_dir):
    """回傳 models{full:[{mesh,static,postProcess,src}]}、fbx{relpath_lower: Path}。"""
    models, fbx = {}, {}
    for mod_dir in sorted((wid_dir / "mods").iterdir()):
        if not mod_dir.is_dir():
            continue
        for media in load_roots(mod_dir):
            for sub in media.iterdir():
                if sub.is_dir() and sub.name.lower() == "models_x":
                    for p in sub.rglob("*"):
                        if p.is_file():
                            fbx[p.relative_to(sub).as_posix().lower()] = p
            scripts = media / "scripts"
            if not scripts.is_dir():
                continue
            for txt in sorted(scripts.rglob("*.txt")):
                for mod_blk in parse_script(txt)["children"]:
                    if mod_blk["type"] != "module":
                        continue
                    for b in mod_blk["children"]:
                        if b["type"] != "model" or not b["id"]:
                            continue
                        d = {"mesh": None, "static": True, "postProcess": None, "src": txt}
                        for k, v in b["values"]:
                            kl = k.lower()
                            if kl == "mesh":
                                d["mesh"] = v
                            elif kl == "static":
                                d["static"] = v.lower() == "true"
                            elif kl == "postprocess":
                                d["postProcess"] = v
                        # Model 類型有 ResetExisting：同名後載入的 body 整個取代前一個
                        models.setdefault(f"{mod_blk['id']}.{b['id']}", []).append(d)
    return {k: v[-1] for k, v in models.items()}, fbx


# ---------- jassimp 探針 ----------
def run_probe(javac, game, files, extra):
    """以遊戲附的 jre64 執行探針：native 方法綁定在載入 jassimp 類別的 class loader 上，探針必須和它同在 classpath。"""
    tmp = Path(tempfile.mkdtemp(prefix="msp_og_"))
    jar = game / "projectzomboid.jar"
    jre = game / "jre64" / "bin" / ("java.exe" if os.name == "nt" else "java")
    try:
        (tmp / "Probe.java").write_text(PROBE_JAVA, encoding="utf-8")
        res = subprocess.run([javac, "-nowarn", "-cp", str(jar), "-d", str(tmp), str(tmp / "Probe.java")],
                             capture_output=True, text=True, encoding="utf-8")
        if res.returncode != 0:
            sys.exit(f"探針編譯失敗（需要 JDK 的 javac）：\n{res.stderr[-2000:]}")
        out = {}
        for i in range(0, len(files), 12):
            cmd = [str(jre), "--enable-native-access=ALL-UNNAMED", f"-Djava.library.path={game}",
                   "-cp", os.pathsep.join([str(jar), str(tmp)]), "Probe", *extra, *map(str, files[i:i + 12])]
            res = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8")
            lines = [l for l in res.stdout.splitlines() if l.startswith("{")]
            if res.returncode != 0 or not lines:
                sys.exit(f"探針執行失敗：\n{res.stderr[-2000:]}")
            for l in lines:
                r = json.loads(l)
                if "error" in r:
                    sys.exit(f"jassimp 匯入失敗 {r['file']}：{r['error']}")
                out[r["file"]] = r
        return out
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


def find_mesh(scene, name):
    """ProcessedAiScene.findMesh（42.21.0 :97-125）。"""
    if not name:
        return next((m for m in scene["meshes"] if m["hasBones"]), scene["meshes"][0] if scene["meshes"] else None)
    for m in scene["meshes"]:
        if m["name"].lower() == name.lower():
            return m
    if any(n[0] == name and n[2] == 1 for n in scene["nodes"]):
        return next((m for m in scene["meshes"] if m["node"] == name), None)
    return None


def chains(scene):
    imp = {c for a in scene["anims"] for c in a["ch"]} | {b[0] for m in scene["meshes"] for b in m["bones"]}
    parent = {}
    for n, p, _ in scene["nodes"]:
        parent.setdefault(n, p)
    out = {}
    for n in imp:
        ch, p, seen = [], parent.get(n), {n}
        while p and p not in seen:
            seen.add(p)
            if p in imp:
                ch.append(p)
            p = parent.get(p)
        out[n] = ch
    return out


def close(a, b):
    return abs(a - b) <= 1e-4 * max(1.0, abs(a))


def mesh_problem(base, opt, name):
    a, b = find_mesh(base, name), find_mesh(opt, name)
    if a is None:
        return "原本就找不到 mesh"
    if b is None:
        return "OPTIMIZE_GRAPH 後找不到 mesh（被合併）"
    if a["nv"] != b["nv"] or a["hasBones"] != b["hasBones"] or not close(a["vsum"], b["vsum"]) or not close(a["wsum"], b["wsum"]):
        return "頂點或 mesh 節點矩陣不同"
    ba, bb = dict(map(tuple, a["bones"])), dict(map(tuple, b["bones"]))
    if ba.keys() != bb.keys() or any(not close(ba[k], bb[k]) for k in ba):
        return "骨頭 offset 不同"
    if sorted(x["name"] for x in base["anims"]) != sorted(x["name"] for x in opt["anims"]):
        return "動畫集合不同"
    if chains(base) != chains(opt):
        return "動畫／蒙皮節點階層不同"
    return None


# ---------- 白名單 ----------
def compute(entries, src_root, game, javac):
    scanned = {}
    for u in entries:
        wid = str(u["wid"])
        if not (src_root / wid).is_dir():
            sys.exit(f"{wid}：本機沒有訂閱副本（{src_root / wid}）")
        scanned[wid] = scan_upstream(src_root / wid)
    # 跨上游：mesh asset 以路徑為鍵（AssetManager.load），同名模型以最後載入者為準——兩者都要一致才收
    static_meshes = {d["mesh"].lower() for models, _ in scanned.values() for d in models.values() if d["static"] and d["mesh"]}
    meshes_of = {}
    for models, _ in scanned.values():
        for full, d in models.items():
            meshes_of.setdefault(full, set()).add((d["mesh"] or "").lower())
    rejects, cand = [], []
    for wid, (models, fbx) in scanned.items():
        for full, d in sorted(models.items()):
            if d["static"] or not d["mesh"]:
                continue
            path, _, sel = d["mesh"].partition("|")
            f = fbx.get(path.lower() + ".fbx")
            why = None
            if d["postProcess"]:
                why = f"已有 postProcess={d['postProcess']}（Lua 讀不到原值，不覆寫）"
            elif f is None:
                why = "mesh 不是本上游的 .fbx"
            elif d["mesh"].lower() in static_meshes:
                why = "同一 mesh 也被 static 模型使用"
            elif len(meshes_of[full]) > 1:
                why = "同名模型在不同上游指向不同 mesh"
            if why:
                rejects.append((wid, full, why))
            else:
                cand.append((wid, full, d["mesh"], sel, f))
    files = sorted({c[4] for c in cand})
    base = run_probe(javac, game, files, [])
    opt = run_probe(javac, game, files, ["+" + FLAG])
    per_wid = {}
    for wid, full, mesh, sel, f in cand:
        why = mesh_problem(base[str(f)], opt[str(f)], sel)
        if why:
            rejects.append((wid, full, why))
        else:
            per_wid.setdefault(wid, {})[full] = (mesh, f)
    return per_wid, rejects, files


def render(entries, per_wid):
    names = {str(u["wid"]): u.get("mod_id", "") for u in entries}
    out = [BEGIN + " by scripts/check_optimize_graph.py; do not edit by hand", "local LIST = {"]
    for wid in sorted(per_wid, key=lambda w: (names[w].lower(), w)):
        out.append(f"    -- {wid} {names[wid]} ({len(per_wid[wid])})")
        for full in sorted(per_wid[wid]):
            out.append(f'    ["{full}"] = "{per_wid[wid][full][0]}",')
    out += ["}", END]
    return "\n".join(out)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--write", action="store_true", help="把重算結果寫回補丁檔的產生區")
    ap.add_argument("--source", help="workshop content 根（其下為 <wid>/）")
    ap.add_argument("--game", help="Project Zomboid 安裝目錄")
    ap.add_argument("--javac", default=os.environ.get("JAVAC", "javac"), help="JDK 的 javac")
    args = ap.parse_args()

    entries = [u for u in json.loads(UPSTREAM.read_text(encoding="utf-8"))["upstreams"] if PATCH_REL in u.get("patches", [])]
    if not entries:
        sys.exit("upstream.json 沒有登記本補丁的上游")
    src_root = Path(args.source) if args.source else first_dir(SOURCES)
    game = Path(args.game) if args.game else first_dir(GAMES)
    if not src_root or not game or not (game / "projectzomboid.jar").is_file():
        sys.exit("找不到 workshop 目錄或遊戲本體（--source／--game）")

    per_wid, rejects, files = compute(entries, src_root, game, args.javac)
    total = sum(len(v) for v in per_wid.values())
    print(f"上游 {len(entries)} 個、FBX {len(files)} 個、白名單 {total} 個模型腳本、排除 {len(rejects)} 個")
    for wid, full, why in rejects:
        print(f"  排除 {wid} {full}：{why}")
    for wid in sorted(per_wid):
        sha = hashlib.sha256(b"".join(f.read_bytes() for f in sorted({v[1] for v in per_wid[wid].values()}))).hexdigest()[:12]
        print(f"  {wid}: {len(per_wid[wid])} 個模型、FBX 合併 sha256 {sha}")

    text = PATCH_FILE.read_text(encoding="utf-8")
    m = re.search(re.escape(BEGIN) + r".*?" + re.escape(END), text, flags=re.S)
    if not m:
        sys.exit(f"{PATCH_FILE} 沒有產生區標記")
    block = render(entries, per_wid)
    if block == m.group(0):
        print("OK：補丁檔白名單與重算結果一致")
        return 0
    if args.write:
        PATCH_FILE.write_text(text[:m.start()] + block + text[m.end():], encoding="utf-8", newline="\n")
        print(f"已寫回 {PATCH_FILE.relative_to(ROOT)}")
        return 0
    old = set(re.findall(r'\["([^"]+)"\] = "([^"]+)"', m.group(0)))
    new = set(re.findall(r'\["([^"]+)"\] = "([^"]+)"', block))
    for k, v in sorted(old - new):
        print(f"  - {k} = {v}")
    for k, v in sorted(new - old):
        print(f"  + {k} = {v}")
    print("FAIL：白名單與重算結果不同；確認差異後跑 --write")
    return 1


if __name__ == "__main__":
    sys.exit(main())
