sgs.weapon_range.SPMoonSpear = 3

sgs.ai_skill_playerchosen.sp_moonspear = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
	for _, target in ipairs(targets) do
		if self:isEnemy(target) and self:damageIsEffective(target) and sgs.isGoodTarget(target, targets, self) then
			return target
		end
	end
	return nil
end

sgs.ai_playerchosen_intention.sp_moonspear = 80

function sgs.ai_slash_prohibit.weidi(self, from, to, card)
	if to:isLord() then return false end
	local lord = self.room:getLord()
	if not lord then return false end
	for _, askill in sgs.qlist(lord:getVisibleSkillList()) do
		if askill:objectName() ~= "weidi" and askill:isLordSkill() then
			local filter = sgs.ai_slash_prohibit[askill:objectName()]
			if type(filter) == "function" and filter(self, from, to, card) then return true end
		end
	end
end

sgs.ai_skill_use["@jijiang"] = function(self, prompt)
	if self.player:hasFlag("Global_JijiangFailed") then return "." end
	local card = sgs.Card_Parse("@JijiangCard=.")
	local dummy_use = { isDummy = true }
	self:useSkillCard(card, dummy_use)
	if dummy_use.card then
		local jijiang = {}
		if sgs.jijiangtarget then
			for _, p in ipairs(sgs.jijiangtarget) do
				table.insert(jijiang, p:objectName())
			end
			return "@JijiangCard=.->" .. table.concat(jijiang, "+")
		end
	end
	return "."
end

sgs.ai_skill_invoke.danlao = function(self, data)
	local effect = data:toCardUse()
	local current = self.room:getCurrent()
	if (effect.card:isKindOf("GodSalvation") and self.player:isWounded()) or effect.card:isKindOf("ExNihilo") then
		return false
	elseif effect.card:isKindOf("AmazingGrace")
		and (self.player:getSeat() - current:getSeat()) % (global_room:alivePlayerCount()) < global_room:alivePlayerCount() / 2 then
		return false
	else
		return true
	end
end

sgs.ai_skill_invoke.jilei = function(self, data)
	local damage = data:toDamage()
	if not damage then return false end
	self.jilei_source = damage.from
	return self:isEnemy(damage.from)
end

sgs.ai_skill_choice.jilei = function(self, choices)
	local tmptrick = sgs.cloneCard("ex_nihilo")
	if (self:hasCrossbowEffect(self.jilei_source) and self.jilei_source:inMyAttackRange(self.player))
		or self.jilei_source:isCardLimited(tmptrick, sgs.Card_MethodUse, true) then
		return "BasicCard"
	else
		return "TrickCard"
	end
end

local function yuanhu_validate(self, equip_type, is_handcard)
	local is_SilverLion = false
	if equip_type == "SilverLion" then
		equip_type = "Armor"
		is_SilverLion = true
	end
	local targets
	if is_handcard then targets = self.friends else targets = self.friends_noself end
	if equip_type ~= "Weapon" then
		if equip_type == "DefensiveHorse" or equip_type == "OffensiveHorse" then self:sort(targets, "hp") end
		if equip_type == "Armor" then self:sort(targets, "handcard") end
		if is_SilverLion then
			for _, enemy in ipairs(self.enemies) do
				if enemy:hasSkill("kongcheng") and enemy:isKongcheng() then
					local seat_diff = enemy:getSeat() - self.player:getSeat()
					local alive_count = self.room:alivePlayerCount()
					if seat_diff < 0 then seat_diff = seat_diff + alive_count end
					if seat_diff > alive_count / 2.5 + 1 then return enemy end
				end
			end
			for _, enemy in ipairs(self.enemies) do
				if enemy:hasSkills("bazhen|yizhong|bossmanjia") then
					return enemy
				end
			end
		end
		for _, friend in ipairs(targets) do
			local has_equip = false
			for _, equip in sgs.qlist(friend:getEquips()) do
				if equip:isKindOf(equip_type) then
					has_equip = true
					break
				end
			end
			if not has_equip then
				if equip_type == "Armor" then
					if not self:needKongcheng(friend) and not friend:hasSkills("bazhen|yizhong|bossmanjia") then return friend end
				else
					if friend:isWounded() and not (friend:hasSkill("longhun") and friend:getCardCount() >= 3) then return friend end
				end
			end
		end
	else
		for _, friend in ipairs(targets) do
			local has_equip = false
			for _, equip in sgs.qlist(friend:getEquips()) do
				if equip:isKindOf(equip_type) then
					has_equip = true
					break
				end
			end
			if not has_equip then
				for _, aplayer in sgs.qlist(self.room:getAllPlayers()) do
					if friend:distanceTo(aplayer) == 1 then
						if self:isFriend(aplayer) and not aplayer:containsTrick("YanxiaoCard")
							and (aplayer:containsTrick("indulgence") or aplayer:containsTrick("supply_shortage")
								or (aplayer:containsTrick("lightning") and self:hasWizard(self.enemies))) then
							aplayer:setFlags("AI_YuanhuToChoose")
							return friend
						end
					end
				end
				self:sort(self.enemies, "defense")
				for _, enemy in ipairs(self.enemies) do
					if friend:distanceTo(enemy) == 1 and self.player:canDiscard(enemy, "he") then
						enemy:setFlags("AI_YuanhuToChoose")
						return friend
					end
				end
			end
		end
	end
	return nil
end

sgs.ai_skill_use["@@yuanhu"] = function(self, prompt)
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	if self.player:hasArmorEffect("silver_lion") then
		local player = yuanhu_validate(self, "SilverLion", false)
		if player then return "@YuanhuCard=" .. self.player:getArmor():getEffectiveId() .. "->" .. player:objectName() end
	end
	if self.player:getOffensiveHorse() then
		local player = yuanhu_validate(self, "OffensiveHorse", false)
		if player then return "@YuanhuCard=" .. self.player:getOffensiveHorse():getEffectiveId() .. "->" .. player:objectName() end
	end
	if self.player:getWeapon() then
		local player = yuanhu_validate(self, "Weapon", false)
		if player then return "@YuanhuCard=" .. self.player:getWeapon():getEffectiveId() .. "->" .. player:objectName() end
	end
	if self.player:getArmor() and self.player:getLostHp() <= 1 and self.player:getHandcardNum() >= 3 then
		local player = yuanhu_validate(self, "Armor", false)
		if player then return "@YuanhuCard=" .. self.player:getArmor():getEffectiveId() .. "->" .. player:objectName() end
	end
	for _, card in ipairs(cards) do
		if card:isKindOf("DefensiveHorse") then
			local player = yuanhu_validate(self, "DefensiveHorse", true)
			if player then return "@YuanhuCard=" .. card:getEffectiveId() .. "->" .. player:objectName() end
		end
	end
	for _, card in ipairs(cards) do
		if card:isKindOf("OffensiveHorse") then
			local player = yuanhu_validate(self, "OffensiveHorse", true)
			if player then return "@YuanhuCard=" .. card:getEffectiveId() .. "->" .. player:objectName() end
		end
	end
	for _, card in ipairs(cards) do
		if card:isKindOf("Weapon") then
			local player = yuanhu_validate(self, "Weapon", true)
			if player then return "@YuanhuCard=" .. card:getEffectiveId() .. "->" .. player:objectName() end
		end
	end
	for _, card in ipairs(cards) do
		if card:isKindOf("SilverLion") then
			local player = yuanhu_validate(self, "SilverLion", true)
			if player then return "@YuanhuCard=" .. card:getEffectiveId() .. "->" .. player:objectName() end
		end
		if card:isKindOf("Armor") and yuanhu_validate(self, "Armor", true) then
			local player = yuanhu_validate(self, "Armor", true)
			if player then return "@YuanhuCard=" .. card:getEffectiveId() .. "->" .. player:objectName() end
		end
	end
