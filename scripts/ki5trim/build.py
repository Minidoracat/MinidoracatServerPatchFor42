#!/usr/bin/env python3
"""KI5 骨架裁剪產生器：依「共用同一個 AnimationPlayer 的模型群組」把 KI5 車輛 FBX 拆成小檔，並產生客戶端 Lua 覆寫表。

    python scripts/ki5trim/build.py            # 重產 FBX、Lua 資料表與 manifest.json（位元組可重現）
    python scripts/ki5trim/build.py --check    # 只重算並比對：FBX、資料表、manifest 與目前檔案不同就 exit 1

FBX 是 KI5 內容的衍生物（KI5 宣告 On Lockdown），只在本機產生到 MOD 樹（.gitignore 排除），隨 Workshop 上傳給本服玩家；
本公開 repo 只收工具、Lua 與 manifest（名稱、雜湊、骨頭數等中繼資料）。verify_mod.py 會擋「資料表引用的 FBX 不存在或雜湊不符」。
manifest 的骨頭數由 verify.py 實測後寫回，本工具依「同一個新檔與來源檔雜湊」沿用。

除了刪節點，只改一處數值：VehicleSkeleton 節點的變換屬性歸零（neutralize_skeleton_root）。KI5 的 VehicleSkeleton 帶
PreRotation 與 Lcl Translation，assimp 因此在它上方補兩個 `VehicleSkeleton_$AssimpFbx$_*` pivot 節點，PZ 把它們算成骨頭
（ImportedSkeleton.java:56-112 從根的直接子節點收整棵子樹）。這兩個節點與 VehicleSkeleton 都沒有動畫 channel、也不是 aiBone，
在 PZ 的動畫裡本來就是單位矩陣（AnimationTrack.java:929-931；bindPose 只由 aiBone offset 決定，ImportedSkeleton.java:114-156），
而 PZ 只在 ProcessedAiScene.initMeshTransform（:78-95，javap 位移 46、81 是全 jassimp 套件僅有的 AiNode.getTransform 呼叫）
讀 aiNode 變換、且只走 mesh 節點自己的祖先鏈。所以前提成立（沒有 channel、不是 aiBone、不是任何 mesh 節點的祖先、
不是名稱引用的骨頭）時歸零不影響畫面，每組少 2 根骨頭；verify.py 逐位元確認。前提不成立的群組不改。
不用 +OPTIMIZE_GRAPH：它把 mesh 節點的 pivot 鏈摺成一個節點，PZ 對摺疊前後算出的 mesh 世界矩陣平移差 0.666（實測，363 組皆然）。

輸入：遊戲本體（--game）、Steam Workshop 內容（--workshop）、正式服 MOD 清單（--prodmods，`M <id>`／`W <wid>` 行）。
群組規則（BaseVehicle$ModelInfo.getAnimationPlayer，BaseVehicle.java:11844-11867）：零件有 parent 且 parent 有 ModelInfo 時，
用 parent 的 player，parent 再往上遞迴；哪個 ModelInfo 先出現取決於可見性，所以「非 static 模型 ↔ 祖先零件的所有非 static 模型」
都連邊，取連通分量。分量內所有模型在新檔共用同一份骨架，骨頭索引一致。
"""
import argparse
import hashlib
import json
import os
import re
import shutil
import struct
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import fbx  # noqa: E402
import pzscripts as ps  # noqa: E402

TOOL_DIR = Path(__file__).resolve().parent
ROOT = TOOL_DIR.parent.parent
MOD_ID = "MinidoracatServerPatchFor42"
MOD_42 = ROOT / "MOD" / MOD_ID / "Contents" / "mods" / MOD_ID / "42"
OUT_DIR_REL = "MSP_KI5Trim"  # media/models_X/ 底下的子目錄（mesh 寫成 MSP_KI5Trim/<檔>|<mesh>）
OUT_MODELS = MOD_42 / "media" / "models_X" / OUT_DIR_REL
OUT_LUA = MOD_42 / "media" / "lua" / "client" / "Patches" / "MSP_KI5SkeletonTrimData.lua"
MANIFEST = TOOL_DIR / "manifest.json"
VERIFIED_KEYS = ("bones_before", "bones_after")  # verify.py 寫回的欄位
# 歸零的節點與屬性（identity 值）；assimp FBX 匯入對這些分量非 identity 時會補 $AssimpFbx$ pivot 節點
NEUTRAL_NODE = "VehicleSkeleton"
NEUTRAL_PROPS = {"Lcl Translation": 0.0, "Lcl Rotation": 0.0, "Lcl Scaling": 1.0, "PreRotation": 0.0, "PostRotation": 0.0,
                 "RotationOffset": 0.0, "RotationPivot": 0.0, "ScalingOffset": 0.0, "ScalingPivot": 0.0,
                 "GeometricTranslation": 0.0, "GeometricRotation": 0.0, "GeometricScaling": 1.0}

