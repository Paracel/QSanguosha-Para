#include "general.h"
#include "standard.h"
#include "skill.h"
#include "engine.h"
#include "client.h"
#include "serverplayer.h"
#include "room.h"
#include "standard-skillcards.h"
#include "ai.h"

class Jianxiong: public MasochismSkill {
public:
    Jianxiong(): MasochismSkill("jianxiong") {
    }

    virtual void onDamaged(ServerPlayer *caocao, const DamageStruct &damage) const{
        Room *room = caocao->getRoom();
        const Card *card = damage.card;
        if (card && room->getCardPlace(card->getEffectiveId()) == Player::PlaceTable) {
            QVariant data = QVariant::fromValue(card);
            if (room->askForSkillInvoke(caocao, "jianxiong", data)) {
                room->broadcastSkillInvoke(objectName());
                caocao->obtainCard(card);
            }
        }
    }
};

class Hujia: public TriggerSkill {
public:
    Hujia(): TriggerSkill("hujia$") {
        events << CardAsked;
        default_choice = "ignore";
    }

    virtual bool triggerable(const ServerPlayer *target) const{
        return target != NULL && target->hasLordSkill("hujia");
    }

    virtual bool trigger(TriggerEvent, Room *room, ServerPlayer *caocao, QVariant &data) const{
        QString pattern = data.toStringList().first();
        if (pattern != "jink")
            return false;

        QList<ServerPlayer *> lieges = room->getLieges("wei", caocao);
        if (lieges.isEmpty())
            return false;

        if (!room->askForSkillInvoke(caocao, objectName()))
            return false;

        room->broadcastSkillInvoke(objectName());
        QVariant tohelp = QVariant::fromValue((PlayerStar)caocao);
        foreach (ServerPlayer *liege, lieges) {
            const Card *jink = room->askForCard(liege, "jink", "@hujia-jink:" + caocao->objectName(),
                                                tohelp, Card::MethodResponse, caocao);
            if (jink) {
                room->provide(jink);
                return true;
            }
        }

        return false;
    }
};

class TuxiViewAsSkill: public ZeroCardViewAsSkill {
public:
    TuxiViewAsSkill(): ZeroCardViewAsSkill("tuxi") {
    }

    virtual const Card *viewAs() const{
        return new TuxiCard;
    }

    virtual bool isEnabledAtPlay(const Player *player) const{
        return false;
    }

    virtual bool isEnabledAtResponse(const Player *player, const QString &pattern) const{
        return  pattern == "@@tuxi";
    }
};

class Tuxi: public PhaseChangeSkill {
public:
    Tuxi(): PhaseChangeSkill("tuxi") {
        view_as_skill = new TuxiViewAsSkill;
    }

    virtual bool onPhaseChange(ServerPlayer *zhangliao) const{
        if (zhangliao->getPhase() == Player::Draw) {
            Room *room = zhangliao->getRoom();
            bool can_invoke = false;
            QList<ServerPlayer *> other_players = room->getOtherPlayers(zhangliao);
            foreach (ServerPlayer *player, other_players) {
                if (!player->isKongcheng()) {
                    can_invoke = true;
                    break;
                }
            }

            if (can_invoke && room->askForUseCard(zhangliao, "@@tuxi", "@tuxi-card"))
                return true;
        }

        return false;
    }
};

class Tiandu: public TriggerSkill {
public:
    Tiandu(): TriggerSkill("tiandu") {
        frequency = Frequent;
        default_choice = "no";
        events << FinishJudge;
    }

    virtual bool trigger(TriggerEvent, Room *room, ServerPlayer *guojia, QVariant &data) const{
        JudgeStar judge = data.value<JudgeStar>();
        CardStar card = judge->card;

        QVariant data_card = QVariant::fromValue(card);
        if (guojia->askForSkillInvoke(objectName(), data_card)) {
            guojia->obtainCard(judge->card);
            room->broadcastSkillInvoke(objectName());
            return false;
        }

        return false;
    }
};

class Yiji: public MasochismSkill {
public:
    Yiji(): MasochismSkill("yiji") {
        frequency = Frequent;
    }

    virtual void onDamaged(ServerPlayer *guojia, const DamageStruct &damage) const{
        Room *room = guojia->getRoom();
        int x = damage.damage, i;
        for (i = 0; i < x; i++) {
            if(!room->askForSkillInvoke(guojia, objectName()))
                return;
            room->broadcastSkillInvoke(objectName());
            room->setPlayerFlag(guojia, "Yiji_InTempMoving");
            QList<int> yiji_cards;
            yiji_cards.append(room->drawCard());
            yiji_cards.append(room->drawCard());
            CardsMoveStruct move;
            move.card_ids = yiji_cards;
            move.to = guojia;
            move.to_place = Player::PlaceHand;
            move.reason = CardMoveReason(CardMoveReason::S_REASON_PREVIEW, guojia->objectName(), "yiji", QString());
            room->moveCardsAtomic(move, false);

            if (yiji_cards.isEmpty()) {
                room->setPlayerFlag(guojia, "-Yiji_InTempMoving");
                continue;
            }

            while (room->askForYiji(guojia, yiji_cards)) {}

            if (yiji_cards.isEmpty()) {
                room->setPlayerFlag(guojia, "-Yiji_InTempMoving");
                continue;
            }

            guojia->addToPile("#yiji_tempPile", yiji_cards, false);
            DummyCard *dummy = new DummyCard;
            foreach (int id, yiji_cards)
                dummy->addSubcard(id);
            room->setPlayerFlag(guojia, "-Yiji_InTempMoving");
            guojia->obtainCard(dummy, false);
            dummy->deleteLater();
        }
    }
};

class YijiAvoidTriggeringCardsMove: public TriggerSkill {
public:
    YijiAvoidTriggeringCardsMove(): TriggerSkill("#yiji-avoid-triggering-cards-move") {
        events << CardsMoving << CardsMoveOneTime;
    }

    virtual int getPriority() const{
        return 10;
    }

    virtual bool trigger(TriggerEvent, Room *, ServerPlayer *player, QVariant &) const{
        if (player->hasFlag("Yiji_InTempMoving"))
            return true;
        return false;
    }
};

class Ganglie: public MasochismSkill {
public:
    Ganglie(): MasochismSkill("ganglie") {
    }

    virtual void onDamaged(ServerPlayer *xiahou, const DamageStruct &damage) const{
        ServerPlayer *from = damage.from;
        Room *room = xiahou->getRoom();
        QVariant source = QVariant::fromValue(from);

        if (from && room->askForSkillInvoke(xiahou, "ganglie", source)) {
            room->broadcastSkillInvoke(objectName());

            JudgeStruct judge;
            judge.pattern = QRegExp("(.*):(heart):(.*)");
            judge.good = false;
            judge.reason = objectName();
            judge.who = xiahou;

            room->judge(judge);
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
    }
};

class Fankui: public MasochismSkill {
public:
    Fankui(): MasochismSkill("fankui") {
    }

