import QtQuick

// Original miniature artwork; no Finder screenshots or Apple image assets.
Canvas {
    property int variant: 0
    implicitWidth: 18
    implicitHeight: 14
    onVariantChanged: requestPaint()
    onPaint: {
        const c = getContext("2d");
        c.reset();
        c.clearRect(0, 0, width, height);
        c.scale(width / 24, height / 18);
        c.fillStyle = "#efefee";
        c.fillRect(0, 0, 24, 18);
        c.fillStyle = "#55595e";
        c.fillRect(1, 1, 22, 16);
        if (variant < 6) {
            c.fillStyle = "#fafaf8";
            c.fillRect(2, 2, 20, 14);
            c.fillStyle = "#a0a7ac";
            for (let x = 4; x < 21; x += 3) {
                for (let y = 4; y < 15; y += 3)
                    c.fillRect(x, y, 1, 1);
            }
            c.fillStyle = "#c9ced2";
            c.fillRect(4, 3, 16, 1);
        } else {
            c.fillStyle = variant === 6 ? "#4f9ac2" : variant === 7 ? "#aa98c1" : "#7291b0";
            c.fillRect(2, 2, 20, 14);
            c.fillStyle = "#d9cfb1";
            c.beginPath();
            c.moveTo(2, 12);
            c.lineTo(11, 4);
            c.lineTo(17, 12);
            c.closePath();
            c.fill();
            c.fillStyle = "#4a5659";
            c.beginPath();
            c.moveTo(7, 16);
            c.lineTo(18, 5);
            c.lineTo(22, 12);
            c.lineTo(22, 16);
            c.closePath();
            c.fill();
            c.fillStyle = "#30463b";
            c.fillRect(2, 13, 20, 3);
        }
    }
}
