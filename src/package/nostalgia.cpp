#include "standard.h"
#include "skill.h"
#include "wind.h"
#include "client.h"
#include "engine.h"
#include "nostalgia.h"
#include "yjcm.h"
#include "settings.h"

class MoonSpearSkill: public WeaponSkill {
public:
    MoonSpearSkill(): WeaponSkill("moon_spear") {
        events << CardFinished << CardResponded;
    }

    virtual bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const{
        if (player->getPhase() != Player::NotActive)
            return false;

        CardStar card = NULL;
        if (event == CardFinished) {
            CardUseStruct card_use = data.value<CardUseStruct>();
            card = card_use.card;

            if (card == player->tag["MoonSpearSlash"].value<CardStar>())
                card = NULL;
        } else if (event == CardResponded) {
            card = data.value<CardResponseStruct>().m_card;
            player->tag["MoonSpearSlash"] = data;
        }

        if (card == NULL || !card->isBlack())
            return false;

        if (room->askForUseCard(player, "slash", "@moon-spear-slash"))
            room->setEmotion(player, "weapon/moonspear");

        return false;
    }
};

MoonSpear::MoonSpear(Suit suit, int number)
    : Weapon(suit, number, 3)
{
    setObjectName("moon_spear");
}

NostalgiaPackage::NostalgiaPackage()
    : Package("nostalgia")
{
    type = CardPack;

    Card *moon_spear = new MoonSpear;
    moon_spear->setParent(this);

    skills << new MoonSpearSkill;
}

// old yjcm's generals

class NosWuyan: public TriggerSkill {
public:
    NosWuyan(): TriggerSkill("noswuyan") {
        events << CardEffected;
        frequency = Compulsory;
    }

    virtual bool triggerable(const ServerPlayer *target) const{
        return target != NULL;
    }

    virtual bool trigger(TriggerEvent, Room *room, ServerPlayer *, QVariant &data) const{
        CardEffectStruct effect = data.value<CardEffectStruct>();
        if (effect.to == effect.from)
            return false;
        if (effect.card->isNDTrick()) {
            if (effect.from && effect.from->hasSkill(objectName())) {
                LogMessage log;
                log.type = "#WuyanBaD";
                log.from = effect.from;
                log.to << effect.to;
                log.arg = effect.card->objectName();
                log.arg2 = objectName();
                room->sendLog(log);
                room->notifySkillInvoked(effect.from, objectName());
                room->broadcastSkillInvoke("wuyan");
                return true;
            }
            if (effect.to->hasSkill(objectName()) && effect.from) {
                LogMessage log;
                log.type = "#WuyanGooD";
                log.from = effect.to;
                log.to << effect.from;
                log.arg = effect.card->objectName();
                log.arg2 = objectName();
                room->sendLog(log);
                room->notifySkillInvoked(effect.to, objectName());
                room->broadcastSkillInvoke("wuyan");
                return true;
            }
        }
        return false;
    }
};

NosJujianCard::NosJujianCard() {
    mute = true;
}

void NosJujianCard::onEffect(const CardEffectStruct &effect) const{
    int n = subcardsLength();
    effect.to->drawCards(n);
    Room *room = effect.from->getRoom();
    room->broadcastSkillInvoke("jujian");

    if (n == 3) {
        QSet<Card::CardType> types;
        foreach (int card_id, effect.card->getSubcards())
            types << Sanguosha->getCard(card_id)->getTypeId();

        if (types.size() == 1) {
            LogMessage log;
            log.type = "#JujianRecover";
            log.from = effect.from;
            const Card *card = Sanguosha->getCard(subcards.first());
            log.arg = card->getType();
            room->sendLog(log);

            RecoverStruct recover;
            recover.card = this;
            recover.who = effect.from;
            room->recover(effect.from, recover);
        }
    }
}

class NosJujian: public ViewAsSkill {
public:
    NosJujian(): ViewAsSkill("nosjujian") {
    }

    virtual bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const{
        return selected.length() < 3 && !Self->isJilei(to_select);
    }

    virtual bool isEnabledAtPlay(const Player *player) const{
        return !player->isNude() && !player->hasUsed("NosJujianCard");
    }

    virtual const Card *viewAs(const QList<const Card *> &cards) const{
        if (cards.isEmpty())
            return NULL;

        NosJujianCard *card = new NosJujianCard;
        card->addSubcards(cards);
        return card;
    }
};

class NosEnyuan: public TriggerSkill {
public:
    NosEnyuan(): TriggerSkill("nosenyuan") {
        events << HpRecover << Damaged;
        frequency = Compulsory;
    }

    virtual bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const{
        if (event == HpRecover) {
            RecoverStruct recover = data.value<RecoverStruct>();
            if (recover.who && recover.who != player) {
                recover.who->drawCards(recover.recover);

                LogMessage log;
                log.type = "#EnyuanRecover";
                log.from = player;
                log.to << recover.who;
                log.arg = QString::number(recover.recover);
                log.arg2 = objectName();
                room->sendLog(log);
                room->broadcastSkillInvoke("enyuan", qrand() % 2 + 1);
            }
        } else if (event == Damaged) {
            DamageStruct damage = data.value<DamageStruct>();
            ServerPlayer *source = damage.from;
            if (source && source != player) {
                room->broadcastSkillInvoke("enyuan", qrand() % 2 + 3);

                const Card *card = room->askForCard(source, ".|heart|.|hand", "@enyuanheart", data, Card::MethodNone);
                if (card) player->obtainCard(card); else room->loseHp(source);
            }
        }

        return false;
    }
};

