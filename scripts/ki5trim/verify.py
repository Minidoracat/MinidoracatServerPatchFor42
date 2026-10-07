#!/usr/bin/env python3
"""離線驗證：用遊戲本體的 jassimp＋PZ 自己的匯入類別，比較原 KI5 檔與裁剪後的檔，容差 0（逐位元）。

    python scripts/ki5trim/verify.py              # 全部群組逐位元等價才 exit 0，並把 PZ 骨頭數寫回 manifest.json
    python scripts/ki5trim/verify.py --mutations  # 突變測試：故意做壞的檔必須被抓到

原檔＋原 selector 對 新檔＋同 selector（Probe.java；每個值取 IEEE754 原始位元的 SHA-256）：
- mesh：ImportedSkinnedMesh.vertices（位置、法線、權重、骨頭索引→骨頭名、所有 UV）、三角形索引、mesh 節點世界矩陣（transform）
- 骨頭（以名稱對應）：父骨頭名、bindPose／invBindPose、skinOffset（＝aiBone offset）、aiNode 本地矩陣與世界矩陣
- 動畫：clip 名稱集合、每個 clip 的時長、保留骨頭的每個 keyframe（時間、位置、旋轉、縮放）、
  保留骨頭在「自己＋祖先」所有 keyframe 時刻的 model 矩陣與 skin 矩陣（AnimationPlayer 的 model[b]=bone[b]×model[parent]、
  skin=boneOffset×model）
- 同一群組各成員在新檔的骨頭順序一致（共用 player 時索引才對得上）

VehicleSkeleton 歸零的群組（manifest neutralized）只放寬三件事：
(a) `VehicleSkeleton_$AssimpFbx$_*` 節點消失（新檔不得還有它們，否則歸零沒生效）；
(b) VehicleSkeleton 自己的父骨頭、aiNode 本地／世界矩陣改變；
(c) VehicleSkeleton 子孫骨頭的 aiNode 世界矩陣改變（本地矩陣仍須相同）。PZ 只在 ProcessedAiScene.initMeshTransform
    （42.21.0 :78-95；javap 位移 46、81，全 jassimp 套件與 AnimationPlayer／ModelInstanceRenderData／SkinningData 僅有的
    AiNode.getTransform 呼叫）讀 aiNode 變換，且只走 mesh 節點自己的祖先鏈；骨架只用節點名稱與父子關係
    （ImportedSkeleton.java:56-112），bindPose 由 aiBone offset 算（:114-156），動畫只用 keyframe（AnimationPlayer
    updateModelTransformsInternal :1456-1464），attachment 骨頭取 player 的 model 矩陣（ModelInstanceRenderData.java:123-135）。
另外逐組再確認前提：VehicleSkeleton 在原檔任何 clip 都沒有 keyframe、仍在新檔骨架裡。
"""
import argparse
import json
import os
import shutil
import struct
import subprocess
import sys
import tempfile
import zlib
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build  # noqa: E402
import fbx  # noqa: E402

TOOLS = Path(__file__).resolve().parent
PIVOT_PREFIX = build.NEUTRAL_NODE + "_$AssimpFbx$_"


def compile_probe(game, javac):
    out = Path(tempfile.mkdtemp(prefix="ki5trim_probe_"))
    res = subprocess.run([javac, "-nowarn", "-encoding", "UTF-8", "-cp", str(game / "projectzomboid.jar"), "-d", str(out),
                          str(TOOLS / "Probe.java")], capture_output=True, text=True)
    if res.returncode:
        sys.exit("探針編譯失敗（需要 JDK 的 javac）：\n" + res.stderr[-2000:])
    return out


