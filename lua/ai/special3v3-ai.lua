sgs.ai_skill_cardask["@huanshi-card"] = function(self, data)
	local judge = data:toJudge()

	if self:needRetrial(judge) then
		local cards = sgs.QList2Table(self.player:getCards("he"))
		local card_id = self:getRetrialCardId(cards, judge)
		if card_id ~= -1 then
			return "$" .. card_id
		end
	end

	return "."
end

sgs.ai_skill_invoke.huanshi = true

sgs.ai_skill_choice.huanshi = function(self, choices)
	local zhugejin = self.room:findPlayerBySkillName("huanshi")
	if self:objectiveLevel(zhugejin) > 2 then return "reject" end
	return "accept"
end

function sgs.ai_cardneed.huanshi(to, card, self)
	for _, player in ipairs(self.friends) do
		if self:getFinalRetrial(to) == 1 then
			if self:willSkipDrawPhase(player) then
				return card:getSuit() == sgs.Card_Club and not self:hasSuit("club", true, to)
			end
			if self:willSkipPlayPhase(player) then
				return card:getSuit() == sgs.Card_Heart and not self:hasSuit("heart", true, to)
			end
		end
	end
end

sgs.ai_skill_invoke.hongyuan = function(self, data)
	local count = 0
	for i = 1, #self.friends_noself do
		if self:needKongcheng(self.friends_noself[i]) and self.friends_noself[i]:getHandcardNum() == 0
			or self.friends_noself[i]:hasSkill("manjuan") then
		else
			count = count + 1
		end
		if count == 2 then return true end
	end
	return false
end

function sgs.ai_cardneed.mingzhe(to, card, self)
	return card:isRed() and getKnownCard(to, "red", false) < 2
end

sgs.ai_skill_use["@@hongyuan"] = function(self, prompt)
	self:sort(self.friends_noself, "handcard")
	local first_index, second_index
	for i = 1, #self.friends_noself do
		if self:needKongcheng(self.friends_noself[i]) and self.friends_noself[i]:getHandcardNum() == 0
			or self.friends_noself[i]:hasSkill("manjuan") then
		else
			if not first_index then
				first_index = i
			else
				second_index = i
			end
		end
		if second_index then break end
	end

	if first_index and not second_index then
		local others = self.room:getOtherPlayers(self.player)
		for _, other in sgs.qlist(others) do
			if (not self:isFriend(other) and (self:needKongcheng(other) and others:getHandcardNum() == 0 or other:hasSkill("manjuan"))) and
				self.friends_noself[first_index]:objectName() ~= other:objectName() then
				return ("@HongyuanCard=.->%s+%s"):format(self.friends_noself[first_index]:objectName(), other:objectName())
			end
		end
	end

	if not second_index then return "." end

	self:log(self.friends_noself[first_index]:getGeneralName() .. "+" .. self.friends_noself[second_index]:getGeneralName())
	local first = self.friends_noself[first_index]:objectName()
	local second = self.friends_noself[second_index]:objectName()
	return ("@HongyuanCard=.->%s+%s"):format(first, second)
end

sgs.ai_card_intention.HongyuanCard = -70

sgs.huanshi_suit_value = {
	heart = 3.9,
	diamond = 3.4,
	club = 3.9,
	spade = 3.5
}

sgs.mingzhe_suit_value = {
	heart = 4.0,
	diamond = 4.0
}

sgs.ai_skill_playerchosen.vsganglie = function(self, targets)
	self:sort(self.enemies)
	local prior_enemies = {}
	for _, enemy in ipairs(self.enemies) do
		if enemy:getHandcardNum() < 2 then table.insert(prior_enemies, enemy) end
	end
	for _, enemy in ipairs(prior_enemies) do
		if self:canAttack(enemy) then return enemy end
	end
	for _, enemy in ipairs(self.enemies) do
		if self:canAttack(enemy) or enemy:getHandcardNum() > 3 then return enemy end
	end
	for _, friend in ipairs(self.friends_noself) do
		if self:damageIsEffective(friend, sgs.DamageStruct_Normal, friend) and not self:cantBeHurt(friend) and self:getDamagedEffects(damage.from, self.player) then
			sgs.ai_ganglie_effect = string.format("%s_%s_%d", self.player:objectName(), friend:objectName(), sgs.turncount)
			return friend
		end
	end
	return nil
end