end

sgs.ai_skill_playerchosen.yuanhu = function(self, targets)
	targets = sgs.QList2Table(targets)
	for _, p in ipairs(targets) do
		if p:hasFlag("AI_YuanhuToChoose") then
			p:setFlags("-AI_YuanhuToChoose")
			return p
		end
	end
	return targets[1]
end

sgs.ai_card_intention.YuanhuCard = function(self, card, from, to)
	if to[1]:hasSkills("bazhen|yizhong|bossmanjia") or (to[1]:hasSkill("kongcheng") and to[1]:isKongcheng()) then
		if sgs.Sanguosha:getCard(card:getEffectiveId()):isKindOf("SilverLion") then
			sgs.updateIntention(from, to[1], 10)
			return
		end
	end
	sgs.updateIntention(from, to[1], -50)
end

sgs.ai_cardneed.yuanhu = sgs.ai_cardneed.equip

sgs.yuanhu_keep_value = {
	Peach = 6,
	Jink = 5.1,
	Weapon = 4.7,
	Armor = 4.8,
	Horse = 4.9
}

local xueji_skill = {}
xueji_skill.name = "xueji"
table.insert(sgs.ai_skills, xueji_skill)
xueji_skill.getTurnUseCard = function(self, inclusive)
	if self.player:getLostHp() == 0 or self.player:hasUsed("XuejiCard") then return end
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)

	local red_card

	self:sortByUseValue(cards, true)

	for _, card in ipairs(cards) do
		if card:isRed() and not card:isKindOf("Peach") and (self:getUseValue(card) < sgs.ai_use_value.Slash or inclusive) then
			red_card = card
			break
		end
	end

	if red_card then
		local card_id = red_card:getEffectiveId()
		local card_str = ("@XuejiCard=" .. card_id)
		local xueji_card = sgs.Card_Parse(card_str)
		assert(xueji_card)
		return xueji_card
	end
end

local function can_be_selected_as_target_xueji(self, card, who)
	-- validation of rule
	if self.player:getWeapon() and self.player:getWeapon():getEffectiveId() == card:getEffectiveId() then
		if not self.player:inMyAttackRange(who, sgs.weapon_range[self.player:getWeapon():getClassName()] - self.player:getAttackRange(false)) then return false end
	elseif self.player:getOffensiveHorse() and self.player:getOffensiveHorse():getEffectiveId() == card:getEffectiveId() then
		if not self.player:inMyAttackRange(who, 1) then return false end
	elseif not self.player:inMyAttackRange(who) then
		return false
	end
	-- validation of strategy
	if self:cantbeHurt(who) or not self:damageIsEffective(who) then return false end
	if self:isEnemy(who) then
		if not self.player:hasSkill("jueqing") then
			if who:hasSkill("guixin") and (self.room:getAliveCount() >= 4 or not who:faceUp()) and not who:hasSkill("manjuan") then return false end
			if self.player:getHp() == 1 and ((who:hasSkills("vsganglie|nosganglie") and self.player:getHandcardNum() <= 2) or who:hasSkill("ganglie")) then return false end
			if who:hasSkill("jieming") then
				for _, enemy in ipairs(self.enemies) do
					if enemy:getHandcardNum() <= enemy:getMaxHp() - 2 and not enemy:hasSkill("manjuan") then return false end
				end
			end
			if who:hasSkill("fangzhu") then
				for _, enemy in ipairs(self.enemies) do
					if not enemy:faceUp() then return false end
				end
			end
			if who:hasSkill("nosyiji") then
				local huatuo = self.room:findPlayerBySkillName("jijiu")
				if huatuo and self:isEnemy(huatuo) and huatuo:getHandcardNum() >= 3 then
					return false
				end
			end
		end
		return true
	elseif self:isFriend(who) then
		if who:hasSkill("nosyiji") and not self.player:hasSkill("jueqing") then
			local huatuo = self.room:findPlayerBySkillName("jijiu")
			if (huatuo and self:isFriend(huatuo) and huatuo:getHandcardNum() >= 3 and huatuo ~= self.player)
				or (who:getLostHp() == 0 and who:getMaxHp() >= 3) then
				return true
			end
		end
		if who:hasSkill("hunzi") and who:getMark("hunzi") == 0
			and who:objectName() == self.player:getNextAlive():objectName() and who:getHp() == 2 then return true end
		return false
	end
	return false
end

sgs.ai_skill_use_func.XuejiCard = function(card, use, self)
	self:sort(self.enemies)
	local to_use = false
	for _, enemy in ipairs(self.enemies) do
		if can_be_selected_as_target_xueji(self, card, enemy) then
			to_use = true
			break
		end
	end
	if not to_use then
		for _, friend in ipairs(self.friends_noself) do
			if can_be_selected_as_target_xueji(self, card, friend) then
				to_use = true
				break
			end
		end
	end
	if to_use then
		use.card = card
		if use.to then
			for _, enemy in ipairs(self.enemies) do
				if can_be_selected_as_target_xueji(self, card, enemy) then
					use.to:append(enemy)
					if use.to:length() == self.player:getLostHp() then return end
				end
			end
			for _, friend in ipairs(self.friends_noself) do
				if can_be_selected_as_target_xueji(self, card, friend) then
					use.to:append(friend)
					if use.to:length() == self.player:getLostHp() then return end
				end
			end
			assert(use.to:length() > 0)
		end
	end
end

sgs.ai_use_value.XuejiCard = 3
sgs.ai_use_priority.XuejiCard = 3

