#ifndef _GREENHAND_H
#define _GREENHAND_H

#include "package.h"
#include "card.h"
#include "standard.h"

class GreenHandCardPackage: public Package {
    Q_OBJECT

public:
    GreenHandCardPackage();
};

class Broadsword: public Weapon {
    Q_OBJECT

public:
    Q_INVOKABLE Broadsword(Card::Suit suit = Card::Spade, int number = 5);
};

#endif

