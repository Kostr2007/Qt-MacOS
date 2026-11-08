import QtQuick

// Original vector glyphs for the reference scene. No icon font or private API.
Canvas {
    id: glyph
    property string name: "documents"
    property color color: "#b6b6b8"
    implicitWidth: 20
    implicitHeight: 20
    renderTarget: Canvas.Image
    onNameChanged: requestPaint()
    onColorChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        const c = getContext("2d");
        c.reset();
        c.clearRect(0, 0, width, height);
        c.save();
        c.scale(width / 24, height / 24);
        c.strokeStyle = color;
        c.fillStyle = color;
        c.lineWidth = 1.55;
        c.lineCap = "round";
        c.lineJoin = "round";

        function path(points, close) {
            c.beginPath();
            c.moveTo(points[0][0], points[0][1]);
            for (let i = 1; i < points.length; ++i)
                c.lineTo(points[i][0], points[i][1]);
            if (close)
                c.closePath();
            c.stroke();
        }
        function circle(x, y, r, filled) {
            c.beginPath();
            c.arc(x, y, r, 0, 2 * Math.PI);
            if (filled)
                c.fill();
            else
                c.stroke();
        }
        function box(x, y, w, h, radius) {
            c.beginPath();
            c.roundedRect(x, y, w, h, radius, radius);
            c.stroke();
        }

        switch (name) {
        case "back":
            path([[15, 4], [7, 12], [15, 20]]);
            break;
        case "forward":
            path([[9, 4], [17, 12], [9, 20]]);
            break;
        case "chevron":
            path([[7, 10], [12, 15], [17, 10]]);
            break;
        case "sort":
            path([[8, 9], [12, 5], [16, 9]]);
            path([[8, 15], [12, 19], [16, 15]]);
            break;
        case "list":
            for (let y = 6; y <= 18; y += 6) {
                circle(3.5, y, 0.9, true);
                path([[8, y], [21, y]]);
            }
            break;
        case "grid":
            for (let x = 3; x <= 17; x += 7)
                for (let y = 3; y <= 17; y += 7)
                    box(x, y, 4, 4, 0.6);
            break;
        case "share":
            path([[7, 9], [5, 9], [5, 21], [19, 21], [19, 9], [17, 9]]);
            path([[12, 15], [12, 2]]);
            path([[8, 6], [12, 2], [16, 6]]);
            break;
        case "tag":
            path([[3, 12], [12, 3], [19, 3], [21, 5], [21, 12], [12, 21], [3, 12]], true);
            circle(17, 7, 1.1, false);
            break;
        case "more":
            circle(12, 12, 9, false);
            circle(7.8, 12, 0.9, true);
            circle(12, 12, 0.9, true);
            circle(16.2, 12, 0.9, true);
            break;
        case "search":
            circle(10.5, 10.5, 7, false);
            path([[15.6, 15.6], [21, 21]]);
            break;
        case "airdrop":
            for (let r = 3; r <= 9; r += 3) {
                c.beginPath();
                c.arc(12, 10, r, Math.PI * 0.75, Math.PI * 2.25);
                c.stroke();
            }
            path([[12, 13], [8.5, 21], [15.5, 21]], true);
            break;
        case "desktop":
            box(2.5, 4, 19, 14, 1.5);
            path([[3, 14], [21, 14]]);
            path([[9, 21], [15, 21]]);
            path([[12, 18], [12, 21]]);
            break;
        case "applications":
            path([[8.5, 3.5], [18.5, 20.5]]);
            path([[14.5, 3.5], [4.5, 20.5]]);
            path([[3, 15.5], [21, 15.5]]);
            break;
        case "recents":
            circle(12, 12, 9, false);
            path([[12, 5.5], [12, 12], [16.2, 14.5]]);
            break;
        case "documents":
            path([[5, 2.5], [14, 2.5], [20, 8.5], [20, 21.5], [5, 21.5]], true);
            path([[14, 2.5], [14, 8.5], [20, 8.5]]);
            break;
        case "downloads":
            circle(12, 12, 9, false);
            path([[12, 5.5], [12, 16.5]]);
            path([[8, 12.5], [12, 16.5], [16, 12.5]]);
            break;
        case "cloud":
            c.beginPath();
            c.moveTo(6.5, 18);
            c.bezierCurveTo(0.5, 18, 0.5, 10, 6, 10);
            c.bezierCurveTo(6, 2, 18, 2, 18, 10);
            c.bezierCurveTo(24, 9, 25, 18, 19, 18);
            c.closePath();
            c.stroke();
            break;
        case "folder":
            path([[2.5, 6], [9, 6], [11, 8], [21.5, 8], [21.5, 20], [2.5, 20]], true);
            path([[2.5, 10], [21.5, 10]]);
            break;
        default:
            box(5, 3, 14, 18, 1);
        }
        c.restore();
    }
}
