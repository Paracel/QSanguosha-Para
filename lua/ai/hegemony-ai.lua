if sgs.GetConfig("EnableHegemony", false) then
	local init = SmartAI.initialize
	function SmartAI:initialize(player)
		if not sgs.initialized then
			for _, aplayer in sgs.qlist(player:getRoom():getAllPlayers()) do
				sgs.ai_explicit[aplayer:objectName()] = ""
			end
		end
		init(self, player)
	end
	sgs.ai_skill_choice.RevealGeneral = function(self, choices)
		local event = self.player:getTag("event"):toInt()
		local data = self.player:getTag("event_data")
		local generals = self.player:getTag("roles"):toString():split("+")
		local players = {}
		for _, general in ipairs(generals) do
			local player = sgs.ServerPlayer(self.room)
			player:setGeneral(sgs.Sanguosha:getGeneral(general))
			table.insert(players, player)
		end

		local anjiang = {}
		for _, player in sgs.qlist(self.room:getAllPlayers()) do
			if player:getGeneralName() == "anjiang" then table.insert(anjiang, player:getSeat()) end
		end

		if event == sgs.DamageInflicted then
			local damage = data:toDamage()
			for _, player in ipairs(players) do
				if self:hasSkills(sgs.masochism_skill, player) and self:isEnemy(damage.from) then return "yes" end
				if damage.damage > self.player:getHp() + self:getAllPeachNum() then return "yes" end
			end
		elseif event == sgs.CardEffected then
			local effect = data:toCardEffect()
			for _, player in ipairs(players) do
				if self.room:isProhibited(effect.from, player, effect.card) and self:isEnemy(effect.from) then return "yes" end
			end
		end

		if sgs.getValue(self.player) < 6 then return "no" end
		for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if self:isFriend(player) then return "yes" end
		end
		local vequips, defense = 0
		if self.player:getWeapon() or self:hasHegSkills("yitian", players) then vequips = vequips + 1 end
		if (self.player:getArmor() and self:evaluateArmor() > 0) or self:hasHegSkills("bazhen|yizhong", players) then
			vequips = vequips + 2 defense = true end
		if self.player:getDefensiveHorse() or self:hasHegSkills("feiying", players) then vequips = vequips + 1.5 defense = true end
		if self.player:getOffensiveHorse() or self:hasHegSkills("mashu", players) then vequips = vequips + 0.5 end
		if vequips < 2.5 or not defense then return "no" end

		if sgs.ai_loyalty[self:getHegKingdom()][self.player:objectName()] == 160 then return "yes" end

		local anjiang = 0
		for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if player:getGeneralName() == "anjiang" then
				anjiang = anjiang + 1
			end
		end

		if math.random() > (anjiang + 1)/(self.room:alivePlayerCount() + 2) then
			return "yes"
		else
			return "no"
		end
	end

	sgs.isRolePredictable = function()
		return false
	end

	sgs.ai_loyalty = {
		wei = {},
		wu = {},
		shu = {},
		qun = {},
	}
	sgs.ai_explicit = {}

	SmartAI.hasHegSkills = function(self, skills, players)
		for _, player in ipairs(players) do
			if self:hasSkills(skills, player) then return true end
		end
		return false
	end

	SmartAI.getHegKingdom = function(self)
		local names = self.room:getTag(self.player:objectName()):toStringList()
		if #names == 0 then return self.player:getKingdom() end
		local kingdom = sgs.Sanguosha:getGeneral(names[1]):getKingdom()
		return kingdom
	end

	SmartAI.getHegGeneralName = function(self, player)
		player = player or self.player
		local names = self.room:getTag(player:objectName()):toStringList()
		if #names > 0 then return names[1] else return player:getGeneralName() end
	end

	SmartAI.objectiveLevel = function(self, player, recursive)
		if not player then return 0 end
		if self.player == player then return -5 end
		local lieges = {}
		local liege_hp = 0
		for _, aplayer in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if self:getHegKingdom() == aplayer:getKingdom() then table.insert(lieges, aplayer) end
			liege_hp = liege_hp + aplayer:getHp()
		end

		local plieges = {}
		local modifier = 0
		for _, aplayer in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			local kingdom = aplayer:getKingdom()
			if kingdom == "god" then kingdom = sgs.ai_explicit[aplayer:objectName()] end
			if kingdom then plieges[kingdom] = (plieges[kingdom] or 0) + 1 end
		end
		local kingdoms = { "wei", "wu", "shu", "qun" }
		local max_kingdom = 0
		for _, akingdom in ipairs(kingdoms) do
			if (plieges[akingdom] or 0) > max_kingdom then max_kingdom = plieges[akingdom] end
		end

		if max_kingdom > 0 then
			local kingdom = player:getKingdom()
			if kingdom == "god" then kingdom = sgs.ai_explicit[player:objectName()] end
			if not kingdom or (plieges[kingdom] or 0) < max_kingdom then modifier = -2
			elseif (plieges[kingdom] or 0) > 2 then modifier = 2 end
		end

		if self:getHegKingdom() == player:getKingdom() then
			if recursive then return -3 end
			if self.player:getKingdom() == "god" and #lieges >= 2 then
				self:sort(lieges, "hp")
				if player:objectName() ~= lieges[1]:objectName() then return -3 end
				local enemy, enemy_hp = 0, 0
				for _, aplayer in sgs.qlist(self.room:getOtherPlayers(self.player)) do
					if self:objectiveLevel(aplayer, true) > 0 then enemy = enemy + 1 enemy_hp = enemy_hp + aplayer:getHp() end
				end
				local liege
				if enemy_hp - enemy >= liege_hp - #lieges then return -3 else return 4 end
			end
			return -3
		elseif player:getKingdom() ~= "god" then return 5 + modifier
		elseif sgs.ai_explicit[player:objectName()] == self:getHegKingdom() then
			if self.player:getKingdom() ~= "god" and #lieges >= 1 and not recursive then
				for _, aplayer in sgs.qlist(self.room:getOtherPlayers(self.player)) do
					if self:objectiveLevel(aplayer, true) >= 0 then return -1 end
				end
				return 4
			end
			return -1
		elseif (sgs.ai_loyalty[self:getHegKingdom()][player:objectName()] or 0) == -160 then return 5 + modifier
		elseif (sgs.ai_loyalty[self:getHegKingdom()][player:objectName()] or 0) < -80 then return 4 + modifier
		end

		return 0
	end

	SmartAI.isFriend = function(self, player)
		return self:objectiveLevel(player) < 0
	end

	SmartAI.isEnemy = function(self, player)
		return self:objectiveLevel(player) >= 0
	end

	sgs.ai_card_intention["general"] = function(to, level)
		sgs.hegemony_to = to
		return -level
	end

	sgs.updateIntention = function(player, to, intention)
		intention = -intention
		local kingdoms = {"wei", "wu", "shu", "qun"}
		if player:getKingdom() ~= "god" then
			for _, akingdom in ipairs(kingdoms) do
				sgs.ai_loyalty[akingdom][player:objectName()] = -160
			end
			sgs.ai_loyalty[player:getKingdom()][player:objectName()] = 160
			sgs.ai_explicit[player:objectName()] = player:getKingdom()
			return
		end
		local kingdom = to:getKingdom()
		if kingdom ~= "god" then
			sgs.ai_loyalty[kingdom][player:objectName()] = (sgs.ai_loyalty[kingdom][player:objectName()] or 0) + intention
			if sgs.ai_loyalty[kingdom][player:objectName()] > 160 then sgs.ai_loyalty[kingdom][player:objectName()] = 160 end
			if sgs.ai_loyalty[kingdom][player:objectName()] < -160 then sgs.ai_loyalty[kingdom][player:objectName()] = -160 end
		elseif sgs.ai_explicit[player:objectName()] ~= "" then
			kingdom = sgs.ai_explicit[player:objectName()]
			sgs.ai_loyalty[kingdom][player:objectName()] = (sgs.ai_loyalty[kingdom][player:objectName()] or 0) + intention * 0.7
			if sgs.ai_loyalty[kingdom][player:objectName()] > 160 then sgs.ai_loyalty[kingdom][player:objectName()] = 160 end
			if sgs.ai_loyalty[kingdom][player:objectName()] < -160 then sgs.ai_loyalty[kingdom][player:objectName()] = -160 end
		else
			for _, aplayer in sgs.qlist(player:getRoom():getAlivePlayers()) do
				local kingdom = aplayer:getKingdom()
				if aplayer:objectName() ~= to:objectName() and kingdom ~= "god" and (sgs.ai_loyalty[kingdom][player:objectName()] or 0)>-80 then
					sgs.ai_loyalty[kingdom][player:objectName()] = (sgs.ai_loyalty[kingdom][player:objectName()] or 0) - intention * 0.2
					if sgs.ai_loyalty[kingdom][player:objectName()] > 160 then sgs.ai_loyalty[kingdom][player:objectName()] = 160 end
					if sgs.ai_loyalty[kingdom][player:objectName()] < -160 then sgs.ai_loyalty[kingdom][player:objectName()] = -160 end
				end
			end
		end
		local neg_loyalty_count, pos_loyalty_count, max_loyalty, max_kingdom = 0, 0
		for _, akingdom in ipairs(kingdoms) do
			local list = sgs.ai_loyalty[akingdom]
			if not max_loyalty then max_loyalty = (list[player:objectName()] or 0) max_kingdom = akingdom end
			if (list[player:objectName()] or 0)< 0 then
				neg_loyalty_count = neg_loyalty_count + 1
			elseif (list[player:objectName()] or 0)> 0 then
				pos_loyalty_count = pos_loyalty_count + 1
			end
			if max_loyalty < (list[player:objectName()] or 0) then
				max_loyalty = (list[player:objectName()] or 0)
				max_kingdom = akingdom
			end
		end
		if neg_loyalty_count > 2 or pos_loyalty_count > 0 then
			sgs.ai_explicit[player:objectName()] = max_kingdom
		else
			sgs.ai_explicit[player:objectName()] = ""
		end
	end

	SmartAI.updatePlayers = function(self, inclusive)
		local flist = {}
		local elist = {}
		self.friends = flist
		self.enemies = elist
		self.friends_noself = {}

		local players = sgs.QList2Table(self.room:getOtherPlayers(self.player))
		for _, aplayer in ipairs(players) do
			if self:isFriend(aplayer) then table.insert(flist, aplayer) end
		end
		for _, aplayer in ipairs(flist) do
			table.insert(self.friends_noself, aplayer)
		end
		table.insert(flist, self.player)
		for _, aplayer in ipairs(players) do
			if self:isEnemy(aplayer) then table.insert(elist, aplayer) end
		end
	end

	SmartAI.printAll = function(self, player, intention)
		local name = player:objectName()
		self.room:writeToConsole(self:getHegGeneralName(player) .. math.floor(intention * 10) / 10
								.. " R" .. math.floor((sgs.ai_loyalty["shu"][name] or 0) * 10) / 10
								.. " G" .. math.floor((sgs.ai_loyalty["wu"][name] or 0) * 10) / 10
								.. " B" .. math.floor((sgs.ai_loyalty["wei"][name] or 0) * 10) / 10
								.. " Q" .. math.floor((sgs.ai_loyalty["qun"][name] or 0) * 10) / 10
								.. " E" .. (sgs.ai_explicit[name] or "nil"))
	end

	SmartAI.printFEList = function(self)
		for _, player in ipairs (self.enemies) do
			self.room:writeToConsole("enemy " .. self:getHegGeneralName(player))
		end

		for _, player in ipairs (self.friends_noself) do
			self.room:writeToConsole("friend " .. self:getHegGeneralName(player))
		end
		self.room:writeToConsole(self:getHegGeneralName() .. " list end")
	end
