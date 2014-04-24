sgs.ai_skill_playerchosen.youdi = function(self, targets)
	self.youdi_obtain_to_friend = false
	local throw_armor = self:needToThrowArmor()
	if throw_armor and #self.friends_noself > 0 and self.player:getCardCount("he") > 1 then
		for _, friend in ipairs(self.friends_noself) do
			if friend:canDiscard(self.player, self.player:getArmor():getEffectiveId())
				and (self:needToThrowArmor(friend) or (self:needKongcheng(friend) and friend:getHandcardNum() == 1)
					or friend:getHandcardNum() <= self:getLeastHandcardNum(friend)) then
				return friend
			end
		end
	end

	local valuable, dangerous = self:getValuableCard(self.player), self:getDangerousCard(self.player)
	local slash_ratio = 0
	if not self.player:isKongcheng() then
		local slash_count = 0
		for _, c in sgs.qlist(self.player:getHandcards()) do
			if c:isKindOf("Slash") then slash_count = slash_count + 1 end
		end
		slash_ratio = slash_count / self.player:getHandcardNum()
	end
	if not valuable and not dangerous and slash_ratio > 0.45 then return nil end

	self:sort(self.enemies, "defense")
	self.enemies = sgs.reverse(self.enemies)
	for _, enemy in ipairs(self.enemies) do
		if enemy:canDiscard(self.player, "he") and not self:doNotDiscard(enemy, "he") then
			if (valuable and enemy:canDiscard(self.player, valuable)) or (dangerous and enemy:canDiscard(self.player, dangerous)) then
				if (self:getValuableCard(enemy) or self:getDangerousCard(enemy)) and sgs.getDefense(enemy) > 8 then return enemy end
			elseif not enemy:isNude() then return enemy
			end
		end
	end
end

sgs.ai_choicemade_filter.cardChosen.youdi_obtain = sgs.ai_choicemade_filter.cardChosen.snatch