    virtual void onDamaged(ServerPlayer *simayi, const DamageStruct &damage) const{
        ServerPlayer *from = damage.from;
        Room *room = simayi->getRoom();
        QVariant data = QVariant::fromValue(from);
        if (from && !from->isNude() && room->askForSkillInvoke(simayi, "fankui", data)) {
            room->broadcastSkillInvoke(objectName());
            int card_id = room->askForCardChosen(simayi, from, "he", "fankui");
            CardMoveReason reason(CardMoveReason::S_REASON_EXTRACTION, simayi->objectName());
            room->obtainCard(simayi, Sanguosha->getCard(card_id),
                             reason, room->getCardPlace(card_id) != Player::PlaceHand);
        }
    }
};

class GuicaiViewAsSkill: public OneCardViewAsSkill {
public:
    GuicaiViewAsSkill() :OneCardViewAsSkill("guicai") {
    }

    virtual bool isEnabledAtPlay(const Player *player) const{
        return false;
    }

    virtual bool isEnabledAtResponse(const Player *player, const QString &pattern) const{
        return pattern == "@guicai";
    }

    virtual bool viewFilter(const Card *to_select) const{
        return !to_select->isEquipped();
    }

    virtual const Card *viewAs(const Card *originalCard) const{
        Card *card = new GuicaiCard;
        card->addSubcard(originalCard);
        return card;
    }
};

class Guicai: public TriggerSkill {
public:
    Guicai(): TriggerSkill("guicai") {
        events << AskForRetrial;
        view_as_skill = new GuicaiViewAsSkill;
    }

    virtual bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const{
        if (player->isKongcheng())
            return false;

        JudgeStar judge = data.value<JudgeStar>();

        QStringList prompt_list;
        prompt_list << "@guicai-card" << judge->who->objectName()
                    << objectName() << judge->reason << QString::number(judge->card->getEffectiveId());
        QString prompt = prompt_list.join(":");
        const Card *card = room->askForCard(player, "@guicai", prompt, data, Card::MethodResponse, judge->who, true);
        if (card) {
            if (player->hasInnateSkill("guicai") || !player->hasSkill("jilve"))
                room->broadcastSkillInvoke(objectName());
            else
                room->broadcastSkillInvoke("jilve", 1);
            room->retrial(card, player, judge, objectName());
        }

        return false;
    }
};

class LuoyiBuff: public TriggerSkill {
public:
    LuoyiBuff(): TriggerSkill("#luoyi") {
        events << ConfirmDamage;
    }

    virtual bool triggerable(const ServerPlayer *target) const{
        return target != NULL && target->hasFlag("luoyi") && target->isAlive();
    }

