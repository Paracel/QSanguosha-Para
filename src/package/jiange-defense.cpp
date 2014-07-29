#include "jiange-defense.h"
#include "settings.h"
#include "skill.h"
#include "standard.h"
#include "client.h"
#include "clientplayer.h"
#include "engine.h"
#include "maneuvering.h"

bool isJianGeFriend(const Player *a, const Player *b) {
    return a->getRole() == b->getRole();
}

// WEI Souls

class JGChiying: public TriggerSkill {
public:
    JGChiying(): TriggerSkill("jgchiying") {
        events << DamageInflicted;
        frequency = Compulsory;
    }

    virtual bool triggerable(const ServerPlayer *target) const{
        return target != NULL;
    }

    virtual bool trigger(TriggerEvent, Room *room, ServerPlayer *, QVariant &data) const{
        DamageStruct damage = data.value<DamageStruct>();
        ServerPlayer *zidan = room->findPlayerBySkillName(objectName());
        if (zidan && isJianGeFriend(zidan, damage.to) && damage.damage > 1) {
            LogMessage log;
            log.type = "#JGChiying";
            log.from = zidan;
            log.to << damage.to;
            log.arg = QString::number(damage.damage);
            log.arg2 = objectName();
            room->sendLog(log);
            room->broadcastSkillInvoke(objectName());
            room->notifySkillInvoked(zidan, objectName());

            damage.damage = 1;
            data = QVariant::fromValue(damage);
        }
        return false;
    }
};

class JGJingfan: public DistanceSkill {
public:
    JGJingfan(): DistanceSkill("jgjingfan") {
    }

    virtual int getCorrect(const Player *from, const Player *to) const{
        int dist = 0;
        if (!isJianGeFriend(from, to)) {
            foreach (const Player *p, from->getAliveSiblings()) {
                if (p->hasSkill(objectName()) && isJianGeFriend(p, from))
                    dist--;
            }
            return dist;
        }
        return 0;
    }
};

class JGKonghun: public PhaseChangeSkill {
public:
    JGKonghun(): PhaseChangeSkill("jgkonghun") {
    }

    virtual bool onPhaseChange(ServerPlayer *target) const{
        if (target->getPhase() != Player::Play || !target->isWounded()) return false;
        Room *room = target->getRoom();

        QList<ServerPlayer *> enemies;
        foreach (ServerPlayer *p, room->getAllPlayers()) {
            if (!isJianGeFriend(p, target))
                enemies << p;
        }

        int enemy_num = enemies.length();
        if (target->getLostHp() >= enemy_num && room->askForSkillInvoke(player, objectName())) {
            room->broadcastSkillInvoke(objectName());
            foreach (ServerPlayer *p, enemies)
                room->damage(DamageStruct(objectName(), target, p, 1, DamageStruct::Thunder));
            if (target->isWounded())
                room->recover(target, RecoverStruct(target));
        }
        return false;
    }
};

class JGFanshi: public PhaseChangeSkill {
public:
    JGFanshi(): PhaseChangeSkill("jgfanshi") {
        frequency = Compulsory;
    }

    virtual bool onPhaseChange(ServerPlayer *target) const{
        if (target->getPhase() != Player::Finish) return false;
        Room *room = target->getRoom();

        LogMessage log;
        log.type = "#TriggerSkill";
        log.from = target;
        log.arg = objectName();
        room->sendLog(log);
        room->broadcastSkillInvoke(objectName());
        room->notifySkillInvoked(target, objectName());

        room->loseHp(target, 1);
        return false;
    }
};

class JGXuanlei: public PhaseChangeSkill {
public:
    JGXuanlei(): PhaseChangeSkill("jgxuanlei") {
        frequency = Compulsory;
    }

