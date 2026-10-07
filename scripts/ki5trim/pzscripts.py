"""照 42.21 的載入規則讀 vanilla＋MOD 清單的腳本，模擬 ModelScript／VehicleScript 的合併語意。

出處（42.21.0 反編譯快照）：
- 檔案清單與順序：ScriptManager.Load :1546-1640（vanilla 與 MOD 各自依相對路徑排序、`template_` 開頭的檔案優先，
  同一相對路徑只載一次，內容取 activeFileMap 的勝出者）；searchFolders :1333-1348（只收 .txt，路徑轉小寫）
- MOD 目錄：common＋≤遊戲版本的最高版本目錄（後者覆蓋前者）；MOD 之間後載入者覆蓋。
- 語法：ScriptParser.readBlock :11-45（值以逗號結尾才算數）、stripComments :51-88
- Model：ResetExisting（ScriptBucket :183-191），reset() 只清 mesh/static/boneWeights…（ModelScript :244-255），
  attachment 與 postProcess 會累積；Load :54-109
- Vehicle：attachment（LoadAttachment :664-690，bone 可被零件模型的 attachmentParent 引用）；無 ResetExisting，同名 body 依序 Load 合併（ScriptType :107-122）；元素依原始順序處理（VehicleScript.Load :286-330）；
  `template = T[/part/P]` 以整個 part 取代（copyPartsFrom :1233-1260）；`template! = T` 直接 Load 模板 body；
  `part A*` 萬用字元比對既有 part；LoadPart :909-988；LoadModel :693-721
- Template：最後一個同名定義勝出（ScriptBucket.Template.CreateFromTokenPP :297-323），script 延遲建立。
- 無模組前綴的名稱一律查 Base 模組（ScriptBucketCollection.getScript :72-89）。
"""
import copy
import fnmatch
import re
from pathlib import Path

PZ_VERSION = (42, 21)


# ---------- 檔案系統 ----------
def ver_key(name):
    try:
        return tuple(int(x) for x in name.split("."))
    except ValueError:
        return None


def mod_roots(mod_dir):
    """MOD 的 common 與 ≤PZ_VERSION 最高版本目錄（後者優先）。"""
    subs = [d for d in mod_dir.iterdir() if d.is_dir()]
    vers = [(ver_key(d.name), d) for d in subs if ver_key(d.name) and ver_key(d.name) <= PZ_VERSION]
    roots = [d for d in subs if d.name == "common"]
    if vers:
        roots.append(max(vers)[1])
    return roots


def read_modinfo(p):
    d = {}
    for line in p.read_text(encoding="utf-8", errors="replace").splitlines():
        if "=" in line:
            k, v = line.split("=", 1)
            d.setdefault(k.strip().lower(), v.strip())
    return d


def index_workshop(workshop, wids):
    """mod id → (wid, mod 目錄)。同 id 多處時取清單中先出現的 wid。"""
    out = {}
    for wid in wids:
        mods = workshop / wid / "mods"
        if not mods.is_dir():
            continue
        for m in sorted(mods.iterdir()):
            infos = sorted(m.glob("*/mod.info")) + ([m / "mod.info"] if (m / "mod.info").is_file() else [])
            for mi in infos:
                mid = read_modinfo(mi).get("id")
                if mid and mid not in out:
                    out[mid] = (wid, m)
    return out


class FileMap:
    """相對路徑（小寫，例如 media/scripts/x.txt）→ (實體檔, 來源 mod id, wid)。後加入者覆蓋。"""

    def __init__(self):
        self.files = {}
        self.vanilla = set()  # vanilla 擁有的相對路徑（ScriptManager 先載這一批）

    def add_tree(self, root, prefix, mod_id, wid):
        if not root.is_dir():
            return
        for p in root.rglob("*"):
            if p.is_file():
                rel = prefix + p.relative_to(root).as_posix().lower()
                self.files[rel] = (p, mod_id, wid)
                if mod_id == "pz-vanilla":
                    self.vanilla.add(rel)


def build_filemap(game, workshop, mod_ids, wids):
    idx = index_workshop(workshop, wids)
    fm = FileMap()
    for sub in ("scripts", "models_X"):
        fm.add_tree(game / "media" / sub, f"media/{sub.lower()}/", "pz-vanilla", None)
    missing = []
    for mid in mod_ids:
        if mid not in idx:
            missing.append(mid)
            continue
        wid, mdir = idx[mid]
        for r in mod_roots(mdir):
            for sub in ("scripts", "models_X"):
                fm.add_tree(r / "media" / sub, f"media/{sub.lower()}/", mid, wid)
    return fm, idx, missing


