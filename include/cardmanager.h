#pragma once

#include <QObject>
#include <QStringList>
#include <QDir>
#include <QQmlEngine>

class CardManager : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
    Q_PROPERTY(QStringList availableCards READ availableCards NOTIFY availableCardsChanged)
    Q_PROPERTY(int cardCount READ cardCount NOTIFY availableCardsChanged)

public:
    static CardManager* create(QQmlEngine *qmlEngine, QJSEngine *jsEngine);

    QStringList availableCards() const { return m_availableCards; }
    int cardCount() const { return m_availableCards.size(); }

    Q_INVOKABLE QStringList getRandomCards(int count);
    Q_INVOKABLE QString getCardPath(const QString &cardName);

signals:
    void availableCardsChanged();

private:
    explicit CardManager(QObject *parent = nullptr);
    void loadCards();
    QStringList m_availableCards;
};
