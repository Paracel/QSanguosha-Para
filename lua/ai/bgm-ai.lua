sgs.ai_skill_invoke.chongzhen = function(self, data)
	local target = data:toPlayer()
	if self:isFriend(target) then
		return target:hasSkill("kongcheng") and target:getHandcardNum() == 1
	else
		return not (target:hasSkill("kongcheng") and target:getHandcardNum() == 1 and target:getEquips():isEmpty())
	end
end

local lihun_skill = {}
lihun_skill.name = "lihun"
table.insert(sgs.ai_skills, lihun_skill)
lihun_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("LihunCard") or self.player:isNude() then return end
	local card_id
	if (self:isEquip("SilverLion") and self.player:isWounded()) or self:evaluateArmor() < -5 then
		return sgs.Card_Parse("@LihunCard=" .. self.player:getArmor():getId())
	elseif self.player:getHandcardNum() > self.player:getHp() then
		local cards = self.player:getHandcards()
		cards = sgs.QList2Table(cards)

		for _, acard in ipairs(cards) do
			if (acard:getTypeId() ~= sgs.Card_TypeTrick or acard:isKindOf("AmazingGrace"))
				and not acard:isKindOf("Peach") then
				card_id = acard:getEffectiveId()
				break
			end
		end
	elseif not self.player:getEquips():isEmpty() then
		local player = self.player
		if player:getWeapon() then card_id = player:getWeapon():getId()
		elseif player:getOffensiveHorse() then card_id = player:getOffensiveHorse():getId()
		elseif player:getDefensiveHorse() then card_id = player:getDefensiveHorse():getId()
		elseif player:getArmor() and player:getHandcardNum() <= 1 then card_id = player:getArmor():getId()
		end
	end
	if not card_id then
		cards = sgs.QList2Table(self.player:getHandcards())
		for _, acard in ipairs(cards) do
			if (acard:getTypeId() ~= sgs.Card_TypeTrick or acard:isKindOf("AmazingGrace"))
				and not acard:isKindOf("Peach") then
				card_id = acard:getEffectiveId()
				break
			end
		end
	end
	if not card_id then
		return nil
	else
		return sgs.Card_Parse("@LihunCard=" .. card_id)
	end
end

sgs.ai_skill_use_func.LihunCard = function(card, use, self)
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)

	if not self.player:hasUsed("LihunCard") then
		self:sort(self.enemies, "hp")
		local target
		for _, enemy in ipairs(self.enemies) do
			if enemy:isMale() and not enemy:hasSkill("kongcheng") then
				if (enemy:hasSkill("lianying") and self:damageMinusHp(self, enemy, 1) > 0)
					or (enemy:getHp() < 3 and self:damageMinusHp(self, enemy, 0) > 0 and enemy:getHandcardNum() > 0)
					or (enemy:getHandcardNum() >= enemy:getHp() and enemy:getHp() > 2 and self:damageMinusHp(self, enemy, 0) >= -1)
					or (enemy:getHandcardNum() - enemy:getHp() > 2) then
					target = enemy
					break
				end
			end
		end
		if not self.player:faceUp() and not target then
			for _, enemy in ipairs(self.enemies) do
				if enemy:isMale() then
					if enemy:getHandcardNum() >= enemy:getHp() then
						target = enemy
						break
					end
				end
			end
		end

		if target then
			use.card = card
			if use.to then use.to:append(target) end
		end
	end
end

sgs.ai_skill_discard.lihun = function(self, discard_num, min_num, optional, include_equip)
	local to_discard = {}

	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
	local card_ids = {}
	for _, card in ipairs(cards) do
		table.insert(card_ids, card:getEffectiveId())
	end

	local temp = table.copyFrom(card_ids)
	for i = 1, #temp, 1 do
		local card = sgs.Sanguosha:getCard(temp[i])
		if (self:isEquip("SilverLion") and self.player:isWounded()) and card:isKindOf("SilverLion") then
			table.insert(to_discard, temp[i])
			table.removeOne(card_ids, temp[i])
			if #to_discard == discard_num then
				return to_discard
			end
		end
	end

	temp = table.copyFrom(card_ids)

	for i = 1, #card_ids, 1 do
		local card = sgs.Sanguosha:getCard(card_ids[i])
		table.insert(to_discard, card_ids[i])
		if #to_discard == discard_num then
			return to_discard
		end
	end

	if #to_discard < discard_num then return {} end
end

sgs.ai_use_value.LihunCard = 8.5
sgs.ai_use_priority.LihunCard = 6

function sgs.ai_skill_invoke.kuiwei(self, data)
	local weapon = 0
	if not self.player:faceUp() then return true end
	for _, friend in ipairs(self.friends) do
		if self:hasSkills("fangzhu|jilve", friend) then return true end
	end
	for _, aplayer in sgs.qlist(self.room:getAlivePlayers()) do
		if aplayer:getWeapon() then weapon = weapon + 1 end
	end
	if weapon > 1 then return true end
	return self:isWeak()
end