GAMES = [os.environ.get("PZ_GAME_DIR", ""), "D:/SteamLibrary/steamapps/common/ProjectZomboid",
         "C:/Program Files (x86)/Steam/steamapps/common/ProjectZomboid"]
WORKSHOPS = [os.environ.get("PZ_WORKSHOP_DIR", ""), "D:/SteamLibrary/steamapps/workshop/content/108600",
             "C:/Program Files (x86)/Steam/steamapps/workshop/content/108600"]
PRODMODS = TOOL_DIR / "prodmods.txt"

# 骨架判定需要的節點（ImportedSkeleton.processAiScene :56-85）
SKELETON_NODES = ("Dummy01", "VehicleSkeleton", "Translation_Data")
# KI5／damnlib／tsarslib Lua 以名稱引用的骨頭（見報告「名稱引用骨頭」；目前 grep 結果為空）
LUA_BONES = ()
# 依附於模型（自己的 parent 是模型或其子物件）的物件類型：只在 parent 保留時保留
DEPENDENT = {"Geometry", "NodeAttribute", "Material", "Texture", "Video", "Deformer", "AnimationCurveNode", "AnimationCurve"}


def first_dir(cands):
    return next((Path(c) for c in cands if c and Path(c).is_dir()), None)


def name_of(o):
    return o.props[1].split("\x00\x01")[0]


# ---------- 群組 ----------
def part_models(world, part):
    """零件模型 → 模型腳本名；file 為空時改看物品的 VehiclePartModel（BaseVehicle.getModelScriptNameForPart :1758-1779）。"""
    out = []
    for mid, m in part.models.items():
        if m["file"]:
            out.append((mid, m["file"]))
        else:
            out += [(mid, x[2]) for x in world.item_part_models if x[0].lower() == part.id.lower() and x[1].lower() == mid.lower()]
    return out


def full_name(n):
    return n if "." in n else "Base." + n


def build_groups(world):
    """回傳 (群組列表, {模型腳本: 需保留的骨頭名}, {模型腳本: 可能在其 player 上播放的 clip 名})。"""
    skinned = lambda n: world.model(n) is not None and not world.model(n).static
    adj, extra, clips = {}, {}, {}
    for v in world.vehicles.values():
        for p in v.parts.values():
            own = [full_name(f) for _, f in part_models(world, p) if skinned(f)]
            for n in own:
                adj.setdefault(n, set())
            chain, seen, anc = [], set(), p.parent
            while anc and anc in v.parts and anc not in seen:
                seen.add(anc)
                chain.append(v.parts[anc])
                anc = v.parts[anc].parent
            for ap in chain:
                for _, a in part_models(world, ap):
                    if skinned(a):
                        for n in own:
                            adj[n].add(full_name(a))
                            adj.setdefault(full_name(a), set()).add(n)
            # playPartAnim 播在「本零件 ModelInfo 的 player」上，也就是本零件或某個祖先零件的模型（BaseVehicle.java:2012-2048）
            for q in [p] + chain:
                for _, a in part_models(world, q):
                    if skinned(a):
                        clips.setdefault(full_name(a), set()).update(c for c in p.anims.values() if c)
            if not chain:
                continue
            # attachmentParent：在 parent 零件 ModelInfo 的 player 上依骨頭名取矩陣；attachment 先找 parent 模型腳本、
            # 再找車輛腳本（BaseVehicle.updateTransform :4431-4451、initTransform :4514-4545）
            for m in p.models.values():
                att = m["attachmentParent"]
                if not att:
                    continue
                for _, a in part_models(world, chain[0]):
                    ms = world.model(a)
                    bone = (ms.attachments.get(att) if ms else None) or v.attachments.get(att)
                    if bone:
                        extra.setdefault(full_name(a), set()).add(bone)
    seen, groups = set(), []
    for n in sorted(adj):
        if n in seen:
            continue
        stack, comp = [n], []
        seen.add(n)
        while stack:
            x = stack.pop()
            comp.append(x)
            for y in sorted(adj[x]):
                if y not in seen:
                    seen.add(y)
                    stack.append(y)
        groups.append(sorted(comp))
    return groups, extra, clips