sgs.ai_card_intention.XuejiCard = function(self, card, from, tos)
	local huatuo = self.room:findPlayerBySkillName("jijiu")
	for _, to in ipairs(tos) do
		local intention = 60
		if to:hasSkill("nosyiji") and not from:hasSkill("jueqing") then
			if (huatuo and self:isFriend(huatuo) and huatuo:getHandcardNum() >= 3 and huatuo:objectName() ~= from:objectName()) then
				intention = -30
			end
			if to:getLostHp() == 0 and to:getMaxHp() >= 3 then
				intention = -10
			end
		end
		if to:hasSkill("hunzi") and to:getMark("hunzi") == 0
			and to:objectName() == from:getNextAlive():objectName() and to:getHp() == 2 then intention = -20 end
		sgs.updateIntention(from, to, intention)
	end
end

sgs.ai_cardneed.xueji = function(to, card)
	return to:getHandcardNum() < 3 and card:isRed()
end

sgs.ai_skill_use["@@bifa"] = function(self, prompt)
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	self:sort(self.enemies, "handcard")
	if #self.enemies == 0 then return "." end
	for _, enemy in ipairs(self.enemies) do
		if not self:needToLoseHp(enemy) and enemy:getPile("bifa"):isEmpty() then
			for _, c in ipairs(cards) do
				if c:isKindOf("EquipCard") then return "@BifaCard=" .. c:getEffectiveId() .. "->" .. self.enemies[1]:objectName() end
			end
			for _, c in ipairs(cards) do
				if c:isKindOf("TrickCard") and not (c:isKindOf("Nullification") and self:getCardsNum("Nullification") == 1) then
					return "@BifaCard=" .. c:getEffectiveId() .. "->" .. self.enemies[1]:objectName()
				end
			end
			for _, c in ipairs(cards) do
				if c:isKindOf("Slash") then
					return "@BifaCard=" .. c:getEffectiveId() .. "->" .. self.enemies[1]:objectName()
				end
			end
		end
	end
	return "."
end

sgs.ai_skill_cardask["@bifa-give"] = function(self, data)
	if self:needToLoseHp() then return "." end
	local card_type = data:toString()
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards)
	for _, c in ipairs(cards) do
		if c:isKindOf(card_type) and not isCard("Peach", c, self.player) and not isCard("ExNihilo", c, self.player) then
			return "$" .. c:getEffectiveId()
		end
	end
	return "."
end

sgs.ai_card_intention.BifaCard = 30

sgs.bifa_keep_value = {
	Peach = 6,
	Jink = 5.1,
	Nullification = 5,
	EquipCard = 4.9,
	TrickCard = 4.8
}

local songci_skill = {}
songci_skill.name = "songci"
table.insert(sgs.ai_skills, songci_skill)
songci_skill.getTurnUseCard = function(self)
	return sgs.Card_Parse("@SongciCard=.")
end

sgs.ai_skill_use_func.SongciCard = function(card, use, self)
	self:sort(self.friends, "handcard")
	for _, friend in ipairs(self.friends) do
		if friend:getMark("songci" .. self.player:objectName()) == 0 and friend:getHandcardNum() < friend:getHp() and not (friend:hasSkill("manjuan") and self.room:getCurrent() ~= friend) then
			if not (friend:hasSkill("kongcheng") and friend:isKongcheng()) then
				use.card = sgs.Card_Parse("@SongciCard=.")
				if use.to then use.to:append(friend) end
				return
			end
		end
	end

	self:sort(self.enemies, "handcard")
	self.enemies = sgs.reverse(self.enemies)
	for _, enemy in ipairs(self.enemies) do
		if enemy:getMark("songci" .. self.player:objectName()) == 0 and enemy:getHandcardNum() > enemy:getHp() and not enemy:isNude()
			and not self:doNotDiscard(enemy, "nil", false, 2) then
			use.card = sgs.Card_Parse("@SongciCard=.")
			if use.to then use.to:append(enemy) end
			return
		end
	end
end

sgs.ai_use_value.SongciCard = 3
sgs.ai_use_priority.SongciCard = 3

sgs.ai_card_intention.SongciCard = function(self, card, from, to)
	sgs.updateIntention(from, to[1], to[1]:getHandcardNum() > to[1]:getHp() and 80 or -80)
end

sgs.ai_skill_cardask["@xingwu"] = function(self, data)
	local cards = sgs.QList2Table(self.player:getHandcards())
	if #cards <= 1 and self.player:getPile("xingwu"):length() == 1 then return "." end

	local good_enemies = {}
	for _, enemy in ipairs(self.enemies) do
		if enemy:isMale() and ((self:damageIsEffective(enemy) and not self:cantbeHurt(enemy, self.player, 2))
								or (not self:damageIsEffective(enemy) and not enemy:getEquips():isEmpty()
									and not (enemy:getEquips():length() == 1 and enemy:getArmor() and self:needToThrowArmor(enemy)))) then
			table.insert(good_enemies, enemy)
		end
	end
	if #good_enemies == 0 and (not self.player:getPile("xingwu"):isEmpty() or not self.player:hasSkill("luoyan")) then return "." end

	local red_avail, black_avail
	local n = self.player:getMark("xingwu")
	if bit32.band(n, 2) == 0 then red_avail = true end
	if bit32.band(n, 1) == 0 then black_avail = true end

	self:sortByKeepValue(cards)
	local xwcard = nil
	local heart = 0
	local to_save = 0
	for _, card in ipairs(cards) do
		if self.player:hasSkill("tianxiang") and card:getSuit() == sgs.Card_Heart and heart < math.min(self.player:getHp(), 2) then
			heart = heart + 1
		elseif isCard("Jink", card, self.player) then
			if self.player:hasSkill("liuli") and self.room:alivePlayerCount() > 2 then
				for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
					if self:canLiuli(self.player, p) then
						xwcard = card
						break
					end
				end
			end
			if not xwcard and self:getCardsNum("Jink") >= 2 then
				xwcard = card
			end
		elseif to_save > self.player:getMaxCards()
				or (not isCard("Peach", card, self.player) and not (self:isWeak() and isCard("Analeptic", card, self.player))) then
			xwcard = card
		else
			to_save = to_save + 1
		end
		if xwcard then
			if (red_avail and xwcard:isRed()) or (black_avail and xwcard:isBlack()) then
				break
			else
				xwcard = nil
				to_save = to_save + 1
			end
		end
	end
	if xwcard then return "$" .. xwcard:getEffectiveId() else return "." end
end

