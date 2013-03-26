#include "special3v3.h"
#include "skill.h"
#include "standard.h"
#include "server.h"
#include "engine.h"
#include "ai.h"
#include "maneuvering.h"
#include "clientplayer.h"

HongyuanCard::HongyuanCard() {
    mute = true;
}

bool HongyuanCard::targetsFeasible(const QList<const Player *> &targets, const Player *Self) const{
    return targets.length() <= 2 && !targets.contains(Self);
}

bool HongyuanCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const{
    return to_select != Self && targets.length() < 2;
}

void HongyuanCard::onEffect(const CardEffectStruct &effect) const{
   effect.to->setFlags("HongyuanTarget");
}

class HongyuanViewAsSkill: public ZeroCardViewAsSkill {
public:
    HongyuanViewAsSkill(): ZeroCardViewAsSkill("hongyuan") {
    }

    virtual const Card *viewAs() const{
        return new HongyuanCard;
    }

    virtual bool isEnabledAtPlay(const Player *) const{
        return false;
    }

    virtual bool isEnabledAtResponse(const Player *, const QString &pattern) const{
        return pattern == "@@hongyuan";
    }
};

class Hongyuan: public DrawCardsSkill {
public:
    Hongyuan(): DrawCardsSkill("hongyuan") {
        frequency = NotFrequent;
        view_as_skill = new HongyuanViewAsSkill;
    }

    virtual int getDrawNum(ServerPlayer *zhugejin, int n) const{
        Room *room = zhugejin->getRoom();
        bool invoke = false;
        if (room->getMode().startsWith("06_"))
            invoke = room->askForSkillInvoke(zhugejin, objectName());
        else
            invoke = room->askForUseCard(zhugejin, "@@hongyuan", "@hongyuan");
        if (invoke) {
            room->broadcastSkillInvoke(objectName());
            zhugejin->setFlags("hongyuan");
            return n - 1;
        } else
            return n;
    }
};

class HongyuanDraw: public TriggerSkill {
public:
    HongyuanDraw(): TriggerSkill("#hongyuan") {
        events << AfterDrawNCards;
    }

    virtual bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const{
        if (!player->hasFlag("hongyuan"))
            return false;
        player->setFlags("-hongyuan");

        QList<ServerPlayer *> targets;
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (room->getMode().startsWith("06_")) {
                if (AI::GetRelation3v3(player, p) == AI::Friend)
                    targets << p;
            } else if (p->hasFlag("HongyuanTarget")) {
                p->setFlags("-HongyuanTarget");
                targets << p;
            }
        }

        if (targets.isEmpty()) return false;
        room->drawCards(targets, 1, "hongyuan");
        return false;
    }
};

class Huanshi: public TriggerSkill {
public:
    Huanshi(): TriggerSkill("huanshi") {
        events << AskForRetrial;
    }

    QList<ServerPlayer *> getTeammates(ServerPlayer *zhugejin) const{
        Room *room = zhugejin->getRoom();

        QList<ServerPlayer *> teammates;
        teammates << zhugejin;
        foreach (ServerPlayer *other, room->getOtherPlayers(zhugejin)) {
            if (AI::GetRelation3v3(zhugejin, other) == AI::Friend)
                teammates << other;
        }
        return teammates;
    }

    virtual bool triggerable(const ServerPlayer *target) const{
        return TriggerSkill::triggerable(target) && !target->isNude();
    }

    virtual bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const{
        JudgeStar judge = data.value<JudgeStar>();

        bool can_invoke = false;
        if (room->getMode().startsWith("06_")) {
            foreach (ServerPlayer *teammate, getTeammates(player)) {
                if (teammate == judge->who) {
                    can_invoke = true;
                    break;
                }
            }
         } else if (!player->isNude())
            can_invoke = (judge->who == player || room->askForChoice(judge->who, "huanshi", "accept+reject") == "accept");

        if (!can_invoke) {
            LogMessage log;
            log.type = "#ZhibaReject";
            log.from = judge->who;
            log.to << player;
            log.arg = objectName();
            room->sendLog(log);

            return false;
        }

        QStringList prompt_list;
        prompt_list << "@huanshi-card" << judge->who->objectName()
                    << objectName() << judge->reason << QString::number(judge->card->getEffectiveId());
        QString prompt = prompt_list.join(":");

        const Card *card = room->askForCard(player, "..", prompt, data, Card::MethodResponse, judge->who, true);
        if (card != NULL) {
            room->broadcastSkillInvoke(objectName());
            room->retrial(card, player, judge, objectName());
        }

        return false;
    }
};

class Mingzhe: public TriggerSkill {
public:
    Mingzhe(): TriggerSkill("mingzhe") {
        events << BeforeCardsMove << CardsMoveOneTime;
        frequency = Frequent;
    }

