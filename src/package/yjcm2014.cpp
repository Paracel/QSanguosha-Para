#include "yjcm2014.h"
#include "settings.h"
#include "skill.h"
#include "standard.h"
#include "client.h"
#include "clientplayer.h"
#include "engine.h"
#include "maneuvering.h"

ShenxingCard::ShenxingCard() {
    target_fixed = true;
}

void ShenxingCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const{
    if (source->isAlive())
        room->drawCards(source, 1, "shenxing");
}

class Shenxing: public ViewAsSkill {
public:
    Shenxing(): ViewAsSkill("shenxing") {
    }

    virtual bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const{
        return selected.length() < 2 && !Self->isJilei(to_select);
    }

    virtual const Card *viewAs(const QList<const Card *> &cards) const{
        if (cards.length() != 2)
            return NULL;

        ShenxingCard *card = new ShenxingCard;
        card->addSubcards(cards);
        return card;
    }

    virtual bool isEnabledAtPlay(const Player *player) const{
        return player->getCardCount(true) >= 2 && player->canDiscard(player, "he");
    }
};

BingyiCard::BingyiCard() {
}

bool BingyiCard::targetsFeasible(const QList<const Player *> &targets, const Player *Self) const{
    Card::Color color = Card::Colorless;
    foreach (const Card *c, Self->getHandcards()) {
        if (color == Card::Colorless)
            color = c->getColor();
        else if (c->getColor() != color)
            return targets.isEmpty();
    }
    return targets.length() <= Self->getHandcardNum();
}

bool BingyiCard::targetFilter(const QList<const Player *> &targets, const Player *, const Player *Self) const{
    Card::Color color = Card::Colorless;
    foreach (const Card *c, Self->getHandcards()) {
        if (color == Card::Colorless)
            color = c->getColor();
        else if (c->getColor() != color)
            return false;
    }
    return targets.length() < Self->getHandcardNum();
}

void BingyiCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const{
    room->showAllCards(source);
    foreach (ServerPlayer *p, targets)
        room->drawCards(p, 1, "bingyi");
}

class BingyiViewAsSkill: public ZeroCardViewAsSkill {
public:
    BingyiViewAsSkill(): ZeroCardViewAsSkill("bingyi") {
        response_pattern = "@@bingyi";
    }

    virtual const Card *viewAs() const{
        return new BingyiCard;
    }
};

class Bingyi: public PhaseChangeSkill {
public:
    Bingyi(): PhaseChangeSkill("bingyi") {
        view_as_skill = new BingyiViewAsSkill;
    }

    virtual bool onPhaseChange(ServerPlayer *target) const{
        if (target->getPhase() != Player::Finish || target->isKongcheng()) return false;
        target->getRoom()->askForUseCard(target, "@@bingyi", "@bingyi-card");
        return false;
    }
};

class Youdi: public PhaseChangeSkill {
public:
    Youdi(): PhaseChangeSkill("youdi") {
    }

    virtual bool onPhaseChange(ServerPlayer *target) const{
        if (target->getPhase() != Player::Finish || target->isNude()) return false;
        Room *room = target->getRoom();
        QList<ServerPlayer *> players;
        foreach (ServerPlayer *p, room->getOtherPlayers(target)) {
            if (p->canDiscard(target, "he")) players << p;
        }
        if (players.isEmpty()) return false;
        ServerPlayer *player = room->askForPlayerChosen(target, players, objectName(), "youdi-invoke", true, true);
        if (player) {
            int id = room->askForCardChosen(player, target, "he", objectName(), false, Card::MethodDiscard);
            room->throwCard(id, target, player);
            if (!Sanguosha->getCard(id)->isKindOf("Slash") && player->isAlive() && !player->isNude()) {
                int id2= room->askForCardChosen(target, player, "he", "youdi_obtain");
                room->obtainCard(target, id2);
            }
        }
        return false;
    }
};

class Jianying: public TriggerSkill {
public:
    Jianying(): TriggerSkill("jianying") {
        events << CardUsed << CardResponded << EventPhaseChanging;
        frequency = Frequent;
        global = true;
    }

    virtual bool triggerable(const ServerPlayer *target) const{
        return target != NULL;
    }

