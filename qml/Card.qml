import QtQuick
import QtQuick.Effects
import Odizinne.DNDBingo

Item {
    id: card

    property string imagePath: ""
    property bool isCompleted: false
    property bool isPlaceholder: imagePath === ""
    property bool hoverEnabled: true
    property alias cardImage: sourceItem

    signal clicked()

    opacity: 0

    // Transform origin at center for smooth rotation
    transformOrigin: Item.Center

    // Scale property for hover effect when not interactive
    scale: 1.0

    // Scale hover behavior (only when not interactive)
    Behavior on scale {
        enabled: !UserSettings.interactiveCards
        PropertyAnimation {
            duration: 150
            easing.type: Easing.OutQuad
        }
    }

    // Always create transforms, but only use them when enabled
    transform: [
        Rotation {
            id: xRotation
            angle: 0
            axis.x: 1
            axis.y: 0
            axis.z: 0
            origin.x: card.width / 2
            origin.y: card.height / 2

            Behavior on angle {
                enabled: !resetAnimation.running && UserSettings.interactiveCards
                PropertyAnimation {
                    duration: 50
                    easing.type: Easing.OutQuad
                }
            }
        },
        Rotation {
            id: yRotation
            angle: 0
            axis.x: 0
            axis.y: 1
            axis.z: 0
            origin.x: card.width / 2
            origin.y: card.height / 2

            Behavior on angle {
                enabled: !resetAnimation.running && UserSettings.interactiveCards
                PropertyAnimation {
                    duration: 50
                    easing.type: Easing.OutQuad
                }
            }
        }
    ]

    // Background for placeholders
    Rectangle {
        anchors.fill: parent
        color: isPlaceholder ? Qt.hsla(Math.random(), 0.3, 0.7, 1.0) : "white"
        radius: 8
        visible: isPlaceholder

        Text {
            anchors.centerIn: parent
            text: "🎲"
            font.pixelSize: parent.width * 0.3
            color: "white"
        }
    }

    // Source image (invisible)
    Image {
        id: sourceItem
        source: card.imagePath
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        visible: false
        mipmap: true
    }

    // Rounded image effect
    MultiEffect {
        source: sourceItem
        anchors.fill: sourceItem
        maskEnabled: true
        maskSource: mask
        visible: !card.isPlaceholder
    }

    // Mask for rounded corners
    Item {
        id: mask
        width: sourceItem.width
        height: sourceItem.height
        layer.enabled: true
        visible: false

        Rectangle {
            width: sourceItem.width
            height: sourceItem.height
            radius: 8  // Same as card border radius
            color: "black"
        }
    }

    // Border rectangle (on top of image)
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.color: isCompleted ? "#4CAF50" : "#ddd"
        border.width: 2
        radius: 8
    }

    // Completion overlay
    Rectangle {
        anchors.fill: parent
        color: "#4CAF50"
        opacity: card.isCompleted ? 0.7 : 0
        radius: 8

        Behavior on opacity {
            NumberAnimation { duration: 200 }
        }

        Text {
            anchors.centerIn: parent
            text: "✓"
            font.pixelSize: parent.width * 0.4
            color: "white"
            font.bold: true
            opacity: card.isCompleted ? 1.0 : 0.0

            Behavior on opacity {
                NumberAnimation { duration: 200 }
            }
        }
    }

    // Mouse area for interaction and hover tracking
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: card.hoverEnabled
        onClicked: card.clicked()
        cursorShape: card.hoverEnabled ? Qt.PointingHandCursor : Qt.ArrowCursor

        onPositionChanged: {
            if (card.hoverEnabled && containsMouse && UserSettings.interactiveCards) {
                updateTilt()
            }
        }

        onEntered: {
            if (!card.hoverEnabled) return

            if (UserSettings.interactiveCards) {
                updateTilt()
            } else {
                card.scale = 1.05
            }
        }

        onExited: {
            if (!card.hoverEnabled) return

            if (UserSettings.interactiveCards) {
                resetTilt()
            } else {
                card.scale = 1.0
            }
        }

        function updateTilt() {
            if (!UserSettings.interactiveCards) return

            let centerX = card.width / 2
            let centerY = card.height / 2

            let relativeX = (mouseX - centerX) / centerX
            let relativeY = (mouseY - centerY) / centerY

            relativeX = Math.max(-1, Math.min(1, relativeX))
            relativeY = Math.max(-1, Math.min(1, relativeY))

            let maxTilt = 15
            let rotationYAngle = relativeX * maxTilt
            let rotationXAngle = -relativeY * maxTilt

            xRotation.angle = rotationXAngle
            yRotation.angle = rotationYAngle
        }

        function resetTilt() {
            if (!UserSettings.interactiveCards) return
            resetAnimation.start()
        }
    }

    // Animation to reset tilt
    ParallelAnimation {
        id: resetAnimation

        PropertyAnimation {
            target: xRotation
            property: "angle"
            to: 0
            duration: 200
            easing.type: Easing.OutQuad
        }
        PropertyAnimation {
            target: yRotation
            property: "angle"
            to: 0
            duration: 200
            easing.type: Easing.OutQuad
        }
    }
}
