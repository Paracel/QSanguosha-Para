#include "wandianba.h"
#include "general.h"
#include "standard.h"
#include "standard-equips.h"
#include "skill.h"
#include "engine.h"
#include "client.h"
#include "serverplayer.h"
#include "room.h"
#include "ai.h"
#include "settings.h"

JuntunCard::JuntunCard() {
    handling_method = Card::MethodRecast;
    target_fixed = true;
    will_throw = false;
}

void JuntunCard::onUse(Room *room, const CardUseStruct &card_use) const{
    room->notifySkillInvoked(card_use.from, "juntun");
    CardMoveReason reason(CardMoveReason::S_REASON_RECAST, card_use.from->objectName());
    reason.m_eventName = "juntun";
    room->moveCardTo(this, card_use.from, NULL, Player::DiscardPile, reason);
    card_use.from->broadcastSkillInvoke("@recast");

    LogMessage log;
    log.type = "$JuntunRecast";
    log.from = card_use.from;
    log.card_str = QString::number(card_use.card->getEffectiveId());
    log.arg = "juntun";
    room->sendLog(log);

    card_use.from->drawCards(1);
}

class Juntun: public OneCardViewAsSkill {
public:
    Juntun(): OneCardViewAsSkill("juntun") {
    }

    virtual bool isEnabledAtPlay(const Player *player) const{
        return !player->isNude();
    }

    virtual bool viewFilter(const Card *to_select) const{
        return to_select->getTypeId() == Card::TypeEquip && !Self->isCardLimited(to_select, Card::MethodRecast);
    }

    virtual const Card *viewAs(const Card *originalCard) const{
        JuntunCard *card = new JuntunCard;
        card->addSubcard(originalCard);
        return card;
    }
};

class Moshou: public TriggerSkill {
public:
    Moshou(): TriggerSkill("moshou") {
        events << EventPhaseSkipping;
        frequency = Compulsory;
    }

    virtual bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const{
        PhaseChangeStruct change = data.value<PhaseChangeStruct>();
        if (change.to == Player::NotActive)
            return false;
        room->notifySkillInvoked(player, objectName());

        static QStringList phase_strings;
        if (phase_strings.isEmpty())
            phase_strings << "round_start" << "start" << "judge" << "draw"
                          << "play" << "discard" << "finish" << "not_active";
        int index = static_cast<int>(change.to);

        LogMessage log;
        log.type = "#Moshou";
        log.from = player;
        log.arg = objectName();
        log.arg2 = phase_strings.at(index);
        room->sendLog(log);
        return true;
    }
};

WandianbaPackage::WandianbaPackage()
    : Package("wandianba")
{
    General *zaozhirenjun = new General(this, "zaozhirenjun", "wei", 3);
    zaozhirenjun->addSkill(new Juntun);
    /*
    zaozhirenjun->addSkill(new Liangce);
    zaozhirenjun->addSkill(new Jianbi);*/

    General *feishi = new General(this, "feishi", "shu", 3);
    //feishi->addSkill(new Shuaiyan);
    feishi->addSkill(new Moshou);

    /*General *liuzan = new General(this, "liuzan", "wu", 4);
    liuzan->addSkill(new Kangyin);

    General *liuyan = new General(this, "liuyan", "qun", 4);
    liuyan->addSkill(new Juedao);
    liuyan->addSkill(new Geju);
    */

    addMetaObject<JuntunCard>();
}

ADD_PACKAGE(Wandianba)