sgs.ai_skill_playerchosen.xingwu = function(self, targets)
	local good_enemies = {}
	for _, enemy in ipairs(self.enemies) do
		if enemy:isMale() then
			table.insert(good_enemies, enemy)
		end
	end
	if #good_enemies == 0 then return targets:first() end

	local getCmpValue = function(enemy)
		local value = 0
		if self:damageIsEffective(enemy) then
			local dmg = enemy:hasArmorEffect("silver_lion") and 1 or 2
			if enemy:getHp() <= dmg then value = 5 else value = value + enemy:getHp() / (enemy:getHp() - dmg) end
			if not sgs.isGoodTarget(enemy, self.enemies, self) then value = value - 2 end
			if self:cantbeHurt(enemy, self.player, dmg) then value = value - 5 end
			if enemy:isLord() then value = value + 2 end
			if enemy:hasArmorEffect("silver_lion") then value = value - 1.5 end
			if enemy:hasSkills(sgs.exclusive_skill) then value = value - 1 end
			if enemy:hasSkills(sgs.masochism_skill) then value = value - 0.5 end
		end
		if not enemy:getEquips():isEmpty() then
			local len = enemy:getEquips():length()
			if enemy:hasSkills(sgs.lose_equip_skill) then value = value - 0.6 * len end
			if enemy:getArmor() and self:needToThrowArmor() then value = value - 1.5 end
			if enemy:hasArmorEffect("silver_lion") then value = value - 0.5 end

			if enemy:getWeapon() then value = value + 0.8 end
			if enemy:getArmor() then value = value + 1 end
			if enemy:getDefensiveHorse() then value = value + 0.9 end
			if enemy:getOffensiveHorse() then value = value + 0.7 end
			if self:getDangerousCard(enemy) then value = value + 0.3 end
			if self:getValuableCard(enemy) then value = value + 0.15 end
		end
		return value
	end

	local cmp = function(a, b)
		return getCmpValue(a) > getCmpValue(b)
	end
	table.sort(good_enemies, cmp)
	return good_enemies[1]
end

sgs.ai_playerchosen_intention.xingwu = 80

sgs.ai_skill_cardask["@yanyu-discard"] = function(self, data)
	if self.player:getHandcardNum() < 3 and self.player:getPhase() ~= sgs.Player_Play then
		if self:needToThrowArmor() then return "$" .. self.player:getArmor():getEffectiveId()
		elseif self:needKongcheng(self.player, true) and self.player:getHandcardNum() == 1 then return "$" .. self.player:handCards():first()
		else return "." end
	end
	local current = self.room:getCurrent()
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByKeepValue(cards)
	if current:objectName() == self.player:objectName() then
		local ex_nihilo, savage_assault, archery_attack
		for _, card in ipairs(cards) do
			if card:isKindOf("ExNihilo") then ex_nihilo = card
			elseif card:isKindOf("SavageAssault") and not current:hasSkills("wuyan|noswuyan") then savage_assault = card
			elseif card:isKindOf("ArcheryAttack") and not current:hasSkills("wuyan|noswuyan") then archery_attack = card
			end
		end
		if savage_assault and self:getAoeValue(savage_assault) <= 0 then savage_assault = nil end
		if archery_attack and self:getAoeValue(archery_attack) <= 0 then archery_attack = nil end
		local aoe = archery_attack or savage_assault
		if ex_nihilo then
			for _, card in ipairs(cards) do
				if card:getTypeId() == sgs.Card_TypeTrick and not card:isKindOf("ExNihilo") and card:getEffectiveId() ~= ex_nihilo:getEffectiveId() then
					return "$" .. card:getEffectiveId()
				end
			end
		end
		if self.player:isWounded() then
			local peach
			for _, card in ipairs(cards) do
				if card:isKindOf("Peach") then
					peach = card
					break
				end
			end
			local dummy_use = { isDummy = true }
			self:useCardPeach(peach, dummy_use)
			if dummy_use.card and dummy_use.card:isKindOf("Peach") then
				for _, card in ipairs(cards) do
					if card:getTypeId() == sgs.Card_TypeBasic and card:getEffectiveId() ~= peach:getEffectiveId() then
						return "$" .. card:getEffectiveId()
					end
				end
			end
		end
		if aoe then
			for _, card in ipairs(cards) do
				if card:getTypeId() == sgs.Card_TypeTrick and card:getEffectiveId() ~= aoe:getEffectiveId() then
					return "$" .. card:getEffectiveId()
				end
			end
		end
		if self:getCardsNum("Slash") > 1 then
			for _, card in ipairs(cards) do
				if card:objectName() == "slash" then
					return "$" .. card:getEffectiveId()
				end
			end
		end
	else
		local throw_trick
		local aoe_type
		if getCardsNum("ArcheryAttack", current, self.player) >= 1 and not current:hasSkills("wuyan|noswuyan") then aoe_type = "archery_attack" end
		if getCardsNum("SavageAssault", current, self.player) >= 1 and not current:hasSkills("wuyan|noswuyan") then aoe_type = "savage_assault" end
		if aoe_type then
			local aoe = sgs.cloneCard(aoe_type)
			if self:getAoeValue(aoe, current) > 0 then throw_trick = true end
		end
		if getCardsNum("ExNihilo", current, self.player) > 0 then throw_trick = true end
		if throw_trick then
			for _, card in ipairs(cards) do
				if card:getTypeId() == sgs.Card_TypeTrick and not isCard("ExNihilo", card, self.player) then
					return "$" .. card:getEffectiveId()
				end
			end
		end
		if self:getCardsNum("Slash") > 1 then
			for _, card in ipairs(cards) do
				if card:objectName() == "slash" then
					return "$" .. card:getEffectiveId()
				end
			end
		end
		if self:getCardsNum("Jink") > 1 then
			for _, card in ipairs(cards) do
				if card:isKindOf("Jink") then
					return "$" .. card:getEffectiveId()
				end
			end
		end
		if self.player:getHp() >= 3 and (self.player:getHandcardNum() > 3 or self:getCardsNum("Peach") > 0) then
			for _, card in ipairs(cards) do
				if card:isKindOf("Slash") then
					return "$" .. card:getEffectiveId()
				end
			end
		end
		if getCardsNum("TrickCard", current, self.player) - getCardsNum("Nullification", current, self.player) > 0 then
			for _, card in ipairs(cards) do
				if card:getTypeId() == sgs.Card_TypeTrick and not isCard("ExNihilo", card, self.player) then
					return "$" .. card:getEffectiveId()
				end
			end
		end
	end
	if self:needToThrowArmor() then return "$" .. self.player:getArmor():getEffectiveId() else return "." end
end

