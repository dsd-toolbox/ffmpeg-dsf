#!/bin/sh
# SPDX-License-Identifier: MIT OR Apache-2.0
# Byte comparison of ffmpeg + libdsdupsample against the dsd-upsample CLI, and DSF muxer
# checks. Usage: test/compare.sh FFMPEG_BUILD_DIR DSD_UPSAMPLE_CLI WORK_DIR
# FFMPEG_BUILD_DIR is an in-tree build of the patched FFmpeg (ffmpeg, ffprobe, configure).
set -u
build=$(cd "$1" && pwd)
CLI=$(cd "$(dirname "$2")" && pwd)/$(basename "$2")
here=$(cd "$(dirname "$0")" && pwd)
FF="$build/ffmpeg -nostdin -hide_banner -loglevel error -y"
mkdir -p "$3" && cd "$3" || exit 1
fail=0
check() { if cmp -s "$1" "$2"; then echo "SAME  $3"; else echo "DIFF  $3 ($(stat -c %s "$1") vs $(stat -c %s "$2"))"; cmp "$1" "$2" | head -1; fail=1; fi; }

# sources
$FF -f lavfi -i "aevalsrc=0.5*sin(2*PI*1000*t)|0.4*sin(2*PI*1500*t+1):s=44100:d=7.3" -c:a pcm_s24le s44.wav || fail=1
$FF -f lavfi -i "aevalsrc=0.5*sin(2*PI*997*t):s=88200:d=3" -c:a pcm_s16le m88.wav || fail=1
$FF -f lavfi -i "aevalsrc=0.3*sin(2*PI*440*t)|0.3*sin(2*PI*550*t)|0.3*sin(2*PI*660*t)|0.2*sin(2*PI*50*t)|0.3*sin(2*PI*770*t)|0.3*sin(2*PI*880*t):s=176400:d=2:c=5.1(side)" -c:a pcm_s24le six176.wav || fail=1
$FF -f lavfi -i "aevalsrc=0.9*sin(2*PI*3000*t)|0.9*sin(2*PI*5000*t):s=352800:d=1" -c:a pcm_s24le s352.wav || fail=1
# 48 kHz family: the encoder takes these rates as they are and the library resamples them by
# 147/160; had ffmpeg resampled them first, the bytes would differ from the CLI's.
$FF -f lavfi -i "aevalsrc=0.5*sin(2*PI*1000*t)|0.4*sin(2*PI*1500*t+1):s=48000:d=5.3" -c:a pcm_s24le s48.wav || fail=1
$FF -f lavfi -i "aevalsrc=0.5*sin(2*PI*997*t):s=96000:d=3" -c:a pcm_s16le m96.wav || fail=1
$FF -f lavfi -i "aevalsrc=0.3*sin(2*PI*440*t)|0.3*sin(2*PI*550*t)|0.3*sin(2*PI*660*t)|0.2*sin(2*PI*50*t)|0.3*sin(2*PI*770*t)|0.3*sin(2*PI*880*t):s=192000:d=1:c=5.1(side)" -c:a pcm_s24le six192.wav || fail=1
$FF -f lavfi -i "aevalsrc=0.9*sin(2*PI*3000*t)|0.9*sin(2*PI*5000*t):s=384000:d=1" -c:a pcm_s24le s384.wav || fail=1
# 48,001 frames (gen truncates seconds x rate): after the resampler, the output length is not
# a whole number of bytes, so the last byte holds padding and the DSF count is not a
# multiple of 8.
$CLI gen s48odd.wav --fs 48000 --bits 24 --seconds 1.0000209 --channels 2 >/dev/null || fail=1

