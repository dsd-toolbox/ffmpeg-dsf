# SPDX-License-Identifier: MIT OR Apache-2.0
"""Check a DSF file against raw interleaved MSB-first DSD bytes:
verify_dsf.py FILE.dsf RAW CHANNELS
or check that a DSF file ends in the ID3v2 tag its header points to:
verify_dsf.py --tag FILE.dsf
or check header fields (channel type, channel count, bit rate, sample count):
verify_dsf.py --expect FILE.dsf ctype=5 nch=4 rate=2822400 count=8000
or write a copy of a DSF file with another sample count in its header:
verify_dsf.py --set-count IN.dsf OUT.dsf COUNT
or check that a non-seekable write has the audio of a seekable one and no sizes:
verify_dsf.py --pipe PIPE.dsf SEEKABLE.dsf"""
import struct, sys

FIELDS = ("ver", "fid", "ctype", "nch", "rate", "bps", "count", "bsz", "res")


def fields(d):
    return dict(zip(FIELDS, struct.unpack_from("<IIIIIIQII", d, 40)))


if sys.argv[1] == "--expect":
    f = fields(open(sys.argv[2], "rb").read())
    want = dict(a.split("=") for a in sys.argv[3:])
    bad = {k: (f[k], int(v)) for k, v in want.items() if f[k] != int(v)}
    assert not bad, f"{sys.argv[2]}: (found, expected) {bad}"
    print(f"OK {sys.argv[2]}: " + " ".join(f"{k}={f[k]}" for k in want))
    sys.exit(0)

if sys.argv[1] == "--set-count":
    d = bytearray(open(sys.argv[2], "rb").read())
    struct.pack_into("<Q", d, 64, int(sys.argv[4]))
    open(sys.argv[3], "wb").write(d)
    sys.exit(0)

if sys.argv[1] == "--pipe":
    p, s = open(sys.argv[2], "rb").read(), open(sys.argv[3], "rb").read()
    meta = struct.unpack_from("<Q", s, 20)[0]
    audio_end = meta or len(s)
    assert struct.unpack_from("<QQ", p, 12) == (0, 0), "file size or metadata offset set"
    assert fields(p)["count"] == 0, "sample count set"
    assert struct.unpack_from("<Q", p, 84)[0] == 12, "data size set"
    assert p[40:64] == s[40:64], "fmt chunk differs"
    assert len(p) >= audio_end and p[92:audio_end] == s[92:audio_end], "audio differs"
    print(f"OK {sys.argv[2]}: no sizes in the header, audio equal to {sys.argv[3]} ({audio_end - 92} bytes)")
    sys.exit(0)

if sys.argv[1] == "--tag":
    d = open(sys.argv[2], "rb").read()
    total, meta = struct.unpack_from("<QQ", d, 12)
    assert total == len(d) and meta and d[meta:meta + 3] == b"ID3", (total, len(d), meta)
    print(f"OK {sys.argv[2]}: ID3v2.{d[meta + 3]} tag at {meta}, file {total} bytes")
    sys.exit(0)

def rev(b):
    return int(f"{b:08b}"[::-1], 2)

REV = bytes(rev(i) for i in range(256))
dsf, raw, ch = sys.argv[1], sys.argv[2], int(sys.argv[3])
d = open(dsf, "rb").read()
r = open(raw, "rb").read()
assert d[:4] == b"DSD " and struct.unpack_from("<Q", d, 4)[0] == 28
total, meta = struct.unpack_from("<QQ", d, 12)
assert total == len(d), (total, len(d))
assert d[28:32] == b"fmt " and struct.unpack_from("<Q", d, 32)[0] == 52
ver, fid, ctype, nch, rate, bps, count, bsz, res = (fields(d)[k] for k in FIELDS)
assert (ver, fid, nch, bps, bsz, res) == (1, 0, ch, 1, 4096, 0), (ver, fid, nch, bps, bsz, res)
assert d[80:84] == b"data"
dsize = struct.unpack_from("<Q", d, 84)[0]
data = d[92:80 + dsize]
assert len(data) % (4096 * ch) == 0
assert meta == 0 or meta == 80 + dsize, meta
nbytes = count // 8
assert nbytes == len(r) // ch, (nbytes, len(r) // ch)
blocks = len(data) // (4096 * ch)
assert blocks == -(-nbytes // 4096)
for c in range(ch):
    plane = b"".join(data[(k * ch + c) * 4096:(k * ch + c + 1) * 4096] for k in range(blocks))
    assert plane[:nbytes] == bytes(REV[b] for b in r[c::ch][:nbytes]), f"channel {c} differs"
    assert not any(plane[nbytes:]), "padding not zero"
print(f"OK {dsf}: {ch} ch, type {ctype}, rate {rate}, {count} samples, {blocks} blocks, meta at {meta}")
