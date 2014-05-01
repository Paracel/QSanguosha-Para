#include "yjcm2014.h"
#include "settings.h"
#include "skill.h"
#include "standard.h"
#include "client.h"
#include "clientplayer.h"
#include "engine.h"
#include "maneuvering.h"

class Sidi: public TriggerSkill {
public:
    Sidi(): TriggerSkill("sidi") {
        events << CardResponded << EventPhaseStart << EventPhaseChanging;
        frequency = Frequent;
    }

    virtual bool triggerable(const ServerPlayer *target) const{
        return target != NULL;
    }

    virtual bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const{
        if (triggerEvent == EventPhaseChanging) {
            PhaseChangeStruct change = data.value<PhaseChangeStruct>();
            if (change.from == Player::Play)
                room->setPlayerMark(player, "sidi", 0);
        } else if (triggerEvent == CardResponded) {
            CardResponseStruct resp = data.value<CardResponseStruct>();
            if (resp.m_isUse && resp.m_card->isKindOf("Jink")) {
                foreach (ServerPlayer *p, room->getAllPlayers()) {
                    if (TriggerSkill::triggerable(p) && (p == player || p->getPhase() != Player::NotActive)
                        && room->askForSkillInvoke(p, objectName(), data)) {
                        room->broadcastSkillInvoke(objectName());
                        QList<int> ids = room->getNCards(1, false); // For UI
                        CardsMoveStruct move(ids, p, Player::PlaceTable,
                                             CardMoveReason(CardMoveReason::S_REASON_TURNOVER, p->objectName(), "sidi", QString()));
                        room->moveCardsAtomic(move, true);
                        p->addToPile("sidi", ids);
                    }
                }
            }
        } else if (triggerEvent == EventPhaseStart && player->getPhase() == Player::Play) {
            foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                if (player->getPhase() != Player::Play) return false;
                if (TriggerSkill::triggerable(p) && p->getPile("sidi").length() > 0
                    && room->askForSkillInvoke(p, "sidi_remove", "remove")) {
                    LogMessage log;
                    log.type = "#InvokeSkill";
                    log.from = p;
                    log.arg = "sidi";
                    room->sendLog(log);

                    room->fillAG(p->getPile("sidi"), p);
                    int id = room->askForAG(p, p->getPile("sidi"), false, "sidi");
                    room->clearAG(p);
                    room->throwCard(id, NULL);
                    room->addPlayerMark(player, "sidi");
                }
            }
        }
        return false;
    }
};

class SidiTargetMod: public TargetModSkill {
public:
    SidiTargetMod(): TargetModSkill("#sidi-target") {
    }

    virtual int getResidueNum(const Player *from, const Card *card) const{
        return card->isKindOf("Slash") ? -from->getMark("sidi") : 0;
    }
};

class Zhongyong: public TriggerSkill {
public:
    Zhongyong(): TriggerSkill("zhongyong") {
        events << SlashMissed;
    }

    virtual bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const{
        SlashEffectStruct effect = data.value<SlashEffectStruct>();

        const Card *jink = effect.jink;
        if (!jink) return false;
        QList<int> ids;
        if (!jink->isVirtualCard()) {
            if (room->getCardPlace(jink->getEffectiveId()) == Player::DiscardPile)
                ids << jink->getEffectiveId();
        } else {
            foreach (int id, jink->getSubcards()) {
                if (room->getCardPlace(id) == Player::DiscardPile)
                    ids << id;
            }
        }
        if (ids.isEmpty()) return false;

        room->fillAG(ids, player);
        ServerPlayer *target = room->askForPlayerChosen(player, room->getOtherPlayers(effect.to), objectName(),
                                                        "zhongyong-invoke:" + effect.to->objectName(), true, true);
        room->clearAG(player);
        if (!target) return false;
        room->broadcastSkillInvoke(objectName());
        DummyCard *dummy = new DummyCard(ids);
        room->obtainCard(target, dummy);
        delete dummy;

        if (player->isAlive() && effect.to->isAlive() && target != player) {
            if (!player->canSlash(effect.to, NULL, false))
                return false;
            if (room->askForUseSlashTo(player, effect.to, QString("zhongyong-slash:%1").arg(effect.to->objectName()), false, true))
                return true;
        }
        return false;
    }
};

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

