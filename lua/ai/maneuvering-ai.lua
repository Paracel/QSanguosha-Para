function SmartAI:useCardThunderSlash(...)
	self:useCardSlash(...)
end

sgs.ai_card_intention.ThunderSlash = sgs.ai_card_intention.Slash

sgs.ai_use_value.ThunderSlash = 4.55
sgs.ai_keep_value.ThunderSlash = 2.5
sgs.ai_use_priority.ThunderSlash = 2.3

function SmartAI:useCardFireSlash(...)
	self:useCardSlash(...)
end

sgs.ai_card_intention.FireSlash = sgs.ai_card_intention.Slash

sgs.ai_use_value.FireSlash = 4.6
sgs.ai_keep_value.FireSlash = 2.6
sgs.ai_use_priority.FireSlash = 2.3

sgs.weapon_range.Fan = 4
sgs.ai_use_priority.Fan = 2.655
sgs.ai_use_priority.Vine = 0.95
sgs.ai_use_priority.SilverLion = 1.0

sgs.ai_skill_invoke.fan = function(self, data)
	local use = data:toCardUse()
	for _, target in sgs.qlist(use.to) do
		if self:isFriend(target) then
			if not (target:isChained() and self:isGoodChainTarget(target)) then return false end
		else
			if target:isChained() and not self:isGoodChainTarget(target) then return false end
		end
	end
	for _, target in sgs.qlist(use.to) do
		if not self:damageIsEffective(target, sgs.DamageStruct_Fire) then return self:isFriend(target) end
		if target:hasArmorEffect("vine") or target:getMark("@gale") > 0 then return self:isEnemy(target) end
	end
	return false
end

sgs.ai_view_as.fan = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card_place ~= sgs.Player_PlaceSpecial and card:objectName() == "slash" then
		return ("fire_slash:fan[%s:%s]=%d"):format(suit, number, card_id)
	end
end

local fan_skill = {}
fan_skill.name = "fan"
table.insert(sgs.ai_skills, fan_skill)
fan_skill.getTurnUseCard = function(self)
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	local slash_card

	for _, card in ipairs(cards) do
		if card:isKindOf("Slash") and not (card:isKindOf("FireSlash") or card:isKindOf("ThunderSlash")) then
			slash_card = card
			break
		end
	end

	if not slash_card then return nil end
	local suit = slash_card:getSuitString()
	local number = slash_card:getNumberString()
	local card_id = slash_card:getEffectiveId()
	local card_str = ("fire_slash:fan[%s:%s]=%d"):format(suit, number, card_id)
	local fireslash = sgs.Card_Parse(card_str)
	assert(fireslash)

	return fireslash

end

function sgs.ai_weapon_value.fan(self, enemy)
	if enemy and enemy:hasArmorEffect("vine") then return 6 end
end

