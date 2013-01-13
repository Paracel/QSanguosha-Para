#ifndef _ASSASSINS_H
#define _ASSASSINS_H

#include "package.h"
#include "card.h"
#include "skill.h"
#include "standard.h"

class AssassinsPackage: public Package {
    Q_OBJECT

public:
    AssassinsPackage();
};

class MizhaoCard: public SkillCard {
    Q_OBJECT

public:
    Q_INVOKABLE MizhaoCard();

    virtual bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    virtual void onEffect(const CardEffectStruct &effect) const;
};

#endif

