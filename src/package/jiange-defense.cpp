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

// Defensive Machines

JianGeDefensePackage::JianGeDefensePackage()
    : Package("JianGeDefense")
{
#define Machine General

    General *jg_soul_caozhen = new General(this, "jg_soul_caozhen", "wei", 5, true, true);
    jg_soul_caozhen->addSkill(new JGChiying);
    jg_soul_caozhen->addSkill(new JGJingfan);

    Machine *jg_machine_tuntianqiongqi = new Machine(this, "jg_machine_tuntianqiongqi", "wei", 5, true, true);
    jg_machine_tuntianqiongqi->addSkill(new JGJiguan);
    jg_machine_tuntianqiongqi->addSkill(new JGTanshi);
    jg_machine_tuntianqiongqi->addSkill(new JGTunshi);

#undef Machine
}

ADD_PACKAGE(JianGeDefense)
