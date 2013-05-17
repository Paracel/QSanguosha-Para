#include "assassins.h"
#include "skill.h"
#include "standard.h"
#include "clientplayer.h"
#include "engine.h"

class Moukui: public TriggerSkill {
public:
    Moukui(): TriggerSkill("moukui") {
        events << TargetConfirmed << SlashMissed << CardFinished;
    }

    virtual bool triggerable(const ServerPlayer *target) const{
        return target != NULL;
    }

    virtual bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const{
        if (triggerEvent == TargetConfirmed) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (player != use.from || !TriggerSkill::triggerable(player) || !use.card->isKindOf("Slash"))
                return false;
            foreach (ServerPlayer *p, use.to) {
                if (player->askForSkillInvoke(objectName(), QVariant::fromValue(p))) {
                    QString choice;
                    if (p->isNude())
                        choice = "draw";
                    else
                        choice = room->askForChoice(player, objectName(), "draw+discard", QVariant::fromValue(p));
                    if (choice == "draw") {
                        room->broadcastSkillInvoke(objectName(), 1);
                        player->drawCards(1);
                    } else {
                        room->broadcastSkillInvoke(objectName(), 2);
                        int disc = room->askForCardChosen(player, p, "he", objectName());
                        room->throwCard(disc, p, player);
                    }
                    room->addPlayerMark(p, objectName() + use.card->toString());
                }
            }
        } else if (triggerEvent == SlashMissed) {
            SlashEffectStruct effect = data.value<SlashEffectStruct>();
            if (effect.to->isDead() || effect.to->getMark(objectName() + effect.slash->toString()) <= 0)
                return false;
            if (!effect.from->isAlive() || !effect.to->isAlive() || effect.from->isNude())
                return false;
            int disc = room->askForCardChosen(effect.to, effect.from, "he", objectName());
            room->broadcastSkillInvoke(objectName(), 3);
            room->throwCard(disc, effect.from, effect.to);
            room->removePlayerMark(effect.to, objectName() + effect.slash->toString());
        } else if (triggerEvent == CardFinished) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (!use.card->isKindOf("Slash"))
                return false;
            foreach (ServerPlayer *p, room->getAllPlayers())
                room->setPlayerMark(p, objectName() + use.card->toString(), 0);
        }

        return false;
    }
};

class Tianming: public TriggerSkill {
public:
    Tianming(): TriggerSkill("tianming") {
        events << TargetConfirming;
    }

    virtual bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const{
        CardUseStruct use = data.value<CardUseStruct>();
        if (use.card && use.card->isKindOf("Slash") && room->askForSkillInvoke(player, objectName())) {
            room->broadcastSkillInvoke(objectName(), 1);
            room->askForDiscard(player, objectName(), 2, 2, false, true);
            player->drawCards(2);

            int max = -1000;
            foreach (ServerPlayer *p, room->getAllPlayers())
                if (p->getHp() > max)
                    max = p->getHp();
            if (player->getHp() == max)
                return false;

            QList<ServerPlayer *> maxs;
            foreach (ServerPlayer *p, room->getAllPlayers()) {
                if (p->getHp() == max)
                    maxs << p;
                if (maxs.size() > 1)
                    return false;
            }
            ServerPlayer *mosthp = maxs.first();
            if (room->askForSkillInvoke(mosthp, objectName())) {
                int index = 2;
                if (mosthp->isFemale())
                    index = 3;
                room->broadcastSkillInvoke(objectName(), index);
                room->askForDiscard(mosthp, objectName(), 2, 2, false, true);
                mosthp->drawCards(2);
            }
        }

        return false;
    }
};

MizhaoCard::MizhaoCard() {
    will_throw = false;
    mute = true;
    handling_method = Card::MethodNone;
}

bool MizhaoCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const{
    return targets.isEmpty() && to_select != Self;
}

void MizhaoCard::onEffect(const CardEffectStruct &effect) const{
    effect.to->obtainCard(effect.card, false);
    if (effect.to->isKongcheng()) return;

    Room *room = effect.from->getRoom();
    room->broadcastSkillInvoke("mizhao", effect.to->getGeneralName().contains("liubei") ? 2 : 1);

    QList<ServerPlayer *> targets;
    foreach (ServerPlayer *p, room->getOtherPlayers(effect.to))
        if (!p->isKongcheng())
            targets << p;

    if (!targets.isEmpty()) {
        ServerPlayer *target = room->askForPlayerChosen(effect.from, targets, "mizhao", "@mizhao-pindian:" + effect.to->objectName());
        target->setFlags("MizhaoPindianTarget");
        effect.to->pindian(target, "mizhao", NULL);
        target->setFlags("-MizhaoPindianTarget");
    }
}

class MizhaoViewAsSkill: public ViewAsSkill {
public:
    MizhaoViewAsSkill(): ViewAsSkill("mizhao") {
    }

    virtual bool isEnabledAtPlay(const Player *player) const{
        return !player->isKongcheng() && !player->hasUsed("MizhaoCard");
    }

    virtual bool viewFilter(const QList<const Card *> &, const Card *to_select) const{
        return !to_select->isEquipped();
    }

    virtual const Card *viewAs(const QList<const Card *> &cards) const{
        if (cards.length() < Self->getHandcardNum())
            return NULL;

        MizhaoCard *card = new MizhaoCard;
        card->addSubcards(cards);
        return card;
    }
};

