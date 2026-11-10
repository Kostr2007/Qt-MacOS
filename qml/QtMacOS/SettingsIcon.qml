pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Window
import QtQuick.Shapes

// Original vector symbols. No system font glyphs, raster canvas or Apple assets.
Item {
    id: glyph
    property string name: "mouse"
    property color color: "white"
    implicitWidth: 28
    implicitHeight: 28
    readonly property var symbols: ({
        search: {stroke: "M18 11 A7 7 0 1 1 4 11 A7 7 0 1 1 18 11 M16 16 L23 23"},
        notification: {fill: "M14 4.8 C10.5 4.8 8.2 7.2 8.2 10.6 L8.2 15.2 C8.2 17 7.6 18 6.5 19.2 Q6 20.2 7.2 20.2 L20.8 20.2 Q22 20.2 21.5 19.2 C20.4 18 19.8 17 19.8 15.2 L19.8 10.6 C19.8 7.2 17.5 4.8 14 4.8 Z M11.7 21.6 C12 24.3 16 24.3 16.3 21.6 Z M13 3 L15 3 L15 5 L13 5 Z"},
        internet: {stroke: "M18.4 9.8 L17.8 16.4 C17.5 19.4 22.4 19.2 23 15.2 C24 8.3 19.5 4.5 14.2 4.5 C8.5 4.5 4.5 8.6 4.5 14.3 C4.5 20 8.7 23.4 14.2 23.4 C16.1 23.4 17.6 23 19 22.2 M18.1 13.4 C18.1 8 10 8.7 9.7 14.4 C9.4 20 17.6 19.3 18.1 13.4 Z"},
        sound: {fill: "M5 11 L9 11 L15 6 L15 22 L9 17 L5 17 Z", stroke: "M18 10 C20.5 12 20.5 16 18 18 M21 7 C25.3 10.5 25.3 17.5 21 21"},
        focus: {fill: "M18.4 4.6 C8 1 1.1 13 7.5 20.4 C12.6 26.3 22.4 23.2 23.3 16 C15 20.1 9.2 10.5 18.4 4.6 Z"},
        screentime: {stroke: "M8 4.5 L20 4.5 L20 8 C20 10.3 16 12 15 14 C16 16 20 17.7 20 20 L20 23.5 L8 23.5 L8 20 C8 17.7 12 16 13 14 C12 12 8 10.3 8 8 Z M10.5 8 L17.5 8 M10.5 20.5 L17.5 20.5"},
        lock: {fill: "M8 11 L20 11 Q21 11 21 13 L21 22 Q21 24 19 24 L9 24 Q7 24 7 22 L7 13 Q7 11 8 11 Z M12.5 15 L12.5 19 L15.5 19 L15.5 15 Z", stroke: "M9 11 L9 8 A5 5 0 0 1 19 8 L19 11"},
        password: {fill: "M8 11 L20 11 Q21 11 21 13 L21 22 Q21 24 19 24 L9 24 Q7 24 7 22 L7 13 Q7 11 8 11 Z M12.5 15 L12.5 19 L15.5 19 L15.5 15 Z", stroke: "M9 11 L9 8 A5 5 0 0 1 19 8 L19 11"},
        privacy: {stroke: "M14 3.5 L22 7 L22 13.8 C22 18.3 19 21.8 14 24 C9 21.8 6 18.3 6 13.8 L6 7 Z M10 13.7 L13 16.7 L18.5 10.7"},
        users: {fill: "M17.5 8 A3.5 3.5 0 1 1 10.5 8 A3.5 3.5 0 1 1 17.5 8 Z M9 20 C9 12.5 19 12.5 19 20 L19 23 L9 23 Z M8.6 10.5 A2.6 2.6 0 1 1 3.4 10.5 A2.6 2.6 0 1 1 8.6 10.5 Z M19.4 10.5 A2.6 2.6 0 1 1 24.6 10.5 A2.6 2.6 0 1 1 19.4 10.5 Z M2.5 22 L2.5 18 C2.5 14 7.5 14 7.5 18 L7.5 22 Z M20.5 22 L20.5 18 C20.5 14 25.5 14 25.5 18 L25.5 22 Z"},
        cloud: {fill: "M7.5 22 C.8 22 1.5 12.4 7.6 12.4 C9 2.2 23.2 3.7 23 13 C29.4 15.5 25.5 22 21 22 Z"},
        keyboard: {stroke: "M5 7 L23 7 Q25 7 25 9 L25 20 Q25 22 23 22 L5 22 Q3 22 3 20 L3 9 Q3 7 5 7 Z M7 11 L8 11 M12 11 L13 11 M17 11 L18 11 M22 11 L22 11.2 M7 15 L8 15 M12 15 L13 15 M17 15 L18 15 M22 15 L22 15.2 M9 18.5 L19 18.5"},
        printer: {stroke: "M8 10 L8 4 L20 4 L20 10 M8 21 L5 21 Q3 21 3 19 L3 12 Q3 10 5 10 L23 10 Q25 10 25 12 L25 19 Q25 21 23 21 L20 21 M8 17 L20 17 L20 25 L8 25 Z M11 20 L17 20 M11 22.5 L17 22.5 M21 13 L21.1 13"},
        mouse: {fill: "M14 3 C5.5 3 6.5 11 6.5 16 C6.5 28 21.5 28 21.5 16 L21.5 11 C21.5 6 18.9 3 14 3 Z M13 7 L13 12 L15 12 L15 7 Z"},
        wallet: {stroke: "M6 5 L22 5 Q24 5 24 7 L24 21 Q24 23 22 23 L6 23 Q4 23 4 21 L4 7 Q4 5 6 5 Z"},
        game: {}
    })
    readonly property var symbol: symbols[name] || symbols.mouse
    Shape {
        id: vectorShape
        width: 28; height: 28
        antialiasing: true
        Component.onCompleted: {
            // CurveRenderer has analytic edge AA in newer Qt. Keep a guarded
            // MSAA fallback for the library's older Qt 6 kits.
            if ("preferredRendererType" in vectorShape && typeof Shape.CurveRenderer !== "undefined")
                vectorShape.preferredRendererType = Shape.CurveRenderer;
        }
        // GeometryRenderer needs MSAA for curved edges. Size the backing layer
        // for the final display size, not the 28-unit drawing coordinates.
        // QPainter already antialiases paths; fractional-DPI raster layers can
        // clip them, so reserve multisampled layers for the RHI renderer.
        layer.enabled: GraphicsInfo.api !== GraphicsInfo.Software
        layer.samples: 4
        layer.smooth: true
        layer.textureSize: Qt.size(Math.ceil(glyph.width * Screen.devicePixelRatio), Math.ceil(glyph.height * Screen.devicePixelRatio))
        transform: Scale { xScale: glyph.width / 28; yScale: glyph.height / 28 }
        ShapePath {
            strokeColor: "transparent"
            fillColor: glyph.color
            fillRule: ShapePath.OddEvenFill
            PathSvg { path: glyph.symbol.fill || "" }
        }
        ShapePath {
            strokeColor: glyph.color
            strokeWidth: 1.75
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathSvg { path: glyph.symbol.stroke || "" }
        }
    }
    // Original multicolour tiles use geometry rather than a font or bitmap.
    Repeater {
        model: glyph.name === "game" ? ["#ffb62e", "#f04e82", "#7978e9", "#39c99f"] : []
        Rectangle {
            id: gameDot
            required property int index
            required property string modelData
            x: (gameDot.index === 0 || gameDot.index === 3 ? 5 : 13) * glyph.width / 28
            y: (gameDot.index < 2 ? 5 : 13) * glyph.height / 28
            width: glyph.width * 10 / 28; height: glyph.height * 10 / 28
            radius: width / 2
            antialiasing: true
            color: gameDot.modelData
        }
    }
    Repeater {
        model: glyph.name === "wallet" ? ["#f6b63d", "#72c8ac", "#e77680"] : []
        Rectangle {
            id: walletStripe
            required property int index
            required property string modelData
            x: 6.5 * glyph.width / 28; y: (8 + walletStripe.index * 4) * glyph.height / 28
            width: glyph.width * 15 / 28; height: glyph.height * 3.5 / 28
            radius: height / 4
            antialiasing: true
            color: walletStripe.modelData
        }
    }
}
