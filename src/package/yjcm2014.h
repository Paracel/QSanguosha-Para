#ifndef _YJCM2014_H
#define _YJCM2014_H

#include "package.h"
#include "card.h"

class ShenxingCard: public SkillCard {
    Q_OBJECT

public:
    Q_INVOKABLE ShenxingCard();
    virtual void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
};

class BingyiCard: public SkillCard {
    Q_OBJECT

public:
    Q_INVOKABLE BingyiCard();

    virtual bool targetsFeasible(const QList<const Player *> &targets, const Player *Self) const;
    virtual bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    virtual void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
};

class YJCM2014Package: public Package {
    Q_OBJECT

public:
    YJCM2014Package();
};

#endif