NosXuanhuoCard::NosXuanhuoCard() {
    will_throw = false;
    handling_method = Card::MethodNone;
    mute = true;
}

void NosXuanhuoCard::onEffect(const CardEffectStruct &effect) const{
    effect.to->obtainCard(this);

    Room *room = effect.from->getRoom();
    room->broadcastSkillInvoke("xuanhuo");
    int card_id = room->askForCardChosen(effect.from, effect.to, "he", "nosxuanhuo");
    CardMoveReason reason(CardMoveReason::S_REASON_EXTRACTION, effect.from->objectName());
    room->obtainCard(effect.from, Sanguosha->getCard(card_id), reason, room->getCardPlace(card_id) != Player::PlaceHand);

    QList<ServerPlayer *> targets = room->getOtherPlayers(effect.to);
    ServerPlayer *target = room->askForPlayerChosen(effect.from, targets, "nosxuanhuo");
    if (target != effect.from) {
        CardMoveReason reason2(CardMoveReason::S_REASON_GIVE, effect.from->objectName());
        reason2.m_playerId = target->objectName();
        room->obtainCard(target, Sanguosha->getCard(card_id), reason2, false);
    }
}

class NosXuanhuo: public OneCardViewAsSkill {
public:
    NosXuanhuo():OneCardViewAsSkill("nosxuanhuo") {
    }

    virtual bool isEnabledAtPlay(const Player *player) const{
        return !player->isKongcheng() && !player->hasUsed("NosXuanhuoCard");
    }

    virtual bool viewFilter(const Card *to_select) const{
        return !to_select->isEquipped() && to_select->getSuit() == Card::Heart;
    }

    virtual const Card *viewAs(const Card *originalCard) const{
        NosXuanhuoCard *xuanhuoCard = new NosXuanhuoCard;
        xuanhuoCard->addSubcard(originalCard);
        return xuanhuoCard;
    }
};

class NosXuanfeng: public TriggerSkill {
public:
    NosXuanfeng(): TriggerSkill("nosxuanfeng") {
        events << CardsMoveOneTime;
        default_choice = "nothing";
    }

    virtual bool trigger(TriggerEvent event, Room *room, ServerPlayer *lingtong, QVariant &data) const{
        if (event == CardsMoveOneTime) {
            CardsMoveOneTimeStar move = data.value<CardsMoveOneTimeStar>();
            if (move->from == lingtong && move->from_places.contains(Player::PlaceEquip)) {
                QStringList choicelist;
                choicelist << "nothing";
                QList<ServerPlayer *> targets1;
                foreach (ServerPlayer *target, room->getAlivePlayers()) {
                    if (lingtong->canSlash(target, NULL, false))
                        targets1 << target;
                }
                Slash *slashx = new Slash(Card::NoSuit, 0);
                if (!targets1.isEmpty() && !lingtong->isCardLimited(slashx, Card::MethodUse))
                    choicelist << "slash";
                slashx->deleteLater();
                QList<ServerPlayer *> targets2;
                foreach (ServerPlayer *p, room->getOtherPlayers(lingtong)) {
                    if (lingtong->distanceTo(p) <= 1)
                        targets2 << p;
                }
                if (!targets2.isEmpty()) choicelist << "damage";

                QString choice = room->askForChoice(lingtong, objectName(), choicelist.join("+"));
                if (choice == "slash") {
                    ServerPlayer *target = room->askForPlayerChosen(lingtong, targets1, "nosxuanfeng_slash");
                    room->broadcastSkillInvoke("xuanfeng", 1);
                    Slash *slash = new Slash(Card::NoSuit, 0);
                    slash->setSkillName(objectName());

                    CardUseStruct card_use;
                    card_use.card = slash;
                    card_use.from = lingtong;
                    card_use.to << target;
                    room->useCard(card_use, false);
                } else if (choice == "damage") {
                    room->broadcastSkillInvoke("xuanfeng", 2);
                    room->notifySkillInvoked(lingtong, objectName());

                    ServerPlayer *target = room->askForPlayerChosen(lingtong, targets2, "nosxuanfeng_damage");
                    DamageStruct damage;
                    damage.from = lingtong;
                    damage.to = target;
                    damage.reason = "nosxuanfeng";
                    room->damage(damage);
                }
            }
        }

        return false;
    }
};

class NosShangshi: public Shangshi {
public:
    NosShangshi(): Shangshi() {
        setObjectName("nosshangshi");
    }

    virtual int getMaxLostHp(ServerPlayer *zhangchunhua) const{
        return qMin(zhangchunhua->getLostHp(), zhangchunhua->getMaxHp());
    }
};

class NosFuhun: public TriggerSkill {
public:
    NosFuhun(): TriggerSkill("nosfuhun") {
        events << EventPhaseStart << EventPhaseChanging;
    }