class Zenhui: public TriggerSkill {
public:
    Zenhui(): TriggerSkill("zenhui") {
        events << TargetSpecifying << CardFinished;
    }

    virtual bool triggerable(const ServerPlayer *target) const{
        return target != NULL;
    }

    virtual bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const{
        CardUseStruct use = data.value<CardUseStruct>();
        if (triggerEvent == CardFinished
            && (use.card->isKindOf("Slash") || (use.card->isNDTrick() && use.card->isBlack()))) {
            use.from->setFlags("-ZenhuiUser_" + use.card->toString());
            return false;
        }
        if (!TriggerSkill::triggerable(player) || player->getPhase() != Player::Play || player->hasFlag(objectName()))
            return false;

        if (use.to.length() == 1 && !use.card->targetFixed()
            && (use.card->isKindOf("Slash") || (use.card->isNDTrick() && use.card->isBlack()))) {
            QList<ServerPlayer *> targets;
            foreach (ServerPlayer *p, room->getAlivePlayers()) {
                if (p != player && p != use.to.first()
                    && !room->isProhibited(player, p, use.card)
                    && use.card->targetFilter(QList<const Player *>(), p, player))
                    targets << p;
            }
            if (targets.isEmpty()) return false;
            ServerPlayer *target = room->askForPlayerChosen(player, targets, objectName(),
                                                            "zenhui-invoke:" + use.to.first()->objectName(), true, true);
            if (target) {
                room->broadcastSkillInvoke(objectName());
                player->setFlags(objectName());

                // Collateral
                ServerPlayer *collateral_victim = NULL;
                if (use.card->isKindOf("Collateral")) {
                    QList<ServerPlayer *> victims;
                    foreach (ServerPlayer *p, room->getOtherPlayers(target)) {
                        if (target->canSlash(p))
                            victims << p;
                    }
                    Q_ASSERT(!victims.isEmpty());
                    collateral_victim = room->askForPlayerChosen(player, victims, "zenhui_collateral", "@zenhui-collateral:" + target->objectName());
                    target->tag["collateralVictim"] = QVariant::fromValue((PlayerStar)(collateral_victim));

                    LogMessage log;
                    log.type = "#CollateralSlash";
                    log.from = player;
                    log.to << collateral_victim;
                    room->sendLog(log);
                }

                bool extra_target = true;
                if (!target->isNude()) {
                    const Card *card = room->askForCard(target, "..", "@zenhui-give:" + player->objectName(), data, Card::MethodNone);
                    if (card) {
                        extra_target = false;
                        player->obtainCard(card);

                        if (target->isAlive()) {
                            LogMessage log;
                            log.type = "#BecomeUser";
                            log.from = target;
                            log.card_str = use.card->toString();

                            target->setFlags("ZenhuiUser_" + use.card->toString()); // For AI
                            use.from = target;
                            data = QVariant::fromValue(use);
                        }
                    }
                }
                if (extra_target) {
                    LogMessage log;
                    log.type = "#BecomeTarget";
                    log.from = target;
                    log.card_str = use.card->toString();
                    room->sendLog(log);

                    room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, player->objectName(), target->objectName());
                    if (use.card->isKindOf("Collateral") && collateral_victim)
                        room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, target->objectName(), collateral_victim->objectName());

                    use.to.append(target);
                    room->sortByActionOrder(use.to);
                    data = QVariant::fromValue(use);
                }
            }
        }
        return false;
    }
};

class Jiaojin: public TriggerSkill {
public:
    Jiaojin(): TriggerSkill("jiaojin") {
        events << DamageInflicted;
    }

