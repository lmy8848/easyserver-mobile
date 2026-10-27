#include "Panels.h"

#include <QAbstractItemView>
#include <QCheckBox>
#include <QColor>
#include <QComboBox>
#include <QDir>
#include <QLabel>
#include <QSplitter>
#include <QHBoxLayout>
#include <QLineEdit>
#include <QListWidget>
#include <QPlainTextEdit>
#include <QPushButton>
#include <QScrollBar>
#include <QTextCursor>
#include <QTextEdit>
#include <QVBoxLayout>

Panels::Panels(QWidget *parent) : QTabWidget(parent) {
    setTabPosition(QTabWidget::North);
    buildShellTab();
    buildLogTab();
    buildInfoTab();
    buildActionTab();
    buildAppLogTab();
}

void Panels::buildShellTab() {
    auto *page = new QWidget(this);
    auto *lay = new QVBoxLayout(page);
    lay->setContentsMargins(6, 6, 6, 6);
    lay->setSpacing(6);

    m_shellOut = new QPlainTextEdit(page);
    m_shellOut->setReadOnly(true);
    m_shellOut->setPlaceholderText(QStringLiteral("命令输出"));
    m_shellIn = new QLineEdit(page);
    m_shellIn->setPlaceholderText(QStringLiteral("输入 shell 命令，回车执行"));
    connect(m_shellIn, &QLineEdit::returnPressed, this, [this]() {
        const QString cmd = m_shellIn->text().trimmed();
        if (cmd.isEmpty())
            return;
        appendShell(QStringLiteral("$ ") + cmd);
        m_shellIn->clear();
        emit shellCommandEntered(cmd);
    });

    lay->addWidget(m_shellOut, 1);
    lay->addWidget(m_shellIn);
    addTab(page, QStringLiteral("终端"));
}

void Panels::buildLogTab() {
    auto *page = new QWidget(this);
    auto *lay = new QVBoxLayout(page);
    lay->setContentsMargins(6, 6, 6, 6);
    lay->setSpacing(6);

    auto *bar = new QHBoxLayout();
    m_logFilter = new QLineEdit(page);
    m_logFilter->setPlaceholderText(QStringLiteral("过滤关键字"));
    m_pauseLog = new QCheckBox(QStringLiteral("暂停"), page);
    m_logcatBtn = new QPushButton(QStringLiteral("开始抓取"), page);
    m_logcatBtn->setToolTip(QStringLiteral("抓取 logcat 到本页（F6 开始/停止）"));
    auto *clearBtn = new QPushButton(QStringLiteral("清空"), page);
    bar->addWidget(m_logFilter, 1);
    bar->addWidget(m_pauseLog);
    bar->addWidget(m_logcatBtn);
    bar->addWidget(clearBtn);
    connect(m_logcatBtn, &QPushButton::clicked, this, [this]() {
        if (m_logcatRunning)
            emit logcatStopRequested();
        else
            emit logcatStartRequested();
    });

    m_logOut = new QPlainTextEdit(page);
    m_logOut->setReadOnly(true);
    m_logOut->setPlaceholderText(QStringLiteral("logcat 输出（F6 开始/停止抓取）"));
    m_logOut->setMaximumBlockCount(2000);
    m_logOut->setUndoRedoEnabled(false);
    m_logOut->setLineWrapMode(QPlainTextEdit::NoWrap);
    connect(clearBtn, &QPushButton::clicked, this, &Panels::clearLog);

    lay->addLayout(bar);
    lay->addWidget(m_logOut, 1);
    addTab(page, QStringLiteral("日志"));
}

void Panels::buildInfoTab() {
    auto *page = new QWidget(this);
    auto *lay = new QVBoxLayout(page);
    lay->setContentsMargins(6, 6, 6, 6);
    lay->setSpacing(6);

    auto *refreshBtn = new QPushButton(QStringLiteral("刷新设备信息"), page);
    connect(refreshBtn, &QPushButton::clicked, this, &Panels::refreshInfoRequested);

    m_infoOut = new QTextEdit(page);
    m_infoOut->setReadOnly(true);
    m_infoOut->setPlaceholderText(QStringLiteral("品牌 / 系统 / ABI / 分辨率 / 电量"));

    lay->addWidget(refreshBtn);
    lay->addWidget(m_infoOut, 1);
    addTab(page, QStringLiteral("设备"));
}