def script_load_list(fm):
    """ScriptManager.Load 的檔案順序。"""
    def key(rel):
        name = rel.rsplit("/", 1)[-1]
        return (0 if name.startswith("template_") else 1, rel)
    scripts = [r for r in fm.files if r.startswith("media/scripts/") and r.endswith(".txt")]
    vanilla = sorted((r for r in scripts if r in fm.vanilla), key=key)
    mods = sorted((r for r in scripts if r not in fm.vanilla), key=key)
    return vanilla + mods


# ---------- ScriptParser ----------
def strip_comments(s):
    while True:
        end = s.rfind("*/")
        if end == -1:
            return s
        start = s.rfind("/*", 0, end)
        if start == -1:
            return s
        inner = s.rfind("*/", 0, end)
        while inner > start:
            inner_start = start
            start = s.rfind("/*", 0, start - 1)
            if start == -1:
                return s
            inner = s.rfind("*/", 0, inner_start - 1)
        s = s[:start] + s[end + 2:]


class Block:
    __slots__ = ("type", "id", "elements", "header")

    def __init__(self, type_, id_, header=""):
        self.type, self.id, self.elements, self.header = type_, id_, [], header

    @property
    def values(self):
        return [e for e in self.elements if isinstance(e, tuple)]

    @property
    def children(self):
        return [e for e in self.elements if isinstance(e, Block)]


def read_block(s, start, block):
    i = start
    n = len(s)
    while i < n:
        ch = s[i]
        if ch == "{":
            header = s[start:i].strip()
            ss = header.split()
            child = Block(ss[0] if ss else "", ss[1] if len(ss) > 1 else None, header)
            block.elements.append(child)
            i = read_block(s, i + 1, child)
            start = i
            continue
        if ch == "}":
            return i + 1
        if ch == ",":
            k, eq, v = s[start:i].partition("=")
            block.elements.append((k.strip(), v.strip() if eq else ""))
            start = i + 1
        i += 1
    return i


def parse(text):
    root = Block("", None)
    read_block(strip_comments(text), 0, root)
    return root


# ---------- Model ----------
class ModelScript:
    def __init__(self, full):
        self.full = full
        self.mesh = None
        self.static = True
        self.post_process = None
        self.attachments = {}  # id → bone
        self.bone_weights = []
        self.animations_mesh = None
        self.bodies = []  # (rel, wid)

    def reset(self):
        self.mesh, self.static, self.bone_weights = None, True, []

    def load(self, blk):
        for c in blk.children:
            if c.type == "attachment" and c.id:
                for k, v in c.values:
                    if k == "bone":
                        self.attachments[c.id] = v
                self.attachments.setdefault(c.id, None)
        for k, v in blk.values:
            kl = k.lower()
            if kl == "mesh":
                self.mesh = v
            elif kl == "static":
                self.static = v.lower() == "true"
            elif kl == "postprocess":
                self.post_process = v
            elif kl == "boneweight":
                ss = v.split()
                if len(ss) == 2:
                    self.bone_weights.append(ss[0])
            elif kl == "animationsmesh":
                self.animations_mesh = v or None


# ---------- Vehicle ----------
class Part:
    def __init__(self, pid):
        self.id, self.parent, self.models = pid, None, {}  # models: id → {file, attachmentParent, attachmentSelf}
        self.anims = {}  # anim id → clip 名（LoadAnim :822-851）
        self.lua = {}  # lua { init = NS.Init.Key, ... }（每個 lua 區塊整個取代）


class Vehicle:
    def __init__(self, full):
        self.full, self.parts, self.attachments = full, {}, {}  # parts 保留插入順序；attachments: id → bone


def _model_into(models, blk):
    m = models.setdefault(blk.id, {"file": None, "attachmentParent": None, "attachmentSelf": None})
    for k, v in blk.values:
        if k == "file":
            m["file"] = v
        elif k == "attachmentParent":
            m["attachmentParent"] = v or None
        elif k == "attachmentSelf":
            m["attachmentSelf"] = v or None


