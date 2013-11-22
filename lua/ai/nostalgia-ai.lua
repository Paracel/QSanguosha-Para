sgs.weapon_range.MoonSpear = 3
sgs.ai_use_priority.MoonSpear = 2.635

nosjujian_skill = {}
nosjujian_skill.name = "nosjujian"
table.insert(sgs.ai_skills, nosjujian_skill)
nosjujian_skill.getTurnUseCard = function(self)
	if not self.player:hasUsed("NosJujianCard") then return sgs.Card_Parse("@NosJujianCard=.") end
end

sgs.ai_skill_use_func.NosJujianCard = function(card, use, self)
	local abandon_card = {}
	local index = 0
	local hasPeach = (self:getCardsNum("Peach") > 0)
	local to

	local trick_num, basic_num, equip_num = 0, 0, 0
	if not hasPeach and self.player:isWounded() and self.player:getCards("he"):length() >=3 then
		local cards = self.player:getCards("he")
		cards = sgs.QList2Table(cards)
		self:sortByUseValue(cards, true)
		for _, card in ipairs(cards) do
			if card:getTypeId() == sgs.Card_TypeTrick and not isCard("ExNihilo", card, self.player) then trick_num = trick_num + 1
			elseif card:getTypeId() == sgs.Card_TypeBasic then basic_num = basic_num + 1
			elseif card:getTypeId() == sgs.Card_TypeEquip then equip_num = equip_num + 1
			end
		end
		local result_class
		if trick_num >= 3 then result_class = "TrickCard"
		elseif equip_num >= 3 then result_class = "EquipCard"
		elseif basic_num >= 3 then result_class = "BasicCard"
		end

		for _, fcard in ipairs(cards) do
			if fcard:isKindOf(result_class) and not fcard:isKindOf("ExNihilo") then
				table.insert(abandon_card, fcard:getId())
				index = index + 1
				if index == 3 then break end
			end
		end

		if index == 3 then
			to = self:findPlayerToDraw(false, 3)
			if not to then return end
			if use.to then use.to:append(to) end
			use.card = sgs.Card_Parse("@NosJujianCard=" .. table.concat(abandon_card, "+"))
			return
		end
	end

	abandon_card = {}
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards, true)
	local slash_num = self:getCardsNum("Slash")
	local jink_num = self:getCardsNum("Jink")
	index = 0
	for _, card in ipairs(cards) do
		if index >= 3 then break end
		if card:isKindOf("TrickCard") and not card:isKindOf("Nullification") then
			table.insert(abandon_card, card:getId())
			index = index + 1
		elseif card:isKindOf("EquipCard") then
			table.insert(abandon_card, card:getId())
			index = index + 1
		elseif card:isKindOf("Slash") and slash_num > 1 then
			table.insert(abandon_card, card:getId())
			index = index + 1
			slash_num = slash_num - 1
		elseif card:isKindOf("Jink") and jink_num > 1 then
			table.insert(abandon_card, card:getId())
			index = index + 1
			jink_num = jink_num - 1
		end
	end

	if index == 3 then
		to = self:findPlayerToDraw(false, 3)
		if not to then return end
		if use.to then use.to:append(to) end
		use.card = sgs.Card_Parse("@NosJujianCard=" .. table.concat(abandon_card, "+"))
		return
	end

	if self:getOverflow() > 0 then
		local discard = self:askForDiscard("dummyreason", math.min(self:getOverflow(), 3), nil, false, true)
		to = self:findPlayerToDraw(false, math.min(self:getOverflow(), 3))
		if not to then return end
		use.card = sgs.Card_Parse("@NosJujianCard=" .. table.concat(discard, "+"))
		if use.to then use.to:append(to) end
		return
	end

	if index > 0 then
		to = self:findPlayerToDraw(false, index)
		if not to then return end
		use.card = sgs.Card_Parse("@NosJujianCard=" .. table.concat(abandon_card, "+"))
		if use.to then use.to:append(to) end
		return
	end
end

sgs.ai_use_priority.NosJujianCard = 0
sgs.ai_use_value.NosJujianCard = 6.7

sgs.ai_card_intention.NosJujianCard = -100

sgs.dynamic_value.benefit.NosJujianCard = true

sgs.ai_skill_cardask["@enyuanheart"] = function(self)
	if self:needToLoseHp() then return "." end
	local damage = data:toDamage()
	if self:isFriend(damage.to) then return end

	local cards = self.player:getHandcards()
	for _, card in sgs.qlist(cards) do
		if card:getSuit() == sgs.Card_Heart
			and not (isCard("Peach", card, self.player) or (isCard("ExNihilo", card, self.player) and self.player:getPhase() == sgs.Player_Play)) then
			return card:getEffectiveId()
		end
	end
	return "."
end

function sgs.ai_slash_prohibit.nosenyuan(self, from, to, card)
	if from:hasSkill("jueqing") or (from:hasSkill("nosqianxi") and from:distanceTo(to) == 1) then return false end
	if from:hasFlag("NosJiefanUsed") then return false end
	if self:needToLoseHp(from) then return false end
	if from:getHp() > 3 then return false end

	local n = 0
	local cards = from:getHandcards()
	for _, hcard in sgs.qlist(cards) do
		if hcard:getSuit() == sgs.Card_Heart and not (isCard("Peach", hcard, to) or isCard("ExNihilo", hcard, to)) then
			if not hcard:isKindOf("Slash") then return false end
			n = n + 1
			if n > 1 then return false end
		end
	end
	if n == 1 then return card:getSuit() == sgs.Card_Heart end
	return self:isWeak(from)
end

sgs.ai_need_damaged.nosenyuan = function(self, attacker, player)
	if self:isEnemy(attacker, player) and self:isWeak(attacker) then
		return true
	end
	return false