sgs.ai_skill_askforag.yanyu = function(self, card_ids)
	local cards = {}
	for _, id in ipairs(card_ids) do
		table.insert(cards, sgs.Sanguosha:getEngineCard(id))
	end
	self.yanyu_need_player = nil
	local card, player = self:getCardNeedPlayer(cards, self.friends)
	if card and player then
		self.yanyu_need_player = player
		return card:getEffectiveId()
	end
	return -1
end

sgs.ai_skill_playerchosen.yanyu = function(self, targets)
	local only_id = self.player:getMark("YanyuOnlyId") - 1
	if only_id < 0 then
		assert(self.yanyu_need_player ~= nil)
		return self.yanyu_need_player
	else
		local card = sgs.Sanguosha:getEngineCard(only_id)
		if card:getTypeId() == sgs.Card_TypeTrick and not card:isKindOf("Nullification") then
			return self.player
		end
		local cards = { card }
		local c, player = self:getCardNeedPlayer(cards, self.friends)
		if player then return player
		else
			self:sort(self.friends)
			for _, friend in ipairs(self.friends) do
				if not self:needKongcheng(friend) and not hasManjuanEffect(friend) then
					return friend
				end
			end
		end
	end
end

sgs.ai_playerchosen_intention.yanyu = function(self, from, to)
	if hasManjuanEffect(to) then return end
	local intention = -60
	if self:needKongcheng(to, true) then intention = 10 end
	sgs.updateIntention(from, to, intention)
end

sgs.ai_skill_invoke.xiaode = function(self, data)
	local round = self:playerGetRound(self.player)
	local xiaode_skill = sgs.ai_skill_choice.huashen(self, table.concat(data:toStringList(), "+"), nil, math.random(1 - round, 7 - round))
	if xiaode_skill then
		sgs.xiaode_choice = xiaode_skill
		return true
	else
		sgs.xiaode_choice = nil
		return false
	end
end

sgs.ai_skill_choice.xiaode = function(self, choices)
	return sgs.xiaode_choice
end

function sgs.ai_cardsview_valuable.aocai(self, class_name, player)
	if player:hasFlag("Global_AocaiFailed") or player:getPhase() ~= sgs.Player_NotActive then return end
	if class_name == "Slash" and sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
		return "@AocaiCard=.:slash"
	elseif (class_name == "Peach" and player:getMark("Global_PreventPeach") == 0) or class_name == "Analeptic" then
		local dying = self.room:getCurrentDyingPlayer()
		if dying and dying:objectName() == player:objectName() then
			local user_string = "peach+analeptic"
			if player:getMark("Global_PreventPeach") > 0 then user_string = "analeptic" end
			return "@AocaiCard=.:" .. user_string
		else
			local user_string
			if class_name == "Analeptic" then user_string = "analeptic" else user_string = "peach" end
			return "@AocaiCard=.:" .. user_string
		end
	end
end

sgs.ai_skill_invoke.aocai = function(self, data)
	local asked = data:toStringList()
	local pattern = asked[1]
	local prompt = asked[2]
	return self:askForCard(pattern, prompt, 1) ~= "."
end

sgs.ai_skill_askforag.aocai = function(self, card_ids)
	local card = sgs.Sanguosha:getCard(card_ids[1])
	if card:isKindOf("Jink") and self.player:hasFlag("dahe") then
		for _, id in ipairs(card_ids) do
			if sgs.Sanguosha:getCard(id):getSuit() == sgs.Card_Heart then return id end
		end
		return -1
	end
	return card_ids[1]
end

local duwu_skill = {}
duwu_skill.name = "duwu"
table.insert(sgs.ai_skills, duwu_skill)
duwu_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasFlag("DuwuEnterDying") or #self.enemies == 0 then return end
	return sgs.Card_Parse("@DuwuCard=.")
end

sgs.ai_skill_use_func.DuwuCard = function(card, use, self)
	local cmp = function(a, b)
		if a:getHp() < b:getHp() then
			if a:getHp() == 1 and b:getHp() == 2 then return false else return true end
		end
		return false
	end
	local enemies = {}
	for _, enemy in ipairs(self.enemies) do
		if self:canAttack(enemy, self.player) and self.player:inMyAttackRange(enemy) then table.insert(enemies, enemy) end
	end
	if #enemies == 0 then return end
	table.sort(enemies, cmp)
	if enemies[1]:getHp() <= 0 then
		use.card = sgs.Card_Parse("@DuwuCard=.")
		if use.to then use.to:append(enemies[1]) end
		return
	end

	-- find cards
	local card_ids = {}
	if self:needToThrowArmor() then table.insert(card_ids, self.player:getArmor():getEffectiveId()) end

	local zcards = self.player:getHandcards()
	local use_slash, keep_jink, keep_analeptic = false, false, false
	for _, zcard in sgs.qlist(zcards) do
		if not isCard("Peach", zcard, self.player) and not isCard("ExNihilo", zcard, self.player) then
			local shouldUse = true
			if zcard:getTypeId() == sgs.Card_TypeTrick then
				local dummy_use = { isDummy = true }
				self:useTrickCard(zcard, dummy_use)
				if dummy_use.card then shouldUse = false end
			end
			if zcard:getTypeId() == sgs.Card_TypeEquip and not self.player:hasEquip(zcard) then
				local dummy_use = { isDummy = true }
				self:useEquipCard(zcard, dummy_use)
				if dummy_use.card then shouldUse = false end
			end
			if isCard("Jink", zcard, self.player) and not keep_jink then
				keep_jink = true
				shouldUse = false
			end
			if self.player:getHp() == 1 and isCard("Analeptic", zcard, self.player) and not keep_analeptic then
				keep_analeptic = true
				shouldUse = false
			end
			if shouldUse then table.insert(card_ids, zcard:getId()) end
		end
	end

	local to_discard = {}
	for _, id in ipairs(card_ids) do
		local c = sgs.Sanguosha:getCard(id)
		if not self.player:isJilei(c) then table.insert(to_discard, id) end
	end
	if #to_discard == 0 then return end

	local hc_num = #to_discard
	local eq_num = 0
	if self.player:getOffensiveHorse() and not self.player:isJilei(self.player:getOffensiveHorse()) then
		table.insert(to_discard, self.player:getOffensiveHorse():getEffectiveId())
		eq_num = eq_num + 1
	end
	if self.player:getWeapon() and self:evaluateWeapon(self.player:getWeapon()) < 5 and not self.player:isJilei(self.player:getWeapon()) then
		table.insert(to_discard, self.player:getWeapon():getEffectiveId())
		eq_num = eq_num + 2
	end

	local function getRangefix(index)
		if index <= hc_num then return 0
		elseif index == hc_num + 1 then
			if eq_num == 2 then
				return sgs.weapon_range[self.player:getWeapon():getClassName()] - self.player:getAttackRange(false)
			else
				return 1
			end
		elseif index == hc_num + 2 then
			return sgs.weapon_range[self.player:getWeapon():getClassName()]
		end
	end

	for _, enemy in ipairs(enemies) do
		if enemy:getHp() > #card_ids then continue end
		if enemy:getHp() <= 0 then
			use.card = sgs.Card_Parse("@DuwuCard=.")
			if use.to then use.to:append(enemy) end
			return
		elseif enemy:getHp() > 1 then
			local hp_ids = {}
			if self.player:inMyAttackRange(enemy, getRangefix(enemy:getHp())) then
				for _, id in ipairs(to_discard) do
					table.insert(hp_ids, id)
					if #hp_ids == enemy:getHp() then break end
				end
				if #hp_ids == enemy:getHp() then
					use.card = sgs.Card_Parse("@DuwuCard=" .. table.concat(hp_ids, "+"))
					if use.to then use.to:append(enemy) end
					return
				end
			end
		else
			if not self:isWeak() or self:getSaveNum(true) >= 1 then
				if self.player:inMyAttackRange(enemy, getRangefix(1)) then
					use.card = sgs.Card_Parse("@DuwuCard=" .. to_discard[1])
					if use.to then use.to:append(enemy) end
					return
				end
			end
		end
	end