    virtual bool trigger(TriggerEvent event, Room *room, ServerPlayer *shuangying, QVariant &data) const{
        if (event == EventPhaseStart && shuangying->getPhase() ==  Player::Draw) {
            if (shuangying->askForSkillInvoke(objectName())) {
                int card1 = room->drawCard();
                int card2 = room->drawCard();
                bool diff = (Sanguosha->getCard(card1)->getColor() != Sanguosha->getCard(card2)->getColor());

                CardsMoveStruct move, move2;
                move.card_ids.append(card1);
                move.card_ids.append(card2);
                move.reason = CardMoveReason(CardMoveReason::S_REASON_TURNOVER, shuangying->objectName(), "fuhun", QString());
                move.to_place = Player::PlaceTable;
                room->moveCardsAtomic(move, true);
                room->getThread()->delay();

                move2 = move;
                move2.to_place = Player::PlaceHand;
                move2.to = shuangying;
                move2.reason.m_reason = CardMoveReason::S_REASON_DRAW;
                room->moveCardsAtomic(move2, true);

                if (diff) {
                    room->acquireSkill(shuangying, "wusheng");
                    room->acquireSkill(shuangying, "paoxiao");

                    room->broadcastSkillInvoke(objectName(), qrand() % 2 + 1);
                    shuangying->setFlags(objectName());
                } else {
                    room->broadcastSkillInvoke(objectName(), 3);
                }

                return true;
            }
        } else if (event == EventPhaseChanging) {
            PhaseChangeStruct change = data.value<PhaseChangeStruct>();
            if (change.to == Player::NotActive && shuangying->hasFlag(objectName())) {
                room->detachSkillFromPlayer(shuangying, "wusheng");
                room->detachSkillFromPlayer(shuangying, "paoxiao");
            }
        }

        return false;
    }
};

class NosGongqi: public OneCardViewAsSkill {
public:
    NosGongqi(): OneCardViewAsSkill("nosgongqi") {
    }

    virtual bool isEnabledAtPlay(const Player *player) const{
        return Slash::IsAvailable(player);
    }

    virtual bool isEnabledAtResponse(const Player *, const QString &pattern) const{
        return pattern == "slash";
    }

    virtual bool viewFilter(const Card *to_select) const{
        if (to_select->getTypeId() != Card::TypeEquip)
            return false;

        if (Self->getWeapon() && to_select->getEffectiveId() == Self->getWeapon()->getId() && to_select->objectName() == "crossbow")
            return Self->canSlashWithoutCrossbow();
        else
            return true;
    }

    const Card *viewAs(const Card *originalCard) const{
        Slash *slash = new Slash(originalCard->getSuit(), originalCard->getNumber());
        slash->addSubcard(originalCard);
        slash->setSkillName(objectName());
        return slash;
    }
};

class NosGongqiTargetMod: public TargetModSkill {
public:
    NosGongqiTargetMod(): TargetModSkill("#nosgongqi-target") {
        frequency = NotFrequent;
    }

    virtual int getDistanceLimit(const Player *, const Card *card) const{
        if (card->getSkillName() == "nosgongqi")
            return 1000;
        else
            return 0;
    }
};

class NosJiefan: public TriggerSkill {
public:
    NosJiefan(): TriggerSkill("nosjiefan") {
        events << AskForPeaches << DamageCaused << CardFinished << PreCardUsed;
    }

    virtual bool trigger(TriggerEvent event, Room *room, ServerPlayer *handang, QVariant &data) const{
        ServerPlayer *current = room->getCurrent();
        if (!current || current->isDead())
            return false;
        if (event == PreCardUsed) {
            if (!handang->hasFlag("nosjiefanUsed"))
                return false;

            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card->isKindOf("Slash")) {
                room->setPlayerFlag(handang, "-nosjiefanUsed");
                room->setCardFlag(use.card, "nosjiefan-slash");
            }
        } else if (event == AskForPeaches && current != handang
                   && room->askForSkillInvoke(handang, objectName(), data)) {
            DyingStruct dying = data.value<DyingStruct>();

            forever {
                if (handang->hasFlag("nosjiefan_failed")) {
                    room->setPlayerFlag(handang, "-nosjiefan_failed");
                    break;
                }

                if (dying.who->getHp() > 0 || handang->isNude()
                    || !current || current->isDead() || !handang->canSlash(current, NULL, false))
                    break;

                room->setPlayerFlag(handang, "nosjiefanUsed");
                room->setTag("NosJiefanTarget", data);
                bool use_slash = room->askForUseSlashTo(handang, current, "jiefan-slash:" + current->objectName(), false);
                if (!use_slash) {
                    room->setPlayerFlag(handang, "-nosjiefanUsed");
                    room->removeTag("NosJiefanTarget");
                    break;
                }
            }
        } else if (event == DamageCaused) {
            DamageStruct damage = data.value<DamageStruct>();
            if (damage.card && damage.card->isKindOf("Slash") && damage.card->hasFlag("nosjiefan-slash")) {
                LogMessage log2;
                log2.type = "#NosJiefanPrevent";
                log2.from = handang;
                log2.to << damage.to;
                room->sendLog(log2);

                DyingStruct dying = room->getTag("NosJiefanTarget").value<DyingStruct>();

                ServerPlayer *target = dying.who;
                if (target && target->getHp() > 0) {
                    LogMessage log;
                    log.type = "#NosJiefanNull1";
                    log.from = dying.who;
                    room->sendLog(log);
                } else if (target && target->isDead()) {
                    LogMessage log;
                    log.type = "#NosJiefanNull2";
                    log.from = dying.who;
                    log.to << handang;
                    room->sendLog(log);
                } else if (current && current->hasSkill("wansha") && current->isAlive() && target != handang) {
                    LogMessage log;
                    log.type = "#NosJiefanNull3";
                    log.from = current;
                    room->sendLog(log);
                } else {
                    Peach *peach = new Peach(damage.card->getSuit(), damage.card->getNumber());
                    peach->setSkillName(objectName());
                    CardUseStruct use;
                    use.card = peach;
                    use.from = handang;
                    use.to << target;

                    room->setCardFlag(damage.card, "nosjiefan_success");
                    if ((target->getGeneralName().contains("sunquan")
                         || target->getGeneralName().contains("sunce")
                         || target->getGeneralName().contains("sunjian"))
                        && target->isLord())
                        room->setPlayerFlag(handang, "NosJiefanToLord");
                    room->useCard(use);
                    room->setPlayerFlag(handang, "-NosJiefanToLord");
                }
                return true;
            }
            return false;
        } else if (event == CardFinished && !room->getTag("NosJiefanTarget").isNull()) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card->hasFlag("nosjiefan-slash")) {
                if (!use.card->hasFlag("nosjiefan_success"))
                    room->setPlayerFlag(handang, "nosjiefan_failed");
                room->removeTag("NosJiefanTarget");
            }
        }

        return false;
    }

    virtual int getEffectIndex(const ServerPlayer *player, const Card *) const {
        if (player->hasFlag("NosJiefanToLord"))
            return 2;
        else
            return 1;
    }
};

