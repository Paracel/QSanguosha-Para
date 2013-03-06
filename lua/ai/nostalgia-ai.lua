sgs.weapon_range.MoonSpear = 3
sgs.ai_use_priority.MoonSpear = 2.635

local nosfanjian_skill = {}
nosfanjian_skill.name = "nosfanjian"
table.insert(sgs.ai_skills, nosfanjian_skill)
nosfanjian_skill.getTurnUseCard = function(self)
	if self.player:isKongcheng() then return nil end
	if self.player:usedTimes("NosFanjianCard") > 0 then return nil end

	local cards = self.player:getHandcards()

	for _, card in sgs.qlist(cards) do
		if card:getSuit() == sgs.Card_Diamond and self.player:getHandcardNum() == 1 then
			return nil
		elseif card:isKindOf("Peach") or card:isKindOf("Analeptic") then
			return nil
		end
	end

	local card_str = "@NosFanjianCard=."
	local fanjianCard = sgs.Card_Parse(card_str)
	assert(fanjianCard)

	return fanjianCard
end

sgs.ai_skill_use_func.NosFanjianCard = sgs.ai_skill_use_func.FanjianCard
sgs.ai_card_intention.NosFanjianCard = sgs.ai_card_intention.FanjianCard
sgs.dynamic_value.damage_card.NosFanjianCard = true

sgs.ai_chaofeng.noszhouyu = sgs.ai_chaofeng.zhouyu

nosjujian_skill = {}
nosjujian_skill.name = "nosjujian"
table.insert(sgs.ai_skills, nosjujian_skill)
nosjujian_skill.getTurnUseCard = function(self)
	if not self.player:hasUsed("NosJujianCard") then return sgs.Card_Parse("@NosJujianCard=.") end
end

sgs.ai_skill_use_func.NosJujianCard = function(card, use, self)
	local abandon_handcard = {}
	local index = 0
	local hasPeach = (self:getCardsNum("Peach") > 0)
	local tos = {}
	for _, player in ipairs(self.friends_noself) do
		if not player:hasSkill("manjuan") then
			table.insert(tos, player)
		end  
	end

	local trick_num, basic_num, equip_num = 0, 0, 0
	if not hasPeach and self.player:isWounded() and self.player:getHandcardNum() >= 3 then
		local cards = self.player:getCards("he")
		cards = sgs.QList2Table(cards)
		self:sortByUseValue(cards, true)
		for _, card in ipairs(cards) do
			if card:getTypeId() == sgs.Card_TypeTrick and not card:isKindOf("ExNihilo") then trick_num = trick_num + 1
			elseif card:getTypeId() == sgs.Card_TypeBasic then basic_num = basic_num + 1
			elseif card:getTypeId() == sgs.Card_TypeEquip then equip_num = equip_num + 1
			end
		end
		local result_class
		if trick_num >= 3 then result_class = "TrickCard"
		elseif equip_num >= 3 then result_class = "EquipCard"
		elseif basic_num >= 3 then result_class = "BasicCard"
		end
		local f
		for _, friend in ipairs(tos) do
			if friend:getHandcardNum() < 2 or friend:getHandcardNum() < friend:getHp() + 1 then
				for _, fcard in ipairs(cards) do
					if fcard:isKindOf(result_class) and not fcard:isKindOf("ExNihilo") then
						table.insert(abandon_handcard, fcard:getId())
						index = index + 1
					end
					if index == 3 then f = friend break end
				end
			end
		end
		if index == 3 then
			if use.to then use.to:append(f) end
			use.card = sgs.Card_Parse("@NosJujianCard=" .. table.concat(abandon_handcard, "+"))
			return
		end
	end
	abandon_handcard = {}
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards, true)
	local slash_num = self:getCardsNum("Slash")
	local jink_num = self:getCardsNum("Jink")
	for _, friend in ipairs(tos) do
		if friend:getHandcardNum() < 2 or friend:getHandcardNum() < friend:getHp() + 1 or self.player:isWounded() then
			for _, card in ipairs(cards) do
				if #abandon_handcard >= 3 then break end
				if not card:isKindOf("Nullification") and not card:isKindOf("EquipCard")
					and not card:isKindOf("Peach") and not card:isKindOf("Jink")
					and not card:isKindOf("Indulgence") and not card:isKindOf("SupplyShortage") then
					table.insert(abandon_handcard, card:getId())
					index = 5
				elseif card:isKindOf("Slash") and slash_num > 1 then
					if (self.player:getWeapon() and not self.player:getWeapon():objectName() == "crossbow")
						or not self.player:getWeapon() then
						table.insert(abandon_handcard, card:getId())
						index = 5
						slash_num = slash_num - 1
					end
				elseif card:isKindOf("Jink") and jink_num > 1 then
					table.insert(abandon_handcard, card:getId())
					index = 5
					jink_num = jink_num - 1
				end
			end
			if index == 5 then
				use.card = sgs.Card_Parse("@NosJujianCard=" .. table.concat(abandon_handcard, "+"))
				if use.to then use.to:append(friend) end
				return
			end
		end
	end
	if #tos > 0 and self:getOverflow() > 0 then
		self:sort(tos, "handcard")
		local discard = self:askForDiscard("gamerule", math.min(self:getOverflow(), 3))
		use.card = sgs.Card_Parse("@NosJujianCard=" .. table.concat(discard, "+"))
		if use.to then use.to:append(self.friends_noself[1]) end
		return
	end
