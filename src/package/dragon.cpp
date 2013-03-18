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
        events << ConfirmDamage;
        frequency = Compulsory;
    }

    virtual bool trigger(TriggerEvent, Room *room, ServerPlayer *xuchu, QVariant &data) const{
        DamageStruct damage = data.value<DamageStruct>();

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
        room->drawCards(source, source->getHp() - source->getHandcardNum());
    }
}

class DrZhihengViewAsSkill: public ViewAsSkill {
public:
    DrZhihengViewAsSkill(): ViewAsSkill("drzhiheng") {
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

DrJiuyuanCard::DrJiuyuanCard() {
    will_throw = false;
    handling_method = Card::MethodNone;
    m_skillName = "drjiuyuanv";
    mute = true;
}

void DrJiuyuanCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const{
    ServerPlayer *sunquan = targets.first();
    if (sunquan->hasLordSkill("drjiuyuan")) {
        room->setPlayerFlag(sunquan, "DrJiuyuanInvoked");
        room->notifySkillInvoked(sunquan, "drjiuyuan");
        sunquan->obtainCard(this, false);
        QList<ServerPlayer *> sunquans;
        QList<ServerPlayer *> players = room->getOtherPlayers(source);
        foreach (ServerPlayer *p, players) {
            if (p->hasLordSkill("drjiuyuan") && !p->hasFlag("DrJiuyuanInvoked"))
                sunquans << p;
        }
        if (sunquans.empty())
            room->setPlayerFlag(source, "ForbidDrJiuyuan");
    }
}

bool DrJiuyuanCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const{
    return targets.isEmpty() && to_select->hasLordSkill("drjiuyuan") && !to_select->hasFlag("DrJiuyuanInvoked");
}

class DrJiuyuanViewAsSkill: public OneCardViewAsSkill {
public:
    DrJiuyuanViewAsSkill(): OneCardViewAsSkill("drjiuyuanv") {
        attached_lord_skill = true;
    }

    virtual bool isEnabledAtPlay(const Player *player) const{
        return player->getKingdom() == "wu" && !player->hasFlag("ForbidDrJiuyuan") && !player->isKongcheng();
    }

    virtual bool viewFilter(const Card *to_select) const{
        return !to_select->isEquipped();
    }

    virtual const Card *viewAs(const Card *originalCard) const{
        DrJiuyuanCard *card = new DrJiuyuanCard;
        card->addSubcard(originalCard);

        return card;
    }
};

class DrJiuyuan: public TriggerSkill {
public:
    DrJiuyuan():TriggerSkill("drjiuyuan$") {
        events << GameStart << EventPhaseChanging;
    }

    virtual bool triggerable(const ServerPlayer *target) const{
        return target != NULL;
    }

    virtual bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const{
        if (event == GameStart && player->isLord()) {
            QList<ServerPlayer *> lords;
            foreach (ServerPlayer *p, room->getAlivePlayers())
                if (p->hasLordSkill(objectName()))
                    lords << p;

            foreach (ServerPlayer *lord, lords) {
                QList<ServerPlayer *> players = room->getOtherPlayers(lord);
                foreach (ServerPlayer *p, players) {
                    if (!p->hasSkill("drjiuyuanv"))
                        room->attachSkillToPlayer(p, "drjiuyuanv");
                }
            }
        } else if (event == EventPhaseChanging) {
            PhaseChangeStruct phase_change = data.value<PhaseChangeStruct>();
            if (phase_change.from != Player::Play)
                  return false;
            if (player->hasFlag("ForbidDrJiuyuan")) {
                room->setPlayerFlag(player, "-ForbidDrJiuyuan");
            }
            QList<ServerPlayer *> players = room->getOtherPlayers(player);
            foreach (ServerPlayer *p, players) {
                if (p->hasFlag("DrJiuyuanInvoked")) {
                    room->setPlayerFlag(p, "-DrJiuyuanInvoked");
                }
            }
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
    effect.to->getRoom()->setPlayerFlag(effect.to, "DrJiedaoTarget");

    QList<CardsMoveStruct> exchangeMove;
    CardsMoveStruct move1;
    move1.card_ids << effect.to->getWeapon()->getEffectiveId();
    move1.to = effect.from;
    move1.to_place = Player::PlaceEquip;
    move1.reason = CardMoveReason(CardMoveReason::S_REASON_ROB, effect.from->objectName());
    exchangeMove.push_back(move1);
    if (effect.from->getWeapon() != NULL) {
        CardsMoveStruct move2;
        move2.card_ids << effect.from->getWeapon()->getEffectiveId();
        move2.to = NULL;
        move2.to_place = Player::DiscardPile;
        move2.reason = CardMoveReason(CardMoveReason::S_REASON_CHANGE_EQUIP, effect.from->objectName());
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
                room->setPlayerFlag(p, "-DrJiedaoTarget");
                target = p;
                break;
            }
        if (target == NULL) {
            room->throwCard(player->getWeapon(), NULL);
        } else {
            QList<CardsMoveStruct> exchangeMove;
            CardsMoveStruct move1;
            move1.card_ids << player->getWeapon()->getEffectiveId();
            move1.to = target;
            move1.to_place = Player::PlaceEquip;
            move1.reason = CardMoveReason(CardMoveReason::S_REASON_GOTCARD, player->objectName());
            exchangeMove.push_back(move1);
            if (target->getWeapon() != NULL) {
                CardsMoveStruct move2;
                move2.card_ids << target->getWeapon()->getEffectiveId();
                move2.to = NULL;
                move2.to_place = Player::DiscardPile;
                move2.reason = CardMoveReason(CardMoveReason::S_REASON_CHANGE_EQUIP, target->objectName());
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
        events << TargetConfirmed << CardFinished;
        frequency = Compulsory;
    }

    virtual bool triggerable(const ServerPlayer *target) const{
        return target != NULL;
    }

    virtual bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const{
        if (event == TargetConfirmed) {
            CardUseStruct use = data.value<CardUseStruct>();
            bool can_invoke = false;
            if (use.card->isKindOf("Slash") && TriggerSkill::triggerable(use.from) && use.from == player) {
                can_invoke = true;
                int count = 1;
                int mark_n = player->getMark("double_jink" + use.card->toString());
                for (int i = 0; i < use.to.length(); i++) {
                    mark_n += count;
                    player->setMark("double_jink" + use.card->toString(), mark_n);
                    count *= 10;
                }
            }
            if (!can_invoke) return false;

            LogMessage log;
            log.from = player;
            log.arg = objectName();
            log.type = "#TriggerSkill";
            room->sendLog(log);
            room->notifySkillInvoked(player, objectName());

            room->broadcastSkillInvoke("wushuang");
        } else if (event == CardFinished) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card->isKindOf("Slash")) {
                if (player->getMark("double_jink" + use.card->toString()) > 0)
                    player->setMark("double_jink" + use.card->toString(), 0);
            }
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
        if (!huatuo || huatuo->isNude()) return false;

        DamageStruct damage = data.value<DamageStruct>();
        if (room->askForCard(huatuo, ".|.|.|.|red", "@DrJijiuDecrease", data, objectName())) {
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
    RecoverStruct recover;
    recover.card = this;
    recover.who = source;
    room->recover(source, recover);
}

class DrQingnang: public OneCardViewAsSkill {
public:
    DrQingnang(): OneCardViewAsSkill("drqingnang") {
    }

    virtual bool isEnabledAtPlay(const Player *player) const{
        return player->isWounded() && !player->isNude();
    }

    virtual bool viewFilter(const Card *to_select) const{
        return !Self->isJilei(to_select);
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
    dr_sunquan->addSkill(new DrJiuyuan);

    General *dr_zhouyu = new General(this, "dr_zhouyu", "wu", 3);
    dr_zhouyu->addSkill("yingzi");
    dr_zhouyu->addSkill(new DrJiedao);

    General *dr_huatuo = new General(this, "dr_huatuo", "qun", 3);
    dr_huatuo->addSkill(new DrJijiu);
    dr_huatuo->addSkill(new DrQingnang);

    General *dr_lvbu = new General(this, "dr_lvbu", "qun");
    dr_lvbu->addSkill(new DrWushuang);

    skills << new DrJiuyuanViewAsSkill;

    addMetaObject<DrZhihengCard>();
    addMetaObject<DrJiuyuanCard>();
    addMetaObject<DrJiedaoCard>();
    addMetaObject<DrQingnangCard>();
}

ADD_PACKAGE(Dragon)