    virtual bool trigger(TriggerEvent, Room *room, ServerPlayer *xuchu, QVariant &data) const{
        DamageStruct damage = data.value<DamageStruct>();
        const Card *reason = damage.card;

        if (reason && (reason->isKindOf("Slash") || reason->isKindOf("Duel"))) {
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

class Luoyi: public DrawCardsSkill {
public:
    Luoyi(): DrawCardsSkill("luoyi") {
    }

    virtual int getDrawNum(ServerPlayer *xuchu, int n) const{
        Room *room = xuchu->getRoom();
        if (room->askForSkillInvoke(xuchu, objectName())) {
            room->broadcastSkillInvoke(objectName());
            xuchu->setFlags(objectName());
            return n - 1;
        } else
            return n;
    }
};

class Luoshen: public TriggerSkill {
public:
    Luoshen(): TriggerSkill("luoshen") {
        events << EventPhaseStart << FinishJudge;
        frequency = Frequent;
    }

    virtual bool trigger(TriggerEvent event, Room *room, ServerPlayer *zhenji, QVariant &data) const{
        if (event == EventPhaseStart && zhenji->getPhase() == Player::Start) {
            while (zhenji->askForSkillInvoke("luoshen")) {
                room->broadcastSkillInvoke(objectName());

                JudgeStruct judge;
                judge.pattern = QRegExp("(.*):(spade|club):(.*)");
                judge.good = true;
                judge.reason = objectName();
                judge.play_animation = false;
                judge.who = zhenji;
                judge.time_consuming = true;

                room->judge(judge);
                if (judge.isBad())
                    break;
            }
        } else if (event == FinishJudge) {
            JudgeStar judge = data.value<JudgeStar>();
            if (judge->reason == objectName() && judge->card->isBlack())
                zhenji->obtainCard(judge->card);
        }

        return false;
    }
};

class Qingguo: public OneCardViewAsSkill {
public:
    Qingguo(): OneCardViewAsSkill("qingguo") {
    }

    virtual bool viewFilter(const Card *to_select) const{
        return to_select->isBlack() && !to_select->isEquipped();
    }

    virtual const Card *viewAs(const Card *originalCard) const{
        Jink *jink = new Jink(originalCard->getSuit(), originalCard->getNumber());
        jink->setSkillName(objectName());
        jink->addSubcard(originalCard->getId());
        return jink;
    }

    virtual bool isEnabledAtPlay(const Player *player) const{
        return false;
    }

    virtual bool isEnabledAtResponse(const Player *player, const QString &pattern) const{
        return pattern == "jink";
    }
};

class RendeViewAsSkill: public ViewAsSkill {
public:
    RendeViewAsSkill(): ViewAsSkill("rende") {
    }

    virtual bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const{
        if (ServerInfo.GameMode == "04_1v3"
            && selected.length() + Self->getMark("rende") >= 2)
           return false;
        else
            return !to_select->isEquipped();
    }

    virtual const Card *viewAs(const QList<const Card *> &cards) const{
        if (cards.isEmpty())
            return NULL;

        RendeCard *rende_card = new RendeCard;
        rende_card->addSubcards(cards);
        return rende_card;
    }
};

class Rende: public TriggerSkill {
public:
    Rende(): TriggerSkill("rende") {
        events << EventPhaseChanging;
        view_as_skill = new RendeViewAsSkill;
    }

    virtual bool triggerable(const ServerPlayer *target) const{
        return target != NULL && target->getMark("rende") > 0;
    }

    virtual bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const{
        PhaseChangeStruct change = data.value<PhaseChangeStruct>();
        if (change.to != Player::NotActive)
            return false;
        room->setPlayerMark(player, "rende", 0);
        return false;
    }
};

class JijiangViewAsSkill: public ZeroCardViewAsSkill {
public:
    JijiangViewAsSkill(): ZeroCardViewAsSkill("jijiang$") {
    }

    virtual bool isEnabledAtPlay(const Player *player) const{
        return hasShuGenerals(player) && player->hasLordSkill("jijiang") && Slash::IsAvailable(player);
    }

    virtual const Card *viewAs() const{
        return new JijiangCard;
    }

    virtual bool isEnabledAtResponse(const Player *player, const QString &pattern) const{
        return hasShuGenerals(player)
               && pattern == "slash" && !ClientInstance->hasNoTargetResponding()
               && !player->hasFlag("jijiang_failed");
    }

private:
    static bool hasShuGenerals(const Player *player) {
        foreach (const Player *p, player->getSiblings())
            if (p->getKingdom() == "shu")
                return true;
        return false;
    }
};

class Jijiang: public TriggerSkill {
public:
    Jijiang(): TriggerSkill("jijiang$") {
        events << CardAsked;
        default_choice = "ignore";
        view_as_skill = new JijiangViewAsSkill;
    }

    virtual bool triggerable(const ServerPlayer *target) const{
        return target != NULL && target->hasLordSkill("jijiang");
    }

    virtual bool trigger(TriggerEvent, Room *room, ServerPlayer *liubei, QVariant &data) const{
        QString pattern = data.toStringList().first();
        if (pattern != "slash")
            return false;
                
        QList<ServerPlayer *> lieges = room->getLieges("shu", liubei);
        if (lieges.isEmpty())
            return false;

        if (!room->askForSkillInvoke(liubei, objectName()))
            return false;

        room->broadcastSkillInvoke(objectName(), getEffectIndex(liubei, NULL));

        foreach (ServerPlayer *liege, lieges) {
            const Card *slash = room->askForCard(liege, "slash", "@jijiang-slash:" + liubei->objectName(), QVariant(), Card::MethodResponse, liubei);
            if (slash) {
                room->provide(slash);
                return true;
            }
        }

        return false;
    }

    virtual int getEffectIndex(const ServerPlayer *player, const Card *) const{
        int r = 1 + qrand() % 2;
        if (!player->hasInnateSkill("jijiang") && player->hasSkill("ruoyu"))
            r += 2;
        return r;
    }
};

class Wusheng: public OneCardViewAsSkill {
public:
    Wusheng(): OneCardViewAsSkill("wusheng") {
    }

    virtual bool isEnabledAtPlay(const Player *player) const{
        return Slash::IsAvailable(player);
    }

    virtual bool isEnabledAtResponse(const Player *, const QString &pattern) const{
        return pattern == "slash";
    }

    virtual bool viewFilter(const Card* card) const{
        if (!card->isRed())
            return false;

        if (Self->getWeapon()
            && card->getEffectiveId() == Self->getWeapon()->getId() && card->objectName() == "crossbow")
            return Self->canSlashWithoutCrossbow();
        else
            return true;
    }

    virtual const Card *viewAs(const Card *originalCard) const{
        Card *slash = new Slash(originalCard->getSuit(), originalCard->getNumber());
        slash->addSubcard(originalCard->getId());
        slash->setSkillName(objectName());
        return slash;
    }
};

class Paoxiao: public TargetModSkill {
public:
    Paoxiao(): TargetModSkill("paoxiao") {
    }

    virtual int getResidueNum(const Player *from, const Card *) const{
        if (from->hasSkill(objectName()))
            return 1000;
        else
            return 0;
    }
};

class Longdan: public OneCardViewAsSkill {
public:
    Longdan(): OneCardViewAsSkill("longdan") {
    }

    virtual bool viewFilter(const Card *to_select) const{
        const Card *card = to_select;

        switch (Sanguosha->currentRoomState()->getCurrentCardUseReason()) {
        case CardUseStruct::CARD_USE_REASON_PLAY: {
                return card->isKindOf("Jink");
            }
        case CardUseStruct::CARD_USE_REASON_RESPONSE: {
                QString pattern = Sanguosha->currentRoomState()->getCurrentCardUsePattern();
                if (pattern == "slash")
                    return card->isKindOf("Jink");
                else if (pattern == "jink")
                    return card->isKindOf("Slash");
            }
        default:
            return false;
        }
    }

    virtual bool isEnabledAtPlay(const Player *player) const{
        return Slash::IsAvailable(player);
    }

    virtual bool isEnabledAtResponse(const Player *player, const QString &pattern) const{
        return pattern == "jink" || pattern == "slash";
    }

    virtual const Card *viewAs(const Card *originalCard) const{
        if (originalCard->isKindOf("Slash")) {
            Jink *jink = new Jink(originalCard->getSuit(), originalCard->getNumber());
            jink->addSubcard(originalCard);
            jink->setSkillName(objectName());
            return jink;
        } else if(originalCard->isKindOf("Jink")) {
            Slash *slash = new Slash(originalCard->getSuit(), originalCard->getNumber());
            slash->addSubcard(originalCard);
            slash->setSkillName(objectName());
            return slash;
        } else
            return NULL;
    }
};

class Tieji: public TriggerSkill {
public:
    Tieji(): TriggerSkill("tieji") {
        events << TargetConfirmed << CardFinished;
    }

    virtual bool triggerable(const ServerPlayer *target) const{
        return target && target->hasSkill(objectName());
    }

    virtual bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const{
        if (event == TargetConfirmed) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (!player->isAlive() || player != use.from || !use.card->isKindOf("Slash"))
                return false;
            int count = 1;
            int mark_n = player->getMark("no_jink" + use.card->toString());
            foreach (ServerPlayer *p, use.to) {
                if (player->askForSkillInvoke("tieji", QVariant::fromValue(p))) {
                    room->broadcastSkillInvoke(objectName());

                    JudgeStruct judge;
                    judge.pattern = QRegExp("(.*):(heart|diamond):(.*)");
                    judge.good = true;
                    judge.reason = objectName();
                    judge.who = player;

                    room->judge(judge);
                    if (judge.isGood()) {
                        LogMessage log;
                        log.type = "#NoJink";
                        log.from = p;
                        room->sendLog(log);

                        mark_n += count;
                        room->setPlayerMark(player, "no_jink" + use.card->toString(), mark_n);
                    }
                }
                count *= 10;
            }
        } else if (event == CardFinished) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card->isKindOf("Slash"))
                room->setPlayerMark(player, "no_jink" + use.card->toString(), 0);
        }

        return false;
    }
};

class Guanxing: public PhaseChangeSkill {
public:
    Guanxing(): PhaseChangeSkill("guanxing") {
        frequency = Frequent;
    }

