[ffmpeg-dsf](../../README.md) › [Documentation](../README.md) › [Install](README.md) › Linux

# Linux

Build FFmpeg with the patches on Linux. The [Quick start](../../README.md#quick-start) has
the tested commands for a minimal build.

## Minimal and full builds

The [Quick start](../../README.md#quick-start) builds a minimal FFmpeg with only what it
needs. For a full build, drop `--disable-everything` and the `--enable-*` lists and keep
`--enable-libdsdupsample`.

## The library and pkg-config

`pkgconfig/dsd_upsample.pc` points at the library built in
`dsd-upsample-rs/target/release` next to this repository and links it statically, so
`ffmpeg` needs no library path at run time. Its link flags are for Linux; on other
systems, or with an installed library, use a pkg-config file for that library instead.

## Other systems

The same source build may work on macOS and Windows, but neither the dsd-upsample library
0.1.0 nor these patches are tested there yet.

## See also

- [Install](README.md)
- [User guide](../user-guide.md)
- [Development](../development.md): what CI builds and runs

Part of the [DSD Toolbox](https://github.com/dsd-toolbox/dsd-toolbox).
