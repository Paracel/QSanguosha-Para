function sgs.ai_cardsview.jiushi(class_name, player)
	if class_name == "Analeptic" then
		if player:hasSkill("jiushi") and player:faceUp() then
			return ("analeptic:jiushi[no_suit:0]=.")
		end
	end
end

function sgs.ai_skill_invoke.jiushi(self, data)
	return not self.player:faceUp()
end

sgs.ai_skill_invoke.luoying = function(self)
	if self.player:hasFlag("DimengTarget") then
		local another
		for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if player:hasFlag("DimengTarget") then
				another = player
				break
			end
		end
		if not another or not self:isFriend(another) then return false end
	end
	return true
end

sgs.ai_skill_askforag.luoying = function(self, card_ids)
	return -1
end

sgs.ai_skill_use["@@jujian"] = function(self, prompt, method)
	local needfriend = 0
	local nobasiccard = -1
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	if self:needToThrowArmor() and not self.player:isCardLimited(self.player:getArmor(), method) then
		nobasiccard = self.player:getArmor():getId()
	else
		self:sortByKeepValue(cards)
		for _, card in ipairs(cards) do
			if card:getTypeId() ~= sgs.Card_TypeBasic and not self.player:isCardLimited(card, method) then nobasiccard = card:getEffectiveId() end
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if self:isWeak(friend) or friend:getHandcardNum() < 2 or not friend:faceUp()
		or (friend:getArmor() and friend:getArmor():objectName() == "vine" and (friend:isChained() and not self:isGoodChainPartner(friend))) then
			needfriend = needfriend + 1
		end
	end
	if nobasiccard < 0 or needfriend < 1 then return "." end
	self:sort(self.friends_noself, "defense")
	for _, friend in ipairs(self.friends_noself) do
		if not friend:faceUp() then
			return "@JujianCard=" .. nobasiccard .. "->" .. friend:objectName()
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if friend:getArmor() and friend:getArmor():objectName() == "vine" and (friend:isChained() and not self:isGoodChainPartner(friend)) then
			return "@JujianCard=" .. nobasiccard .. "->" .. friend:objectName()
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if self:isWeak(friend) then
			return "@JujianCard=" .. nobasiccard .. "->" .. friend:objectName()
		end
	end
	return "@JujianCard=" .. nobasiccard .. "->" .. self.friends_noself[1]:objectName()
end

sgs.ai_skill_choice.jujian = function(self, choices)
	if not self.player:faceUp() then return "reset" end
	if self.player:hasArmorEffect("vine") and self.player:isChained() and not self:isGoodChainPartner() then
		return "reset"
	end
	if self:isWeak() and self.player:isWounded() then return "recover" end
	if self.player:hasSkill("manjuan") then
		if self.player:isWounded() then return "recover" end
		if self.player:isChained() then return "reset" end
	end
	return "draw"
end

sgs.ai_card_intention.JujianCard = -100

sgs.jujian_keep_value = {
	Peach = 6,
	Jink = 5,
	EquipCard = 5,
	Duel = 5,
	FireAttack = 5,
	ArcheryAttack = 5,
	SavageAssault = 5
}

function sgs.ai_armor_value.yizhong(card)
	if not card then return 4 end
end

local xinzhan_skill = {}
xinzhan_skill.name = "xinzhan"
table.insert(sgs.ai_skills, xinzhan_skill)
xinzhan_skill.getTurnUseCard = function(self)
	if not self.player:hasUsed("XinzhanCard") and self.player:getHandcardNum() > self.player:getMaxHp() then
		return sgs.Card_Parse("@XinzhanCard=.")
	end
end

sgs.ai_skill_use_func.XinzhanCard = function(card, use, self)
	use.card = card
end

sgs.ai_use_value.XinzhanCard = 4.4
sgs.ai_use_priority.XinzhanCard = 9.4

function sgs.ai_slash_prohibit.huilei(self, from, to)
	if from:hasSkill("jueqing") or (from:hasSkill("nosqianxi") and from:distanceTo(to) == 1) then return false end
	if from:hasFlag("nosjiefanUsed") then return false end
	if self:isFriend(to, from) and self:isWeak(to) then return true end
	return #(self:getEnemies(from)) > 1 and self:isWeak(to) and from:getHandcardNum() > 3