sgs.ai_view_as.yanzheng = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card_place == sgs.Player_PlaceEquip and player:getHandcardNum() > player:getHp() then
		return ("nullification:yanzheng[%s:%s]=%d"):format(suit, number, card_id)
	end
end

sgs.ai_chaofeng.bgm_pangtong = 10

sgs.ai_skill_invoke.manjuan = true
sgs.ai_skill_invoke.zuixiang = true

sgs.ai_skill_askforag.manjuan = function(self, card_ids)
	local cards = {}
	for _, card_id in ipairs(card_ids) do
		table.insert(cards, sgs.Sanguosha:getCard(card_id))
	end
	for _, card in ipairs(cards) do
		if card:isKindOf("ExNihilo") then return card:getEffectiveId() end
		if card:isKindOf("IronChain") then return card:getEffectiveId() end
	end
	for _, card in ipairs(cards) do
		if card:isKindOf("Snatch") then
			self:sort(self.enemies,"defense")
			if sgs.getDefense(self.enemies[1]) >= 8 then self:sort(self.enemies, "threat") end
			local enemies = self:exclude(self.enemies, card)
			for _, enemy in ipairs(enemies) do
				if self:hasTrickEffective(card, enemy) then
					return card:getEffectiveId()
				end
			end
		end
	end
	for _, card in ipairs(cards) do
		if card:isKindOf("Peach") and self.player:isWounded() and self:getCardsNum("Peach") < self.player:getLostHp() then return card:getEffectiveId() end
	end
	for _, card in ipairs(cards) do
		if card:isKindOf("AOE") and self:getAoeValue(card) > 0 then return card:getEffectiveId() end
	end
	self:sortByCardNeed(cards)
	return cards[#cards]:getEffectiveId()
end

local dahe_skill = {}
dahe_skill.name = "dahe"
table.insert(sgs.ai_skills, dahe_skill)
dahe_skill.getTurnUseCard = function(self)
	if not self.player:hasUsed("DaheCard") and not self.player:isKongcheng() then return sgs.Card_Parse("@DaheCard=.") end
end

sgs.ai_skill_use_func.DaheCard = function(card, use, self)
	self:sort(self.enemies, "handcard")
	local max_card = self:getMaxCard(self.player)
	local max_point = max_card:getNumber()
	local slashcount = self:getCardsNum("Slash")
	if max_card:isKindOf("Slash") then slashcount = slashcount - 1 end
	if self.player:hasSkill("kongcheng") and self.player:getHandcardNum() == 1 then
		for _, enemy in ipairs(self.enemies) do
			if not enemy:isKongcheng() then
				use.card = sgs.Card_Parse("@DaheCard=" .. max_card:getId())
				if use.to then use.to:append(enemy) end
				return
			end
		end
	end
	if slashcount > 0 then
		local slash = self:getCard("Slash")
		assert(slash)
		local dummy_use = { isDummy = true }
		self:useBasicCard(slash, dummy_use)
		for _, enemy in ipairs(self.enemies) do
			if not (enemy:hasSkill("kongcheng") and enemy:getHandcardNum() == 1 and enemy:getHp() > self.player:getHp())
				and not enemy:isKongcheng() and self.player:canSlash(enemy, nil, true) then
				local enemy_max_card = self:getMaxCard(enemy)
				local allknown = 0
				if self:getKnownNum(enemy) == enemy:getHandcardNum() then
					allknown = allknown + 1
				end
				if (enemy_max_card and max_point > enemy_max_card:getNumber() and allknown > 0)
					or (enemy_max_card and max_point > enemy_max_card:getNumber() and allknown < 1 and max_point > 10)
					or (not enemy_max_card and max_point > 10) then
					use.card = sgs.Card_Parse("@DaheCard=" .. max_card:getId())
					if use.to then use.to:append(enemy) end
					return
				end
			end
		end
	end
end

function sgs.ai_skill_pindian.dahe(minusecard, self, requestor)
	if self:isFriend(requestor) then return minusecard end
	return self:getMaxCard(self.player):getId()
end

sgs.ai_skill_choice.dahe = function(self, choices)
	return "yes"
end

sgs.ai_skill_playerchosen.dahe = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
	for _, target in ipairs(targets) do
		if target:hasSkill("kongcheng") and target:isKongcheng()
			and target:hasFlag("dahe") then
			return target
		end
	end
	for _, target in ipairs(targets) do
		if self:isFriend(target) then return target end
	end
end

sgs.ai_cardneed.dahe = sgs.ai_cardneed.bignumber

sgs.ai_card_intention.DaheCard = 60

sgs.dynamic_value.control_card.DaheCard = true

sgs.ai_use_value.DaheCard = 8.5
sgs.ai_use_priority.DaheCard = 8

local tanhu_skill = {}
tanhu_skill.name = "tanhu"
table.insert(sgs.ai_skills, tanhu_skill)
tanhu_skill.getTurnUseCard = function(self)
	if not self.player:hasUsed("TanhuCard") and not self.player:isKongcheng() then
		local max_card = self:getMaxCard()
		return sgs.Card_Parse("@TanhuCard=" .. max_card:getEffectiveId())
	end
end

sgs.ai_skill_use_func.TanhuCard = function(card, use, self)
	local max_card = self:getMaxCard()
	local max_point = max_card:getNumber()
	local ptarget = self:getPriorTarget()
	local slashcount = self:getCardsNum("Slash")
	if max_card:isKindOf("Slash") then slashcount = slashcount - 1 end
	if not ptarget:isKongcheng() and slashcount > 0 and self.player:canSlash(ptarget, nil, true)
	and not ptarget:hasSkill("kongcheng") and ptarget:getHandcardNum() == 1 then
		local card_id = max_card:getEffectiveId()
		local card_str = "@TanhuCard=" .. card_id
		if use.to then
			use.to:append(ptarget)
		end
		use.card = sgs.Card_Parse(card_str)
		return
	end
	self:sort(self.enemies, "defense")

	for _, enemy in ipairs(self.enemies) do
		if self:getCardsNum("Snatch") > 0 and not enemy:isKongcheng() then
			local enemy_max_card = self:getMaxCard(enemy)
			local allknown = 0
			if self:getKnownNum(enemy) == enemy:getHandcardNum() then
				allknown = allknown + 1
			end
			if (enemy_max_card and max_point > enemy_max_card:getNumber() and allknown > 0)
				or (enemy_max_card and max_point > enemy_max_card:getNumber() and allknown < 1 and max_point > 10)
				or (not enemy_max_card and max_point > 10)
				and (self:getDangerousCard(enemy) or self:getValuableCard(enemy)) then
					local card_id = max_card:getEffectiveId()
					local card_str = "@TanhuCard=" .. card_id
					use.card = sgs.Card_Parse(card_str)
					if use.to then use.to:append(enemy)	end
					return
			end
		end
	end
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards, true)
	if self:getUseValue(cards[1]) >= 6 or self:getKeepValue(cards[1]) >= 6 then return end
	if self:getOverflow() > 0 then
		if not ptarget:isKongcheng() then
			local card_id = max_card:getEffectiveId()
			local card_str = "@TanhuCard=" .. card_id
			if use.to then
				use.to:append(ptarget)
			end
			use.card = sgs.Card_Parse(card_str)
			return
		end
		for _, enemy in ipairs(self.enemies) do
			if not (enemy:hasSkill("kongcheng") and enemy:getHandcardNum() == 1) and not enemy:isKongcheng() and not enemy:hasSkill("tuntian") then
				use.card = sgs.Card_Parse("@TanhuCard=" .. cards[1]:getId())
				if use.to then use.to:append(enemy) end
				return
			end
		end
	end
