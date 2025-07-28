pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls.FluentWinUI3
import Odizinne.DNDBingo

ApplicationWindow {
    id: root
    visible: true
    width: 1400
    height: 805
    minimumWidth: 800
    minimumHeight: 600
    title: "D&D Bingo"

    header: Rectangle {
        height: 60
        color: Qt.rgba(0, 0, 0, 0.3)

        Text {
            anchors.centerIn: parent
            text: "D&D Bingo"
            color: "white"
            font.pixelSize: 24
            font.bold: true
        }

        // Card count display
        Switch {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: 20
            text: "Interactive cards"
            checked: UserSettings.interactiveCards
            onClicked: UserSettings.interactiveCards = checked
        }

        // New Game button
        Rectangle {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: 20
            width: 120
            height: 40
            color: "#4CAF50"
            radius: 20

            MouseArea {
                anchors.fill: parent
                onClicked: bingoGrid.startGame()
                cursorShape: Qt.PointingHandCursor
            }

            Text {
                anchors.centerIn: parent
                text: "New Game"
                color: "white"
                font.pixelSize: 14
                font.bold: true
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#1a1a2e" }
            GradientStop { position: 1.0; color: "#16213e" }
        }

        BingoGrid {
            id: bingoGrid
            anchors.fill: parent
            anchors.margins: 20

            onCardCompleted: function(index) {
                // You can add sound effects or other feedback here
                console.log("Card completed:", index)
            }
        }

        // Instructions (shown when no cards available)
        Rectangle {
            anchors.centerIn: parent
            width: 400
            height: 200
            color: Qt.rgba(0, 0, 0, 0.7)
            radius: 10
            visible: CardManager.cardCount === 0

            Column {
                anchors.centerIn: parent
                spacing: 20

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "No Cards Found!"
                    color: "white"
                    font.pixelSize: 18
                    font.bold: true
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "To add cards:\n1. Place image files in resources/cards/\n2. Add them to resources/cards/cards.qrc\n3. Rebuild the app"
                    color: "white"
                    font.pixelSize: 14
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }
}
