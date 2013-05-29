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

local junxing_skill = {}
junxing_skill.name = "junxing"
table.insert(sgs.ai_skills, junxing_skill)
junxing_skill.getTurnUseCard = function(self)
	if self.player:isKongcheng() or self.player:hasUsed("JunxingCard") then return nil end
	return sgs.Card_Parse("@JunxingCard=.")
end

sgs.ai_skill_use_func.JunxingCard = function(card, use, self)
	-- find enough cards
	local unpreferedCards = {}
	local cards = sgs.QList2Table(self.player:getHandcards())
	local use_slash_num = 0
	self:sortByKeepValue(cards)
	for _, card in ipairs(cards) do
		if card:isKindOf("Slash") then
			local will_use = false
			if use_slash_num <= sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, self.player, card) then
				local dummy_use = { isDummy = true }
				self:useBasicCard(card, dummy_use)
				if dummy_use.card then
					will_use = true
					use_slash_num = use_slash_num + 1
				end
			end
			if not will_use then table.insert(unpreferedCards, card:getId()) end
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
		if card:isKindOf("EquipCard") then
			local dummy_use = { isDummy = true }
			self:useEquipCard(card, dummy_use)
			if not dummy_use.card then table.insert(unpreferedCards, card:getId()) end
		end
	end
	for _, card in ipairs(cards) do
		if card:isNDTrick() or card:isKindOf("Lightning") then
			local dummy_use = { isDummy = true }
			self:useTrickCard(card, dummy_use)
			if not dummy_use.card then table.insert(unpreferedCards, card:getId()) end
		end
	end
	local use_cards = {}
	for index = #unpreferedCards, 1, -1 do
		if not self.player:isJilei(sgs.Sanguosha:getCard(unpreferedCards[index])) then table.insert(use_cards, unpreferedCards[index]) end
	end
	if #use_cards == 0 then return end

	-- to friends
	self:sort(self.friends_noself, "defense")
	for _, friend in ipairs(self.friends_noself) do
		if not self:toTurnOver(friend, #use_cards) then
			use.card = sgs.Card_Parse("@JunxingCard=" .. table.concat(use_cards, "+"))
			if use.to then use.to:append(friend) end
			return
		end
	end
	if #use_cards >= 3 then
		for _, friend in ipairs(self.friends_noself) do
			if friend:getHandcardNum() <= 1 and not self:needKongcheng(friend) then
				use.card = sgs.Card_Parse("@JunxingCard=" .. table.concat(use_cards, "+"))
				if use.to then use.to:append(friend) end
				return
			end
		end
	end

	-- to enemies
	local basic, trick, equip
	for _, id in ipairs(use_cards) do
		local typeid = sgs.Sanguosha:getEngineCard(id):getTypeId()
		if not basic and typeid == sgs.Card_TypeBasic then basic = id
		elseif not trick and typeid == sgs.Card_TypeTrick then trick = id
		elseif not equip and typeid == sgs.Card_TypeEquip then equip = id
		end
		if basic and trick and equip then break end
	end
	self:sort(self.enemies, "handcards")
	local other_enemy
	for _, enemy in ipairs(self.enemies) do
		local id = nil
		if self:toTurnOver(enemy, 1) then
			if getKnownCard(enemy, "BasicCard") == 0 then id = equip or trick end
			if not id and getKnownCard(enemy, "TrickCard") == 0 then id = equip or basic end
			if not id and getKnownCard(enemy, "EquipCard") == 0 then id = trick or basic end
			if id then
				use.card = sgs.Card_Parse("@JunxingCard=" .. id)
				if use.to then use.to:append(enemy) end
				return
			elseif not other_enemy then
				other_enemy = enemy
			end
		end
	end
	if other_enemy then
		use.card = sgs.Card_Parse("@JunxingCard=" .. use_cards[1])
		if use.to then use.to:append(other_enemy) end
		return
	end
end

sgs.ai_use_priority.JunxingCard = 1.2
sgs.ai_card_intention.JunxingCard = function(self, card, from, tos)
	local to = tos[1]
	if not to:faceUp() then
		sgs.updateIntention(from, to, -80)
	else
		if to:getHandcardNum() <= 1 and card:subcardsLength() >= 3 then
			sgs.updateIntention(from, to, -40)
		else
			sgs.updateIntention(from, to, 80)
		end
	end
end

sgs.ai_skill_cardask["@junxing-discard"] = function(self, data, pattern)
	local manchong = self.room:findPlayerBySkillName("junxing")
	if manchong and self:isFriend(manchong) then return "." end

	local types = pattern:split("|")[1]:split(",")
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByKeepValue(cards)
	for _, card in ipairs(cards) do
		if not self:isValuableCard(card) then
			for _, classname in ipairs(types) do
				if card:isKindOf(classname) then return "$" .. card:getEffectiveId() end
			end
		end
	end
	return "."
end

sgs.ai_skill_cardask["@yuce-show"] = function(self, data)
	local damage = self.room:getTag("CurrentDamageStruct"):toDamage()
	if not damage.from or damage.from:isDead() then return "." end
	if self:isFriend(damage.from) then return "$" .. self.player:handCards():first() end
	local flag = string.format("%s_%s_%s", "visible", self.player:objectName(), damage.from:objectName())
	local types = { sgs.Card_TypeBasic, sgs.Card_TypeEquip, sgs.Card_TypeTrick }
	for _, card in sgs.qlist(damage.from:getHandcards()) do
		if card:hasFlag("visible") or card:hasFlag(flag) then
			table.removeOne(types, card:getTypeId())
		end
		if #types == 0 then break end
	end
	if #types == 0 then types = { sgs.Card_TypeBasic } end
	for _, card in sgs.qlist(self.player:getHandcards()) do
		for _, cardtype in ipairs(types) do
			if card:getTypeId() == cardtype then return "$" .. card:getEffectiveId() end
		end
	end
	return "$" .. self.player:handCards():first()
end

sgs.ai_skill_cardask["@yuce-discard"] = function(self, data, pattern, target)
	if target and self:isFriend(target) then return "." end
	local types = pattern:split("|")[1]:split(",")
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards)
	for _, card in ipairs(cards) do
		if not self:isValuableCard(card) then
			for _, classname in ipairs(types) do
				if card:isKindOf(classname) then return "$" .. card:getEffectiveId() end
			end
		end
	end
	return "."
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
				if self:getKeepValue(c) < 8 and not self.player:isJilei(c) and not self:isValuableCard(c) then return "$" .. c:getEffectiveId() end
			end
			if offhorse_avail and not self.player:isJilei(self.player:getOffensiveHorse()) then return "$" .. self.player:getOffensiveHorse():getEffectiveId() end
			if weapon_avail and not self.player:isJilei(self.player:getWeapon()) and self:evaluateWeapon(self.player:getWeapon()) < 5 then return "$" .. self.player:getWeapon():getEffectiveId() end
		else
			local slashc
			local cards = sgs.QList2Table(self.player:getHandcards())
			self:sortByUseValue(cards)
			for _, c in ipairs(cards) do
				if self:getUseValue(c) < 6 and not self:isValuableCard(c) and not self.player:isJilei(c) then
					if isCard("Slash", c, self.player) then
						if not slashc then slashc = c end
					else
						return "$" .. c:getEffectiveId()
					end
				end
			end
			if offhorse_avail and not self.player:isJilei(self.player:getOffensiveHorse()) then return "$" .. self.player:getOffensiveHorse():getEffectiveId() end
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