end

sgs.ai_cardneed.tanhu = sgs.ai_cardneed.bignumber
sgs.ai_card_intention.TanhuCard = 30
sgs.dynamic_value.control_card.TanhuCard = true
sgs.ai_use_priority.TanhuCard = 8

sgs.ai_skill_invoke.mouduan = function(self, data)
	local cardsCount = self.player:getHandcardNum()
	if cardsCount <= 3 then return false end
	local current = self.room:getCurrent()
	if current:objectName() == self.player:objectName() then
		if self:isEquip("Crossbow") or self:getCardsNum("Crossbow") > 0 and self:getCardsNum("Slash") >= 3 then
			local hasTarget = false
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuitNoColor, 0)
			for _, enemy in ipairs(self.enemies) do
				if not self:slashProhibit(slash, enemy) and self:slashIsEffective(slash, enemy) and sgs.isGoodTarget(enemy, self.enemies) then
					hasTarget = true
					break
				end
			end
			return hasTarget
		end
	elseif (cardsCount == 4 or cardsCount == 5) and #self.enemies > 1 then
		return true
	end
	return false
end

sgs.ai_skill_invoke.zhaolie = function(self, data)
	local enemynum = 0
	for _, enemy in ipairs(self.enemies) do
		if self.player:distanceTo(enemy) <= self.player:getAttackRange() then
			enemynum = enemynum + 1
		end
	end
	return enemynum > 0
end

sgs.ai_skill_playerchosen.zhaolie = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "hp")
	for _, target in ipairs(targets) do
		if self:isEnemy(target) then
			return target
		end
	end
	return targets[1]
end

sgs.ai_skill_choice.zhaolie = function(self, choices, data)
	local nobasic = data:toInt()
	if self.player:hasSkill("manjuan") then	return "throw" end
	if nobasic == 0 then return "damage" end
	if nobasic < 2 and self.player:getHp() > 1 then	return "damage" else return "throw" end
end

sgs.ai_skill_discard.zhaolie = function(self, discard_num, min_num, optional, include_equip)
	local to_discard = {}
	local cards = sgs.QList2Table(self.player:getCards("he"))
	local index = 0

	self:sortByKeepValue(cards)
	cards = sgs.reverse(cards)

	for i = #cards, 1, -1 do
		local card = cards[i]
		if not self.player:isJilei(card) then
			table.insert(to_discard, card:getEffectiveId())
			table.remove(cards, i)
			index = index + 1
			if index == discard_num then break end
		end
	end
	if #to_discard < min_num then return {} else return to_discard end
end

