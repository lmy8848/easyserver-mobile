#pragma once

#include <QByteArray>
#include <QString>

/// scrcpy control 消息构造器（对齐 scrcpy 2.7 app/src/control_msg.c，
/// 大端字节序；坐标/压感为 16.16 定点数，x/width 归一化）。
/// 常量与 PLAN.md 附录 A.5 一致。
namespace ControlMsg {

constexpr char TYPE_INJECT_KEYCODE = 0;
constexpr char TYPE_INJECT_TEXT = 1;
constexpr char TYPE_INJECT_TOUCH_EVENT = 2;
constexpr char TYPE_INJECT_SCROLL_EVENT = 3;
constexpr char TYPE_BACK_OR_SCREEN_ON = 4;
constexpr char TYPE_SET_SCREEN_POWER_MODE = 10;

// Android 动作/键值
constexpr int ACTION_DOWN = 0;
constexpr int ACTION_UP = 1;
constexpr int ACTION_MOVE = 2;

constexpr int KEYCODE_BACK = 4;
constexpr int KEYCODE_HOME = 3;
constexpr int KEYCODE_APP_SWITCH = 187;
constexpr int KEYCODE_POWER = 26;
constexpr int KEYCODE_WAKEUP = 224;

// 触摸 pointerId：scrcpy 的虚拟鼠标指
constexpr qint64 POINTER_ID_MOUSE = -1;

inline void appendU16(QByteArray &b, quint16 v) {
    b.append(static_cast<char>((v >> 8) & 0xFF));
    b.append(static_cast<char>(v & 0xFF));
}

inline void appendU32(QByteArray &b, quint32 v) {
    b.append(static_cast<char>((v >> 24) & 0xFF));
    b.append(static_cast<char>((v >> 16) & 0xFF));
    b.append(static_cast<char>((v >> 8) & 0xFF));
    b.append(static_cast<char>(v & 0xFF));
}

inline void appendU64(QByteArray &b, quint64 v) {
    for (int shift = 56; shift >= 0; shift -= 8)
        b.append(static_cast<char>((v >> shift) & 0xFF));
}

// 16.16 定点：像素坐标 → (px / 维度) * 65536，归一化到 [0,1]
inline quint32 floatToFp16_16(double normalized) {
    if (normalized < 0) normalized = 0;
    if (normalized > 1) normalized = 1;
    return static_cast<quint32>(normalized * 65536.0 + 0.5);
}

inline QByteArray buildInjectKeycode(int action, int keycode,
                                     int repeat = 0, int metaState = 0) {
    QByteArray b;
    b.append(TYPE_INJECT_KEYCODE);
    appendU32(b, static_cast<quint32>(action));
    appendU32(b, static_cast<quint32>(keycode));
    appendU32(b, static_cast<quint32>(repeat));
    appendU32(b, static_cast<quint32>(metaState));
    return b;
}

inline QByteArray buildInjectText(const QString &text) {
    QByteArray b;
    b.append(TYPE_INJECT_TEXT);
    const QByteArray utf8 = text.toUtf8();
    appendU32(b, static_cast<quint32>(utf8.size()));
    b.append(utf8);
    return b;
}

inline QByteArray buildInjectTouchEvent(int action, qint64 pointerId,
                                        double xNorm, double yNorm,
                                        double pressure = 1.0,
                                        quint32 buttons = 0) {
    QByteArray b;
    b.append(TYPE_INJECT_TOUCH_EVENT);
    appendU64(b, static_cast<quint64>(pointerId));
    appendU32(b, floatToFp16_16(xNorm));
    appendU32(b, floatToFp16_16(yNorm));
    appendU16(b, 1080); // 宽高仅用于旋转映射，归一化坐标下为名义值
    appendU16(b, 2400);
    appendU16(b, static_cast<quint16>(pressure * 65535.0 + 0.5));
    appendU32(b, buttons);
    return b;
}

inline QByteArray buildInjectScroll(double xNorm, double yNorm, int vScroll) {
    QByteArray b;
    b.append(TYPE_INJECT_SCROLL_EVENT);
    appendU32(b, floatToFp16_16(xNorm));
    appendU32(b, floatToFp16_16(yNorm));
    appendU16(b, 1080);
    appendU16(b, 2400);
    appendU16(b, 0); // hscroll
    appendU16(b, static_cast<quint16>(static_cast<int>(vScroll * 65536.0) >> 16));
    appendU32(b, 0);
    return b;
}

inline QByteArray buildBackOrScreenOn(int action) {
    QByteArray b;
    b.append(TYPE_BACK_OR_SCREEN_ON);
    b.append(static_cast<char>(action));
    return b;
}

} // namespace ControlMsg