function sgs.ai_armor_value.vine(player, self)
	if not self:damageIsEffective(nil, sgs.DamageStruct_Fire) then return 6 end
	if player:hasSkill("jujian") and not player:getArmor() and #(self:getFriendsNoself(player)) > 0 and player:getPhase() == sgs.Player_Play then return 3 end
	if player:hasSkill("diyyicong") and not player:getArmor() and player:getPhase() == sgs.Player_Play then return 3 end
	for _, enemy in sgs.qlist(self.room:getOtherPlayers(player)) do
		if not self:isFriend(enemy, player) then
			if (enemy:canSlash(player) and (enemy:hasWeapon("fan") or enemy:hasSkill("lihuo"))) or enemy:hasSkills("huoji|longhun") then return -2 end
			if enemy:hasSkill("yeyan") and enemy:getMark("@flame") > 0 then return -2 end
			if getKnownCard(enemy, "FireSlash", true) >= 1 or getKnownCard(enemy, "FireAttack", true) >= 1 or getKnownCard(enemy, "Fan") >= 1 then return -2 end
		end
	end

	if (#self.enemies < 3 and sgs.turncount >= 2) or player:getHp() <= 2 then return 5 end

	if (self:needKongcheng(player) and player:getHandcardNum() == 1) or not self:hasLoseHandcardEffective(player) then
		return player:hasSkill("kongcheng") and 5 or 3.8
	end
	if self:hasSkills(sgs.lose_equip_skill, player) then return 3.8 end
	return 3.5
end

function SmartAI:useCardAnaleptic(card, use)
	if not self.player:hasEquip(card) and not self:hasLoseHandcardEffective() and not self:isWeak()
		and sgs.Analeptic_IsAvailable(self.player, card) then
		use.card = card
	end
end

function SmartAI:searchForAnaleptic(use, enemy, slash)
	if not self.toUse then return nil end

	for _, card in ipairs(self.toUse) do
		if card:getEffectiveId() ~= slash:getEffectiveId() then return nil else break end
	end

	if not use.to or use.to:isEmpty() then return nil end
	if use.to:first():hasSkill("zhenlie") then return nil end
	if not sgs.Analeptic_IsAvailable(self.player) then return nil end

	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:fillSkillCards(cards)
	local allcards = self.player:getCards("he")
	allcards = sgs.QList2Table(allcards)

	local card_str = self:getCardId("Analeptic")
	if card_str then return sgs.Card_Parse(card_str) end

	for _, anal in ipairs(cards) do
		if anal:getClassName() == "Analeptic" and anal:getEffectiveId() ~= slash:getEffectiveId() then
			return anal
		end
	end
end

function SmartAI:shouldUseAnaleptic(target, slash)
	if sgs.turncount <= 1 and self.role == "renegade" and sgs.isLordHealthy() and self:getOverflow() < 2 then return false end
	if target:hasArmorEffect("silver_lion") and not (self.player:hasWeapon("qinggang_sword") or self.player:hasSkill("jueqing")) then
		return
	end
	if target:hasSkill("zhenlie") then return false end
	if target:hasSkill("xiangle") then
		local basicnum = 0
		for _, acard in sgs.qlist(self.player:getHandcards()) do
			if acard:getTypeId() == sgs.Card_TypeBasic and not acard:isKindOf("Peach") then basicnum = basicnum + 1 end
		end
		if basicnum < 3 then return false end
	end

	if self:hasSkills(sgs.masochism_skill .. "|longhun|buqu|" .. sgs.recover_skill, target)
		and self.player:hasSkill("nosqianxi") and self.player:distanceTo(target) == 1 then
		return
	end

	local hcard = target:getHandcardNum()
	if self.player:hasSkill("liegong") and self.player:getPhase() == sgs.Player_Play and (hcard >= self.player:getHp() or hcard <= self.player:getAttackRange()) then return true end
	if self.player:hasSkill("kofliegong") and self.player:getPhase() == sgs.Player_Play and hcard >= self.player:getHp() then return true end
	if self.player:hasSkill("tieji") then return true end

	if self.player:hasWeapon("axe") and self.player:getCards("he"):length() > 4 then return true end
	if target:hasFlag("dahe") then return true end

	if ((self.player:hasSkill("roulin") and target:isFemale()) or (self.player:isFemale() and target:hasSkill("roulin"))) or self.player:hasSkill("wushuang") then
		if getKnownCard(target, "Jink", true, "he") >= 2 then return false end
		return getCardsNum("Jink", target) < 2
	end

	if getKnownCard(target, "Jink", true, "he") >= 1 and not (self:getOverflow() > 0 and self:getCardsNum("Analeptic") > 1) then return false end
	return self:getCardsNum("Analeptic") > 1 or getCardsNum("Jink", target) < 1 or sgs.card_lack[target:objectName()]["Jink"] == 1
end

sgs.dynamic_value.benefit.Analeptic = true

sgs.ai_use_value.Analeptic = 5.98
sgs.ai_keep_value.Analeptic = 4.5
sgs.ai_use_priority.Analeptic = 2.5

local function handcard_subtract_hp(a, b)
	local diff1 = a:getHandcardNum() - a:getHp()
	local diff2 = b:getHandcardNum() - b:getHp()

	return diff1 < diff2
end

function SmartAI:useCardSupplyShortage(card, use)
	local enemies = self:exclude(self.enemies, card)
	if #enemies == 0 then return end

	local zhanghe = self.room:findPlayerBySkillName("qiaobian")
	local zhanghe_seat = zhanghe and zhanghe:faceUp() and not self:isFriend(zhanghe) and zhanghe:getSeat() or 0

	local sb_daqiao = self.room:findPlayerBySkillName("yanxiao")
	local yanxiao = sb_daqiao and not self:isFriend(sb_daqiao) and sb_daqiao:faceUp()
					and (getKnownCard(sb_daqiao, "diamond", nil, "he") > 0
						or sb_daqiao:getHandcardNum() > 2
						or sb_daqiao:containsTrick("YanxiaoCard"))

	local getvalue = function(enemy)
		if enemy:containsTrick("supply_shortage") or enemy:containsTrick("YanxiaoCard")
			or (enemy:hasSkill("qiaobian") and not enemy:isKongcheng()
				and not enemy:containsTrick("supply_shortage") and not enemy:containsTrick("indulgence")) then
			return -100
		end
		if zhanghe_seat > 0 and (self:playerGetRound(zhanghe) <= self:playerGetRound(enemy) and self:enemiesContainsTrick() <= 1 or not enemy:faceUp()) then
			return - 100
		end
		if yanxiao and (self:playerGetRound(sb_daqiao) <= self:playerGetRound(enemy) and self:enemiesContainsTrick(true) <= 1 or not enemy:faceUp()) then
			return -100
		end

		local value = 0 - enemy:getHandcardNum()

		if enemy:hasSkills("yongsi|haoshi|tuxi|noslijian|lijian|fanjian|neofanjian|dimeng|jijiu|jieyin|beige") or (enemy:hasSkill("zaiqi") and enemy:getLostHp() > 1) then
			value = value + 10
		end
		if enemy:hasSkills(sgs.cardneed_skill .. "|zhaolie|tianxiang|qinyin|yanxiao|zhaoxin|renjie+baiyin") then
			value = value + 5
		end
		if enemy:hasSkills("yingzi|shelie|xuanhuo|buyi|jujian|jiangchi|mizhao|hongyuan|chongzhen+longdan|duoshi") then value = value + 1 end
		if enemy:hasSkill("zishou") then value = value + enemy:getLostHp() end
		if self:isWeak(enemy) then value = value + 5 end
		if enemy:isLord() then value = value + 3 end

		if self:objectiveLevel(enemy) < 3 then value = value - 10 end
		if not enemy:faceUp() then value = value - 10 end
		if enemy:hasSkills("keji|shensu") then value = value - enemy:getHandcardNum() end
		if enemy:hasSkills("guanxing|xiuluo|tiandu|guidao|noszhenlie") then value = value - 5 end
		if self:needKongcheng(enemy) then value = value - 1 end
		if enemy:getMark("@kuiwei") > 0 then value = value - 2 end
		if not sgs.isGoodTarget(enemy, self.enemies, self) then value = value - 1 end
		return value
	end

	local cmp = function(a, b)
		return getvalue(a) > getvalue(b)
	end

	table.sort(enemies, cmp)

	local target = enemies[1]
	if getvalue(target) > -100 then
		use.card = card
		if use.to then use.to:append(target) end
		return
	end
end

sgs.ai_use_value.SupplyShortage = 7
sgs.ai_use_priority.SupplyShortage = 0.5
sgs.ai_card_intention.SupplyShortage = 120

function SmartAI:getChainedFriends(player)
	player = player or self.player
	local chainedFriends = {}
	for _, friend in ipairs(self:getFriends(player)) do
		if friend:isChained() then
			table.insert(chainedFriends, friend)
		end
	end
	return chainedFriends
end

function SmartAI:getChainedEnemies(player)
	player = player or self.player
	local chainedEnemies = {}
	for _, enemy in ipairs(self:getEnemies(player)) do
		if enemy:isChained() then
			table.insert(chainedEnemies, enemy)
		end
	end
	return chainedEnemies
end

function SmartAI:isGoodChainPartner(player)
	player = player or self.player
	if player:hasSkill("buqu") or (self.player:hasSkill("niepan") and self.player:getMark("@nirvana") > 0) or self:needToLoseHp(player)
		or self:getDamagedEffects(player) or (player:hasSkill("fuli") and player:getMark("@laoji") > 0) then
		return true
	end
	return false
end

function SmartAI:isGoodChainTarget(who, source)
	if not who:isChained() then return false end
	source = source or self.player
	local good = #(self:getChainedEnemies(source))
	local bad = #(self:getChainedFriends(source))

	if not sgs.GetConfig("EnableHegemony", false) then
		local lord = self.room:getLord()
		if lord and self:isWeak(lord) and lord:isChained() and not self:isEnemy(lord, source) then
			return false
		end
	end

	for _, friend in ipairs(self:getChainedFriends(source)) do
		if self:cantbeHurt(friend, source) then
			return false
		end
		if self:isGoodChainPartner(friend) then
			good = good + 1
		elseif self:isWeak(friend) then
			good = good - 1
		end
	end
	for _, enemy in ipairs(self:getChainedEnemies(source)) do
		if self:cantbeHurt(enemy, source) then
			return false
		end
		if self:isGoodChainPartner(enemy) then
			bad = bad + 1
		elseif self:isWeak(enemy) then
			bad = bad - 1
		end
	end
	return good >= bad
end

function SmartAI:useCardIronChain(card, use)
	local needTarget = (card:getSkillName() == "guhuo" or card:getSkillName() == "qice")
	if not (self.player:hasSkill("noswuyan") and needTarget) then use.card = card end
	if not needTarget then
		if self.player:hasSkill("noswuyan") then return end
		if self.player:isLocked(card) then return end
		if #self.enemies == 1 and #(self:getChainedFriends()) <= 1 then return end
		if self:needBear() then return end
		if self:getOverflow() <= 0 and self.player:hasSkill("manjuan") then return end
		if self.player:hasSkill("wumou") and self.player:getMark("@wrath") < 7 then return end
	end
	local friendtargets = {}
	local otherfriends = {}
	local enemytargets = {}
	local yangxiu = self.room:findPlayerBySkillName("danlao")
	local liuxie = self.room:findPlayerBySkillName("huangen")
	self:sort(self.friends, "defense")
	for _, friend in ipairs(self.friends) do
		if friend:isChained() and not self:isGoodChainPartner(friend) and self:hasTrickEffective(card, friend) and not friend:hasSkill("danlao") then
			table.insert(friendtargets, friend)
		else
			table.insert(otherfriends, friend)
		end
	end
	if not (liuxie and self:isEnemy(liuxie)) then
		self:sort(self.enemies, "defense")
		for _, enemy in ipairs(self.enemies) do
			if not enemy:isChained() and not self.room:isProhibited(self.player, enemy, card) and not enemy:hasSkill("danlao")
				and self:hasTrickEffective(card, enemy) and not (self:objectiveLevel(enemy) <= 3)
				and not self:getDamagedEffects(enemy) and not self:needToLoseHp(enemy) and sgs.isGoodTarget(enemy, self.enemies, self) then
				table.insert(enemytargets, enemy)
			end
		end
	end

	local chainSelf = (self:needToLoseHp(self.player) or self:getDamagedEffects(self.player)) and not self.player:isChained()
						and not self.player:hasSkill("jueqing")
						and (self:getCardId("NatureSlash") or (self:getCardId("Slash") and (self.player:hasWeapon("fan") or self.player:hasSkill("lihuo")))
						or (self:getCardId("FireAttack") and self.player:getHandcardNum() > 2))

	local targets_num = 2 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, self.player, card)
	if not self.player:hasSkill("noswuyan") then
		if #friendtargets > 1 then
			if use.to then
				for _, friend in ipairs(friendtargets) do
					use.to:append(friend)
					if use.to:length() == targets_num then return end
				end
			end
		elseif #friendtargets == 1 then
			if #enemytargets > 0 then
				if use.to then
					use.to:append(friendtargets[1])
					for _, enemy in ipairs(enemytargets) do
						use.to:append(enemy)
						if use.to:length() == targets_num then return end
					end
				end
			elseif chainSelf then
				if use.to then use.to:append(friendtargets[1]) end
				if use.to then use.to:append(self.player) end
			elseif liuxie and self:isFriend(liuxie) and liuxie:getHp() > 0 and #otherfriends > 0 then
				if use.to then
					use.to:append(friendtargets[1])
					for _, friend in ipairs(otherfriends) do
						use.to:append(friend)
						if use.to:length() == math.min(targets_num, liuxie:getHp() + 1) then return end
					end
				end
			elseif yangxiu and self:isFriend(yangxiu) then
				if use.to then use.to:append(friendtargets[1]) end
				if use.to then use.to:append(yangxiu) end
			end
		elseif #enemytargets > 1 then
			if use.to then
				for _, enemy in ipairs(enemytargets) do
					use.to:append(enemy)
					if use.to:length() == targets_num then return end
				end
			end
		elseif #enemytargets == 1 then
			if chainSelf then
				if use.to then use.to:append(enemytargets[1]) end
				if use.to then use.to:append(self.player) end
			elseif liuxie and self:isFriend(liuxie) and liuxie:getHp() > 0 and #otherfriends > 0 then
				if use.to then
					use.to:append(enemytargets[1])
					for _, friend in ipairs(otherfriends) do
						use.to:append(friend)
						if use.to:length() == math.min(targets_num, liuxie:getHp() + 1) then return end
					end
				end
			elseif yangxiu and self:isFriend(yangxiu) then
				if use.to then use.to:append(enemytargets[1]) end
				if use.to then use.to:append(yangxiu) end
			end
		elseif #friendtargets == 0 and #enemytargets == 0 then
			if use.to and liuxie and self:isFriend(liuxie) and liuxie:getHp() > 0 and #otherfriends > 1 then
				for _, friend in ipairs(otherfriends) do
					use.to:append(friend)
					if use.to:length() == math.min(targets_num, liuxie:getHp()) then return end
				end
			end
		end
	end
	if use.to then assert(use.to:length() < targets_num + 1) end