sgs.ai_skill_invoke.zongshih = function(self, data)
	return not self:needKongcheng(self.player, true)
end

sgs.ai_skill_cardask["@duodao-get"] = function(self, data)
	local function getLeastValueCard(from)
		if self:needToThrowArmor() then return "$" .. self.player:getArmor():getEffectiveId() end
		local cards = sgs.QList2Table(self.player:getHandcards())
		self:sortByKeepValue(cards)
		for _, c in ipairs(cards) do
			if self:getKeepValue(c) < 8 and not self.player:isJilei(c) and not self:isValuableCard(c) then return "$" .. c:getEffectiveId() end
		end
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
		if offhorse_avail and not self.player:isJilei(self.player:getOffensiveHorse()) then return "$" .. self.player:getOffensiveHorse():getEffectiveId() end
		if weapon_avail and not self.player:isJilei(self.player:getWeapon()) and self:evaluateWeapon(self.player:getWeapon()) < self:evaluateWeapon(from:getWeapon()) then
			return "$" .. self.player:getWeapon():getEffectiveId()
		end
	end
	local damage = data:toDamage()
	if not damage.from or not damage.from:getWeapon() then
		if self:needToThrowArmor() then
			return "$" .. self.player:getArmor():getEffectiveId()
		elseif self.player:getHandcardNum() == 1 and (self.player:hasSkill("kongcheng") or (self.player:hasSkill("zhiji") and self.player:getMark("zhiji") == 0)) then
			return "$" .. self.player:handCards():first()
		end
	else
		if self:isFriend(damage.from) then
			if damage.from:hasSkills("kofxiaoji|xiaoji") and self:isWeak(damage.from) then
				local str = getLeastValueCard(damage.from)
				if str then return str end
			else
				if self:getCardsNum("Slash") == 0 or self:willSkipPlayPhase() then return "." end
				local invoke = false
				local range = sgs.weapon_range[damage.from:getWeapon():getClassName()] or 0
				if self.player:hasSkill("anjian") then
					for _, enemy in ipairs(self.enemies) do
						if not enemy:inMyAttackRange(self.player) and not self.player:inMyAttackRange(enemy) and self.player:distanceTo(enemy) <= range then
							invoke = true
							break
						end
					end
				end
				if not invoke and self:evaluateWeapon(damage.from:getWeapon()) > 8 then invoke = true end
				if invoke then
					local str = getLeastValueCard(damage.from)
					if str then return str end
				end
			end
		else
			if damage.from:hasSkill("nosxuanfeng") then
				for _, friend in ipairs(self.friends) do
					if self:isWeak(friend) then return "." end
				end
			else
				if self.player:hasSkill("manjuan") and self.player:getPhase() == sgs.Player_NotActive then
					if self:needToThrowArmor() and not self.player:isJilei(self.player:getArmor()) then
						return "$" .. self.player:getArmor():getEffectiveId()
					elseif self.player:getHandcardNum() == 1
							and (self.player:hasSkill("kongcheng") or (self.player:hasSkill("zhiji") and self.player:getMark("zhiji") == 0))
							and not self.player:isJilei(self.player:getHandcards():first()) then
						return "$" .. self.player:handCards():first()
					end
				else
					local str = getLeastValueCard(damage.from)
					if str then return str end
				end
			end
		end
	end
	return "."