    virtual bool onPhaseChange(ServerPlayer *zhuge) const{
        if (zhuge->getPhase() == Player::Start && zhuge->askForSkillInvoke(objectName())) {
            Room *room = zhuge->getRoom();
            int index = qrand() % 2 + 1;
            if (!zhuge->hasInnateSkill(objectName()) && zhuge->hasSkill("zhiji"))
                index += 2;
            room->broadcastSkillInvoke(objectName(), index);

            int n = qMin(5, room->alivePlayerCount());
            room->askForGuanxing(zhuge, room->getNCards(n, false), false);
        }

        return false;
    }
};

class Kongcheng: public ProhibitSkill {
public:
    Kongcheng(): ProhibitSkill("kongcheng") {
    }

    virtual bool isProhibited(const Player *from, const Player *to, const Card *card) const{
        if (card->isKindOf("Slash") || card->isKindOf("Duel"))
            return to->isKongcheng();
        else
            return false;
    }
};

class KongchengEffect: public TriggerSkill {
public:
    KongchengEffect() :TriggerSkill("#kongcheng-effect") {
        events << CardsMoveOneTime;
    }

    virtual bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const{
        if (player->isKongcheng()) {
            CardsMoveOneTimeStar move = data.value<CardsMoveOneTimeStar>();
            if (move->from == player && move->from_places.contains(Player::PlaceHand))
                room->broadcastSkillInvoke("kongcheng");
        }

        return false;
    }
};

class Jizhi: public TriggerSkill {
public:
    Jizhi(): TriggerSkill("jizhi") {
        frequency = Frequent;
        events << CardUsed << CardResponded;
    }

    virtual bool trigger(TriggerEvent event, Room *room, ServerPlayer *yueying, QVariant &data) const{
        CardStar card = NULL;
        if (event == CardUsed) {
            CardUseStruct use = data.value<CardUseStruct>();
            card = use.card;
        } else if (event == CardResponded)
            card = data.value<CardResponseStruct>().m_card;

        if (card->isNDTrick() && room->askForSkillInvoke(yueying, objectName())) {
            room->broadcastSkillInvoke(objectName());
            yueying->drawCards(1);
        }

        return false;
    }
};

class Qicai: public TargetModSkill {
public:
    Qicai(): TargetModSkill("qicai") {
        pattern = "TrickCard";
    }

    virtual int getDistanceLimit(const Player *from, const Card *) const{
        if (from->hasSkill(objectName()))
            return 1000;
        else
            return 0;
    }
};

class Zhiheng: public ViewAsSkill {
public:
    Zhiheng(): ViewAsSkill("zhiheng") {
    }

    virtual bool viewFilter(const QList<const Card *> &, const Card *) const{
        return true;
    }

    virtual const Card *viewAs(const QList<const Card *> &cards) const{
        if(cards.isEmpty())
            return NULL;

        ZhihengCard *zhiheng_card = new ZhihengCard;
        zhiheng_card->addSubcards(cards);
        zhiheng_card->setSkillName(objectName());
        return zhiheng_card;
    }

    virtual bool isEnabledAtPlay(const Player *player) const{
        return !player->hasUsed("ZhihengCard");
    }
};

class Jiuyuan: public TriggerSkill {
public:
    Jiuyuan(): TriggerSkill("jiuyuan$") {
        events << TargetConfirmed << PreHpRecover;
        frequency = Compulsory;
    }

    virtual bool triggerable(const ServerPlayer *target) const{
        return target != NULL && target->hasLordSkill("jiuyuan");
    }

    virtual bool trigger(TriggerEvent event, Room *room, ServerPlayer *sunquan, QVariant &data) const{
        if (event == TargetConfirmed) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card->isKindOf("Peach") && use.from && use.from->getKingdom() == "wu"
                && sunquan != use.from && sunquan->hasFlag("dying")) {
                room->setCardFlag(use.card, "jiuyuan");
            }
        } else if (event == PreHpRecover) {
            RecoverStruct rec = data.value<RecoverStruct>();
            if (rec.card && rec.card->hasFlag("jiuyuan")) {
                room->broadcastSkillInvoke("jiuyuan", rec.who->isMale() ? 1 : 2);

                LogMessage log;
                log.type = "#JiuyuanExtraRecover";
                log.from = sunquan;
                log.to << rec.who;
                log.arg = objectName();
                room->sendLog(log);

                rec.recover++;
                data = QVariant::fromValue(rec);
            }
        }

        return false;
    }
};

class Yingzi: public DrawCardsSkill {
public:
    Yingzi(): DrawCardsSkill("yingzi") {
        frequency = Frequent;
    }

    virtual int getDrawNum(ServerPlayer *zhouyu, int n) const{
        Room *room = zhouyu->getRoom();
        if (room->askForSkillInvoke(zhouyu, objectName())) {
            int index = qrand() % 2 + 1;
            if (!zhouyu->hasInnateSkill(objectName())) {
                if (zhouyu->hasSkill("hunzi"))
                    index += 2;
                else if (zhouyu->hasSkill("mouduan"))
                    index += 4;
            }

            room->broadcastSkillInvoke(objectName(), index);
            return n + 1;
        } else
            return n;
    }
};

class Fanjian: public ZeroCardViewAsSkill {
public:
    Fanjian(): ZeroCardViewAsSkill("fanjian") {
    }

    virtual bool isEnabledAtPlay(const Player *player) const{
        return !player->isKongcheng() && !player->hasUsed("FanjianCard");
    }

    virtual const Card *viewAs() const{
        return new FanjianCard;
    }
};

class Keji: public TriggerSkill {
public:
    Keji(): TriggerSkill("keji") {
        events << EventPhaseChanging << CardResponded;
        frequency = Frequent;
    }

    virtual bool trigger(TriggerEvent event, Room *room, ServerPlayer *lvmeng, QVariant &data) const{
        if (event == CardResponded && lvmeng->getPhase() == Player::Play) {
            CardStar card_star = data.value<CardResponseStruct>().m_card;
            if (card_star->isKindOf("Slash"))
                lvmeng->setFlags("keji_use_slash");
        } else if(event == EventPhaseChanging) {
            PhaseChangeStruct change = data.value<PhaseChangeStruct>();
            if (change.to == Player::Discard) {
                if (!lvmeng->hasFlag("keji_use_slash")
                    && lvmeng->getSlashCount() == 0 && lvmeng->askForSkillInvoke(objectName())) {
                    if (lvmeng->getHandcardNum() > lvmeng->getMaxCards()) {
                        int index = qrand() % 2 + 1;
                        if (!lvmeng->hasInnateSkill(objectName()) && lvmeng->hasSkill("mouduan"))
                            index += 2;
                        room->broadcastSkillInvoke(objectName(), index);
                    }
                    lvmeng->skip(Player::Discard);
                }
            }
        }

        return false;
    }
};

class Lianying: public TriggerSkill {
public:
    Lianying(): TriggerSkill("lianying") {
        events << CardsMoveOneTime;
        frequency = Frequent;
    }