    virtual bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const{
        DamageStruct damage = data.value<DamageStruct>();
        if (damage.from && damage.from->isMale() && player->canDiscard(player, "he")) {
            if (room->askForCard(player, ".Equip", "@jiaojin", data, objectName())) {
                room->broadcastSkillInvoke(objectName());

                LogMessage log;
                log.type = "#Jiaojin";
                log.from = player;
                log.arg = QString::number(damage.damage);
                log.arg2 = QString::number(--damage.damage);
                room->sendLog(log);

                if (damage.damage < 1)
                    return true;
                data = QVariant::fromValue(damage);
            }
        }
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

class Qieting: public TriggerSkill {
public:
    Qieting(): TriggerSkill("qieting") {
        events << EventPhaseChanging;
    }

    virtual bool triggerable(const ServerPlayer *target) const{
        return target != NULL;
    }

    virtual bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const{
        PhaseChangeStruct change = data.value<PhaseChangeStruct>();
        if (change.to != Player::NotActive || player->getMark("qieting") > 0) return false;
        foreach (ServerPlayer *caifuren, room->getAllPlayers()) {
            if (!TriggerSkill::triggerable(caifuren) || caifuren == player) continue;
            QStringList choices;
            for (int i = 0; i < S_EQUIP_AREA_LENGTH; i++) {
                if (player->getEquip(i) && !caifuren->getEquip(i))
                    choices << QString::number(i);
            }
            choices << "draw" << "cancel";
            QString choice = room->askForChoice(caifuren, objectName(), choices.join("+"), QVariant::fromValue((PlayerStar)player));
            if (choice == "cancel") {
                continue;
            } else {
                LogMessage log;
                log.type = "#InvokeSkill";
                log.arg = objectName();
                log.from = caifuren;
                room->sendLog(log);
                room->notifySkillInvoked(caifuren, objectName());
                if (choice == "draw") {
                    room->broadcastSkillInvoke(objectName(), 2);
                    caifuren->drawCards(1, objectName());
                } else {
                    room->broadcastSkillInvoke(objectName(), 1);
                    int index = choice.toInt();
                    const Card *card = player->getEquip(index);
                    room->moveCardTo(card, caifuren, Player::PlaceEquip);
                }
            }
        }
        return false;
    }
};

class QietingRecord: public TriggerSkill {
public:
    QietingRecord(): TriggerSkill("#qieting-record") {
        events << PreCardUsed << TurnStart;
        global = true;
    }

    virtual int getPriority(TriggerEvent triggerEvent) const{
        return 6;
    }

    virtual bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const{
        if (triggerEvent == PreCardUsed && player->isAlive() && player->getPhase() != Player::NotActive
            && player->getMark("qieting") == 0) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card->getTypeId() != Card::TypeSkill) {
                foreach (ServerPlayer *p, use.to) {
                    if (p != player) {
                        player->addMark("qieting");
                        return false;
                    }
                }
            }
        } else if (triggerEvent == TurnStart) {
            player->setMark("qieting", 0);
        }
        return false;
    }
};

XianzhouDamageCard::XianzhouDamageCard() {
    mute = true;
}

bool XianzhouDamageCard::targetsFeasible(const QList<const Player *> &targets, const Player *Self) const{
    return targets.length() == Self->getMark("xianzhou");
}

bool XianzhouDamageCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const{
    return targets.length() < Self->getMark("xianzhou") && Self->inMyAttackRange(to_select);
}

void XianzhouDamageCard::onEffect(const CardEffectStruct &effect) const{
    effect.from->getRoom()->damage(DamageStruct("xianzhou", effect.from, effect.to));
}

XianzhouCard::XianzhouCard() {
}

bool XianzhouCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const{
    return targets.isEmpty() && to_select != Self;
}

void XianzhouCard::onEffect(const CardEffectStruct &effect) const{
    Room *room = effect.from->getRoom();
    room->removePlayerMark(effect.from, "@handover");
    //room->doLightbox("$XianzhouAnimate");

    int len = 0;
    DummyCard *dummy = new DummyCard;
    foreach (const Card *c, effect.from->getEquips()) {
        dummy->addSubcard(c);
        len++;
    }
    room->setPlayerMark(effect.to, "xianzhou", len);
    effect.to->obtainCard(dummy);
    delete dummy;

    bool rec = true;
    int count = 0;
    foreach (ServerPlayer *p, room->getOtherPlayers(effect.to)) {
        if (effect.to->inMyAttackRange(p)) {
            count++;
            if (count >= len) {
                rec = false;
                break;
            }
        }
    }

    if ((rec || !room->askForUseCard(effect.to, "@xianzhou", "@xianzhou-damage:::" + QString::number(len)))
        && effect.from->isWounded())
        room->recover(effect.from, RecoverStruct(effect.to, NULL, len));
}