def run_probe(game, classes, jobs, extra=()):
    """jobs: [(檔案, mesh 名)]；回傳 {(檔案, mesh 名): 結果}。依檔案排序，讓探針一個檔只匯入一次。"""
    jobs = sorted(set(jobs))
    java = game / "jre64" / "bin" / ("java.exe" if os.name == "nt" else "java")
    cmd = [str(java), "--enable-native-access=ALL-UNNAMED", f"-Djava.library.path={game}", "-Xmx4g",
           "-cp", os.pathsep.join([str(game / "projectzomboid.jar"), str(classes)]),
           "zombie.core.skinnedmodel.model.jassimp.Probe", *extra]
    stdin = "".join(f"{f}|{m}\n" for f, m in jobs)
    res = subprocess.run(cmd, input=stdin.encode("utf-8"), capture_output=True)
    lines = [json.loads(l) for l in res.stdout.decode("utf-8").splitlines() if l.startswith("{")]
    if res.returncode or len(lines) != len(jobs):
        sys.exit(f"探針執行失敗（{len(lines)}/{len(jobs)}）：\n{res.stderr.decode('utf-8', 'replace')[-3000:]}")
    return {j: r for j, r in zip(jobs, lines)}


def compare(a, b, clips_used, neutral=False):
    """a＝原檔結果、b＝新檔結果。回傳問題列表（空＝等價）。
    clips_used：群組零件 anim 會播的 clip。assimp 會丟掉「裁剪後沒有任何 channel」的 AnimationStack；這種 clip 只有在
    不會被本群組 player 播放、且原本對保留骨頭也沒有 keyframe 時才允許消失（播了會把骨頭 lerp 向單位矩陣，不能少）。
    neutral：新檔的 VehicleSkeleton 歸零過，套用模組說明的 (a)(b)(c) 放寬。"""
    if "error" in a:
        return [f"原檔匯入失敗：{a['error']}"]
    if "error" in b:
        return [f"新檔匯入失敗：{b['error']}"]
    probs = [f"mesh.{k} 不同" for k in sorted(set(a["mesh"]) | set(b["mesh"])) if a["mesh"].get(k) != b["mesh"].get(k)]
    A = {x[0]: x for x in a["bones"]}
    B = {x[0]: x for x in b["bones"]}
    parent = {x[0]: x[1] for x in b["bones"]}
    vs = build.NEUTRAL_NODE

    def under_vs(n):
        seen = set()
        while n in parent and n not in seen:
            seen.add(n)
            n = parent[n]
            if n == vs:
                return True
        return False

    if neutral:
        if vs not in B:
            probs.append(f"新檔骨架沒有 {vs}")
        probs += [f"歸零後仍有 {n}" for n in B if n.startswith(PIVOT_PREFIX)]
        probs += [f"{vs} 在原檔 clip {c} 有 keyframe" for c, x in a["clips"].items() if vs in x["keys"]]
    idx = {"parent": 1, "bindPose": 2, "skinOffset": 3, "local": 4, "world": 5}
    for n, x in B.items():
        if n not in A:
            probs.append(f"新檔多出骨頭 {n}")
            continue
        for f, i in idx.items():
            if neutral and n == vs and f in ("parent", "local", "world"):
                continue  # (b)
            if neutral and f == "world" and under_vs(n):
                continue  # (c)
            if x[i] != A[n][i]:
                probs.append(f"骨頭 {n} 的 {f} 不同")
    lost, extra = set(a["clips"]) - set(b["clips"]), set(b["clips"]) - set(a["clips"])
    bad_lost = {c for c in lost if c in clips_used or set(a["clips"][c]["keys"]) & set(B)}
    if bad_lost or extra:
        probs.append(f"clip 集合不同：少 {sorted(bad_lost)} 多 {sorted(extra)}")
    for cn in sorted(set(a["clips"]) & set(b["clips"])):
        ca, cb = a["clips"][cn], b["clips"][cn]
        if ca["dur"] != cb["dur"]:
            probs.append(f"clip {cn} 時長不同")
        for n in B:
            if n in A and ca["keys"].get(n) != cb["keys"].get(n):
                probs.append(f"clip {cn} 骨頭 {n} 的 keyframe 不同")
            if n in A and ca["skin"].get(n) != cb["skin"].get(n):
                probs.append(f"clip {cn} 骨頭 {n} 的 model／skin 矩陣不同")
    return probs