void Panels::buildActionTab() {
    auto *page = new QWidget(this);
    auto *lay = new QVBoxLayout(page);
    lay->setContentsMargins(6, 6, 6, 6);
    lay->setSpacing(6);

    auto *row1 = new QHBoxLayout();
    auto *shotBtn = new QPushButton(QStringLiteral("截图"), page);
    shotBtn->setToolTip(QStringLiteral("截取当前屏幕并保存到上面的目录（F10）"));
    m_recordBtn = new QPushButton(QStringLiteral("录屏"), page);
    m_recordBtn->setToolTip(
        QStringLiteral("按所选时长录制屏幕；录制中再点一次可提前结束（F11）"));
    m_recordDur = new QComboBox(page);
    m_recordDur->addItem(QStringLiteral("10 秒"), 10);
    m_recordDur->addItem(QStringLiteral("30 秒"), 30);
    m_recordDur->addItem(QStringLiteral("60 秒"), 60);
    m_recordDur->addItem(QStringLiteral("120 秒"), 120);
    m_recordDur->setCurrentIndex(1);
    m_recordDur->setFixedWidth(90);
    row1->addWidget(shotBtn);
    row1->addWidget(m_recordBtn);
    row1->addWidget(m_recordDur);
    row1->addStretch(1);

    auto *row2 = new QHBoxLayout();
    auto *installBtn = new QPushButton(QStringLiteral("安装 APK"), page);
    auto *listBtn = new QPushButton(QStringLiteral("列出应用"), page);
    listBtn->setToolTip(QStringLiteral("列出第三方应用，供「卸载选中」使用（F9）"));
    auto *uninstallBtn = new QPushButton(QStringLiteral("卸载选中"), page);
    row2->addWidget(installBtn);
    row2->addWidget(listBtn);
    row2->addWidget(uninstallBtn);
    row2->addStretch(1);

    auto *dirRow = new QHBoxLayout();
    m_captureDir = new QLineEdit(page);
    m_captureDir->setReadOnly(true);
    m_captureDir->setPlaceholderText(QStringLiteral("截图与录屏的保存目录"));
    auto *chooseBtn = new QPushButton(QStringLiteral("更改…"), page);
    auto *openBtn = new QPushButton(QStringLiteral("打开文件夹"), page);
    dirRow->addWidget(new QLabel(QStringLiteral("保存到"), page));
    dirRow->addWidget(m_captureDir, 1);
    dirRow->addWidget(chooseBtn);
    dirRow->addWidget(openBtn);

    m_captureList = new QListWidget(page);
    m_captureList->setSelectionMode(QAbstractItemView::SingleSelection);
    m_captureList->setToolTip(QStringLiteral("双击打开最近生成的文件"));

    m_pkgList = new QListWidget(page);
    m_pkgList->setSelectionMode(QAbstractItemView::SingleSelection);

    auto *splitter = new QSplitter(Qt::Vertical, page);
    auto *capBox = new QWidget(splitter);
    auto *capLay = new QVBoxLayout(capBox);
    capLay->setContentsMargins(0, 0, 0, 0);
    capLay->setSpacing(4);
    capLay->addWidget(new QLabel(QStringLiteral("最近截图 / 录屏"), capBox));
    capLay->addWidget(m_captureList, 1);
    auto *pkgBox = new QWidget(splitter);
    auto *pkgLay = new QVBoxLayout(pkgBox);
    pkgLay->setContentsMargins(0, 0, 0, 0);
    pkgLay->setSpacing(4);
    pkgLay->addWidget(new QLabel(QStringLiteral("第三方应用"), pkgBox));
    pkgLay->addWidget(m_pkgList, 1);
    splitter->addWidget(capBox);
    splitter->addWidget(pkgBox);
    splitter->setStretchFactor(0, 2);
    splitter->setStretchFactor(1, 3);

    connect(shotBtn, &QPushButton::clicked, this, &Panels::screenshotRequested);
    connect(m_recordBtn, &QPushButton::clicked, this, [this]() {
        if (m_recording) {
            emit cancelRecordRequested();
            return;
        }
        emit recordRequested(m_recordDur->currentData().toInt());
    });
    connect(chooseBtn, &QPushButton::clicked, this, &Panels::chooseCaptureDirRequested);
    connect(openBtn, &QPushButton::clicked, this, &Panels::openCaptureDirRequested);
    connect(m_captureList, &QListWidget::itemDoubleClicked, this, [this](QListWidgetItem *item) {
        const QString path = item->data(Qt::UserRole).toString();
        if (!path.isEmpty())
            emit openCaptureFileRequested(path);
    });
    connect(installBtn, &QPushButton::clicked, this, &Panels::installApkRequested);
    connect(listBtn, &QPushButton::clicked, this, &Panels::listPackagesRequested);
    connect(uninstallBtn, &QPushButton::clicked, this, [this]() {
        if (auto *item = m_pkgList->currentItem())
            emit uninstallPackageRequested(item->text());
    });

    lay->addLayout(row1);
    lay->addLayout(row2);
    lay->addLayout(dirRow);
    lay->addWidget(splitter, 1);
    addTab(page, QStringLiteral("操作"));
}

void Panels::setCaptureDir(const QString &dir) {
    m_captureDir->setText(QDir::toNativeSeparators(dir));
    m_captureDir->setToolTip(dir);
}

void Panels::appendCapture(const QString &label, const QString &path, bool ok) {
    auto *item = new QListWidgetItem((ok ? QStringLiteral("✓ ") : QStringLiteral("✗ ")) + label,
                                     m_captureList);
    item->setData(Qt::UserRole, ok ? path : QString());
    item->setForeground(ok ? QColor(QStringLiteral("#4ade80")) : QColor(QStringLiteral("#f87171")));
    item->setToolTip(path.isEmpty() ? label : QDir::toNativeSeparators(path));
    m_captureList->scrollToItem(item);
    while (m_captureList->count() > 30)
        delete m_captureList->takeItem(0);
}

