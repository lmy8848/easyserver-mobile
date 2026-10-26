#pragma once

#include <QImage>
#include <QMutex>
#include <QQuickImageProvider>

/// 向 QML 提供最新镜像帧（M1 临时方案：QImage；M2 换 scene graph 纹理）。
/// worker 线程写入，渲染线程读取 —— 互斥锁保护。
class MirrorImageProvider : public QQuickImageProvider {
public:
    explicit MirrorImageProvider()
        : QQuickImageProvider(QQuickImageProvider::Image) {}

    QImage requestImage(const QString &id, QSize *size,
                        const QSize &requestedSize) override {
        QMutexLocker locker(&m_mutex);
        Q_UNUSED(id);
        Q_UNUSED(requestedSize); // 等比缩放交给 Image.fillMode，避免每帧平滑缩放
        if (m_last.isNull()) {
            QImage blank(16, 16, QImage::Format_RGBA8888);
            blank.fill(Qt::black);
            return blank;
        }
        if (size) *size = m_last.size();
        return m_last;
    }

    void setLast(const QImage &img) {
        QMutexLocker locker(&m_mutex);
        m_last = img;
    }

private:
    QMutex m_mutex;
    QImage m_last;
};
