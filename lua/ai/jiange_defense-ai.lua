sgs.ai_skill_invoke.jgjizhen = function(self)
	local v = 0
	for _, friend in ipairs(self.friends) do
		if not self:needKongcheng(friend, true) then v = v + 1 else v = v - 1 end
	end
	return v > 0
end

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