def _load_part(veh, blk):
    part = veh.parts.get(blk.id)
    if part is None:
        part = veh.parts[blk.id] = Part(blk.id)
    for k, v in blk.values:
        if k == "parent":
            part.parent = v or None
    for c in blk.children:
        if c.type == "model":
            _model_into(part.models, c)
        elif c.type == "lua":
            part.lua = dict(c.values)
        elif c.type == "anim" and c.id:
            for k, v in c.values:
                if k == "anim":
                    part.anims[c.id] = v


class World:
    def __init__(self):
        self.models, self.vehicles, self.templates = {}, {}, {}
        self._tmpl_cache = {}
        self.vehicle_bodies = {}  # full → [(module, block, rel)]
        self.item_part_models = []  # (partId, partModelId, modelId)

    def template_script(self, name):
        full = name if "." in name else "Base." + name
        if full not in self.templates:
            return None
        if full not in self._tmpl_cache:
            v = Vehicle(full)
            self._tmpl_cache[full] = v
            self._load_vehicle(v, self.templates[full])
        return self._tmpl_cache[full]

    def _load_vehicle(self, veh, blk):
        for e in blk.elements:
            if isinstance(e, tuple):
                k, v = e
                if k == "template":
                    self._template(veh, v)
                elif k == "template!":
                    t = self.templates.get(v if "." in v else "Base." + v)
                    if t is not None:
                        self._load_vehicle(veh, t)
            elif e.type == "attachment" and e.id:
                for k, v in e.values:
                    if k == "bone":
                        veh.attachments[e.id] = v
            elif e.type == "part":
                if e.id and "*" in e.id:
                    for pid in list(veh.parts):
                        if fnmatch.fnmatchcase(pid, e.id):
                            b = Block("part", pid)
                            b.elements = e.elements
                            _load_part(veh, b)
                elif e.id:
                    _load_part(veh, e)

    def _template(self, veh, spec):
        ss = [x.strip() for x in spec.split("/")]
        src = self.template_script(ss[0])
        if src is None:
            return
        if len(ss) == 1:
            for pid, p in src.parts.items():
                veh.parts[pid] = copy.deepcopy(p)
        elif len(ss) == 3 and ss[1] == "part":
            if ss[2] == "*":
                for pid, p in src.parts.items():
                    veh.parts[pid] = copy.deepcopy(p)
            elif ss[2] in src.parts:
                veh.parts[ss[2]] = copy.deepcopy(src.parts[ss[2]])

    def model(self, name):
        return self.models.get(name if "." in name else "Base." + name)


def load_world(fm):
    w = World()
    model_bodies = {}
    for rel in script_load_list(fm):
        path, mod_id, wid = fm.files[rel]
        root = parse(path.read_text(encoding="utf-8", errors="replace"))
        for mod_blk in root.children:
            if mod_blk.type != "module" or not mod_blk.id:
                continue
            mod = mod_blk.id
            for b in mod_blk.children:
                if b.type == "model" and b.id:
                    model_bodies.setdefault(f"{mod}.{b.id}", []).append((b, rel, wid, mod_id))
                elif b.type == "vehicle" and b.id:
                    w.vehicle_bodies.setdefault(f"{mod}.{b.id}", []).append((b, rel, wid, mod_id))
                elif b.type == "template":
                    ss = b.header.split()
                    if len(ss) == 3 and ss[1] == "vehicle":
                        w.templates[f"{mod}.{ss[2]}"] = b
                elif b.type == "item":
                    for k, v in b.values:
                        if k.strip().lower() == "vehiclepartmodel":
                            ss = v.split()
                            if len(ss) == 3:
                                w.item_part_models.append(tuple(ss))
    for full, bodies in model_bodies.items():
        m = ModelScript(full)
        for i, (b, rel, wid, mod_id) in enumerate(bodies):
            if i:
                m.reset()
            m.load(b)
            m.bodies.append((rel, wid, mod_id))
        w.models[full] = m
    for full, bodies in w.vehicle_bodies.items():
        v = Vehicle(full)
        for b, rel, wid, mod_id in bodies:
            w._load_vehicle(v, b)
        w.vehicles[full] = v
    return w


def mesh_file(fm, mesh):
    """`path|selector` → (FileMap 項目, rel, selector)。PZ 以 media/models_x/<小寫>.fbx 查（ModelScript.checkMesh）。"""
    path, _, sel = mesh.partition("|")
    rel = "media/models_x/" + path.strip().lower().replace("\\", "/")
    for ext in (".fbx", ".x", ".glb", ".gltf"):
        if rel + ext in fm.files:
            return fm.files[rel + ext], rel + ext, sel or None
    return None, rel, sel or None
