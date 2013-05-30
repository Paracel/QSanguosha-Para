#include "special1v1.h"
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

class KOFTuxi: public DrawCardsSkill {
public:
    KOFTuxi(): DrawCardsSkill("koftuxi") {
    }

    virtual int getDrawNum(ServerPlayer *zhangliao, int n) const{
        Room *room = zhangliao->getRoom();
        bool can_invoke = false;
        QList<ServerPlayer *> targets;
        foreach (ServerPlayer *p, room->getOtherPlayers(zhangliao))
            if (p->getHandcardNum() > zhangliao->getHandcardNum())
                targets << p;
        if (!targets.isEmpty())
            can_invoke = true;

        if (can_invoke) {
            ServerPlayer *target = room->askForPlayerChosen(zhangliao, targets, objectName(), "koftuxi-invoke", true, true);
            if (target) {
                target->setFlags("KOFTuxiTarget");
                zhangliao->setFlags("koftuxi");
                return n - 1;
            } else {
                return n;
            }
        } else
            return n;
    }
};

class KOFTuxiAct: public TriggerSkill {
public:
    KOFTuxiAct(): TriggerSkill("#koftuxi") {
        events << AfterDrawNCards;
    }

    virtual bool triggerable(const ServerPlayer *player) const{
        return player != NULL;
    }

    virtual bool trigger(TriggerEvent, Room *room, ServerPlayer *zhangliao, QVariant &) const{
        if (!zhangliao->hasFlag("koftuxi")) return false;
        zhangliao->setFlags("-koftuxi");

        ServerPlayer *target = NULL;
        foreach (ServerPlayer *p, room->getOtherPlayers(zhangliao)) {
            if (p->hasFlag("KOFTuxiTarget")) {
                p->setFlags("-KOFTuxiTarget");
                target = p;
                break;
            }
        }
        if (!target) return false;

        int card_id = room->askForCardChosen(zhangliao, target, "h", "koftuxi");
        room->broadcastSkillInvoke("tuxi");
        CardMoveReason reason(CardMoveReason::S_REASON_EXTRACTION, zhangliao->objectName());
        room->obtainCard(zhangliao, Sanguosha->getCard(card_id), reason, false);

        return false;
    }
};

class KOFQingguo: public OneCardViewAsSkill {
public:
    KOFQingguo(): OneCardViewAsSkill("kofqingguo") {
    }

    virtual bool viewFilter(const Card *to_select) const{
        return to_select->isEquipped();
    }

    virtual const Card *viewAs(const Card *originalCard) const{
        Jink *jink = new Jink(originalCard->getSuit(), originalCard->getNumber());
        jink->setSkillName(objectName());
        jink->addSubcard(originalCard->getId());
        return jink;
    }

    virtual bool isEnabledAtPlay(const Player *) const{
        return false;
    }

    virtual bool isEnabledAtResponse(const Player *player, const QString &pattern) const{
        return pattern == "jink" && !player->getEquips().isEmpty();
    }
};

class KOFLiegong: public TriggerSkill {
public:
    KOFLiegong(): TriggerSkill("kofliegong") {
        events << TargetConfirmed;
    }

    virtual bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const{
        CardUseStruct use = data.value<CardUseStruct>();
        if (player != use.from || player->getPhase() != Player::Play || !use.card->isKindOf("Slash"))
            return false;
        QVariantList jink_list = player->tag["Jink_" + use.card->toString()].toList();
        int index = 0;
        foreach (ServerPlayer *p, use.to) {
            int handcardnum = p->getHandcardNum();
            if (player->getHp() <= handcardnum && player->askForSkillInvoke(objectName(), QVariant::fromValue(p))) {
                room->broadcastSkillInvoke("liegong");

                LogMessage log;
                log.type = "#NoJink";
                log.from = p;
                room->sendLog(log);
                jink_list.replace(index, QVariant(0));
            }
            index++;
        }
        player->tag["Jink_" + use.card->toString()] = QVariant::fromValue(jink_list);
        return false;
    }
};