    virtual bool trigger(TriggerEvent, Room *room, ServerPlayer *luxun, QVariant &data) const{
        CardsMoveOneTimeStar move = data.value<CardsMoveOneTimeStar>();
        if (move->from == luxun && move->from_places.contains(Player::PlaceHand) && luxun->isKongcheng()) {
            if (room->askForSkillInvoke(luxun, objectName(), data)) {
                room->broadcastSkillInvoke(objectName());
                luxun->drawCards(1);
            }
        }

        return false;
    }
};

class Qixi: public OneCardViewAsSkill {
public:
    Qixi(): OneCardViewAsSkill("qixi") {
    }

    virtual bool viewFilter(const Card *to_select) const{
        return to_select->isBlack();
    }

    virtual const Card *viewAs(const Card *originalCard) const{
        Dismantlement *dismantlement = new Dismantlement(originalCard->getSuit(), originalCard->getNumber());
        dismantlement->addSubcard(originalCard->getId());
        dismantlement->setSkillName(objectName());
        return dismantlement;
    }
};

class Kurou: public ZeroCardViewAsSkill {
public:
    Kurou(): ZeroCardViewAsSkill("kurou") {
    }

    virtual const Card *viewAs() const{
        return new KurouCard;
    }
};

class Guose: public OneCardViewAsSkill {
public:
    Guose(): OneCardViewAsSkill("guose") {
    }

    virtual bool viewFilter(const Card *to_select) const{
        return to_select->getSuit() == Card::Diamond;
    }

    virtual const Card *viewAs(const Card *originalCard) const{
        Indulgence *indulgence = new Indulgence(originalCard->getSuit(), originalCard->getNumber());
        indulgence->addSubcard(originalCard->getId());
        indulgence->setSkillName(objectName());
        return indulgence;
    }
};

class LiuliViewAsSkill: public OneCardViewAsSkill {
public:
    LiuliViewAsSkill(): OneCardViewAsSkill("liuli") {
    }

    virtual bool isEnabledAtPlay(const Player *) const{
        return false;
    }

    virtual bool isEnabledAtResponse(const Player *, const QString &pattern) const{
        return pattern == "@@liuli";
    }

    virtual bool viewFilter(const Card *) const{
        return true;
    }

    virtual const Card *viewAs(const Card *originalCard) const{
        LiuliCard *liuli_card = new LiuliCard;
        liuli_card->addSubcard(originalCard);
        return liuli_card;
    }
};

class Liuli: public TriggerSkill {
public:
    Liuli(): TriggerSkill("liuli") {
        events << TargetConfirming;
        view_as_skill = new LiuliViewAsSkill;
    }

    virtual bool trigger(TriggerEvent, Room *room, ServerPlayer *daqiao, QVariant &data) const{
        CardUseStruct use = data.value<CardUseStruct>();

        if (use.card && use.card->isKindOf("Slash")
            && use.to.contains(daqiao) && !daqiao->isNude() && room->alivePlayerCount() > 2) {
            QList<ServerPlayer *> players = room->getOtherPlayers(daqiao);
            players.removeOne(use.from);

            bool can_invoke = false;
            foreach (ServerPlayer *p, players) {
                if (use.from->canSlash(p, use.card)) {
                    can_invoke = true;
                    break;
                }
            }

            if (can_invoke) {
                QString prompt = "@liuli:" + use.from->objectName();
                room->setPlayerFlag(use.from, "slash_source");
                daqiao->tag["liuli-card"] = QVariant::fromValue((CardStar)use.card);
                if (room->askForUseCard(daqiao, "@@liuli", prompt, -1, Card::MethodDiscard)) {
                    daqiao->tag.remove("liuli-card");
                    room->setPlayerFlag(use.from, "-slash_source");
                    foreach (ServerPlayer *p, players) {
                        if (p->hasFlag("liuli_target")) {
                            use.to.insert(use.to.indexOf(daqiao), p);
                            use.to.removeOne(daqiao);

                            data = QVariant::fromValue(use);

                            room->setPlayerFlag(p, "-liuli_target");
                            return true;
                        }
                    }
                }
                daqiao->tag.remove("liuli-card");
            }
        }

        return false;
    }
};

class CVDaqiao: public GameStartSkill {
public:
    CVDaqiao(): GameStartSkill("cv_daqiao") {
        default_choice = "wz_daqiao";
        sp_convert_skill = true;
    }

    virtual bool triggerable(const ServerPlayer *target) const{
        if (Sanguosha->getBanPackages().contains("sp")) return false;
        bool canInvoke = ServerInfo.GameMode.endsWith("p") || ServerInfo.GameMode.endsWith("pd")
                         || ServerInfo.GameMode.endsWith("pz");
        return GameStartSkill::triggerable(target) && target->getGeneralName() == "daqiao" && canInvoke;
    }

    virtual void onGameStart(ServerPlayer *player) const{
        if (player->getGeneral()->hasSkill(objectName()) && player->askForSkillInvoke(objectName(), "convert")) {
            Room *room = player->getRoom();
            QString choice = room->askForChoice(player, objectName(), "wz_daqiao+tw_daqiao");

            LogMessage log;
            log.type = "#Transfigure";
            log.from = player;
            log.arg = choice;
            room->sendLog(log);
            room->setPlayerProperty(player, "general", choice);
        }
    }
};

class Jieyin: public ViewAsSkill {
public:
    Jieyin(): ViewAsSkill("jieyin") {
    }

    virtual bool isEnabledAtPlay(const Player *player) const{
        return !player->hasUsed("JieyinCard");
    }

    virtual bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const{
        if (selected.length() > 1)
            return false;

        return !to_select->isEquipped();
    }

    virtual const Card *viewAs(const QList<const Card *> &cards) const{
        if (cards.length() != 2)
            return NULL;

        JieyinCard *jieyin_card = new JieyinCard();
        jieyin_card->addSubcards(cards);
        return jieyin_card;
    }
};

class Xiaoji: public TriggerSkill {
public:
    Xiaoji(): TriggerSkill("xiaoji") {
        events << CardsMoveOneTime;
        frequency = Frequent;
    }

    virtual bool trigger(TriggerEvent, Room *room, ServerPlayer *sunshangxiang, QVariant &data) const{
        CardsMoveOneTimeStar move = data.value<CardsMoveOneTimeStar>();
        if (move->from == sunshangxiang && move->from_places.contains(Player::PlaceEquip)) {
            for (int i = 0; i < move->card_ids.size(); i++)
                if (move->from_places[i] == Player::PlaceEquip
                    && room->askForSkillInvoke(sunshangxiang, objectName())) {
                    room->broadcastSkillInvoke(objectName());
                    sunshangxiang->drawCards(2);
                }
        }

        return false;
    }
};

