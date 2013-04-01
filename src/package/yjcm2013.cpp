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
}

ADD_PACKAGE(YJCM2013)