end

sgs.ai_chaofeng.masu = -4

sgs.ai_skill_invoke.enyuan = function(self, data)
	local damage = data:toDamage()
	if damage and damage.from then
		if damage.from and damage.from:isAlive() then
			return self:isFriend(damage.from) and self:getOverflow(damage.from) > 2 or true
		end
	else
		local move = data:toMoveOneTime()
		if move and move.from then
			local from
			for _, player in sgs.qlist(self.room:getAlivePlayers()) do
				if player:objectName() == move.from:objectName() then from = move.from break end
			end
			if from then return self:isFriend(from) and not (from:hasSkill("kongcheng") and from:isKongcheng()) end
		end
		return false
	end
end

sgs.ai_skill_discard.enyuan = function(self, discard_num, min_num, optional, include_equip)
	local to_discard = {}
	local cards = self.player:getHandcards()
	local fazheng = self.room:findPlayerBySkillName("enyuan")
	cards = sgs.QList2Table(cards)

	if fazheng and self:isFriend(fazheng) then
		for _, card in ipairs(cards) do
			if isCard("Peach", card, fazheng) and ((not self:isWeak() and self:getCardsNum("Peach") > 0) or self:getCardsNum("Peach") > 1) then
				table.insert(to_discard, card:getEffectiveId())
				return to_discard
			end
			if isCard("Analeptic", card, fazheng) and self:getCardsNum("Analeptic") > 1 then
				table.insert(to_discard, card:getEffectiveId())
				return to_discard
			end
			if isCard("Jink", card, fazheng) and self:getCardsNum("Jink") > 1 then
				table.insert(to_discard, card:getEffectiveId())
				return to_discard
			end
		end
	end

	self:sortByKeepValue(cards)
	for _, card in ipairs(cards) do
		if not isCard("Peach", card, self.player) and not isCard("ExNihilo", card, self.player) then
			table.insert(to_discard, card:getEffectiveId())
			return to_discard
		end
	end

	return {}
end

function sgs.ai_slash_prohibit.enyuan(self, from, to)
	if from:hasSkill("jueqing") or (from:hasSkill("nosqianxi") and from:distanceTo(to) == 1) then return false end
	if from:hasFlag("nosjiefanUsed") then return false end
	local num = from:getHandcardNum()
	if num >= 3 or from:hasSkill("lianying") or (from:hasSkill("kongcheng") and num == 2) then return false end
	return true
end

sgs.ai_need_damaged.enyuan = function (self, attacker)
	if self:isEnemy(attacker) and self:isWeak(attacker) and attacker:getHandcardNum() < 3 and not self:hasSkills("lianying|kongcheng", attacker) then
		return true
	end
	return false
end

function sgs.ai_cardneed.enyuan(to, card)
	return getKnownCard(to, "Card", false) < 2
end

sgs.ai_skill_use["@@xuanhuo"] = function(self, prompt)
	local lord = self.room:getLord()
	local killloyal = 0
	local robequip = 0
	if lord and self:isEnemy(lord) then
		for _, enemy in ipairs(self.enemies) do
			if lord:canSlash(enemy) and (enemy:getHp() < 2 and not enemy:hasSkill("buqu"))
			and sgs.getDefense(enemy) < 2 then
				killloyal = killloyal + 1
			end
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if enemy:getCards("e"):length() > 1 and getCardsNum("Slash", enemy) == 0
			and not self:hasSkills(sgs.lose_equip_skill, enemy) then
			robequip = robequip + 1
		end
	end
	if #self.enemies < 2 and killloyal < 1 and robequip < 1 then return "." end
	if lord and self:isEnemy(lord) and killloyal > 0 then
		return "@XuanhuoCard=.->" .. lord:objectName()
	end
	for _, enemy in ipairs(self.enemies) do
		if enemy:getCards("e"):length() > 1 and getCardsNum("Slash", enemy) == 0
			and not self:hasSkills(sgs.lose_equip_skill, enemy) then
			return "@XuanhuoCard=.->" .. enemy:objectName()
		end
	end
	self:sort(self.enemies, "defense")
	for _, friend in ipairs(self.friends_noself) do
		for _, enemy in ipairs(self.enemies) do
			if friend:canSlash(enemy) and (enemy:getHp() < 2 and not enemy:hasSkill("buqu"))
			and sgs.getDefense(enemy) < 2 then
				return "@XuanhuoCard=.->" .. friend:objectName()
			end
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if self:hasSkills(sgs.lose_equip_skill, friend) and not friend:getEquips():isEmpty() then
			return "@XuanhuoCard=.->" .. friend:objectName()
		end
	end

	if #self.friends_noself == 0 then return end
	self:sort(self.friends_noself, "defense")
	return "@XuanhuoCard=.->" .. self.friends_noself[1]:objectName()