sgs.ai_skill_invoke.shichou = function(self, data)
	local enemynum = 0
	local shu = 0
	local first = self.player:hasFlag("FirstRound")
	local players = self.room:getOtherPlayers(self.player)
	local shenguanyu = self.room:findPlayerBySkillName("wuhun");
	if shenguanyu ~= nil then
		if shenguanyu:getKingdom() == "shu" then return true end
	end
	for _, player in sgs.qlist(players) do
		if player:getKingdom() == "shu" then
			shu = shu + 1
			if self:isEnemy(player) then enemynum = enemynum + 1 end
		end
	end
	if first and shu > 1 then return false end
	return true
end

sgs.ai_skill_playerchosen.shichou = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "hp", true)
	if self.player:hasSkill("weidi") and self.player:getRole() == "rebel" then
		for _, target in ipairs(targets) do
			if target:hasLordSkill("shichou") then return target end
		end
	end
	for _, target in ipairs(targets) do
		if target:hasSkill("wuhun") then return target end
	end
	for _, target in ipairs(targets) do
		if target:hasSkill("guixin") and self:isFriend(target) and self.player:aliveCount() > 3 then return target end
	end
	for _, target in ipairs(targets) do
		if self:isEnemy(target) then return target end
	end
	for _, target in ipairs(targets) do
		if self:hasSkills("zaiqi|nosenyuan|kuanggu|enyuan|shushen", target) and target:getHp() >= 2 then
			return target
		end
	end
	return targets[1]
end

sgs.ai_need_damaged.shichou = function (self, attacker)
	local player = self.player
	if player:hasLordSkill("shichou") then
		local victim
		for _, p in sgs.qlist(self.room:getOtherPlayers(player)) do
			if p:getMark("@hate_" .. player:objectName()) > 0 and p:getMark("@hate_to") > 0 then
				victim = p
				break
			end
		end
		if victim ~= nil then
			local role
			if sgs.isRolePredictable() and sgs.evaluatePlayerRole(player) == "rebel" or sgs.compareRoleEvaluation(player, "rebel", "loyalist") == "rebel" then
				role = "rebel"
			end
			local need_damage = false
			if (self.player:getRole() == "loyalist" or self.player:isLord()) and role == "rebel" then need_damage = true end
			if self.player:getRole() == "rebel" and role ~= "rebel" then need_damage = true end
			if self.player:getRole() == "renegade" then need_damage = true end
			if victim:isAlive() and need_damage then
				return victim:hasSkill("wuhun") and 2 or 1
			end
		end
	end
	return false
end

sgs.ai_skill_discard.shichou = sgs.ai_skill_discard.lihun

function SmartAI:useCardYanxiaoCard(card, use)
	local players = self.room:getOtherPlayers(self.player)
	local tricks
	for _, friend in ipairs(self.friends_noself) do
		local judges = friend:getJudgingArea()
		if not judges:isEmpty() and not friend:containsTrick("YanxiaoCard") then
			use.card = card
			if use.to then use.to:append(friend) end
			return
		end
	end
	self:sort(self.friends, "defense")
	for _, friend in ipairs(self.friends) do
		if not friend:containsTrick("YanxiaoCard") then
			use.card = card
			if use.to then use.to:append(friend) end
			return
		end
	end
end

sgs.ai_use_priority.YanxiaoCard = 3.9
sgs.ai_card_intention.YanxiaoCard = -80

local yanxiao_skill = {}
yanxiao_skill.name = "yanxiao"
table.insert(sgs.ai_skills, yanxiao_skill)
yanxiao_skill.getTurnUseCard = function(self)
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	local diamond_card
	self:sortByUseValue(cards, true)

	for _, card in ipairs(cards) do
		if card:getSuit() == sgs.Card_Diamond then
			diamond_card = card
			break
		end
	end

	if diamond_card then
		local suit = diamond_card:getSuitString()
		local number = diamond_card:getNumberString()
		local card_id = diamond_card:getEffectiveId()
		local card_str = ("YanxiaoCard:yanxiao[%s:%s]=%d"):format(suit, number, card_id)
		local yanxiaocard = sgs.Card_Parse(card_str)
		assert(yanxiaocard)
		return yanxiaocard
	end
end

sgs.ai_skill_invoke.anxian = function(self, data)
	local damage = data:toDamage()
	local target = damage.to
	if self:isFriend(target) and not self:hasSkills(sgs.masochism_skill, target) then return true end
	if self:isEnemy(target) and self:hasSkills(sgs.masochism_skill, target) then return true end
	if damage.damage > 1 then return false end
	return false
end

sgs.ai_skill_cardask["@anxian-discard"] = function(self, data)
	local use = data:toCardUse()
	if self:getCardsNum("Jink") > 0 or self.player:isKongcheng() or not self:slashIsEffective(use.card, self.player) then return "." end
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	return "$" .. cards[1]:getEffectiveId()
end

