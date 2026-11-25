[ffmpeg-dsf](../README.md) › [Documentation](README.md) › Options

# Options

The options of the `libdsdupsample` encoder and the DSF muxer that the patches add. How to use
them is in the [user guide](user-guide.md).

## Encoder (`libdsdupsample`)

Input: PCM at 44.1, 88.2, 176.4 or 352.8 kHz, or at 48, 96, 192 or 384 kHz (the library
resamples these by 147/160 to the 44.1 kHz family), 1 to 6 channels. ffmpeg resamples other
rates to one of these. Output: DSD, most significant bit first, planar
(`dsd_msbf_planar`).

| Option | Values | Default |
|---|---|---|
| `dsd_rate` | `dsd64`, `dsd128`, `dsd256` | `dsd128` |
| `order` | modulator order, 5 to 8 (5 to 7 at DSD128), or `auto` (-1): the library's default for the output rate | `auto`: 6 at every rate |
| `gain` | dB before the modulator, -120 to 24 | the library's default for DSD output (-6 in dsd-upsample 0.1.0) |
| `dither` | TPDF dither before the modulator, 0 or 1 | 0 |

`ffmpeg -h encoder=libdsdupsample` prints `(default nan)` for `gain`: not a number is how the
encoder marks "not set", and then the library's default applies. Set `-gain` to choose a value.

The modulator input limit is the library's default (0.51); the encoder has no option for it.

## DSF muxer

| Option | Values | Default |
|---|---|---|
| `write_id3v2` | write global metadata and chapters as an ID3v2 tag | 1 |
| `id3v2_version` | 3 or 4 | 4 |

The channel type comes from the channel layout, as in the DSF specification: mono 1,
stereo 2, 3.0 3, quad 4, 3.1 5, 5.0 6, 5.1 7 (FFmpeg's 5.0 and 5.1, with back channels).
Other layouts get the type for their channel count (1, 2, 3, 4, 6 or 7 for 1 to 6
channels), with a warning. The sample count is 8 times the bytes per channel
([design notes](design.md)).

## See also

- [User guide](user-guide.md)
- [dsd-upsample options](https://github.com/dsd-toolbox/dsd-upsample-rs/blob/main/docs/options.md): the command-line options these mirror
- [Design notes](design.md)

Part of the [DSD Toolbox](https://github.com/dsd-toolbox/dsd-toolbox).