end

sgs.ai_use_priority.DuwuCard = 0.6
sgs.ai_use_value.DuwuCard = 2.45
sgs.dynamic_value.damage_card.DuwuCard = true
sgs.ai_card_intention.DuwuCard = 80

function getNextJudgeReason(self, player)
	if self:playerGetRound(player) > 2 then
		if player:hasSkills("ganglie|nosganglie|vsganglie") then return end
		local caiwenji = self.room:findPlayerBySkillName("beige")
		if caiwenji and caiwenji:canDiscard(caiwenji, "he") and self:isFriend(caiwenji, player) then return end
		if player:hasArmorEffect("eight_diagram") or player:hasSkill("bazhen") then
			if self:playerGetRound(player) > 3 and self:isEnemy(player) then return "eight_diagram"
			else return end
		end
	end
	if self:isFriend(player) and player:hasSkill("luoshen") then return "luoshen" end
	if not player:getJudgingArea():isEmpty() and not player:containsTrick("YanxiaoCard") then
		return player:getJudgingArea():last():objectName()
	end
	if player:hasSkill("qianxi") then return "qianxi" end
	if player:hasSkill("nosmiji") and player:getLostHp() > 0 then return "nosmiji" end
	if player:hasSkill("tuntian") then return "tuntian" end
	if player:hasSkill("nosqianxi") then return "nosqianxi" end
end

local zhoufu_skill = {}
zhoufu_skill.name = "zhoufu"
table.insert(sgs.ai_skills, zhoufu_skill)
zhoufu_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("ZhoufuCard") or self.player:isKongcheng() then return end
	return sgs.Card_Parse("@ZhoufuCard=.")
end