    virtual bool onPhaseChange(ServerPlayer *target) const{
        if (target->getPhase() != Player::Start) return false;
        Room *room = target->getRoom();

        QList<ServerPlayer *> enemies;
        foreach (ServerPlayer *p, room->getAllPlayers()) {
            if (!p->getJudgingArea().isEmpty() && !isJianGeFriend(p, target))
                enemies << p;
        }

        if (!enemies.isEmpty()) {
            LogMessage log;
            log.type = "#TriggerSkill";
            log.from = target;
            log.arg = objectName();
            room->sendLog(log);
            room->broadcastSkillInvoke(objectName());
            room->notifySkillInvoked(target, objectName());

            foreach (ServerPlayer *p, enemies)
                room->damage(DamageStruct(objectName(), target, p, 1, DamageStruct::Thunder));
            return false;
        }
    }
};

// Offensive Machines

class JGJiguan: public ProhibitSkill {
public:
    JGJiguan(): ProhibitSkill("jgjiguan") {
    }

    virtual bool isProhibited(const Player *, const Player *to, const Card *card, const QList<const Player *> &) const{
        return to->hasSkill(objectName()) && card->isKindOf("Indulgence");
    }
};

class JGTanshi: public DrawCardsSkill {
public:
    JGTanshi(): DrawCardsSkill("jgtanshi") {
        frequency = Compulsory;
    }

    virtual int getDrawNum(ServerPlayer *player, int n) const{
        Room *room = player->getRoom();

        LogMessage log;
        log.type = "#TriggerSkill";
        log.from = player;
        log.arg = objectName();
        room->sendLog(log);

        room->broadcastSkillInvoke(objectName());
        room->notifySkillInvoked(player, objectName());

        return n - 1;
    }
};

class JGTunshi: public PhaseChangeSkill {
public:
    JGTunshi(): PhaseChangeSkill("jgtunshi") {
        frequency = Compulsory;
    }

    virtual bool onPhaseChange(ServerPlayer *target) const{
        if (target->getPhase() != Player::Start) return false;
        Room *room = target->getRoom();

        QList<ServerPlayer *> to_damage;
        foreach (ServerPlayer *p, room->getAllPlayers()) {
            if (p->getHandcardNum() > target->getHandcardNum() && !isJianGeFriend(p, target))
                to_damage << p;
        }

        if (!to_damage.isEmpty()) {
            LogMessage log;
            log.type = "#TriggerSkill";
            log.from = target;
            log.arg = objectName();
            room->sendLog(log);

            room->broadcastSkillInvoke(objectName());
            room->notifySkillInvoked(target, objectName());

            foreach (ServerPlayer *p, to_damage)
                room->damage(DamageStruct(objectName(), target, p));
        }
        return false;
    }
};

// SHU Souls

class JGJizhen: public PhaseChangeSkill {
public:
    JGJizhen(): PhaseChangeSkill("jgjizhen") {
    }

    virtual bool onPhaseChange(ServerPlayer *target) const{
        if (target->getPhase() != Player::Finish) return false;
        Room *room = target->getRoom();

        QList<ServerPlayer *> to_draw;
        foreach (ServerPlayer *p, room->getAllPlayers()) {
            if (p->isWounded() && isJianGeFriend(p, target))
                to_draw << p;
        }

        if (!to_draw.isEmpty() && room->askForSkillInvoke(target, objectName())) {
            room->broadcastSkillInvoke(objectName());
            room->drawCards(to_draw, 1, objectName());
        }
        return false;
    }
};

class JGLingfeng: public PhaseChangeSkill {
public:
    JGLingfeng(): PhaseChangeSkill("jglingfeng") {
    }

    virtual bool onPhaseChange(ServerPlayer *target) const{
        if (target->getPhase() != Player::Draw) return false;
        Room *room = target->getRoom();
        if (target->askForSkillInvoke(objectName())) {
            room->broadcastSkillInvoke(objectName());

            int card1 = room->drawCard();
            int card2 = room->drawCard();
            QList<int> ids;
            ids << card1 << card2;
            bool diff = (Sanguosha->getCard(card1)->getColor() != Sanguosha->getCard(card2)->getColor());

            CardsMoveStruct move;
            move.card_ids = ids;
            move.reason = CardMoveReason(CardMoveReason::S_REASON_TURNOVER, target->objectName(), objectName(), QString());
            move.to_place = Player::PlaceTable;
            room->moveCardsAtomic(move, true);
            room->getThread()->delay();

            DummyCard *dummy = new DummyCard(move.card_ids);
            room->obtainCard(target, dummy);
            delete dummy;

            if (diff) {
                QList<ServerPlayer *> enemies;
                foreach (ServerPlayer *p, room->getAllPlayers()) {
                    if (!isJianGeFriend(p, target))
                        enemies << p;
                }
                Q_ASSERT(!enemies.isEmpty());
                ServerPlayer *enemy = room->askForPlayerChosen(target, enemies, objectName(), "@jglingfeng");
                if (enemy)
                    room->loseHp(enemy);
            }
        }
        return true;
    }
};

