#pragma once

#include <QDialog>
#include <QString>
#include <QStringList>

class AdbClient;
class QLabel;
class QLineEdit;
class QListWidget;
class QPushButton;

// 无线调试配对向导。
//
// 手机上「开发者选项 → 无线调试」里点「使用配对码配对设备」会弹出地址+6 位码，
// 弹窗有效期约 2 分钟。这里做三件事：
//  1. adb mdns services 扫描局域网里的 _adb-tls-pairing / _adb-tls-connect 服务（可选）；
//  2. adb pair <地址> <码>；
//  3. 配对成功后自动 adb connect 到同 IP 的 connect 服务，让设备直接出现在设备列表。
class PairDialog : public QDialog {
    Q_OBJECT
public:
    explicit PairDialog(AdbClient *adb, QWidget *parent = nullptr);

signals:
    void deviceConnected(const QString &serial);

private slots:
    void onScan();
    void onMdns(const QStringList &services);
    void onPair();
    void onPairFinished(bool ok, const QString &message);
    void onItemClicked();

private:
    AdbClient *m_adb;
    QLineEdit *m_addrEdit = nullptr;
    QLineEdit *m_codeEdit = nullptr;
    QListWidget *m_list = nullptr;
    QLabel *m_result = nullptr;
    QPushButton *m_pairBtn = nullptr;
    // pairing 服务地址 → 同 IP 的 connect 服务地址
    QStringList m_connectAddrs;
    QString m_pairedAddr;
};