def named_bones(world, members, extra):
    """名稱引用的骨頭：成員模型腳本的 attachment／boneWeight、子零件 attachmentParent 解析到的骨頭、Lua 引用。"""
    bones = set(LUA_BONES)
    for n in members:
        m = world.models[n]
        bones.update(b for b in m.attachments.values() if b)
        bones.update(m.bone_weights)
        bones.update(extra.get(n, ()))
    return bones


# ---------- FBX 裁剪 ----------
class FbxIndex:
    def __init__(self, doc):
        self.doc = doc
        self.objs = doc.root("Objects").children
        self.byid = {o.props[0]: o for o in self.objs}
        self.conns = doc.root("Connections").children
        self.model_parent, self.parents = {}, {}
        for c in self.conns:
            ch, pa = c.props[1], c.props[2]
            self.parents.setdefault(ch, []).append(pa)
            if self._is(ch, "Model") and self._is(pa, "Model"):
                self.model_parent[ch] = pa
        self.models_by_name = {}
        for o in self.objs:
            if o.name == "Model":
                self.models_by_name.setdefault(name_of(o), []).append(o.props[0])

    def _is(self, oid, typ):
        o = self.byid.get(oid)
        return o is not None and o.name == typ

    def ancestors(self, mid):
        out = []
        while mid in self.model_parent:
            mid = self.model_parent[mid]
            out.append(mid)
        return out

    def select_mesh(self, sel):
        """PZ findMesh（ProcessedAiScene :97-125）：aiMesh 名（Geometry 名，空則用 Model 名）不分大小寫，再找同名節點。
        回傳可能被選中的 Mesh Model（取超集合，順序不變），裁剪後由驗證確認選中的 mesh 等價。"""
        out = []
        low = sel.lower()
        for o in self.objs:
            if o.name == "Geometry":
                g = name_of(o)
                for pa in self.parents.get(o.props[0], ()):
                    if self._is(pa, "Model") and (g or name_of(self.byid[pa])).lower() == low:
                        out.append(pa)
        out += [i for i in self.models_by_name.get(sel, ()) if self.byid[i].props[2] == "Mesh"]
        return list(dict.fromkeys(out))

    def cluster_bones(self, mesh_model):
        """Mesh Model → Geometry → Skin → Cluster ← LimbNode Model。"""
        geoms = [c.props[1] for c in self.conns if c.props[2] == mesh_model and self._is(c.props[1], "Geometry")]
        skins = [c.props[1] for c in self.conns if c.props[2] in geoms and self._is(c.props[1], "Deformer")]
        clusters = [c.props[1] for c in self.conns if c.props[2] in skins and self._is(c.props[1], "Deformer")]
        return [c.props[1] for c in self.conns if c.props[2] in clusters and self._is(c.props[1], "Model")]


def plan_keep(ix, selectors, bone_names):
    """回傳 (保留的 Model id 集合, 錯誤)。"""
    keep = set()
    for sel in selectors:
        if not sel:
            return None, "mesh 沒有 |selector（PZ 會選第一個蒙皮 mesh）"
        ms = ix.select_mesh(sel)
        if not ms:
            return None, f"FBX 找不到 mesh {sel}"
        for m in ms:
            keep.add(m)
            keep.update(ix.cluster_bones(m))
    for nm in set(bone_names) | set(SKELETON_NODES):
        keep.update(ix.models_by_name.get(nm, ()))
    for m in list(keep):
        keep.update(ix.ancestors(m))
    return keep, None