end

sgs.ai_skill_choice.xuanhuo = function(self, choices)
	local fazheng = self.room:findPlayerBySkillName("xuanhuo")
	if fazheng and not self:isFriend(fazheng) then
		for _, friend in ipairs(self.friends_noself) do
			if self.player:canSlash(friend) and self:isWeak(friend) then
				return "give"
			end
		end
		return "slash"
	end
	for _, enemy in ipairs(self.enemies) do
		if self.player:canSlash(enemy) and (enemy:getHp() < 2 and not enemy:hasSkill("buqu"))
		and sgs.getDefense(enemy) < 2 then
			return "slash"
		end
	end
	return "give"
end

sgs.ai_skill_playerchosen.xuanhuo = sgs.ai_skill_playerchosen.zero_card_as_slash

sgs.ai_skill_cardask["xuanhuo-slash"] = function(self, data, pattern, target, target2)
	if target and target2 and self:isEnemy(target2) then
		for _, slash in ipairs(self:getCards("Slash")) do
			if self:slashIsEffective(slash, target2) then
				return slash:toString()
			end
		end
	end
	if target and target2 and self:isFriend(target2) then
		for _, slash in ipairs(self:getCards("Slash")) do
			if not self:slashIsEffective(slash, target2) then
				return slash:toString()
			end
		end
		if (target2:getHp() > 2 or getCardsNum("Jink", target2) > 1) and not target2:getRole() == "lord" and self.player:getHandcardNum() > 1 then
			for _, slash in ipairs(self:getCards("Slash")) do
				return slash:toString()
			end
		end
	end
	return "."
end

sgs.ai_playerchosen_intention.xuanhuo = 80
sgs.ai_card_intention.XuanhuoCard = -30

sgs.ai_chaofeng.fazheng = -3

function sgs.ai_skill_invoke.xuanfeng(self, data)
	if self.player:getPhase() == sgs.Player_Discard then
		local erzhang = self.room:findPlayerBySkillName("guzheng")
		if erzhang and self:isEnemy(erzhang) then return false end
	end
	local player = self:findPlayerToDiscard()
	if player then return true else return false end
end

sgs.ai_skill_playerchosen.xuanfeng = function(self, targets)
	local player = self:findPlayerToDiscard()
	return player or targets[1]
end

sgs.ai_playerchosen_intention.xuanfeng = function(from, to)
	local intention = 80
	if to:hasSkill("kongcheng") and to:getHandcardNum() == 1 and to:getHp() <= 2 then
		intention = -10
	elseif self:needToThrowArmor(to) then
		intention = -10
	end
	sgs.updateIntention(from, to, intention)
end

sgs.xuanfeng_keep_value = sgs.xiaoji_keep_value

sgs.ai_skill_invoke.pojun = function(self, data)
	local damage = data:toDamage()

	if not damage.to:faceUp() then
		return self:isFriend(damage.to)
	end

	local good = damage.to:getHp() > 2
	if self:isFriend(damage.to) then
		return good
	elseif self:isEnemy(damage.to) then
		return not good
	end
end

ganlu_skill = {}
ganlu_skill.name = "ganlu"
table.insert(sgs.ai_skills, ganlu_skill)
ganlu_skill.getTurnUseCard = function(self)
	if not self.player:hasUsed("GanluCard") then
		return sgs.Card_Parse("@GanluCard=.")
	end