class Mizhao: public TriggerSkill {
public:
    Mizhao(): TriggerSkill("mizhao") {
        events << Pindian;
        view_as_skill = new MizhaoViewAsSkill;
    }

    virtual bool triggerable(const ServerPlayer *target) const{
        return target != NULL;
    }

    virtual bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const{
        PindianStar pindian = data.value<PindianStar>();
        if (pindian->reason != objectName() || pindian->from_number == pindian->to_number)
            return false;

        ServerPlayer *winner = pindian->isSuccess() ? pindian->from : pindian->to;
        ServerPlayer *loser = pindian->isSuccess() ? pindian->to : pindian->from;
        if (winner->canSlash(loser, NULL, false)) {
            Slash *slash = new Slash(Card::NoSuit, 0);
            slash->setSkillName("_mizhao");
            room->useCard(CardUseStruct(slash, winner, loser), false);
        }

        return false;
    }

    virtual int getEffectIndex(const ServerPlayer *, const Card *) const{
        return -2;
    }
};

class MizhaoSlashNoDistanceLimit: public TargetModSkill {
public:
    MizhaoSlashNoDistanceLimit(): TargetModSkill("#mizhao-slash-ndl") {
    }

    virtual int getDistanceLimit(const Player *, const Card *card) const{
        if (card->isKindOf("Slash") && card->getSkillName() == "mizhao")
            return 1000;
        else
            return 0;
    }
};

class Jieyuan: public TriggerSkill {
public:
    Jieyuan(): TriggerSkill("jieyuan") {
        events << DamageCaused << DamageInflicted;
    }

    virtual bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const{
        DamageStruct damage = data.value<DamageStruct>();
        if (triggerEvent == DamageCaused) {
            if (damage.to && damage.to->isAlive()
                && damage.to->getHp() >= player->getHp() && damage.to != player && !player->isKongcheng()
                && room->askForCard(player, ".black", "@jieyuan-increase:" + damage.to->objectName(), data, objectName())) {
                room->broadcastSkillInvoke(objectName(), 1);

                LogMessage log;
                log.type = "#JieyuanIncrease";
                log.from = player;
                log.arg = QString::number(damage.damage);
                log.arg2 = QString::number(++damage.damage);
                room->sendLog(log);

                data = QVariant::fromValue(damage);
            }
        } else if (triggerEvent == DamageInflicted) {
            if (damage.from && damage.from->isAlive()
                && damage.from->getHp() >= player->getHp() && damage.from != player && !player->isKongcheng()
                && room->askForCard(player, ".red", "@jieyuan-decrease:" + damage.from->objectName(), data, objectName())) {
                room->broadcastSkillInvoke(objectName(), 2);

                LogMessage log;
                log.type = "#JieyuanDecrease";
                log.from = player;
                log.arg = QString::number(damage.damage);
                log.arg2 = QString::number(--damage.damage);
                room->sendLog(log);

                data = QVariant::fromValue(damage);
                if (damage.damage < 1)
                    return true;
            }
        }

        return false;
    }
};

class Fenxin: public TriggerSkill {
public:
    Fenxin(): TriggerSkill("fenxin") {
        events << BeforeGameOverJudge;
        frequency = Limited;
    }

    virtual bool triggerable(const ServerPlayer *target) const{
        return target != NULL;
    }

    virtual bool trigger(TriggerEvent , Room *room, ServerPlayer *player, QVariant &data) const{
        if (!isNormalGameMode(room->getMode()))
            return false;
        DeathStruct death = data.value<DeathStruct>();
        if (death.damage == NULL)
            return false;
        ServerPlayer *killer = death.damage->from;
        if (killer == NULL || killer->isLord() || player->isLord() || player->getHp() > 0)
            return false;
        if (!TriggerSkill::triggerable(killer) || killer->getMark("@burnheart") == 0)
            return false;
        player->setFlags("FenxinTarget");
        bool invoke = room->askForSkillInvoke(killer, objectName(), QVariant::fromValue(player));
        player->setFlags("-FenxinTarget");
        if (invoke) {
            room->broadcastSkillInvoke(objectName());
            room->doLightbox("$FenxinAnimate");
            room->removePlayerMark(killer, "@burnheart");
            QString role1 = killer->getRole();
            killer->setRole(player->getRole());
            room->notifyProperty(killer, killer, "role", player->getRole());
            room->setPlayerProperty(player, "role", role1);
        }
        return false;
    }
};

AssassinsPackage::AssassinsPackage(): Package("assassins") {
    General *fuwan = new General(this, "fuwan", "qun", 4); //SP 018
    fuwan->addSkill(new Moukui);

    General *liuxie = new General(this, "liuxie", "qun", 3); // SP 016
    liuxie->addSkill(new Tianming);
    liuxie->addSkill(new Mizhao);
    liuxie->addSkill(new MizhaoSlashNoDistanceLimit);
    related_skills.insertMulti("mizhao", "#mizhao-slash-ndl");

    General *lingju = new General(this, "lingju", "qun", 3, false); // SP 017
    lingju->addSkill(new Jieyuan);
    lingju->addSkill(new Fenxin);
    lingju->addSkill(new MarkAssignSkill("@burnheart", 1));
    related_skills.insertMulti("fenxin", "#@burnheart-1");

    addMetaObject<MizhaoCard>();
}

ADD_PACKAGE(Assassins)