end

nosxuanhuo_skill = {}
nosxuanhuo_skill.name = "nosxuanhuo"
table.insert(sgs.ai_skills, nosxuanhuo_skill)
nosxuanhuo_skill.getTurnUseCard = function(self)
	if not self.player:hasUsed("NosXuanhuoCard") then
		return sgs.Card_Parse("@NosXuanhuoCard=.")
	end
end

sgs.ai_skill_use_func.NosXuanhuoCard = function(card, use, self)
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)

	local target
	for _, friend in ipairs(self.friends_noself) do
		if self:hasSkills(sgs.lose_equip_skill, friend) and not friend:getEquips():isEmpty() and not friend:hasSkill("manjuan") then
			target = friend
			break
		end
	end
	if not target then
		for _, enemy in ipairs(self.enemies) do
			if self:getDangerousCard(enemy) then
				target = enemy
				break
			end
		end
	end
	if not target then
		for _, friend in ipairs(self.friends_noself) do
			if self:needToThrowArmor(friend) and not friend:hasSkill("manjuan") then
				target = friend
				break
			end
		end
	end
	if not target then
		self:sort(self.enemies, "handcard")
		for _, enemy in ipairs(self.enemies) do
			if self:getValuableCard(enemy) then
				target = enemy
				break
			end
			if target then break end

			local cards = sgs.QList2Table(enemy:getHandcards())
			local flag = string.format("%s_%s_%s", "visible", self.player:objectName(), enemy:objectName())
			if not enemy:isKongcheng() and not enemy:hasSkills("tuntian+zaoxian") then
				for _, cc in ipairs(cards) do
					if (cc:hasFlag("visible") or cc:hasFlag(flag)) and (cc:isKindOf("Peach") or cc:isKindOf("Analeptic")) then
						target = enemy
						break
					end
				end
			end
			if target then break end

			if self:getValuableCard(enemy) then
				target = enemy
				break
			end
			if target then break end
		end
	end
	if not target then
		for _, friend in ipairs(self.friends_noself) do
			if friend:hasSkills("tuntian+zaoxian") and not friend:hasSkill("manjuan") then
				target = friend
				break
			end
		end
	end
	if not target then
		for _, enemy in ipairs(self.enemies) do
			if not enemy:isNude() and enemy:hasSkill("manjuan") then
				target = enemy
				break
			end
		end
	end

	if target then
		local heart_card
		if self:isFriend(target) then
			for _, card in ipairs(cards) do
				if card:getSuit() == sgs.Card_Heart then
					heart_card = card
					break
				end
			end
		else
			for _, card in ipairs(cards) do
				if card:getSuit() == sgs.Card_Heart and not isCard("Peach", card, target) and not isCard("Nullification", card, target) then
					heart_card = card
					break
				end
			end
		end

		if heart_card then
			target:setFlags("AI_NosXuanhuoTarget")
			use.card = sgs.Card_Parse("@NosXuanhuoCard=" .. heart_card:getEffectiveId())
			if use.to then use.to:append(target) end
		end
	end
end

sgs.ai_skill_playerchosen.nosxuanhuo = function(self, targets)
	for _, player in sgs.qlist(targets) do
		if (player:getHandcardNum() <= 2 or player:getHp() < 2) and self:isFriend(player)
			and not player:hasFlag("AI_NosXuanhuoTarget") and not self:needKongcheng(player, true) and not player:hasSkill("manjuan") then
			return player
		end
	end
	for _, player in sgs.qlist(targets) do
		if self:isFriend(player)
			and not player:hasFlag("AI_NosXuanhuoTarget") and not self:needKongcheng(player, true) and not player:hasSkill("manjuan") then
			return player
		end
	end
	for _, player in sgs.qlist(targets) do
		if player == self.player then
			return player
		end
	end
end

sgs.nosxuanhuo_suit_value = {
	heart = 3.9
}

sgs.ai_chaofeng.nos_fazheng = -3

sgs.ai_cardneed.nosxuanhuo = function(to, card)
	return card:getSuit() == sgs.Card_Heart
end

sgs.ai_skill_choice.nosxuanfeng = function(self, choices)
	self:sort(self.enemies, "defense")
	local slash = sgs.Sanguosha:cloneCard("slash")
	for _, enemy in ipairs(self.enemies) do
		if self.player:distanceTo(enemy) <= 1 then
			return "damage"
		elseif not self:slashProhibit(slash, enemy) and self:slashIsEffective(slash, enemy) and sgs.isGoodTarget(enemy, self.enemies, self) then
			return "slash"
		end
	end
	return "nothing"
end

sgs.ai_skill_playerchosen.nosxuanfeng_damage = sgs.ai_skill_playerchosen.damage
sgs.ai_skill_playerchosen.nosxuanfeng_slash = sgs.ai_skill_playerchosen.zero_card_as_slash

sgs.ai_playerchosen_intention.nosxuanfeng_damage = 80
sgs.ai_playerchosen_intention.nosxuanfeng_slash = 80

sgs.nosxuanfeng_keep_value = sgs.xiaoji_keep_value

sgs.ai_skill_invoke.nosshangshi = sgs.ai_skill_invoke.shangshi

sgs.ai_view_as.nosgongqi = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card_place ~= sgs.Player_PlaceSpecial and card:getTypeId() == sgs.Card_TypeEquip and not card:hasFlag("using") then
		return ("slash:nosgongqi[%s:%s]=%d"):format(suit, number, card_id)
	end
end

