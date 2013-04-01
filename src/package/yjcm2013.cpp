#include "yjcm2013.h"
#include "skill.h"
#include "standard.h"
#include "client.h"
#include "clientplayer.h"
#include "engine.h"
#include "maneuvering.h"

class Chengxiang: public MasochismSkill {
public:
    Chengxiang(): MasochismSkill("chengxiang") {
    }

    virtual void onDamaged(ServerPlayer *target, const DamageStruct &damage) const{
        Room *room = target->getRoom();
        while (room->askForSkillInvoke(target, objectName(), QVariant::fromValue(damage))) {
            if (!target->isKongcheng())
                room->showAllCards(target);
            int num = 0;
            foreach (const Card *card, target->getHandcards())
                num += card->getNumber();
            if (num >= 13) break;
            target->drawCards(1);
        }
    }
};

class Bingxin: public TriggerSkill {
public:
    Bingxin(): TriggerSkill("bingxin") {
        events << Dying;
    }

    virtual bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const{
        DyingStruct dying = data.value<DyingStruct>();
        if (player != dying.who || player->isNude()) return false;
        if (room->askForSkillInvoke(player, objectName(), data)) {
            QList<int> ids;
            foreach (const Card *card, player->getCards("he"))
                ids << card->getEffectiveId();

            while (room->askForYiji(player, ids, objectName(), false, false, false)) {}
            if (!ids.isEmpty()) {
                while (!ids.isEmpty()) {
                    int len = ids.length();
                    qShuffle(ids);
                    int give = qrand() % len + 1;
                    len -= give;
                    QList<int> to_give = ids.mid(0, give);
                    ServerPlayer *receiver = room->getOtherPlayers(player).at(qrand() % (player->aliveCount() - 1));
                    DummyCard *dummy = new DummyCard;
                    foreach (int id, to_give) {
                        dummy->addSubcard(id);
                        ids.removeOne(id);
                    }
                    room->obtainCard(receiver, dummy, false);
                    delete dummy;
                    if (len == 0)
                        break;
                }
            }
            player->turnOver();
        }
        return false;
    }
};

class Jingce: public TriggerSkill {
public:
    Jingce(): TriggerSkill("jingce") {
        events << PreCardUsed << CardResponded << EventPhaseStart << EventPhaseEnd;
    }

    virtual bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const{
        if ((event == PreCardUsed || event == CardResponded) && player->getPhase() <= Player::Play) {
            CardStar card = NULL;
            if (event == PreCardUsed)
                card = data.value<CardUseStruct>().card;
            else {
                CardResponseStruct response = data.value<CardResponseStruct>();
                if (response.m_isUse)
                   card = response.m_card;
            }
            if (card && card->getHandlingMethod() == Card::MethodUse)
                player->addMark(objectName());
        } else if (event == EventPhaseStart && player->getPhase() == Player::RoundStart) {
                player->setMark(objectName(), 0);
        } else if (event == EventPhaseEnd) {
            if (player->getPhase() == Player::Play && player->getMark(objectName()) > player->getHp()) {
                if (room->askForSkillInvoke(player, objectName())) {
                    if (player->isWounded() && room->askForChoice(player, objectName(), "draw+recover") == "recover") {
                        RecoverStruct recover;
                        recover.who = player;
                        room->recover(player, recover);
                    } else {
                        player->drawCards(1);
                    }
                }
            }
        }
        return false;
    }
};

class Longyin: public TriggerSkill {
public:
    Longyin(): TriggerSkill("longyin") {
        events << CardUsed;
    }

    virtual bool triggerable(const ServerPlayer *target) const{
        return target->getPhase() == Player::Play;
    }

    virtual int getPriority() const{
        return 1;
    }

    virtual bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const{
        CardUseStruct use = data.value<CardUseStruct>();
        if (use.card->isKindOf("Slash") && use.m_addHistory) {
            ServerPlayer *guanping = room->findPlayerBySkillName(objectName());
            if (guanping && !guanping->isKongcheng()
                && room->askForCard(guanping, ".black", "@longyin", data, objectName())) {
                room->addPlayerHistory(player, use.card->getClassName(), -1);
                if (use.card->isRed())
                    guanping->drawCards(1);
            }
        }
        return false;
    }
};

XiansiCard::XiansiCard() {
}

bool XiansiCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const{
    return targets.length() < 2 && !to_select->isNude() && to_select != Self;
}

void XiansiCard::onEffect(const CardEffectStruct &effect) const{
    if (effect.to->isNude()) return;
    int id = effect.from->getRoom()->askForCardChosen(effect.from, effect.to, "he", "xiansi");
    effect.from->addToPile("counter", id);
}

class XiansiViewAsSkill: public OneCardViewAsSkill {
public:
    XiansiViewAsSkill(): OneCardViewAsSkill("xiansi") {
    }

    virtual bool isEnabledAtPlay(const Player *player) const{
        return false;
    }

