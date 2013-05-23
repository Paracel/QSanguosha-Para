sgs.ai_skill_invoke.chengxiang = function(self, data)
	return not (self.player:hasSkill("manjuan") and self.player:getPhase() == sgs.Player_NotActive)
end

sgs.ai_skill_askforag.chengxiang = function(self, card_ids)
	return self:askForAG(card_ids, false, "dummyreason")
end

function sgs.ai_cardsview_valuable.renxin(self, class_name, player)
	if class_name == "Peach" and not player:isKongcheng() then
		local dying = player:getRoom():getCurrentDyingPlayer()
		if not dying or self:isEnemy(dying, player) or dying:objectName() == player:objectName() then return nil end
		if dying:hasSkill("manjuan") and dying:getPhase() == sgs.Player_NotActive then
			local peach_num = 0
			if not player:hasFlag("Global_PreventPeach") then
				for _, c in sgs.qlist(player:getCards("he")) do
					if isCard("Peach", c, player) then peach_num = peach_num + 1 end
					if peach_num > 1 then return nil end
				end
			end
		end
		if self:playerGetRound(dying) < self:playerGetRound(self.player) and dying:getHp() < 0 then return nil end
		if not player:faceUp() then
			if player:getHp() < 2 and (getCardsNum("Jink", player) > 0 or getCardsNum("Analeptic", player) > 0) then return nil end
			return "@RenxinCard=."
		else
			if not dying:hasFlag("Global_PreventPeach") then
				for _, c in sgs.qlist(player:getHandcards()) do
					if not isCard("Peach", c, player) then return nil end
				end
			end
			return "@RenxinCard=."
		end
		return nil
	end
end

function sgs.ai_cardsview.renxin(self, class_name, player)
	if class_name == "Peach" and not player:isKongcheng() then
		local dying = player:getRoom():getCurrentDyingPlayer()
		if not dying or self:isEnemy(dying, player) or dying:objectName() == player:objectName() then return nil end
		if player:getHp() < 2 and (getCardsNum("Jink", player) > 0 or getCardsNum("Analeptic", player) > 0) then return nil end
		if not self:isWeak(player) then return "@RenxinCard=." end
		return nil
	end
end

sgs.ai_card_intention.RenxinCard = sgs.ai_card_intention.Peach

sgs.ai_skill_invoke.jingce = function(self, data)
	return not self:needKongcheng(self.player, true)
end

local xiansi_slash_skill = {}
xiansi_slash_skill.name = "xiansi_slash"
table.insert(sgs.ai_skills, xiansi_slash_skill)
xiansi_slash_skill.getTurnUseCard = function(self)
	if not self:slashIsAvailable() then return end
	local liufeng = self.room:findPlayerBySkillName("xiansi")
	if not liufeng or liufeng:getPile("counter"):length() <= 1 or not self.player:canSlash(liufeng) then return end
	return sgs.Card_Parse("@XiansiSlashCard=.")
end

sgs.ai_skill_use_func.XiansiSlashCard = function(card, use, self)
	local liufeng = self.room:findPlayerBySkillName("xiansi")
	if not liufeng or liufeng:getPile("counter"):length() <= 1 or not self.player:canSlash(liufeng) then return "." end
	local slash = sgs.Sanguosha:cloneCard("slash")

	if self:slashIsAvailable() and not self:slashIsEffective(slash, liufeng, self.player) and self:isFriend(liufeng) then
		sgs.ai_use_priority.XiansiSlashCard = 0.1
		use.card = card
		if use.to then use.to:append(liufeng) end
	else
		sgs.ai_use_priority.XiansiSlashCard = 2.6
		local dummy_use = { to = sgs.SPlayerList() }
		self:useCardSlash(slash, dummy_use)
		if dummy_use.card then
			if (dummy_use.card:isKindOf("GodSalvation") or dummy_use.card:isKindOf("Analeptic") or dummy_use.card:isKindOf("Weapon"))
				and self:getCardsNum("Slash") > 0 then
				use.card = dummy_use.card
				return
			else
				if dummy_use.card:isKindOf("Slash") and dummy_use.to:length() > 0 then
					local lf
					for _, p in sgs.qlist(dummy_use.to) do
						if p:objectName() == liufeng:objectName() then
							lf = true
							break
						end
					end
					if not lf then return end
					use.card = card
					if use.to then use.to:append(liufeng) end
				end
			end
		end
	end
end

sgs.ai_card_intention.XiansiSlashCard = function(self, card, from, tos)
	local slash = sgs.Sanguosha:cloneCard("slash")
	if not self:slashIsEffective(slash, tos[1], from) then
		sgs.updateIntention(from, tos[1], -30)
	else
		return sgs.ai_card_intention.Slash(self, slash, from, tos)
	end
end

sgs.ai_skill_cardask["@longyin"] = function(self, data)
	local function getLeastValueCard(isRed)
		local offhorse_avail, weapon_avail
		for _, enemy in ipairs(self.enemies) do
			if self:canAttack(enemy, self.player) then
				if not offhorse_avail and self.player:getOffensiveHorse() and self.player:distanceTo(enemy, 1) <= self.player:getAttackRange() then
					offhorse_avail = true
				end
				if not weapon_avail and self.player:getWeapon() and self.player:distanceTo(enemy) == 1 then
					weapon_avail = true
				end
			end
			if offhorse_avail and weapon_avail then break end
		end
		if self:needToThrowArmor() then return "$" .. self.player:getArmor():getEffectiveId() end
		if self.player:getPhase() > sgs.Player_Play then
			local cards = sgs.QList2Table(self.player:getHandcards())
			self:sortByKeepValue(cards)
			for _, c in ipairs(cards) do
				if self:getKeepValue(c) < 8 and not self:isValuableCard(c) then return "$" .. c:getEffectiveId() end
			end
			if offhorse_avail then return "$" .. self.player:getOffensiveHorse():getEffectiveId() end
			if weapon_avail and self:evaluateWeapon(self.player:getWeapon()) < 5 then return "$" .. self.player:getWeapon():getEffectiveId() end
		else
			local slashc
			local cards = sgs.QList2Table(self.player:getHandcards())
			self:sortByUseValue(cards)
			for _, c in ipairs(cards) do
				if self:getUseValue(c) < 6 and not self:isValuableCard(c) then
					if isCard("Slash", c, self.player) then
						if not slashc then slashc = c end
					else
						return "$" .. c:getEffectiveId()
					end
				end
			end
			if offhorse_avail then return "$" .. self.player:getOffensiveHorse():getEffectiveId() end
			if isRed and slashc then return "$" .. slash:getEffectiveId() end
		end
	end
	local use = data:toCardUse()
	local slash = use.card
	local slash_num = 0
	if use.from:objectName() == self.player:objectName() then slash_num = self:getCardsNum("Slash") else slash_num = getCardsNum("Slash", use.from) end
	if self:isEnemy(use.from) and use.m_addHistory and not self:hasCrossbowEffect(use.from) and slash_num > 0 then return "." end
	if (slash:isRed() and not (self.player:hasSkill("manjuan") and self.player:getPhase() == sgs.Player_NotActive))
		or (use.m_reason == sgs.CardUseStruct_CARD_USE_REASON_PLAY and use.m_addHistory and self:isFriend(use.from) and slash_num >= 1) then
		local str = getLeastValueCard(slash:isRed())
		if str then return str end
	end
	return "."
end

sgs.ai_skill_invoke.juece = function(self, data)
	local move = data:toMoveOneTime()
	if not move.from then return false end
	local from = findPlayerByObjectName(self.room, move.from:objectName())
	return from and self:isEnemy(from) and self:canAttack(from)
end