local yinling_skill = {}
yinling_skill.name = "yinling"
table.insert(sgs.ai_skills, yinling_skill)
yinling_skill.getTurnUseCard = function(self, inclusive)
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards, true)
	local black_card
	local has_weapon = false

	for _, card in ipairs(cards) do
		if card:isKindOf("Weapon") and card:isBlack() then has_weapon = true end
	end

	for _, card in ipairs(cards) do
		if card:isBlack() and ((self:getUseValue(card) < sgs.ai_use_value.YinlingCard) or inclusive or self:getOverflow() > 0) then
			local shouldUse = true

			if card:isKindOf("Armor") then
				if not self.player:getArmor() then shouldUse = false
				elseif self:hasEquip(card) and not (card:isKindOf("SilverLion") and self.player:isWounded()) then shouldUse = false
				end
			end

			if card:isKindOf("Weapon") then
				if not self.player:getWeapon() then shouldUse = false
				elseif self:hasEquip(card) and not has_weapon then shouldUse = false
				end
			end

			if card:isKindOf("Slash") then
				local dummy_use = { isDummy = true }
				if self:getCardsNum("Slash") == 1 then
					self:useBasicCard(card, dummy_use)
					if dummy_use.card then shouldUse = false end
				end
			end

			if self:getUseValue(card) > sgs.ai_use_value.YinlingCard and card:isKindOf("TrickCard") then
				local dummy_use = { isDummy = true }
				self:useTrickCard(card, dummy_use)
				if dummy_use.card then shouldUse = false end
			end

			if shouldUse then
				black_card = card
				break
			end
		end
	end

	if black_card then
		local card_id = black_card:getEffectiveId()
		local card_str = ("@YinlingCard=" .. card_id)
		local yinling = sgs.Card_Parse(card_str)
		assert(yinling)
		return yinling
	end
end

sgs.ai_skill_use_func.YinlingCard = function(card, use, self)
	if self.player:getPile("brocade"):length() >= 4 then return end
	local players = self.room:getOtherPlayers(self.player)
	players = self:exclude(players, card)

	self:sort(self.enemies, "defenseSlash")
	local enemies = self:exclude(self.enemies, card)
	self:sort(self.friends_noself,"defense")
	local friends = self:exclude(self.friends_noself, card)
	local hasLion, target
	for _, enemy in ipairs(enemies) do
		if not enemy:isNude() then
			if self:getDangerousCard(enemy) then
				use.card = card
				if use.to then
					sgs.ai_skill_cardchosen.yinling = self:getDangerousCard(enemy)
					use.to:append(enemy)
					self:speak("hostile", self.player:isFemale())
				end
				return
			end
		end
	end

	for _, friend in ipairs(friends) do
		if self:isEquip("SilverLion", friend) and
		friend:isWounded() and not self:hasSkills("longhun|duanliang|qixi|guidao|lijian|jujian", friend) then
			hasLion = true
			target = friend
		end
	end

	for _, enemy in ipairs(enemies) do
		if not enemy:isNude() then
			if self:getValuableCard(enemy) then
				use.card = card
				if use.to then
					sgs.ai_skill_cardchosen.yinling = self:getValuableCard(enemy)
					use.to:append(enemy)
					self:speak("hostile", self.player:isFemale())
				end
				return
			end
		end
	end

	for _, enemy in ipairs(enemies) do
		local cards = sgs.QList2Table(enemy:getHandcards())
		local flag = string.format("%s_%s_%s","visible", self.player:objectName(), enemy:objectName())
		if #cards <= 2 and not enemy:isKongcheng() then
			for _, cc in ipairs(cards) do
				if (cc:hasFlag("visible") or cc:hasFlag(flag)) and (cc:isKindOf("Peach") or cc:isKindOf("Analeptic")) then
					use.card = card
					if use.to then
						sgs.ai_skill_cardchosen.yinling = self:getCardRandomly(enemy, "h")
						use.to:append(enemy)
						self:speak("hostile", self.player:isFemale())
					end
					return
				end
			end
		end
	end

	for _, enemy in ipairs(enemies) do
		if not enemy:isNude() then
			if self:hasSkills("jijiu|dimeng|guzheng|qiaobian|jieyin|lijian|beige", enemy) or (enemy:hasSkill("miji") and enemy:isWounded()) then
				local cardchosen = self:getValuableCard(enemy)
				local gethandcard
				if cardchosen then
					local card = sgs.Sanguosha:getCard(cardchosen)
					local isDefenseCard = card:isKindOf("Armor") or card:isKindOf("DefensiveHorse")
					if enemy:hasSkill("jijiu") and (not isDefenseCard or not card:isRed()) then
						gethandcard = true
					elseif enemy:hasSkill("beige") then
						gethandcard = false
					elseif not isDefenseCard then
						gethandcard = true
					end
				end

				if not enemy:isKongcheng() and gethandcard then cardchosen = self:getCardRandomly(enemy, "h") end
				if not cardchosen then cardchosen = self:getCardRandomly(enemy, "he") end
				use.card = card
				if use.to then
					sgs.ai_skill_cardchosen.yinling = cardchosen
					use.to:append(enemy)
					self:speak("hostile", self.player:isFemale())
				end
				return
			end
		end
	end

	for i = 1, 2, 1 do
		for _, enemy in ipairs(enemies) do
			if not enemy:isNude()
				and not self:needKongcheng(enemy) and not self:hasSkills("kongcheng|lianying|shangshi|nosshangshi", enemy) then
				if enemy:getHandcardNum() == i and sgs.getDefenseSlash(enemy) < 3 and enemy:getHp() <= 3 then
					local cardchosen
					if self.player:distanceTo(enemy) == self.player:getAttackRange() + 1 and enemy:getDefensiveHorse() then
						cardchosen = enemy:getDefensiveHorse():getEffectiveId()
					elseif enemy:getArmor() and enemy:getArmor():isKindOf("EightDiagram") then
						cardchosen = enemy:getArmor():getEffectiveId()
					else
						cardchosen = self:getCardRandomly(enemy, "h")
					end
					use.card = card
					if use.to then
						sgs.ai_skill_cardchosen.yinling = cardchosen
						use.to:append(enemy)
						self:speak("hostile", self.player:isFemale())
					end
					return
				end
			end
		end
	end

	if hasLion then
		use.card = card
		if use.to then
			sgs.ai_skill_cardchosen.yinling = target:getArmor():getEffectiveId()
			use.to:append(target)
		end
		return
	end

	for _, enemy in ipairs(enemies) do
		if not enemy:isKongcheng() and (enemy:getHandcardNum() > enemy:getHp() - 2 or (enemy:getHandcardNum() == 1 and not self:needKongcheng(enemy))) then
			use.card = card
			if use.to then
				sgs.ai_skill_cardchosen.yinling = enemy:getRandomHandCardId()
				use.to:append(enemy)
			end
			return
		end
	end
	return