class NosQianxi: public TriggerSkill {
public:
    NosQianxi(): TriggerSkill("nosqianxi") {
        events << DamageCaused;
    }

    virtual bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const{
        DamageStruct damage = data.value<DamageStruct>();

        if (player->distanceTo(damage.to) == 1 && damage.card && damage.card->isKindOf("Slash")
            && !damage.chain && !damage.transfer && player->askForSkillInvoke(objectName(), data)) {
            room->broadcastSkillInvoke(objectName(), 1);
            JudgeStruct judge;
            judge.pattern = QRegExp("(.*):(heart):(.*)");
            judge.good = false;
            judge.who = player;
            judge.reason = objectName();

            room->judge(judge);
            if (judge.isGood()) {
                room->broadcastSkillInvoke(objectName(), 2);
                room->loseMaxHp(damage.to);
                return true;
            } else
                room->broadcastSkillInvoke(objectName(), 3);
        }
        return false;
    }
};

class NosZhenlie: public TriggerSkill {
public:
    NosZhenlie(): TriggerSkill("noszhenlie") {
        events << AskForRetrial;
    }

    virtual bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const{
        JudgeStar judge = data.value<JudgeStar>();
        if (judge->who != player)
            return false;

        if (player->askForSkillInvoke(objectName(), data)) {
            int card_id = room->drawCard();
            room->broadcastSkillInvoke(objectName(), room->getCurrent() == player ? 2 : 1);
            room->getThread()->delay();
            const Card *card = Sanguosha->getCard(card_id);

            room->retrial(card, player, judge, objectName());
        }
        return false;
    }
};

class NosMiji: public PhaseChangeSkill {
public:
    NosMiji(): PhaseChangeSkill("nosmiji") {
        frequency = Frequent;
    }

    virtual bool onPhaseChange(ServerPlayer *wangyi) const{
        if (!wangyi->isWounded())
            return false;
        if (wangyi->getPhase() == Player::Start || wangyi->getPhase() == Player::Finish) {
            if (!wangyi->askForSkillInvoke(objectName()))
                return false;
            Room *room = wangyi->getRoom();
            room->broadcastSkillInvoke(objectName(), 1);
            JudgeStruct judge;
            judge.pattern = QRegExp("(.*):(club|spade):(.*)");
            judge.good = true;
            judge.reason = objectName();
            judge.who = wangyi;

            room->judge(judge);

            if (judge.isGood() && wangyi->isAlive()) {
                room->setPlayerFlag(wangyi, "nosmiji_InTempMoving");
                int x = wangyi->getLostHp();
                wangyi->drawCards(x); //It should be preview, not draw
                ServerPlayer *target = room->askForPlayerChosen(wangyi, room->getAllPlayers(), objectName());

                if (target == wangyi)
                    room->broadcastSkillInvoke(objectName(), 2);
                else if (target->getGeneralName().contains("machao"))
                    room->broadcastSkillInvoke(objectName(), 4);
                else
                    room->broadcastSkillInvoke(objectName(), 3);

                QList<const Card *> miji_cards = wangyi->getHandcards().mid(wangyi->getHandcardNum() - x);
                QList<int> ids;
                foreach (const Card *card, miji_cards)
                    ids << card->getId();
                CardsMoveStruct move;
                move.card_ids = ids;
                move.from = wangyi;
                move.from_place = Player::PlaceHand;
                move.to = target;
                move.to_place = Player::PlaceHand;
                move.reason = CardMoveReason(CardMoveReason::S_REASON_PREVIEWGIVE,
                                             wangyi->objectName(), target->objectName(), objectName());
                if (target != wangyi) {
                    room->moveCardsAtomic(move, false);
                    room->setPlayerFlag(wangyi, "-nosmiji_InTempMoving");
                } else {
                    wangyi->addToPile("#nosmiji_tempPile", ids, false);
                    DummyCard *dummy = new DummyCard;
                    foreach (int id, ids)
                        dummy->addSubcard(id);
                    room->setPlayerFlag(wangyi, "-nosmiji_InTempMoving");
                    wangyi->obtainCard(dummy, false);
                    dummy->deleteLater();
                }
            }
        }
        return false;
    }
};