local nosgongqi_skill = {}
nosgongqi_skill.name = "nosgongqi"
table.insert(sgs.ai_skills, nosgongqi_skill)
nosgongqi_skill.getTurnUseCard = function(self, inclusive)
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)

	local equip_card
	self:sortByUseValue(cards, true)

	for _, card in ipairs(cards) do
		if card:getTypeId() == sgs.Card_TypeEquip and (self:getUseValue(card) < sgs.ai_use_value.Slash or inclusive) then
			equip_card = card
			break
		end
	end

	if equip_card then
		local suit = equip_card:getSuitString()
		local number = equip_card:getNumberString()
		local card_id = equip_card:getEffectiveId()
		local card_str = ("slash:nosgongqi[%s:%s]=%d"):format(suit, number, card_id)
		local slash = sgs.Card_Parse(card_str)

		assert(slash)

		return slash
	end
end


function sgs.ai_cardneed.nosgongqi(to, card)
	return card:getTypeId() == sgs.Card_TypeEquip and getKnownCard(to, "EquipCard", true) == 0
end

function sgs.ai_cardsview_valuable.nosjiefan(self, class_name, player)
	if class_name == "Peach" and not player:hasFlag("Global_NosJiefanFailed") then
		local dying = player:getRoom():getCurrentDyingPlayer()
		if not dying then return nil end
		local current = player:getRoom():getCurrent()
		if not current or current:isDead() or current:getPhase() == sgs.Player_NotActive
			or current:objectName() == player:objectName() or (current:hasSkill("wansha") and player:objectName() ~= dying:objectName())
			or (self:isEnemy(current) and self:findLeijiTarget(current, 50, player)) then return nil end
		return "@NosJiefanCard=."
	end
end

sgs.ai_card_intention.NosJiefanCard = sgs.ai_card_intention.Peach

sgs.ai_skill_cardask["nosjiefan-slash"] = function(self, data, pattern, target)
	if self:isEnemy(target) and self:findLeijiTarget(target, 50, self.player) then return "." end
	for _, slash in ipairs(self:getCards("Slash")) do
		if self:slashIsEffective(slash, target) then
			return slash:toString()
		end
	end
	return "."
end

function sgs.ai_cardneed.nosjiefan(to, card)
	return isCard("Slash", card, to) and getKnownCard(to, "Slash", true) == 0
end

sgs.ai_skill_invoke.nosfuhun = function(self, data)
	local target = 0
	for _, enemy in ipairs(self.enemies) do
		if (self.player:distanceTo(enemy) <= self.player:getAttackRange()) then target = target + 1 end
	end
	return target > 0 and not self.player:isSkipped(sgs.Player_Play)
end

sgs.ai_skill_invoke.noszhenlie = function(self, data)
	local judge = data:toJudge()
	if not judge:isGood() then
	return true end
	return false
end

sgs.ai_skill_playerchosen.nosmiji = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
	local n = self.player:getLostHp()
	if self.player:getPhase() == sgs.Player_Start then
		if self.player:getHandcardNum() - n < 2 and not self:needKongcheng() and not self:willSkipPlayPhase() then return self.player end
	elseif self.player:getPhase() == sgs.Player_Finish then
		if self.player:getHandcardNum() - n < 2 and not self:needKongcheng() then return self.player end
	end
	local to = self:findPlayerToDraw(true, n)
	return to or self.player
end

sgs.ai_playerchosen_intention.nosmiji = function(self, from, to)
	if not (self:needKongcheng(to, true) and from:getLostHp() == 1)
		and not (to:hasSkill("manjuan") and to:getPhase() == sgs.Player_NotActive) then
		sgs.updateIntention(from, to, -80)
	end
end

sgs.ai_skill_invoke.nosqianxi = function(self, data)
	local damage = data:toDamage()
	local target = damage.to
	if self:isFriend(target) then return false end
	if target:getLostHp() >= 2 and target:getHp() <= 1 then return false end
	if target:hasSkills(sgs.masochism_skill .. "|" .. sgs.recover_skill .. "|longhun|buqu|nosbuqu") then return true end
	if self:hasHeavySlashDamage(self.player, damage.card, target) then return false end
	return (target:getMaxHp() - target:getHp()) < 2
end

function sgs.ai_cardneed.nosqianxi(to, card)
	return isCard("Slash", card, to) and getKnownCard(to, "Slash", true) == 0
end

sgs.ai_skill_invoke.noszhenggong = function(self, data)
	local target = data:toPlayer()

	if target:getCards("e"):length() == 1 and target:getArmor() and self:hasSkills("bazhen|yizhong") then return false end
	if self:hasSkills(sgs.lose_equip_skill, target) and not (self:isFriend(target) and not self:isWeak(target)) then return false end
	local benefit = (target:getCards("e"):length() == 1 and target:getArmor() and self:needToThrowArmor(target))
	if not self:isFriend(target) then benefit = not benefit end
	if not benefit then return false end

	for i = 0, 3 do
		if not self.player:getEquip(i) and target:getEquip(i) and not (i == 1 and self:hasSkills("bazhen|yizhong")) then
			return true
		end
	end
	if target:getArmor() and self:evaluateArmor(target:getArmor()) >= self:evaluateArmor(self.player:getArmor()) then return true end
	if target:getDefensiveHorse() or target:getOffensiveHorse() then return true end
	if target:getWeapon() and self:evaluateWeapon(target:getWeapon()) >= self:evaluateWeapon(self.player:getWeapon()) then return true end

	return false
end

function sgs.ai_cardneed.noszhenggong(to, card, self)
	if not to:containsTrick("indulgence") and to:getMark("nosbaijiang") == 0 then
		return card:getTypeId() == sgs.Card_TypeEquip
	end
end