end

sgs.ai_use_value.YinlingCard = sgs.ai_use_value.Dismantlement + 1
sgs.ai_use_priority.YinlingCard = sgs.ai_use_priority.Dismantlement + 1
sgs.ai_card_intention.YinlingCard = sgs.ai_card_intention.Dismantlement

sgs.ai_skill_invoke.junwei = function(self, data)
	return #self.enemies > 0
end

sgs.ai_skill_playerchosen.junwei = function(self, targets)
	local tos = {}
	for _, target in sgs.qlist(targets) do
		if self:isEnemy(target) and not (self:isEquip("SilverLion", target) and target:getCards("e"):length() == 1)then
			table.insert(tos, target)
		end
	end

	if #tos > 0 then
		self:sort(tos, "defense")
		return tos[1]
	end
end

sgs.ai_skill_playerchosen.junweigive = function(self, targets)
	local tos = {}
	for _, target in sgs.qlist(targets) do
		if self:isFriend(target) and not target:hasSkill("manjuan") and not (target:hasSkill("kongcheng") and target:isKongcheng()) then
			table.insert(tos, target)
		end
	end

	if #tos > 0 then
		self:sort(tos, "defense")
		return tos[1]
	end
end

sgs.ai_skill_cardask["@junwei-show"] = function(self, data)
	local ganning = data:toPlayer()
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	for _, card in ipairs(cards) do
		if card:isKindOf("Jink") then
			return "$" .. card:getEffectiveId()
		end
	end
	return "."
end

sgs.bgm_ganning_suit_value = {
	spade = 3.9,
	club = 3.9
}

sgs.ai_skill_invoke.fenyong = function(self, data)
	return true
end

function sgs.ai_slash_prohibit.fenyong(self, to)
	return to:getMark("@fenyong") > 0 and to:hasSkill("fenyong")
end

sgs.ai_skill_choice.xuehen = function(self, choices)
	local current = self.room:getCurrent();
	self:sort(self.enemies, "defenseSlash")
	for _, enemy in ipairs(self.enemies) do
		local def = sgs.getDefense(enemy)
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuitNoColor, 0)
		local eff = self:slashIsEffective(slash, enemy) and sgs.isGoodTarget(enemy, self.enemies)

		if self.player:canSlash(enemy, nil, false) and not self:slashProhibit(nil, enemy) and eff and def < 8 then
			self.room:setPlayerFlag(enemy, "XuehenToChoose")
			return "slash"
		end
	end
	if self:isFriend(current) then
		for _, enemy in ipairs(self.enemies) do
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuitNoColor, 0)
			local eff = self:slashIsEffective(slash, enemy)

			if self.player:canSlash(enemy, nil , false) and not self:slashProhibit(nil, enemy) then
				self.room:setPlayerFlag(enemy, "XuehenToChoose")
				return "slash"
			end
		end
	end
	return "discard"
end

sgs.ai_skill_playerchosen.xuehen = function(self, targets)
	targets = sgs.QList2Table(targets)
	for _, enemy in ipairs(targets) do
		if enemy:hasFlag("XuehenToChoose") then
			self.room:setPlayerFlag(enemy, "-XuehenToChoose")
			return enemy
		end
	end
	for _, p in sgs.qlist(self.room:getAllPlayers()) do
		if p:hasFlag("XuehenToChoose") then
			self.room:setPlayerFlag(p, "-XuehenToChoose")
		end
	end
end