end

sgs.ai_skill_invoke.danshou = function(self, data)
	local damage = data:toDamage()
	local phase = self.player:getPhase()
	if phase < sgs.Player_Play then
		return self:willSkipPlayPhase()
	elseif phase == sgs.Player_Play then
		if self:getOverflow() >= 2 then
			return true
		else
			if damage.chain or self.room:getTag("is_chained"):toInt() > 0 then
				local nextp
				for _, p in sgs.qlist(self.room:getAllPlayers()) do
					if p:isChained() and self:damageIsEffective(p, damage.nature, self.player) then
						nextp = p
						break
					end
				end
				if not nextp or self:isFriend(nextp) then return true else return false end
			end
			if damage.card and damage.card:isKindOf("Slash") and self:getCardsNum("Slash") >= 1 and self:slashIsAvailable() then
				return false
			end
			if (damage.card and damage.card:isKindOf("AOE")) or (self.player:hasFlag("ShenfenUsing") and self.player:faceUp()) then
				if damage.to:getNextAlive():objectName() == self.player:objectName() then return true
				else
					local dmg_val = 0
					local p = damage.to
					repeat
						if self:damageIsEffective(p, damage.nature, self.player) then
							if self:isFriend(p) then
								dmg_val = dmg_val + 1
							else
								if self:cantbeHurt(p, self.player, damage.damage) then dmg_val = dmg_val + 1 end
								if self:getDamagedEffects(p, self.player) then dmg_val = dmg_val + 0.5 end
								if self:isEnemy(p) then dmg_val = dmg_val - 1 end
							end
						end
						p = p:getNextAlive()
					until p:objectName() == self.player:objectName()
					return dmg_val >= 1.5
				end
			end
			if damage.to:hasSkills(sgs.masochism_skill .. "|zhichi|zhiyu|fenyong") then return self:isEnemy(damage.to) end
			return true
		end
	elseif phase > sgs.Player_Play and phase ~= sgs.Player_NotActive then
		return true
	elseif phase == sgs.Player_NotActive then
		local current = self.room:getCurrent()
		if not current or not current:isAlive() or current:getPhase() == sgs.Player_NotActive() then return true end
		if self:isFriend(current) then
			return self:getOverflow(current) >= 2
		else
			if self:getOverflow(current) <= 2 then
				return true
			else
				local threat = getCardsNum("Duel", current) + getCardsNum("AOE", current)
				if self:slashIsAvailable(current) and getCardsNum("Slash", current) > 0 then threat = threat + math.min(1, getCardsNum("Slash", current)) end
				return threat >= 1
			end
		end
	end
	return false
end

