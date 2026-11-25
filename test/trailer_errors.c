// SPDX-License-Identifier: MIT OR Apache-2.0
//
// The DSF muxer's trailer seeks back to patch the header. On a seekable output whose seeks
// fail, av_write_trailer must return the error instead of 0 (the file's sizes would be
// wrong). With working seeks it returns 0 and the header holds the file size.
// Public FFmpeg API only. Built and run by test/compare.sh against the patched build.
#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include <libavformat/avformat.h>
#include <libavutil/mem.h>

#define MAX_OUT (1 << 20)

struct sink {
    uint8_t data[MAX_OUT];
    int64_t pos, size;
    int fail_seeks;
};

static int sink_write(void *opaque, const uint8_t *buf, int n)
{
    struct sink *s = opaque;
    if (s->pos < 0 || s->pos + n > MAX_OUT)
        return AVERROR(ENOSPC);
    memcpy(s->data + s->pos, buf, n);
    s->pos += n;
    if (s->pos > s->size)
        s->size = s->pos;
    return n;
}

static int64_t sink_seek(void *opaque, int64_t off, int whence)
{
    struct sink *s = opaque;
    if (whence == AVSEEK_SIZE)
        return s->size;
    if (s->fail_seeks)
        return AVERROR(EIO);
    if (whence == SEEK_CUR)
        off += s->pos;
    else if (whence == SEEK_END)
        off += s->size;
    if (off < 0 || off > MAX_OUT)
        return AVERROR(EINVAL);
    s->pos = off;
    return off;
}

// Muxes 3 blocks of 2-channel DSD64 into s; returns av_write_trailer's result.
static int mux(struct sink *s)
{
    AVFormatContext *oc = NULL;
    AVStream *st;
    AVPacket *pkt = av_packet_alloc();
    uint8_t *iobuf = av_malloc(4096);
    int ret;

    if (!pkt || !iobuf)
        return AVERROR(ENOMEM);
    if ((ret = avformat_alloc_output_context2(&oc, NULL, "dsf", NULL)) < 0)
        return ret;
    oc->pb = avio_alloc_context(iobuf, 4096, 1, s, NULL, sink_write, sink_seek);
    if (!oc->pb)
        return AVERROR(ENOMEM);
    oc->pb->seekable = AVIO_SEEKABLE_NORMAL;
    st = avformat_new_stream(oc, NULL);
    st->codecpar->codec_type  = AVMEDIA_TYPE_AUDIO;
    st->codecpar->codec_id    = AV_CODEC_ID_DSD_LSBF_PLANAR;
    st->codecpar->sample_rate = 352800;
    av_channel_layout_default(&st->codecpar->ch_layout, 2);
    oc->flags |= AVFMT_FLAG_BITEXACT;
    if ((ret = avformat_write_header(oc, NULL)) < 0)
        return ret;
    for (int i = 0; i < 3; i++) {
        if ((ret = av_new_packet(pkt, 2 * 4096)) < 0)
            return ret;
        memset(pkt->data, 0x69, pkt->size);
        pkt->pts = pkt->dts = (int64_t)i * 4096;
        if ((ret = av_write_frame(oc, pkt)) < 0)
            return ret;
        av_packet_unref(pkt);
    }
    ret = av_write_trailer(oc);
    av_freep(&oc->pb->buffer);
    avio_context_free(&oc->pb);
    avformat_free_context(oc);
    av_packet_free(&pkt);
    return ret;
}

int main(void)
{
    static struct sink ok, bad;
    int fail = 0, r;
    uint64_t file_size = 0;

    r = mux(&ok);
    for (int i = 0; i < 8; i++)
        file_size |= (uint64_t)ok.data[12 + i] << (8 * i);
    if (r < 0 || file_size != (uint64_t)ok.size) {
        printf("FAIL  working seeks: trailer %d, header file size %llu, file %lld\n", r,
               (unsigned long long)file_size, (long long)ok.size);
        fail = 1;
    } else {
        printf("OK    working seeks: trailer 0, header file size %llu\n",
               (unsigned long long)file_size);
    }

    bad.fail_seeks = 1;
    r = mux(&bad);
    if (r >= 0) {
        printf("FAIL  failing seeks: trailer returned %d, not an error\n", r);
        fail = 1;
    } else {
        printf("OK    failing seeks: trailer returned an error (%d)\n", r);
    }
    return fail;
}
