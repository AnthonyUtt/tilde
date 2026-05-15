import QtQuick
import Quickshell
import Quickshell.Wayland
import "../common"

PanelWindow {
    id: root

    required property var modelData
    screen: modelData

    WlrLayershell.namespace: "quickshell-bar"
    WlrLayershell.layer: WlrLayer.Top

    anchors {
        top: true
        right: true
        bottom: true
    }

    implicitWidth: Config.options.bar.width + 2 * Config.options.bar.margin + Appearance.sizes.barShadowRadius

    color: "transparent"

    exclusiveZone: Config.options.bar.width + Config.options.bar.margin

    mask: Region {
        item: barContent.visibleRect
    }

    BarContent {
        id: barContent
        anchors.fill: parent
    }
}
