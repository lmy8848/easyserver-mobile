#pragma once

#include <QImage>

extern "C" {
#include <libavcodec/avcodec.h>
#include <libavutil/imgutils.h>
#include <libswscale/swscale.h>
}

/// libavcodec H.264 软解封装（ADR-003：M1 软解，M5 评估 D3D11VA）。
/// 线程约定：仅在 IO/解码线程使用（非线程安全）。
/// CONFIG 包（SPS/PPS）作为 extradata 在 open 前注入。
class FfmpegDecoder {
public:
    FfmpegDecoder() = default;
    ~FfmpegDecoder() { close(); }

    FfmpegDecoder(const FfmpegDecoder &) = delete;
    FfmpegDecoder &operator=(const FfmpegDecoder &) = delete;

    bool open(const QByteArray &extradata) {
        close();
        m_codec = avcodec_find_decoder(AV_CODEC_ID_H264);
        if (!m_codec) return false;
        m_ctx = avcodec_alloc_context3(m_codec);
        if (!m_ctx) return false;
        m_ctx->flags |= AV_CODEC_FLAG_LOW_DELAY; // 低延迟优先（ADR-003）
        m_ctx->thread_count = 1;
        if (!extradata.isEmpty()) {
            m_ctx->extradata =
                static_cast<uint8_t *>(av_malloc(extradata.size() + 8));
            memcpy(m_ctx->extradata, extradata.constData(), extradata.size());
            m_ctx->extradata_size = extradata.size();
        }
        if (avcodec_open2(m_ctx, m_codec, nullptr) < 0) {
            close();
            return false;
        }
        m_frame = av_frame_alloc();
        return m_frame != nullptr;
    }

    /// 喂入一个 H.264 access unit（含起始码），解码成功返回 true（可 takeFrame）
    bool feed(const QByteArray &packet) {
        if (!m_ctx) return false;
        AVPacket *pkt = av_packet_alloc();
        if (!pkt) return false;
        if (av_new_packet(pkt, packet.size()) == 0) {
            memcpy(pkt->data, packet.constData(), packet.size());
            pkt->pts = AV_NOPTS_VALUE;
            pkt->dts = AV_NOPTS_VALUE;
            avcodec_send_packet(m_ctx, pkt);
        }
        av_packet_free(&pkt);
        return drain();
    }

    QImage takeFrame() {
        QImage out = m_last;
        m_last = QImage();
        return out;
    }

    bool hasFrame() const { return !m_last.isNull(); }

    void close() {
        if (m_frame) av_frame_free(&m_frame);
        if (m_ctx) avcodec_free_context(&m_ctx);
        if (m_sws) sws_freeContext(m_sws);
        m_sws = nullptr;
        m_ctx = nullptr;
        m_codec = nullptr;
        m_frame = nullptr;
        m_last = QImage();
        m_swsW = m_swsH = 0;
    }

private:
    bool drain() {
        bool got = false;
        while (true) {
            const int r = avcodec_receive_frame(m_ctx, m_frame);
            if (r < 0) break;
            m_last = convert(m_frame);
            got = true;
        }
        return got;
    }

    QImage convert(AVFrame *f) {
        if (f->format != AV_PIX_FMT_YUV420P) return QImage(); // scrcpy 固定 yuv420p
        // 解码端直接缩到 ≤720 宽：显示区也就几百像素宽，全尺寸 RGBA（1080x2400
        // ≈ 10MB/帧）会让 QML 纹理上传成为瓶颈；缩到 720 宽 ≈ 2.6MB/帧。
        int dstW = f->width, dstH = f->height;
        if (dstW > 720) {
            dstW = 720;
            dstH = (f->height * 720 + f->width / 2) / f->width;
        }
        if (m_swsW != f->width || m_swsH != f->height || !m_sws) {
            if (m_sws) sws_freeContext(m_sws);
            m_sws = sws_getContext(f->width, f->height, AV_PIX_FMT_YUV420P,
                                   dstW, dstH, AV_PIX_FMT_RGBA,
                                   SWS_FAST_BILINEAR, nullptr, nullptr, nullptr);
            m_swsW = f->width;
            m_swsH = f->height;
        }
        if (!m_sws) return QImage();
        QImage img(dstW, dstH, QImage::Format_RGBA8888);
        uint8_t *dst[] = {img.bits()};
        int dstStride[] = {static_cast<int>(img.bytesPerLine())};
        sws_scale(m_sws, f->data, f->linesize, 0, f->height, dst, dstStride);
        return img;
    }

    const AVCodec *m_codec = nullptr;
    AVCodecContext *m_ctx = nullptr;
    AVFrame *m_frame = nullptr;
    SwsContext *m_sws = nullptr;
    QImage m_last;
    int m_swsW = 0;
    int m_swsH = 0;
};
