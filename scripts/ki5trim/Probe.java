package zombie.core.skinnedmodel.model.jassimp;

import jassimp.*;
import java.lang.reflect.Field;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.security.MessageDigest;
import java.util.*;
import org.lwjgl.util.vector.Matrix4f;
import zombie.core.skinnedmodel.HelperFunctions;
import zombie.core.skinnedmodel.animation.AnimationClip;
import zombie.core.skinnedmodel.animation.Keyframe;
import zombie.core.skinnedmodel.model.VertexBufferObject;

/**
 * 以遊戲本體的 jassimp＋PZ 自己的匯入類別（ProcessedAiScene／ImportedSkeleton／ImportedSkinnedMesh）處理 FBX。
 * 放在 PZ 的 package 內才能讀 package-private 欄位。
 *
 * 參數：[+STEP ...]（額外的 assimp 步驟）；標準輸入每行一個工作「檔案|mesh名」，每個工作輸出一行 JSON，
 *   每個值都取 IEEE754 原始位元的 SHA-256（逐位元比較用）。
 */
public class Probe {
    static final AiBuiltInWrapperProvider W = new AiBuiltInWrapperProvider();

    static String q(String s) { return "\"" + s.replace("\\", "\\\\").replace("\"", "\\\"").replace("\t", "\\t") + "\""; }

    static final class H {
        final MessageDigest md;
        H() { try { md = MessageDigest.getInstance("SHA-256"); } catch (Exception e) { throw new RuntimeException(e); } }
        H f(float v) { int b = Float.floatToRawIntBits(v); md.update(new byte[]{(byte) b, (byte) (b >> 8), (byte) (b >> 16), (byte) (b >> 24)}); return this; }
        H i(int v) { return f(Float.intBitsToFloat(v)); }
        H s(String v) { md.update(v.getBytes(java.nio.charset.StandardCharsets.UTF_8)); md.update((byte) 0); return this; }
        H m(Matrix4f m) { if (m == null) return s("null"); float[] a = new float[16]; java.nio.FloatBuffer fb = java.nio.FloatBuffer.wrap(a); m.store(fb); for (float x : a) f(x); return this; }
        H am(AiMatrix4f m) { if (m == null) return s("null"); for (int r = 0; r < 4; r++) for (int c = 0; c < 4; c++) f(m.get(r, c)); return this; }
        String hex() { byte[] d = md.digest(); StringBuilder sb = new StringBuilder(); for (int k = 0; k < 12; k++) sb.append(String.format("%02x", d[k])); return sb.toString(); }
    }

    static Object get(Object o, String name) throws Exception {
        Field f = o.getClass().getDeclaredField(name);
        f.setAccessible(true);
        return f.get(o);
    }

    static float[] worldOf(AiNode n) {
        Matrix4f acc = JAssImpImporter.getMatrixFromAiMatrix(n.getTransform(W));
        Matrix4f p = new Matrix4f();
        for (AiNode a = n.getParent(); a != null; a = a.getParent()) {
            JAssImpImporter.getMatrixFromAiMatrix(a.getTransform(W), p);
            Matrix4f.mul(p, acc, acc);
        }
        float[] out = new float[16];
        acc.store(java.nio.FloatBuffer.wrap(out));
        return out;
    }

    static Keyframe at(List<Keyframe> keys, float t) {
        Keyframe best = null;
        for (Keyframe k : keys) if (k.time <= t) best = k;
        return best != null ? best : keys.get(0);
    }

    static final EnumSet<AiPostProcessSteps> BASE_STEPS = EnumSet.of(AiPostProcessSteps.FIND_INSTANCES, AiPostProcessSteps.MAKE_LEFT_HANDED,
        AiPostProcessSteps.LIMIT_BONE_WEIGHTS, AiPostProcessSteps.TRIANGULATE, AiPostProcessSteps.OPTIMIZE_MESHES,
        AiPostProcessSteps.REMOVE_REDUNDANT_MATERIALS, AiPostProcessSteps.JOIN_IDENTICAL_VERTICES); // FileTask_LoadMesh.loadFBX（42.21.0 :79-90）