run() { # name input cli-args ffmpeg-args
  name=$1 in=$2; cliargs=$3; ffargs=$4
  $CLI $in cli-$name.dsf $cliargs >cli-$name.log 2>&1 || { echo "CLI FAILED $name"; cat cli-$name.log; fail=1; return; }
  $FF -i $in -c:a libdsdupsample $ffargs -fflags +bitexact -map_metadata -1 ff-$name.dsf || { echo "FFMPEG FAILED $name"; fail=1; return; }
  check cli-$name.dsf ff-$name.dsf "$name: CLI $in $cliargs | ffmpeg -c:a libdsdupsample $ffargs"
}
run d128 s44.wav "--rate 128" "-dsd_rate dsd128"
run d64 s44.wav "--rate 64" "-dsd_rate dsd64"
run d256 s44.wav "--rate 256" "-dsd_rate dsd256"
run default s44.wav "--rate 128" ""
run orderauto s44.wav "--rate 256" "-dsd_rate dsd256 -order auto"
run order5 s44.wav "--rate 128 --order 5" "-order 5"
run order8g0 s44.wav "--rate 256 --order 8 --gain 0" "-dsd_rate dsd256 -order 8 -gain 0"
run dither s44.wav "--rate 128 --dither" "-dither 1"
# 0.1.0 has no band option (the library's audio band only): -band is refused
if $FF -i s44.wav -c:a libdsdupsample -band audio -f null - 2>band.log; then echo "ACCEPTED -band"; fail=1; else echo "OK  -band is not an option"; fi
run gainm3 s44.wav "--rate 64 --gain -3" "-dsd_rate dsd64 -gain -3"
run mono88 m88.wav "--rate 128" ""
run six176 six176.wav "--rate 256" "-dsd_rate dsd256"
run s352 s352.wav "--rate 256" "-dsd_rate dsd256"
run s48 s48.wav "--rate 128" ""
run s48d64 s48.wav "--rate 64" "-dsd_rate dsd64"
run s48d256o5dither s48.wav "--rate 256 --order 5 --dither" "-dsd_rate dsd256 -order 5 -dither 1"
run mono96 m96.wav "--rate 256" "-dsd_rate dsd256"
run mono96g3 m96.wav "--rate 128 --gain -3" "-gain -3"
run six192 six192.wav "--rate 128" ""
run s384 s384.wav "--rate 256" "-dsd_rate dsd256"
# FFmpeg counts DSD in whole bytes (one sample = 8 bits), so the encoder cannot pass on a
# length that ends inside a byte: the muxer's sample count is the CLI's rounded up to a
# multiple of 8, and the up to 7 extra bits are the library's padding. Everything else,
# the last byte included, must equal the CLI's file (docs/user-guide.md).
partial=0
for r in 64 128 256; do
  $CLI s48odd.wav cli-s48odd$r.dsf --rate $r >/dev/null 2>&1 || { echo "CLI FAILED s48odd$r"; fail=1; continue; }
  $FF -i s48odd.wav -c:a libdsdupsample -dsd_rate dsd$r -fflags +bitexact -map_metadata -1 ff-s48odd$r.dsf || { echo "FFMPEG FAILED s48odd$r"; fail=1; continue; }
  if python3 -I - cli-s48odd$r.dsf ff-s48odd$r.dsf <<'PY'