class Xianzhou: public ZeroCardViewAsSkill {
public:
    Xianzhou(): ZeroCardViewAsSkill("xianzhou") {
        frequency = Skill::Limited;
        limit_mark = "@handover";
    }

    virtual bool isEnabledAtPlay(const Player *player) const{
        return player->getMark("@handover") > 0 && player->getEquips().length() > 0;
    }

    virtual bool isEnabledAtResponse(const Player *, const QString &pattern) const{
        return pattern == "@xianzhou";
    }

    virtual const Card *viewAs() const{
        QString pattern = Sanguosha->currentRoomState()->getCurrentCardUsePattern();
        if (pattern == "@xianzhou") {
            return new XianzhouDamageCard;
        } else {
            return new XianzhouCard;
        }
    }
};

class Jianying: public TriggerSkill {
public:
    Jianying(): TriggerSkill("jianying") {
        events << CardUsed << CardResponded << EventPhaseChanging;
        frequency = Frequent;
        global = true;
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

class Shibei: public MasochismSkill {
public:
    Shibei(): MasochismSkill("shibei") {
        frequency = Compulsory;
    }

    virtual void onDamaged(ServerPlayer *player, const DamageStruct &) const{
        Room *room = player->getRoom();  
        if (player->getMark("shibei") > 0) {
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
    }
};

class ShibeiRecord: public TriggerSkill {
public:
    ShibeiRecord(): TriggerSkill("#shibei-record") {
        events << PreDamageDone << EventPhaseChanging;
        frequency = Compulsory;
        global = true;
    }

    virtual bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const{
        if (triggerEvent == EventPhaseChanging) {
            PhaseChangeStruct change = data.value<PhaseChangeStruct>();
            if (change.to == Player::NotActive) {
                foreach (ServerPlayer *p, room->getAlivePlayers())
                    p->setMark("shibei", 0);
            }
        } else if (triggerEvent == PreDamageDone) {
            ServerPlayer *current = room->getCurrent();
            if (!current || current->isDead() || current->getPhase() == Player::NotActive)
                return false;
            player->addMark("shibei");
        }
        return false;
    }
};

YJCM2014Package::YJCM2014Package()
    : Package("YJCM2014")
{
    General *caifuren = new General(this, "caifuren", "qun", 3, false); // YJ 301
    caifuren->addSkill(new Qieting);
    caifuren->addSkill(new QietingRecord);
    caifuren->addSkill(new Xianzhou);
    related_skills.insertMulti("qieting", "#qieting-record");

    General *caozhen = new General(this, "caozhen", "wei"); // YJ 302
    caozhen->addSkill(new Sidi);
    caozhen->addSkill(new SidiTargetMod);
    related_skills.insertMulti("sidi", "#sidi-target");

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
    jvshou->addSkill(new ShibeiRecord);
    related_skills.insertMulti("shibei", "#shibei-record");

    General *sunluban = new General(this, "sunluban", "wu", 3, false); // YJ 307
    sunluban->addSkill(new Zenhui);
    sunluban->addSkill(new Jiaojin);

    /*General *wuyi = new General(this, "wuyi", "shu"); // YJ 308
    wuyi->addSkill(new Benxi);*/

    /*General *zhangsong = new General(this, "zhangsong", "shu", 3); // YJ 309
    zhangsong->addSkill(new Qiangzhi);
    zhangsong->addSkill(new Xiantu);*/

    General *zhoucang = new General(this, "zhoucang", "shu"); // YJ 310
    zhoucang->addSkill(new Zhongyong);

    General *zhuhuan = new General(this, "zhuhuan", "wu"); // YJ 311
    zhuhuan->addSkill(new Youdi);

    addMetaObject<ShenxingCard>();
    addMetaObject<BingyiCard>();
    addMetaObject<XianzhouCard>();
    addMetaObject<XianzhouDamageCard>();
}

ADD_PACKAGE(YJCM2014)