--AI for DIY generals
sgs.ai_skill_invoke.zhaoxin = function(self, data)
	local target
	self:sort(self.enemies,"defenseSlash")
	for _, enemy in ipairs(self.enemies) do
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuitNoColor, 0)
		local eff = self:slashIsEffective(slash, enemy) and sgs.isGoodTarget(enemy, self.enemies)
		if eff and self.player:canSlash(enemy) and not self:slashProhibit(nil, enemy) then
			sgs.ai_skill_playerchosen.zhaoxin = enemy
			return true
		end
	end
	return false
end

sgs.ai_skill_invoke.langgu = function(self, data)
	local damage = data:toDamage()
	return not self:isFriend(damage.from)
end

sgs.ai_skill_askforag.langgu = function(self, card_ids)
	return -1
end

sgs.ai_skill_cardask["@langgu-card"]=function(self, data)
	local judge = data:toJudge()

	if self.player:hasFlag("langgu_hongyan") and judge.card:getSuit() ~= sgs.Card_Heart then
		local cards = sgs.QList2Table(self.player:getHandcards())
		for _, card in ipairs(cards) do
			if card:getSuit() == sgs.Card_Heart then
				return "@LangguCard[" .. card:getSuitString() .. ":" .. card:getNumberString() .. "]=" .. card:getId()
			end
		end
		if judge.card:getSuit() == sgs.Card_Spade then
			self:sortByKeepValue(cards)
			local card = cards[1]
			return "@LangguCard[" .. card:getSuitString() .. ":" .. card:getNumberString() .. "]=" .. card:getId()
		end
	end

	return "."
end

local fuluan_skill = {}
fuluan_skill.name = "fuluan"
table.insert(sgs.ai_skills, fuluan_skill)
fuluan_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("FuluanCard") or self.player:hasFlag("ForbidFuluan") then return end
	local first_found, second_found, third_found = false, false, false
	local first_card, second_card, third_card
	if self.player:getCards("he"):length() >= 3 then
		local cards = self.player:getCards("he")
		local same_suit = false
		cards = sgs.QList2Table(cards)
		for _, fcard in ipairs(cards) do
			if not (fcard:isKindOf("Peach") or fcard:isKindOf("ExNihilo")) then
				first_card = fcard
				first_found = true
				for _, scard in ipairs(cards) do
					if first_card ~= scard and scard:getSuitString() == first_card:getSuitString() and
						not (scard:isKindOf("Peach") or scard:isKindOf("ExNihilo")) then
						second_card = scard
						second_found = true
						for _, tcard in ipairs(cards) do
							if first_card ~= tcard and second_card ~= tcard and tcard:getSuitString() == first_card:getSuitString() and
								not (tcard:isKindOf("Peach") or tcard:isKindOf("ExNihilo")) then
								third_card = tcard
								third_found = true
								break
							end
						end
					end
					if third_found then break end
				end
			end
			if third_found and second_found then break end
		end
	end

	if first_found and second_found and third_found then
		local card_str = ("@FuluanCard=%d+%d+%d"):format(first_card:getId(), second_card:getId(), third_card:getId())
		assert(card_str)
		return sgs.Card_Parse(card_str)
	end
end

local function can_be_selected_as_target_fuluan(self, card, who)
	local subcards = card:getSubcards()
	if self.player:getWeapon() and subcards:contains(self.player:getWeapon():getId()) then
		local distance_fix = sgs.weapon_range[self.player:getWeapon():getClassName()] - 1
		if self.player:getOffensiveHorse() and subcards:contains(self.player:getOffensiveHorse():getId()) then
			distance_fix = distance_fix + 1
		end
		return self.player:distanceTo(enemy, distance_fix) <= self.player:getAttackRange()
	elseif self.player:getOffensiveHorse() and subcards:contains(self.player:getOffensiveHorse():getId()) then
		return self.player:distanceTo(enemy, 1) <= self.player:getAttackRange()
	elseif self.player:inMyAttackRange(enemy) then
		return true
	end
	return false
end

sgs.ai_skill_use_func.FuluanCard = function(card, use, self)
	local subcards = card:getSubcards()
	self:sort(self.friends_noself)
	for _, friend in ipairs(self.friends_noself) do
		if not friend:faceUp() then
			if can_be_selected_as_target_fuluan(self, card, friend) then
				use.card = card
				if use.to then use.to:append(friend) end
				return
			end
		end
	end
	self:sort(self.enemies, "defense")
	for _, enemy in ipairs(self.enemies) do
		if enemy:faceUp() then
			if can_be_selected_as_target_fuluan(self, card, enemy) then
				use.card = card
				if use.to then use.to:append(enemy) end
				return
			end
		end
	end
end

sgs.ai_use_priority.FuluanCard = 2.3

local function need_huangen(self, who)
	local card = sgs.Card_Parse(self.player:getTag("Huangen_user"):toString())
	if card == nil then return false end
	if self:isEnemy(who) then
		if card:isKindOf("GodSalvation") and who:getLostHp() > 0 and (who:getHp() <= 0 or who:hasSkill("manjuan")) then
			return true
		end
		return false
	else
		if self:hasSkills("wuyan", who) and self.getCurrent() ~= who then return true end
		if card:isKindOf("GodSalvation") and who:isWounded() then return false end
		if card:isKindOf("IronChain") and who:isChained() then return false end
		return true
	end