    virtual bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const{
        if ((triggerEvent == CardUsed || triggerEvent == CardResponded) && player->getPhase() == Player::Play) {
            CardStar card = NULL;
            if (triggerEvent == CardUsed)
                card = data.value<CardUseStruct>().card;
            else if (triggerEvent == CardResponded) {
                CardResponseStruct resp = data.value<CardResponseStruct>();
                if (resp.m_isUse)
                    card = resp.m_card;
            }
            if (!card || card->getTypeId() == Card::TypeSkill) return false;
            int suit = player->getMark("JianyingSuit"), number = player->getMark("JianyingNumber");
            player->setMark("JianyingSuit", int(card->getSuit()) > 3 ? 0 : (int(card->getSuit()) + 1));
            player->setMark("JianyingNumber", card->getNumber());
            if (TriggerSkill::triggerable(player)
                && ((suit > 0 && int(card->getSuit()) + 1 == suit)
                    || (number > 0 && card->getNumber() == number))
                && room->askForSkillInvoke(player, objectName(), data)) {
                room->broadcastSkillInvoke(objectName());
                room->drawCards(player, 1, objectName());
            }
        } else if (triggerEvent == EventPhaseChanging) {
            PhaseChangeStruct change = data.value<PhaseChangeStruct>();
            if (change.from == Player::Play) {
                player->setMark("JianyingSuit", 0);
                player->setMark("JianyingNumber", 0);
            }
        }
        return false;
    }
};

class Shibei: public TriggerSkill {
public:
    Shibei(): TriggerSkill("shibei") {
        events << DamageDone << Damaged << EventPhaseChanging;
        frequency = Compulsory;
        global = true;
    }

    virtual bool triggerable(const ServerPlayer *target) const{
        return target != NULL;
    }

    virtual bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const{
        if (triggerEvent == EventPhaseChanging) {
            PhaseChangeStruct change = data.value<PhaseChangeStruct>();
            if (change.to == Player::NotActive) {
                foreach (ServerPlayer *p, room->getAlivePlayers())
                    p->setMark("shibei", 0);
            }
        } else if (triggerEvent == DamageDone) {
            ServerPlayer *current = room->getCurrent();
            if (!current || current->isDead() || current->getPhase() == Player::NotActive)
                return false;
            player->addMark("shibei");
        } else if (triggerEvent == Damaged && TriggerSkill::triggerable(player) && player->getMark("shibei") > 0) {
            LogMessage log;
            log.type = "#TriggerSkill";
            log.from = player;
            log.arg = objectName();
            room->sendLog(log);
            room->notifySkillInvoked(player, objectName());
            room->broadcastSkillInvoke(objectName());

            if (player->getMark("shibei") == 1)
                room->recover(player, RecoverStruct(player));
            else
                room->loseHp(player);
        }
        return false;
    }
};

YJCM2014Package::YJCM2014Package()
    : Package("YJCM2014")
{
    /*General *caifuren = new General(this, "caifuren", "qun", 3, false); // YJ 301
    caifuren->addSkill(new Qieting);
    caifuren->addSkill(new Xianzhou);*/

    /*General *caozhen = new General(this, "caozhen", "wei"); // YJ 302
    caozhen->addSkill(new Sidi);*/

    /*General *chenqun = new General(this, "chenqun", "wei", 3); // YJ 303
    chenqun->addSkill(new Dingpin);
    chenqun->addSkill(new Faen);*/

    General *guyong = new General (this, "guyong", "wu", 3); // YJ 304
    guyong->addSkill(new Shenxing);
    guyong->addSkill(new Bingyi);

    /*General *hanhaoshihuan = new General(this, "hanhaoshihuan", "wei"); // YJ 305
    hanhaoshihuan->addSkill(new Shenduan);
    hanhaoshihuan->addSkill(new Yonglve);*/

    General *jvshou = new General(this, "jvshou", "qun", 3); // YJ 306
    jvshou->addSkill(new Jianying);
    jvshou->addSkill(new Shibei);

    /*General *sunluban = new General(this, "sunluban", "wu", 3, false); // YJ 307
    sunluban->addSkill(new Zenhui);
    sunluban->addSkill(new Jiaojin);*/

    /*General *wuyi = new General(this, "wuyi", "shu"); // YJ 308
    wuyi->addSkill(new Benxi);*/

    /*General *zhangsong = new General(this, "zhangsong", "shu", 3); // YJ 309
    zhangsong->addSkill(new Qiangzhi);
    zhangsong->addSkill(new Xiantu);*/

    /*General *zhoucang = new General(this, "zhoucang", "shu"); // YJ 310
    zhoucang->addSkill(new Zhongyong)*/

    General *zhuhuan = new General(this, "zhuhuan", "wu"); // YJ 311
    zhuhuan->addSkill(new Youdi);

    addMetaObject<ShenxingCard>();
    addMetaObject<BingyiCard>();
}

ADD_PACKAGE(YJCM2014)
