#ifndef _WANDIANBA_H
#define _WANDIANBA_H

#include "package.h"
#include "card.h"
#include "skill.h"

class JuntunCard: public SkillCard {
    Q_OBJECT

public:
    Q_INVOKABLE JuntunCard();

    virtual void onUse(Room *room, const CardUseStruct &card_use) const;
};

class WandianbaPackage: public Package {
    Q_OBJECT

public:
    WandianbaPackage();
};

#endif