end

sgs.ai_card_intention.IronChain = function(self, card, from, tos)
	local liuxie = self.room:findPlayerBySkillName("huangen")
	for _, to in ipairs(tos) do
		if not to:isChained() then
			local enemy = true
			if to:hasSkill("danlao") and #tos > 1 then enemy = false end
			if liuxie and liuxie:getHp() >= 1 and #tos > 1 and self:isFriend(to, liuxie) then enemy = false end
			sgs.updateIntention(from, to, enemy and 60 or -30)
		else
			sgs.updateIntention(from, to, -60)
		end
	end
end

sgs.ai_use_value.IronChain = 5.4
sgs.ai_use_priority.IronChain = 9.1

sgs.ai_skill_cardask["@fire-attack"] = function(self, data, pattern, target)
	local cards = sgs.QList2Table(self.player:getHandcards())
	local convert = { [".S"] = "spade", [".D"] = "diamond", [".H"] = "heart", [".C"] = "club" }
	local card
	local lord = self.room:getLord()
	self:sortByUseValue(cards, true)

	for _, acard in ipairs(cards) do
		if acard:getSuitString() == convert[pattern] then
			if not isCard("Peach", acard, self.player) then
				card = acard
				break
			else
				local needKeepPeach = true
				if (self:isWeak(target) and not self:isWeak()) or target:getHp() == 1
					or self:isGoodChainTarget(target) or target:hasArmorEffect("vine") or target:getMark("@gale") > 0 then
					needKeepPeach = false
				end
				if lord and not self:isEnemy(lord) and sgs.isLordInDanger() and self:getCardsNum("Peach") == 1 and self.player:aliveCount() > 2 then
					needKeepPeach = true
				end
				if not needKeepPeach then
					card = acard
					break
				end
			end
		end
	end
	return card and card:getId() or "."
