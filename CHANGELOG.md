# Changelog

All notable changes to this project are listed here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow
[Semantic Versioning](https://semver.org/).

## 0.1.0 - 2026-11-25

First public release.

### Added
- Three patches for FFmpeg, against FFmpeg master 05c674c9132eb13e65e3fb6e9b4cf1cad1219fd5;
  they target FFmpeg and are not part of FFmpeg yet:
  - a fix to FFmpeg's DSF demuxer: channel type 5 is 3.1 (as in the DSF specification),
    not 4.0;
  - a DSF muxer for the four DSD codecs, 1 to 6 channels, with global metadata and
    chapters in an ID3v2 tag;
  - the encoder `libdsdupsample`: PCM at 44.1 to 352.8 kHz, or at 48, 96, 192 and 384 kHz
    (which the library resamples by 147/160 to the 44.1 kHz family, so ffmpeg does not
    resample it), to DSD64, DSD128 or DSD256 through the dsd-upsample C library
    (`--enable-libdsdupsample`), with options for the library's settings; order 8 is
    refused for DSD128 output (the library refuses it there: in the audio band it clips on
    legal input).
- A cover letter for the series and the FATE tests `fate-dsf-dsd-msbf`,
  `fate-dsf-dsd-lsbf-planar-copy` and `fate-dsf-3point1`.
- `test/compare.sh`: a byte-for-byte comparison of ffmpeg's DSF output with the
  `dsd-upsample` command-line tool of the same library release, run in CI on Linux x86_64.
  When the converted audio ends inside a byte (common with 48 kHz-family input), the DSF
  header's sample count is rounded up to a whole byte, because FFmpeg counts DSD in bytes;
  the audio data is identical to the command-line tool's. The other difference is the
  channel type of 3.1 input (5 from FFmpeg, 4 from the command-line tool).
- A pkg-config file for a locally built dsd-upsample library.
