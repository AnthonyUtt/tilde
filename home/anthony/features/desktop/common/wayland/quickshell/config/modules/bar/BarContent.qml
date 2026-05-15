import QtQuick
import QtQuick.Effects
import "../common"

Item {
    id: root

    property alias visibleRect: visibleRect

    Rectangle {
        id: visibleRect
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.rightMargin: Config.options.bar.margin
        anchors.topMargin: Config.options.bar.margin
        anchors.bottomMargin: Config.options.bar.margin
        width: Config.options.bar.width
        radius: Config.options.bar.cornerRadius
        color: Appearance.colors.background

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowBlur: 1.0
            shadowColor: Appearance.colors.shadow
            shadowVerticalOffset: 0
            shadowHorizontalOffset: 0
        }

        Item {
            id: contentArea
            anchors.fill: parent

            ClockWidget {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Appearance.sizes.clockPaddingBottom
            }
        }
    }
}