end

-- AI for general
sgs.ai_skill_use["@xiaoguo"] = function(self, prompt)
	local currentplayer = self.room:getCurrent()
	if self:damageIsEffective(currentplayer) then return "." end
	if self:isEquip("SilverLion", currentplayer) and currentplayer:getLostHp() > 0 then return "." end
	if self:isFriend(currentplayer) then
		return "."
	else
		for _, card in sgs.qlist(self.player:getHandcards()) do
			if card:isKindOf("Peach") then has_peach = card
			elseif card:isKindOf("Analeptic") then has_anal = card
			elseif card:isKindOf("Slash") then has_slash = card
			elseif card:isKindOf("Jink") then has_jink = card
			end
		end

		if has_slash then return "$" .. has_slash:getEffectiveId()
		elseif has_jink then return "$" .. has_jink:getEffectiveId()
		elseif has_anal or has_peach then
			if getCardsNum("Jink", target) == 0 and self:getAllPeachNum(target) == 0 and not self:isWeak() then
				if has_anal then return "$" .. has_anal:getEffectiveId()
				else return "$" .. has_peach:getEffectiveId()
				end
			end
		else return "."
		end
	end
end

sgs.ai_skill_cardask["@xiaoguo-discard"] = function(self, data)
	local yuejin = self.room:findPlayerBySkillName("xiaoguo")
	if not self:damageIsEffective(self.player, sgs.DamageStruct_Normal, yuejin) then
		return "."
	end
	if self.player:getArmor() and self.player:getArmor():isKindOf("SilverLion") and self.player:isWounded() then
		return "$" .. self.player:getArmor():getEffectiveId()
	end
	for _, card in sgs.qlist(self.player:getCards("he")) do
		if card:isKindOf("EquipCard") and not self.player:hasEquip(card) then
			return "$" .. card:getEffectiveId()
		end
	end
	for _, card in sgs.qlist(self.player:getCards("he")) do
		if card:isKindOf("EquipCard") then
			return "$" .. card:getEffectiveId()
		end
	end
	return "."
