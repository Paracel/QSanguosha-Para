#ifndef GREENHAND_H
#define GREENHAND_H

#include "package.h"
#include "card.h"
#include "skill.h"
#include "standard.h"

class GreenHandPackage : public Package{
    Q_OBJECT

public:
    GreenHandPackage();
};

class GreenHandCardPackage: public Package{
    Q_OBJECT

public:
    GreenHandCardPackage();
};

class Broadsword:public Weapon{
    Q_OBJECT

public:
    Q_INVOKABLE Broadsword(Card::Suit suit = Card::Spade, int number = 5);
};

#endif // GREENHAND_H