sgs.ai_skill_cardchosen.noszhenggong = function(self, who, flags)
	for i = 0, 3 do
		if not self.player:getEquip(i) and who:getEquip(i) and not (i == 1 and self:hasSkills("bazhen|yizhong")) then
			return who:getEquip(i)
		end
	end
	if who:getArmor() and self:evaluateArmor(who:getArmor()) >= self:evaluateArmor(self.player:getArmor()) then return who:getArmor() end
	if who:getDefensiveHorse() then return who:getDefensiveHorse() end
	if who:getOffensiveHorse() then return who:getOffensiveHorse() end
	if who:getWeapon() and self:evaluateWeapon(who:getWeapon()) >= self:evaluateWeapon(self.player:getWeapon()) then return who:getWeapon() end

	return sgs.Sanguosha:getCard(self:askForCardChosen(who, flags, "dummy"))
end

sgs.ai_skill_invoke.nosquanji = function(self, data)
	local current = self.room:getCurrent()
	if self:isFriend(current) then
		if current:hasSkill("zhiji") and not current:hasSkill("guanxing") and current:getHandcardNum() == 1 then
			self.nosquanji_card = self:getMinCard(self.player):getId()
			return true
		end

	elseif self:isEnemy(current) then
		if self.player:getHandcardNum() <= 1 and not self:needKongcheng(self.player) then return "." end
		local invoke = false
		if current:hasSkill("yinghun") and current:getLostHp() > 2 then invoke = true end
		if current:hasSkill("luoshen") and not self:isWeak() then invoke = true end
		if current:hasSkill("baiyin") and not current:hasSkill("jilve") and current:getMark("@bear") >= 4 then invoke = true end
		if current:hasSkill("zaoxian") and not current:hasSkill("jixi") and current:getPile("field"):length() >= 3 then invoke = true end
		if current:hasSkill("zili") and not current:hasSkill("paiyi") and current:getPile("power"):length() >= 3 then invoke = true end
		if current:hasSkill("hunzi") and not current:hasSkill("yingzi") and current:getHp() == 1 then invoke = true end
		if current:hasSkill("zuixiang") and current:getMark("@dream") > 0 then invoke = true end
		if self:isWeak(current) and self.player:getHandcardNum() > 1 and current:getCards("j"):isEmpty() then invoke = true end

		if invoke and self:getMaxCard(self.player):getNumber() > 7 then
			self.nosquanji_card = self:getMaxCard(self.player):getId()
			return true
		end
	end

	return false
end

sgs.ai_skill_invoke.nosyexin = function(self, data)
	return true
end

local nosyexin_skill = {}
nosyexin_skill.name = "nosyexin"
table.insert(sgs.ai_skills, nosyexin_skill)
nosyexin_skill.getTurnUseCard = function(self)
	if self.player:getPile("nospower"):isEmpty() or self.player:hasUsed("NosYexinCard") then
		return
	end

	return sgs.Card_Parse("@NosYexinCard=.")
end

sgs.ai_skill_use_func.NosYexinCard = function(card, use, self)
	use.card = sgs.Card_Parse("@NosYexinCard=.")
end

