import QtQuick
import Odizinne.DNDBingo

Item {
    id: root

    property var gameCards: []
    property var completedCards: []
    property bool gameStarted: false
    property bool animationInProgress: false
    property int cardsPlaced: 0

    signal cardCompleted(int index)

    // Watch for size changes and reposition cards
    onWidthChanged: {
        if (gameStarted && !animationInProgress) {
            repositionCards()
        }
    }

    onHeightChanged: {
        if (gameStarted && !animationInProgress) {
            repositionCards()
        }
    }

    function startGame() {
        if (animationInProgress) return

        animationInProgress = true
        gameStarted = false
        completedCards = []
        cardsPlaced = 0

        // STOP ALL TIMERS from previous game
        stopAllTimers()

        // Get 25 random cards using the singleton
        let cards = CardManager.getRandomCards(25)
        gameCards = cards

        // Reset spinning circle rotation
        spinningCircle.rotation = 0

        // Reset all cards first
        resetAllCards()

        // Start the animation sequence
        animateCardsIn()
    }

    function stopAllTimers() {
        // Stop all global timers
        startSpinSequenceTimer.stop()
        spinSequenceAnimation.stop()
        startDistributionTimer.stop()
        cardDistributionTimer.stop()  // This was the culprit!
        gameFinishTimer.stop()
    }

    function resetAllCards() {
        // First, stop any running animations and reset all cards
        for (let i = 0; i < 25; i++) {
            let card = repeater.itemAt(i)
            if (card) {
                // Stop any running animations
                card.stopAllAnimations()

                // Reset card to initial state and put back in spinning circle
                card.parent = spinningCircle
                card.opacity = 0
                card.scale = 1.0
                card.rotation = 0

                // Will be positioned properly in animateCardsIn()
            }
        }
    }

    function animateCardsIn() {
        let layout = calculateGridLayout()

        // Position cards in circle and make them invisible
        for (let i = 0; i < 25; i++) {
            let card = repeater.itemAt(i)
            if (card) {
                // Ensure consistent size for positioning
                card.width = layout.cellSize
                card.height = layout.cellSize

                let angle = (i / 25) * Math.PI * 2
                let radius = Math.min(root.width, root.height) * 0.35
                let centerX = root.width / 2
                let centerY = root.height / 2

                card.x = centerX + Math.cos(angle) * radius - card.width / 2
                card.y = centerY + Math.sin(angle) * radius - card.height / 2
                card.rotation = 0
                card.scale = 1.0
                card.opacity = 0

                // Store original circle position for later calculation
                card.originalCircleX = card.x
                card.originalCircleY = card.y

                // Show cards with staggered timing
                card.startShowAnimation(i * 30)
            }
        }

        // Wait for all cards to appear, then start spinning sequence
        startSpinSequenceTimer.start()
    }

    function regroupCards() {
        // Calculate where each card actually is after the spin stopped
        let centerX = root.width / 2
        let centerY = root.height / 2
        let finalRotation = spinningCircle.rotation * Math.PI / 180 // Convert to radians

        for (let i = 0; i < 25; i++) {
            let card = repeater.itemAt(i)
            if (card) {
                // Calculate the card's actual position after rotation
                let originalCenterX = card.originalCircleX + card.width/2
                let originalCenterY = card.originalCircleY + card.height/2

                // Rotate around the center
                let dx = originalCenterX - centerX
                let dy = originalCenterY - centerY

                let rotatedX = centerX + (dx * Math.cos(finalRotation) - dy * Math.sin(finalRotation))
                let rotatedY = centerY + (dx * Math.sin(finalRotation) + dy * Math.cos(finalRotation))

                // Set card to its actual rotated position
                card.parent = root
                card.x = rotatedX - card.width/2
                card.y = rotatedY - card.height/2

                // Now move to center with slight random offset for pack effect
                let offsetX = (Math.random() - 0.5) * 20
                let offsetY = (Math.random() - 0.5) * 20

                card.regroupToCenter(centerX - card.width/2 + offsetX, centerY - card.height/2 + offsetY, i * 20)
            }
        }

        // Start distributing after regrouping is done
        startDistributionTimer.start()
    }

    function calculateGridLayout() {
        let cellSize = Math.min(root.width, root.height) / 5 - 10
        let startX = (root.width - cellSize * 5 - 40) / 2
        let startY = (root.height - cellSize * 5 - 40) / 2

        return {
            cellSize: cellSize,
            startX: startX,
            startY: startY
        }
    }

    function startDistributingCards() {
        // Start distributing cards faster
        cardDistributionTimer.start()
    }

    function placeNextCard() {
        if (cardsPlaced >= 25) {
            // All cards placed, finish
            gameFinishTimer.start()
            return
        }

        let card = repeater.itemAt(cardsPlaced)
        if (card) {
            let layout = calculateGridLayout()
            let row = Math.floor(cardsPlaced / 5)
            let col = cardsPlaced % 5

            let targetX = layout.startX + col * (layout.cellSize + 10)
            let targetY = layout.startY + row * (layout.cellSize + 10)

            // Move card to grid position
            card.moveToPosition(targetX, targetY, layout.cellSize)
        }

        cardsPlaced++
    }

    function repositionCards() {
        let layout = calculateGridLayout()

        for (let i = 0; i < 25; i++) {
            let card = repeater.itemAt(i)
            if (card) {
                let row = Math.floor(i / 5)
                let col = i % 5

                let targetX = layout.startX + col * (layout.cellSize + 10)
                let targetY = layout.startY + row * (layout.cellSize + 10)

                card.instantRepositionTo(targetX, targetY, layout.cellSize)
            }
        }
    }

    // Timer to start spin sequence after all cards appear
    Timer {
        id: startSpinSequenceTimer
        interval: 1000
        running: false
        repeat: false
        onTriggered: {
            spinSequenceAnimation.start()
        }
    }

    // Complete spin sequence: accelerate then decelerate to stop
    SequentialAnimation {
        id: spinSequenceAnimation

        // Acceleration phase
        RotationAnimation {
            target: spinningCircle
            from: 0
            to: 1440 // 4 full rotations while accelerating
            duration: 1500
            easing.type: Easing.InQuart
        }

        // Deceleration phase - stop at exactly 5 full rotations
        RotationAnimation {
            target: spinningCircle
            from: 1440
            to: 1800 // One more rotation while decelerating to stop
            duration: 1000
            easing.type: Easing.OutQuart
        }

        // Brief pause when stopped
        PauseAnimation {
            duration: 200
        }

        // Start regrouping cards
        ScriptAction {
            script: regroupCards()
        }
    }

    // Timer to start distribution after regrouping
    Timer {
        id: startDistributionTimer
        interval: 800 // Wait for regrouping to complete
        running: false
        repeat: false
        onTriggered: startDistributingCards()
    }

    // Timer for distributing cards every 0.1s (faster)
    Timer {
        id: cardDistributionTimer
        interval: 100 // Much faster distribution
        running: false
        repeat: true
        onTriggered: placeNextCard()
    }

    Timer {
        id: gameFinishTimer
        interval: 500
        running: false
        repeat: false
        onTriggered: {
            gameStarted = true
            animationInProgress = false
        }
    }

    // Spinning circle container
    Item {
        id: spinningCircle
        anchors.fill: parent

        Repeater {
            id: repeater
            model: 25

            Card {
                id: cardItem

                // Custom properties to store original positions
                property real originalCircleX: 0
                property real originalCircleY: 0

                imagePath: {
                    if (index < gameCards.length) {
                        let cardName = gameCards[index]
                        return cardName ? CardManager.getCardPath(cardName) : ""
                    }
                    return ""
                }

                isCompleted: completedCards.includes(index)
                hoverEnabled: gameStarted && !animationInProgress

                width: 100
                height: 100
                onClicked: {
                    if (!gameStarted || animationInProgress) return

                    let newCompleted = [...completedCards]
                    let cardIndex = newCompleted.indexOf(index)

                    if (cardIndex === -1) {
                        newCompleted.push(index)
                    } else {
                        newCompleted.splice(cardIndex, 1)
                    }

                    completedCards = newCompleted
                    root.cardCompleted(index)
                }

                function stopAllAnimations() {
                    // Stop all running animations
                    showAnimation.stop()
                    regroupAnimation.stop()
                    moveAnimation.stop()

                    // Stop all timers
                    showTimer.stop()
                    regroupTimer.stop()
                }

                function startShowAnimation(delay) {
                    showTimer.interval = delay
                    showTimer.start()
                }

                function regroupToCenter(targetX, targetY, delay) {
                    // Move to center as part of regrouping
                    regroupXAnimation.to = targetX
                    regroupYAnimation.to = targetY

                    regroupTimer.interval = delay
                    regroupTimer.start()
                }

                function moveToPosition(targetX, targetY, size) {
                    // Animate from pack to grid position
                    xAnimation.to = targetX
                    yAnimation.to = targetY
                    sizeAnimation.to = size
                    moveAnimation.start()
                }

                function instantRepositionTo(targetX, targetY, size) {
                    parent = root
                    x = targetX
                    y = targetY
                    width = size
                    height = size
                }

                Timer {
                    id: showTimer
                    running: false
                    repeat: false
                    onTriggered: showAnimation.start()
                }

                Timer {
                    id: regroupTimer
                    running: false
                    repeat: false
                    onTriggered: regroupAnimation.start()
                }

                // Show animation - simple fade in
                PropertyAnimation {
                    id: showAnimation
                    target: cardItem
                    property: "opacity"
                    to: 1.0
                    duration: 250
                    easing.type: Easing.OutQuad
                }

                // Regroup animation - move to center pack
                ParallelAnimation {
                    id: regroupAnimation

                    PropertyAnimation {
                        id: regroupXAnimation
                        target: cardItem
                        property: "x"
                        duration: 500
                        easing.type: Easing.OutQuad
                    }

                    PropertyAnimation {
                        id: regroupYAnimation
                        target: cardItem
                        property: "y"
                        duration: 500
                        easing.type: Easing.OutQuad
                    }
                }

                // Move to grid animation
                ParallelAnimation {
                    id: moveAnimation

                    PropertyAnimation {
                        id: xAnimation
                        target: cardItem
                        property: "x"
                        duration: 300 // Faster movement
                        easing.type: Easing.OutQuad
                    }

                    PropertyAnimation {
                        id: yAnimation
                        target: cardItem
                        property: "y"
                        duration: 300
                        easing.type: Easing.OutQuad
                    }

                    PropertyAnimation {
                        id: sizeAnimation
                        target: cardItem
                        property: "width"
                        duration: 300
                        easing.type: Easing.OutQuad
                    }

                    PropertyAnimation {
                        target: cardItem
                        property: "height"
                        from: cardItem.height
                        to: sizeAnimation.to
                        duration: 300
                        easing.type: Easing.OutQuad
                    }
                }
            }
        }
    }

    // Start button
    Rectangle {
        anchors.centerIn: parent
        width: 200
        height: 60
        color: "#2196F3"
        radius: 30
        visible: !gameStarted && !animationInProgress

        MouseArea {
            anchors.fill: parent
            onClicked: root.startGame()
            cursorShape: Qt.PointingHandCursor
        }

        Text {
            anchors.centerIn: parent
            text: "Start New Game"
            color: "white"
            font.pixelSize: 16
            font.bold: true
        }
    }
}
