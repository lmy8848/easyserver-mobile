#include "Panels.h"

#include <QAbstractItemView>
#include <QCheckBox>
#include <QHBoxLayout>
#include <QLineEdit>
#include <QListWidget>
#include <QPlainTextEdit>
#include <QPushButton>
#include <QTextCursor>
#include <QTextEdit>
#include <QVBoxLayout>

Panels::Panels(QWidget *parent) : QTabWidget(parent) {
    setTabPosition(QTabWidget::North);
    buildShellTab();
    buildLogTab();
    buildInfoTab();
    buildActionTab();
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
    auto *clearBtn = new QPushButton(QStringLiteral("清空"), page);
    bar->addWidget(m_logFilter, 1);
    bar->addWidget(m_pauseLog);
    bar->addWidget(clearBtn);

    m_logOut = new QPlainTextEdit(page);
    m_logOut->setReadOnly(true);
    m_logOut->setPlaceholderText(QStringLiteral("logcat 输出（切换到此页时开始抓取）"));
    m_logOut->setMaximumBlockCount(4000);
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
    auto *recBtn = new QPushButton(QStringLiteral("录屏 30s"), page);
    row1->addWidget(shotBtn);
    row1->addWidget(recBtn);

    auto *row2 = new QHBoxLayout();
    auto *installBtn = new QPushButton(QStringLiteral("安装 APK"), page);
    auto *listBtn = new QPushButton(QStringLiteral("列出应用"), page);
    auto *uninstallBtn = new QPushButton(QStringLiteral("卸载选中"), page);
    row2->addWidget(installBtn);
    row2->addWidget(listBtn);
    row2->addWidget(uninstallBtn);

    m_pkgList = new QListWidget(page);
    m_pkgList->setSelectionMode(QAbstractItemView::SingleSelection);

    connect(shotBtn, &QPushButton::clicked, this, &Panels::screenshotRequested);
    connect(recBtn, &QPushButton::clicked, this, &Panels::recordRequested);
    connect(installBtn, &QPushButton::clicked, this, &Panels::installApkRequested);
    connect(listBtn, &QPushButton::clicked, this, &Panels::listPackagesRequested);
    connect(uninstallBtn, &QPushButton::clicked, this, [this]() {
        if (auto *item = m_pkgList->currentItem())
            emit uninstallPackageRequested(item->text());
    });

    lay->addLayout(row1);
    lay->addLayout(row2);
    lay->addWidget(m_pkgList, 1);
    addTab(page, QStringLiteral("操作"));
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

void Panels::clearLog() { m_logOut->clear(); }

void Panels::setInfo(const QString &text) { m_infoOut->setPlainText(text); }

void Panels::appendInfo(const QString &text) { m_infoOut->append(text); }

void Panels::appendPackage(const QString &line) {
    if (!line.trimmed().isEmpty())
        m_pkgList->addItem(line.trimmed());
}

void Panels::clearPackages() { m_pkgList->clear(); }