NosFanjianCard::NosFanjianCard() {
    mute = true;
}

void NosFanjianCard::onEffect(const CardEffectStruct &effect) const{
    ServerPlayer *zhouyu = effect.from;
    ServerPlayer *target = effect.to;
    Room *room = zhouyu->getRoom();

    int card_id = zhouyu->getRandomHandCardId();
    const Card *card = Sanguosha->getCard(card_id);
    room->broadcastSkillInvoke("fanjian");
    Card::Suit suit = room->askForSuit(target, "nosfanjian");

    LogMessage log;
    log.type = "#ChooseSuit";
    log.from = target;
    log.arg = Card::Suit2String(suit);
    room->sendLog(log);
    room->showCard(zhouyu, card_id);

    if (card->getSuit() != suit) {
        DamageStruct damage;
        damage.card = NULL;
        damage.from = zhouyu;
        damage.to = target;
        damage.reason = "nosfanjian";

        room->damage(damage);
    }

    room->getThread()->delay();
    if (target->isAlive())
        target->obtainCard(card);
}

class NosFanjian: public ZeroCardViewAsSkill {
public:
    NosFanjian(): ZeroCardViewAsSkill("nosfanjian") {
    }

    virtual bool isEnabledAtPlay(const Player *player) const{
        return !player->isKongcheng() && !player->hasUsed("NosFanjianCard");
    }

    virtual const Card *viewAs() const{
        return new NosFanjianCard;
    }
};

class NosZhenggong: public MasochismSkill {
public:
    NosZhenggong(): MasochismSkill("noszhenggong") {
    }

    virtual bool triggerable(const ServerPlayer *target) const{
        return TriggerSkill::triggerable(target) && target->getMark("nosbaijiang") == 0;
    }

    virtual void onDamaged(ServerPlayer *zhonghui, const DamageStruct &damage) const{
        if (damage.from && damage.from->hasEquip()) {
            QVariant data = QVariant::fromValue((PlayerStar)damage.from);
            if (!zhonghui->askForSkillInvoke(objectName(), data))
                return;

            Room *room = zhonghui->getRoom();
            room->broadcastSkillInvoke(objectName());
            int equip = room->askForCardChosen(zhonghui, damage.from, "e", objectName());
            const Card *card = Sanguosha->getCard(equip);

            int equip_index = -1;
            const EquipCard *equipcard = qobject_cast<const EquipCard *>(card->getRealCard());
            equip_index = static_cast<int>(equipcard->location());

            QList<CardsMoveStruct> exchangeMove;
            CardsMoveStruct move1;
            move1.card_ids << equip;
            move1.to = zhonghui;
            move1.to_place = Player::PlaceEquip;
            move1.reason = CardMoveReason(CardMoveReason::S_REASON_ROB, zhonghui->objectName());
            exchangeMove.push_back(move1);
            if (zhonghui->getEquip(equip_index) != NULL) {
                CardsMoveStruct move2;
                move2.card_ids << zhonghui->getEquip(equip_index)->getId();
                move2.to = NULL;
                move2.to_place = Player::DiscardPile;
                move2.reason = CardMoveReason(CardMoveReason::S_REASON_CHANGE_EQUIP, zhonghui->objectName());
                exchangeMove.push_back(move2);
            }
            room->moveCardsAtomic(exchangeMove, true);
        }
    }
};

NosQuanjiCard::NosQuanjiCard() {
    target_fixed = true;
    will_throw = false;
    handling_method = Card::MethodPindian;
}

void NosQuanjiCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const{
    ServerPlayer *target = room->getTag("QuanjiTarget").value<PlayerStar>();
    room->cardEffect(this, source, target);
}

void NosQuanjiCard::onEffect(const CardEffectStruct &effect) const{
    if (effect.from->pindian(effect.to, "nosquanji", Sanguosha->getCard(this->getSubcards().first())))
        effect.from->setFlags("quanji_win");
}

class NosQuanjiViewAsSkill: public OneCardViewAsSkill {
public:
    NosQuanjiViewAsSkill(): OneCardViewAsSkill("nosquanji") {
    }

    virtual bool isEnabledAtPlay(const Player *) const{
        return false;
    }

    virtual bool isEnabledAtResponse(const Player *, const QString &pattern) const{
        return pattern == "@@nosquanji";
    }

    virtual bool viewFilter(const Card *to_select) const{
        return !to_select->isEquipped();
    }