    virtual bool isEnabledAtResponse(const Player *player, const QString &pattern) const{
        return !player->isKongcheng() && pattern == "@@xiansi";
    }

    virtual bool viewFilter(const Card *to_select) const{
        return !to_select->isEquipped();
    }

    virtual const Card *viewAs(const Card *originalCard) const{
        XiansiCard *card = new XiansiCard;
        card->addSubcard(originalCard);
        return card;
    }
};

class Xiansi: public TriggerSkill {
public:
    Xiansi(): TriggerSkill("xiansi") {
        events << EventPhaseStart;
        view_as_skill = new XiansiViewAsSkill;
    }

    virtual bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const{
        if (player->getPhase() == Player::Start)
            room->askForUseCard(player, "@@xiansi", "@xiansi-card", -1, Card::MethodDiscard);
        return false;
    }
};

class XiansiAttach: public TriggerSkill {
public:
    XiansiAttach(): TriggerSkill("#xiansi-attach") {
        events << GameStart << EventAcquireSkill << EventLoseSkill;
    }

    virtual bool triggerable(const ServerPlayer *target) const{
        return target != NULL;
    }

    virtual bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const{
        if (event == GameStart || (event == EventAcquireSkill && data.toString() == "xiansi")) {
            foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                if (!p->hasSkill("xiansi_slash"))
                    room->attachSkillToPlayer(p, "xiansi_slash");
            }
        } else if (event == EventLoseSkill && data.toString() == "xiansi") {
            player->clearOnePrivatePile("counter");
            foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                if (p->hasSkill("xiansi_slash"))
                    room->detachSkillFromPlayer(p, "xiansi_slash", true);
            }
        }
        return false;
    }
};

XiansiSlashCard::XiansiSlashCard() {
    target_fixed = true;
    m_skillName = "xiansi_slash";
}

void XiansiSlashCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const{
    ServerPlayer *liufeng = room->findPlayerBySkillName("xiansi");
    if (!liufeng || liufeng->getPile("counter").isEmpty()) return;

    int id = -1;
    if (liufeng->getPile("counter").length() == 1) {
        id = liufeng->getPile("counter").first();
    } else {
        QList<int> ids = liufeng->getPile("counter");
        room->fillAG(ids, source);
        id = room->askForAG(source, ids, false, "xiansi");
        room->clearAG(source);
    }

    CardMoveReason reason(CardMoveReason::S_REASON_REMOVE_FROM_PILE, QString(), "xiansi", QString());
    room->throwCard(Sanguosha->getCard(id), reason, NULL);

    Slash *slash = new Slash(Card::SuitToBeDecided, -1);
    slash->setSkillName("XIANSI");
    room->useCard(CardUseStruct(slash, source, liufeng));
}

class XiansiSlashViewAsSkill: public ZeroCardViewAsSkill {
public:
    XiansiSlashViewAsSkill(): ZeroCardViewAsSkill("xiansi_slash") {
        attached_lord_skill = true;
    }

    virtual bool isEnabledAtPlay(const Player *player) const{
        return Slash::IsAvailable(player) && canSlashLiufeng(player);
    }

    virtual bool isEnabledAtResponse(const Player *player, const QString &pattern) const{
        return pattern == "slash" && !ClientInstance->hasNoTargetResponding()
               && canSlashLiufeng(player);
    }

    virtual const Card *viewAs() const{
        return new XiansiSlashCard;
    }

private:
    static bool canSlashLiufeng(const Player *player) {
        const Player *liufeng = NULL;
        foreach (const Player *p, player->getSiblings()) {
            if (p->isAlive() && p->hasSkill("xiansi") && !p->getPile("counter").isEmpty()) {
                liufeng = p;
                break;
            }
        }
        if (!liufeng) return false;

        QList<const Player *> empty_list;
        Slash *slash = new Slash(Card::SuitToBeDecided, -1);
        slash->deleteLater();
        return slash->targetFilter(empty_list, liufeng, player);
    }
};

YJCM2013Package::YJCM2013Package()
    : Package("YJCM2013")
{
    General *caochong = new General(this, "caochong", "wei", 3);
    caochong->addSkill(new Chengxiang);
    caochong->addSkill(new Bingxin);

    General *guohuai = new General(this, "guohuai", "wei");
    guohuai->addSkill(new Jingce);

    General *guanping = new General(this, "guanping", "shu", 4);
    guanping->addSkill(new Longyin);

    General *liufeng = new General(this, "liufeng", "shu");
    liufeng->addSkill(new Xiansi);
    liufeng->addSkill(new XiansiAttach);
    related_skills.insertMulti("xiansi", "#xiansi-attach");

    addMetaObject<XiansiCard>();
    addMetaObject<XiansiSlashCard>();

    skills << new XiansiSlashViewAsSkill;
}

ADD_PACKAGE(YJCM2013)
