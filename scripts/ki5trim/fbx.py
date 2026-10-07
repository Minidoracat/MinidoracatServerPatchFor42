"""FBX 節點樹的讀寫，裁剪後只重組結構、不重算任何數值。

- Binary（7100～7700）：屬性保留原始位元組（陣列維持原壓縮資料），只重算紀錄長度與偏移。
- ASCII：每個節點保留原文（含前置空白／註解），刪節點就是刪掉那段原文。
"""
import re
import struct

MAGIC = b"Kaydara FBX Binary  \x00\x1a\x00"
_SCALAR = {b"Y": 2, b"C": 1, b"I": 4, b"F": 4, b"D": 8, b"L": 8}
_FMT = {b"Y": "<h", b"C": "<?", b"I": "<i", b"F": "<f", b"D": "<d", b"L": "<q"}


class Node:
    __slots__ = ("name", "props", "raw_props", "children", "has_null")

    def __init__(self, name, props, raw_props, children, has_null):
        self.name, self.props, self.raw_props, self.children, self.has_null = name, props, raw_props, children, has_null

    def find(self, name):
        return next((c for c in self.children if c.name == name), None)

    def __repr__(self):
        return f"Node({self.name!r}, {self.props[:3]!r}, {len(self.children)} children)"


def _props(buf, pos, n):
    """回傳 (值列表, 每個屬性的原始位元組)。陣列只回 None（不解壓，保留原位元組）。"""
    vals, raws = [], []
    for _ in range(n):
        start, t = pos, buf[pos:pos + 1]
        pos += 1
        if t in _SCALAR:
            vals.append(struct.unpack_from(_FMT[t], buf, pos)[0])
            pos += _SCALAR[t]
        elif t in (b"S", b"R"):
            ln, = struct.unpack_from("<I", buf, pos)
            pos += 4
            v = bytes(buf[pos:pos + ln])
            vals.append(v if t == b"R" else v.decode("utf-8", "surrogateescape"))
            pos += ln
        elif t in (b"f", b"d", b"l", b"i", b"b"):
            _, _, clen = struct.unpack_from("<III", buf, pos)
            pos += 12 + clen
            vals.append(None)
        else:
            raise ValueError(f"unknown FBX property type {t!r} at {start}")
        raws.append(bytes(buf[start:pos]))
    return vals, raws


class Doc:
    def __init__(self, data):
        if data[:23] != MAGIC:
            raise ValueError("not a binary FBX")
        self.version, = struct.unpack_from("<I", data, 23)
        # 7500 起紀錄標頭的三個長度欄位是 u64，之前是 u32
        self.hdr, self.nul = ("<QQQ", 25) if self.version >= 7500 else ("<III", 13)
        self.head = bytes(data[:27])
        self.roots, pos = [], 27
        while True:
            node, pos = self._read(data, pos)
            if node is None:
                break
            self.roots.append(node)
        # footer：16 bytes id＋(4＋16－id 起點 mod 16) 個 0、version＋120 個 0＋16 bytes magic
        self.foot_id, self.foot_end = bytes(data[pos:pos + 16]), bytes(data[-140:])

    def _read(self, buf, pos):
        end, nprops, plen = struct.unpack_from(self.hdr, buf, pos)
        h = self.nul
        if end == 0:
            return None, pos + h
        nlen = buf[pos + h - 1]
        name = bytes(buf[pos + h:pos + h + nlen]).decode("ascii")
        p = pos + h + nlen
        vals, raws = _props(buf, p, nprops)
        if sum(map(len, raws)) != plen:
            raise ValueError(f"property length mismatch in {name}")
        p += plen
        children, has_null = [], False
        while p < end:
            child, p = self._read(buf, p)
            if child is None:
                has_null = True
                break
            children.append(child)
        if p != end:
            raise ValueError(f"record {name} ends at {p}, expected {end}")
        return Node(name, vals, raws, children, has_null), end

    def root(self, name):
        return next((n for n in self.roots if n.name == name), None)

    def dumps(self):
        out = bytearray(self.head)
        for n in self.roots:
            _write(out, n, self.hdr, self.nul)
        out += b"\0" * self.nul
        pad = 16 - len(out) % 16  # 以 footer id 的起點計算（實測 KI5 各版本 FBX 皆如此）
        out += self.foot_id + b"\0" * (4 + pad)
        out += self.foot_end
        return bytes(out)