end

sgs.ai_skill_invoke.shushen = function(self, data)
	return #self.friends_noself > 0
end

sgs.ai_skill_playerchosen.shushen = function(self, targets)
	local tos = {}
	local current = self.player:getRoom():getCurrent()
	for _, target in sgs.qlist(targets) do
		if self:isFriend(target)
			and not (target:hasSkill("manjuan") and target:objectName() ~= current:objectName())
			and not (target:hasSkill("kongcheng") and target:isKongcheng()) then
			table.insert(tos, target)
		end
	end

	if #tos > 0 then
		self:sort(tos, "defense")
		return tos[1]
	end
end

sgs.ai_skill_invoke.shenzhi = function(self, data)
	return self.player:getHandcardNum() >= self.player:getHp() and self.player:getHandcardNum() <= self.player:getHp() + math.max(3, self.player:getHp())
			and self.player:getLostHp() > 0 and self:getCardsNum("Peach") == 0
end

local duoshi_skill = {}
duoshi_skill.name = "duoshi"
table.insert(sgs.ai_skills, duoshi_skill)
duoshi_skill.getTurnUseCard = function(self, inclusive)
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)

	local red_card
	if self.player:getCardCount(false) <= 2 then return end
	self:sortByUseValue(cards,true)

	for _, card in ipairs(cards) do
		if card:isRed() then
			local shouldUse = true
			if card:isKindOf("Slash") then
				local dummy_use = { isDummy = true }
				if self:getCardsNum("Slash") == 1 then
					self:useBasicCard(card, dummy_use)
					if dummy_use.card then shouldUse = false end
				end
			end

			if self:getUseValue(card) > sgs.ai_use_value.DuoshiCard and card:isKindOf("TrickCard") then
				local dummy_use = { isDummy = true }
				self:useTrickCard(card, dummy_use)
				if dummy_use.card then shouldUse = false end
			end

			if shouldUse then
				red_card = card
				break
			end

		end
	end

	if red_card then
		local card_id = red_card:getEffectiveId()
		local card_str = ("@DuoshiCard=" .. card_id)
		local await = sgs.Card_Parse(card_str)
		assert(await)
		return await
	end
