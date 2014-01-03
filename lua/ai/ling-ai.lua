sgs.ai_skill_invoke.yishi = function(self, data)
	local damage = data:toDamage()
	local target = damage.to
	if self:isFriend(target) then
		if self:getDamagedEffects(target, self.players, true) or self:needToLoseHp(target, self.player, true) then return false
		elseif target:isChained() and self:isGoodChainTarget(target, self.player, nil, nil, damage.card) then return false
		elseif self:isWeak(target) or damage.damage > 1 then return true end
		if target:getJudgingArea():isEmpty() or target:containsTrick("YanxiaoCard") then
			return false
		end
		return true
	else
		if target:isNude() then return false end
		if self:isWeak(target) or damage.damage > 1 or self:hasHeavySlashDamage(self.player, damage.card, target) then return false end
		if target:getArmor() and self:evaluateArmor(target:getArmor(), target) > 3 and not (target:hasArmorEffect("silver_lion") and target:isWounded()) then
			return true
		end
		if target:getEquips():isEmpty() and (target:getHandcardNum() == 1 and (target:hasSkills(sgs.need_kongcheng) or not self:hasLoseHandcardEffective(target))) then
			return false
		end
		if (target:hasSkills("tuntian+zaoxian") and target:getPhase() == sgs.Player_NotActive)
			or (target:isKongcheng() and target:hasSkills(sgs.lose_equip_skill)) then
			return false
		end
		if self:getDamagedEffects(target, self.player, true) then return true end
		return false
	end
	return false
end