def _write(out, n, hdr, nul):
    start = len(out)
    props = b"".join(n.raw_props)
    name = n.name.encode("ascii")
    out += struct.pack(hdr, 0, len(n.raw_props), len(props)) + bytes([len(name)]) + name + props
    for c in n.children:
        _write(out, c, hdr, nul)
    if n.children or n.has_null:
        out += b"\0" * nul
    struct.pack_into(hdr[:2], out, start, len(out))


def set_count(node, n):
    """改寫單一整數屬性（Pose 的 NbPoseNodes）。"""
    if isinstance(node, ANode):
        node.head = node.head[:node.head.index(":") + 1] + f" {n}"
    else:
        t = node.raw_props[0][:1]
        node.raw_props = [t + n.to_bytes(4 if t == b"I" else 8, "little", signed=True)]
    node.props = [n]


# ---------- ASCII ----------
_TOK = re.compile(r'\s+|;[^\n]*|"[^"]*"|[{},]|[^\s{},;":]+:|[^\s{},;"]+')
_INT = re.compile(r"[-+]?\d+$")


class ANode:
    """pre＝與前一個兄弟節點之間的原文；head＝鍵到 `{`（無子節點時到最後一個值）；tail＝最後一個子節點後到 `}`。"""
    __slots__ = ("name", "props", "children", "pre", "head", "tail")

    def __init__(self, name, props, pre, head):
        self.name, self.props, self.children, self.pre, self.head, self.tail = name, props, [], pre, head, ""

    def find(self, name):
        return next((c for c in self.children if c.name == name), None)

    def dump(self, out):
        out.append(self.pre)
        out.append(self.head)
        for c in self.children:
            c.dump(out)
        out.append(self.tail)


def _value(tok):
    if tok.startswith('"'):
        s = tok[1:-1]
        cls, sep, name = s.partition("::")
        return f"{name}\x00\x01{cls}" if sep else s  # 與 binary 的名稱格式一致
    if _INT.match(tok):
        return int(tok)
    try:
        return float(tok)
    except ValueError:
        return None  # `*N` 陣列長度等


class AsciiDoc:
    def __init__(self, text):
        self.text = text
        toks = [(m.start(), m.end()) for m in _TOK.finditer(text) if not text[m.start()].isspace() and text[m.start()] != ";"]
        self.roots, i, last = [], 0, 0
        while i < len(toks):
            node, i, last = self._node(toks, i, last)
            self.roots.append(node)
        self.tail = text[last:]

    def _node(self, toks, i, prev_end):
        t = self.text
        s, e = toks[i]
        if not t[s:e].endswith(":"):
            raise ValueError(f"expected key at {s}: {t[s:e]!r}")
        name, props = t[s:e - 1], []
        i += 1
        end = e
        while i < len(toks):
            v = t[toks[i][0]:toks[i][1]]
            if v in ("{", "}") or (v.endswith(":") and not v.startswith('"')):
                break
            if v != ",":
                props.append(_value(v))
            end = toks[i][1]
            i += 1
        node = ANode(name, props, t[prev_end:s], None)
        if i < len(toks) and t[toks[i][0]] == "{":
            end = toks[i][1]
            node.head = t[s:end]
            i += 1
            while t[toks[i][0]] != "}":
                child, i, end = self._node(toks, i, end)
                node.children.append(child)
            node.tail = t[end:toks[i][1]]
            end = toks[i][1]
            i += 1
        else:
            node.head = t[s:end]
        return node, i, end

    def root(self, name):
        return next((n for n in self.roots if n.name == name), None)

    def dumps(self):
        out = []
        for n in self.roots:
            n.dump(out)
        out.append(self.tail)
        return "".join(out).encode("utf-8", "surrogateescape")


def load(data):
    if data[:23] == MAGIC:
        return Doc(data)
    return AsciiDoc(data.decode("utf-8", "surrogateescape"))


if __name__ == "__main__":
    import sys
    from pathlib import Path
    for f in sys.argv[1:]:
        data = Path(f).read_bytes()
        d = load(data)
        same = d.dumps() == data
        print(f, getattr(d, "version", "ascii"), "roundtrip", "OK" if same else "DIFF")