end

sgs.ai_use_priority.NosJujianCard = 4.5
sgs.ai_use_value.NosJujianCard = 6.7

sgs.ai_card_intention.NosJujianCard = -100

sgs.dynamic_value.benefit.NosJujianCard = true

sgs.ai_skill_cardask["@enyuanheart"] = function(self)
	if self:needLoseHp() then return "." end
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
	if from:hasFlag("nosjiefanUsed") then return false end
	if self:needLoseHp(from) then return false end
	if from:getHp() > 3 then return false end

	local n = 0
	local cards = self.player:getHandcards()
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

sgs.ai_need_damaged.nosenyuan = function (self, attacker)
	if self:isEnemy(attacker) and self:isWeak(attacker) then
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
			if friend:hasArmorEffect("silver_lion") and not self:hasSkills(sgs.use_lion_skill, friend)
			  and friend:isWounded() and self:isWeak(friend) and not friend:hasSkill("manjuan") then
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
			if not enemy:isKongcheng() and not enemy:hasSkill("tuntian") then
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
			if friend:hasSkill("tuntian") and not friend:hasSkill("manjuan") then
				target = friend
				break
			end
		end
	end

	if target then
		local willUse = false
		if self:isFriend(target) then
			for _, card in ipairs(cards) do
				if card:getSuit() == sgs.Card_Heart then
					willUse = true
					break
				end
			end
		else
			for _, card in ipairs(cards) do
				if card:getSuit() == sgs.Card_Heart and not isCard("Peach", card, target) and not isCard("Nullification", card, target) then
					willUse = true
					break
				end
			end
		end

		if willUse then
			target:setFlags("nosxuanhuo_target")
			use.card = sgs.Card_Parse("@NosXuanhuoCard=" .. card:getEffectiveId())
			if use.to then use.to:append(target) end
		end
	end
end

sgs.ai_skill_playerchosen.nosxuanhuo = function(self, targets)
	for _, player in sgs.qlist(targets) do
		if (player:getHandcardNum() <= 2 or player:getHp() < 2) and self:isFriend(player)
			and not player:hasFlag("nosxuanhuo_target") and not self:needKongcheng(player) and not player:hasSkill("manjuan") then
			return player
		end
	end
	for _, player in sgs.qlist(targets) do
		if self:isFriend(player)
			and not player:hasFlag("nosxuanhuo_target") and not self:needKongcheng(player) and not player:hasSkill("manjuan") then
			return player
		end
	end
	for _, player in sgs.qlist(targets) do
		if player == self.player then
			return player
		end
	end
end

sgs.nosenyuan_suit_value = {
	heart = 3.9
}

sgs.ai_chaofeng.nos_fazheng = -3

sgs.ai_cardneed.nosxuanhuo = function(to, card)
	return card:getSuit() == sgs.Card_Heart
end

sgs.ai_skill_choice.nosxuanfeng = function(self, choices)
	self:sort(self.enemies, "defense")
	local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
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

sgs.ai_view_as.nosgongqi = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card:getTypeId() == sgs.Card_TypeEquip and not card:hasFlag("using") then
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

sgs.ai_skill_invoke.nosshangshi = sgs.ai_skill_invoke.shangshi