    virtual bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const{
        if (player->getPhase() != Player::NotActive)
            return false;

        CardsMoveOneTimeStar move = data.value<CardsMoveOneTimeStar>();
        if (move->from != player)
            return false;

        if (event == BeforeCardsMove) {
            CardMoveReason reason = move->reason;

            if ((reason.m_reason & CardMoveReason::S_MASK_BASIC_REASON) == CardMoveReason::S_REASON_USE
                || (reason.m_reason & CardMoveReason::S_MASK_BASIC_REASON) == CardMoveReason::S_REASON_DISCARD
                || (reason.m_reason & CardMoveReason::S_MASK_BASIC_REASON) == CardMoveReason::S_REASON_RESPONSE) {
                const Card *card;
                int i = 0;
                foreach (int card_id, move->card_ids) {
                    card = Sanguosha->getCard(card_id);
                    if (card->isRed() && (move->from_places[i] == Player::PlaceHand
                                          || move->from_places[i] == Player::PlaceEquip)) {
                        player->addMark(objectName());
                    }
                    i++;
                }
            }
        } else {
            for (int i = 0; i < player->getMark(objectName()); i++) {
                if (player->askForSkillInvoke(objectName(), data)) {
                    room->broadcastSkillInvoke(objectName());
                    player->drawCards(1);
                } else {
                    break;
                }
            }
            player->setMark(objectName(), 0);
        }
        return false;
    }
};

class VsGanglie: public MasochismSkill {
public:
    VsGanglie(): MasochismSkill("vsganglie") {
    }

    virtual void onDamaged(ServerPlayer *xiahou, const DamageStruct &) const{
        Room *room = xiahou->getRoom();
        ServerPlayer *from = room->askForPlayerChosen(xiahou, room->getOtherPlayers(xiahou), objectName(), "vsganglie-invoke", true, true);
        if (!from) return;

        room->broadcastSkillInvoke("ganglie");

        JudgeStruct judge;
        judge.pattern = QRegExp("(.*):(heart):(.*)");
        judge.good = false;
        judge.reason = objectName();
        judge.who = xiahou;

        room->judge(judge);
        if (from->isDead()) return;
        if (judge.isGood()) {
            if (!room->askForDiscard(from, objectName(), 2, 2, true)) {
                DamageStruct damage;
                damage.from = xiahou;
                damage.to = from;
                damage.reason = objectName();
                room->damage(damage);
            }
        }
    }
};

ZhongyiCard::ZhongyiCard() {
    mute = true;
    will_throw = false;
    target_fixed = true;
    handling_method = Card::MethodNone;
}

void ZhongyiCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const{
    room->broadcastSkillInvoke("zhongyi");
    room->doLightbox("$ZhongyiAnimate");
    source->loseMark("@loyal");
    source->addToPile("loyal", this);
}

class Zhongyi: public OneCardViewAsSkill {
public:
    Zhongyi(): OneCardViewAsSkill("zhongyi") {
        frequency = Limited;
    }

    virtual bool viewFilter(const Card *to_select) const{
        return !to_select->isEquipped() && to_select->isRed();
    }

    virtual bool isEnabledAtPlay(const Player *player) const{
        return !player->isKongcheng() && player->getMark("@loyal") > 0;
    }

    virtual const Card *viewAs(const Card *originalCard) const{
        ZhongyiCard *card = new ZhongyiCard;
        card->addSubcard(originalCard);
        return card;
    }
};

class ZhongyiAction: public TriggerSkill {
public:
    ZhongyiAction(): TriggerSkill("#zhongyi-action") {
        events << ConfirmDamage << EventPhaseStart << ActionedReset;
    }

    virtual bool triggerable(const ServerPlayer *target) const{
        return target != NULL;
    }

    virtual bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const{
        QString mode = room->getMode();
        if (event == ConfirmDamage) {
            DamageStruct damage = data.value<DamageStruct>();
            if (damage.card && damage.card->isKindOf("Slash")) {
                foreach (ServerPlayer *p, room->getAllPlayers()) {
                    if (p->getPile("loyal").isEmpty()) continue;
                    bool on_effect = false;
                    if (room->getMode().startsWith("06_"))
                        on_effect = (AI::GetRelation3v3(player, p) == AI::Friend);
                    else
                        on_effect = (room->askForSkillInvoke(p, "zhongyi", data));
                    if (on_effect) {
                        LogMessage log;
                        log.type = "#ZhongyiBuff";
                        log.from = p;
                        log.to << damage.to;
                        log.arg = QString::number(damage.damage);
                        log.arg2 = QString::number(++damage.damage);
                        room->sendLog(log);
                    }
                }
            }
            data = QVariant::fromValue(damage);
        } else if ((mode == "06_3v3" && event == ActionedReset) || (mode != "06_3v3" && event == EventPhaseStart)) {
            if (event == EventPhaseStart && player->getPhase() != Player::RoundStart)
                return false;
            if (player->getPile("loyal").length() > 0)
                player->clearOnePrivatePile("loyal");
        }
        return false;
    }
};

class Jiuzhu: public TriggerSkill {
public:
    Jiuzhu(): TriggerSkill("jiuzhu") {
        events << AskForPeaches;
    }

