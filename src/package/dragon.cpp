#include "dragon.h"
#include "skill.h"
#include "standard.h"
#include "server.h"
#include "engine.h"
#include "ai.h"
#include "clientplayer.h"

class DrLuoyi: public TriggerSkill {
public:
    DrLuoyi(): TriggerSkill("drluoyi") {
        events << DamageCaused;
        frequency = Compulsory;
    }

    virtual bool trigger(TriggerEvent, Room *room, ServerPlayer *xuchu, QVariant &data) const{
        DamageStruct damage = data.value<DamageStruct>();
        if (damage.chain || damage.transfer || !damage.by_user) return false;
        const Card *reason = damage.card;
        if (xuchu->getWeapon() == NULL && reason && reason->isKindOf("Slash")) {
            room->notifySkillInvoked(xuchu, objectName());
            LogMessage log;
            log.type = "#LuoyiBuff";
            log.from = xuchu;
            log.to << damage.to;
            log.arg = QString::number(damage.damage);
            log.arg2 = QString::number(++damage.damage);
            room->sendLog(log);

            data = QVariant::fromValue(damage);
        }

        return false;
    }
};

class DrMashu: public DistanceSkill {
public:
    DrMashu(): DistanceSkill("drmashu") {
    }

    virtual int getCorrect(const Player *from, const Player *to) const{
        if (to->hasSkill(objectName()))
            return +1;
        else if (from->hasSkill(objectName()))
            return -1;
        return 0;
    }
};

DrZhihengCard::DrZhihengCard() {
    mute = true;
}

bool DrZhihengCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const{
    return to_select == Self;
}

bool DrZhihengCard::targetsFeasible(const QList<const Player *> &targets, const Player *Self) const{
    return targets.length() <= 1;
}

void DrZhihengCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const{
    if (source->isAlive() && source->getHp() > source->getHandcardNum()) {
        room->broadcastSkillInvoke("zhiheng");
        room->drawCards(source, source->getHp() - source->getHandcardNum(), "drzhiheng");
    }
}

class DrZhihengViewAsSkill: public ViewAsSkill {
public:
    DrZhihengViewAsSkill(): ViewAsSkill("drzhiheng") {
        response_pattern = "@@drzhiheng";
    }

    virtual bool viewFilter(const QList<const Card *> &, const Card *to_select) const{
        return !to_select->isEquipped() && !Self->isJilei(to_select);
    }

    virtual bool isEnabledAtPlay(const Player *) const{
        return false;
    }

    virtual bool isEnabledAtResponse(const Player *, const QString &pattern) const{
        return pattern == "@@drzhiheng";
    }

    virtual const Card *viewAs(const QList<const Card *> &cards) const{
        DrZhihengCard *zhiheng_card = new DrZhihengCard;
        zhiheng_card->addSubcards(cards);
        return zhiheng_card;
    }
};

class DrZhiheng: public PhaseChangeSkill {
public:
    DrZhiheng(): PhaseChangeSkill("drzhiheng") {
        view_as_skill = new DrZhihengViewAsSkill;
    }

    virtual bool onPhaseChange(ServerPlayer *target) const{
        if (target->getPhase() == Player::Finish) {
            target->getRoom()->askForUseCard(target, "@@drzhiheng", "@drzhiheng-card", -1, Card::MethodDiscard);
        }
        return false;
    }
};

DrJiedaoCard::DrJiedaoCard() {
}

bool DrJiedaoCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const{
    return targets.isEmpty() && to_select->getWeapon() && to_select != Self;
}

void DrJiedaoCard::onEffect(const CardEffectStruct &effect) const{
    if (!effect.to->getWeapon()) return;
    effect.from->tag["DrJiedaoWeapon"] = effect.to->getWeapon()->getEffectiveId();
    effect.to->setFlags("DrJiedaoTarget");

    QList<CardsMoveStruct> exchangeMove;
    CardsMoveStruct move1(effect.to->getWeapon()->getEffectiveId(), effect.from, Player::PlaceEquip,
                          CardMoveReason(CardMoveReason::S_REASON_ROB, effect.from->objectName()));
    exchangeMove.push_back(move1);
    if (effect.from->getWeapon() != NULL) {
        CardsMoveStruct move2(effect.from->getWeapon()->getEffectiveId(), NULL, Player::DiscardPile,
                              CardMoveReason(CardMoveReason::S_REASON_CHANGE_EQUIP, effect.from->objectName()));
        exchangeMove.push_back(move2);
    }
    effect.to->getRoom()->moveCardsAtomic(exchangeMove, true);
}

class DrJiedaoViewAsSkill: public ZeroCardViewAsSkill {
public:
    DrJiedaoViewAsSkill():ZeroCardViewAsSkill("drjiedao") {
    }

    virtual bool isEnabledAtPlay(const Player *player) const{
        return !player->hasUsed("DrJiedaoCard");
    }

    virtual const Card *viewAs() const{
        return new DrJiedaoCard;
    }
};

