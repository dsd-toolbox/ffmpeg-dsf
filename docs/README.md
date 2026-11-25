[ffmpeg-dsf](../README.md) › Documentation

<img src="assets/icon-256.png" alt="" width="96">

# Documentation

Everything about the FFmpeg patches that add a DSF muxer and a PCM to DSD encoder: building
FFmpeg with them, using them, and how they are tested.

## Install

- [Install guides](install/README.md)
- [Linux](install/linux.md): apply the patches and build FFmpeg

## Use

- [User guide](user-guide.md): the patches, converting to DSF, byte-identical output

## Reference

- [Options](options.md): encoder and DSF muxer options

## Internals

- [Design notes](design.md)

## Project

- [Changelog](../CHANGELOG.md)
- [Security policy](../SECURITY.md)
- [Development](development.md): CI, FATE tests, byte comparison with the command-line tool
- [Contributing](../CONTRIBUTING.md)
- [Provenance](../PROVENANCE.md)
- [Icon](assets/README.md): the project icon files

## See also

- [README](../README.md)
- [dsd-upsample](https://github.com/dsd-toolbox/dsd-upsample-rs): the library behind the encoder

Part of the [DSD Toolbox](https://github.com/dsd-toolbox/dsd-toolbox).
