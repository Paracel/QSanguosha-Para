sgs.ai_skill_invoke.moukui = function(self, data)
	local target = data:toPlayer()
	self.moukuitarget = target
	if self:isFriend(target) then return target:getArmor() and self:needToThrowArmor(target) else return true end
end

sgs.ai_skill_choice.moukui = function(self, choices, data)
	local target = self.moukuitarget
	if not target then return "draw" end
	if self:isEnemy(target) and self:doNotDiscard(target, "he", false, 1, "moukui") then return "draw" end
	return "discard"
end

sgs.ai_skill_cardchosen.moukui = function(self, who, flags)
	local use = self.room:getTag("MoukuiDiscard"):toCardUse()
	self.moukui_effect = use.card
	local id = self:askForCardChosen(who, flags, "dummy")
	self.moukui_effect = nil
	return id
end

sgs.ai_skill_invoke.tianming = function(self, data)
	self.tianming_discard = nil
	if hasManjuanEffect(self.player) then return false end
	if self.player:hasArmorEffect("eight_diagram") and self.player:getCardCount() == 2 then return false end
	if self:getCardsNum("Jink") == 0 or self.player:isNude() then return true end
	local unpreferedCards = {}
	local cards = sgs.QList2Table(self.player:getHandcards())

	self:sortByKeepValue(cards)
	if self:isWeak() then
		for _, card in ipairs(cards) do
			if card:isKindOf("Slash") then table.insert(unpreferedCards, card:getId()) end
		end
	else
		if self:getCardsNum("Slash") > 1 then
			for _, card in ipairs(cards) do
				if card:isKindOf("Slash") then table.insert(unpreferedCards, card:getId()) end
			end
			table.remove(unpreferedCards, 1)
		end
	end

	local num = self:getCardsNum("Jink") - 1
	if self.player:getArmor() then num = num + 1 end
	if num > 0 then
		for _, card in ipairs(cards) do
			if card:isKindOf("Jink") and num > 0 then
				table.insert(unpreferedCards, card:getId())
				num = num - 1
			end
		end
	end

	for _, card in ipairs(cards) do
		if (card:isKindOf("Weapon") and self.player:getHandcardNum() < 3) or card:isKindOf("OffensiveHorse")
			or self:getSameEquip(card, self.player) or card:isKindOf("AmazingGrace") or card:isKindOf("Lightning") then
			table.insert(unpreferedCards, card:getId())
		end
	end

	if self.player:getWeapon() and self.player:getHandcardNum() < 3 then
		table.insert(unpreferedCards, self.player:getWeapon():getId())
	end

	if self:needToThrowArmor() then
		table.insert(unpreferedCards, self.player:getArmor():getId())
	end

	if self.player:getOffensiveHorse() and self.player:getWeapon() then
		table.insert(unpreferedCards, self.player:getOffensiveHorse():getId())
	end

	local use_cards = {}
	for index = #unpreferedCards, 1, -1 do
		if not self.player:isJilei(sgs.Sanguosha:getCard(unpreferedCards[index])) then table.insert(use_cards, unpreferedCards[index]) end
	end

	if #use_cards >= 2 or #use_cards == #cards then
		self.tianming_discard = use_cards
		return true
	end
end

sgs.ai_skill_discard.tianming = function(self, discard_num, min_num, optional, include_equip)
	local discard = self.tianming_discard
	if discard and #discard >= 2 then
		return { discard[1], discard[2] }
	else
		return self:askForDiscard("dummyreason", 2, 2, false, true)
	end
end

local mizhao_skill = {}
mizhao_skill.name = "mizhao"
table.insert(sgs.ai_skills, mizhao_skill)
mizhao_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("MizhaoCard") or self.player:isKongcheng() then return end
	return sgs.Card_Parse("@MizhaoCard=.")
end

sgs.ai_skill_use_func.MizhaoCard = function(card, use, self)
	local handcardnum = self.player:getHandcardNum()
	local trash = self:getCard("Disaster") or self:getCard("GodSalvation") or self:getCard("AmazingGrace") or self:getCard("Slash") or self:getCard("FireAttack")
	local count = 0
	local target
	for _, enemy in ipairs(self.enemies) do
		if not enemy:isKongcheng() then count = count + 1 end
	end
	if handcardnum == 1 and trash and count >= 1 and #self.enemies > 1 then
		self:sort(self.enemies, "handcard")
		for _, enemy in ipairs(self.enemies) do
			if not (enemy:hasSkill("manjuan") and enemy:isKongcheng()) and not enemy:hasSkills("tuntian+zaoxian") then
				target = enemy
				break
			end
		end
	end
	if not target then
		self:sort(self.friends_noself, "defense")
		self.friends_noself = sgs.reverse(self.friends_noself)
		if count < 1 then return end
		for _, friend in ipairs(self.friends_noself) do
			if not friend:hasSkill("manjuan") and friend:hasSkills("tuntian+zaoxian") and not self:isWeak(friend) then
				target = friend
				break
			end
		end
		if not target then
			for _, friend in ipairs(self.friends_noself) do
				if not friend:hasSkill("manjuan") then
					target = friend
					break
				end
			end
		end
	end
	if target then
		for _, acard in sgs.qlist(self.player:getHandcards()) do
			if isCard("Peach", acard, self.player) and self.player:getHandcardNum() > 1 and self.player:isWounded()
				and not self:needToLoseHp(self.player) then
					use.card = acard
					return
			end
		end
		use.card = card
		if use.to then
			target:setFlags("AI_MizhaoTarget")
			use.to:append(target)
		end
	end