end

sgs.ai_skill_use_func.DuoshiCard = function(card, use, self)
	use.card = card
	if use.to then use.to:append(self.player) end
	for _, player in ipairs(self.friends) do
		if use.to and not player:hasSkill("manjuan") and player:objectName() ~= self.player:objectName() then
			use.to:append(player)
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if use.to and enemy:hasSkill("manjuan") then
			use.to:append(enemy)
		end
	end
end

sgs.ai_use_value.DuoshiCard = 3
sgs.ai_use_priority.DuoshiCard = 2.2
sgs.ai_card_intention.DuoshiCard = -30

local fenxun_skill = {}
fenxun_skill.name = "fenxun"
table.insert(sgs.ai_skills, fenxun_skill)
fenxun_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("FenxunCard") then return end
	if not self.player:isNude() then
		local card
		local card_id
		if self:isEquip("SilverLion") and self.player:isWounded() then
			card = sgs.Card_Parse("@FenxunCard=" .. self.player:getArmor():getId())
		elseif self.player:getHandcardNum() > self.player:getHp() then
			local cards = self.player:getHandcards()
			cards = sgs.QList2Table(cards)

			for _, acard in ipairs(cards) do
				if (acard:isKindOf("BasicCard") or acard:isKindOf("EquipCard") or acard:isKindOf("AmazingGrace"))
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
				if (acard:isKindOf("BasicCard") or acard:isKindOf("EquipCard") or acard:isKindOf("AmazingGrace"))
					and not acard:isKindOf("Peach") then
					card_id = acard:getEffectiveId()
					break
				end
			end
		end
		if not card_id then
			return nil
		else
			card = sgs.Card_Parse("@FenxunCard=" .. card_id)
			return card
		end
	end
	return nil