end

sgs.ai_skill_use_func.GanluCard = function(card, use, self)
	local lost_hp = self.player:getLostHp()
	local target, min_friend, max_enemy

	local compare_func = function(a, b)
		return a:getEquips():length() > b:getEquips():length()
	end
	table.sort(self.enemies, compare_func)
	table.sort(self.friends, compare_func)
	self.friends = sgs.reverse(self.friends)

	for _, friend in ipairs(self.friends) do
		for _, enemy in ipairs(self.enemies) do
			if not self:hasSkills(sgs.lose_equip_skill, enemy) then
				local ee = enemy:getEquips():length()
				local fe = friend:getEquips():length()
				local value = self:evaluateArmor(enemy:getArmor(), friend) - self:evaluateArmor(friend:getArmor(), enemy)
								- self:evaluateArmor(friend:getArmor(), friend) + self:evaluateArmor(enemy:getArmor(), enemy)
				if math.abs(ee - fe) <= lost_hp and ee > 0 and (ee > fe or ee == fe and value>0) then
					if self:hasSkills(sgs.lose_equip_skill, friend) then
						use.card = sgs.Card_Parse("@GanluCard=.")
						if use.to then
							use.to:append(friend)
							use.to:append(enemy)
						end
						return
					elseif not min_friend and not max_enemy then
						min_friend = friend
						max_enemy = enemy
					end
				end
			end
		end
	end
	if min_friend and max_enemy then
		use.card = sgs.Card_Parse("@GanluCard=.")
		if use.to then
			use.to:append(min_friend)
			use.to:append(max_enemy)
		end
		return
	end

	target = nil
	for _, friend in ipairs(self.friends) do
		if self:needToThrowArmor(friend) or (self:hasSkills(sgs.lose_equip_skill, friend)
			and not friend:getEquips():isEmpty()) then target = friend break end
	end
	if not target then return end
	for _, friend in ipairs(self.friends) do
		if friend:objectName() ~= target:objectName() and math.abs(friend:getEquips():length() - target:getEquips():length()) <= lost_hp then
			use.card = sgs.Card_Parse("@GanluCard=.")
			if use.to then
				use.to:append(friend)
				use.to:append(target)
			end
			return
		end
	end
end

sgs.ai_use_priority.GanluCard = 9
sgs.dynamic_value.control_card.GanluCard = true

sgs.ai_card_intention.GanluCard = function(self, card, from, to)
	local compare_func = function(a, b)
		return a:getEquips():length() < b:getEquips():length()
	end
	table.sort(to, compare_func)
	for i = 1, 2, 1 do
		if to[i]:hasArmorEffect("silver_lion") then
			sgs.updateIntention(from, to[i], -20)
			break
		end
	end
	if to[1]:getEquips():length() < to[2]:getEquips():length() then
		sgs.updateIntention(from, to[2], (to[2]:getEquips():length() - to[1]:getEquips():length()) * 10 + 20)
	end
end

sgs.ai_skill_invoke.buyi = function(self, data)
	local dying = data:toDying()
	local isFriend = false
	local allBasicCard = true
	if dying.who:isKongcheng() then return false end

	isFriend = not self:isEnemy(dying.who)
	if not sgs.GetConfig("EnableHegemony", false) and self.role == "renegade" and not (dying.who:isLord() or dying.who:objectName() == self.player:objectName()) and
		(sgs.current_mode_players["loyalist"] == sgs.current_mode_players["rebel"] or self.room:getCurrent():objectName() == self.player:objectName()) then
		isFriend = false
	end

	local knownNum = 0
	local cards = dying.who:getHandcards()
	for _, card in sgs.qlist(cards) do
		local flag = string.format("%s_%s_%s","visible", self.player:objectName(), dying.who:objectName())
		if dying.who:objectName() == self.player:objectName() or card:hasFlag("visible") or card:hasFlag(flag) then
			knownNum = knownNum + 1
			if card:getTypeId() ~= sgs.Card_TypeBasic then allBasicCard = false end
		end
	end
	if knownNum < dying.who:getHandcardNum() then allBasicCard = false end

	return isFriend and not allBasicCard
end

