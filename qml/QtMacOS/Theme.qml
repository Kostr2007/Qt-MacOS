pragma Singleton
import QtQuick

QtObject {
    property bool dark: true
    property int radius: 6
    property int rowHeight: 32

    // Application-owned accessibility preference. Durations are our Qt tuning,
    // not constants specified by Apple. No repeating or blocking animations.
    property bool reducedMotion: false
    property bool differentiateWithoutColor: false
    readonly property int pressDuration: reducedMotion ? 0 : 65
    readonly property int releaseDuration: reducedMotion ? 0 : 180
    readonly property int colorDuration: reducedMotion ? 0 : 110
    readonly property int revealDuration: reducedMotion ? 0 : 180
    readonly property int dismissDuration: reducedMotion ? 0 : 100
    readonly property int sidebarHoverDuration: reducedMotion ? 0 : 180
    readonly property int selectionDuration: reducedMotion ? 0 : 160
    readonly property int pageDuration: reducedMotion ? 0 : 180
    readonly property int motionEasing: Easing.OutCubic
    readonly property real pressedScale: reducedMotion ? 1 : 0.97
    readonly property color activeSelection: dark ? "#245a97" : "#0068cf"
    readonly property color inactiveSelection: dark ? "#555558" : "#d8d8db"

    readonly property color window: dark ? "#292a2d" : "#f5f5f5"
    readonly property color sidebar: dark ? "#36373a" : "#e9e9ec"
    readonly property color toolbar: dark ? "#303135" : "#f4f4f5"
    readonly property color content: dark ? "#242528" : "#ffffff"
    readonly property color text: dark ? "#f0f0f2" : "#252529"
    readonly property color secondary: dark ? "#afb0b8" : "#62636b"
    readonly property color border: dark ? "#47484d" : "#d4d4d8"
    readonly property color hover: dark ? "#303136" : "#f0f0f2"
    readonly property color selection: dark ? "#425a79" : "#d1e4fc"
    readonly property color accent: dark ? "#6cb7ff" : "#0068cf"
    readonly property color accentText: dark ? "#142338" : "#ffffff"
    readonly property color field: dark ? "#242529" : "#ffffff"
    readonly property color button: dark ? "#47484d" : "#ffffff"

    readonly property color settingsGroup: dark ? "#2e2e31" : "#f7f7f7"
    readonly property color settingsText: dark ? "#f0f0f2" : "#252529"
    readonly property color settingsSecondary: dark ? "#a6a6ac" : "#8b8b90"
    readonly property color settingsSeparator: dark ? "#414145" : "#e9e9ec"
    readonly property color settingsAccent: dark ? "#0a84ff" : "#007aff"
}
