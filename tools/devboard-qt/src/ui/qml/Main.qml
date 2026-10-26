import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Dialogs
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

    ListModel { id: mdnsModel }

    // 追加文本到终端/日志区（保持底部跟随）
    function appendTo(area, chunk) {
        const atEnd = area.length === 0 || area.cursorPosition === area.length
        area.insert(area.length, chunk)
        if (atEnd) area.cursorPosition = area.length
    }

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
            Button {
                text: qsTr("断开")
                flat: true
                visible: Mirror.running
                onClicked: Mirror.disconnect()
            }
            ToolButton {
                text: qsTr("↻")
                onClicked: Adb.refreshDevices()
            }
        }
    }

    // ── 主体：左镜像 / 右面板 ──
    SplitView {
        anchors.fill: parent
        orientation: Qt.Horizontal

        // 镜像区（scrcpy-server 直连 + 解码线程 + 触摸注入）
        Rectangle {
            SplitView.fillWidth: true
            SplitView.minimumWidth: 480
            color: "#000000"

            Image {
                anchors.fill: parent
                fillMode: Image.PreserveAspectFit
                source: Mirror.running ? ("image://mirror/last?" + Mirror.frameSeq)
                                       : ""
                asynchronous: false // 同步取帧：不吃线程池排队，延迟最低
                cache: false
            }

            Label {
                anchors.centerIn: parent
                visible: text !== ""
                text: Mirror.running ? Mirror.status
                                     : qsTr("未连接 · 选好设备后自动连接")
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

                    // ── 0 终端：交互式 shell ──
                    ColumnLayout {
                        spacing: 6

                        RowLayout {
                            Layout.fillWidth: true
                            Button {
                                text: Tools.shellRunning ? qsTr("停止") : qsTr("启动 shell")
                                enabled: Adb.currentSerial !== ""
                                onClicked: Tools.shellRunning
                                           ? Tools.shellStop()
                                           : Tools.shellStart(Adb.currentSerial)
                            }
                            Button {
                                text: qsTr("清屏")
                                flat: true
                                onClicked: shellOut.clear()
                            }
                            Item { Layout.fillWidth: true }
                            Label {
                                text: Tools.shellRunning ? Adb.currentSerial : ""
                                font.pixelSize: 11
                                color: Material.hintTextColor
                            }
                        }

                        ScrollView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            TextArea {
                                id: shellOut
                                readOnly: true
                                wrapMode: TextArea.NoWrap
                                font.family: "Consolas"
                                font.pixelSize: 11
                                color: "#b8c4cc"
                                text: qsTr("> 待机中。启动 shell 后可直接交互；未启动时输入命令走一次性执行。\n")
                                background: Rectangle { color: "#101418" }
                            }
                        }

                        TextField {
                            id: shellInput
                            Layout.fillWidth: true
                            placeholderText: qsTr("输入命令，如 ls /sdcard")
                            font.family: "Consolas"
                            font.pixelSize: 12
                            onAccepted: {
                                if (text.trim() === "") return
                                if (Tools.shellRunning) Tools.shellSend(text)
                                else Adb.runCommand(text)
                                text = ""
                            }
                        }
                    }

                    // ── 1 日志：logcat 流式 ──
                    ColumnLayout {
                        spacing: 6

                        RowLayout {
                            Layout.fillWidth: true
                            Button {
                                text: Tools.logcatRunning ? qsTr("停止") : qsTr("启动 logcat")
                                enabled: Adb.currentSerial !== ""
                                onClicked: Tools.logcatRunning
                                           ? Tools.logcatStop()
                                           : Tools.logcatStart(Adb.currentSerial)
                            }
                            Button {
                                text: Tools.logPaused ? qsTr("继续") : qsTr("暂停")
                                flat: true
                                enabled: Tools.logcatRunning
                                onClicked: Tools.logPaused = !Tools.logPaused
                            }
                            Button {
                                text: qsTr("清空")
                                flat: true
                                onClicked: Tools.logcatClear()
                            }
                        }

                        TextField {
                            id: logFilterField
                            Layout.fillWidth: true
                            placeholderText: qsTr("过滤（如 ANR、FATAL、你的 TAG）")
                            font.pixelSize: 12
                            onTextEdited: Tools.setLogFilter(text)
                        }

                        ScrollView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            TextArea {
                                id: logOut
                                readOnly: true
                                wrapMode: TextArea.NoWrap
                                font.family: "Consolas"
                                font.pixelSize: 11
                                color: "#b8c4cc"
                                background: Rectangle { color: "#101418" }
                            }
                        }
                    }

                    // ── 2 设备：信息面板 ──
                    ColumnLayout {
                        spacing: 6

                        RowLayout {
                            Layout.fillWidth: true
                            Button {
                                text: qsTr("刷新信息")
                                enabled: Adb.currentSerial !== "" && !Tools.actionBusy
                                onClicked: Tools.refreshInfo(Adb.currentSerial)
                            }
                            Item { Layout.fillWidth: true }
                            Label {
                                text: Adb.currentSerial
                                font.pixelSize: 11
                                color: Material.hintTextColor
                            }
                        }

                        ScrollView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            TextArea {
                                id: infoOut
                                readOnly: true
                                wrapMode: TextArea.Wrap
                                font.family: "Consolas"
                                font.pixelSize: 12
                                color: "#c8d2da"
                                text: Tools.infoText
                                background: Rectangle { color: "#101418" }
                            }
                        }
                    }

                    // ── 3 操作：截图 / 录屏 / APK ──
                    ColumnLayout {
                        spacing: 6

                        GridLayout {
                            Layout.fillWidth: true
                            columns: 3
                            columnSpacing: 6
                            rowSpacing: 6

                            Button {
                                text: qsTr("截图")
                                enabled: Adb.currentSerial !== "" && !Tools.actionBusy
                                onClicked: Tools.screenshot(Adb.currentSerial)
                            }
                            Button {
                                text: qsTr("录屏 30s")
                                enabled: Adb.currentSerial !== "" && !Tools.actionBusy
                                onClicked: Tools.recordScreen(Adb.currentSerial)
                            }
                            Button {
                                text: qsTr("安装 APK")
                                enabled: Adb.currentSerial !== "" && !Tools.actionBusy
                                onClicked: apkDialog.open()
                            }
                            Button {
                                text: qsTr("列出应用")
                                enabled: Adb.currentSerial !== "" && !Tools.actionBusy
                                onClicked: Tools.listPackages(Adb.currentSerial)
                            }
                            Button {
                                text: qsTr("卸载")
                                enabled: Adb.currentSerial !== "" && !Tools.actionBusy
                                         && pkgField.text.trim() !== ""
                                onClicked: Tools.uninstallApk(Adb.currentSerial, pkgField.text)
                            }
                            TextField {
                                id: pkgField
                                Layout.fillWidth: true
                                placeholderText: qsTr("com.example.app")
                                font.pixelSize: 11
                            }
                        }

                        Label {
                            Layout.fillWidth: true
                            text: Tools.actionStatus
                            wrapMode: Text.WordWrap
                            font.pixelSize: 11
                            color: Material.hintTextColor
                        }

                        Label {
                            text: qsTr("第三方应用（点击填入卸载框）")
                            font.pixelSize: 11
                            color: Material.hintTextColor
                        }

                        ListView {
                            id: pkgList
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            model: Tools.packages
                            spacing: 2
                            delegate: ItemDelegate {
                                width: pkgList.width
                                height: 30
                                text: modelData
                                font.pixelSize: 11
                                onClicked: pkgField.text = modelData
                            }
                        }
                    }
                }
            }
        }
    }

    // ── 底部状态栏 ──
    footer: ToolBar {
        Material.elevation: 0
        Label {
            anchors.centerIn: parent
            text: {
                if (!Adb.ready)
                    return qsTr("adb 未就绪：请设置 DEVBOARD_ADB")
                if (Tools.actionBusy) return Tools.actionStatus
                if (Mirror.running)
                    return qsTr("● H.264 %1fps · %2 kbps · 链路 %3ms · %4x%5")
                        .arg(Mirror.fps).arg(Mirror.bitrateKbps)
                        .arg(Mirror.latencyMs)
                        .arg(Mirror.videoWidth).arg(Mirror.videoHeight)
                return qsTr("就绪 · 在线设备 %1 台 · 当前 %2")
                        .arg(Adb.devices.length).arg(Adb.currentSerial || "-")
            }
            font.pixelSize: 11
            color: Material.hintTextColor
        }
    }

    // 命令输出 -> 终端 TextArea；设备切换 -> 自动刷新信息
    Connections {
        target: Adb
        function onCommandOutput(text) {
            appendTo(shellOut, text + "\n")
        }
        function onError(message) {
            appendTo(shellOut, "ERR: " + message + "\n")
        }
        function onCurrentSerialChanged() {
            if (Adb.currentSerial !== "") Tools.refreshInfo(Adb.currentSerial)
        }
    }

    // Tools 增量流 → 终端/日志
    Connections {
        target: Tools
        function onShellAppended(chunk) { appendTo(shellOut, chunk) }
        function onShellViewReset() { shellOut.clear() }
        function onLogAppended(chunk) { appendTo(logOut, chunk) }
        function onLogViewReset() {
            logOut.clear()
            logOut.insert(0, Tools.logText())
        }
    }

    // 连接对话框（已知无线调试端口时直连）
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

    // 无线配对向导：mDNS 扫描 → 配对 → 连接
    Dialog {
        id: pairDialog
        title: qsTr("无线配对向导")
        anchors.centerIn: parent
        width: 440
        standardButtons: Dialog.Close

        ColumnLayout {
            width: parent.width
            spacing: 8

            Label {
                Layout.fillWidth: true
                text: qsTr("手机「开发者选项 → 无线调试 → 使用配对码配对设备」，弹窗里有 IP:配对端口 和 6 位码")
                wrapMode: Text.WordWrap
                font.pixelSize: 11
                color: Material.hintTextColor
            }

            RowLayout {
                Layout.fillWidth: true
                Button {
                    text: qsTr("扫描配对服务")
                    enabled: !Adb.busy
                    onClicked: Adb.mdnsScan()
                }
                Label {
                    text: qsTr("同一 Wi-Fi 下自动发现，点击结果填入对应输入框")
                    font.pixelSize: 11
                    color: Material.hintTextColor
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }
            }

            ListView {
                id: mdnsList
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(contentHeight, 96)
                model: mdnsModel
                clip: true
                spacing: 2
                delegate: ItemDelegate {
                    width: mdnsList.width
                    height: 28
                    font.pixelSize: 11
                    text: (kind === "pairing" ? qsTr("[配对] ") : qsTr("[连接] ")) + name
                                          + "  →  " + addr
                    onClicked: {
                        if (kind === "pairing") pairAddr.text = addr
                        else connectAddr.text = addr
                    }
                }
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: 8
                Label { text: qsTr("配对地址") }
                TextField {
                    id: pairAddr
                    Layout.fillWidth: true
                    placeholderText: qsTr("192.168.1.10:40001")
                }
                Label { text: qsTr("配对码") }
                TextField {
                    id: pairCode
                    Layout.fillWidth: true
                    placeholderText: qsTr("6 位数字")
                }
            }

            Button {
                text: qsTr("配对")
                enabled: pairAddr.text.trim() !== "" && pairCode.text.trim() !== ""
                         && !Adb.busy
                onClicked: Adb.pairWireless(pairAddr.text.trim(), pairCode.text.trim())
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: 8
                Label { text: qsTr("连接地址") }
                TextField {
                    id: connectAddr
                    Layout.fillWidth: true
                    placeholderText: qsTr("无线调试主页的 IP:端口")
                }
            }

            Button {
                text: qsTr("连接")
                enabled: connectAddr.text.trim() !== "" && !Adb.busy
                onClicked: {
                    Adb.connectWireless(connectAddr.text.trim())
                }
            }

            Label {
                id: pairMsg
                Layout.fillWidth: true
                text: qsTr("配对成功后，填「无线调试」主页面的 IP:端口 再点连接")
                wrapMode: Text.WordWrap
                font.pixelSize: 11
                color: Material.hintTextColor
            }

            Connections {
                target: Adb
                function onPairFinished(ok, message) {
                    pairMsg.text = (ok ? "✔ " : "✘ ") + message
                    pairMsg.color = ok ? "#43a047" : "#e53935"
                }
                function onMdnsServices(services) {
                    mdnsModel.clear()
                    for (let i = 0; i < services.length; ++i) {
                        const parts = services[i].split("|")
                        mdnsModel.append({ kind: parts[0], name: parts[1], addr: parts[2] })
                    }
                }
            }
        }
    }

    FileDialog {
        id: apkDialog
        title: qsTr("选择 APK 安装包")
        nameFilters: [qsTr("APK 安装包 (*.apk)")]
        onAccepted: Tools.installApk(Adb.currentSerial, selectedFile)
    }
}