sgs.ai_choicemade_filter.skillInvoke.buyi = function(player, promptlist)
	if promptlist[#promptlist] == "yes" then
		local dying
		for _, p in sgs.qlist(player:getRoom():getOtherPlayers(player)) do
			if p:hasFlag("dying") then
				dying = p
				break
			end
		end
		if dying then sgs.updateIntention(player, dying, -80) end
	end
end

sgs.ai_cardshow.buyi = function(self, requestor)
	assert(self.player:objectName() == requestor:objectName())

	local cards = self.player:getHandcards()
	for _, card in sgs.qlist(cards) do
		if card:getTypeId() ~= sgs.Card_TypeBasic then
			return card
		end
	end

	return self.player:getRandomHandCard()
end

mingce_skill = {}
mingce_skill.name = "mingce"
table.insert(sgs.ai_skills, mingce_skill)
mingce_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("MingceCard") then return end

	local card
	if self.player:getArmor() and (self.player:getArmor():objectName() == "silver_lion" and self.player:isWounded()) then
		card = self.player:getArmor()
	end
	if not card then
		local hcards = self.player:getCards("h")
		hcards = sgs.QList2Table(hcards)
		self:sortByUseValue(hcards, true)

		for _, hcard in ipairs(hcards) do
			if hcard:isKindOf("Slash") or hcard:isKindOf("EquipCard") then
				card = hcard
				break
			end
		end
	end
	if card then
		card = sgs.Card_Parse("@MingceCard=" .. card:getEffectiveId())
		return card
	end

	return nil
end

sgs.ai_skill_use_func.MingceCard = function(card, use, self)
	local target
	local friends = self.friends_noself
	local slash = sgs.Sanguosha:cloneCard("slash")

	local canMingceTo = function(player)
		local canGive = not (player:hasSkill("kongcheng") and player:isKongcheng())
		return canGive or (not canGive and self:getEnemyNumBySeat(self.player, player) == 0)
	end

	self:sort(self.enemies, "defense")
	for _, friend in ipairs(friends) do
		if canMingceTo(friend) then
			for _, enemy in ipairs(self.enemies) do
				if friend:canSlash(enemy) and not self:slashProhibit(slash, enemy) and sgs.getDefenseSlash(enemy) <= 2
					and self:slashIsEffective(slash, enemy) and sgs.isGoodTarget(enemy, self.enemies, self)
					and enemy:objectName() ~= self.player:objectName() then
					target = friend
					break
				end
			end
		end
		if target then break end
	end

	if not target then
		self:sort(friends, "defense")
		for _, friend in ipairs(friends) do
			if canMingceTo(friend) then
				target = friend
				break
			end
		end
	end

	if target then
		use.card = card
		if use.to then
			use.to:append(target)
		end
	end
end

sgs.ai_skill_choice.mingce = function(self, choices)
	local chengong = self.room:getCurrent()
	if not self:isFriend(chengong) and self:isWeak() then return "draw" end
	local slash = sgs.Sanguosha:cloneCard("slash")
	for _, player in sgs.qlist(self.room:getAlivePlayers()) do
		if player:hasFlag("MingceTarget") then
			if self:isEnemy(player) and not self:slashProhibit(slash, player) and sgs.getDefenseSlash(player) <= 2
				and self:slashIsEffective(slash, player) and sgs.isGoodTarget(player, self.enemies, self) then
				return "use"
			else
				return "draw"
			end
		end
	end
	return "draw"
end

sgs.ai_skill_playerchosen.mingce = function(self, targets)
	targets = sgs.QList2Table(targets)
	local slash = sgs.Sanguosha:cloneCard("slash")
	for _, target in ipairs(targets) do
		if self:isEnemy(target) and not self:slashProhibit(slash, target) and sgs.getDefenseSlash(target) <= 2
			and self:slashIsEffective(slash, target) and sgs.isGoodTarget(target, self.enemies, self)
			and target:objectName() ~= self.player:objectName() then
			return target
		end
	end
	return sgs.ai_skill_playerchosen.zero_card_as_slash(self, targets)
end

sgs.ai_playerchosen_intention.mingce = 80

sgs.ai_use_value.MingceCard = 5.9
sgs.ai_use_priority.MingceCard = 4
sgs.ai_card_intention.MingceCard = -70

sgs.ai_cardneed.mingce = sgs.ai_cardneed.equip

local jinjiu_skill = {}
jinjiu_skill.name = "jinjiu"
table.insert(sgs.ai_skills, jinjiu_skill)
jinjiu_skill.getTurnUseCard = function(self)
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	local anal_card

	self:sortByUseValue(cards, true)

	for _, card in ipairs(cards) do
		if card:isKindOf("Analeptic") then
			anal_card = card
			break
		end
	end

	if anal_card then
		local suit = anal_card:getSuitString()
		local number = anal_card:getNumberString()
		local card_id = anal_card:getEffectiveId()
		local card_str = ("slash:jinjiu[%s:%s]=%d"):format(suit, number, card_id)
		local slash = sgs.Card_Parse(card_str)

		return slash
	end
end

local xianzhen_skill = {}
xianzhen_skill.name = "xianzhen"
table.insert(sgs.ai_skills, xianzhen_skill)
xianzhen_skill.getTurnUseCard = function(self)
	if not self.player:hasUsed("XianzhenCard") and not self.player:isKongcheng() then return sgs.Card_Parse("@XianzhenCard=.")
	elseif self.player:hasUsed("XianzhenCard") and self.player:hasFlag("xianzhen_success") then
		local card_str = "@XianzhenSlashCard=."
		local card = sgs.Card_Parse(card_str)
		return card
	end
end

sgs.ai_skill_use_func.XianzhenSlashCard = function(card, use, self)
	local target = self.player:getTag("XianzhenTarget"):toPlayer()
	if not target or self:askForUseCard("slash", "@xianzhen-slash", sgs.Card_MethodUse) == "." then return end

	if self:getCard("Slash") and self.player:canSlash(target, nil, false) and target:isAlive() then
		use.card = card
	end
end

sgs.ai_skill_use_func.XianzhenCard = function(card, use, self)
	self:sort(self.enemies, "handcard")
	local max_card = self:getMaxCard()
	local max_point = max_card:getNumber()
	local slashcount = self:getCardsNum("Slash")
	if max_card:isKindOf("Slash") then slashcount = slashcount - 1 end

	if slashcount > 0 then
		local slash = self:getCard("Slash")
		assert(slash)
		local dummy_use = { isDummy = true }
		self:useBasicCard(slash, dummy_use)
		for _, enemy in ipairs(self.enemies) do
			if not (enemy:hasSkill("kongcheng") and enemy:getHandcardNum() == 1) and not enemy:isKongcheng() and self:canAttack(enemy, self.player) then
				local enemy_max_card = self:getMaxCard(enemy)
				local enemy_max_point = enemy_max_card and enemy_max_card:getNumber() or 100
				if max_point > enemy_max_point then
					use.card = sgs.Card_Parse("@XianzhenCard=" .. max_card:getId())
					if use.to then use.to:append(enemy) end
					return
				end
			end
		end
		for _, enemy in ipairs(self.enemies) do
			if not (enemy:hasSkill("kongcheng") and enemy:getHandcardNum() == 1) and not enemy:isKongcheng() and self:canAttack(enemy, self.player) then
				if max_point >= 10 then
					use.card = sgs.Card_Parse("@XianzhenCard=" .. max_card:getId())
					if use.to then use.to:append(enemy) end
					return
				end
			end
		end
	end
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards, true)
	if self:getUseValue(cards[1]) >= 6 or self:getKeepValue(cards[1]) >= 6 then return end
	local shouldUse = self:getOverflow() > 0
	if shouldUse then
		for _, enemy in ipairs(self.enemies) do
			if not (enemy:hasSkill("kongcheng") and enemy:getHandcardNum() == 1) and not enemy:isKongcheng() and not enemy:hasSkill("tuntian") then
				use.card = sgs.Card_Parse("@XianzhenCard=" .. cards[1]:getId())
				if use.to then use.to:append(enemy) end
				return
			end
		end
	end
