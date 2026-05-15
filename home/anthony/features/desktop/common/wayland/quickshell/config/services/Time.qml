pragma Singleton

import QtQuick
import Quickshell
import "../modules/common"

Singleton {
    id: root

    property date now: new Date()

    readonly property string hourStr: Qt.formatDateTime(now, Config.options.clock.use24Hour ? "HH" : "hh")
    readonly property string minuteStr: Qt.formatDateTime(now, "mm")
    readonly property string monthShortStr: Qt.formatDateTime(now, "MMM")
    readonly property string dayOfMonthStr: Qt.formatDateTime(now, "dd")

    Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: root.now = new Date()
    }
}