// Defensive Machines

class JGMojian: public PhaseChangeSkill {
public:
    JGMojian(): PhaseChangeSkill("jgmojian") {
        frequency = Compulsory;
    }

    virtual bool onPhaseChange(ServerPlayer *target) const{
        if (target->getPhase() != Player::Play) return false;
        Room *room = target->getRoom();

        ArcheryAttack *aa = new ArcheryAttack(Card::NoSuit, 0);
        aa->setSkillName("_" + objectName());
        bool can_invoke = false;
        if (!target->isCardLimited(aa, Card::MethodUse)) {
            foreach (ServerPlayer *p, room->getOtherPlayers(target)) {
                if (!room->isProhibited(target, p, aa)) {
                    can_invoke = true;
                    break;
                }
            }
        }
        if (!can_invoke) {
            delete aa;
            return false;
        }

        LogMessage log;
        log.type = "#TriggerSkill";
        log.from = target;
        log.arg = objectName();
        room->sendLog(log);

        room->broadcastSkillInvoke(objectName());
        room->notifySkillInvoked(target, objectName());
        room->useCard(CardUseStruct(aa, target, QList<ServerPlayer *>()));
        return false;
    }
};

class JGMojianProhibit: public ProhibitSkill {
public:
    JGMojianProhibit(): ProhibitSkill("#jgmojian-prohibit") {
    }

    virtual bool isProhibited(const Player *from, const Player *to, const Card *card, const QList<const Player *> &) const{
        return isJianGeFriend(from, to) && card->isKindOf("ArcheryAttack") && card->getSkillName() == "jgmojian";
    }
};

JianGeDefensePackage::JianGeDefensePackage()
    : Package("JianGeDefense")
{
    typedef General Soul;
    typedef General Machine;

    Soul *jg_soul_caozhen = new Soul(this, "jg_soul_caozhen", "wei", 5, true, true);
    jg_soul_caozhen->addSkill(new JGChiying);
    jg_soul_caozhen->addSkill(new JGJingfan);

    Soul *jg_soul_simayi = new Soul(this, "jg_soul_simayi", "wei", 5, true, true);
    jg_soul_simayi->addSkill(new JGKonghun);
    jg_soul_simayi->addSkill(new JGFanshi);
    jg_soul_simayi->addSkill(new JGXuanlei);

    Machine *jg_machine_tuntianqiongqi = new Machine(this, "jg_machine_tuntianqiongqi", "wei", 5, true, true);
    jg_machine_tuntianqiongqi->addSkill(new JGJiguan);
    jg_machine_tuntianqiongqi->addSkill(new JGTanshi);
    jg_machine_tuntianqiongqi->addSkill(new JGTunshi);

    Soul *jg_soul_liubei = new Soul(this, "jg_soul_liubei", "shu", 5, true, true);
    jg_soul_liubei->addSkill(new JGJizhen);
    jg_soul_liubei->addSkill(new JGLingfeng);

    Machine *jg_machine_yunpingqinglong = new Machine(this, "jg_machine_yunpingqinglong", "shu", 5, true, true);
    jg_machine_yunpingqinglong->addSkill("jgjiguan");
    jg_machine_yunpingqinglong->addSkill(new JGMojian);
    jg_machine_yunpingqinglong->addSkill(new JGMojianProhibit);
    related_skills.insertMulti("jgmojian", "#jgmojian-prohibit");
}

ADD_PACKAGE(JianGeDefense)