end

sgs.ai_cardneed.xianzhen = function(to, card, self)
	local cards = to:getHandcards()
	local has_big = false
	for _, c in sgs.qlist(cards) do
		local flag = string.format("%s_%s_%s", "visible", self.room:getCurrent():objectName(), to:objectName())
		if c:hasFlag("visible") or c:hasFlag(flag) then
			if c:getNumber() > 10 then
				has_big = true
				break
			end
		end
	end
	if not has_big then
		return card:getNumber() > 10
	else
		return card:isKindOf("Slash") or card:isKindOf("Analeptic")
	end
end

function sgs.ai_skill_pindian.xianzhen(minusecard, self, requestor)
	if self:isFriend(requestor) then return end
	if requestor:getHandcardNum() <= 2 then return minusecard end
end

sgs.ai_card_intention.XianzhenCard = 70

sgs.dynamic_value.control_card.XianzhenCard = true

sgs.ai_use_value.XianzhenCard = 9.2
sgs.ai_use_priority.XianzhenCard = 9.2

sgs.ai_skill_cardask["@xianzhen-slash"] = function(self)
	local target = self.player:getTag("XianzhenTarget"):toPlayer()
	local slashes = self:getCards("Slash")
	for _, slash in ipairs(slashes) do
		if self.player:canSlash(target, slash) and not self:slashProhibit(slash, target)
			and self:slashIsEffective(slash, target) then
			return slash:toString()
		end
	end
	return "."