    public static void main(String[] args) throws Exception {
        Jassimp.setLibraryLoader(new JassimpLibraryLoader() { public void loadLibrary() { System.loadLibrary("jassimp64"); } });
        java.io.BufferedReader in = new java.io.BufferedReader(new java.io.InputStreamReader(System.in, java.nio.charset.StandardCharsets.UTF_8));
        java.io.PrintStream out = new java.io.PrintStream(new java.io.FileOutputStream(java.io.FileDescriptor.out), false, "UTF-8");
        EnumSet<AiPostProcessSteps> extra = EnumSet.noneOf(AiPostProcessSteps.class);
        for (String a : args) extra.add(AiPostProcessSteps.valueOf(a.substring(1)));
        Map<String, AiScene> scenes = new HashMap<>();
        for (String job; (job = in.readLine()) != null; ) {
            if (job.isBlank()) continue;
            int bar = job.lastIndexOf('|');
            String file = job.substring(0, bar), meshName = job.substring(bar + 1);
            StringBuilder sb = new StringBuilder("{\"job\":" + q(job));
            try {
                AiScene sc = scenes.get(file);
                if (sc == null) {
                    EnumSet<AiPostProcessSteps> steps = EnumSet.copyOf(BASE_STEPS);
                    steps.addAll(extra);
                    sc = Jassimp.importFile(file, steps);
                    scenes.clear();
                    scenes.put(file, sc);
                }
                ProcessedAiSceneParams p = ProcessedAiSceneParams.create();
                p.scene = sc;
                p.mode = JAssImpImporter.LoadMode.Normal;
                p.meshName = meshName;
                ProcessedAiScene pas = ProcessedAiScene.process(p);
                ImportedSkeleton sk = (ImportedSkeleton) get(pas, "skeleton");
                ImportedSkinnedMesh sm = (ImportedSkinnedMesh) get(pas, "skinnedMesh");
                if (sk == null || sm == null) throw new IllegalStateException("not a skinned mesh");
                String[] names = new String[sk.boneIndices.size()];
                for (Map.Entry<String, Integer> e : sk.boneIndices.entrySet()) names[e.getValue()] = e.getKey();
                AiNode root = sc.getSceneRoot(W);

                // ---- mesh（ImportedSkinnedMesh.vertices 就是上傳 GPU 的資料）
                VertexBufferObject.VertexArray va = sm.vertices;
                int nel = ((VertexBufferObject.VertexElement[]) get(va.format, "elements")).length;
                sb.append(",\"mesh\":{\"name\":" + q(sm.name) + ",\"nv\":" + va.numVertices + ",\"nel\":" + nel);
                String[] tags = {"pos", "nrm", "wgt", "bidx"};
                for (int e = 0; e < nel; e++) {
                    H h = new H();
                    int comps = e == 0 || e == 1 ? 3 : e < 4 ? 4 : 2;
                    for (int v = 0; v < va.numVertices; v++)
                        for (int c = 0; c < comps; c++) {
                            float x = va.getElementFloat(v, e, c);
                            // 骨頭索引換成骨頭名；權重 0 的槽位記成固定字串：vehicle.vert 只累加 weight > 0 的槽位
                            //（media/shaders/vehicle.vert 39-46），那裡的索引不影響畫面（ImportedSkinnedMesh 對空槽位填 0＝根骨頭）
                            if (e == 3) h.s(va.getElementFloat(v, 2, c) > 0f ? names[(int) x] : "<w0>"); else h.f(x);
                        }
                    sb.append(",\"" + (e < 4 ? tags[e] : "uv" + (e - 4)) + "\":" + q(h.hex()));
                }
                H he = new H();
                for (int x : sm.elements) he.i(x);
                sb.append(",\"idx\":" + q(he.hex()) + ",\"xfrm\":" + q(new H().m(sm.transform).hex()) + "}");

                // ---- skeleton（依 PZ 的骨頭順序；比較時以名稱對應）
                sb.append(",\"bones\":[");
                for (int b = 0; b < names.length; b++) {
                    int par = sk.skeletonHierarchy.get(b);
                    AiNode node = JAssImpImporter.FindNode(names[b], root);
                    H loc = new H(), wor = new H();
                    if (node != null) { loc.am(node.getTransform(W)); for (float x : worldOf(node)) wor.f(x); }
                    sb.append(b == 0 ? "" : ",").append("[" + q(names[b]) + "," + q(par < 0 ? "" : names[par])
                        + "," + q(new H().m(sk.bindPose.get(b)).m(sk.invBindPose.get(b)).hex())
                        + "," + q(new H().m(sk.skinOffsetMatrices.get(b)).hex())
                        + "," + q(loc.hex()) + "," + q(wor.hex()) + "]");
                }
                sb.append("]");

                // ---- 動畫：每個 clip 的時長、每根骨頭的 keyframe、每根骨頭在其＋祖先 keyframe 時刻的 model／skin 矩陣
                sb.append(",\"clips\":{");
                List<String> clipNames = new ArrayList<>(sk.clips.keySet());
                Collections.sort(clipNames);
                int ci = 0;
                for (String cn : clipNames) {
                    AnimationClip clip = sk.clips.get(cn);
                    Map<String, List<Keyframe>> per = new TreeMap<>();
                    for (Keyframe k : clip.getKeyframes()) per.computeIfAbsent(k.boneName, x -> new ArrayList<>()).add(k);
                    sb.append(ci++ == 0 ? "" : ",").append(q(cn) + ":{\"dur\":" + Float.floatToRawIntBits(clip.getDuration()) + ",\"keys\":{");
                    int bi = 0;
                    for (Map.Entry<String, List<Keyframe>> e : per.entrySet()) {
                        H h = new H();
                        for (Keyframe k : e.getValue()) {
                            h.f(k.time).f(k.position.x).f(k.position.y).f(k.position.z)
                             .f(k.rotation.x).f(k.rotation.y).f(k.rotation.z).f(k.rotation.w)
                             .f(k.scale.x).f(k.scale.y).f(k.scale.z);
                        }
                        sb.append(bi++ == 0 ? "" : ",").append(q(e.getKey()) + ":" + q(h.hex()));
                    }
                    sb.append("},\"skin\":{");
                    for (int b = 0; b < names.length; b++) {
                        // 取樣時刻＝本骨頭與所有祖先的 keyframe 時刻
                        TreeSet<Float> times = new TreeSet<>();
                        List<Integer> chain = new ArrayList<>();
                        for (int a = b; a >= 0; a = sk.skeletonHierarchy.get(a)) { chain.add(0, a); if (a == 0) break; }
                        for (int a : chain) if (per.containsKey(names[a])) for (Keyframe k : per.get(names[a])) times.add(k.time);
                        if (times.isEmpty()) times.add(0f);
                        H h = new H();
                        for (float t : times) {
                            Matrix4f model = new Matrix4f(), local = new Matrix4f(), tmp = new Matrix4f();
                            for (int a : chain) {
                                List<Keyframe> keys = per.get(names[a]);
                                local.setIdentity();
                                if (keys != null) { Keyframe k = at(keys, t); HelperFunctions.CreateFromQuaternionPositionScale(k.position, k.rotation, k.scale, local); }
                                // AnimationPlayer.updateModelTransformsInternal：model[b] = bone[b] × model[parent]
                                if (a == chain.get(0)) model.load(local); else { Matrix4f.mul(local, model, tmp); model.load(tmp); }
                            }
                            // AnimationPlayer.getSkinTransforms：skin = boneOffset × model
                            Matrix4f skin = new Matrix4f();
                            Matrix4f.mul(sk.skinOffsetMatrices.get(b), model, skin);
                            h.f(t).m(model).m(skin);
                        }
                        sb.append(b == 0 ? "" : ",").append(q(names[b]) + ":" + q(h.hex()));
                    }
                    sb.append("}}");
                }
                sb.append("}");
            } catch (Throwable t) {
                sb.append(",\"error\":" + q(t.toString()));
            }
            out.println(sb.append("}"));
        }
        out.flush();
    }
}
