pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property QtObject colors: QtObject {
        readonly property color background: "#1e1e2e"
        readonly property color foreground: "#cdd6f4"
        readonly property color accent: "#89b4fa"
        readonly property color divider: "#45475a"
        readonly property color shadow: "#80000000"
        readonly property color surface: "#181825"
    }

    readonly property QtObject sizes: QtObject {
        readonly property int barWidth: 36
        readonly property int barMargin: 8
        readonly property int barCornerRadius: 16
        readonly property int barShadowRadius: 24
        readonly property int clockFontSizeLarge: 18
        readonly property int clockFontSizeSmall: 11
        readonly property int clockDividerWidth: 24
        readonly property int clockDividerHeight: 1
        readonly property int clockSpacing: 2
        readonly property int clockPaddingBottom: 12
    }

    readonly property QtObject fonts: QtObject {
        readonly property string family: "Inter"
        readonly property string monoFamily: "JetBrains Mono"
    }

    readonly property QtObject animation: QtObject {
        readonly property int durationShort: 150
        readonly property int durationMedium: 250
    }
}