def neutral_reason(ix, named, node=NEUTRAL_NODE):
    """VehicleSkeleton 能不能歸零：回傳 None（可以）或原因。ix 用原檔（整個檔，不只群組）。"""
    ids = ix.models_by_name.get(node, [])
    if len(ids) != 1:
        return f"{node} 有 {len(ids)} 個"
    vid = ids[0]
    if node in named:
        return f"{node} 是名稱引用的骨頭"
    for c in ix.conns:
        if c.props[2] == vid and ix._is(c.props[1], "AnimationCurveNode"):
            return f"{node} 有動畫 channel"
        if c.props[1] == vid and ix._is(c.props[2], "Deformer"):
            return f"{node} 是 aiBone（Cluster 連到它）"
    for o in ix.objs:
        if o.name == "Model" and o.props[2] == "Mesh" and vid in ix.ancestors(o.props[0]):
            return f"{node} 是 mesh 節點 {name_of(o)} 的祖先"
    return None


def neutralize(doc, model_id):
    """把一個 Model 的變換屬性設成 identity；回傳 {屬性: 原值}。binary 改屬性的原始位元組、ASCII 改那一行的數值。"""
    obj = next(o for o in doc.root("Objects").children if o.props[0] == model_id)
    p70 = obj.find("Properties70")
    changed = {}
    for p in (p70.children if p70 else []):
        name = p.props[0]
        if name not in NEUTRAL_PROPS or len(p.props) < 7:
            continue
        ident = NEUTRAL_PROPS[name]
        vals = [float(x) for x in p.props[4:7]]
        if vals == [ident] * 3:
            continue
        changed[name] = vals
        if isinstance(p, fbx.ANode):
            m = re.match(r'(\s*P:\s*(?:"[^"]*"\s*,\s*){4})', p.head)
            p.head = m.group(1) + ",".join(["1" if ident else "0"] * 3)
        else:
            p.raw_props = p.raw_props[:4] + [b"D" + struct.pack("<d", ident)] * 3 + p.raw_props[7:]
        p.props = p.props[:4] + [ident] * 3 + p.props[7:]
    return changed


def trim(doc, keep_models):
    ix = FbxIndex(doc)
    kept = {o.props[0] for o in ix.objs if (o.name == "Model" and o.props[0] in keep_models)
            or (o.name != "Model" and o.name not in DEPENDENT)}
    while True:  # 依附物件：任何一個 parent（CurveNode 不算 AnimationLayer）保留就保留
        add = set()
        for o in ix.objs:
            oid = o.props[0]
            if oid in kept or o.name not in DEPENDENT:
                continue
            for pa in ix.parents.get(oid, ()):
                if pa in kept and not (o.name == "AnimationCurveNode" and ix._is(pa, "AnimationLayer")):
                    add.add(oid)
                    break
        if not add:
            break
        kept |= add
    removed = {o.props[0] for o in ix.objs} - kept
    objects = doc.root("Objects")
    objects.children = [o for o in objects.children if o.props[0] in kept]
    for o in objects.children:
        if o.name == "Pose":
            nodes = [c for c in o.children if c.name != "PoseNode" or c.find("Node").props[0] not in removed]
            o.children = nodes
            nb = o.find("NbPoseNodes")
            if nb is not None:
                fbx.set_count(nb, sum(1 for c in nodes if c.name == "PoseNode"))
    conns = doc.root("Connections")
    conns.children = [c for c in conns.children if c.props[1] not in removed and c.props[2] not in removed]
    return doc


# ---------- 主流程 ----------
def load_prod(path):
    lines = path.read_text(encoding="utf-8").splitlines()
    return [x[2:].strip() for x in lines if x.startswith("M ")], [x[2:].strip() for x in lines if x.startswith("W ")]