end

sgs.ai_use_priority.MizhaoCard = 1.5
sgs.ai_card_intention.MizhaoCard = 0
sgs.ai_playerchosen_intention.mizhao = 10

sgs.ai_skill_playerchosen.mizhao = function(self, targets)
	self:sort(self.enemies, "defense")
	local slash = sgs.cloneCard("slash")
	local from
	for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if player:hasFlag("AI_MizhaoTarget") then
			from = player
			from:setFlags("-AI_MizhaoTarget")
			break
		end
	end
	if from then
		for _, to in ipairs(self.enemies) do
			if targets:contains(to) and self:slashIsEffective(slash, to, nil, from) and not self:getDamagedEffects(to, from, true)
				and not self:needToLoseHp(to, from, true) and not self:findLeijiTarget(to, 50, from) then
				return to
			end
		end
	end
	for _, to in ipairs(self.enemies) do
		if targets:contains(to) then
			return to
		end
	end
end

function sgs.ai_skill_pindian.mizhao(minusecard, self, requestor, maxcard)
	local req
	if self.player:objectName() == requestor:objectName() then
		for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if p:hasFlag("MizhaoPindianTarget") then
				req = p
				break
			end
		end
	else
		req = requestor
	end
	local cards, maxcard = sgs.QList2Table(self.player:getHandcards())
	local max_value = 0
	self:sortByKeepValue(cards)
	max_value = self:getKeepValue(cards[#cards])
	local function compare_func1(a, b)
		return a:getNumber() > b:getNumber()
	end
	local function compare_func2(a, b)
		return a:getNumber() < b:getNumber()
	end
	if self:isFriend(req) and self.player:getHp() > req:getHp() then
		table.sort(cards, compare_func2)
	else
		table.sort(cards, compare_func1)
	end
	for _, card in ipairs(cards) do
		if max_value > 7 or self:getKeepValue(card) < 7 or card:isKindOf("EquipCard") then maxcard = card break end
	end
	return maxcard or cards[1]
end

sgs.ai_skill_cardask["@jieyuan-increase"] = function(self, data)
	local damage = data:toDamage()
	local target = damage.to
	if self:isFriend(target) then return "." end
	if target:hasArmorEffect("silver_lion") then return "." end
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByKeepValue(cards)
	for _, card in ipairs(cards) do
		if card:isBlack() then return "$" .. card:getEffectiveId() end
	end
	return "."
end

sgs.ai_skill_cardask["@jieyuan-decrease"] = function(self, data)
	local damage = data:toDamage()
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByKeepValue(cards)
	if damage.card and damage.card:isKindOf("Slash") then
		if self:hasHeavySlashDamage(damage.from, damage.card, self.player) then
			for _, card in ipairs(cards) do
				if card:isRed() then return "$" .. card:getEffectiveId() end
			end
		end
	end
	if self:getDamagedEffects(self.player, damage.from) and damage.damage <= 1 then return "." end
	if self:needToLoseHp(self.player, damage.from) and damage.damage <= 1 then return "." end
	for _, card in ipairs(cards) do
		if card:isRed() then return "$" .. card:getEffectiveId() end
	end
	return "."
end

function sgs.ai_cardneed.jieyuan(to, card)
	return to:getHandcardNum() < 4 and (to:getHp() >= 3 and true or card:isRed())
end

sgs.ai_skill_invoke.fenxin = function(self, data)
	local target = data:toPlayer()
	local target_role = sgs.evaluatePlayerRole(target)
	local self_role = self.player:getRole()
	if target_role == "renegade" or target_role == "neutral" then return false end
	local process = sgs.gameProcess(self.room)
	return (target_role == "rebel" and self.role ~= "rebel" and process:match("rebel"))
			or (target_role == "loyalist" and self.role ~= "loyalist" and process:match("loyal"))
end
