import QtQuick
import QtMacOS

// Animate the popup surface, leaving layout and application state intact.
Transition {
    id: motion
    property bool appearing: true
    ParallelAnimation {
        NumberAnimation {
            property: "opacity"
            from: motion.appearing ? 0 : 1
            to: motion.appearing ? 1 : 0
            duration: motion.appearing ? Theme.revealDuration : Theme.dismissDuration
            easing.type: Theme.motionEasing
        }
        NumberAnimation {
            property: "scale"
            from: motion.appearing && !Theme.reducedMotion ? 0.97 : 1
            to: !motion.appearing && !Theme.reducedMotion ? 0.97 : 1
            duration: motion.appearing ? Theme.revealDuration : Theme.dismissDuration
            easing.type: Theme.motionEasing
        }
    }
}
