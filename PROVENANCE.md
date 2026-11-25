# Provenance

- `patches/`: changes to FFmpeg (LGPL-2.1-or-later), written for FFmpeg and licensed as
  FFmpeg is. They modify and extend FFmpeg files and so contain FFmpeg context lines. FFmpeg
  code appears only in `patches/`; no other file in this repository contains or is derived
  from FFmpeg code.
- DSF layout (header chunks, 4096-byte blocks, LSB-first, zero padding, ID3v2 at the end):
  from the DSF format as read by FFmpeg's DSF demuxer and as written by dsd2pcm's DSF
  writer (MIT OR Apache-2.0); no code copied, the muxer is written against FFmpeg's
  APIs.
- `libdsdupsample` wraps libdsd_upsample's C API (`dsd_upsample.h`, MIT OR Apache-2.0),
  which is compatible with FFmpeg's LGPL; the library stays a separate external
  library enabled by `--enable-libdsdupsample`.
- Code outside `patches/` (`pkgconfig/`, `test/`, `.github/`): MIT OR Apache-2.0. The
  documentation (README.md, `docs/` including the icon in `docs/assets/`): CC BY 4.0.
- FFmpeg itself is not in this repository; the Quick start fetches it.