class Wushuang: public TriggerSkill {
public:
    Wushuang(): TriggerSkill("wushuang") {
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
                    room->setPlayerMark(player, "double_jink" + use.card->toString(), mark_n);
                    count *= 10;
                }
            }
            if (use.card->isKindOf("Duel")) {
                if (TriggerSkill::triggerable(use.from) && use.from == player)
                    can_invoke = true;
                if (TriggerSkill::triggerable(player) && use.to.contains(player))
                    can_invoke = true;
            }
            if (!can_invoke) return false;

            LogMessage log;
            log.from = player;
            log.arg = objectName();
            log.type = "#TriggerSkill";
            room->sendLog(log);

            room->broadcastSkillInvoke(objectName());
            if (use.card->isKindOf("Duel"))
                room->setPlayerMark(player, "WushuangTarget", 1);
        } else if (event == CardFinished) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card->isKindOf("Slash")) {
                if (player->hasSkill(objectName()))
                    room->setPlayerMark(player, "double_jink" + use.card->toString(), 0);
            } else if (use.card->isKindOf("Duel")) {
                foreach(ServerPlayer *lvbu, room->getAllPlayers())
                    if (lvbu->getMark("WushuangTarget") > 0)
                        room->setPlayerMark(lvbu, "WushuangTarget", 0);
            }
        }

        return false;
    }
};

class Lijian: public OneCardViewAsSkill {
public:
    Lijian(): OneCardViewAsSkill("lijian") {
    }

    virtual bool isEnabledAtPlay(const Player *player) const{
        return !player->hasUsed("LijianCard");
    }

    virtual bool viewFilter(const Card *) const{
        return true;
    }

    virtual const Card *viewAs(const Card *originalCard) const{
        LijianCard *lijian_card = new LijianCard;
        lijian_card->addSubcard(originalCard->getId());
        return lijian_card;
    }

    virtual int getEffectIndex(const ServerPlayer *, const Card *) const{
        return 0;
    }
};

class Biyue: public PhaseChangeSkill {
public:
    Biyue(): PhaseChangeSkill("biyue") {
        frequency = Frequent;
    }

    virtual bool onPhaseChange(ServerPlayer *diaochan) const{
        if (diaochan->getPhase() == Player::Finish) {
            Room *room = diaochan->getRoom();
            if (room->askForSkillInvoke(diaochan, objectName())) {
                room->broadcastSkillInvoke(objectName());
                diaochan->drawCards(1);
            }
        }

        return false;
    }
};

class CVDiaochan: public GameStartSkill {
public:
    CVDiaochan(): GameStartSkill("cv_diaochan") {
        default_choice = "sp_diaochan";
        sp_convert_skill = true;
    }

    virtual bool triggerable(const ServerPlayer *target) const{
        if (Sanguosha->getBanPackages().contains("sp") && Sanguosha->getBanPackages().contains("hegemony"))
            return false;
        bool canInvoke = ServerInfo.GameMode.endsWith("p") || ServerInfo.GameMode.endsWith("pd")
                         || ServerInfo.GameMode.endsWith("pz");
        return GameStartSkill::triggerable(target) && target->getGeneralName() == "diaochan" && canInvoke;
    }

    virtual void onGameStart(ServerPlayer *player) const{
        if (player->getGeneral()->hasSkill(objectName()) && player->askForSkillInvoke(objectName(), "convert")) {
            Room *room = player->getRoom();
            QStringList choicelist;
            if (!Sanguosha->getBanPackages().contains("sp"))
                choicelist << "sp_diaochan" << "tw_diaochan";
            if (!Sanguosha->getBanPackages().contains("hegemony"))
                choicelist << "heg_diaochan";
            QString choice = room->askForChoice(player, objectName(), choicelist.join("+"));

            LogMessage log;
            log.type = "#Transfigure";
            log.from = player;
            log.arg = choice;
            room->sendLog(log);
            room->setPlayerProperty(player, "general", choice);
        }
    }
};

class CVZhouyu: public GameStartSkill {
public:
    CVZhouyu(): GameStartSkill("cv_zhouyu") {
        default_choice = "heg_zhouyu";
        sp_convert_skill = true;
    }

    virtual bool triggerable(const ServerPlayer *target) const{
        if (Sanguosha->getBanPackages().contains("hegemony") && Sanguosha->getBanPackages().contains("hegemony_sp"))
            return false;
        bool canInvoke = ServerInfo.GameMode.endsWith("p") || ServerInfo.GameMode.endsWith("pd")
                         || ServerInfo.GameMode.endsWith("pz");
        return GameStartSkill::triggerable(target) && target->getGeneralName() == "zhouyu" && canInvoke;
    }

    virtual void onGameStart(ServerPlayer *player) const{
        if (player->getGeneral()->hasSkill(objectName()) && player->askForSkillInvoke(objectName(), "convert")) {
            Room *room = player->getRoom();
            QStringList choicelist;
            if (!Sanguosha->getBanPackages().contains("hegemony"))
                choicelist << "heg_zhouyu";
            if (!Sanguosha->getBanPackages().contains("hegemony_sp"))
                choicelist << "sp_heg_zhouyu";
            QString choice = room->askForChoice(player, objectName(), choicelist.join("+"));

            LogMessage log;
            log.type = "#Transfigure";
            log.from = player;
            log.arg = choice;
            room->sendLog(log);
            room->setPlayerProperty(player, "general", choice);
        }
    }
};

class Qingnang: public OneCardViewAsSkill {
public:
    Qingnang(): OneCardViewAsSkill("qingnang") {
    }

    virtual bool isEnabledAtPlay(const Player *player) const{
        return !player->hasUsed("QingnangCard");
    }

    virtual bool viewFilter(const Card *to_select) const{
        return !to_select->isEquipped();
    }

    virtual const Card *viewAs(const Card *originalCard) const{
        QingnangCard *qingnang_card = new QingnangCard;
        qingnang_card->addSubcard(originalCard->getId());
        return qingnang_card;
    }
};

class Jijiu: public OneCardViewAsSkill {
public:
    Jijiu(): OneCardViewAsSkill("jijiu") {
    }

    virtual bool isEnabledAtPlay(const Player *) const{
        return false;
    }

    virtual bool isEnabledAtResponse(const Player *player, const QString &pattern) const{
        return pattern.contains("peach") && player->getPhase() == Player::NotActive;
    }

    virtual bool viewFilter(const Card *to_select) const{
        return to_select->isRed();
    }

    virtual const Card *viewAs(const Card *originalCard) const{
        Peach *peach = new Peach(originalCard->getSuit(), originalCard->getNumber());
        peach->addSubcard(originalCard->getId());
        peach->setSkillName(objectName());
        return peach;
    }
};

class Qianxun: public ProhibitSkill {
public:
    Qianxun(): ProhibitSkill("qianxun") {
    }