end

sgs.ai_skill_use_func.FenxunCard = function(card, use, self)
	if not self.player:hasUsed("FenxunCard") then
		self:sort(self.enemies, "defense")
		local target
		for _, enemy in ipairs(self.enemies) do
			if self.player:distanceTo(enemy) > 1 and self.player:canSlash(enemy, nil, true) then
				target = enemy
				break
			end
		end
		if target and self:getCardsNum("Slash") > 0 then
			use.card = card
			if use.to then
				use.to:append(target)
			end
		end
	end
end

sgs.ai_use_value.FenxunCard = 5.5
sgs.ai_use_priority.FenxunCard = 8
sgs.ai_card_intention.FenxunCard = 50

sgs.ai_skill_choice.mingshi = function(self, choices, data)
	local to = data:toPlayer()
	if self:isEnemy(to) and not to:hasFlag("damage_plus") then
		return "yes"
	end
	return "no"
end

sgs.ai_skill_invoke.lirang = function(self, data)
	return #self.friends_noself > 0
end

sgs.ai_skill_invoke.sijian = function(self, data)
	return #self.enemies > 0
end

sgs.ai_skill_playerchosen.sijian = sgs.ai_skill_playerchosen.zero_card_as_slash

sgs.ai_skill_choice.suishi1 = function(self, choices)
	local tianfeng = self.room:findPlayerBySkillName("suishi")
	if tianfeng and self:isFriend(tianfeng) then
		return "draw"
	end
	return "no"
end

sgs.ai_skill_choice.suishi2 = function(self, choices)
	local tianfeng = self.room:findPlayerBySkillName("suishi")
	if tianfeng and self:objectiveLevel(tianfeng) > 3 then
		return "damage"
	end
	return "no"
end

sgs.ai_skill_use["@@shuangren"] = function(self, prompt)
	local target
	self:sort(self.enemies, "handcard")
	local max_card = self:getMaxCard(self.player)
	local max_point = max_card:getNumber()
	for _, enemy in ipairs(self.enemies) do
		if not enemy:isKongcheng() then
			local enemy_max_card = self:getMaxCard(enemy)
			local allknown = 0
			if self:getKnownNum(enemy) == enemy:getHandcardNum() then
				allknown = allknown + 1
			end
			if (enemy_max_card and max_point > enemy_max_card:getNumber() and allknown > 0)
				or (enemy_max_card and max_point > enemy_max_card:getNumber() and allknown < 1 and max_point > 10)
				or (not enemy_max_card and max_point > 10) then
					return "@ShuangrenCard=" .. max_card:getEffectiveId() .. "->" .. enemy:objectName()
			end
		end
	end
	return "."
end

sgs.ai_skill_playerchosen.shuangren_slash = sgs.ai_skill_playerchosen.zero_card_as_slash

xiongyi_skill = {}
xiongyi_skill.name = "xiongyi"
table.insert(sgs.ai_skills, xiongyi_skill)
xiongyi_skill.getTurnUseCard = function(self)
	if self.player:getMark("@arise") < 1 then return end
	if #self.friends <= #self.enemies and self.player:getLostHp() > 1 then return sgs.Card_Parse("@XiongyiCard=.") end
end

sgs.ai_skill_use_func.XiongyiCard = function(card, use, self)
	use.card = card
	for i = 1, #self.friends - 1 do
		if use.to then use.to:append(self.friends[i]) end
	end
end

sgs.ai_card_intention.XiongyiCard = -50

sgs.ai_skill_invoke.kuangfu = function(self, data)
	local damage = data:toDamage()
	if self:isEnemy(damage.to) then
		if damage.to:getCards("e"):length() == 1 and damage.to:getArmor() and damage.to:getArmor():isKindOf("SilverLion") then
			return false
		end
		return true
	end
	if damage.to:getCards("e"):length() == 1 and damage.to:getArmor() and damage.to:getArmor():isKindOf("SilverLion") then
		return true
	end
	return false
end

sgs.ai_skill_choice.kuangfu = function(self, choices)
	return "move"