class KOFXiaoji: public TriggerSkill {
public:
    KOFXiaoji(): TriggerSkill("kofxiaoji") {
        events << CardsMoveOneTime;
        frequency = Frequent;
    }

    virtual bool trigger(TriggerEvent, Room *room, ServerPlayer *sunshangxiang, QVariant &data) const{
        CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
        if (move.from == sunshangxiang && move.from_places.contains(Player::PlaceEquip)) {
            for (int i = 0; i < move.card_ids.size(); i++) {
                if (move.from_places[i] == Player::PlaceEquip) {
                    QStringList choicelist;
                    choicelist << "draw" << "cancel";
                    if (sunshangxiang->isWounded())
                        choicelist.prepend("recover");
                    QString choice = room->askForChoice(sunshangxiang, objectName(), choicelist.join("+"));
                    if (choice == "cancel")
                        return false;
                    room->broadcastSkillInvoke("xiaoji");
                    room->notifySkillInvoked(sunshangxiang, objectName());

                    LogMessage log;
                    log.type = "#InvokeSkill";
                    log.from = sunshangxiang;
                    log.arg = objectName();
                    room->sendLog(log);
                    if (choice == "draw")
                        sunshangxiang->drawCards(2);
                    else {
                        RecoverStruct recover;
                        recover.who = sunshangxiang;
                        room->recover(sunshangxiang, recover);
                    }
                }
            }
        }
        return false;
    }
};

class Yinli: public TriggerSkill {
public:
    Yinli(): TriggerSkill("yinli") {
        events << BeforeCardsMove;
        frequency = Frequent;
    }

    virtual bool trigger(TriggerEvent , Room *room, ServerPlayer *sunshangxiang, QVariant &data) const{
        CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
        if (move.from == sunshangxiang || move.from == NULL)
            return false;
        if (move.from->getPhase() != Player::NotActive && move.to_place == Player::DiscardPile
            && ((move.reason.m_reason & CardMoveReason::S_MASK_BASIC_REASON) == CardMoveReason::S_REASON_DISCARD
                || move.reason.m_reason == CardMoveReason::S_REASON_CHANGE_EQUIP)) {
            QList<int> card_ids;
            int i = 0;
            foreach (int card_id, move.card_ids) {
                if (Sanguosha->getCard(card_id)->getTypeId() == Card::TypeEquip)
                    card_ids << card_id;
                i++;
            }
            if (card_ids.empty())
                return false;
            else if (sunshangxiang->askForSkillInvoke(objectName(), data)) {
                int ai_delay = Config.AIDelay;
                Config.AIDelay = 0;
                while (!card_ids.empty()) {
                    room->fillAG(card_ids, sunshangxiang);
                    int id = room->askForAG(sunshangxiang, card_ids, true, objectName());
                    if (id == -1) {
                        room->clearAG(sunshangxiang);
                        break;
                    }
                    card_ids.removeOne(id);
                    room->clearAG(sunshangxiang);
                }
                Config.AIDelay = ai_delay;

                if (!card_ids.empty()) {
                    room->broadcastSkillInvoke("yinli");
                    foreach (int id, card_ids) {
                        if (move.card_ids.contains(id)) {
                            move.from_places.removeAt(move.card_ids.indexOf(id));
                            move.card_ids.removeOne(id);
                            data = QVariant::fromValue(move);
                        }
                        room->moveCardTo(Sanguosha->getCard(id), sunshangxiang, Player::PlaceHand, move.reason, true);
                        if (!sunshangxiang->isAlive())
                            break;
                    }
                }
            }
        }
        return false;
    }
};

MouzhuCard::MouzhuCard() {
}

bool MouzhuCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const{
    return targets.isEmpty() && to_select != Self && !to_select->isKongcheng();
}