    virtual const Card *viewAs(const Card *originalCard) const{
        Card *card = new NosQuanjiCard;
        card->addSubcard(originalCard);

        return card;
    }
};

class NosQuanji: public TriggerSkill {
public:
    NosQuanji(): TriggerSkill("nosquanji") {
        events << EventPhaseStart;
        view_as_skill = new NosQuanjiViewAsSkill;
    }

    virtual int getPriority() const{
        return 5;
    }

    virtual bool triggerable(const ServerPlayer *target) const{
        return target != NULL;
    }

    virtual bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const{
        if (player->getPhase() != Player::RoundStart || player->isKongcheng())
            return false;

        bool skip = false;
        room->setTag("QuanjiTarget", QVariant::fromValue((PlayerStar)player));
        foreach (ServerPlayer *zhonghui, room->findPlayersBySkillName(objectName())) {
            if (zhonghui == player || zhonghui->isKongcheng()
                || zhonghui->getMark("nosbaijiang") > 0 || player->isKongcheng())
                continue;

            if (room->askForUseCard(zhonghui, "@@nosquanji", "@quanji-pindian", -1, Card::MethodPindian)
                && zhonghui->hasFlag("quanji_win")) {
                zhonghui->setFlags("-quanji_win");
                if (!skip) {
                    room->broadcastSkillInvoke(objectName(), 2);
                    player->skip(Player::Start);
                    player->skip(Player::Judge);
                    skip = true;
                } else {
                    room->broadcastSkillInvoke(objectName(), 3);
                }
            }
        }
        room->removeTag("QuanjiTarget");
        return skip;
    }

    virtual int getEffectIndex(const ServerPlayer *, const Card *) const{
        return 1;
    }
};

class NosBaijiang: public PhaseChangeSkill {
public:
    NosBaijiang(): PhaseChangeSkill("nosbaijiang") {
        frequency = Wake;
    }

    virtual bool triggerable(const ServerPlayer *target) const{
        return PhaseChangeSkill::triggerable(target)
               && target->getMark("nosbaijiang") == 0
               && target->getPhase() == Player::Start
               && target->getEquips().length() >= 3;
    }

    virtual bool onPhaseChange(ServerPlayer *zhonghui) const{
        Room *room = zhonghui->getRoom();
        room->notifySkillInvoked(zhonghui, objectName());

        LogMessage log;
        log.type = "#NosBaijiangWake";
        log.from = zhonghui;
        log.arg = QString::number(zhonghui->getEquips().length());
        log.arg2 = objectName();
        room->sendLog(log);
        room->broadcastSkillInvoke(objectName());
        room->doLightbox("$NosBaijiangAnimate", 5000);
        room->addPlayerMark(zhonghui, "nosbaijiang");

        if (room->changeMaxHpForAwakenSkill(zhonghui, 1)) {
            RecoverStruct recover;
            recover.who = zhonghui;
            room->recover(zhonghui, recover);

            room->acquireSkill(zhonghui, "nosyexin");
            room->detachSkillFromPlayer(zhonghui, "noszhenggong");
            room->detachSkillFromPlayer(zhonghui, "nosquanji");
        }

        return false;
    }
};

NosYexinCard::NosYexinCard() {
    target_fixed = true;
}

void NosYexinCard::onUse(Room *, const CardUseStruct &card_use) const{
    ServerPlayer *zhonghui = card_use.from;

    QList<int> powers = zhonghui->getPile("nospower");
    if (powers.isEmpty())
        return;
    zhonghui->exchangeFreelyFromPrivatePile("nosyexin", "nospower");
}

class NosYexinViewAsSkill: public ZeroCardViewAsSkill {
public:
    NosYexinViewAsSkill(): ZeroCardViewAsSkill("nosyexin") {
    }

    virtual bool isEnabledAtPlay(const Player *player) const{
        return !player->getPile("nospower").isEmpty() && !player->hasUsed("NosYexinCard");
    }

    virtual const Card *viewAs() const{
        return new NosYexinCard;
    }

    virtual Location getLocation() const{
        return Right;
    }
};

class NosYexin: public TriggerSkill {
public:
    NosYexin(): TriggerSkill("nosyexin") {
        events << Damage << Damaged;
        view_as_skill = new NosYexinViewAsSkill;
    }

    virtual bool trigger(TriggerEvent, Room *room, ServerPlayer *zhonghui, QVariant &) const{
        if (!zhonghui->askForSkillInvoke(objectName()))
            return false;
        room->broadcastSkillInvoke(objectName(), 1);
        zhonghui->addToPile("nospower", room->drawCard());

        return false;
    }

    virtual int getEffectIndex(const ServerPlayer *, const Card *) const{
        return 2;
    }
};

class NosYexinClear: public TriggerSkill {
public:
    NosYexinClear(): TriggerSkill("#nosyexin-clear") {
        events << EventLoseSkill;
    }

    virtual bool triggerable(const ServerPlayer *target) const{
        return target && !target->hasSkill("nosyexin") && target->getPile("nospower").length() > 0;
    }

    virtual bool trigger(TriggerEvent, Room *, ServerPlayer *player, QVariant &) const{
        player->clearOnePrivatePile("nospower");
        return false;
    }
};

