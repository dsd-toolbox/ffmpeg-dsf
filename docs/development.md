[ffmpeg-dsf](../README.md) › [Documentation](README.md) › Development

# Development

How the patches are tested: in CI, with FATE, and byte for byte against the command-line tool.

## Checks

- `.github/workflows/ci.yml` (Linux x86_64, Ubuntu 24.04): builds the library, applies
  the patches to FFmpeg at the base commit, builds a minimal FFmpeg with
  `--enable-libdsdupsample`, runs `make fate-dsf fate-source`, then `test/compare.sh`.
- FATE: `fate-dsf-dsd-msbf`, `fate-dsf-dsd-lsbf-planar-copy` and `fate-dsf-3point1` write
  DSF from raw DSD data (the generated test WAV file read as bytes) and read it back; no
  external samples. `fate-dsf-3point1` checks that channel type 5 round-trips as 3.1.
- `test/compare.sh FFMPEG_BUILD_DIR DSD_UPSAMPLE_CLI WORK_DIR`: ffmpeg with
  `libdsdupsample` against the `dsd-upsample` command-line tool for the same input and
  settings, byte for byte: DSD64, DSD128, DSD256, the default order and orders 5 and 8, that
  `-band` is not an option,
  gains 0 and -3, dither, mono to 6 channels, 44.1 to 352.8 kHz input, and 48, 96, 192 and
  384 kHz input, which the encoder takes without resampling in ffmpeg, and a 48,001-frame
  48 kHz input whose output ends inside a byte (the same file except the sample count, which
  is rounded up to whole bytes; see the user guide). Also stream copy of DSF files, decoding and
  re-encoding with `dsd_msbf`, all four DSD codec ids, the block layout against raw input
  (`test/verify_dsf.py`), the ID3v2 tag, non-seekable output (same audio, no sizes), the
  channel type of every layout in the DSF table, the sample count after a copy of a file
  whose count is not a multiple of 8, and a DSD rate above 2^31 bits per second.

## Library pin

CI fetches dsd-upsample-rs by commit, not by tag: `DSD_UPSAMPLE_COMMIT` at the top of
`.github/workflows/ci.yml` is the only place the commit is named, and the build stops
unless `git rev-parse HEAD` of the fetched tree equals it. Set it when releasing, to the
public dsd-upsample-rs commit that the release's library tag points to.

## See also

- [Install on Linux](install/linux.md)
- [Contributing](../CONTRIBUTING.md)
- [User guide](user-guide.md#same-bytes-as-the-command-line-tool)

Part of the [DSD Toolbox](https://github.com/dsd-toolbox/dsd-toolbox).
