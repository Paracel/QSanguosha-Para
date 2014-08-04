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
		local equip_num = to:getEquips():length()
		if to:hasArmorEffect("silver_lion") and to:isWounded() then equip_num = equip_num - 1.1 end
		value_e = equip_num * 1.1
		if to:hasSkills("kofxiaoji|xiaoji") then value_e = value_e * 0.7 end
		if to:hasSkill("nosxuanfeng") then value_e = value_e * 0.85 end
		if to:hasSkills("bazhen|yizhong|bossmanjia") and to:getArmor() then value_e = value_e - 1 end
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
		if not self:slashProhibit(nil, enemy) and self:slashIsEffective(slash, enemy) and sgs.isGoodTarget(enemy, self.enemies, self) then
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