#include "cardmanager.h"
#include <QDebug>
#include <QRandomGenerator>
#include <algorithm>

CardManager* CardManager::create(QQmlEngine *qmlEngine, QJSEngine *jsEngine)
{
    Q_UNUSED(qmlEngine)
    Q_UNUSED(jsEngine)

    static CardManager* instance = new CardManager();
    return instance;
}

CardManager::CardManager(QObject *parent)
    : QObject(parent)
{
    loadCards();
}

void CardManager::loadCards()
{
    QDir cardsDir(":/cards");
    if (!cardsDir.exists()) {
        qWarning() << "Cards directory does not exist in resources";
        return;
    }

    // Load all image files from the cards directory
    QStringList filters;
    filters << "*.png" << "*.jpg" << "*.jpeg" << "*.gif" << "*.svg";

    m_availableCards = cardsDir.entryList(filters, QDir::Files);

    qDebug() << "Loaded" << m_availableCards.size() << "cards:" << m_availableCards;
    emit availableCardsChanged();
}

QStringList CardManager::getRandomCards(int count)
{
    if (m_availableCards.isEmpty()) {
        qDebug() << "No cards available, creating placeholders";
        // Create placeholder cards for testing
        QStringList result;
        for (int i = 0; i < count; ++i) {
            result.append(""); // Empty string for placeholder
        }
        return result;
    }

    QStringList shuffled = m_availableCards;

    // Use Qt's proper random generator with Fisher-Yates shuffle
    auto rng = QRandomGenerator::global();
    for (int i = shuffled.size() - 1; i > 0; --i) {
        int j = rng->bounded(i + 1);
        shuffled.swapItemsAt(i, j);
    }

    // If we don't have enough cards, we'll need to fill with placeholders
    QStringList result;
    for (int i = 0; i < count; ++i) {
        if (i < shuffled.size()) {
            result.append(shuffled[i]);
        } else {
            // Add placeholder (empty string will be handled in QML)
            result.append("");
        }
    }

    return result;
}

QString CardManager::getCardPath(const QString &cardName)
{
    if (cardName.isEmpty()) {
        return "";
    }
    return "qrc:/cards/" + cardName;
}
