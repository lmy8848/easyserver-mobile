#include "PairDialog.h"

#include "AdbClient.h"

#include <QFormLayout>
#include <QHBoxLayout>
#include <QLabel>
#include <QLineEdit>
#include <QListWidget>
#include <QPushButton>
#include <QRegularExpression>
#include <QVBoxLayout>

#include <algorithm>

PairDialog::PairDialog(AdbClient *adb, QWidget *parent) : QDialog(parent), m_adb(adb) {
    setWindowTitle(QStringLiteral("无线调试配对"));
    setMinimumWidth(520);
    setModal(true);

    auto *hint = new QLabel(
        QStringLiteral("手机：设置 → 开发者选项 → 无线调试 →「使用配对码配对设备」。\n"
                       "弹窗里的 IP:端口 与 6 位配对码填到下面（弹窗 2 分钟内有效）。"),
        this);
    hint->setWordWrap(true);
    hint->setStyleSheet(QStringLiteral("color:#9aa4b2;"));

    m_list = new QListWidget(this);
    m_list->setMaximumHeight(120);
    m_list->setAlternatingRowColors(false);
    connect(m_list, &QListWidget::itemClicked, this, &PairDialog::onItemClicked);

    m_addrEdit = new QLineEdit(this);
    m_addrEdit->setPlaceholderText(QStringLiteral("192.168.1.10:37891"));
    m_codeEdit = new QLineEdit(this);
    m_codeEdit->setPlaceholderText(QStringLiteral("6 位配对码"));
    m_codeEdit->setMaxLength(10);

    auto *form = new QFormLayout;
    form->addRow(QStringLiteral("配对地址"), m_addrEdit);
    form->addRow(QStringLiteral("配对码"), m_codeEdit);

    auto *scanBtn = new QPushButton(QStringLiteral("扫描局域网设备"), this);
    connect(scanBtn, &QPushButton::clicked, this, &PairDialog::onScan);

    m_pairBtn = new QPushButton(QStringLiteral("配对"), this);
    m_pairBtn->setDefault(true);
    connect(m_pairBtn, &QPushButton::clicked, this, &PairDialog::onPair);

    auto *closeBtn = new QPushButton(QStringLiteral("关闭"), this);
    connect(closeBtn, &QPushButton::clicked, this, &QDialog::reject);

    m_result = new QLabel(this);
    m_result->setWordWrap(true);
    m_result->setStyleSheet(QStringLiteral("color:#9aa4b2;"));

    auto *actions = new QHBoxLayout;
    actions->addWidget(scanBtn);
    actions->addStretch(1);
    actions->addWidget(m_pairBtn);
    actions->addWidget(closeBtn);

    auto *root = new QVBoxLayout(this);
    root->addWidget(hint);
    root->addWidget(m_list);
    root->addLayout(form);
    root->addWidget(m_result);
    root->addLayout(actions);

    connect(m_adb, &AdbClient::mdnsServices, this, &PairDialog::onMdns);
    connect(m_adb, &AdbClient::pairFinished, this, &PairDialog::onPairFinished);
}

void PairDialog::onScan() {
    m_result->setText(QStringLiteral("正在扫描局域网无线调试服务…"));
    m_adb->scanMdns();
}

void PairDialog::onMdns(const QStringList &services) {
    m_list->clear();
    m_connectAddrs.clear();
    if (services.isEmpty()) {
        m_result->setText(
            QStringLiteral("未发现无线调试服务。请确认手机已打开「无线调试」，"
                           "或直接在手机上打开配对弹窗后手动填地址。"));
        return;
    }

    // pairing 服务排前面：配对弹窗打开期间才会广播
    QStringList sorted = services;
    std::sort(sorted.begin(), sorted.end(), [](const QString &a, const QString &b) {
        return a.startsWith(QStringLiteral("pairing")) && !b.startsWith(QStringLiteral("pairing"));
    });

    for (const QString &s : sorted) {
        const QStringList parts = s.split(QLatin1Char('|'));
        if (parts.size() != 3)
            continue;
        const QString kind = parts.at(0);
        const QString addr = parts.at(2);
        if (kind == QStringLiteral("connect")) {
            m_connectAddrs.append(addr);
            continue;
        }
        // 列表项只显示 pairing（配对用地址），connect 地址留作配对后自动连接
        auto *item = new QListWidgetItem(QStringLiteral("%1  (配对服务)").arg(addr), m_list);
        item->setData(Qt::UserRole, addr);
    }

    if (m_list->count() == 0)
        m_result->setText(QStringLiteral("未发现配对服务（手机未打开配对弹窗）。可手动填地址。"));
    else
        m_result->setText(QStringLiteral("点击列表里的地址自动填入，然后输入手机上的配对码。"));
}

void PairDialog::onItemClicked() {
    QListWidgetItem *item = m_list->currentItem();
    if (!item)
        return;
    m_addrEdit->setText(item->data(Qt::UserRole).toString());
    m_codeEdit->setFocus();
}

void PairDialog::onPair() {
    const QString addr = m_addrEdit->text().trimmed();
    const QString code = m_codeEdit->text().trimmed();
    if (addr.isEmpty() || code.isEmpty()) {
        m_result->setText(QStringLiteral("请填写配对地址和配对码。"));
        return;
    }
    if (!addr.contains(QLatin1Char(':'))) {
        m_result->setText(QStringLiteral("配对地址需要带端口，形如 192.168.1.10:37891。"));
        return;
    }
    m_pairedAddr = addr;
    m_pairBtn->setEnabled(false);
    m_result->setText(QStringLiteral("正在配对…"));
    m_adb->pair(addr, code);
}

void PairDialog::onPairFinished(bool ok, const QString &message) {
    m_pairBtn->setEnabled(true);
    if (!ok) {
        m_result->setText(QStringLiteral("配对失败：%1").arg(message));
        return;
    }

    // 配对成功后要 connect 才能进设备列表：优先用扫描到的同 IP connect 服务地址，
    // 没有就按 pairing 端口 +1 猜（Android 无线调试的 connect 端口通常紧跟 pairing）。
    QString target;
    const QString ip = m_pairedAddr.section(QLatin1Char(':'), 0, 0);
    for (const QString &c : m_connectAddrs) {
        if (c.section(QLatin1Char(':'), 0, 0) == ip) {
            target = c;
            break;
        }
    }
    if (target.isEmpty()) {
        m_result->setText(
            QStringLiteral("配对成功。请重新打开手机「无线调试」页面查看 IP:端口，"
                           "在设备栏点「刷新」，或手动用 adb connect 连接。"));
        emit deviceConnected(QString());
        return;
    }

    m_result->setText(QStringLiteral("配对成功，正在连接 %1…").arg(target));
    m_adb->connectDevice(target);
    emit deviceConnected(target);
}