def verify_all(manifest, workshop, new_root, game, classes):
    jobs = []
    for g in manifest["groups"]:
        for sel in g["selectors"]:
            jobs += [(str(workshop / g["source_file"]), sel), (str(new_root / f"{g['file']}.fbx"), sel)]
    res = run_probe(game, classes, jobs)
    bad, dropped = 0, set()
    for g in manifest["groups"]:
        probs, orders, before, after = [], set(), set(), set()
        src = str(workshop / g["source_file"])
        new = str(new_root / f"{g['file']}.fbx")
        for sel in g["selectors"]:
            a, b = res[(src, sel)], res[(new, sel)]
            probs += [f"{sel}: {p}" for p in compare(a, b, set(g["clips_used"]), bool(g["neutralized"]))]
            if "error" not in b and "error" not in a:
                dropped.update((g["file"], c) for c in set(a["clips"]) - set(b["clips"]))
                orders.add(tuple(x[0] for x in b["bones"]))
                before.add(len(a["bones"]))
                after.add(len(b["bones"]))
        if len(orders) > 1:
            probs.append("群組成員在新檔的骨頭順序不一致")
        if len(before) == 1 and len(after) == 1:
            g["bones_before"], g["bones_after"] = before.pop(), after.pop()
        if probs:
            bad += 1
            print(f"FAIL {g['file']}：" + "；".join(probs[:6]) + (f"…（共 {len(probs)} 項）" if len(probs) > 6 else ""))
    groups = manifest["groups"]
    neutral = [g for g in groups if g["neutralized"]]
    props = sorted({k for g in neutral for k in g["neutralized"][build.NEUTRAL_NODE]})
    print(f"{len(groups) - bad}/{len(groups)} 個群組逐位元等價（{sum(len(g['selectors']) for g in groups)} 個模型；"
          f"{len(neutral)} 組歸零 {build.NEUTRAL_NODE} 的 {'、'.join(props) or '—'}，{len(groups) - len(neutral)} 組不歸零）；"
          f"PZ 骨頭數合計 {sum(g.get('bones_before', 0) for g in groups)} → {sum(g.get('bones_after', 0) for g in groups)}；"
          f"{len({f for f, _ in dropped})} 個群組少了不會被播放的空 clip（{', '.join(sorted({c for _, c in dropped}))}）")
    return bad


# ---------- 突變 ----------
def _mutate_keyframe(doc, keep_bone_names, delta=1.0):
    """把一根保留骨頭所有 Lcl Rotation 曲線的 key 值 +delta 度（binary：解壓、改值、重新壓縮）。
    改全部曲線是因為 KI5 檔裡有沒接到任何 AnimationStack 的孤兒 AnimationLayer，只改一條可能改到沒用的。"""
    ix = build.FbxIndex(doc)
    targets = {i for n in keep_bone_names[:1] for i in ix.models_by_name.get(n, ())}
    nodes = {c.props[1] for c in ix.conns if c.props[2] in targets and ix._is(c.props[1], "AnimationCurveNode")
             and len(c.props) > 3 and c.props[3] == "Lcl Rotation"}
    done = False
    for c in ix.conns:
        if c.props[2] in nodes and ix._is(c.props[1], "AnimationCurve"):
            kv = ix.byid[c.props[1]].find("KeyValueFloat")
            raw = kv.raw_props[0]
            t, (n, enc, clen) = raw[:1], struct.unpack_from("<III", raw, 1)
            body = raw[13:13 + clen]
            vals = bytearray(zlib.decompress(body) if enc else body)
            for k in range(n):
                v, = struct.unpack_from("<f", vals, 4 * k)
                struct.pack_into("<f", vals, 4 * k, v + delta)
            body = zlib.compress(bytes(vals)) if enc else bytes(vals)
            kv.raw_props = [t + struct.pack("<III", n, enc, len(body)) + body]
            done = True
    return done