def compute(game, workshop, prodmods):
    mods, wids = load_prod(prodmods)
    fm, idx, missing = ps.build_filemap(game, workshop, mods, wids)
    if missing:
        sys.exit(f"Workshop 缺少 MOD：{missing}")
    world = ps.load_world(fm)
    ki5 = {}
    for mid in mods:
        wid, mdir = idx[mid]
        if any("KI5" in ps.read_modinfo(mi).get("author", "") for mi in mdir.glob("*/mod.info")):
            ki5[wid] = mid
    groups, extra, clips = build_groups(world)

    plans, excluded = [], []
    for members in groups:
        srcs = {}
        for n in members:
            ms = world.models[n]
            ent, rel, sel = ps.mesh_file(fm, ms.mesh or "")
            srcs.setdefault((rel, ent[2] if ent else None, ent[1] if ent else None), []).append((n, sel))
        wids_ = {k[1] for k in srcs}
        if not wids_ & set(ki5):
            continue
        reason = None
        if len(srcs) > 1:
            reason = "群組跨多個來源檔：" + ", ".join(sorted(k[0] for k in srcs))
        (rel, wid, mod_id), mem = next(iter(sorted(srcs.items())))
        if not reason and wid not in ki5:
            reason = f"來源檔不在 KI5 MOD：{rel}（{mod_id}）"
        if not reason and not rel.endswith(".fbx"):
            reason = f"來源檔不是 FBX：{rel}"
        entry = {"members": members, "source_rel": rel, "wid": wid, "mod_id": mod_id}
        if reason:
            excluded.append({**entry, "reason": reason})
            continue
        entry["selectors"] = {n: s for n, s in mem}
        entry["old_mesh"] = {n: world.models[n].mesh for n in members}
        entry["bone_names"] = sorted(named_bones(world, members, extra))
        entry["clips_used"] = sorted({c for n in members for c in clips.get(n, ())})
        entry["vehicles"] = users_of(world, members)
        entry["post_process"] = sorted({world.models[n].post_process or "" for n in members})
        entry["src_path"] = fm.files[rel][0]
        plans.append(entry)

    # 同一 mesh selector 也被 static 模型腳本使用：mesh asset 共用快取鍵，排除以免改變「先載先贏」的結果
    static_sel = {}
    for m in world.models.values():
        if m.static and m.mesh:
            static_sel.setdefault(m.mesh.lower(), []).append(m.full)
    final = []
    for e in plans:
        clash = sorted({s for n in e["members"] for s in static_sel.get(e["old_mesh"][n].lower(), ())})
        if clash:
            excluded.append({k: e[k] for k in ("members", "source_rel", "wid", "mod_id")} | {"reason": "mesh 也被 static 模型使用：" + ", ".join(clash)})
        elif any(e["post_process"]):
            excluded.append({k: e[k] for k in ("members", "source_rel", "wid", "mod_id")} | {"reason": "模型腳本已有 postProcess：" + ",".join(e["post_process"])})
        else:
            final.append(e)
    return world, fm, ki5, final, excluded


def group_file_name(e):
    stem = Path(e["src_path"]).stem
    return f"{stem}__{e['members'][0].split('.', 1)[1]}"


STAMP = re.compile(rb"\d\d/\d\d/\d{4} \d\d:\d\d:\d\d\.\d{3}")


def fbx_stamp(data):
    """FBX SDK 寫在檔頭 SceneInfo 的 `Original|DateTime_GMT`（binary 與 ASCII 都是 ASCII 字串，位於前幾 KB；
    每次重新匯出都會變）。Lua 端以同一個樣式比對（MSP_KI5SkeletonTrim.lua 的 STAMP_PATTERN）。"""
    m = STAMP.search(data[:65536])
    return m.group().decode() if m else None


def mod_rel(src_path):
    """來源 FBX 相對於其 MOD 版本目錄（或 common）的路徑，給 Lua 的 getModFileReader 用。"""
    parts = Path(src_path).parts
    i = max(k for k, p in enumerate(parts) if p.lower() == "media")
    return "/".join(parts[i:])


SIG_MOD = 2147483647


def vehicle_sig(v):
    """車輛腳本零件模型的順序無關指紋：Σ hash("partId/modelId=file") mod 2^31-1；MSP_KI5SkeletonTrim.lua 的 vehicleSig 算法相同。
    Lua 讀不到 part 的 parent（VehicleScript.Part 沒有 getter），只能以零件／模型／檔案集合偵測上游改了車輛腳本。"""
    total = 0
    for pid, p in v.parts.items():
        for mid, m in p.models.items():
            h = 0
            for ch in f"{pid}/{mid or ''}={m['file'] or ''}":  # 沒命名的 model 區塊 Java 端 id 是 null（VehicleScript.java:693-697）
                h = (h * 31 + ord(ch)) % SIG_MOD  # Kahlua 的 string.byte 回傳字元碼（非 UTF-8 位元組）
            total = (total + h) % SIG_MOD
    return total