    virtual bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const{
        DyingStruct dying = data.value<DyingStruct>();
        if (dying.who == player || (room->getMode().startsWith("06_") && AI::GetRelation3v3(dying.who, player) != AI::Friend))
            return false;
        while (dying.who->getHp() <= 0) {
            if (player->getHp() <= 1 || player->isNude())
                break;
            if (room->askForCard(player, "..", "@jiuzhu", data, objectName())) {
                room->loseHp(player);
                room->broadcastSkillInvoke(objectName());
                RecoverStruct recover;
                recover.who = player;
                room->recover(dying.who, recover);
            }
        }
        return (dying.who->getHp() > 0);
    }
};

class Zhanshen: public TriggerSkill {
public:
    Zhanshen(): TriggerSkill("zhanshen") {
        events << Death << EventPhaseStart;
        frequency = Wake;
    }

    virtual bool triggerable(const ServerPlayer *target) const{
        return target != NULL;
    }

    virtual bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const{
        if (event == Death) {
            DeathStruct death = data.value<DeathStruct>();
            if (death.who != player)
                return false;
            foreach (ServerPlayer *lvbu, room->findPlayersBySkillName(objectName())) {
                if (room->getMode().startsWith("06_")) {
                    if (lvbu->getMark(objectName()) == 0 && lvbu->getMark("zhanshen_fight") == 0
                        && AI::GetRelation3v3(lvbu, player) == AI::Friend)
                        lvbu->addMark("zhanshen_fight");
                } else {
                    if (lvbu->getMark(objectName()) == 0 && lvbu->getMark("@fight") == 0
                        && room->askForSkillInvoke(player, objectName(), "mark:" + lvbu->objectName()))
                        room->addPlayerMark(lvbu, "@fight");
                }
            }
        } else if (TriggerSkill::triggerable(player)
                   && player->getPhase() == Player::Start
                   && player->getMark(objectName()) == 0
                   && player->isWounded()
                   && (player->getMark("zhanshen_fight") > 0 || player->getMark("@fight") > 0)) {
            room->notifySkillInvoked(player, objectName());

            LogMessage log;
            log.type = "#ZhanshenWake";
            log.from = player;
            log.arg = objectName();
            room->sendLog(log);

            room->broadcastSkillInvoke(objectName());
            room->doLightbox("$ZhanshenAnimate");

            if (player->getMark("@fight") > 0)
                room->setPlayerMark(player, "@fight", 0);
            player->setMark("zhanshen_fight", 0);
            room->addPlayerMark(player, objectName());
            if (room->changeMaxHpForAwakenSkill(player)) {
                if (player->getWeapon())
                    room->throwCard(player->getWeapon(), player);
                room->acquireSkill(player, "mashu");
                room->acquireSkill(player, "shenji");
            }
        }
        return false;
    }
};

New3v3CardPackage::New3v3CardPackage()
    : Package("New3v3Card")
{
    QList<Card *> cards;
    cards << new SupplyShortage(Card::Spade, 1)
          << new SupplyShortage(Card::Club, 12)
          << new Nullification(Card::Heart, 12);

    foreach (Card *card, cards)
        card->setParent(this);

    type = CardPack;
}

ADD_PACKAGE(New3v3Card)

Special3v3Package::Special3v3Package()
    : Package("Special3v3")
{
    General *zhugejin = new General(this, "zhugejin", "wu", 3);
    zhugejin->addSkill(new Hongyuan);
    zhugejin->addSkill(new HongyuanDraw);
    zhugejin->addSkill(new Huanshi);
    zhugejin->addSkill(new Mingzhe);
    related_skills.insertMulti("hongyuan", "#hongyuan");

    addMetaObject<HongyuanCard>();
}

ADD_PACKAGE(Special3v3)

Special3v3_2013Package::Special3v3_2013Package()
    : Package("Special3v3_2013")
{
    General *vs_xiahoudun = new General(this, "vs_xiahoudun", "wei");
    vs_xiahoudun->addSkill(new VsGanglie);

    General *vs_guanyu = new General(this, "vs_guanyu", "shu");
    vs_guanyu->addSkill("wusheng");
    vs_guanyu->addSkill(new Zhongyi);
    vs_guanyu->addSkill(new ZhongyiAction);
    vs_guanyu->addSkill(new MarkAssignSkill("@loyal", 1));
    related_skills.insertMulti("zhongyi", "#zhongyi-action");
    related_skills.insertMulti("zhongyi", "#@loyal-1");

    General *vs_zhaoyun = new General(this, "vs_zhaoyun", "shu");
    vs_zhaoyun->addSkill("longdan");
    vs_zhaoyun->addSkill(new Jiuzhu);

    General *vs_lvbu = new General(this, "vs_lvbu", "qun");
    vs_lvbu->addSkill("wushuang");
    vs_lvbu->addSkill(new Zhanshen);

    /*
    General *wenpin = new General(this, "wenpin", "wei");
    */

    addMetaObject<ZhongyiCard>();
}

ADD_PACKAGE(Special3v3_2013)