end

sgs.ai_skill_use["@@huangen"] = function(self, prompt)
	local card = sgs.Sanguosha:getCard(self.player:getTag("Huangen_user"):toInt())
	if card:isKindOf("AmazingGrace") then return "." end
	local first_index, second_index, third_index, forth_index, fifth_index
	local i = 1
	local players = sgs.QList2Table(self.room:getAllPlayers())
	for _, player in ipairs(players) do
		if player:hasFlag("HuangenTarget") then
			if not first_index and need_huangen(self, player) then
				first_index = i
			elseif not second_index and need_huangen(self, player) then
				second_index = i
			elseif not third_index and need_huangen(self, player) then
				third_index = i
			elseif not forth_index and need_huangen(self, player) then
				forth_index = i
			elseif need_huangen(self, player) then
				fifth_index = i
			end
			if fifth_index then break end
		end
		i = i + 1
	end
	if not first_index then return "." end
	
	local first, second, third, forth, fifth
	if first_index then
		first = players[first_index]:objectName()
	end
	if second_index then
		second = players[second_index]:objectName()
	end
	if third_index then
		third = players[third_index]:objectName()
	end
	if forth_index then
		forth = players[forth_index]:objectName()
	end
	if fifth_index then
		fifth = players[fifth_index]:objectName()
	end

	local hp = self.player:getHp()
	if fifth_index and hp >= 5 then
		return ("@HuangenCard=.->%s+%s+%s+%s+%s"):format(first, second, third, forth, fifth)
	elseif forth_index and hp >= 4 then
		return ("@HuangenCard=.->%s+%s+%s+%s"):format(first, second, third, forth)
	elseif third_index and hp >= 3 then
		return ("@HuangenCard=.->%s+%s+%s"):format(first, second, third)
	elseif second_index and hp >= 2 then
		return ("@HuangenCard=.->%s+%s"):format(first, second)
	elseif first_index and hp >= 1 then
		return ("@HuangenCard=.->%s"):format(first)
	end
end

sgs.ai_card_intention.HuangenCard = -50

sgs.ai_skill_invoke.hantong = true

sgs.ai_skill_invoke.hantong_acquire = function(self, data)
	local skill = data:toString()
	if skill == "hujia" and not self.player:hasSkill("hujia") then
		local can_invoke = false
		for _, friend in ipairs(self.friends_noself) do
			if friend:getKingdom() == "wei" then can_invoke = true end
		end
		if can_invoke then return sgs.ai_skill_invoke.hujia end
	elseif skill == "jijiang" and not self.player:hasSkill("jijiang") then
		local can_invoke = false
		for _, friend in ipairs(self.friends_noself) do
			if friend:getKingdom() == "shu" then can_invoke = true end
		end
		if can_invoke then return sgs.ai_skill_invoke.jijiang end
	elseif skill == "jiuyuan" and not self.player:hasSkill("jiuyuan") then
		return true
	elseif skill == "xueyi" and not self.player:hasSkill("xueyi") then
		local maxcards = self.player:getMaxCards()
		local can_invoke = false
		for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if player:getKingdom() == "qun" then can_invoke = true end
		end
		if can_invoke then return self.player:getHandcardNum() > maxcards end
	end
	return false
end

local hantong_skill = {}
hantong_skill.name = "hantong"
table.insert(sgs.ai_skills, hantong_skill)
hantong_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("HantongCard") or not self:slashIsAvailable() then return end
	local can_invoke = false
	for _, friend in ipairs(self.friends_noself) do
		if friend:getKingdom() == "shu" then can_invoke = true end
	end
	if not can_invoke then return end
	return sgs.Card_Parse("@HantongCard=.")
end

sgs.ai_skill_use_func.HantongCard = function(card, use, self)
	self:sort(self.enemies, "defenseSlash")
	for _, enemy in ipairs(self.enemies) do
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuitNoColor, 0)
		local eff = self:slashIsEffective(slash, enemy) and sgs.isGoodTarget(enemy, self.enemies)
		if eff and self.player:canSlash(enemy) and not self:slashProhibit(nil, enemy) then
			use.card = card
		end
	end
end

sgs.ai_skill_use["@@diyyicong"] = function(self, prompt)
	local yicongcards = {}
	local cards = self.player:getCards("he")
	if self:isEquip("SilverLion") and self.player:isWounded() then
		table.insert(yicongcards, self.player:getArmor():getId())
	end
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	for _, card in ipairs(cards) do
		if self:getKeepValue(card) < 6
			and (not self.player:getArmor() or card:getId() ~= self.player:getArmor():getEffectiveId())
			and (not self.player:getDefensiveHorse() or card:getId() ~= self.player:getDefensiveHorse():getEffectiveId()) then
			table.insert(yicongcards, card:getId())
			break
		end
	end
	if #yicongcards > 0 then
		return "@DIYYicongCard=" .. table.concat(yicongcards, "+") .. "->."
	end
	return "."
end