sgs.ai_skill_invoke.juece = function(self, data)
	local move = data:toMoveOneTime()
	if not move.from then return false end
	local from = findPlayerByObjectName(self.room, move.from:objectName())
	return from and self:canAttack(from)
end

sgs.ai_skill_playerchosen.mieji = function(self, targets) -- extra target for Ex Nihilo
	return self:findPlayerToDraw(false, 2)
end

sgs.ai_playerchosen_intention.mieji = -50

sgs.ai_skill_use["@@mieji"] = function(self, prompt) -- extra target for Collateral
	local collateral = sgs.Sanguosha:cloneCard("collateral", sgs.Card_NoSuitBlack)
	local dummy_use = { isDummy = true, to = sgs.SPlayerList(), current_targets = {} }
	dummy_use.current_targets = self.player:property("extra_collateral_current_targets"):toString():split("+")
	self:useCardCollateral(collateral, dummy_use)
	if dummy_use.card and dummy_use.to:length() == 2 then
		local first = dummy_use.to:at(0):objectName()
		local second = dummy_use.to:at(1):objectName()
		return "@ExtraCollateralCard=.->" .. first .. "+" .. second
	end
end

sgs.ai_card_intention.ExtraCollateralCard = 0

sgs.ai_skill_invoke.zhuikong = function(self, data)
	if self.player:getHandcardNum() <= (self:isWeak() and 3 or 1) then return false end
	local current = self.room:getCurrent()
	if not current or self:isFriend(current) then return false end

	local max_card = self:getMaxCard()
	local max_point = max_card:getNumber()
	if not (current:hasSkill("zhiji") and current:getMark("zhiji") == 0 and current:getHandcardNum() == 1) then
		local enemy_max_card = self:getMaxCard(current)
		local enemy_max_point = enemy_max_card and enemy_max_card:getNumber() or 100
		if max_point > enemy_max_point or max_point > 10 then
			self.zhuikong_card = max_card:getEffectiveId()
			return true
		end
	end
	if current:distanceTo(self.player) == 1 and not self:isValuableCard(max_card) then
		self.zhuikong_card = max_card:getEffectiveId()
		return true
	end
	return false
end

sgs.ai_skill_playerchosen.qiuyuan = function(self, targets)
	local targetlist = sgs.QList2Table(targets)
	self:sort(targetlist, "handcard")
	local enemy
	for _, p in ipairs(targetlist) do
		if self:isEnemy(p) and not (p:getHandcardNum() == 1 and (p:hasSkill("kongcheng") or (p:hasSkill("zhiji") and p:getMark("zhiji") == 0))) then
			if p:hasSkills(sgs.cardneed_skill) then return p
			elseif not enemy and not enemy:canLiuli(enemy, self.friends_noself) then enemy = p end
		end
	end
	targetlist = sgs.reverse(targetlist)
	local friend
	for _, p in ipairs(targetlist) do
		if self:isFriend(p) then
			if (p:hasSkill("kongcheng") and p:getHandcardNum() == 1) or (p:getCardCount(true) >= 2 and self:canLiuli(p, self.enemies)) then return p
			elseif not friend and getCardsNum("Jink", friend) >= 1 then friend = p end
		end
	end
	return friend
end

sgs.ai_skill_cardask["@qiuyuan-give"] = function(self, data, pattern, target)
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByKeepValue(cards)
	for _, card in ipairs(cards) do
		local e_card = sgs.Sanguosha:getEngineCard(card:getEffectiveId())
		if e_card:isKindOf("Jink")
			and not (target and target:isAlive() and target:hasSkill("wushen") and (e_card:getSuit() == sgs.Card_Heart or (target:hasSkill("hongyan") and e_card:getSuit() == sgs.Card_Spade))) then
			return "$" .. card:getEffectiveId()
		end
	end
	for _, card in ipairs(cards) do
		if not self:isValuableCard(card) and self:getKeepValue(card) < 5 then return "$" .. card:getEffectiveId() end
	end
	return "$" .. cards[1]:getEffectiveId()
end

function sgs.ai_slash_prohibit.qiuyuan(self, from, to)
	if self:isFriend(to, from) then return false end
	if from:hasFlag("NosJiefanUsed") then return false end
	for _, friend in ipairs(self:getFriendsNoself(from)) do
		if not to:isKongcheng() and not (to:getHandcardNum() == 1 and (to:hasSkill("kongcheng") or (to:hasSkill("zhiji") and to:getMark("zhiji") == 0))) then return true end
	end
end