sgs.ai_playerchosen_intention.vsganglie = function(from, to)
	if sgs.ai_ganglie_effect and sgs.ai_ganglie_effect == string.format("%s_%s_%d", from:objectName(), to:objectName(), sgs.turncount) then
		sgs.updateIntention(from, to, -10)
	elseif from:getState() == "online" then
		if not from:hasSkill("jueqing") then
			for _, askill in sgs.qlist(to:getVisibleSkillList()) do
				local callback = sgs.ai_need_damaged[askill:objectName()]
				if type(callback) == "function" and callback(self, attacker) then return end
			end
		end
		sgs.updateIntention(from, to, 40)
	else
		sgs.updateIntention(from, to, 80)
	end
end

sgs.ai_need_damaged.vsganglie = function(self, attacker)
	for _, enemy in ipairs(self.enemies) do
		if self:isEnemy(enemy) and enemy:getHp() + enemy:getHandcardNum() <= 3
			and not (self:hasSkills(sgs.need_kongcheng .. "|buqu", enemy) and attacker:getHandcardNum() > 1) and sgs.isGoodTarget(enemy, self.enemies, self) then
			return true
		end
	end
	return false
end

sgs.ai_skill_discard.vsganglie = function(self, discard_num, min_num, optional, include_equip)
	return ganglie_discard(self, discard_num, min_num, optional, include_equip, "vsganglie")
end

function sgs.ai_slash_prohibit.vsganglie(self, from, to)
	if self:isFriend(from, to) then return false end
	if from:hasSkill("jueqing") or (from:hasSkill("nosqianxi") and from:distanceTo(to) == 1) then return false end
	if from:hasFlag("nosjiefanUsed") then return false end
	if #(self:getEnemies(from)) > 1 then
		for _, p in ipairs(self:getFriends(from)) do
			if p:getHandcardNum() + p:getHp() < 4 then return true end
		end
	end
	return false
end

sgs.ai_skill_invoke.zhongyi = function(self, data)
	local damage = data:toDamage()
	return self:isEnemy(damage.to)
end

function SmartAI:ableToSave(saver, dying)
	local current = self.room:getCurrent()
	if current and current:getPhase() ~= sgs.Player_NotActive and current:hasSkill("wansha")
		and current:objectName() ~= saver:objectName() and current:objectName() ~= dying:objectName() then
		return false
	end
	if saver:getMark("@qianxi_red") > 0 or saver:getMark("@jilei_basic") > 0 then return false end
	return true
end

sgs.ai_skill_cardask["@jiuzhu"] = function(self, data)
	local dying = data:toDying()
	if not self:isFriend(dying.who) then return "." end
	if dying.who:hasSkill("jiushi") and dying.who:faceUp() then return "." end
	if (self:getCardsNum("Peach") > 0 and self:ableToSave(self.player, dying.who)) or self.player:getPile("wine"):length() > 0 then return "." end
	for _, friend in ipairs(self.friends_noself) do
		if getKnownCard(friend, "Peach", true, "he") > 0 and self:ableToSave(friend, dying.who) then return "." end
	end
	local must_save = false
	if self.room:getMode() == "06_3v3" then
		if dying.who:getRole() == "renegade" or dying.who:getRole() == "lord" then must_save = true end
	elseif dying.who:isLord() and (self.role == "loyalist" or (self.role == "renegade" and room:alivePlayerCount() > 2)) then
		must_save = true
	end
	if not must_save and self:willUsePeachTo(dying.who) == "." then return "." end
	if not must_save and self:isWeak() and not self.player:hasArmorEffect("silver_lion") then return "." end

	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	local card_id
	local lightning = self:getCard("Lightning")

	if self:needToThrowArmor() then
		card_id = self.player:getArmor():getId()
	elseif lightning and not self:willUseLightning(lightning) then
		card_id = lightning:getEffectiveId()
	else
		for _, acard in ipairs(cards) do
			if (acard:isKindOf("BasicCard") or acard:isKindOf("EquipCard") or acard:isKindOf("AmazingGrace"))
				and not acard:isKindOf("Peach") then
				card_id = acard:getEffectiveId()
				break
			end
		end
	end
	if not card_id and not self.player:getEquips():isEmpty() then
		if self.player:getOffensiveHorse() then card_id = self.player:getOffensiveHorse():getId()
		elseif self.player:getDefensiveHorse() then card_id = self.player:getDefensiveHorse():getId()
		elseif self.player:getWeapon() then card_id = self.player:getWeapon():getId()
		end
	end
	if card_id then return "$" .. card_id else return "." end
end

sgs.ai_skill_invoke.zhanshen = function(self, data)
	local obj = data:toString():split(":")[2]
	local lvbu = self:findPlayerByObjectName(obj)
	return self:isFriend(obj)
end

sgs.weapon_range.VSCrossbow = sgs.weapon_range.Crossbow
sgs.ai_use_priority.VSCrossbow = sgs.ai_use_priority.Crossbow
