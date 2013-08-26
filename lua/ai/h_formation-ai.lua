function sgs.ai_skill_invoke.ziliang = function(self, data)
	self.ziliang_id = nil
	local damage = data:toDamage()
	if damage.to:hasSkill("manjuan") and damage.to:getPhase() == sgs.Player_NotActive then return false end
	if not self:isFriend(damage.to) then
		if damage.to:getPhase() == sgs.Player_NotActive and self:needKongcheng(damage.to, true) then
			local ids = sgs.QList2Table(self.player:getPile("field"))
			for _, id in ipairs(ids) do
				local card = sgs.Sanguosha:getCard(id)
				if card:isKindOf("Disaster") or card:isKindOf("GodSalvation") or card:isKindOf("AmazingGrace") or card:isKindOf("FireAttack") then
					self.ziliang_id = id
					return true
				end
		else
			return false
		end
	else
		if not (damage.to:getPhase() == sgs.Player_NotActive and self:needKongcheng(damage.to, true)) then
			local ids = sgs.QList2Table(self.player:getPile("field"))
			local cards = {}
			for _, id in ipairs(ids) do table.insert(cards, sgs.Sanguosha:getCard(id)) end
			for _, card in ipairs(cards) do
				if card:isKindOf("Peach") then self.ziliang_id = card:getEffectiveId() return true end
			end
			for _, card in ipairs(cards) do
				if card:isKindOf("Jink") then self.ziliang_id = card:getEffectiveId() return true end
			end
			self:sortByKeepValue(cards, true)
			self.ziliang_id = cards[1]:getEffectiveId()
			return true
		else
			return false
		end
	end
end

sgs.ai_skill_askforag.ziliang = function(self, card_ids)
	return self.ziliang_id
end

sgs.ai_choicemade_filter.skillInvoke.ziliang = function(self, player, promptlist)
	local damage = self.room:getTag("CurrentDamageStruct"):toDamage()
	if damage.to and promptlist[#promptlist] == "yes" then
		local intention = -40
		if damage.to:getPhase() == sgs.Player_NotActive and self:needKongcheng(damage.to, true) then intention = 10 end
		sgs.updateIntention(player, damage.to, intention)
	end
end