class NosPaiyi: public PhaseChangeSkill {
public:
    NosPaiyi(): PhaseChangeSkill("nospaiyi") {
        _m_place["Judging"] = Player::PlaceDelayedTrick;
        _m_place["Equip"] = Player::PlaceEquip;
        _m_place["Hand"] = Player::PlaceHand;
    }

    QString getPlace(Room *room, ServerPlayer *player, QStringList places) const{
        if (places.length() > 0) {
            QString place = room->askForChoice(player, "nospaiyi", places.join("+"));
            return place;
        }
        return QString();
    }

    virtual bool onPhaseChange(ServerPlayer *zhonghui) const{
        if (zhonghui->getPhase() != Player::Finish || zhonghui->getPile("nospower").isEmpty())
            return false;

        Room *room = zhonghui->getRoom();
        QList<int> powers = zhonghui->getPile("nospower");
        if (powers.isEmpty() || !room->askForSkillInvoke(zhonghui, objectName()))
            return false;
        QStringList places;
        places << "Hand";

        room->fillAG(powers, zhonghui);
        int power = room->askForAG(zhonghui, powers, false, "nospaiyi");
        zhonghui->invoke("clearAG");

        if (power == -1)
            power = powers.first();

        const Card *card = Sanguosha->getCard(power);

        ServerPlayer *target = room->askForPlayerChosen(zhonghui, room->getAlivePlayers(), "nospaiyi");
        CardMoveReason reason(CardMoveReason::S_REASON_TRANSFER, zhonghui->objectName(), "nospaiyi", QString());

        if (card->isKindOf("DelayedTrick")) {
            if (!zhonghui->isProhibited(target, card) && !target->containsTrick(card->objectName()))
                places << "Judging";
            room->moveCardTo(card, zhonghui, target, _m_place[getPlace(room, zhonghui, places)], reason, true);
        } else if (card->isKindOf("EquipCard")) {
            const EquipCard *equip = qobject_cast<const EquipCard *>(card->getRealCard());
            if (!target->getEquip(equip->location()))
                places << "Equip";
            room->moveCardTo(card, zhonghui, target, _m_place[getPlace(room, zhonghui, places)], reason, true);
        } else
            room->moveCardTo(card, zhonghui, target, _m_place[getPlace(room, zhonghui, places)], reason, true);

        int index = 1;
        if (target != zhonghui) {
            index++;
            room->drawCards(zhonghui, 1);
        }
        room->broadcastSkillInvoke(objectName(), index);

        return false;
    }

private:
    QMap<QString, Player::Place> _m_place;
};

class NosZili: public PhaseChangeSkill {
public:
    NosZili(): PhaseChangeSkill("noszili") {
        frequency = Wake;
    }

    virtual bool triggerable(const ServerPlayer *target) const{
        return PhaseChangeSkill::triggerable(target)
               && target->getMark("noszili") == 0
               && target->getPhase() == Player::Start
               && target->getPile("nospower").length() >= 4;
    }

    virtual bool onPhaseChange(ServerPlayer *zhonghui) const{
        Room *room = zhonghui->getRoom();
        room->notifySkillInvoked(zhonghui, objectName());

        LogMessage log;
        log.type = "#NosZiliWake";
        log.from = zhonghui;
        log.arg = QString::number(zhonghui->getPile("nospower").length());
        log.arg2 = objectName();
        room->sendLog(log);
        room->broadcastSkillInvoke(objectName());
        room->doLightbox("$NosZiliAnimate", 5000);

        room->addPlayerMark(zhonghui, "noszili");
        if (room->changeMaxHpForAwakenSkill(zhonghui))
            room->acquireSkill(zhonghui, "nospaiyi");

        return false;
    }
};

class NosGuixin: public PhaseChangeSkill {
public:
    NosGuixin(): PhaseChangeSkill("nosguixin") {
    }

    virtual bool onPhaseChange(ServerPlayer *weiwudi) const{
        if (weiwudi->getPhase() != Player::Finish)
            return false;

        Room *room = weiwudi->getRoom();
        if (!room->askForSkillInvoke(weiwudi, objectName()))
            return false;

        QString choice = room->askForChoice(weiwudi, objectName(), "modify+obtain");

        int index = qrand() % 2;

        if (choice == "modify") {
            PlayerStar to_modify = room->askForPlayerChosen(weiwudi, room->getOtherPlayers(weiwudi), objectName());
            room->setTag("Guixin2Modify", QVariant::fromValue(to_modify));
            QStringList kingdomList = Sanguosha->getKingdoms();
            kingdomList.removeOne("god");
            QString kingdom = room->askForChoice(weiwudi, objectName(), kingdomList.join("+"));
            room->removeTag("Guixin2Modify");
            QString old_kingdom = to_modify->getKingdom();
            room->setPlayerProperty(to_modify, "kingdom", kingdom);

            room->broadcastSkillInvoke("guixin", index);

            LogMessage log;
            log.type = "#ChangeKingdom";
            log.from = weiwudi;
            log.to << to_modify;
            log.arg = old_kingdom;
            log.arg2 = kingdom;
            room->sendLog(log);
        } else if (choice == "obtain") {
            room->broadcastSkillInvoke("guixin", index + 2);
            QStringList lords = Sanguosha->getLords();
            QList<ServerPlayer *> players = room->getOtherPlayers(weiwudi);
            foreach (ServerPlayer *player, players) {
                lords.removeOne(player->getGeneralName());
            }

            QStringList lord_skills;
            foreach (QString lord, lords) {
                const General *general = Sanguosha->getGeneral(lord);
                QList<const Skill *> skills = general->findChildren<const Skill *>();
                foreach (const Skill *skill, skills) {
                    if (skill->isLordSkill() && !weiwudi->hasSkill(skill->objectName()))
                        lord_skills << skill->objectName();
                }
            }

            if (!lord_skills.isEmpty()) {
                QString skill_name = room->askForChoice(weiwudi, objectName(), lord_skills.join("+"));

                const Skill *skill = Sanguosha->getSkill(skill_name);
                room->acquireSkill(weiwudi, skill);

                if (skill->inherits("TriggerSkill")) {
                    const TriggerSkill *game_start_skill = qobject_cast<const TriggerSkill *>(skill);
                    if (!game_start_skill->getTriggerEvents().contains(GameStart))
                        return false;
                    QVariant data = 0;
                    game_start_skill->trigger(GameStart, room, weiwudi, data);
                }
            }
        }
        return false;
    }
};