void MouzhuCard::onEffect(const CardEffectStruct &effect) const{
    Room *room = effect.from->getRoom();
    ServerPlayer *hejin = effect.from, *target = effect.to;
    if (target->isKongcheng()) return;

    const Card *card = NULL;
    if (target->getHandcardNum() > 1) {
        card = room->askForCard(target, ".!", "@mouzhu-give:" + hejin->objectName(), QVariant(), Card::MethodNone);
        if (!card)
            card = target->getHandcards().at(qrand() % target->getHandcardNum());
    } else {
        card = target->getHandcards().first();
    }
    Q_ASSERT(card != NULL);
    hejin->obtainCard(card, false);
    if (!hejin->isAlive() || !target->isAlive()) return;
    if (hejin->getHandcardNum() > target->getHandcardNum()) {
        QStringList choicelist;
        Slash *slash = new Slash(Card::NoSuit, 0);
        slash->setSkillName("_mouzhu");
        Duel *duel = new Duel(Card::NoSuit, 0);
        duel->setSkillName("_mouzhu");
        if (!target->isLocked(slash) && target->canSlash(hejin, slash, false))
            choicelist.append("slash");
        if (!target->isLocked(duel) && !target->isProhibited(hejin, duel))
            choicelist.append("duel");
        if (choicelist.isEmpty()) {
            delete slash;
            delete duel;
            return;
        }
        QString choice = room->askForChoice(target, "mouzhu", choicelist.join("+"));
        CardUseStruct use;
        use.from = target;
        use.to << hejin;
        if (choice == "slash") {
            delete duel;
            use.card = slash;
        } else {
            delete slash;
            use.card = duel;
        }
        room->useCard(use);
    }
}

class Mouzhu: public ZeroCardViewAsSkill {
public:
    Mouzhu(): ZeroCardViewAsSkill("mouzhu") {
    }

    virtual bool isEnabledAtPlay(const Player *player) const{
        return !player->hasUsed("MouzhuCard");
    }

    virtual const Card *viewAs() const{
        return new MouzhuCard;
    }

    virtual int getEffectIndex(const ServerPlayer *, const Card *card) const{
        if (card->isKindOf("MouzhuCard"))
            return -1;
        else
            return -2;
    }
};

class Yanhuo: public TriggerSkill {
public:
    Yanhuo(): TriggerSkill("yanhuo") {
        events << BeforeGameOverJudge << Death;
    }

    virtual bool triggerable(const ServerPlayer *target) const{
        return target && !target->isAlive() && target->hasSkill(objectName());
    }

    virtual bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const{
        if (triggerEvent == BeforeGameOverJudge) {
            player->setMark(objectName(), player->getCardCount(true));
        } else {
            int n = player->getMark(objectName());
            bool normal = false;
            ServerPlayer *killer = NULL;
            if (room->getMode() == "02_1v1")
                killer = room->getOtherPlayers(player).first();
            else {
                normal = true;
                QList<ServerPlayer *> targets;
                foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                    if (player->canDiscard(p, "he"))
                        targets << p;
                }
                if (!targets.isEmpty())
                    killer = room->askForPlayerChosen(player, targets, objectName(), "yanhuo-invoke", true, true);
            }
            if (killer && killer->isAlive() && player->canDiscard(killer, "he")
                && (normal || room->askForSkillInvoke(player, objectName()))) {
                for (int i = 0; i < n; i++) {
                    if (player->canDiscard(killer, "he")) {
                        int card_id = room->askForCardChosen(player, killer, "he", objectName(), false, Card::MethodDiscard);
                        room->throwCard(Sanguosha->getCard(card_id), killer, player);
                    } else {
                        break;
                    }
                }
            }
        }
        return false;
    }
};

Drowning::Drowning(Suit suit, int number)
    : SingleTargetTrick(suit, number)
{
    setObjectName("drowning");
}

bool Drowning::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const{
    int total_num = 1 + Sanguosha->correctCardTarget(TargetModSkill::ExtraTarget, Self, this);
    if (targets.length() >= total_num)
        return false;

    if (to_select == Self)
        return false;

    return true;
}

void Drowning::onEffect(const CardEffectStruct &effect) const{
    Room *room = effect.to->getRoom();
    if (!effect.to->getEquips().isEmpty()
        && room->askForChoice(effect.to, objectName(), "throw+damage", QVariant::fromValue(effect)) == "throw")
        effect.to->throwAllEquips();
    else
        room->damage(DamageStruct(this, effect.from->isAlive() ? effect.from : NULL, effect.to));
}

