[ffmpeg-dsf](../README.md) › [Documentation](README.md) › User guide

# User guide

What the patches add to FFmpeg and how to convert to DSF with them. Building is in the
[install guide](install/linux.md); every option is in [options](options.md).

## The patches

Three patches in `git format-patch` form against FFmpeg master
05c674c9132eb13e65e3fb6e9b4cf1cad1219fd5 (2026-11-23). They are not part of FFmpeg yet.

- `patches/0001-avformat-dsfdec-fix-the-channel-layout-of-channel-ty.patch`: a fix to FFmpeg's DSF demuxer, which
  read channel type 5 as 4.0; the DSF specification defines it as 3.1 (front left, front
  right, center, low frequency).
- `patches/0002-avformat-add-DSF-muxer.patch`: a DSF (DSD Stream File) muxer. Takes the
  four DSD codecs (`dsd_lsbf`, `dsd_msbf`, `dsd_lsbf_planar`, `dsd_msbf_planar`), 1 to 6
  channels. Writes 4096-byte blocks per channel, least significant bit first, the last
  block zero-padded; sizes are filled in at the end; global metadata and chapters go into
  an ID3v2 tag after the audio. Needs no external library.
- `patches/0003-avcodec-add-PCM-to-DSD-encoding-via-libdsd_upsample.patch`: the encoder
  `libdsdupsample`, which uses the C library of
  [dsd-upsample](https://github.com/dsd-toolbox/dsd-upsample-rs). Enable it with
  `--enable-libdsdupsample` (found with pkg-config as `dsd_upsample`).
- `patches/0000-cover-letter.patch`: a cover letter for the series.

Apply them in order with `git apply` (or `git am`, which records the commits) in an FFmpeg
checkout of that commit.

## Convert to DSF

The encoder takes PCM at 44.1, 88.2, 176.4 or 352.8 kHz, or at 48, 96, 192 or 384 kHz, and
writes DSD64, DSD128 or DSD256 ([options](options.md)). The library resamples 48 kHz-family
input by 147/160 to the 44.1 kHz family; ffmpeg hands such input to the encoder as it is, so
the output is byte-identical to the command-line tool's. ffmpeg resamples other rates (for
example 32 kHz) to one of these rates. This converts a FLAC file to DSD256:

```sh
ffmpeg -i input.flac -c:a libdsdupsample -dsd_rate dsd256 output.dsf
```

This needs a build with the FLAC demuxer and decoder, for example a full build.

The muxer also stores DSD from other sources, for example `ffmpeg -i in.dff -c:a copy
out.dsf`. The output should be seekable: the header sizes are written at the end.

## Same bytes as the command-line tool

`-fflags +bitexact -map_metadata -1` stops ffmpeg from writing an ID3v2 tag (its
`encoder` tag and the input's metadata). With them, the DSF file is byte-identical to
what the `dsd-upsample` command-line tool writes for the same input and settings; without
them the audio is the same and the file ends in a tag.

Two exceptions:

- For 4-channel input with the 3.1 layout, ffmpeg writes channel type 5 (3.1) and the
  command-line tool writes type 4 (quad), so the files differ in that header field.
- When the converted audio ends inside a byte (common with 48 kHz-family input), the DSF
  header's sample count is rounded up to a whole byte, because FFmpeg counts DSD in bytes;
  the audio data is identical to the command-line tool's.

The host decodes the input; a damaged file the host accepts (for example a truncated FLAC) is converted as the host delivers it. The command-line tool refuses such files.

## See also

- [Options](options.md)
- [Install on Linux](install/linux.md)
- [Development](development.md): how the byte identity is checked

Part of the [DSD Toolbox](https://github.com/dsd-toolbox/dsd-toolbox).
