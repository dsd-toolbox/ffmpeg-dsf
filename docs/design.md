[ffmpeg-dsf](../README.md) › [Documentation](README.md) › Design notes

# Design notes

Why the encoder and the muxer behave as they do inside FFmpeg.

## Decisions

- DSD sample rate: as for the other DSD codecs in FFmpeg (and `AV_SAMPLE_FMT_DSD`), the
  sample rate is the DSD bit rate / 8. The encoder sets `avctx->sample_rate` to the DSD
  rate in init, after the input rate has been checked against its supported rates;
  timestamps stay in the caller's time base. An alternative is an audio filter producing
  `AV_SAMPLE_FMT_DSD`, encoded by the existing `dsd_msbf` encoder.
- ffmpeg prints the encoder's output stream as `dsd_msbf_planar, 705600 Hz, dblp (8 bit)`
  because the codec context keeps its input sample format; the DSF demuxer reports `dsd`.
- The muxer always writes least significant bit first (bits per sample 1), the form most
  players read; most significant bit first input is bit-reversed.
- Channel types follow the DSF specification's table, and the series fixes FFmpeg's DSF
  demuxer to the same table (type 5 is 3.1), so files round-trip. Layouts outside the table
  get the default type for their channel count, with a warning.
- The sample count in the header is 8 times the bytes per channel. FFmpeg's DSF demuxer
  drops a partial last byte, so a stream copy of a DSF file whose sample count is not a
  multiple of 8 loses its last 1 to 7 samples; the demuxer does not pass on the exact count.

## See also

- [User guide](user-guide.md)
- [Options](options.md)
- [Development](development.md)

Part of the [DSD Toolbox](https://github.com/dsd-toolbox/dsd-toolbox).