sgs.ai_skill_use_func.ZhoufuCard = function(card, use, self)
	local cards = {}
	for _, card in sgs.qlist(self.player:getHandcards()) do
		table.insert(cards, sgs.Sanguosha:getEngineCard(card:getEffectiveId()))
	end
	self:sortByKeepValue(cards)
	self:sort(self.friends_noself)
	local zhenji
	for _, friend in ipairs(self.friends_noself) do
		if friend:getPile("incantation"):length() > 0 then continue end
		local reason = getNextJudgeReason(self, friend)
		if reason then
			if reason == "luoshen" then
				zhenji = friend
			elseif reason == "indulgence" then
				for _, card in ipairs(cards) do
					if card:getSuit() == sgs.Card_Heart or (friend:hasSkill("hongyan") and card:getSuit() == sgs.Card_Spade)
						and (friend:hasSkill("tiandu") or not self:isValuableCard(card)) then
						use.card = sgs.Card_Parse("@ZhoufuCard=" .. card:getEffectiveId())
						if use.to then use.to:append(friend) end
						return
					end
				end
			elseif reason == "supply_shortage" then
				for _, card in ipairs(cards) do
					if card:getSuit() == sgs.Card_Club and (friend:hasSkill("tiandu") or not self:isValuableCard(card)) then
						use.card = sgs.Card_Parse("@ZhoufuCard=" .. card:getEffectiveId())
						if use.to then use.to:append(friend) end
						return
					end
				end
			elseif reason == "lightning" and not friend:hasSkills("hongyan|wuyan") then
				for _, card in ipairs(cards) do
					if (card:getSuit() ~= sgs.Card_Spade or card:getNumber() == 1 or card:getNumber() > 9)
						and (friend:hasSkill("tiandu") or not self:isValuableCard(card)) then
						use.card = sgs.Card_Parse("@ZhoufuCard=" .. card:getEffectiveId())
						if use.to then use.to:append(friend) end
						return
					end
				end
			elseif reason == "nosmiji" then
				for _, card in ipairs(cards) do
					if card:getSuit() == sgs.Card_Club or (card:getSuit() == sgs.Card_Spade and not friend:hasSkill("hongyan")) then
						use.card = sgs.Card_Parse("@ZhoufuCard=" .. card:getEffectiveId())
						if use.to then use.to:append(friend) end
						return
					end
				end
			elseif reason == "nosqianxi" or reason == "tuntian" then
				for _, card in ipairs(cards) do
					if (card:getSuit() ~= sgs.Card_Heart and not (card:getSuit() == sgs.Card_Spade and friend:hasSkill("hongyan")))
						and (friend:hasSkill("tiandu") or not self:isValuableCard(card)) then
						use.card = sgs.Card_Parse("@ZhoufuCard=" .. card:getEffectiveId())
						if use.to then use.to:append(friend) end
						return
					end
				end
			elseif reason == "nostieji" then
				for _, card in ipairs(cards) do
					if (card:isRed() or (card:getSuit() == sgs.Card_Spade and friend:hasSkill("hongyan")))
						and (friend:hasSkill("tiandu") or not self:isValuableCard(card)) then
						use.card = sgs.Card_Parse("@ZhoufuCard=" .. card:getEffectiveId())
						if use.to then use.to:append(friend) end
						return
					end
				end
			end
		end
	end
	if zhenji then
		for _, card in ipairs(cards) do
			if card:isBlack() and not (zhenji:hasSkill("hongyan") and card:getSuit() == sgs.Card_Spade) then
				use.card = sgs.Card_Parse("@ZhoufuCard=" .. card:getEffectiveId())
				if use.to then use.to:append(zhenji) end
				return
			end
		end
	end
	self:sort(self.enemies)
	for _, enemy in ipairs(self.enemies) do
		if enemy:getPile("incantation"):length() > 0 then continue end
		local reason = getNextJudgeReason(self, enemy)
		if not enemy:hasSkill("tiandu") and reason then
			if reason == "indulgence" then
				for _, card in ipairs(cards) do
					if not (card:getSuit() == sgs.Card_Heart or (enemy:hasSkill("hongyan") and card:getSuit() == sgs.Card_Spade))
						and not self:isValuableCard(card) then
						use.card = sgs.Card_Parse("@ZhoufuCard=" .. card:getEffectiveId())
						if use.to then use.to:append(enemy) end
						return
					end
				end
			elseif reason == "supply_shortage" then
				for _, card in ipairs(cards) do
					if card:getSuit() ~= sgs.Card_Club and not self:isValuableCard(card) then
						use.card = sgs.Card_Parse("@ZhoufuCard=" .. card:getEffectiveId())
						if use.to then use.to:append(enemy) end
						return
					end
				end
			elseif reason == "lightning" and not enemy:hasSkills("hongyan|wuyan") then
				for _, card in ipairs(cards) do
					if card:getSuit() == sgs.Card_Spade and card:getNumber() >= 2 and card:getNumber() <= 9 then
						use.card = sgs.Card_Parse("@ZhoufuCard=" .. card:getEffectiveId())
						if use.to then use.to:append(enemy) end
						return
					end
				end
			elseif reason == "nosmiji" then
				for _, card in ipairs(cards) do
					if card:isRed() or (card:getSuit() == sgs.Card_Spade and enemy:hasSkill("hongyan")) then
						use.card = sgs.Card_Parse("@ZhoufuCard=" .. card:getEffectiveId())
						if use.to then use.to:append(enemy) end
						return
					end
				end
			elseif reason == "nosqianxi" or reason == "tuntian" then
				for _, card in ipairs(cards) do
					if (card:getSuit() == sgs.Card_Heart or (card:getSuit() == sgs.Card_Spade and enemy:hasSkill("hongyan")))
						and not self:isValuableCard(card) then
						use.card = sgs.Card_Parse("@ZhoufuCard=" .. card:getEffectiveId())
						if use.to then use.to:append(enemy) end
						return
					end
				end
			elseif reason == "nostieji" then
				for _, card in ipairs(cards) do
					if (card:getSuit() == sgs.Card_Club or (card:getSuit() == sgs.Card_Spade and not enemy:hasSkill("hongyan")))
						and not self:isValuableCard(card) then
						use.card = sgs.Card_Parse("@ZhoufuCard=" .. card:getEffectiveId())
						if use.to then use.to:append(enemy) end
						return
					end
				end
			end
		end
	end

	local has_indulgence, has_supplyshortage
	local friend
	for _, p in ipairs(self.friends) do
		if getKnownCard(p, self.player, "Indulgence", true, "he") > 0 then
			has_indulgence = true
			friend = p
			break
		end
		if getKnownCard(p, self.player, "SupplySortage", true, "he") > 0 then
			has_supplyshortage = true
			friend = p
			break
		end
	end
	if has_indulgence then
		local indulgence = sgs.cloneCard("indulgence")
		for _, enemy in ipairs(self.enemies) do
			if enemy:getPile("incantation"):length() > 0 then continue end
			if self:hasTrickEffective(indulgence, enemy, friend) and self:playerGetRound(friend) < self:playerGetRound(enemy) and not self:willSkipPlayPhase(enemy) then
				for _, card in ipairs(cards) do
					if not (card:getSuit() == sgs.Card_Heart or (enemy:hasSkill("hongyan") and card:getSuit() == sgs.Card_Spade))
						and not self:isValuableCard(card) then
						use.card = sgs.Card_Parse("@ZhoufuCard=" .. card:getEffectiveId())
						if use.to then use.to:append(enemy) end
						return
					end
				end
			end
		end
	elseif has_supplyshortage then
		local supplyshortage = sgs.cloneCard("supply_shortage")
		local distance = self:getDistanceLimit(supplyshortage, friend)
		for _, enemy in ipairs(self.enemies) do
			if enemy:getPile("incantation"):length() > 0 then continue end
			if self:hasTrickEffective(supplyshortage, enemy, friend) and self:playerGetRound(friend) < self:playerGetRound(enemy)
				and not self:willSkipDrawPhase(enemy) and friend:distanceTo(enemy) <= distance then
				for _, card in ipairs(cards) do
					if card:getSuit() ~= sgs.Card_Club and not self:isValuableCard(card) then
						use.card = sgs.Card_Parse("@ZhoufuCard=" .. card:getEffectiveId())
						if use.to then use.to:append(enemy) end
						return
					end
				end
			end
		end
	end
end

sgs.ai_card_intention.ZhoufuCard = 0
sgs.ai_use_value.ZhoufuCard = 2
sgs.ai_use_priority.ZhoufuCard = 1.0

local function getKangkaiCard(self, target, data)
	local use = data:toCardUse()
	local weapon, armor, def_horse, off_horse = {}, {}, {}, {}
	for _, card in sgs.qlist(self.player:getHandcards()) do
		if card:isKindOf("Weapon") then table.insert(weapon, card)
		elseif card:isKindOf("Armor") then table.insert(armor, card)
		elseif card:isKindOf("DefensiveHorse") then table.insert(def_horse, card)
		elseif card:isKindOf("OffensiveHorse") then table.insert(off_horse, card)
		end
	end
	if #armor > 0 then
		for _, card in ipairs(armor) do
			if ((not target:getArmor() and not target:hasSkills("bazhen|yizhong|bossmanjia"))
				or (target:getArmor() and self:evaluateArmor(card, target) >= self:evaluateArmor(target:getArmor(), target)))
				and not (card:isKindOf("Vine") and use.card:isKindOf("FireSlash") and self:slashIsEffective(use.card, target, use.from)) then
				return card:getEffectiveId()
			end
		end
	end
	if self:needToThrowArmor()
		and ((not target:getArmor() and not target:hasSkills("bazhen|yizhong|bossmanjia"))
			or (target:getArmor() and self:evaluateArmor(self.player:getArmor(), target) >= self:evaluateArmor(target:getArmor(), target)))
		and not (self.player:getArmor():isKindOf("Vine") and use.card:isKindOf("FireSlash") and self:slashIsEffective(use.card, target, use.from)) then
		return self.player:getArmor():getEffectiveId()
	end
	if #def_horse > 0 then return def_horse[1]:getEffectiveId() end
	if #weapon > 0 then
		for _, card in ipairs(weapon) do
			if not target:getWeapon()
				or (self:evaluateArmor(card, target) >= self:evaluateArmor(target:getWeapon(), target)) then
				return card:getEffectiveId()
			end
		end
	end
	if self.player:getWeapon() and self:evaluateWeapon(self.player:getWeapon()) < 5
		and (not target:getArmor()
			or (self:evaluateArmor(self.player:getWeapon(), target) >= self:evaluateArmor(target:getWeapon(), target))) then
		return self.player:getWeapon():getEffectiveId()
	end
	if #off_horse > 0 then return off_horse[1]:getEffectiveId() end
	if self.player:getOffensiveHorse()
		and ((self.player:getWeapon() and not self.player:getWeapon():isKindOf("Crossbow")) or self.player:hasSkills("tannang|mashu|tuntian")) then
		return self.player:getOffensiveHorse():getEffectiveId()
	end