def users_of(world, members):
    """零件模型直接引用群組成員的車輛腳本。"""
    mem = set(members)
    return sorted(full for full, v in world.vehicles.items()
                  if any(full_name(f) in mem for p in v.parts.values() for _, f in part_models(world, p)))


def render_lua(groups, world):
    vehicles = sorted({x for e in groups for x in e["vehicles"]})
    out = ["-- 由 scripts/ki5trim/build.py 產生，請勿手改（MSP_KI5SkeletonTrim.lua 的資料表）。",
           "-- groups：上游 mod id、Workshop id、來源 FBX（MOD 內相對路徑）與檔頭 Original|DateTime_GMT、",
           "--         引用成員的車輛腳本、成員 { 模型腳本全名, 原 mesh, 新 mesh, static }",
           "-- vehicles：車輛腳本 → 零件模型指紋（build.py vehicle_sig）",
           "return {", "vehicles = {"]
    out += [f'    ["{x}"] = {vehicle_sig(world.vehicles[x])},' for x in vehicles]
    out += ["},", "groups = {"]
    for e in groups:
        out.append(f'    {{ mod = "{e["mod_id"]}", wid = "{e["wid"]}", src = "{e["src_rel"]}", stamp = "{e["stamp"]}",')
        out.append("      vehicles = { " + ", ".join(f'"{x}"' for x in e["vehicles"]) + " }, models = {")
        for n in e["members"]:
            new = f'{OUT_DIR_REL}/{e["file"]}|{e["selectors"][n]}'
            out.append(f'        {{ "{n}", "{e["old_mesh"][n]}", "{new}", false }},')
        out.append("    } },")
    out += ["},", "}"]
    return "\n".join(out) + "\n"


def sha(b):
    return hashlib.sha256(b).hexdigest()


def generate(game, workshop, prodmods):
    """回傳 ({models_X 下相對路徑: FBX bytes}, Lua 資料表文字, manifest dict)。骨頭數取自 MANIFEST（verify.py 寫回）。"""
    world, fm, ki5, groups, excluded = compute(game, workshop, prodmods)
    files, src_cache = {}, {}
    for e in groups:
        src = e["src_path"]
        if src not in src_cache:
            src_cache[src] = src.read_bytes()
        data = src_cache[src]
        if not fbx_stamp(data):
            excluded.append({k: e[k] for k in ("members", "source_rel", "wid", "mod_id")} | {"reason": "FBX 檔頭找不到時間戳，Lua 無法偵測上游更新"})
            e["skip"] = True
            continue
        doc = fbx.load(data)
        ix = FbxIndex(doc)
        keep, err = plan_keep(ix, [e["selectors"][n] for n in e["members"]], e["bone_names"])
        if err:
            excluded.append({k: e[k] for k in ("members", "source_rel", "wid", "mod_id")} | {"reason": err})
            e["skip"] = True
            continue
        why = neutral_reason(ix, set(e["bone_names"]))
        trimmed = trim(doc, keep)
        e["neutralized"] = {} if why else neutralize(trimmed, ix.models_by_name[NEUTRAL_NODE][0])
        e["neutral_skip"] = why
        out = trimmed.dumps()
        e["file"] = group_file_name(e)
        e["kept_nodes"] = sorted(name_of(o) for o in FbxIndex(fbx.load(out)).objs if o.name == "Model")
        e["sha256"] = sha(out)
        e["source_sha256"] = sha(data)
        e["stamp"] = fbx_stamp(data)
        e["src_rel"] = mod_rel(src)
        files[f"{OUT_DIR_REL}/{e['file']}.fbx"] = out
    groups = [e for e in groups if not e.get("skip")]
    names = [e["file"] for e in groups]
    if len(names) != len(set(names)):
        sys.exit("群組檔名重複")
    manifest = {
        "_doc": "scripts/ki5trim/build.py 產生（不含 KI5 內容，只有名稱、雜湊與實測數字）。groups[].file＝42/media/models_X/MSP_KI5Trim/<file>.fbx（本機產生、不進 git）；clips_used＝群組零件 anim 會播的 clip 名；neutralized＝歸零的 VehicleSkeleton 變換屬性與原值、neutral_skip＝不歸零的原因；bones_before／bones_after（PZ ImportedSkeleton 實測骨頭數）由 verify.py 寫回。",
        "groups": [{
            "file": e["file"], "mod_id": e["mod_id"], "wid": e["wid"], "source": e["source_rel"],
            "source_file": Path(e["src_path"]).relative_to(workshop).as_posix(), "source_stamp": e["stamp"],
            "source_sha256": e["source_sha256"], "sha256": e["sha256"], "members": e["members"],
            "selectors": [e["selectors"][n] for n in e["members"]], "old_mesh": [e["old_mesh"][n] for n in e["members"]],
            "named_bones": e["bone_names"], "clips_used": e["clips_used"], "kept_nodes": e["kept_nodes"],
            "neutralized": {NEUTRAL_NODE: e["neutralized"]} if e["neutralized"] else {}, "neutral_skip": e["neutral_skip"],
        } for e in groups],
        "excluded": sorted(({k: v for k, v in x.items() if k in ("members", "source_rel", "wid", "mod_id", "reason")} for x in excluded),
                           key=lambda x: x["members"]),
    }
    merge_verified(manifest)
    return files, render_lua(groups, world), manifest


