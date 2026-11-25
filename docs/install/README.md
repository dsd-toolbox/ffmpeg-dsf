[ffmpeg-dsf](../../README.md) › [Documentation](../README.md) › Install

# Install

Where the patches are tested and how to build FFmpeg with them. They are source patches only:
there is nothing to download or sign, and they are not part of FFmpeg yet.

## Choose a guide

| System | How | Guide |
|---|---|---|
| Linux, x86_64 | Apply the patches to FFmpeg's source, build with `--enable-libdsdupsample`; tested in CI (Ubuntu 24.04) | [Linux](linux.md) |
| macOS, Windows | The same source build; FFmpeg and the library build there, but these patches are not tested there yet | [Linux](linux.md#other-systems) |

## See also

- [User guide](../user-guide.md)
- [Development](../development.md)

Part of the [DSD Toolbox](https://github.com/dsd-toolbox/dsd-toolbox).