sgs.ai_skill_askforag.nosyexin = function(self, card_ids)
	local cards = {}
	for _, card_id in ipairs(card_ids) do
		table.insert(cards, sgs.Sanguosha:getCard(card_id))
	end
	self:sortByCardNeed(cards)
	return cards[#cards]:getEffectiveId()
end

sgs.ai_skill_invoke.nospaiyi = function(self, data)
	return true
end

sgs.ai_skill_askforag.nospaiyi = function(self, card_ids)
	local cards = {}
	for _, card_id in ipairs(card_ids) do
		table.insert(cards, sgs.Sanguosha:getCard(card_id))
	end
	self:sortByCardNeed(cards)

	for _, acard in ipairs(cards) do
		if acard:isKindOf("Indulgence") or acard:isKindOf("SupplyShortage") then
			sgs.nosPaiyiCard = acard
			return acard:getEffectiveId()
		end
	end

	local card = cards[#cards]
	sgs.nosPaiyiCard = card
	return card:getEffectiveId()
end

local function hp_subtract_handcard(a, b)
	local diff1 = a:getHp() - a:getHandcardNum()
	local diff2 = b:getHp() - b:getHandcardNum()

	return diff1 < diff2
end

local function handcard_subtract_hp(a, b)
	local diff1 = a:getHandcardNum() - a:getHp()
	local diff2 = b:getHandcardNum() - b:getHp()

	return diff1 < diff2
end

sgs.ai_skill_playerchosen.nospaiyi = function(self, targets)
	if sgs.nosPaiyiCard:isKindOf("Indulgence") then
		table.sort(self.enemies, hp_subtract_handcard)

		local enemies = self.enemies
		for _, enemy in ipairs(enemies) do
			if enemy:hasSkills("noslijian|lijian|fanjian") and not enemy:containsTrick("indulgence") and not enemy:isKongcheng() and enemy:faceUp() and self:objectiveLevel(enemy) > 3 then
				sgs.nosPaiyiTarget = enemy
				sgs.nosPaiyiCard = nil
				return enemy
			end
		end

		for _, enemy in ipairs(enemies) do
			if not enemy:containsTrick("indulgence") and not enemy:hasSkill("keji") and enemy:faceUp() and self:objectiveLevel(enemy) > 3 then
				sgs.nosPaiyiTarget = enemy
				sgs.nosPaiyiCard = nil
				return enemy
			end
		end
	end

	if sgs.nosPaiyiCard:isKindOf("SupplyShortage") then
		table.sort(self.enemies, handcard_subtract_hp)

		local enemies = self.enemies
		for _, enemy in ipairs(enemies) do
			if (self:hasSkills("yongsi|haoshi|tuxi", enemy) or (enemy:hasSkill("zaiqi") and enemy:getLostHp() > 1))
				and not enemy:containsTrick("supply_shortage") and enemy:faceUp() and self:objectiveLevel(enemy) > 3 then
				sgs.nosPaiyiTarget = enemy
				sgs.nosPaiyiCard = nil
				return enemy
			end
		end
		for _, enemy in ipairs(enemies) do
			if (#enemies == 1 or not self:hasSkills("tiandu|guidao", enemy)) and not enemy:containsTrick("supply_shortage") and enemy:faceUp() and self:objectiveLevel(enemy) > 3 then
				sgs.nosPaiyiTarget = enemy
				sgs.nosPaiyiCard = nil
				return enemy
			end
		end
	end

	targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
	for _, target in ipairs(targets) do
		if self:isEnemy(target) and target:hasSkill("zhiji") and not target:hasSkill("guanxing") and target:getHandcardNum() == 0 then
			sgs.nosPaiyiTarget = target
			sgs.nosPaiyiCard = nil
			return target
		end
	end

	for _, target in ipairs(targets) do
		if self:isFriend(target) and target:objectName() ~= self.player:objectName() then
			sgs.nosPaiyiTarget = target
			sgs.nosPaiyiCard = nil
			return target
		end
	end

	sgs.nosPaiyiTarget = self.player
	sgs.nosPaiyiCard = nil
	return self.player
end

sgs.ai_skill_choice.nospaiyi = function(self, choices)
	local choice_table = choices:split("+")
	if table.contains(choice_table, "Judging") and self:isEnemy(sgs.nosPaiyiTarget) then
		sgs.nosPaiyiTarget = nil
		return "Judging"
	end

	if table.contains(choice_table, "Equip") and self:isFriend(sgs.nosPaiyiTarget) then
		sgs.nosPaiyiTarget = nil
		return "Equip"
	end

	sgs.nosPaiyiTarget = nil
	return "Hand"
end

sgs.ai_skill_invoke.weiwudi_guixin = true

local function findPlayerForModifyKingdom(self, players)
	local lord = self.room:getLord()
	local isGood = self:isFriend(lord)

	for _, player in sgs.qlist(players) do
		if player:hasSkill("huashen") then
		elseif lord and not player:isLord() then
			if sgs.evaluatePlayerRole(player) == "loyalist" then
				local sameKingdom = player:getKingdom() == lord:getKingdom()
				if isGood ~= sameKingdom then
					return player
				end
			elseif lord:hasLordSkill("xueyi") and not player:isLord() then
				local isQun = player:getKingdom() == "qun"
				if isGood ~= isQun then
					return player
				end
			end
		end
	end
end

local function chooseKingdomForPlayer(self, to_modify)
	local lord = self.room:getLord()
	local isGood = lord and self:isFriend(lord)
	if sgs.evaluatePlayerRole(to_modify) == "loyalist" or sgs.evaluatePlayerRole(to_modify) == "renegade" then
		if isGood then
			return lord:getKingdom()
		else
			-- find a kingdom that is different from the lord
			if lord then
				local kingdoms = {"wei", "shu", "wu", "qun"}
				for _, kingdom in ipairs(kingdoms) do
					if lord:getKingdom() ~= kingdom then
						return kingdom
					end
				end
			end
		end
	elseif lord and lord:hasLordSkill("xueyi") and not to_modify:isLord() then
		return isGood and "qun" or "wei"
	elseif self.player:hasLordSkill("xueyi") then
		return "qun"
	end

	return "wei"
end

sgs.ai_skill_choice.weiwudi_guixin = function(self, choices)
	if choices == "wei+shu+wu+qun" then
		local to_modify = self.room:getTag("Guixin2Modify"):toPlayer()
		return chooseKingdomForPlayer(self, to_modify)
	end

	if choices ~= "modify+obtain" then
		if choices:match("xueyi") and not self.room:getLieges("qun", self.player):isEmpty() then return "xueyi" end
		if choices:match("ruoyu") then return "ruoyu" end
		local choice_table = choices:split("+")
		return choice_table[math.random(1, #choice_table)]
	end

	-- two choices: modify and obtain
	if self.player:getRole() == "renegade" or self.player:getRole() == "lord" then
		return "obtain"
	end

	local lord = self.room:getLord()
	local skills = lord:getVisibleSkillList()
	local hasLordSkill = false
	for _, skill in sgs.qlist(skills) do
		if skill:isLordSkill() then
			hasLordSkill = true
			break
		end
	end

	if not hasLordSkill then
		return "obtain"
	end

	local players = self.room:getOtherPlayers(self.player)
	players:removeOne(lord)
	if findPlayerForModifyKingdom(self, players) then
		return "modify"
	else
		return "obtain"
	end
end

sgs.ai_skill_playerchosen.weiwudi_guixin = function(self, players)
	local player = findPlayerForModifyKingdom(self, players)
	return player or players:first()
end

local noslijian_skill = {}
noslijian_skill.name = "noslijian"
table.insert(sgs.ai_skills, noslijian_skill)
noslijian_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("NosLijianCard") or self.player:isNude() then
		return
	end
	local card_id = self:getLijianCard()
	if card_id then return sgs.Card_Parse("@NosLijianCard=" .. card_id) end
end

sgs.ai_skill_use_func.NosLijianCard = function(card, use, self)
	local first, second = self:findLijianTarget("NosLijianCard", use)
	if first and second then
		use.card = card
		if use.to then
			use.to:append(first)
			use.to:append(second)
		end
	end
end

sgs.ai_use_value.NosLijianCard = sgs.ai_use_value.LijianCard
sgs.ai_use_priority.NosLijianCard = sgs.ai_use_priority.LijianCard
sgs.ai_card_intention.NosLijianCard = sgs.ai_card_intention.LijianCard

local nosrende_skill = {}
nosrende_skill.name = "nosrende"
table.insert(sgs.ai_skills, nosrende_skill)
nosrende_skill.getTurnUseCard = function(self)
	if self.player:isKongcheng() then return end
	local mode = string.lower(global_room:getMode())
	if self.player:getMark("nosrende") > 1 and mode:find("04_1v3") then return end

	if self:shouldUseRende() then
		return sgs.Card_Parse("@NosRendeCard=.")
	end
end

sgs.ai_skill_use_func.NosRendeCard = function(card, use, self)
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards, true)
	local name = self.player:objectName()
	local card, friend = self:getCardNeedPlayer(cards)
	if card and friend then
		if friend:objectName() == self.player:objectName() or not self.player:getHandcards():contains(card) then return end
		if friend:hasSkill("enyuan") and #cards >= 2 and not (self.room:getMode() == "04_1v3" and self.player:getMark("nosrende") == 1) then
			self:sortByUseValue(cards, true)
			for i = 1, #cards, 1 do
				if cards[i]:getId() ~= card:getId() then
					use.card = sgs.Card_Parse("@NosRendeCard=" .. card:getId() .. "+" .. cards[i]:getId())
					break
				end
			end
		else
			use.card = sgs.Card_Parse("@NosRendeCard=" .. card:getId())
		end
		if use.to then use.to:append(friend) end
		return
	else
		local pangtong = self.room:findPlayerBySkillName("manjuan")
		if not pangtong then return end
		if self.player:isWounded() and self.player:getHandcardNum() > 3 and self.player:getMark("nosrende") < 2 then
			self:sortByUseValue(cards, true)
			local to_give = {}
			for _, card in ipairs(cards) do
				if not isCard("Peach", card, self.player) and not isCard("ExNihilo", card, self.player) then table.insert(to_give, card:getId()) end
				if #to_give == 2 - self.player:getMark("nosrende") then break end
			end
			if #to_give > 0 then
				use.card = sgs.Card_Parse("@NosRendeCard=" .. table.concat(to_give, "+"))
				if use.to then use.to:append(pangtong) end
			end
		end
	end
end

sgs.ai_use_value.NosRendeCard = sgs.ai_use_value.RendeCard
sgs.ai_use_priority.NosRendeCard = sgs.ai_use_priority.RendeCard

sgs.ai_card_intention.NosRendeCard = sgs.ai_card_intention.RendeCard

sgs.dynamic_value.benefit.NosRendeCard = true

function sgs.ai_cardneed.nosjizhi(to, card)
	return card:isNDTrick()
end

sgs.nosjizhi_keep_value = sgs.jizhi_keep_value

sgs.ai_chaofeng.nos_huangyueying = sgs.ai_chaofeng.huangyueying

function sgs.ai_skill_invoke.nosjushou(self, data)
	local sbdiaochan = self.room:findPlayerBySkillName("lihun")
	if sbdiaochan and sbdiaochan:faceUp() and not self:willSkipPlayPhase(sbdiaochan)
		and (self:isEnemy(sbdiaochan) or (sgs.turncount <= 1 and sgs.evaluatePlayerRole(sbdiaochan) == "neutral")) then return false end
	if not self.player:faceUp() then return true end
	for _, friend in ipairs(self.friends) do
		if self:hasSkills("fangzhu|jilve", friend) then return true end
		if friend:hasSkill("junxing") and friend:faceUp() and not self:willSkipPlayPhase(friend)
			and not (friend:isKongcheng() and self:willSkipDrawPhase(friend)) then
			return true
		end
	end
	return self:isWeak()
end

sgs.ai_skill_askforag.nosbuqu = function(self, card_ids)
	for i, card_id in ipairs(card_ids) do
		for j, card_id2 in ipairs(card_ids) do
			if i ~= j and sgs.Sanguosha:getCard(card_id):getNumber() == sgs.Sanguosha:getCard(card_id2):getNumber() then
				return card_id
			end
		end
	end

	return card_ids[1]
end

function sgs.ai_skill_invoke.nosbuqu(self, data)
	if #self.enemies == 1 and self.enemies[1]:hasSkill("nosguhuo") then
		return false
	else
		local damage = data:toDamage()
		if self.player:getHp() == 1 and damage.to and damage:getReason() == "duwu" and self:getSaveNum(true) >= 1 then return false end
		return true
	end
end

sgs.ai_chaofeng.nos_zhoutai = -4

sgs.ai_skill_playerchosen.nosleiji = function(self, targets)
	local mode = self.room:getMode()
	if mode:find("_mini_17") or mode:find("_mini_19") or mode:find("_mini_20") or mode:find("_mini_26") then
		local players = self.room:getAllPlayers();
		for _, aplayer in sgs.qlist(players) do
			if aplayer:getState() ~= "robot" then
				return aplayer
			end
		end
	end

	self:updatePlayers()
	return self:findLeijiTarget(self.player, 100, nil, -1)
end

sgs.ai_playerchosen_intention.nosleiji = sgs.ai_playerchosen_intention.leiji

function sgs.ai_slash_prohibit.nosleiji(self, from, to, card)
	if self:isFriend(to, from) then return false end
	if to:hasFlag("QianxiTarget") and (not self:hasEightDiagramEffect(to) or self.player:hasWeapon("qinggang_sword")) then return false end
	local hcard = to:getHandcardNum()
	if from:hasSkill("liegong") and (hcard >= from:getHp() or hcard <= from:getAttackRange()) then return false end
	if from:hasSkill("kofliegong") and hcard >= from:getHp() then return false end
	if from:getRole() == "rebel" and to:isLord() then
		local other_rebel
		for _, player in sgs.qlist(self.room:getOtherPlayers(from)) do
			if sgs.evaluatePlayerRole(player) == "rebel" or sgs.compareRoleEvaluation(player, "rebel", "loyalist") == "rebel" then
				other_rebel = player
				break
			end
		end
		if not other_rebel and ((from:getHp() >= 4 and (getCardsNum("Peach", from) > 0 or from:hasSkills("ganglie|vsganglie"))) or from:hasSkill("hongyan")) then
			return false
		end
	end

	if getKnownCard(to, "Jink", true) >= 1 or (self:hasSuit("spade", true, to) and hcard >= 2) then return true end
	if self:hasEightDiagramEffect(to) then return true end
end

sgs.ai_cardneed.nosleiji = sgs.ai_cardneed.leiji

table.insert(sgs.ai_global_flags, "questioner")

sgs.ai_skill_choice.nosguhuo = function(self, choices)
	local yuji = self.room:findPlayerBySkillName("nosguhuo")
	local nosguhuoname = self.room:getTag("NosGuhuoType"):toString()
	if nosguhuoname == "peach+analeptic" then nosguhuoname = "peach" end
	if nosguhuoname == "normal_slash" then nosguhuoname = "slash" end
	local nosguhuocard = sgs.Sanguosha:cloneCard(nosguhuoname)
	local nosguhuotype = nosguhuocard:getClassName()
	if nosguhuotype and self:getRestCardsNum(nosguhuotype, yuji) == 0 and self.player:getHp() > 0 then return "question" end
	if nosguhuotype and nosguhuotype == "AmazingGrace" then return "noquestion" end
	if nosguhuotype:match("Slash") then
		if yuji:getState() ~= "robot" and math.random(1, 4) == 1 and not sgs.questioner then return "question" end
		if not self:hasCrossbowEffect(yuji) then return "noquestion" end
	end
	if yuji:hasFlag("NosGuhuoFailed") and math.random(1, 6) == 1 and self:isEnemy(yuji) and self.player:getHp() >= 3
		and self.player:getHp() > self.player:getLostHp() then return "question" end
	local players = self.room:getOtherPlayers(self.player)
	players = sgs.QList2Table(players)
	local x = math.random(1, 5)

	self:sort(self.friends, "hp")
	if self.player:getHp() < 2 and self:getCardsNum("Peach") < 1 and self.room:alivePlayerCount() > 2 then return "noquestion" end
	if self:isFriend(yuji) then return "noquestion"
	elseif sgs.questioner then return "noquestion"
	else
		if self.player:getHp() < self.friends[#self.friends]:getHp() then return "noquestion" end
	end
	if self:needToLoseHp(self.player) and not self:hasSkills(sgs.masochism_skill, self.player) and x ~= 1 then return "question" end

	local questioner
	for _, friend in ipairs(self.friends) do
		if friend:getHp() == self.friends[#self.friends]:getHp() then
			if friend:hasSkills("nosrende|rende|kuanggu|kofkuanggu|zaiqi|buqu|nosbuqu|yinghun|longhun|xueji|baobian") then
				questioner = friend
				break
			end
		end
	end
	if not questioner then questioner = self.friends[#self.friends] end
	return self.player:objectName() == questioner:objectName() and x ~= 1 and "question" or "noquestion"
end

sgs.ai_choicemade_filter.skillChoice.nosguhuo = function(self, player, promptlist)
	if promptlist[#promptlist] == "question" then
		sgs.questioner = player
	end
end

local nosguhuo_skill = {}
nosguhuo_skill.name = "nosguhuo"
table.insert(sgs.ai_skills, nosguhuo_skill)
nosguhuo_skill.getTurnUseCard = function(self)
	if self.player:isKongcheng() then return end

	local cards = sgs.QList2Table(self.player:getHandcards())
	local otherSuit_str, NosGuhuoCard_str = {}, {}

	for _, card in ipairs(cards) do
		if card:isNDTrick() then
			local dummyuse = { isDummy = true }
			self:useTrickCard(card, dummyuse)
			if dummyuse.card then
				local cardstr = "@NosGuhuoCard=" .. card:getId() .. ":" .. card:objectName()
				if card:getSuit() == sgs.Card_Heart then
					table.insert(NosGuhuoCard_str, cardstr)
				else
					table.insert(otherSuit_str, cardstr)
				end
			end
		end
	end

	local other_suit, enemy_is_weak, zgl_kongcheng = true
	local can_fake_nosguhuo = sgs.turncount > 1
	for _, enemy in ipairs(self.enemies) do
		if enemy:getHp() > 2 then
			other_suit = false
		end
		if enemy:getHp() > 1 then
			can_fake_nosguhuo = false
		end
		if self:isWeak(enemy) then
			enemy_is_weak = true
		end
		if enemy:hasSkill("kongcheng") and enemy:isKongcheng() then
			zgl_kongcheng = true
		end
	end

	if #otherSuit_str > 0 and other_suit then
		table.insertTable(NosGuhuoCard_str, otherSuit_str)
	end

	local peach_str = self:getGuhuoCard("Peach", true, -1)
	if peach_str then table.insert(NosGuhuoCard_str, peach_str) end

	local fakeCards = {}

	for _, card in sgs.qlist(self.player:getHandcards()) do
		if (card:isKindOf("Slash") and self:getCardsNum("Slash", "h") >= 2 and not self:hasCrossbowEffect())
			or (card:isKindOf("Jink") and self:getCardsNum("Jink", "h") >= 3)
			or (card:isKindOf("EquipCard") and self:getSameEquip(card))
			or card:isKindOf("Disaster") then
			table.insert(fakeCards, card)
		end
	end
	self:sortByUseValue(fakeCards, true)

	local function fake_nosguhuo(objectName, can_fake_nosguhuo)
		if #fakeCards == 0 then return end

		local fakeCard
		local nosguhuo = "peach|ex_nihilo|snatch|dismantlement|amazing_grace|archery_attack|savage_assault|god_salvation"
		local ban = table.concat(sgs.Sanguosha:getBanPackages(), "|")
		if not ban:match("maneuvering") then nosguhuo = nosguhuo .. "|fire_attack" end
		local nosguhuos = nosguhuo:split("|")
		for i = 1, #nosguhuos do
			local forbidden = nosguhuos[i]
			local forbid = sgs.Sanguosha:cloneCard(forbidden)
			if self.player:isLocked(forbid) then
				table.remove(nosguhuos, i)
				i = i - 1
			end
		end
		if can_fake_nosguhuo then
			for i = 1, #nosguhuos do
				if nosguhuos[i] == "god_salvation" then table.remove(nosguhuos, i) break end
			end
		end
		for i = 1, 10 do
			local card = fakeCards[math.random(1, #fakeCards)]
			local newnosguhuo = objectName or nosguhuos[math.random(1, #nosguhuos)]
			local nosguhuocard = sgs.Sanguosha:cloneCard(newnosguhuo, card:getSuit(), card:getNumber())
			if self:getRestCardsNum(nosguhuocard:getClassName()) > 0 then
				local dummyuse = { isDummy = true }
				if newnosguhuo == "peach" then self:useBasicCard(nosguhuocard, dummyuse) else self:useTrickCard(nosguhuocard, dummyuse) end
				if dummyuse.card then
					fakeCard = sgs.Card_Parse("@NosGuhuoCard=" .. card:getId() .. ":" .. newnosguhuo)
					break
				end
			end
		end
		return fakeCard
	end

	if #NosGuhuoCard_str > 0 then
		local nosguhuo_str = NosGuhuoCard_str[math.random(1, #NosGuhuoCard_str)]

		local str = nosguhuo_str:split("=")
		str = str[2]:split(":")
		local cardid, cardname = str[1], str[2]
		if sgs.Sanguosha:getCard(cardid):objectName() == cardname and cardname == "ex_nihilo" then
			if math.random(1, 3) == 1 then
				local fake_exnihilo = fake_nosguhuo(cardname)
				if fake_exnihilo then return fake_exnihilo end
			end
			return sgs.Card_Parse(nosguhuo_str)
		elseif math.random(1, 5) == 1 then
			local fake_NosGuhuoCard = fake_nosguhuo()
			if fake_NosGuhuoCard then return fake_NosGuhuoCard end
		else
			return sgs.Card_Parse(nosguhuo_str)
		end
	elseif can_fake_nosguhuo and math.random(1, 4) ~= 1 then
		local fake_NosGuhuoCard = fake_nosguhuo(nil, can_fake_nosguhuo)
		if fake_NosGuhuoCard then return fake_NosGuhuoCard end
	elseif zgl_kongcheng and #fakeCards > 0 then
		return sgs.Card_Parse("@NosGuhuoCard=" .. fakeCards[1]:getEffectiveId() .. ":amazing_grace")
	else
		local lord = self.room:getLord()
		local drawcard = false
		if lord and self:isFriend(lord) and self:isWeak(lord) and not self.player:isLord() then
			drawcard = true
		elseif not enemy_is_weak then
			if sgs.current_mode_players["loyalist"] > sgs.current_mode_players["renegade"] + sgs.current_mode_players["rebel"]
				and self.role == "loyalist" and sgs.current_mode_players["rebel"] > 0 then
				drawcard = true
			elseif sgs.current_mode_players["rebel"] > sgs.current_mode_players["loyalist"] + sgs.current_mode_players["renegade"] + 2
				and self.role == "rebel" then
				drawcard = true
			end
		end

		if drawcard and #fakeCards > 0 then
			local card_objectname
			local objectNames = { "ex_nihilo", "snatch", "dismantlement", "amazing_grace", "archery_attack", "savage_assault", "god_salvation", "duel" }
			for _, objectName in ipairs(objectNames) do
				local acard = sgs.Sanguosha:cloneCard(objectName)
				if self:getRestCardsNum(acard:getClassName()) == 0 then
					card_objectname = objectName
					break
				end
			end
			if card_objectname then
				return sgs.Card_Parse("@NosGuhuoCard=" .. fakeCards[1]:getEffectiveId() .. ":" .. card_objectname)
			end
		end
	end

	local slash_str = self:getGuhuoCard("Slash", true, -1)
	if slash_str and self:slashIsAvailable() then
		local card = sgs.Card_Parse(slash_str)
		local slash = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber())
		local dummy_use = { isDummy = true }
		self:useBasicCard(slash, dummy_use)
		if dummy_use.card then return card end
	end
end

sgs.ai_skill_use_func.NosGuhuoCard = function(card, use, self)
	local userstring = card:toString()
	userstring = (userstring:split(":"))[3]
	local nosguhuocard = sgs.Sanguosha:cloneCard(userstring, card:getSuit(), card:getNumber())
	nosguhuocard:setSkillName("nosguhuo")
	if nosguhuocard:getTypeId() == sgs.Card_TypeBasic then self:useBasicCard(nosguhuocard, use) else assert(nosguhuocard) self:useTrickCard(nosguhuocard, use) end
	if not use.card then return end
	use.card = card
end

sgs.ai_use_priority.NosGuhuoCard = 10

sgs.nosguhuo_suit_value = {
	heart = 5,
}

sgs.ai_skill_choice.nosguhuo_saveself = sgs.ai_skill_choice.guhuo_saveself
sgs.ai_skill_choice.nosguhuo_slash = sgs.ai_skill_choice.guhuo_slash

function sgs.ai_cardneed.nosguhuo(to, card)
	return card:getSuit() == sgs.Card_Heart and (card:isKindOf("BasicCard") or card:isNDTrick())
end