function sgs.ai_cardneed.nosgongqi(to, card)
	return card:getTypeId() == sgs.Card_TypeEquip and getKnownCard(to, "EquipCard", true) == 0
end

sgs.ai_skill_invoke.nosjiefan = function(self, data)
	local dying = data:toDying()
	local slashnum = 0
	local friend = dying.who
	local currentplayer = self.room:getCurrent()
	for _, slash in ipairs(self:getCards("Slash")) do
		if self:slashIsEffective(slash, currentplayer) then
			slashnum = slashnum + 1
		end
	end
	return self:isFriend(friend) and not (self:isEnemy(currentplayer) and (currentplayer:hasSkill("leiji") or currentplayer:hasSkill("wansha"))
		and (currentplayer:getHandcardNum() > 2 or self:hasEightDiagramEffect(currentplayer))) and slashnum > 0
end

sgs.ai_skill_cardask["nosjiefan-slash"] = function(self, data, pattern, target)
	target = global_room:getCurrent()
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
	local to = self:findPlayerToDraw(true, self.player:getLostHp())
	return to and self.player
end

sgs.ai_skill_invoke.nosqianxi = function(self, data)
	local damage = data:toDamage()
	local target = damage.to
	if self:isFriend(target) then return false end
	if target:getLostHp() >= 2 and target:getHp() <= 1 then return false end
	if self:hasSkills(sgs.masochism_skill, target) or self:hasSkills(sgs.recover_skill, target) or self:hasSkills("longhun|buqu", target) then return true end
	if self:hasHeavySlashDamage(self.player, damage.card, target) then return false end
	return (target:getMaxHp() - target:getHp()) < 2
end

function sgs.ai_cardneed.nosqianxi(to, card)
	return isCard("Slash", card, to) and getKnownCard(to, "Slash", true) == 0
end

sgs.ai_skill_invoke.noszhenggong = function(self, data)
	local target = data:toPlayer()

	if self:isFriend(target) then
		return (self:hasSkills(sgs.lose_equip_skill, target) and not self:isWeak(target)) or (target:hasArmorEffect("silver_lion") and target:isWounded())
	end

	return true
end

function sgs.ai_cardneed.noszhenggong(to, card, self)
	if not to:containsTrick("indulgence") and to:getMark("nosbaijiang") == 0 then
		return card:getTypeId() == sgs.Card_TypeEquip
	end
end

sgs.ai_skill_cardchosen.noszhenggong = function(self, who, flags)
	for i = 0, 3 do
		if not self.player:getEquip(i) and who:getEquip(i) then
			return who:getEquip(i)
		end
	end

	return sgs.Sanguosha:getCard(self:askForCardChosen(who, flags))
end

sgs.ai_skill_use["@@nosquanji"] = function(self, prompt)
	local current = self.room:getCurrent()
	if self:isFriend(current) then
		if current:hasSkill("zhiji") and not current:hasSkill("guanxing") and current:getHandcardNum() == 1 then
			return "@NosQuanjiCard=" .. self:getMinCard(self.player):getId() .. "->."
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
			return "@NosQuanjiCard=" .. self:getMaxCard(self.player):getId() .. "->."
		end
	end

	return "."
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
			if self:hasSkills("lijian|fanjian|nosfanjian|neofanjian", enemy) and not enemy:containsTrick("indulgence") and not enemy:isKongcheng() and enemy:faceUp() and self:objectiveLevel(enemy) > 3 then
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
			if ((#enemies == 1) or not self:hasSkills("tiandu|guidao", enemy)) and not enemy:containsTrick("supply_shortage") and enemy:faceUp() and self:objectiveLevel(enemy) > 3 then
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
		elseif not player:isLord() then
			if sgs.evaluateRoleTrends(player) == "loyalist" then
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
	local isGood = self:isFriend(lord)
	if sgs.evaluateRoleTrends(to_modify) == "loyalist" or sgs.evaluateRoleTrends(to_modify) == "renegade" then
		if isGood then
			return lord:getKingdom()
		else
			-- find a kingdom that is different from the lord
			local kingdoms = {"wei", "shu", "wu", "qun"}
			for _, kingdom in ipairs(kingdoms) do
				if lord:getKingdom() ~= kingdom then
					return kingdom
				end
			end
		end
	elseif lord:hasLordSkill("xueyi") and not to_modify:isLord() then
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