void Panels::setRecording(bool recording) {
    m_recording = recording;
    m_recordBtn->setText(recording ? QStringLiteral("停止录屏") : QStringLiteral("录屏"));
    m_recordDur->setEnabled(!recording);
}

void Panels::buildAppLogTab() {
    auto *page = new QWidget(this);
    auto *lay = new QVBoxLayout(page);
    lay->setContentsMargins(6, 6, 6, 6);
    lay->setSpacing(6);

    auto *row = new QHBoxLayout;
    auto *hint =
        new QLabel(QStringLiteral("应用运行日志（连接、adb 命令、截图、录屏、错误）"), page);
    auto *clearBtn = new QPushButton(QStringLiteral("清空"), page);
    auto *openBtn = new QPushButton(QStringLiteral("打开日志文件夹"), page);
    row->addWidget(hint, 1);
    row->addWidget(clearBtn);
    row->addWidget(openBtn);

    m_appLog = new QPlainTextEdit(page);
    m_appLog->setReadOnly(true);
    m_appLog->setMaximumBlockCount(5000);
    m_appLog->setUndoRedoEnabled(false);
    m_appLog->setLineWrapMode(QPlainTextEdit::NoWrap);

    lay->addLayout(row);
    lay->addWidget(m_appLog, 1);
    addTab(page, QStringLiteral("应用日志"));

    connect(clearBtn, &QPushButton::clicked, this, &Panels::clearAppLog);
    connect(openBtn, &QPushButton::clicked, this, &Panels::openLogDirRequested);
}

void Panels::appendAppLog(const QString &line) {
    if (!m_appLog || line.isEmpty())
        return;
    // 仅当用户停留在底部时自动跟随，翻阅历史时不被拽走
    QScrollBar *bar = m_appLog->verticalScrollBar();
    const bool atBottom = bar->value() >= bar->maximum() - 4;
    m_appLog->moveCursor(QTextCursor::End);
    m_appLog->insertPlainText(line + QLatin1Char('\n'));
    if (atBottom)
        bar->setValue(bar->maximum());
}

void Panels::clearAppLog() {
    if (m_appLog)
        m_appLog->clear();
}


void Panels::appendShell(const QString &text) {
    if (text.isEmpty())
        return;
    m_shellOut->moveCursor(QTextCursor::End);
    m_shellOut->insertPlainText(text.endsWith(QLatin1Char('\n')) ? text : text + QLatin1Char('\n'));
    m_shellOut->moveCursor(QTextCursor::End);
}

void Panels::clearShell() { m_shellOut->clear(); }

void Panels::appendLog(const QString &text) {
    if (text.isEmpty() || m_pauseLog->isChecked())
        return;
    const QString filter = m_logFilter->text().trimmed();
    if (!filter.isEmpty() && !text.contains(filter))
        return;
    m_logOut->moveCursor(QTextCursor::End);
    m_logOut->insertPlainText(text.endsWith(QLatin1Char('\n')) ? text : text + QLatin1Char('\n'));
    m_logOut->moveCursor(QTextCursor::End);
}

void Panels::appendLogLines(const QStringList &lines) {
    if (lines.isEmpty() || m_pauseLog->isChecked())
        return;
    const QString filter = m_logFilter->text().trimmed();
    QString batch;
    batch.reserve(8192);
    int taken = 0;
    auto flushBatch = [this, &batch]() {
        if (batch.isEmpty())
            return;
        QTextCursor cur = m_logOut->textCursor();
        cur.movePosition(QTextCursor::End);
        m_logOut->setTextCursor(cur);
        m_logOut->insertPlainText(batch);
        batch.clear();
    };
    for (const QString &line : lines) {
        if (!filter.isEmpty() && !line.contains(filter))
            continue;
        batch += line;
        batch += QLatin1Char('\n');
        // 每 300 行插入一次：单次插入过多会让排版明显变慢；
        // 分批插完不丢行（控件本身只保留最后 2000 行）。
        if (++taken >= 300) {
            flushBatch();
            taken = 0;
        }
    }
    flushBatch();
}

void Panels::clearLog() { m_logOut->clear(); }

void Panels::setLogcatRunning(bool running) {
    m_logcatRunning = running;
    m_logcatBtn->setText(running ? QStringLiteral("停止抓取") : QStringLiteral("开始抓取"));
}

void Panels::setInfo(const QString &text) { m_infoOut->setPlainText(text); }

void Panels::appendInfo(const QString &text) { m_infoOut->append(text); }

void Panels::appendPackage(const QString &line) {
    if (!line.trimmed().isEmpty())
        m_pkgList->addItem(line.trimmed());
}

void Panels::clearPackages() { m_pkgList->clear(); }
