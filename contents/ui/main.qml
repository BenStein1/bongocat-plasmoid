import QtQuick
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

PlasmoidItem {
    id: root

    implicitWidth: 388
    implicitHeight: 86

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    property url idleFrame: Qt.resolvedUrl("../images/idle-eyes-closed.png")
    property var activeFrames: [
        Qt.resolvedUrl("../images/both-hands-up.png"),
        Qt.resolvedUrl("../images/both-hands-down.png"),
        Qt.resolvedUrl("../images/left-hand-up.png"),
        Qt.resolvedUrl("../images/right-hand-up.png")
    ]

    property var moves: [
        [1, 0],
        [1, 2],
        [1, 3]
    ]

    property real cpuPercent: 0
    property int idleThreshold: 8
    property bool wasIdle: true
    property bool debugVisible: false

    property int currentMove: -1
    property int currentSide: 0
    property int beatsRemaining: 0

    property int idleBlinkMin: 1800
    property int idleBlinkMax: 15000

    property double _prevIdle: 0
    property double _prevTotal: 0
    property bool _havePrev: false

    function intervalFor(percent) {
        var ms = Math.ceil(5000 / Math.sqrt(percent + 35) - 400)
        if (ms < 70)
            ms = 70
        if (ms > 600)
            ms = 600
        return ms
    }

    function randInt(min, max) {
        return Math.floor(min + Math.random() * (max - min + 1))
    }

    function nextIdleBlinkInterval() {
        return randInt(idleBlinkMin, idleBlinkMax)
    }

    function beatsForMove(percent) {
        var base = 10 - Math.floor(Math.min(100, percent) / 20)
        return Math.max(4, base + randInt(0, 3))
    }

    function pickNewMove() {
        var next = randInt(0, moves.length - 1)
        if (moves.length > 1 && next === currentMove) {
            next = (next + 1 + randInt(0, moves.length - 2)) % moves.length
        }
        currentMove = next
        currentSide = 0
        beatsRemaining = beatsForMove(cpuPercent)
    }

    function pollCpu() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///proc/stat")
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return

            var txt = xhr.responseText || ""
            var firstLine = txt.split("\n")[0]
            if (!firstLine)
                return

            var parts = firstLine.trim().split(/\s+/)
            if (parts.length < 5 || parts[0] !== "cpu")
                return

            var user = parseInt(parts[1]) || 0
            var nice = parseInt(parts[2]) || 0
            var system = parseInt(parts[3]) || 0
            var idle = parseInt(parts[4]) || 0
            var iowait = parseInt(parts[5]) || 0
            var irq = parseInt(parts[6]) || 0
            var softirq = parseInt(parts[7]) || 0
            var steal = parseInt(parts[8] || "0") || 0

            var idleAll = idle + iowait
            var nonIdle = user + nice + system + irq + softirq + steal
            var total = idleAll + nonIdle

            if (!root._havePrev) {
                root._prevIdle = idleAll
                root._prevTotal = total
                root._havePrev = true
                return
            }

            var totald = total - root._prevTotal
            var idled = idleAll - root._prevIdle

            root._prevTotal = total
            root._prevIdle = idleAll

            if (totald > 0) {
                var usage = (1.0 - (idled / totald)) * 100.0
                if (usage < 0)
                    usage = 0
                if (usage > 100)
                    usage = 100

                var nowIdle = (usage < root.idleThreshold)

                if (nowIdle && !root.wasIdle) {
                    sprite.source = root.idleFrame
                    currentMove = -1
                    currentSide = 0
                    beatsRemaining = 0
                    anim.interval = root.nextIdleBlinkInterval()
                    anim.restart()
                } else if (!nowIdle && root.wasIdle) {
                    currentMove = -1
                    currentSide = 0
                    beatsRemaining = 0
                    anim.interval = root.intervalFor(usage)
                    anim.restart()
                } else if (!nowIdle) {
                    anim.interval = root.intervalFor(usage)
                }

                root.wasIdle = nowIdle
                root.cpuPercent = usage
            }
        }
        xhr.send()
    }

    Timer {
        id: poll
        repeat: true
        running: true
        interval: 500

        onTriggered: pollCpu()

        Component.onCompleted: pollCpu()
    }

    Image {
        id: sprite
        anchors.fill: parent
        fillMode: Image.PreserveAspectFit
        smooth: true
        source: root.idleFrame
        sourceSize.width: width
        sourceSize.height: height
    }

    Rectangle {
        visible: root.debugVisible
        color: "#66000000"
        radius: 4
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: 6
        height: 22
        width: dbg.implicitWidth + 12

        Text {
            id: dbg
            anchors.centerIn: parent
            color: "white"
            font.pixelSize: 14
            text: root.cpuPercent.toFixed(1) + "%"
        }
    }

    Timer {
        id: anim
        repeat: true
        running: true
        interval: root.nextIdleBlinkInterval()

        onTriggered: {
            if (root.wasIdle) {
                sprite.source = (sprite.source === root.idleFrame)
                    ? root.activeFrames[1]
                    : root.idleFrame

                currentMove = -1
                currentSide = 0
                beatsRemaining = 0
                anim.interval = root.nextIdleBlinkInterval()
            } else {
                if (currentMove < 0 || beatsRemaining <= 0) {
                    pickNewMove()
                }

                var pair = moves[currentMove]
                var target = pair[currentSide]

                sprite.source = root.activeFrames[target]
                currentSide = 1 - currentSide
                beatsRemaining -= 1
            }
        }
    }
}