Special1v1Package::Special1v1Package()
    : Package("Special1v1")
{
    General *kof_zhangliao = new General(this, "kof_zhangliao", "wei");
    kof_zhangliao->addSkill(new KOFTuxi);
    kof_zhangliao->addSkill(new KOFTuxiAct);
    related_skills.insertMulti("koftuxi", "#koftuxi");

    General *kof_zhenji = new General(this, "kof_zhenji", "wei", 3);
    kof_zhenji->addSkill(new KOFQingguo);
    kof_zhenji->addSkill("luoshen");

    General *kof_huangzhong = new General(this, "kof_huangzhong", "shu");
    kof_huangzhong->addSkill(new KOFLiegong);

    General *kof_jiangwei = new General(this, "kof_jiangwei", "shu");
    kof_jiangwei->addSkill("tiaoxin");

    General *kof_sunshangxiang = new General(this, "kof_sunshangxiang", "wu", 3, false);
    kof_sunshangxiang->addSkill(new Yinli);
    kof_sunshangxiang->addSkill(new KOFXiaoji);

    General *hejin = new General(this, "hejin", "qun", 4);
    hejin->addSkill(new Mouzhu);
    hejin->addSkill(new Yanhuo);

    addMetaObject<MouzhuCard>();
}

ADD_PACKAGE(Special1v1)

#include "maneuvering.h"
New1v1CardPackage::New1v1CardPackage()
    : Package("New1v1Card")
{
    QList<Card *> cards;
    cards << new Duel(Card::Spade, 1)
          << new EightDiagram(Card::Spade, 2)
          << new Dismantlement(Card::Spade, 3)
          << new Snatch(Card::Spade, 4)
          << new Slash(Card::Spade, 5)
          << new QinggangSword(Card::Spade, 6)
          << new Slash(Card::Spade, 7)
          << new Slash(Card::Spade, 8)
          << new IceSword(Card::Spade, 9)
          << new Slash(Card::Spade, 10)
          << new Snatch(Card::Spade, 11)
          << new Spear(Card::Spade, 12)
          << new SavageAssault(Card::Spade, 13);

    cards << new ArcheryAttack(Card::Heart, 1)
          << new Jink(Card::Heart, 2)
          << new Peach(Card::Heart, 3)
          << new Peach(Card::Heart, 4)
          << new Jink(Card::Heart, 5)
          << new Indulgence(Card::Heart, 6)
          << new ExNihilo(Card::Heart, 7)
          << new ExNihilo(Card::Heart, 8)
          << new Peach(Card::Heart, 9)
          << new Slash(Card::Heart, 10)
          << new Slash(Card::Heart, 11)
          << new Dismantlement(Card::Heart, 12)
          << new Nullification(Card::Heart, 13);

    cards << new Duel(Card::Club, 1)
          << new RenwangShield(Card::Club, 2)
          << new Dismantlement(Card::Club, 3)
          << new Slash(Card::Club, 4)
          << new Slash(Card::Club, 5)
          << new Slash(Card::Club, 6)
          << new Drowning(Card::Club, 7)
          << new Slash(Card::Club, 8)
          << new Slash(Card::Club, 9)
          << new Slash(Card::Club, 10)
          << new Slash(Card::Club, 11)
          << new SupplyShortage(Card::Club, 12)
          << new Nullification(Card::Club, 13);

    cards << new Crossbow(Card::Diamond, 1)
          << new Jink(Card::Diamond, 2)
          << new Jink(Card::Diamond, 3)
          << new Snatch(Card::Diamond, 4)
          << new Axe(Card::Diamond, 5)
          << new Slash(Card::Diamond, 6)
          << new Jink(Card::Diamond, 7)
          << new Jink(Card::Diamond, 8)
          << new Slash(Card::Diamond, 9)
          << new Jink(Card::Diamond, 10)
          << new Jink(Card::Diamond, 11)
          << new Peach(Card::Diamond, 12)
          << new Slash(Card::Diamond, 13);

    foreach (Card *card, cards)
        card->setParent(this);

    type = CardPack;
}

ADD_PACKAGE(New1v1Card)