import struct, sys
c, f = (open(p, "rb").read() for p in sys.argv[1:3])
nc, nf = (struct.unpack_from("<Q", d, 64)[0] for d in (c, f))
same = len(c) == len(f) and c[:64] == f[:64] and c[72:] == f[72:]
print(f"      {sys.argv[1]}: {nc} samples per channel ({nc % 8} bits in the last byte), ffmpeg {nf}")
sys.exit(0 if same and nf == (nc + 7) // 8 * 8 else 1)
PY
  then echo "SAME  s48odd$r: all but the sample count, which is the CLI's rounded up to whole bytes"
  else echo "DIFF  s48odd$r"; fail=1; fi
  n=$(python3 -I -c 'import struct,sys; print(struct.unpack_from("<Q", open(sys.argv[1], "rb").read(), 64)[0] % 8)' cli-s48odd$r.dsf)
  [ "$n" = 0 ] || partial=$((partial + 1))
done
[ "$partial" -gt 0 ] && echo "OK  s48odd: $partial of 3 outputs end inside a byte" || { echo "NOT TESTED  s48odd: every output is whole bytes"; fail=1; }

# stream copy through the demuxer and muxer
for f in cli-d128 cli-six176 cli-mono88; do
  $FF -i $f.dsf -c copy -fflags +bitexact copy-$f.dsf && check $f.dsf copy-$f.dsf "remux $f.dsf -c copy"
done
# decode to AV_SAMPLE_FMT_DSD and re-encode with dsd_msbf (MSB-first input, bits reversed by the muxer)
$FF -request_sample_fmt dsd -i cli-d128.dsf -c:a dsd_msbf -fflags +bitexact reenc.dsf && check cli-d128.dsf reenc.dsf "decode + dsd_msbf re-encode"

# raw DSD through all four codec ids
head -c 1000000 "$build/configure" > raw.bin
$FF -f u8 -ac 2 -ar 352800 -c:a dsd_msbf -request_sample_fmt dsd -i raw.bin -c:a dsd_msbf -fflags +bitexact r-msbf.dsf
python3 -I "$here/verify_dsf.py" r-msbf.dsf raw.bin 2 || fail=1
$FF -f u8 -ac 2 -ar 352800 -c:a dsd_msbf -i raw.bin -c copy -fflags +bitexact r-msbf-copy.dsf
check r-msbf.dsf r-msbf-copy.dsf "dsd_msbf copy == dsd_msbf encode"
for c in dsd_lsbf dsd_msbf_planar dsd_lsbf_planar; do
  $FF -f u8 -ac 2 -ar 352800 -c:a $c -i raw.bin -c copy -fflags +bitexact r-$c.dsf
  $FF -i r-$c.dsf -c copy -fflags +bitexact r2-$c.dsf && check r-$c.dsf r2-$c.dsf "$c copy, remux stable"
done
# metadata: ID3v2 tag at the end, read back
$FF -i s44.wav -c:a libdsdupsample -metadata title="Test title" -metadata artist="Test artist" -fflags +bitexact tags.dsf
"$build/ffprobe" -v error -show_entries format_tags:stream=codec_name,sample_rate,channels,channel_layout,duration -of compact tags.dsf
python3 -I "$here/verify_dsf.py" --tag tags.dsf || fail=1
# non-seekable output: warns, writes the same audio, leaves the sizes at zero
$FF -i s44.wav -c:a libdsdupsample -fflags +bitexact -map_metadata -1 seek.dsf || fail=1
$FF -i s44.wav -c:a libdsdupsample -fflags +bitexact -map_metadata -1 -f dsf -loglevel warning - 2>pipe.log >pipe.dsf || fail=1
grep -q "Output is not seekable" pipe.log && echo "OK  non-seekable warning" || { echo "NO WARNING for non-seekable output"; fail=1; }
python3 -I "$here/verify_dsf.py" --pipe pipe.dsf seek.dsf || fail=1

# channel types from the layout (DSF specification: 3 = 3.0, 4 = quad, 5 = 3.1,
# 6 = 5.0 and 7 = 5.1 with back channels, which FFmpeg names 5.0 and 5.1)
python3 -I -c 'import sys; d = open(sys.argv[1], "rb").read(); open(sys.argv[2], "wb").write(d[:len(d) // 60 * 60])' raw.bin raw60.bin   # whole samples for 1 to 6 channels
for l in mono:1 stereo:2 3.0:3 quad:4 3.1:5 5.0:6 5.1:7; do
  $FF -f u8 -ch_layout "${l%:*}" -ar 352800 -c:a dsd_lsbf_planar -i raw60.bin -c copy -fflags +bitexact ct.dsf || fail=1
  python3 -I "$here/verify_dsf.py" --expect ct.dsf ctype=${l#*:} || fail=1
done
# 4.0 has no DSF channel type: the default for 4 channels (quad)
$FF -f u8 -ch_layout 4.0 -ar 352800 -c:a dsd_lsbf_planar -i raw60.bin -c copy -fflags +bitexact ct.dsf || fail=1
python3 -I "$here/verify_dsf.py" --expect ct.dsf ctype=4 || fail=1

# a sample count that is not a multiple of 8: the demuxer drops the partial byte on copy
count=$(python3 -I -c 'import struct,sys; print(struct.unpack_from("<Q", open(sys.argv[1], "rb").read(), 64)[0])' cli-d128.dsf)
python3 -I "$here/verify_dsf.py" --set-count cli-d128.dsf odd.dsf $((count - 3))
$FF -i odd.dsf -c copy -fflags +bitexact odd-copy.dsf || fail=1
python3 -I "$here/verify_dsf.py" --expect odd-copy.dsf count=$(( (count - 3) / 8 * 8 )) || fail=1

# a DSD rate above 2^31 bits per second: the header holds it unsigned
$FF -f u8 -ac 2 -ar 300000000 -c:a dsd_lsbf_planar -i raw.bin -c copy -fflags +bitexact big.dsf || fail=1
python3 -I "$here/verify_dsf.py" --expect big.dsf rate=2400000000 || fail=1

# invalid settings are refused in init with EINVAL and a reason, before the library sees them
for bad in "dsd_rate 100:dsd_rate must be 64, 128 or 256" "order 3:order must be auto (-1) or 5 to 8" "order 8:modulator order 8: DSD128 output accepts 5, 6, 7"; do
  opt=${bad%%:*} want=${bad#*:}
  if $FF -i s44.wav -c:a libdsdupsample -$opt -f null - 2>bad.log; then
    echo "ACCEPTED -$opt"; fail=1
  elif grep -qF "$want" bad.log && grep -q "Invalid argument" bad.log; then
    echo "OK  -$opt refused: $want"
  else
    echo "WRONG REFUSAL for -$opt:"; cat bad.log; fail=1
  fi
done

# the trailer's seeks: a seekable output whose seeks fail gets an error, not a wrong header
# (test/trailer_errors.c, linked against this build's static libraries)
libs=$(sed -n 's/^EXTRALIBS[^=]*=//p' "$build/ffbuild/config.mak" | tr '\n' ' ')
if cc -I"$build" "$here/trailer_errors.c" -o trailer_errors "$build/libavformat/libavformat.a" \
     "$build/libavcodec/libavcodec.a" "$build/libswresample/libswresample.a" \
     "$build/libavutil/libavutil.a" $libs -lm -lpthread 2>trailer_errors.log; then
  ./trailer_errors || fail=1
else
  echo "trailer_errors.c did not build"; cat trailer_errors.log; fail=1
fi
echo "RESULT fail=$fail"
exit $fail