def mutations(manifest, workshop, game, classes):
    """回傳失敗（沒被抓到）的突變數。"""
    # 挑一個 binary、含子零件（≥3 個成員）、有歸零的群組
    g = next(x for x in manifest["groups"] if len(x["members"]) >= 3 and x["neutralized"]
             and (workshop / x["source_file"]).read_bytes()[:23] == fbx.MAGIC)
    src = workshop / g["source_file"]
    data = src.read_bytes()
    tmp = Path(tempfile.mkdtemp(prefix="ki5trim_mut_"))
    vs = build.NEUTRAL_NODE

    def plan():
        doc = fbx.load(data)
        ix = build.FbxIndex(doc)
        keep, err = build.plan_keep(ix, g["selectors"], g["named_bones"])
        assert not err, err
        return doc, ix, keep

    def make(doc, ix, keep, extra_neutral=()):
        out = build.trim(doc, keep)
        if vs in {build.name_of(ix.byid[i]) for i in keep}:
            build.neutralize(out, ix.models_by_name[vs][0])
        for mid in extra_neutral:
            assert build.neutralize(out, mid), "突變沒改到任何屬性"
        return out

    cases = []
    child_sel = g["selectors"][-1]
    # 1) 刪掉一根需要的骨頭（某個成員 mesh 的蒙皮骨頭）
    doc, ix, keep = plan()
    victim = [b for m in ix.select_mesh(child_sel) for b in ix.cluster_bones(m) if ix.ancestors(b)][-1]
    cases.append((f"刪掉需要的骨頭 {build.name_of(ix.byid[victim])}", make(doc, ix, keep - {victim}).dumps()))
    # 2) 改一個保留骨頭的 keyframe
    doc, ix, keep = plan()
    kept_names = sorted(build.name_of(ix.byid[i]) for m in ix.select_mesh(g["selectors"][0]) for i in ix.cluster_bones(m))[::-1]
    out = make(doc, ix, keep)
    assert _mutate_keyframe(out, kept_names), "找不到可改的 keyframe"
    cases.append(("改一條保留骨頭的旋轉 keyframe 值", out.dumps()))
    # 3) 漏掉一個子零件的 mesh
    doc, ix, keep = plan()
    cases.append((f"漏掉子零件 mesh {child_sel}", make(doc, ix, keep - set(ix.select_mesh(child_sel))).dumps()))
    # 4) 刪掉骨架判定節點 VehicleSkeleton（骨架改用整個場景）
    doc, ix, keep = plan()
    cases.append((f"刪掉 {vs}", make(doc, ix, keep - set(ix.models_by_name.get(vs, ()))).dumps()))
    # 5) 歸零到「有動畫 channel」的骨頭（前提不成立的節點）
    doc, ix, keep = plan()
    animated = [i for i in ix.cluster_bones(ix.select_mesh(g["selectors"][0])[0])
                if any(c.props[2] == i and ix._is(c.props[1], "AnimationCurveNode") for c in ix.conns)
                and build.neutralize(fbx.load(data), i)]
    cases.append((f"歸零有 channel 的骨頭 {build.name_of(ix.byid[animated[0]])}", make(doc, ix, keep, [animated[0]]).dumps()))
    # 6) 歸零到 mesh 節點本身（前提「不是 mesh 節點的祖先」不成立時的效果）
    doc, ix, keep = plan()
    mesh_id = ix.select_mesh(child_sel)[0]
    cases.append((f"歸零 mesh 節點 {child_sel}", make(doc, ix, keep, [mesh_id]).dumps()))

    jobs, paths = [], []
    for i, (_, blob) in enumerate(cases):
        p = tmp / f"mut{i}.fbx"
        p.write_bytes(blob)
        paths.append(p)
        jobs += [(str(src), s) for s in g["selectors"]] + [(str(p), s) for s in g["selectors"]]
    res = run_probe(game, classes, jobs)
    missed = 0
    print(f"突變測試群組：{g['file']}（{', '.join(g['selectors'])}）")
    for (label, _), p in zip(cases, paths):
        probs = [x for s in g["selectors"] for x in compare(res[(str(src), s)], res[(str(p), s)], set(g["clips_used"]), True)]
        print(("  抓到 " if probs else "  漏抓 ") + label + (f"：{probs[0]}" if probs else ""))
        missed += not probs
    shutil.rmtree(tmp, ignore_errors=True)

    # 7～9) build.py 的前提檢查（不需探針）：前提不成立的檔，neutral_reason 必須拒絕歸零
    def reason_with(edit):
        doc = fbx.load(data)
        edit(doc, build.FbxIndex(doc))
        return build.neutral_reason(build.FbxIndex(doc), set(g["named_bones"]))

    def conn(kind, child, parent, prop=None):
        raw = [fbx.Node("C", [], [], [], False)]
        n = raw[0]
        n.props = [kind, child, parent] + ([prop] if prop else [])
        enc = lambda s: b"S" + struct.pack("<I", len(s)) + s.encode()
        n.raw_props = [enc(kind), b"L" + struct.pack("<q", child), b"L" + struct.pack("<q", parent)] + ([enc(prop)] if prop else [])
        return n

    def add_channel(doc, ix):
        cn = next(o.props[0] for o in ix.objs if o.name == "AnimationCurveNode")
        doc.root("Connections").children.append(conn("OP", cn, ix.models_by_name[vs][0], "Lcl Rotation"))

    def add_mesh_child(doc, ix):
        mesh_id = ix.select_mesh(g["selectors"][0])[0]
        for c in doc.root("Connections").children:
            if c.props[0] == "OO" and c.props[1] == mesh_id and ix._is(c.props[2], "Model") or (c.props[1] == mesh_id and c.props[2] == 0):
                c.props = list(c.props)
                c.props[2] = ix.models_by_name[vs][0]
                c.raw_props = c.raw_props[:2] + [b"L" + struct.pack("<q", c.props[2])] + c.raw_props[3:]

    def add_cluster(doc, ix):
        cl = next(o.props[0] for o in ix.objs if o.name == "Deformer" and o.props[2] == "Cluster")
        doc.root("Connections").children.append(conn("OO", ix.models_by_name[vs][0], cl))

    for label, edit in ((f"{vs} 加一條動畫 channel", add_channel), (f"把 mesh 節點掛到 {vs} 底下", add_mesh_child),
                        (f"{vs} 變成 aiBone（Cluster 連到它）", add_cluster)):
        why = reason_with(edit)
        print(("  抓到 " if why else "  漏抓 ") + f"前提檢查：{label}" + (f"：{why}" if why else ""))
        missed += not why
    why = build.neutral_reason(build.FbxIndex(fbx.load(data)), set(g["named_bones"]) | {vs})
    print(("  抓到 " if why else "  漏抓 ") + f"前提檢查：{vs} 被名稱引用" + (f"：{why}" if why else ""))
    missed += not why
    return missed


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--game", type=Path, default=build.first_dir(build.GAMES))
    ap.add_argument("--workshop", type=Path, default=build.first_dir(build.WORKSHOPS))
    ap.add_argument("--javac", default=shutil.which("javac") or "javac")
    ap.add_argument("--mutations", action="store_true")
    a = ap.parse_args()
    manifest = json.loads(build.MANIFEST.read_text(encoding="utf-8"))
    missing = [g["file"] for g in manifest["groups"] if not (build.OUT_MODELS / f"{g['file']}.fbx").is_file()]
    if missing:
        sys.exit(f"{len(missing)} 個群組檔不存在，先跑 python scripts/ki5trim/build.py")
    classes = compile_probe(a.game, a.javac)
    try:
        if a.mutations:
            return 1 if mutations(manifest, a.workshop, a.game, classes) else 0
        if verify_all(manifest, a.workshop, build.OUT_MODELS, a.game, classes):
            return 1
    finally:
        shutil.rmtree(classes, ignore_errors=True)
    build.MANIFEST.write_bytes(build.manifest_bytes(manifest))
    print("已把骨頭數寫回 manifest.json")
    return 0


if __name__ == "__main__":
    sys.exit(main())