def merge_verified(manifest):
    """沿用 MANIFEST 裡 verify.py 寫回的欄位（新檔與來源檔雜湊都相同才沿用）。"""
    old = json.loads(MANIFEST.read_text(encoding="utf-8")) if MANIFEST.exists() else {}
    prev = {g["file"]: g for g in old.get("groups", [])}
    for g in manifest["groups"]:
        p = prev.get(g["file"])
        if p and p.get("sha256") == g["sha256"] and p.get("source_sha256") == g["source_sha256"]:
            for k in VERIFIED_KEYS:
                if k in p:
                    g[k] = p[k]


def manifest_bytes(manifest):
    return (json.dumps(manifest, ensure_ascii=False, indent=1) + "\n").encode("utf-8")


def write_tree(files, lua, manifest):
    if OUT_MODELS.exists():
        shutil.rmtree(OUT_MODELS)
    for rel, data in files.items():
        p = OUT_MODELS.parent / rel
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_bytes(data)
    OUT_LUA.parent.mkdir(parents=True, exist_ok=True)
    OUT_LUA.write_bytes(lua.encode("utf-8"))
    MANIFEST.write_bytes(manifest_bytes(manifest))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--game", type=Path, default=first_dir(GAMES))
    ap.add_argument("--workshop", type=Path, default=first_dir(WORKSHOPS))
    ap.add_argument("--prodmods", type=Path, default=PRODMODS)
    ap.add_argument("--check", action="store_true")
    a = ap.parse_args()
    files, lua, manifest = generate(a.game, a.workshop, a.prodmods)
    if a.check:
        bad = [r for r, d in files.items() if not (OUT_MODELS.parent / r).is_file() or (OUT_MODELS.parent / r).read_bytes() != d]
        have = {p.relative_to(OUT_MODELS.parent).as_posix() for p in OUT_MODELS.rglob("*.fbx")} if OUT_MODELS.exists() else set()
        bad += sorted(have - set(files))
        if not OUT_LUA.is_file() or OUT_LUA.read_bytes() != lua.encode("utf-8"):
            bad.append(OUT_LUA.relative_to(ROOT).as_posix())
        if not MANIFEST.is_file() or MANIFEST.read_bytes() != manifest_bytes(manifest):
            bad.append(MANIFEST.relative_to(ROOT).as_posix())
        missing = [g["file"] for g in manifest["groups"] if "bones_after" not in g]
        if missing:
            bad.append(f"{len(missing)} 個群組還沒跑 verify.py（manifest 沒有骨頭數）")
        print(f"{len(files)} 個群組檔；" + (f"{len(bad)} 項與目前檔案不同：{bad[:5]}" if bad else "FBX、資料表、manifest 都一致"))
        return 1 if bad else 0
    write_tree(files, lua, manifest)
    print(f"寫出 {len(files)} 個群組檔（{sum(map(len, files.values())) / 1e6:.1f} MB）；排除 {len(manifest['excluded'])} 個群組")
    return 0


if __name__ == "__main__":
    sys.exit(main())
