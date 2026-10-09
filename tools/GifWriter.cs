// Small animated GIF encoder for tools/make-gif.ps1: one global palette (median cut over all frames),
// no dithering, and every frame stores only the rectangle that changed since the previous one.
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;
using System.Runtime.InteropServices;

public static class GifWriter
{
    static int[] Pixels(Bitmap b)
    {
        var r = b.LockBits(new Rectangle(0, 0, b.Width, b.Height), ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
        var px = new int[b.Width * b.Height];
        Marshal.Copy(r.Scan0, px, 0, px.Length);
        b.UnlockBits(r);
        return px;
    }

    // median cut on a 6-bit-per-channel histogram
    class Box { public List<int> C; }
    static byte[] BuildPalette(Dictionary<int, int> hist)
    {
        var boxes = new List<Box> { new Box { C = new List<int>(hist.Keys) } };
        while (boxes.Count < 256)
        {
            Box best = null; int bestRange = 0, bestCh = 0;
            foreach (var b in boxes)
            {
                if (b.C.Count < 2) continue;
                for (int ch = 0; ch < 3; ch++)
                {
                    int lo = 255, hi = 0;
                    foreach (var c in b.C) { int v = (c >> (ch * 6)) & 63; if (v < lo) lo = v; if (v > hi) hi = v; }
                    if (hi - lo > bestRange) { bestRange = hi - lo; best = b; bestCh = ch; }
                }
            }
            if (best == null) break;
            int sh = bestCh * 6;
            best.C.Sort((a, b) => ((a >> sh) & 63).CompareTo((b >> sh) & 63));
            // split at the weighted median
            long total = 0; foreach (var c in best.C) total += hist[c];
            long acc = 0; int cut = 1;
            for (int i = 0; i < best.C.Count - 1; i++) { acc += hist[best.C[i]]; if (acc * 2 >= total) { cut = i + 1; break; } }
            var nb = new Box { C = best.C.GetRange(cut, best.C.Count - cut) };
            best.C = best.C.GetRange(0, cut);
            boxes.Add(nb);
        }
        var pal = new byte[256 * 3];
        for (int i = 0; i < boxes.Count; i++)
        {
            long r = 0, g = 0, bl = 0, n = 0;
            foreach (var c in boxes[i].C)
            {
                long w = hist[c]; n += w;
                bl += ((c & 63) * 4 + 2) * w; g += (((c >> 6) & 63) * 4 + 2) * w; r += (((c >> 12) & 63) * 4 + 2) * w;
            }
            pal[i * 3] = (byte)(r / n); pal[i * 3 + 1] = (byte)(g / n); pal[i * 3 + 2] = (byte)(bl / n);
        }
        return pal;
    }

    static readonly int[] Bayer = { 0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5 };
    public static int Spread = 12;                     // dithering strength, 0 = off
    static int Clamp(int v) { return v < 0 ? 0 : v > 255 ? 255 : v; }

    static int Key(int argb) { return ((argb >> 2) & 63) | (((argb >> 10) & 63) << 6) | (((argb >> 18) & 63) << 12); }

    public static string Write(string[] files, string outFile, int delayCs) { return Write(files, outFile, new int[] { delayCs }); }

    // delaysCs: per-frame delays in 1/100 s (the last value repeats for the remaining frames)
    public static string Write(string[] files, string outFile, int[] delaysCs)
    {
        var frames = new List<int[]>();
        int W = 0, H = 0;
        var hist = new Dictionary<int, int>();
        foreach (var f in files)
            using (var b = new Bitmap(f))
            {
                W = b.Width; H = b.Height;
                var px = Pixels(b);
                frames.Add(px);
                for (int i = 0; i < px.Length; i += 3) { int k = Key(px[i]); int n; hist.TryGetValue(k, out n); hist[k] = n + 1; }
            }
        var pal = BuildPalette(hist);
        var map = new Dictionary<int, byte>();
        Func<int, byte> nearest = k =>
        {
            byte idx; if (map.TryGetValue(k, out idx)) return idx;
            int b = (k & 63) * 4 + 2, g = ((k >> 6) & 63) * 4 + 2, r = ((k >> 12) & 63) * 4 + 2, best = 0, bd = int.MaxValue;
            for (int i = 0; i < 256; i++)
            {
                int dr = pal[i * 3] - r, dg = pal[i * 3 + 1] - g, db = pal[i * 3 + 2] - b;
                int d = dr * dr * 3 + dg * dg * 4 + db * db * 2;
                if (d < bd) { bd = d; best = i; }
            }
            map[k] = (byte)best; return (byte)best;
        };

        using (var fs = new FileStream(outFile, FileMode.Create))
        using (var w = new BinaryWriter(fs))
        {
            w.Write(System.Text.Encoding.ASCII.GetBytes("GIF89a"));
            w.Write((ushort)W); w.Write((ushort)H);
            w.Write((byte)0xF7); w.Write((byte)0); w.Write((byte)0);   // global table, 256 colours
            w.Write(pal);
            w.Write(new byte[] { 0x21, 0xFF, 0x0B }); w.Write(System.Text.Encoding.ASCII.GetBytes("NETSCAPE2.0"));
            w.Write(new byte[] { 3, 1, 0, 0, 0 });                     // loop forever
            byte[] prev = null;
            long bytesIdx = 0;
            int fi = 0;
            foreach (var px in frames)
            {
                int delayCs = delaysCs[Math.Min(fi++, delaysCs.Length - 1)];
                var idx = new byte[px.Length];
                for (int i = 0; i < px.Length; i++)
                {
                    // ordered (Bayer 4x4) dithering: the pattern is tied to the pixel, so still areas stay still
                    int d = (Bayer[((i / W) & 3) * 4 + ((i % W) & 3)] * 2 - 15) * Spread / 30;
                    int r = Clamp(((px[i] >> 16) & 255) + d), g = Clamp(((px[i] >> 8) & 255) + d), b = Clamp((px[i] & 255) + d);
                    idx[i] = nearest(Key((r << 16) | (g << 8) | b));
                }
                int x0 = 0, y0 = 0, x1 = W - 1, y1 = H - 1;
                if (prev != null)
                {
                    x0 = W; y0 = H; x1 = -1; y1 = -1;
                    for (int y = 0; y < H; y++)
                        for (int x = 0; x < W; x++)
                            if (idx[y * W + x] != prev[y * W + x])
                            { if (x < x0) x0 = x; if (x > x1) x1 = x; if (y < y0) y0 = y; if (y > y1) y1 = y; }
                    if (x1 < 0) { x0 = y0 = x1 = y1 = 0; }                // nothing changed: one pixel
                }
                int cw = x1 - x0 + 1, ch = y1 - y0 + 1;
                var crop = new byte[cw * ch];
                for (int y = 0; y < ch; y++) Array.Copy(idx, (y0 + y) * W + x0, crop, y * cw, cw);
                w.Write(new byte[] { 0x21, 0xF9, 4, 0x04, (byte)(delayCs & 0xFF), (byte)(delayCs >> 8), 0, 0 });
                w.Write((byte)0x2C); w.Write((ushort)x0); w.Write((ushort)y0); w.Write((ushort)cw); w.Write((ushort)ch); w.Write((byte)0);
                var lzw = Lzw(crop, 8);
                bytesIdx += lzw.Length;
                w.Write((byte)8);
                for (int p = 0; p < lzw.Length; p += 255) { int n = Math.Min(255, lzw.Length - p); w.Write((byte)n); w.Write(lzw, p, n); }
                w.Write((byte)0);
                prev = idx;
            }
            w.Write((byte)0x3B);
        }
        return frames.Count + " frames " + W + "x" + H;
    }

    // GIF LZW with variable code size, as in the classic compress: the code size grows right after the code
    // that makes the table outgrow it; a full table is reset with a clear code
    static byte[] Lzw(byte[] data, int minBits)
    {
        var ms = new MemoryStream();
        int clear = 1 << minBits, eoi = clear + 1, next = eoi + 1, bits = minBits + 1;
        bool reset = false;
        var dict = new Dictionary<int, int>();
        int acc = 0, nacc = 0;
        Action<int> emit = code =>
        {
            acc |= code << nacc; nacc += bits;
            while (nacc >= 8) { ms.WriteByte((byte)(acc & 0xFF)); acc >>= 8; nacc -= 8; }
            if (reset) { bits = minBits + 1; reset = false; }
            else if (next > (1 << bits) - 1 && bits < 12) bits++;
        };
        emit(clear);
        int cur = data[0];
        for (int i = 1; i < data.Length; i++)
        {
            int k = data[i], key = (cur << 8) | k;
            int code; if (dict.TryGetValue(key, out code)) { cur = code; continue; }
            emit(cur);
            if (next < 4096) dict[key] = next++;
            else { reset = true; emit(clear); dict.Clear(); next = eoi + 1; }
            cur = k;
        }
        emit(cur); emit(eoi);
        if (nacc > 0) ms.WriteByte((byte)(acc & 0xFF));
        return ms.ToArray();
    }
}