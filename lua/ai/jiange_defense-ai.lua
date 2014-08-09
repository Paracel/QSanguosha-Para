sgs.ai_skill_invoke.jglingfeng = true

sgs.ai_skill_playerchosen.jglingfeng = function(self, targets)
	self:sort(self.enemies)
	for _, enemy in ipairs(self.enemies) do
		if not self:needToLoseHp(enemy) then return enemy end
	end
	return self.enemies[1]
end

sgs.ai_skill_invoke.jgkonghun = function(self)
	local dangerous_enemy = 0
	for _, enemy in ipairs(self.enemies) do
		if self:damageIsEffective(enemy, sgs.DamageStruct_Thunder) and not self:canAttack(enemy, self.player, sgs.DamageStruct_Thunder) then
			dangerous_enemy = dangerous_enemy + 1
		end
		if dangerous_enemy == 2 then return false end
	end
	return true
end

sgs.ai_skill_invoke.jglianyu = sgs.ai_skill_invoke.bosslianyu
sgs.ai_skill_playerchosen.jgdidong = sgs.ai_skill_playerchosen.bossdidong

sgs.ai_skill_invoke.jgdixian = function(self)
	local value = -2
	if not self.player:faceUp() then value = 2 end

	for _, enemy in ipairs(self.enemies) do
		local value_e = 0
		local equip_num = enemy:getEquips():length()
		if enemy:hasArmorEffect("silver_lion") and enemy:isWounded() then equip_num = equip_num - 1.1 end
		value_e = equip_num * 1.1
		if enemy:hasSkills("kofxiaoji|xiaoji") then value_e = value_e * 0.7 end
		if enemy:hasSkill("nosxuanfeng") then value_e = value_e * 0.85 end
		if enemy:hasSkills("bazhen|yizhong|bossmanjia") and enemy:getArmor() then value_e = value_e - 1 end
		value = value + value_e
	end
	return value > 0
end

sgs.ai_skill_playerchosen.jgchuanyun = sgs.ai_skill_playerchosen.bossxiaoshou

sgs.ai_skill_playerchosen.jgleili = function(self, targets)
	local ts = sgs.QList2Table(targets)
	self:sort(ts)
	for _, enemy in ipairs(ts) do
		if self:canAttack(enemy, self.player, sgs.DamageStruct_Thunder) then return enemy end
	end
end

sgs.ai_skill_playerchosen.jgfengxing = function(self, targets)
	local ts = sgs.QList2Table(targets)
	self:sort(ts)
	for _, enemy in ipairs(ts) do
		if not self:slashProhibit(nil, enemy) and self:slashIsEffective(nil, enemy) and sgs.isGoodTarget(enemy, self.enemies, self) then
			return enemy
		end
	end
end

sgs.ai_skill_playerchosen.jghuodi = sgs.ai_skill_playerchosen.bossdidong

sgs.ai_skill_invoke.jglingyu = function(self)
	if not self.player:faceUp() then return true end
	local wounded_friend = 0
	for _, friend in ipairs(self.friends_noself) do
		if self:isWeak(friend) then return true end
		if friend:isWounded() then wounded_friend = wounded_friend + 1 end
		if wounded_friend == 2 then return true end
	end
	return false
end

sgs.ai_skill_playerchosen.jgtianyun = function(self, targets)
	local getValue = function(enemy)
		local v = 0
		if self:damageIsEffective(enemy, sgs.DamageStruct_Fire, self.player) then
			if not self:canAttack(enemy, self.player, sgs.DamageStruct_Fire) then
				v = -5
			else
				local def = sgs.getDefense(enemy)
				if def < 1 then def = 1 end
				v = 5 / def
			end
		end

		local value_e = 0
		local equip_num = enemy:getEquips():length()
		if enemy:hasArmorEffect("silver_lion") and enemy:isWounded() then equip_num = equip_num - 1.1 end
		value_e = equip_num * 1.1
		if enemy:hasSkills("kofxiaoji|xiaoji") then value_e = value_e * 0.7 end
		if enemy:hasSkill("nosxuanfeng") then value_e = value_e * 0.85 end
		if enemy:hasSkills("bazhen|yizhong|bossmanjia") and enemy:getArmor() then value_e = value_e - 1 end
		return v + value_e
	end

	local cmp = function(a, b)
		return getValue(a) > getValue(b)
	end

	table.sort(self.enemies, cmp)
	local target = self.enemies[1]
	local value = getValue(target)
	if value >= 6 or (not self:isWeak() and value >= 3) then return target end
end

sgs.ai_skill_choice.jggongshen = function(self, choices)
	local off_mac, def_mac = nil, nil
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:property("jiange_defense_type"):toString() == "machine" then
			if self:isFriend(p) then def_mac = p
			else off_mac = p end
		end
	end
	if def_mac and def_mac:isWounded() and self:isWeak(def_mac) then return "recover" end
	if off_mac and self:canAttack(off_mac, self.player, sgs.DamageStruct_Fire) then return "damage" end
	if dec_mac and def_mac:isWounded() then return "recover" end
	return "cancel"
end

sgs.ai_skill_playerchosen.jgzhinang = function(self)
	local ids = self.room:getTag("JGZhinangCards"):toIntList()
	local cards = {}
	for _, id in sgs.qlist(ids) do
		table.insert(cards, sgs.Sanguosha:getCard(id))
	end
	local friend = self:getCardNeedPlayer(cards, self.friends, false)
	if friend then return friend end
	self:sort(self.friends)
	for _, friend in ipairs(self.friends) do
		if not hasManjuanEffect(friend) and not self:needKongcheng(friend, true) then return friend end
	end
	return self.player
end

sgs.ai_skill_playerchosen.jgqiwu = function(self)
	local wounded_friends = self:getWoundedFriend(false, true)
	if #wounded_friends > 0 then return wounded_friends[1] end
end