class DrJiedao: public TriggerSkill {
public:
    DrJiedao(): TriggerSkill("drjiedao") {
        events << EventPhaseChanging;
        view_as_skill = new DrJiedaoViewAsSkill;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const{
        PhaseChangeStruct change = data.value<PhaseChangeStruct>();
        if (change.to != Player::NotActive) return false;
        int weapon_id = player->tag.value("DrJiedaoWeapon", -1).toInt();
        player->tag["DrJiedaoWeapon"] = -1;
        if (!player->getWeapon()
            || weapon_id != player->getWeapon()->getEffectiveId())
            return false;
        ServerPlayer *target = NULL;
        foreach (ServerPlayer *p, room->getOtherPlayers(player))
            if (p->hasFlag("DrJiedaoTarget")) {
                p->setFlags("-DrJiedaoTarget");
                target = p;
                break;
            }
        if (target == NULL) {
            room->throwCard(player->getWeapon(), NULL);
        } else {
            QList<CardsMoveStruct> exchangeMove;
            CardsMoveStruct move1(player->getWeapon()->getEffectiveId(), target, Player::PlaceEquip,
                                  CardMoveReason(CardMoveReason::S_REASON_GOTCARD, player->objectName()));
            exchangeMove.push_back(move1);
            if (target->getWeapon() != NULL) {
                CardsMoveStruct move2(target->getWeapon()->getEffectiveId(), NULL, Player::DiscardPile,
                                      CardMoveReason(CardMoveReason::S_REASON_CHANGE_EQUIP, target->objectName()));
                exchangeMove.push_back(move2);
            }
            room->moveCardsAtomic(exchangeMove, true);
        }

        return false;
    }
};

class DrWushuang: public TriggerSkill {
public:
    DrWushuang(): TriggerSkill("drwushuang") {
        events << TargetSpecified;
        frequency = Compulsory;
    }

    virtual bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const{
        CardUseStruct use = data.value<CardUseStruct>();
        if (use.card->isKindOf("Slash")) {
            QVariantList jink_list = player->tag["Jink_" + use.card->toString()].toList();
            int index = 0;
            for (int i = 0; i < use.to.length(); i++) {
                if (jink_list.at(index).toInt() == 1)
                    jink_list.replace(index, QVariant(2));
                index++;
            }
            LogMessage log;
            log.from = player;
            log.arg = objectName();
            log.type = "#TriggerSkill";
            room->sendLog(log);
            room->notifySkillInvoked(player, objectName());

            room->broadcastSkillInvoke("wushuang");
            player->tag["Jink_" + use.card->toString()] = QVariant::fromValue(jink_list);
        }
        return false;
    }
};

class DrJijiu: public TriggerSkill {
public:
    DrJijiu(): TriggerSkill("drjijiu") {
        events << DamageInflicted;
    }

    virtual bool triggerable(const ServerPlayer *target) const{
        return target != NULL;
    }

    virtual bool trigger(TriggerEvent, Room *room, ServerPlayer *, QVariant &data) const{
        ServerPlayer *huatuo = room->findPlayerBySkillName(objectName());
        if (!huatuo || !huatuo->canDiscard(huatuo, "he")) return false;

        bool has_red = false;
        if (huatuo->isKongcheng()) {
            for (int i = 0; i < 4; i++) {
                const EquipCard *equip = huatuo->getEquip(i);
                if (equip && equip->isRed()) {
                    has_red = true;
                    break;
                }
            }
        } else
            has_red = true;
        if (!has_red) return false;

        DamageStruct damage = data.value<DamageStruct>();
        if (room->askForCard(huatuo, ".|red", "@drjijiu-decrease", data, objectName())) {
            room->broadcastSkillInvoke("jijiu");
            LogMessage log;
            log.type = "#DrJijiuDecrease";
            log.from = huatuo;
            log.arg = QString::number(damage.damage);
            log.arg2 = QString::number(--damage.damage);
            room->sendLog(log);

            data = QVariant::fromValue(damage);
            if (damage.damage < 1)
                return true;
        }
        return false;
    }
};

DrQingnangCard::DrQingnangCard() {
    target_fixed = true;
    mute = true;
}

void DrQingnangCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const{
    room->broadcastSkillInvoke("qingnang");
    room->recover(source, RecoverStruct(source, this));
}

class DrQingnang: public OneCardViewAsSkill {
public:
    DrQingnang(): OneCardViewAsSkill("drqingnang") {
        filter_pattern = ".!";
    }

    virtual bool isEnabledAtPlay(const Player *player) const{
        return player->isWounded() && player->canDiscard(player, "he");
    }

    virtual const Card *viewAs(const Card *originalCard) const{
        DrQingnangCard *card = new DrQingnangCard;
        card->addSubcard(originalCard);
        return card;
    }
};

DragonPackage::DragonPackage():Package("dragon")
{
    General *dr_xuchu = new General(this, "dr_xuchu", "wei");
    dr_xuchu->addSkill(new DrLuoyi);

    General *dr_machao = new General(this, "dr_machao", "shu");
    dr_machao->addSkill(new DrMashu);

    General *dr_sunquan = new General(this, "dr_sunquan$", "wu");
    dr_sunquan->addSkill(new DrZhiheng);
    dr_sunquan->addSkill("jiuyuan");

    General *dr_zhouyu = new General(this, "dr_zhouyu", "wu", 3);
    dr_zhouyu->addSkill("nosyingzi");
    dr_zhouyu->addSkill(new DrJiedao);

    General *dr_huatuo = new General(this, "dr_huatuo", "qun", 3);
    dr_huatuo->addSkill(new DrJijiu);
    dr_huatuo->addSkill(new DrQingnang);

    General *dr_lvbu = new General(this, "dr_lvbu", "qun");
    dr_lvbu->addSkill(new DrWushuang);

    addMetaObject<DrZhihengCard>();
    addMetaObject<DrJiedaoCard>();
    addMetaObject<DrQingnangCard>();
}

ADD_PACKAGE(Dragon)

