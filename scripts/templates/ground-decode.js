// ground-decode.js - unpacks a zone's ground heights for the ground sandbox
// (issue 617e16c). Inlined into docs/HTML/ground-sandbox.html by
// scripts/generate-ground-sandbox-page, and run alone by
// scripts/test-ground-decode (Node), so the page and its test share one copy.
//
// The heights arrive as scripts/generate-ground-sandbox-data packs them:
// base64 text of gzip (no file name, so a 10-byte header) of 16-bit
// little-endian differences of heights in tenths of a yard, -32768 for "no
// ground". This undoes each step: base64 to bytes, the gzip header skipped,
// the deflate stream inflated (synchronously: a browser's own gunzip only
// answers later, after a headless screenshot may already have been taken),
// the differences summed back with 16-bit wrap-around.

// {{{ inflate: a deflate stream (RFC 1951) into a buffer of known size
// After Mark Adler's puff.c: Huffman codes decoded a bit at a time from
// per-length counts and a symbol list ordered by length.
const LBASE = [3,4,5,6,7,8,9,10,11,13,15,17,19,23,27,31,35,43,51,59,67,83,99,115,131,163,195,227,258];
const LEXT  = [0,0,0,0,0,0,0,0,1,1,1,1,2,2,2,2,3,3,3,3,4,4,4,4,5,5,5,5,0];
const DBASE = [1,2,3,4,5,7,9,13,17,25,33,49,65,97,129,193,257,385,513,769,1025,1537,2049,3073,4097,6145,8193,12289,16385,24577];
const DEXT  = [0,0,0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8,9,9,10,10,11,11,12,12,13,13];
const CLORDER = [16,17,18,0,8,7,9,6,10,5,11,4,12,3,13,2,14,1,15];
function inflate(src, start, outLen) {
  const out = new Uint8Array(outLen);
  let pos = start, buf = 0, cnt = 0, op = 0;
  const bits = n => {
    while (cnt < n) { if (pos >= src.length) throw new Error("inflate: the stream ended early"); buf |= src[pos++] << cnt; cnt += 8; }
    const v = buf & ((1 << n) - 1); buf >>>= n; cnt -= n; return v;
  };
  const table = (lengths, n) => {
    const counts = new Uint16Array(16), offs = new Uint16Array(16), syms = new Uint16Array(n);
    for (let i = 0; i < n; i++) counts[lengths[i]]++;
    counts[0] = 0;
    for (let i = 1; i < 16; i++) offs[i] = offs[i - 1] + counts[i - 1];
    for (let i = 0; i < n; i++) if (lengths[i]) syms[offs[lengths[i]]++] = i;
    return { counts, syms };
  };
  const decode = t => {
    let code = 0, first = 0, index = 0;
    for (let len = 1; len < 16; len++) {
      code |= bits(1);
      const c = t.counts[len];
      if (code - c < first) return t.syms[index + (code - first)];
      index += c; first += c; first <<= 1; code <<= 1;
    }
    throw new Error("inflate: a code no table holds");
  };
  let fixedLit = null, fixedDist = null;
  for (let last = 0; !last; ) {
    last = bits(1);
    const type = bits(2);
    if (type === 0) {                                      // stored: byte-aligned, a length and its complement
      buf = 0; cnt = 0;
      const len = src[pos] | src[pos + 1] << 8; pos += 4;
      out.set(src.subarray(pos, pos + len), op); pos += len; op += len;
      continue;
    }
    let lit, dist;
    if (type === 1) {                                      // the fixed codes
      if (!fixedLit) {
        const l = new Uint8Array(288);
        l.fill(8, 0, 144); l.fill(9, 144, 256); l.fill(7, 256, 280); l.fill(8, 280, 288);
        fixedLit = table(l, 288); fixedDist = table(new Uint8Array(30).fill(5), 30);
      }
      lit = fixedLit; dist = fixedDist;
    } else if (type === 2) {                               // codes sent with the block
      const nlen = bits(5) + 257, ndist = bits(5) + 1, ncode = bits(4) + 4;
      const cl = new Uint8Array(19);
      for (let i = 0; i < ncode; i++) cl[CLORDER[i]] = bits(3);
      const clt = table(cl, 19), lengths = new Uint8Array(nlen + ndist);
      for (let i = 0; i < nlen + ndist; ) {
        const sym = decode(clt);
        if (sym < 16) lengths[i++] = sym;
        else {
          let rep, val = 0;
          if (sym === 16) { if (!i) throw new Error("inflate: a repeat with nothing before it"); val = lengths[i - 1]; rep = 3 + bits(2); }
          else if (sym === 17) rep = 3 + bits(3);
          else rep = 11 + bits(7);
          while (rep--) lengths[i++] = val;
        }
      }
      lit = table(lengths.subarray(0, nlen), nlen); dist = table(lengths.subarray(nlen), ndist);
    } else throw new Error("inflate: block type 3 is not deflate");
    for (;;) {
      let sym = decode(lit);
      if (sym < 256) { out[op++] = sym; continue; }
      if (sym === 256) break;
      sym -= 257;
      const len = LBASE[sym] + bits(LEXT[sym]);
      const ds = decode(dist), d = DBASE[ds] + bits(DEXT[ds]);
      for (let k = 0; k < len; k++, op++) out[op] = out[op - d];
    }
  }
  if (op !== outLen) throw new Error(`inflate: ${op} bytes out, ${outLen} expected`);
  return out;
}
// }}}

// {{{ decodeHeights: the packed text into heights (Int16Array, tenths of a yard)
function decodeHeights(b64, count) {
  const bin = typeof atob === "function" ? atob(b64) : Buffer.from(b64, "base64").toString("latin1");
  const src = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) src[i] = bin.charCodeAt(i);
  if (src[0] !== 0x1f || src[1] !== 0x8b || src[2] !== 8) throw new Error("decodeHeights: not gzip (deflate)");
  if (src[3] !== 0) throw new Error("decodeHeights: the gzip header carries extras (made without -n?)");
  const raw = inflate(src, 10, count * 2);
  const diffs = new Int16Array(raw.buffer), out = new Int16Array(count);
  let prev = 0;
  for (let i = 0; i < count; i++) { prev = (prev + diffs[i]) << 16 >> 16; out[i] = prev; }
  return out;
}
// }}}

if (typeof module !== "undefined") module.exports = { inflate, decodeHeights };