end

sgs.ai_use_value.XianzhenSlashCard = 9.2
sgs.ai_use_priority.XianzhenSlashCard = 2.45

sgs.ai_skill_invoke.shangshi = function(self, data)
	if self.player:getLostHp() == 1 then return sgs.ai_skill_invoke.lianying(self, data) end
	return true
end

sgs.ai_skill_invoke.quanji = true

sgs.ai_skill_discard.quanji = function(self)
	local to_discard = {}
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)

	table.insert(to_discard, cards[1]:getEffectiveId())

	return to_discard
end

sgs.ai_skill_choice.zili = function(self, choice)
	if self.player:getHp() < self.player:getMaxHp()-1 then return "recover" end
	return "draw"
end

local paiyi_skill = {}
paiyi_skill.name = "paiyi"
table.insert(sgs.ai_skills, paiyi_skill)
paiyi_skill.getTurnUseCard = function(self)
	if not (self.player:getPile("power"):isEmpty()
		or self.player:hasUsed("PaiyiCard")) then
		return sgs.Card_Parse("@PaiyiCard=.")
	end
end

sgs.ai_skill_use_func.PaiyiCard = function(card, use, self)
	local target
	self:sort(self.friends_noself, "defense")
	for _, friend in ipairs(self.friends_noself) do
		if friend:getHandcardNum() < 2 and friend:getHandcardNum() + 1 < self.player:getHandcardNum() then
			target = friend
		end
		if target then break end
	end
	if not target then
		if self.player:getHandcardNum() < self.player:getHp() + self.player:getPile("power"):length() - 1 then
			target = self.player
		end
	end
	self:sort(self.friends_noself, "hp")
	self.friends_noself = sgs.reverse(self.friends_noself)
	if not target then
		for _, friend in ipairs(self.friends_noself) do
			if friend:getHandcardNum() > 1 and friend:getHandcardNum() + 2 > self.player:getHandcardNum()
			and self:hasSkills("jieming|yiji|xinsheng|fangzhu|guixin", friend) then
				target = friend
			end
			if target then break end
		end
	end
	self:sort(self.enemies, "defense")
	if not target then
		for _, enemy in ipairs(self.enemies) do
			if not self:hasSkills(sgs.masochism_skill, enemy) and not self:hasSkills("rende|jijiu|tianxiang", enemy)
				and enemy:getHandcardNum() + 2 > self.player:getHandcardNum() then
				target = enemy
			end
			if target then break end
		end
	end

	if target then
		use.card = sgs.Card_Parse("@PaiyiCard=.")
		if use.to then
			use.to:append(target)
		end
	end
end

sgs.ai_skill_askforag.paiyi = function(self, card_ids)
	self.paiyi = card_ids[math.random(1, #card_ids)]
	return self.paiyi
end