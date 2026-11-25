# Contributing

- Licence boundary: changes to FFmpeg live only in `patches/` and are LGPL-2.1-or-later,
  as FFmpeg is. Everything else is MIT OR Apache-2.0. Never copy FFmpeg code into files
  outside `patches/`; record borrowed ideas and their licences in PROVENANCE.md.
- Patches follow FFmpeg's rules (`doc/developer.texi`, `tools/patcheck`): FFmpeg coding
  style, one logical change per patch, FATE tests for new behaviour. Regenerate them
  with `git format-patch` from a branch on the FFmpeg base commit named in [docs/user-guide.md](docs/user-guide.md#the-patches).
- Byte identity: for the same input and settings, ffmpeg with `libdsdupsample` must write
  the same DSF bytes as the `dsd-upsample` command-line tool. `test/compare.sh` checks
  this; keep it passing and extend it with new options.
- Pull requests need the CI checks to pass, and update README.md (and the patch
  documentation) when behaviour, options or the base commit change.
