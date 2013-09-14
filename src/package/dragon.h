#ifndef _DRAGON_H
#define _DRAGON_H

#include "package.h"
#include "card.h"
#include "skill.h"
#include "standard.h"

class DrZhihengCard: public SkillCard {
    Q_OBJECT

public:
    Q_INVOKABLE DrZhihengCard();
    virtual bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    virtual bool targetsFeasible(const QList<const Player *> &targets, const Player *Self) const;
    virtual void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
};

class DrJiedaoCard: public SkillCard {
    Q_OBJECT

public:
    Q_INVOKABLE DrJiedaoCard();

    virtual bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    virtual void onEffect(const CardEffectStruct &effect) const;
};

class DrQingnangCard: public SkillCard {
    Q_OBJECT

public:
    Q_INVOKABLE DrQingnangCard();

    virtual void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
};

class DragonPackage: public Package {
    Q_OBJECT

public:
    DragonPackage();
};

#endif