end

function SmartAI:useCardFireAttack(fire_attack, use)
	if self.player:hasSkill("wuyan") and not self.player:hasSkill("jueqing") then return end
	if self.player:hasSkill("noswuyan") then return end

	local lack = {
		spade = true,
		club = true,
		heart = true,
		diamond = true,
	}

	local cards = self.player:getHandcards()
	for _, card in sgs.qlist(cards) do
		if card:getEffectiveId() ~= fire_attack:getEffectiveId() then
			lack[card:getSuitString()] = false
		end
	end

	if self.player:hasSkill("hongyan") then
		lack.spade = true
	end

	local suitnum = 0
	for suit, islack in pairs(lack) do
		if not islack then suitnum = suitnum + 1 end
	end

	self:sort(self.enemies, "defense")

	local can_attack = function(enemy)
		if self.player:hasFlag("FireAttackFailed_" .. enemy:objectName()) then
			return false
		end
		local damage = 1
		if not self.player:hasSkill("jueqing") and not enemy:hasArmorEffect("silver_lion") then
			if enemy:hasArmorEffect("vine") then damage = damage + 1 end
			if enemy:getMark("@gale") > 0 then damage = damage + 1 end
		end
		if not self.player:hasSkill("jueqing") and enemy:hasSkill("mingshi") and self.player:getEquips():length() <= enemy:getEquips():length() then
			damage = damage - 1
		end
		return self:objectiveLevel(enemy) > 3 and damage > 0 and not enemy:isKongcheng() and not self.room:isProhibited(self.player, enemy, fire_attack)
				and self:damageIsEffective(enemy, sgs.DamageStruct_Fire, self.player) and not self:cantbeHurt(enemy, self.player, damage)
				and self:hasTrickEffective(fire_attack, enemy)
				and sgs.isGoodTarget(enemy, self.enemies, self)
				and (self.player:hasSkill("jueqing")
					or (not (enemy:hasSkill("jianxiong") and not self:isWeak(enemy))
						and not (self:getDamagedEffects(enemy, self.player))
						and not (enemy:isChained() and not self:isGoodChainTarget(enemy))))
	end

	local enemies, targets = {}, {}
	for _, enemy in ipairs(self.enemies) do
		if can_attack(enemy) then
			table.insert(enemies, enemy)
		end
	end

	local can_FireAttack_self
	for _, card in sgs.qlist(self.player:getHandcards()) do
		if (not isCard("Peach", card, self.player) or self:getCardsNum("Peach") >= 3)
			and (not isCard("Analeptic", card, self.player) or self:getCardsNum("Analeptic") >= 2) then
			can_FireAttack_self = true
		end
	end

	if self.role ~= "renegade" and can_FireAttack_self and self.player:isChained() and self:isGoodChainTarget(self.player)
		and self.player:getHandcardNum() > 1 and not self.player:hasSkill("jueqing") and not self.player:hasSkill("mingshi")
		and not self.room:isProhibited(self.player, self.player, fire_attack)
		and self:damageIsEffective(self.player, sgs.DamageStruct_Fire, self.player) and not self:cantbeHurt(self.player)
		and self:hasTrickEffective(fire_attack, self.player)
		and (self.player:getHp() > 1 or self:getCardsNum("Peach") >= 1 or self:getCardsNum("Analeptic") >= 1 or self.player:hasSkill("buqu")
			or (self.player:hasSkill("niepan") and self.player:getMark("@nirvana") > 0)) then

		table.insert(targets, self.player)
	end

	for _, enemy in ipairs(enemies) do
		if enemy:getHandcardNum() == 1 then
			local handcards = sgs.QList2Table(enemy:getHandcards())
			local flag = string.format("%s_%s_%s", "visible", self.player:objectName(), enemy:objectName())
			if handcards[1]:hasFlag("visible") or handcards[1]:hasFlag(flag) then
				local suitstring = handcards[1]:getSuitString()
				if not lack[suitstring] and not table.contains(targets, enemy) then
					table.insert(targets, enemy)
				end
			end
		end
	end

	if ((suitnum == 2 and lack.diamond == false) or suitnum <= 1)
		and self:getOverflow() <= (self.player:hasSkills("jizhi|nosjizhi") and -2 or 0)
		and #targets == 0 then return end

	for _, enemy in ipairs(enemies) do
		local damage = 1
		if not enemy:hasArmorEffect("silver_lion") then
			if enemy:hasArmorEffect("vine") then damage = damage + 1 end
			if enemy:getMark("@gale") > 0 then damage = damage + 1 end
		end
		if not self.player:hasSkill("jueqing") and enemy:hasSkill("mingshi") and self.player:getEquips():length() <= enemy:getEquips():length() then
			damage = damage - 1
		end
		if not self.player:hasSkill("jueqing") and self:damageIsEffective(enemy, sgs.DamageStruct_Fire, self.player) and damage > 1 then
			if not table.contains(targets, enemy) then table.insert(targets, enemy) end
		end
	end
	for _, enemy in ipairs(enemies) do
		if not table.contains(targets, enemy) then table.insert(targets, enemy) end
	end

	if #targets > 0 then
		local godsalvation = self:getCard("GodSalvation")
		if godsalvation and godsalvation:getId() ~= fire_attack:getId() and self:willUseGodSalvation(godsalvation) then
			use.card = godsalvation
			return
		end

		local targets_num = 1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, self.player, fire_attack)
		use.card = fire_attack
		for i = 1, #targets, 1 do
			if use.to then
				use.to:append(targets[i])
				if use.to:length() == targets_num then return end
			end
		end
	end
end

sgs.ai_cardshow.fire_attack = function(self, requestor)
	local cards = sgs.QList2Table(self.player:getHandcards())
	if requestor:objectName() == self.player:objectName() then
		self:sortByUseValue(cards, true)
		return cards[1]
	end

	local priority = { heart = 4, spade = 3, club = 2, diamond = 1 }
	if requestor:hasSkill("hongyan") then priority = { spade = 10, club = 2, diamond = 1, heart = 0 } end
	local index = -1
	local result
	for _, card in ipairs(cards) do
		if priority[card:getSuitString()] > index then
			result = card
			index = priority[card:getSuitString()]
		end
	end

	return result
end

sgs.ai_use_value.FireAttack = 4.8
sgs.ai_use_priority.FireAttack = 2

sgs.ai_card_intention.FireAttack = 80

sgs.dynamic_value.damage_card.FireAttack = true