end

sgs.ai_skill_invoke.kangkai = function(self, data)
	self.kangkai_give_id = nil
	if hasManjuanEffect(self.player) then return false end
	local target = data:toPlayer()
	if not target then return false end
	if target:objectName() == self.player:objectName() then
		return true
	elseif not self:isFriend(target) then
		return hasManjuanEffect(target)
	else
		local id = getKangkaiCard(self, target, self.player:getTag("KangkaiSlash"))
		if id then return true else return not self:needKongcheng(target, true) end
	end
end

sgs.ai_skill_invoke.shenxian = function(self, data)
	return not hasManjuanEffect(self.player) and not self:needKongcheng(self.player, true)
end

local qiangwu_skill = {}
qiangwu_skill.name = "qiangwu"
table.insert(sgs.ai_skills, qiangwu_skill)
qiangwu_skill.getTurnUseCard = function(self, inclusive)
	if not self.player:hasUsed("QiangwuCard") then
		return sgs.Card_Parse("@QiangwuCard=.")
	end
end

sgs.ai_skill_use_func.QiangwuCard = function(card, use, self)
	use.card = card
end

sgs.ai_use_priority.QiangwuCard = 11.0

sgs.ai_skill_cardask["@kangkai-give"] = function(self, data, pattern, target)
	if self:isFriend(target) then
		local id = getKangkaiCard(self, target, data)
		if id then return "$" .. id end
		if self:getCardsNum("Jink") > 1 then
			for _, card in sgs.qlist(self.player:getHandcards()) do
				if isCard("Jink", card, target) then return "$" .. card:getEffectiveId() end
			end
		end
		for _, card in sgs.qlist(self.player:getHandcards()) do
			if not self:isValuableCard(card) then return "$" .. card:getEffectiveId() end
		end
	else
		local to_discard = self:askForDiscard("dummyreason", 1, 1, false, true)
		if #to_discard > 0 then return "$" .. to_discard[1] end
	end
end

sgs.ai_skill_invoke.kangkai_use = function(self, data)
	local use = self.player:getTag("KangkaiSlash"):toCardUse()
	local card = self.player:getTag("KangkaiCard"):toCard()
	if not use.card or not card then return false end
	if card:isKindOf("Vine") and use.card:isKindOf("FireSlash") and self:slashIsEffective(use.card, self.player, use.from) then return false end
	if ((card:isKindOf("DefensiveHorse") and self.player:getDefensiveHorse())
		or (card:isKindOf("OffensiveHorse") and self.player:getOffensiveHorse()))
		and not self.player:hasSkills(sgs.lose_equip_skill) then
		return false
	end
	if card:isKindOf("Armor")
		and ((self.player:hasSkills("bazhen|yizhong|bossmanjia") and not self.player:getArmor())
			or (self.player:getArmor() and self:evaluateArmor(card) < self:evaluateArmor(self.player:getArmor()))) then return false end
	if card:isKindOf("Weanpon") and (self.player:getWeapon() and self:evaluateArmor(card) < self:evaluateArmor(self.player:getWeapon())) then return false end
	return true
end

sgs.ai_skill_use["@@yinbing"] = function(self, prompt)
	local ids = {}
	if self:needToThrowArmor() then table.insert(ids, self.player:getArmor():getEffectiveId()) end
	local cards = sgs.QList2Table(self.player:getHandcards())
	if #cards > 0 then
		self:sortByKeepValue(cards)
		local kept_null
		for _, card in ipairs(cards) do
			if card:getTypeId() == sgs.Card_TypeBasic or self:isValuableCard(card) then continue end
			if card:getTypeId() == sgs.Card_TypeEquip then
				if self:getSameEquip(card, self.player)
					or (card:isKindOf("Weapon") and self:evaluateWeapon(card, self.player) <= 3)
					or (card:isKindOf("Armor") and self:evaluateArmor(card, self.player) <= 1) then
					table.insert(ids, card:getEffectiveId())
				end
			elseif card:getTypeId() == sgs.Card_TypeTrick then
				if card:isKindOf("Nullification") then
					if not kept_null then kept_null = true else table.insert(ids, card:getEffectiveId()) end
				elseif self:getUseValue(card) < 6 then
					table.insert(ids, card:getEffectiveId())
				end
			end
		end
	end
	if #ids > 0 then
		return "@YinbingCard=" .. table.concat(ids, "+") .. "->."
	end
	return "."
end

sgs.ai_skill_invoke.juedi = true

sgs.ai_skill_playerchosen.juedi = function(self, targets)
	local ids = self.player:getPile("yinbing")
	local friends = self:getWoundedFriend()
	for _, friend in ipairs(friends) do
		if friend:getHp() <= self.player:getHp()
			and not (self:needKongcheng(friend, true) and not self:isWeak(friend)) and not (hasManjuanEffect(friend) and ids:length() > 2) then
			return friend
		end
	end
	if ids:length() == 1 then
		local id = ids:first()
		local card = sgs.Sanguosha:getCard(id)
		if card:isKindOf("Disaster") or card:isKindOf("AmazingGrace") or card:isKindOf("GodSalvation") or card:isKindOf("OffensiveHorse") then
			for _, enemy in ipairs(self.enemies) do
				if not enemy:isWounded() and enemy:getHp() <= self.player:getHp() and self:needKongcheng(enemy, true) then return enemy end
			end
		end
	end
	return nil
end

sgs.ai_playerchosen_intention.juedi = function(self, from, to)
	if not to:isWounded() and self:needKongcheng(to, true) then
	else
		sgs.updateIntention(from, to, -60)
	end
end

sgs.ai_skill_use["@@qingyi"] = function(self, prompt)
	local card_str = sgs.ai_skill_use["@@shensu1"](self, "@shensu1")
	return string.gsub(card_str, "ShensuCard", "QingyiCard")
end

sgs.ai_card_intention.QingyiCard = sgs.ai_card_intention.Slash