    virtual bool isProhibited(const Player *, const Player *, const Card *card) const{
        return card->isKindOf("Snatch") || card->isKindOf("Indulgence");
    }
};

class Mashu: public DistanceSkill {
public:
    Mashu(): DistanceSkill("mashu") {
    }

    virtual int getCorrect(const Player *from, const Player *) const{
        if(from->hasSkill(objectName()))
            return -1;
        else
            return 0;
    }
};

void StandardPackage::addGenerals() {
    // Wei
    General *caocao = new General(this, "caocao$", "wei");
    caocao->addSkill(new Jianxiong);
    caocao->addSkill(new Hujia);

    General *simayi = new General(this, "simayi", "wei", 3);
    simayi->addSkill(new Fankui);
    simayi->addSkill(new Guicai);

    General *xiahoudun = new General(this, "xiahoudun", "wei");
    xiahoudun->addSkill(new Ganglie);

    General *zhangliao = new General(this, "zhangliao", "wei");
    zhangliao->addSkill(new Tuxi);

    General *xuchu = new General(this, "xuchu", "wei");
    xuchu->addSkill(new Luoyi);
    xuchu->addSkill(new LuoyiBuff);
    related_skills.insertMulti("luoyi", "#luoyi");

    General *guojia = new General(this, "guojia", "wei", 3);
    guojia->addSkill(new Tiandu);
    guojia->addSkill(new Yiji);
    guojia->addSkill(new YijiAvoidTriggeringCardsMove);
    related_skills.insertMulti("yiji", "#yiji-avoid-triggering-cards-move");

    General *zhenji = new General(this, "zhenji", "wei", 3, false);
    zhenji->addSkill(new Luoshen);
    zhenji->addSkill(new Qingguo);
    zhenji->addSkill(new SPConvertSkill("cv_zhenji", "zhenji", "heg_zhenji"));

    // Shu
    General *liubei = new General(this, "liubei$", "shu");
    liubei->addSkill(new Rende);
    liubei->addSkill(new Jijiang);

    General *guanyu = new General(this, "guanyu", "shu");
    guanyu->addSkill(new Wusheng);

    General *zhangfei = new General(this, "zhangfei", "shu");
    zhangfei->addSkill(new Paoxiao);

    General *zhugeliang = new General(this, "zhugeliang", "shu", 3);
    zhugeliang->addSkill(new Guanxing);
    zhugeliang->addSkill(new Kongcheng);
    zhugeliang->addSkill(new KongchengEffect);
    related_skills.insertMulti("kongcheng", "#kongcheng-effect");
    zhugeliang->addSkill(new SPConvertSkill("cv_zhugeliang", "zhugeliang", "heg_zhugeliang"));

    General *zhaoyun = new General(this, "zhaoyun", "shu");
    zhaoyun->addSkill(new Longdan);
    zhaoyun->addSkill(new SPConvertSkill("cv_zhaoyun", "zhaoyun", "tw_zhaoyun"));

    General *machao = new General(this, "machao", "shu");
    machao->addSkill(new Tieji);
    machao->addSkill(new Mashu);
    machao->addSkill(new SPConvertSkill("cv_machao", "machao", "sp_machao"));

    General *huangyueying = new General(this, "huangyueying", "shu", 3, false);
    huangyueying->addSkill(new Jizhi);
    huangyueying->addSkill(new Qicai);
    huangyueying->addSkill(new SPConvertSkill("cv_huangyueying", "huangyueying", "heg_huangyueying"));

    // Wu
    General *sunquan = new General(this, "sunquan$", "wu");
    sunquan->addSkill(new Zhiheng);
    sunquan->addSkill(new Jiuyuan);

    General *ganning = new General(this, "ganning", "wu");
    ganning->addSkill(new Qixi);

    General *lvmeng = new General(this, "lvmeng", "wu");
    lvmeng->addSkill(new Keji);

    General *huanggai = new General(this, "huanggai", "wu");
    huanggai->addSkill(new Kurou);

    General *zhouyu = new General(this, "zhouyu", "wu", 3);
    zhouyu->addSkill(new Yingzi);
    zhouyu->addSkill(new Fanjian);
    zhouyu->addSkill(new CVZhouyu);

    General *daqiao = new General(this, "daqiao", "wu", 3, false);
    daqiao->addSkill(new Guose);
    daqiao->addSkill(new Liuli);
    daqiao->addSkill(new CVDaqiao);

    General *luxun = new General(this, "luxun", "wu", 3);
    luxun->addSkill(new Qianxun);
    luxun->addSkill(new Lianying);

    General *sunshangxiang = new General(this, "sunshangxiang", "wu", 3, false);
    sunshangxiang->addSkill(new Jieyin);
    sunshangxiang->addSkill(new Xiaoji);
    sunshangxiang->addSkill(new SPConvertSkill("cv_sunshangxiang", "sunshangxiang", "sp_sunshangxiang"));

    // Qun
    General *huatuo = new General(this, "huatuo", "qun", 3);
    huatuo->addSkill(new Qingnang);
    huatuo->addSkill(new Jijiu);

    General *lvbu = new General(this, "lvbu", "qun");
    lvbu->addSkill(new Wushuang);
    lvbu->addSkill(new SPConvertSkill("cv_lvbu", "lvbu", "heg_lvbu"));

    General *diaochan = new General(this, "diaochan", "qun", 3, false);
    diaochan->addSkill(new Lijian);
    diaochan->addSkill(new Biyue);
    diaochan->addSkill(new CVDiaochan);

    // for skill cards
    addMetaObject<ZhihengCard>();
    addMetaObject<RendeCard>();
    addMetaObject<TuxiCard>();
    addMetaObject<JieyinCard>();
    addMetaObject<KurouCard>();
    addMetaObject<LijianCard>();
    addMetaObject<FanjianCard>();
    addMetaObject<GuicaiCard>();
    addMetaObject<QingnangCard>();
    addMetaObject<LiuliCard>();
    addMetaObject<JijiangCard>();
}

class SuperZhiheng: public Zhiheng {
public:
    SuperZhiheng():Zhiheng() {
        setObjectName("super_zhiheng");
    }

    virtual bool isEnabledAtPlay(const Player *player) const{
        return player->usedTimes("ZhihengCard") < (player->getLostHp() + 1);
    }
};

class SuperGuanxing: public Guanxing {
public:
    SuperGuanxing(): Guanxing() {
        setObjectName("super_guanxing");
    }

    virtual bool onPhaseChange(ServerPlayer *zhuge) const{
        if (zhuge->getPhase() == Player::Start
            && zhuge->askForSkillInvoke(objectName())) {
            Room *room = zhuge->getRoom();
            room->broadcastSkillInvoke("guanxing", qrand() % 2 + 1);
            room->askForGuanxing(zhuge, room->getNCards(5, false), false);
        }

        return false;
    }
};

