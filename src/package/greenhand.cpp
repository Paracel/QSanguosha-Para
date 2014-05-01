#include "greenhand.h"
#include "standard.h"
#include "standard-equips.h"
#include "engine.h"

Broadsword::Broadsword(Suit suit, int number)
    :Weapon(suit, number, 2)
{
    setObjectName("broadsword");
}

GreenHandCardPackage::GreenHandCardPackage()
    : Package("GreenHandCard")
{
    QList<Card *> cards;
    cards << new Duel(Card::Spade, 1)
          << new QinggangSword(Card::Spade, 2)
          << new Snatch(Card::Spade, 3)
          << new Dismantlement(Card::Spade, 4)
          << new Broadsword(Card::Spade, 5)
          << new Snatch(Card::Spade, 6)
          << new Slash(Card::Spade, 7)
          << new Slash(Card::Spade, 8)
          << new Slash(Card::Spade, 9)
          << new Slash(Card::Spade, 10)
          << new Slash(Card::Spade, 11)
          << new Spear(Card::Spade, 12)
          << new SavageAssault(Card::Spade, 13);

    cards << new GodSalvation(Card::Heart, 1)
          << new Peach(Card::Heart, 2)
          << new AmazingGrace(Card::Heart, 3)
          << new AmazingGrace(Card::Heart, 4)
          << new Peach(Card::Heart, 5)
          << new Peach(Card::Heart, 6)
          << new ExNihilo(Card::Heart, 7)
          << new ExNihilo(Card::Heart, 8)
          << new Jink(Card::Heart, 9)
          << new Jink(Card::Heart, 10)
          << new Slash(Card::Heart, 11)
          << new Dismantlement(Card::Heart, 12)
          << new ArcheryAttack(Card::Heart, 13);

    cards << new Duel(Card::Club, 1)
          << new Slash(Card::Club, 2)
          << new Slash(Card::Club, 3)
          << new Slash(Card::Club, 4)
          << new Slash(Card::Club, 5)
          << new Slash(Card::Club, 6)
          << new Slash(Card::Club, 7)
          << new Slash(Card::Club, 8)
          << new Dismantlement(Card::Club, 9)
          << new SavageAssault(Card::Club, 10)
          << new Crossbow(Card::Club, 11)
          << new Dismantlement(Card::Club, 12)
          << new Dismantlement(Card::Club, 13);

    cards << new Duel(Card::Diamond, 1)
          << new Jink(Card::Diamond, 2)
          << new Jink(Card::Diamond, 3)
          << new Jink(Card::Diamond, 4)
          << new Jink(Card::Diamond, 5)
          << new Jink(Card::Diamond, 6)
          << new Jink(Card::Diamond, 7)
          << new Slash(Card::Diamond, 8)
          << new Slash(Card::Diamond, 9)
          << new Slash(Card::Diamond, 10)
          << new Snatch(Card::Diamond, 11)
          << new Peach(Card::Diamond, 12)
          << new Slash(Card::Diamond, 13);

    foreach (Card *card, cards)
        card->setParent(this);

    type = CardPack;
}

ADD_PACKAGE(GreenHandCard)