end

local qingcheng_skill = {}
qingcheng_skill.name = "qingcheng"
table.insert(sgs.ai_skills, qingcheng_skill)
qingcheng_skill.getTurnUseCard = function(self, inclusive)
	local equipcard
	if self.player:getArmor() and self.player:getArmor():isKindOf("SilverLion") and self.player:isWounded() then
		equipcard = self.player:getArmor()
	else
		for _, card in sgs.qlist(self.player:getCards("he")) do
			if card:isKindOf("EquipCard") and not self.player:hasEquip(card) then
				equipcard = card
				break
			end
		end
		if not equipcard then
			for _, card in sgs.qlist(self.player:getCards("he")) do
				if card:isKindOf("EquipCard") and not card:isKindOf("Armor") and not card:isKindOf("DefensiveHorse") then
					equipcard = card
				end
			end
		end
	end

	if equipcard then
		local card_id = equipcard:getEffectiveId()
		local card_str = ("@QingchengCard=" .. card_id)
		local qc_card = sgs.Card_Parse(card_str)

		return qc_card
	end
end

sgs.ai_skill_use_func.QingchengCard = function(card, use, self)
	if self.room:alivePlayerCount() == 2 then
		local only_enemy = self.room:getOtherPlayers(self.player):first()
		if only_enemy:getLostHp() < 3 then return end
	end
	for _, enemy in ipairs(self.enemies) do
		for _, askill in ipairs(("noswuyan|wuyan|weimu|kanpo|liuli|yiji|jieming|ganglie|neoganglie|fankui|jianxiong|enyuan|nosenyuan" ..
								"|qingguo|longdan|xiangle|jiang|yanzheng|tianming|" ..
								"huangen|danlao|qianxun|juxiang|huoshou|anxian|fenyong|zhichi|jilei|feiying|yicong|wusheng|wushuang|tianxiang|leiji|" ..
								"xuanfeng|nosxuanfeng|luoying|xiaoguo|guhuo|guidao|guicai|shangshi|lianying|sijian|xiaoji|mingshi|zhiyu|hongyan|tiandu|lirang|" .. 
								"guzheng|xingshang|shushen"):split("|")) do
			if enemy:hasSkill(askill, true) and enemy:getMark("Qingcheng" .. askill) == 0 then
				use.card = card
				if use.to then
					use.to:append(enemy)
				end
				return
			end
		end
	end
	for _,friend in ipairs(self.friends_noself) do
		if friend:hasSkill("shiyong", true) and friend:getMark("Qingchengshiyong") == 0 then
			use.card = card
			if use.to then
				use.to:append(friend)
			end
			return
		end
	end
	return
end

sgs.ai_skill_choice.qingcheng = function(self, choices, data)
	local target = data:toPlayer()
	for _, askill in ipairs(("noswuyan|wuyan|weimu|kanpo|liuli|qingguo|longdan|xiangle|jiang|yanzheng|tianming|" ..
							"huangen|danlao|qianxun|juxiang|huoshou|anxian|fenyong|zhichi|jilei|feiying|yicong|wusheng|wushuang|tianxiang|leiji|" ..
							"xuanfeng|nosxuanfeng|luoying|xiaoguo|guhuo|guidao|guicai|shangshi|lianying|sijian|xiaoji|mingshi|zhiyu|hongyan|tiandu|lirang|" .. 
							"guzheng|xingshang|shushen"):split("|")) do
		if target:hasSkill(askill, true) and target:getMark("Qingcheng" .. askill) == 0 then
			return askill
		end
	end
end

sgs.ai_use_value.QingchengCard = 2
sgs.ai_use_priority.QingchengCard = 2.2
sgs.ai_card_intention.QingchengCard = 30

sgs.ai_skill_invoke.cv_caopi = function(self, data)
	if math.random(0, 2) == 0 then return true end
	return false
end

sgs.ai_skill_invoke.cv_zhenji = sgs.ai_skill_invoke.cv_caopi
sgs.ai_skill_invoke.cv_zhugeliang = sgs.ai_skill_invoke.cv_caopi
sgs.ai_skill_invoke.cv_huangyueying = sgs.ai_skill_invoke.cv_caopi
sgs.ai_skill_invoke.cv_zhouyu = sgs.ai_skill_invoke.cv_caopi
sgs.ai_skill_invoke.cv_lvbu = sgs.ai_skill_invoke.cv_caopi
