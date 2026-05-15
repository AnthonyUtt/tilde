import QtQuick
import "../common"
import "../../services"

Column {
    id: root

    spacing: Appearance.sizes.clockSpacing

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: Time.hourStr
        color: Appearance.colors.foreground
        font.pixelSize: Appearance.sizes.clockFontSizeLarge
        font.family: Appearance.fonts.monoFamily
        horizontalAlignment: Text.AlignHCenter
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: Time.minuteStr
        color: Appearance.colors.foreground
        font.pixelSize: Appearance.sizes.clockFontSizeLarge
        font.family: Appearance.fonts.monoFamily
        horizontalAlignment: Text.AlignHCenter
    }

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        width: Appearance.sizes.clockDividerWidth
        height: Appearance.sizes.clockDividerHeight
        color: Appearance.colors.divider
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: Time.monthShortStr
        color: Appearance.colors.foreground
        font.pixelSize: Appearance.sizes.clockFontSizeSmall
        font.family: Appearance.fonts.monoFamily
        horizontalAlignment: Text.AlignHCenter
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: Time.dayOfMonthStr
        color: Appearance.colors.foreground
        font.pixelSize: Appearance.sizes.clockFontSizeSmall
        font.family: Appearance.fonts.monoFamily
        horizontalAlignment: Text.AlignHCenter
    }
}