NostalGeneralPackage::NostalGeneralPackage()
    : Package("nostal_general")
{
    General *nos_zhouyu = new General(this, "nos_zhouyu", "wu", 3);
    nos_zhouyu->addSkill("yingzi");
    nos_zhouyu->addSkill(new NosFanjian);

    General *nos_zhonghui = new General(this, "nos_zhonghui", "wei", 3);
    nos_zhonghui->addSkill(new NosZhenggong);
    nos_zhonghui->addSkill(new NosQuanji);
    nos_zhonghui->addSkill(new NosBaijiang);
    nos_zhonghui->addSkill(new NosZili);
    nos_zhonghui->addRelateSkill("nosyexin");
    nos_zhonghui->addRelateSkill("#nosyexin-clear");
    nos_zhonghui->addRelateSkill("#nosyexin-fake-move");
    related_skills.insertMulti("nosyexin", "#nosyexin-clear");
    related_skills.insertMulti("nosyexin", "#nosyexin-fake-move");
    nos_zhonghui->addRelateSkill("nospaiyi");

    General *nos_shencaocao = new General(this, "nos_shencaocao", "god", 3);
    nos_shencaocao->addSkill(new NosGuixin);
    nos_shencaocao->addSkill("feiying");

    addMetaObject<NosFanjianCard>();
    addMetaObject<NosQuanjiCard>();
    addMetaObject<NosYexinCard>();

    skills << new NosYexin << new NosYexinClear << new FakeMoveSkill("nosyexin") << new NosPaiyi;
}

NostalYJCMPackage::NostalYJCMPackage()
    : Package("nostal_yjcm")
{
    General *nos_fazheng = new General(this, "nos_fazheng", "shu", 3);
    nos_fazheng->addSkill(new NosEnyuan);
    nos_fazheng->addSkill(new NosXuanhuo);

    General *nos_lingtong = new General(this, "nos_lingtong", "wu");
    nos_lingtong->addSkill(new NosXuanfeng);
    nos_lingtong->addSkill(new SlashNoDistanceLimitSkill("nosxuanfeng"));
    related_skills.insertMulti("nosxuanfeng", "#nosxuanfeng-slash-ndl");

    General *nos_xushu = new General(this, "nos_xushu", "shu", 3);
    nos_xushu->addSkill(new NosWuyan);
    nos_xushu->addSkill(new NosJujian);

    General *nos_zhangchunhua = new General(this, "nos_zhangchunhua", "wei", 3, false);
    nos_zhangchunhua->addSkill("jueqing");
    nos_zhangchunhua->addSkill(new NosShangshi);

    addMetaObject<NosXuanhuoCard>();
    addMetaObject<NosJujianCard>();
}

NostalYJCM2012Package::NostalYJCM2012Package()
    : Package("nostal_yjcm2012")
{
    General *nos_guanxingzhangbao = new General(this, "nos_guanxingzhangbao", "shu");
    nos_guanxingzhangbao->addSkill(new NosFuhun);

    General *nos_handang = new General(this, "nos_handang", "wu");
    nos_handang->addSkill(new NosGongqi);
    nos_handang->addSkill(new NosGongqiTargetMod);
    nos_handang->addSkill(new NosJiefan);
    related_skills.insertMulti("nosgongqi", "#nosgongqi-target");

    General *nos_madai = new General(this, "nos_madai", "shu");
    nos_madai->addSkill(new NosQianxi);
    nos_madai->addSkill("mashu");

    General *nos_wangyi = new General(this, "nos_wangyi", "wei", 3, false);
    nos_wangyi->addSkill(new NosZhenlie);
    nos_wangyi->addSkill(new NosMiji);
    nos_wangyi->addSkill(new FakeMoveSkill("nosmiji", FakeMoveSkill::SourceOnly));
    related_skills.insertMulti("nosmiji", "#nosmiji-fake-move");
}

ADD_PACKAGE(Nostalgia)
ADD_PACKAGE(NostalGeneral)
ADD_PACKAGE(NostalYJCM)
ADD_PACKAGE(NostalYJCM2012)