class SuperMaxCards: public MaxCardsSkill {
public:
    SuperMaxCards(): MaxCardsSkill("super_max_cards") {
    }

    virtual int getExtra(const Player *target) const{
        if (target->hasSkill(objectName()))
            return target->getMark("@max_cards_test");
        return 0;
    }
};

class SuperOffensiveDistance: public DistanceSkill {
public:
    SuperOffensiveDistance(): DistanceSkill("super_offensive_distance") {
    }

    virtual int getCorrect(const Player *from, const Player *) const{
        if (from->hasSkill(objectName()))
            return -from->getMark("@offensive_distance_test");
        else
            return 0;
    }
};

class SuperDefensiveDistance: public DistanceSkill {
public:
    SuperDefensiveDistance(): DistanceSkill("super_defensive_distance") {
    }

    virtual int getCorrect(const Player *, const Player *to) const{
        if (to->hasSkill(objectName()))
            return to->getMark("@defensive_distance_test");
        else
            return 0;
    }
};

#include "sp.h"
class SuperYongsi: public Yongsi {
public:
    SuperYongsi(): Yongsi() {
        setObjectName("super_yongsi");
    }

    virtual int getKingdoms(ServerPlayer *yuanshu) const{
        return yuanshu->getMark("@yongsi_test");
    }
};

#include "wind.h"
class SuperJushou: public Jushou {
public:
    SuperJushou(): Jushou() {
        setObjectName("super_jushou");
    }

    virtual int getJushouDrawNum(ServerPlayer *caoren) const{
        return caoren->getMark("@jushou_test");
    }
};

#include "god.h"
#include "maneuvering.h"
class NosJuejing: public TriggerSkill {
public:
    NosJuejing(): TriggerSkill("nosjuejing") {
        events << CardsMoveOneTime << EventPhaseChanging;
        frequency = Compulsory;
    }

    virtual bool trigger(TriggerEvent event, Room *room, ServerPlayer *gaodayihao, QVariant &data) const{
        if (event == CardsMoveOneTime){
            CardsMoveOneTimeStar move = data.value<CardsMoveOneTimeStar>();
            if (move->from != gaodayihao && move->to != gaodayihao)
                return false;
            if ((move->to_place != Player::PlaceHand && !move->from_places.contains(Player::PlaceHand))
                || gaodayihao->getPhase() == Player::Discard) {
                return false;
            }
        }
        if (event == EventPhaseChanging) {
            PhaseChangeStruct change = data.value<PhaseChangeStruct>();
            if (change.to == Player::Draw) {
                gaodayihao->skip(change.to);
                return false;
            } else if (change.to != Player::Finish)
                return false;
        }
        if (gaodayihao->getHandcardNum() == 4)
            return false;
        int diff = abs(gaodayihao->getHandcardNum() - 4);
        if (gaodayihao->getHandcardNum() < 4) {
            LogMessage log;
            log.type = "#TriggerSkill";
            log.from = gaodayihao;
            log.arg = objectName();
            room->sendLog(log);
            gaodayihao->drawCards(diff);
        } else if (gaodayihao->getHandcardNum() > 4){
            LogMessage log;
            log.type = "#TriggerSkill";
            log.from = gaodayihao;
            log.arg = objectName();
            room->sendLog(log);
            room->askForDiscard(gaodayihao, objectName(), diff, diff);
        }

        return false;
    }
};

class NosLonghun: public Longhun {
public:
    NosLonghun(): Longhun() {
        setObjectName("noslonghun");
    }

    virtual int getEffHp(const Player *) const{
        return 1;
    }
};

class NosDuojian: public TriggerSkill {
public:
    NosDuojian(): TriggerSkill("#noslonghun_duojian") {
        events << EventPhaseStart;
    }

    virtual bool trigger(TriggerEvent, Room *room, ServerPlayer *gaodayihao, QVariant &) const{
        if (gaodayihao->getPhase() == Player::Start) {
            foreach (ServerPlayer *p, room->getOtherPlayers(gaodayihao)) {
               if (p->getWeapon() && p->getWeapon()->isKindOf("QinggangSword")) {
                   if (room->askForSkillInvoke(gaodayihao, objectName())) {
                        room->broadcastSkillInvoke("noslonghun", 5);
                        gaodayihao->obtainCard(p->getWeapon());
                    }
                    break;
                }
            }
        }

        return false;
    }
};

TestPackage::TestPackage()
    : Package("test")
{
    // for test only
    General *zhiba_sunquan = new General(this, "zhiba_sunquan$", "wu", 4, true, true);
    zhiba_sunquan->addSkill(new SuperZhiheng);
    zhiba_sunquan->addSkill("jiuyuan");

    General *wuxing_zhuge = new General(this, "wuxing_zhugeliang", "shu", 3, true, true);
    wuxing_zhuge->addSkill(new SuperGuanxing);
    wuxing_zhuge->addSkill("kongcheng");
    wuxing_zhuge->addSkill("#kongcheng-effect");

    General *super_yuanshu = new General(this, "super_yuanshu", "qun", 4, true, true);
    super_yuanshu->addSkill(new SuperYongsi);
    super_yuanshu->addSkill(new MarkAssignSkill("@yongsi_test", 4));
    related_skills.insertMulti("super_yongsi", "#@yongsi_test-4");
    super_yuanshu->addSkill("weidi");

    General *super_caoren = new General(this, "super_caoren", "wei", 4, true, true);
    super_caoren->addSkill(new SuperJushou);
    super_caoren->addSkill(new MarkAssignSkill("@jushou_test", 5));
    related_skills.insertMulti("super_jushou", "#@jushou_test-5");
    
    General *gd_shenzhaoyun = new General(this, "gaodayihao", "god", 1, true, true);
    gd_shenzhaoyun->addSkill(new NosJuejing);
    gd_shenzhaoyun->addSkill(new NosLonghun);
    gd_shenzhaoyun->addSkill(new NosDuojian);
    related_skills.insertMulti("noslonghun", "#noslonghun_duojian");

    General *nobenghuai_dongzhuo = new General(this, "nobenghuai_dongzhuo$", "qun", 4, true, true);
    nobenghuai_dongzhuo->addSkill("jiuchi");
    nobenghuai_dongzhuo->addSkill("roulin");
    nobenghuai_dongzhuo->addSkill("baonue");

    new General(this, "sujiang", "god", 5, true, true);
    new General(this, "sujiangf", "god", 5, false, true);

    new General(this, "anjiang", "god", 4,true, true, true);

    skills << new SuperMaxCards << new SuperOffensiveDistance << new SuperDefensiveDistance;
}

ADD_PACKAGE(Test)
// FORMATTED
