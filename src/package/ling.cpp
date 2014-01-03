#include "ling.h"
#include "general.h"
#include "skill.h"
#include "standard.h"
#include "client.h"
#include "engine.h"

class Yishi: public TriggerSkill {
public:
    Yishi(): TriggerSkill("yishi") {
        events << DamageCaused;
    }

    virtual bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const{
        DamageStruct damage = data.value<DamageStruct>();

        if (damage.card && damage.card->isKindOf("Slash")
            && damage.by_user && !damage.chain && !damage.transfer && !damage.to->isAllNude()
            && player->askForSkillInvoke(objectName(), data)) {
            room->broadcastSkillInvoke(objectName(), 1);
            LogMessage log;
            log.type = "#Yishi";
            log.from = player;
            log.arg = objectName();
            log.to << damage.to;
            room->sendLog(log);
            int card_id = room->askForCardChosen(player, damage.to, "hej", objectName());
            if (room->getCardPlace(card_id) == Player::PlaceDelayedTrick)
                room->broadcastSkillInvoke(objectName(), 2);
            else if (room->getCardPlace(card_id) == Player::PlaceEquip)
                room->broadcastSkillInvoke(objectName(), 3);
            else
                room->broadcastSkillInvoke(objectName(), 4);
            CardMoveReason reason(CardMoveReason::S_REASON_EXTRACTION, player->objectName());
            room->obtainCard(player, Sanguosha->getCard(card_id), reason, room->getCardPlace(card_id) != Player::PlaceHand);
            return true;
        }
        return false;
    }
};

class Tannang: public DistanceSkill {
public:
    Tannang(): DistanceSkill("tannang") {
    }

    virtual int getCorrect(const Player *from, const Player *to) const{
        if (from->hasSkill(objectName()))
            return -from->getLostHp();
        else
            return 0;
    }
};

LingPackage::LingPackage()
    : Package("ling")
{
    General *neo_guanyu = new General(this, "neo_guanyu", "shu");
    neo_guanyu->addSkill("wusheng");
    neo_guanyu->addSkill(new Yishi);

    General *neo_zhangfei = new General(this, "neo_zhangfei", "shu");
    neo_zhangfei->addSkill("paoxiao");
    neo_zhangfei->addSkill(new Tannang);

    General *neo_zhaoyun = new General(this, "neo_zhaoyun", "shu");
    neo_zhaoyun->addSkill("longdan");
    neo_zhaoyun->addSkill("yicong");
}

ADD_PACKAGE(Ling)