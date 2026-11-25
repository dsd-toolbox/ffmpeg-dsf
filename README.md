<img src="https://raw.githubusercontent.com/dsd-toolbox/ffmpeg-dsf/main/docs/assets/icon-256.png" alt="" width="96">

# ffmpeg-dsf

[![CI](https://github.com/dsd-toolbox/ffmpeg-dsf/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/dsd-toolbox/ffmpeg-dsf/actions/workflows/ci.yml)
[![License: LGPL-2.1-or-later (patches), MIT OR Apache-2.0](https://img.shields.io/badge/license-LGPL--2.1--or--later%20%2F%20MIT%20OR%20Apache--2.0-blue)](PROVENANCE.md)

Patches that add a DSF muxer and a PCM to DSD encoder (DSD64, DSD128, DSD256, via
[dsd-upsample](https://github.com/dsd-toolbox/dsd-upsample-rs)) to FFmpeg, for anyone who
wants DSD files from FFmpeg's inputs and filters. The DSF output is byte-identical to the
dsd-upsample command-line tool's of the same library release for the same settings, except
for two header fields ([details](docs/user-guide.md#same-bytes-as-the-command-line-tool)):
the sample count when the output ends inside a byte, and the channel type of 3.1 input; the
patches are not part of FFmpeg yet, so you apply them to FFmpeg's source.

## Platforms

| System | How | Guide |
|---|---|---|
| Linux, x86_64 | Apply the patches to FFmpeg's source, build with `--enable-libdsdupsample`; tested in CI (Ubuntu 24.04) | [Quick start](#quick-start) · [Linux](docs/install/linux.md) |
| macOS, Windows | The same source build may work there; neither the library nor these patches are tested there yet | [Other systems](docs/install/linux.md#other-systems) |

Source patches only: nothing to download or sign. The DSF muxer needs no external
library.

## Quick start

On Linux with git, Rust 1.83 or later, gcc, make, pkg-config and diffutils, in an empty folder:

```sh
git clone https://github.com/dsd-toolbox/ffmpeg-dsf.git
git clone --depth 1 --branch v0.1.0 https://github.com/dsd-toolbox/dsd-upsample-rs.git
cargo build --release -p dsd-upsample-capi --manifest-path dsd-upsample-rs/Cargo.toml
git init -q ffmpeg
git -C ffmpeg fetch --depth 1 https://github.com/FFmpeg/FFmpeg.git 05c674c9132eb13e65e3fb6e9b4cf1cad1219fd5
git -C ffmpeg checkout -q FETCH_HEAD
git -C ffmpeg apply ../ffmpeg-dsf/patches/0001-avformat-dsfdec-fix-the-channel-layout-of-channel-ty.patch ../ffmpeg-dsf/patches/0002-avformat-add-DSF-muxer.patch ../ffmpeg-dsf/patches/0003-avcodec-add-PCM-to-DSD-encoding-via-libdsd_upsample.patch
cd ffmpeg
PKG_CONFIG_PATH=../ffmpeg-dsf/pkgconfig ./configure --disable-everything --disable-doc --disable-x86asm --enable-libdsdupsample --enable-encoder=libdsdupsample --enable-decoder=pcm_s16le,dsd_lsbf_planar --enable-muxer=dsf --enable-demuxer=dsf --enable-protocol=file --enable-indev=lavfi --enable-filter=sine,aresample,aformat,anull,abuffer,abuffersink
make -j8
./ffmpeg -f lavfi -i sine=frequency=1000:sample_rate=44100:duration=5 -c:a libdsdupsample -dsd_rate dsd256 tone.dsf
./ffprobe tone.dsf
```

The last two lines write a 5-second DSD256 test tone and show its format. This is a
minimal FFmpeg build; for a full one see [Linux](docs/install/linux.md), and for the encoder
options [options](docs/options.md).

## Documentation

- [Documentation index](docs/README.md)
- [Install on Linux](docs/install/linux.md): minimal and full builds, pkg-config
- [User guide](docs/user-guide.md): the patches, converting to DSF, byte-identical output
- [Options](docs/options.md): encoder and DSF muxer options
- [Design notes](docs/design.md)
- [Development](docs/development.md): CI, FATE tests, byte comparison with the command-line
  tool
- [Contributing](CONTRIBUTING.md)

## Licence and credits

**Patches** (`patches/`) are contributions to FFmpeg under LGPL-2.1-or-later, FFmpeg's
licence. **Other code** (`pkgconfig/`, `test/`, `.github/`) is dual-licensed under either of the
Apache License, Version 2.0 ([LICENSE-APACHE](LICENSE-APACHE)) or the MIT licence
([LICENSE-MIT](LICENSE-MIT)), at your option. [NOTICE](NOTICE) holds the attributions to keep
with it. Unless you state otherwise, any contribution you intentionally submit for inclusion in
this work is licensed as above, without any additional terms or conditions.

**Documentation, measurement data and creative assets** are licensed under [CC BY
4.0](https://creativecommons.org/licenses/by/4.0/)
([LICENSES/CC-BY-4.0.txt](LICENSES/CC-BY-4.0.txt)): every README (this one included), the pages
under `docs/` and the icons under `docs/assets/`. Code examples and commands in these files may
also be used under the code licence. Not covered: the patches in `patches/` (cover letter
included), which are FFmpeg contributions under LGPL-2.1-or-later, and facts cited from other
sources (for example the DSF specification), which keep their own terms. Suggested attribution:
"ffmpeg-dsf documentation, the ffmpeg-dsf authors, https://github.com/dsd-toolbox/ffmpeg-dsf,
CC BY 4.0". Contributions to these files are licensed the same way.
[CITATION.cff](CITATION.cff) says how to cite the software.

Credits:
- [FFmpeg](https://ffmpeg.org) (LGPL-2.1-or-later): the patches build on its DSF
  demuxer, DSD codecs and ID3v2 writer.
- [dsd-upsample](https://github.com/dsd-toolbox/dsd-upsample-rs) (MIT OR Apache-2.0): the
  PCM to DSD conversion behind the encoder.
- [dsd2pcm](https://github.com/dsd-toolbox/dsd2pcm-rs) (MIT OR Apache-2.0): its DSF writer
  is the reference for the file layout.
- Every source is listed in [PROVENANCE.md](PROVENANCE.md).

Part of the [DSD Toolbox](https://github.com/dsd-toolbox/dsd-toolbox).
