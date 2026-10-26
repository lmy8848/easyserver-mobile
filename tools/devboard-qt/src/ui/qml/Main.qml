import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Controls.Material
import devboard

ApplicationWindow {
    id: root
    width: 1280
    height: 800
    minimumWidth: 960
    minimumHeight: 600
    visible: true
    title: qsTr("DevBoard · 移动端开发脚手架")
    color: Material.background

    Material.theme: Material.Dark
    Material.accent: Material.Indigo

    // ── 顶部设备栏 ──
    header: ToolBar {
        Material.elevation: 1

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 10

            Label {
                text: qsTr("DevBoard")
                font.pixelSize: 16
                font.bold: true
            }

            ComboBox {
                id: deviceBox
                model: Adb.devices
                textRole: "model"
                enabled: Adb.devices.length > 0
                onActivated: Adb.currentSerial =
                             Adb.devices[currentIndex].serial
            }

            Rectangle {
                width: 8; height: 8; radius: 4
                color: Adb.currentSerial ? "#43a047" : "#9e9e9e"
            }

            Label {
                text: Adb.currentSerial || qsTr("无连接")
                font.pixelSize: 12
                color: Material.hintTextColor
                Layout.fillWidth: true
            }

            Button {
                text: qsTr("无线配对")
                flat: true
                onClicked: pairDialog.open()
            }
            Button {
                text: qsTr("连接")
                flat: true
                onClicked: connectDialog.open()
            }
            ToolButton {
                text: qsTr("↻")
                onClicked: Adb.refreshDevices()
            }
        }
    }

    // ── 主体：左镜像占位 / 右面板 ──
    SplitView {
        anchors.fill: parent
        orientation: Qt.Horizontal

        // 镜像区（M1：image provider 渲染解码帧；M2 换 scene graph 纹理）
        Rectangle {
            SplitView.fillWidth: true
            SplitView.minimumWidth: 480
            color: "#000000"

            Image {
                anchors.fill: parent
                fillMode: Image.PreserveAspectFit
                source: Mirror.running ? ("image://mirror/last?" + Mirror.frameSeq)
                                       : ""
                asynchronous: true
                cache: false
            }

            Label {
                anchors.centerIn: parent
                visible: text !== ""
                text: Mirror.running ? Mirror.status
                                     : qsTr("未连接 · 点击「连接镜像」开始")
                color: "#9e9e9e"
            }

            Button {
                anchors.centerIn: parent
                visible: !Mirror.running
                text: qsTr("连接镜像")
                enabled: Adb.currentSerial !== ""
                onClicked: Mirror.connectTo(Adb.currentSerial)
            }
        }

        // 右侧工具面板
        Rectangle {
            SplitView.preferredWidth: Math.max(320, root.width * 0.28)
            SplitView.minimumWidth: 320
            color: Material.backgroundColor

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 0

                TabBar {
                    id: sideTabBar
                    Layout.fillWidth: true
                    TabButton { text: qsTr("终端") }
                    TabButton { text: qsTr("日志") }
                    TabButton { text: qsTr("设备") }
                    TabButton { text: qsTr("操作") }
                }

                StackLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    currentIndex: sideTabBar.currentIndex

                    // 终端输出
                    ScrollView {
                        ScrollBar.horizontal.policy: ScrollBar.AlwaysOn
                        TextArea {
                            id: termOut
                            readOnly: true
                            wrapMode: TextArea.NoWrap
                            font.family: "Consolas"
                            font.pixelSize: 11
                            color: "#b8c4cc"
                            text: qsTr("> 待机中。M4 接入交互式 shell。")
                            background: Rectangle { color: "#101418" }
                        }
                    }
                    // 日志/设备/操作（M4 接入）
                    Item {}
                    Item {}
                    Item {}
                }
            }
        }
    }

    // ── 底部状态栏 ──
    footer: ToolBar {
        Material.elevation: 0
        Label {
            anchors.centerIn: parent
            text: Adb.ready
                  ? qsTr("就绪 · 在线设备 %1 台 · 当前 %2")
                        .arg(Adb.devices.length).arg(Adb.currentSerial || "-")
                  : qsTr("adb 未就绪：请设置 DEVBOARD_ADB 或确认 bin/scrcpy27/adb.exe 存在")
            font.pixelSize: 11
            color: Material.hintTextColor
        }
    }

    // 命令输出 -> 终端 TextArea
    Connections {
        target: Adb
        function onCommandOutput(text) {
            termOut.text += text + "\n"
        }
        function onError(message) {
            termOut.text += "ERR: " + message + "\n"
        }
    }

    // 连接对话框
    Dialog {
        id: connectDialog
        title: qsTr("连接无线设备")
        standardButtons: Dialog.Cancel | Dialog.Ok
        anchors.centerIn: parent
        width: 360

        ColumnLayout {
            width: parent.width
            TextField {
                id: connectHost
                Layout.fillWidth: true
                placeholderText: qsTr("192.168.1.10:39423")
                onAccepted: connectDialog.accept()
            }
        }
        onAccepted: Adb.connectWireless(connectHost.text.trim())
    }

    // 配对向导占位（M4 接入完整流程）
    Dialog {
        id: pairDialog
        title: qsTr("无线配对向导")
        anchors.centerIn: parent
        standardButtons: Dialog.Close
        Label {
            text: qsTr("M4 接入：自动识别配对端口 + 6 位配对码")
        }
    }
}
