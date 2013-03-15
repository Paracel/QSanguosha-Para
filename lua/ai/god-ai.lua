wushen_skill = {}
wushen_skill.name = "wushen"
table.insert(sgs.ai_skills, wushen_skill)
wushen_skill.getTurnUseCard = function(self)
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)

	local red_card
	self:sortByUseValue(cards, true)

	for _, card in ipairs(cards) do
		if card:getSuit() == sgs.Card_Heart then
			red_card = card
			break
		end
	end

	if red_card then
		local suit = red_card:getSuitString()
		local number = red_card:getNumberString()
		local card_id = red_card:getEffectiveId()
		local card_str = ("slash:wushen[%s:%s]=%d"):format(suit, number, card_id)
		local slash = sgs.Card_Parse(card_str)

		assert(slash)
		return slash
	end
end

sgs.ai_skill_playerchosen.wuhun = function(self, targets)
	local targetlist = sgs.QList2Table(targets)
	local target
	local lord
	for _, player in ipairs(targetlist) do
		if player:isLord() then lord = player end
		if self:isEnemy(player) and (not target or target:getHp() < player:getHp()) then
			target = player
		end
	end
	if self.role == "rebel" and lord then return lord end
	if target then return target end
	self:sort(targetlist, "hp")
	if self.player:getRole() == "loyalist" and targetlist[1]:isLord() then return targetlist[2] end
	return targetlist[1]
end

function sgs.ai_slash_prohibit.wuhun(self, from, to)
	if from:hasSkill("jueqing") or (from:hasSkill("nosqianxi") and from:distanceTo(to) == 1) then return false end
	if from:hasFlag("nosjiefanUsed") then return false end
	local maxfriendmark = 0
	local maxenemymark = 0
	for _, friend in ipairs(self:getFriends(from)) do
		local friendmark = friend:getMark("@nightmare")
		if friendmark > maxfriendmark then maxfriendmark = friendmark end
	end
	for _, enemy in ipairs(self:getEnemies(from)) do
		local enemymark = enemy:getMark("@nightmare")
		if enemymark > maxenemymark and enemy:objectName() ~= to:objectName() then maxenemymark = enemymark end
	end
	if self:isEnemy(to, from) and not (to:isLord() and from:getRole() == "rebel") then
		if (maxfriendmark + 2 > maxenemymark) and not (#(self:getEnemies(from)) == 1 and #(self:getFriends(from)) + #(self:getEnemies(from)) == self.room:alivePlayerCount()) then
			if not (from:getMark("@nightmare") == maxfriendmark and from:getRole() == "loyalist") then
				return true
			end
		end
	end
end

function SmartAI:cantbeHurt(player, from)
	from = from or self.player
	if from:hasSkill("jueqing") then return false end
	local maxfriendmark = 0
	local maxenemymark = 0
	local dyingfriend = 0
	if player:hasSkill("wuhun") and #(self:getFriendsNoself(player)) > 0 then
		for _, friend in ipairs(self:getFriends(from)) do
			local friendmark = friend:getMark("@nightmare")
			if friendmark > maxfriendmark then maxfriendmark = friendmark end
		end
		for _, enemy in ipairs(self:getEnemies(from)) do
			local enemymark = enemy:getMark("@nightmare")
			if enemymark > maxenemymark and enemy:objectName() ~= player:objectName() then maxenemymark = enemymark end
		end
		if self:isEnemy(player, from) then
			if not (player:isLord() and from:getRole() == "rebel")
				and maxfriendmark + 2 > maxenemymark and not (#(self:getEnemies(from)) == 1 and #(self:getFriends(from)) + #(self:getEnemies(from)) == self.room:alivePlayerCount())
				and not (from:getMark("@nightmare") == maxfriendmark and from:getRole() == "loyalist") then
				return true
			end
		elseif maxfriendmark + 1 > maxenemymark then
			return true
		end
	elseif player:hasSkill("duanchang") then
		if player:getHp() > 1 or #(self:getEnemies(from)) == 1 then return false end
		if player:getHp() <= 1 then
			if from:getMaxHp() == 3 and from:getArmor() and from:getDefensiveHorse() then return false end
			if from:getMaxHp() <= 3 or (from:isLord() and self:isWeak(from)) then return true end
		end
	elseif player:hasSkill("tianxiang") then
		local peach_num = self.player:objectName() == from:objectName() and self:getCardsNum("Peach") or getCardsNum("Peach", from)
		for _, friend in ipairs(self:getFriends(from)) do
			if friend:getHp() < 2 and peach_num then
				dyingfriend = dyingfriend + 1
			end
		end
		if dyingfriend > 0 and player:getHandcardNum() > 0 then
			return true
		end
	end
	return false
end

function SmartAI:needDeath(player)
	local maxfriendmark = 0
	local maxenemymark = 0
	player = player or self.player
	if player:hasSkill("wuhun") and #(self:getFriendsNoself(player)) > 0 then
		for _, aplayer in sgs.qlist(self.room:getAlivePlayers()) do
			local mark = aplayer:getMark("@nightmare")
			if self:isFriend(player, aplayer) and player:objectName() ~= aplayer:objectName() then
				if mark > maxfriendmark then maxfriendmark = mark end
			end
			if self:isEnemy(player, aplayer) then
				if mark > maxenemymark then maxenemymark = mark end
			end
			if maxfriendmark > maxenemymark then return false
			elseif maxenemymark == 0 then return false
			else return true end
		end
	end
	return false
end

function SmartAI:doNotSave(player)
	if (player:hasSkill("niepan") and player:getMark("@nirvana") > 0 and player:getCards("e"):length() < 2)
		or (player:hasSkill("fuli") and player:getMark("@laoji") > 0 and player:getCards("e"):length() < 2) then
		return true
	end
	return false
end

sgs.ai_chaofeng.shenguanyu = -6

sgs.ai_skill_invoke.shelie = true

local gongxin_skill = {}
gongxin_skill.name = "gongxin"
table.insert(sgs.ai_skills, gongxin_skill)
gongxin_skill.getTurnUseCard = function(self)
		local card_str = ("@GongxinCard=.")
		local gongxin_card = sgs.Card_Parse(card_str)
		assert(gongxin_card)
		return gongxin_card
end

sgs.ai_skill_use_func.GongxinCard = function(card, use, self)
	if self.player:usedTimes("GongxinCard") > 0 then return end
	self:sort(self.enemies, "handcard")

	for index = #self.enemies, 1, -1 do
		if not self.enemies[index]:isKongcheng() and self:objectiveLevel(self.enemies[index]) > 0 then
			use.card = card
			if use.to then
				use.to:append(self.enemies[index])
			end
			return
		end
	end
end

-- @todo: move the AI of GongXin here

sgs.ai_use_value.GongxinCard = 8.5
sgs.ai_use_priority.GongxinCard = 9.5
sgs.ai_card_intention.GongxinCard = 80

sgs.ai_skill_invoke.qinyin = function(self, data)
	self:sort(self.friends, "hp")
	self:sort(self.enemies, "hp")
	local up = 0
	local down = 0

	for _, friend in ipairs(self.friends) do
		down = down - 10
		up = up + (friend:isWounded() and 10 or 0)
		if self:hasSkills(sgs.masochism_skill, friend) then
			down = down - 5
			up = up + 5
		end
		if friend:getHp() > getBestHp(friend) then
			down = down + 5
			up = up - 5
		end
		if self:isWeak(friend) then
			up = up + 10 + (friend:isLord() and 20 or 0)
			down = down - 10 - (friend:isLord() and 40 or 0)
			if friend:getHp() <= 1 and not friend:hasSkill("buqu") or friend:getPile("buqu"):length() > 4 then
				down = down - 20 - (friend:isLord() and 40 or 0)
			end
		end
	end

	for _, enemy in ipairs(self.enemies) do
		down = down + 10
		up = up - (enemy:isWounded() and 10 or 0)
		if self:hasSkills(sgs.masochism_skill, enemy) then 
			down = down + 10
			up = up - 15
		end
		if enemy:getHp() > getBestHp(enemy) then
			down = down - 5
		end
		if self:isWeak(enemy) then
			up = up - 10
			down = down + 10
			if enemy:getHp() <= 1 and not enemy:hasSkill("buqu") then
				down = down + 10 + ((enemy:isLord() and #self.enemies > 1) and 20 or 0)
			end
		end
	end

	if down > 0 then 
		sgs.ai_skill_choice.qinyin = "down"
		return true
	elseif up > 0 then
		sgs.ai_skill_choice.qinyin = "up"
		return true
	end
	return false
end

local yeyan_skill = {}
yeyan_skill.name = "yeyan"
table.insert(sgs.ai_skills, yeyan_skill)
yeyan_skill.getTurnUseCard = function(self)
	if self.player:getMark("@flame") == 0 then return end
	if self.player:getRole() == "lord" and (#self.enemies > 1 or sgs.turncount == 1) then return end
	if self.player:getHandcardNum() >= 4 then
		local spade, club, heart, diamond
		for _, card in sgs.qlist(self.player:getHandcards()) do
			if card:getSuit() == sgs.Card_Spade then spade = true
			elseif card:getSuit() == sgs.Card_Club then club = true
			elseif card:getSuit() == sgs.Card_Heart then heart = true
			elseif card:getSuit() == sgs.Card_Diamond then diamond = true
			end
		end
		if spade and club and diamond and heart then
			self:sort(self.enemies, "hp")
			local target_num = 0
			for _, enemy in ipairs(self.enemies) do
				if enemy:hasArmorEffect("vine") or (enemy:isChained() and self:isGoodChainTarget(enemy)) then
					target_num = target_num + 1
				elseif enemy:getHp() <= 3 then
					target_num = target_num + 1
				end
			end

			if target_num >= 1 then
				return sgs.Card_Parse("@GreatYeyanCard=.")
			end
		end
	end

	self.yeyanchained = false
	if self.player:getHp() + self:getCardsNum("Peach") + self:getCardsNum("Analeptic") <= 2 then
		return sgs.Card_Parse("@SmallYeyanCard=.")
	end
	local target_num = 0
	local chained = 0
	for _, enemy in ipairs(self.enemies) do
		if (enemy:hasArmorEffect("vine") or enemy:getHp() <= 1)
			and not (self.role == "renegade" and enemy:isLord()) then
			target_num = target_num + 1
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if enemy:isChained() and self:isGoodChainTarget(enemy) then
			if chained == 0 then target_num = target_num + 1 end
			chained = chained + 1
		end
	end
	self.yeyanchained = (chained > 1)
	if target_num > 2 or (target_num > 1 and self.yeyanchained)
		or (#self.enemies + 1 == self.room:alivePlayerCount() and self.room:alivePlayerCount() < sgs.Sanguosha:getPlayerCount(self.room:getMode())) then
		return sgs.Card_Parse("@SmallYeyanCard=.")
	end
end

sgs.ai_skill_use_func.GreatYeyanCard = function(card, use, self)
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards, true)
	local need_cards = {}
	local spade, club, heart, diamond
	for _, card in ipairs(cards) do
		if card:getSuit() == sgs.Card_Spade and not spade then spade = true table.insert(need_cards, card:getId())
		elseif card:getSuit() == sgs.Card_Club and not club then club = true table.insert(need_cards, card:getId())
		elseif card:getSuit() == sgs.Card_Heart and not heart then heart = true table.insert(need_cards, card:getId())
		elseif card:getSuit() == sgs.Card_Diamond and not diamond then diamond = true table.insert(need_cards, card:getId())
		end
	end
	if #need_cards < 4 then return end
	local greatyeyan = sgs.Card_Parse("@GreatYeyanCard=" .. table.concat(need_cards, "+"))
	assert(greatyeyan)

	self:sort(self.enemies, "hp")
	for _, enemy in ipairs(self.enemies) do
		if not enemy:hasArmorEffect("silver_lion")
			and not (enemy:hasSkill("tianxiang") and enemy:getHandcardNum() > 0)
			and self:objectiveLevel(enemy) > 3 and self:damageIsEffective(enemy, sgs.DamageStruct_Fire) then
				if enemy:isChained() and self:isGoodChainTarget(enemy) then
					if enemy:getArmor() and enemy:getArmor():objectName() == "vine" then
						use.card = greatyeyan
						if use.to then
							use.to:append(enemy)
							use.to:append(enemy)
							use.to:append(enemy)
						end
						return
					end
				end
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if not enemy:hasArmorEffect("silver_lion")
			and not (enemy:hasSkill("tianxiang") and enemy:getHandcardNum() > 0)
			and self:objectiveLevel(enemy) > 3 and self:damageIsEffective(enemy, sgs.DamageStruct_Fire) then
				if enemy:isChained() and self:isGoodChainTarget(enemy) then
					use.card = greatyeyan
					if use.to then
						use.to:append(enemy)
						use.to:append(enemy)
						use.to:append(enemy)
					end
					return
				end
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if not enemy:hasArmorEffect("silver_lion")
			and not (enemy:hasSkill("tianxiang") and enemy:getHandcardNum() > 0)
			and self:objectiveLevel(enemy) > 3 and self:damageIsEffective(enemy, sgs.DamageStruct_Fire) then
				if not enemy:isChained() then
					if enemy:getArmor() and enemy:getArmor():objectName() == "vine" then
						use.card = greatyeyan
						if use.to then
							use.to:append(enemy)
							use.to:append(enemy)
							use.to:append(enemy)
						end
						return
					end
				end
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if not enemy:hasArmorEffect("silver_lion")
			and not (enemy:hasSkill("tianxiang") and enemy:getHandcardNum() > 0)
			and self:objectiveLevel(enemy) > 3 and self:damageIsEffective(enemy, sgs.DamageStruct_Fire) then
				if not enemy:isChained() then
					use.card = greatyeyan
					if use.to then
						use.to:append(enemy)
						use.to:append(enemy)
						use.to:append(enemy)
					end
					return
				end
		end
	end
end

sgs.ai_use_value.GreatYeyanCard = 8
sgs.ai_use_priority.GreatYeyanCard = 9

sgs.ai_card_intention.GreatYeyanCard = 200

sgs.ai_skill_use_func.SmallYeyanCard = function(card, use, self)
	local num = 0
	self:sort(self.enemies, "hp")
	for _, enemy in ipairs(self.enemies) do
		if not (enemy:hasSkill("tianxiang") and enemy:getHandcardNum() > 0) and self:damageIsEffective(enemy, sgs.DamageStruct_Fire) then
			if enemy:isChained() and self:isGoodChainTarget(enemy) then
				if enemy:hasArmorEffect("vine") then
					if use.to then use.to:append(enemy) end
					num = num + 1
					if num >= 3 then break end
				end
			end
		end
	end
	if num < 3 then
		for _, enemy in ipairs(self.enemies) do
			if not (enemy:hasSkill("tianxiang") and enemy:getHandcardNum() > 0) and self:damageIsEffective(enemy, sgs.DamageStruct_Fire) then
				if enemy:isChained() and self:isGoodChainTarget(enemy) and not enemy:hasArmorEffect("vine") then
					if use.to then use.to:append(enemy) end
					num = num + 1
					if num >= 3 then break end
				end
			end
		end
	end
	if num < 3 then
		for _, enemy in ipairs(self.enemies) do
			if not (enemy:hasSkill("tianxiang") and enemy:getHandcardNum() > 0) and self:damageIsEffective(enemy, sgs.DamageStruct_Fire) then
				if not enemy:isChained() then
					if enemy:hasArmorEffect("vine") then
						if use.to then use.to:append(enemy) end
						num = num + 1
						if num >= 3 then break end
					end
				end
			end
		end
	end
	if num < 3 then
		for _, enemy in ipairs(self.enemies) do
			if not (enemy:hasSkill("tianxiang") and enemy:getHandcardNum() > 0) and self:damageIsEffective(enemy, sgs.DamageStruct_Fire) then
				if not enemy:isChained() and not enemy:hasArmorEffect("vine") then
					if use.to then use.to:append(enemy) end
					num = num + 1
					if num >= 3 then break end
				end
			end
		end
	end
	if num > 0 then use.card = card end
end

sgs.ai_card_intention.SmallYeyanCard = 80
sgs.ai_use_priority.SmallYeyanCard = 2.3

sgs.ai_skill_askforag.qixing = function(self, card_ids)
	local cards = {}
	for _, card_id in ipairs(card_ids) do
		table.insert(cards, sgs.Sanguosha:getCard(card_id))
	end
	self:sortByCardNeed(cards)
	if self.player:getPhase() == sgs.Player_Draw then
		return cards[#cards]:getEffectiveId()
	end
	if self.player:getPhase() == sgs.Player_Finish then
		return cards[1]:getEffectiveId()
	end
	return -1
end

sgs.ai_skill_use["@@kuangfeng"] = function(self, prompt)
	local friendly_fire
	for _, friend in ipairs(self.friends) do
		if friend:hasSkill("huoji") or friend:hasWeapon("fan") or (friend:hasSkill("yeyan") and friend:getMark("@flame") > 0) then
			friendly_fire = true
			break
		end
	end

	local is_chained = 0
	local target = {}
	for _, enemy in ipairs(self.enemies) do
		if enemy:isChained() then
			is_chained = is_chained + 1
			table.insert(target, enemy)
		end
		if enemy:getArmor() and enemy:getArmor():objectName() == "vine" then
			table.insert(target, 1, enemy)
			break
		end
	end
	local usecard = false
	if friendly_fire and is_chained > 1 then usecard = true end
	self:sort(self.friends, "hp")
	if target[1] and not self:isWeak(self.friends[1]) then
		if target[1]:hasArmorEffect("vine") and friendly_fire then usecard = true end
	end
	if usecard then
		if not target[1] then table.insert(target, self.enemies[1]) end
		if target[1] then return "@KuangfengCard=.->" .. target[1]:objectName() else return "." end
	else
		return "."
	end
end

sgs.ai_card_intention.KuangfengCard = 80

sgs.ai_skill_use["@@dawu"] = function(self, prompt)
	self:sort(self.friends_noself, "hp")
	local targets = {}
	local lord = self.room:getLord()
	self:sort(self.friends_noself, "defense")
	if lord and self:isFriend(lord) and not sgs.isLordHealthy() and not self.player:isLord() and not lord:hasSkill("buqu") then
		table.insert(targets, lord:objectName())
	else
		for _, friend in ipairs(self.friends_noself) do
			if self:isWeak(friend) and not friend:hasSkill("buqu") then table.insert(targets, friend:objectName()) break end
		end
	end
	if self.player:getPile("stars"):length() > #targets and self:isWeak() then table.insert(targets, self.player:objectName()) end
	if #targets > 0 then return "@DawuCard=.->" .. table.concat(targets, "+") end
	return "."
end

sgs.ai_card_intention.DawuCard = -70

sgs.ai_skill_invoke.guixin = function(self, data)
	local damage = data:toDamage()
	if self.player:hasSkill("manjuan") and self.player:getPhase() == sgs.Player_NotActive then return false end
	local diaochan = self.room:findPlayerBySkillName("lihun")
	if diaochan and self:isEnemy(diaochan) and self.room:alivePlayerCount() > 5 then return false end
	return self.room:alivePlayerCount() > 2 or damage.damage > 1
end

sgs.ai_need_damaged.guixin = function (self, attacker)
	if self.room:alivePlayerCount() <= 3 then return false end
	local diaochan = self.room:findPlayerBySkillName("lihun")
	if diaochan and self:isEnemy(diaochan) then return false end
	local num = self.player:getHandcardNum()
	if self.player:faceUp() and num - self.player:getHp() > 2 then return false end
	return true
end

sgs.ai_chaofeng.shencaocao = -6

sgs.ai_skill_choice.wumou = function(self, choices)
	if self.player:getMark("@wrath") > 6 then return "discard" end
	if self.player:getHp() + self:getCardsNum("Peach") > 3 then
		return "losehp"
	else
		return "discard"
	end
end

local wuqian_skill = {}
wuqian_skill.name = "wuqian"
table.insert(sgs.ai_skills, wuqian_skill)
wuqian_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("WuqianCard") or self.player:getMark("@wrath") < 2 then return end

	local card_str = ("@WuqianCard=.")
	self:sort(self.enemies, "hp")
	local has_enemy
	for _, enemy in ipairs(self.enemies) do
		if enemy:getHp() <= 2 and getCardsNum("Jink", enemy) < 2 and self.player:distanceTo(enemy) <= self.player:getAttackRange() then
			has_enemy = enemy
			break
		end
	end

	if has_enemy and self:getCardsNum("Slash") > 0 then
		for _, card in sgs.qlist(self.player:getHandcards()) do
			if isCard("Slash", card, self.player) then
				local slash = card:isKindOf("Slash") and card or sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber())
				if self:slashIsEffective(slash, has_enemy) and self.player:canSlash(has_enemy, slash)
					and (self:getCardsNum("Analeptic") > 0 or has_enemy:getHp() <= 1) and slash:isAvailable(self.player) then
					return sgs.Card_Parse(card_str)
				end
			elseif isCard("Duel", card, self.player) then
				local dummy_use = { isDummy = true }
				local duel = sgs.Sanguosha:cloneCard("duel", card:getSuit(), card:getNumber())
				self:useCardDuel(duel, dummy_use)
				if dummy_use.card then return sgs.Card_Parse(card_str) end
			end
		end
	end
end

sgs.ai_skill_use_func.WuqianCard = function(card, use, self)
	self:sort(self.enemies, "hp")
	for _, enemy in ipairs(self.enemies) do
		if enemy:getHp() <= 2 and getCardsNum("Jink", enemy) < 2 and self.player:inMyAttackRange(enemy) then
			if (not enemy:getArmor() or enemy:hasArmorEffect("silver_lion")) and getCardsNum("Jink", enemy) < 1 then
			else
				if use.to then
					use.to:append(enemy)
				end
				use.card = card
				return
			end
		end
	end
end

sgs.ai_card_intention.WuqianCard = 80
sgs.ai_use_priority.WuqianCard = 10

local shenfen_skill = {}
shenfen_skill.name = "shenfen"
table.insert(sgs.ai_skills, shenfen_skill)
shenfen_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("ShenfenCard") or self.player:getMark("@wrath") < 6 then return end
	return sgs.Card_Parse("@ShenfenCard=.")
end

function SmartAI:getSaveNum(isFriend)
	local num = 0
	for _, player in sgs.qlist(self.room:getAllPlayers()) do
		if (isFriend and self:isFriend(player)) or (not isFriend and self:isEnemy(player)) then
			if not self.player:hasSkill("wansha") or player:objectName() == self.player:objectName() then
				if player:hasSkill("jijiu") then
					num = num + self:getSuitNum("heart", true, player)
					num = num + self:getSuitNum("diamond", true, player)
					num = num + player:getHandcardNum() * 0.4
				end
				if player:hasSkill("nosjiefan") and getCardsNum("Slash", player) > 0 then
					if self:isFriend(player) or self:getCardsNum("Jink") == 0 then num = num + getCardsNum("Slash", player) end
				end
				num = num + getCardsNum("Peach", player)
			end
			if player:hasSkill("buyi") and not player:isKongcheng() then num = num + 0.3 end
			if player:hasSkill("chunlao") and not player:getPile("wine"):isEmpty() then num = num + player:getPile("wine"):length() end
		end
	end
	return num
end

function SmartAI:canSaveSelf(player)
	if player:hasSkill("buqu") and player:getPile("buqu"):length() < 5 then return true end
	if getCardsNum("Analeptic", player) > 0 then return true end
	if player:hasSkill("jiushi") and player:faceUp() then return true end
	if player:hasSkill("jiuchi") then
		for _, c in sgs.qlist(player:getHandcards()) do
			if c:getSuit() == sgs.Card_Spade then return true end
		end
	end
	return false
end

local function getShenfenUseValueOf_HE_Cards(self, to)
	local value = 0
	-- value of handcards
	local value_h = 0
	local hcard = to:getHandcardNum()
	if to:hasSkill("lianying") then
		hcard = hcard - 0.9
	elseif self:hasSkills("shangshi|nosshangshi", to) then
		hcard = hcard - 0.9 * to:getLostHp()
	end
	value_h = (hcard > 4) and 16 / hcard or hcard
	if to:hasSkill("tuntian") then value = value * 0.95 end
	if (to:hasSkill("kongcheng") or (to:hasSkill("zhiji") and to:getHp() > 2 and to:getMark("zhiji") == 0)) and not to:isKongcheng() then value_h = value_h * 0.7 end
	if self:hasSkills("jijiu|qingnang|leiji|jieyin|beige|kanpo|liuli|qiaobian|zhiheng|guidao|longhun|xuanfeng|tianxiang|lijian", to) then value_h = value_h * 0.95 end
	value = value + value_h

	-- value of equips
	local value_e = 0
	local equip_num = to:getEquips():length()
	if to:hasArmorEffect("silver_lion") and to:isWounded() then equip_num = equip_num - 1.1 end
	value_e = equip_num * 1.1
	if to:hasSkill("xiaoji") then value_e = value_e * 0.7 end
	if to:hasSkill("nosxuanfeng") then value_e = value_e * 0.85 end
	if self:hasSkills("bazhen|yizhong", to) and to:getArmor() then value_e = value_e - 1 end
	value = value + value_e

	return value
end

local function getDangerousShenGuanYu(self)
	local most = -100
	local target
	for _, player in sgs.qlist(self.room:getAllPlayers()) do
		local nm_mark = player:getMark("@nightmare")
		if player:objectName() == self.player:objectName() then nm_mark = nm_mark + 1 end
		if nm_mark > 0 and nm_mark > most or (nm_mark == most and self:isEnemy(player)) then
			most = nm_mark
			target = player
		end
	end
	if target and self:isEnemy(target) then return true end
	return false
end

sgs.ai_skill_use_func.ShenfenCard = function(card, use, self)
	if (self.role == "loyalist" or self.role == "renegade") and self.room:getLord() and self:isWeak(self.room:getLord()) and not self.player:isLord() then return end
	local benefit = 0
	for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if self:isFriend(player) then benefit = benefit - getShenfenUseValueOf_HE_Cards(self, player) end
		if self:isFriend(player) then benefit = benefit + getShenfenUseValueOf_HE_Cards(self, player) end
	end
	local friend_save_num = self:getSaveNum(true)
	local enemy_save_num = self:getSaveNum(false)
	local others = 0
	for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if self:damageIsEffective(player, sgs.DamageStruct_Normal) then
			others = others + 1
			local value_d = 3.5 / math.max(player:getHp(), 1)
			if player:getHp() <= 1 then
				if player:hasSkill("wuhun") then
					local can_use = getDangerousShenGuanYu(self)
					if not can_use then return else value_d = value_d * 0.1 end
				end
				if self:canSaveSelf(player) then
					value = value * 0.9
				elseif self:isFriend(player) and friend_save_num > 0 then
					friend_save_num = friend_save_num - 1
					value_d = value_d * 0.9
				elseif self:isEnemy(player) and enemy_save_num > 0 then
					enemy_save_num = enemy_save_num - 1
					value_d = value_d * 0.9
				end
			end
			if player:hasSkill("fankui") then value_d = value_d * 0.8 end
			if player:hasSkill("guixin") then
				if not player:faceUp() then
					value_d = value_d * 0.4
				else
					value_d = value_d * 0.8 * (1.05 - self.room:alivePlayerCount() / 15)
				end
			end
			if self:getDamagedEffects(player, self.player) or getBestHp(player) == player:getHp() - 1 then value_d = value_d * 0.8 end
			if self:isFriend(player) then benefit = benefit - value_d end
			if self:isEnemy(player) then benefit = benefit + value_d end
		end
	end
	if not self.player:faceUp() or self:hasSkills("jushou|neojushou|kuiwei", self.player) then
		benefit = benefit + 1
	else
		local help_friend = false
		for _, friend in ipairs(self.friends_noself) do
			if self:hasSkills("fangzhu|jilve", friend) then
				help_friend = true
				benefit = benefit + 1
				break
			end
		end
		if not help_friend then benefit = benefit - 0.5 end
	end
	if self.player:getKingdom() == "qun" then
		for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if player:hasLordSkill("baonue") and self:isFriend(player) then
				benefit = benefit + 0.2 * self.room:alivePlayerCount()
				break
			end
		end
	end
	benefit = benefit + (others - 7) * 0.05
	if benefit > 0 then
		use.card = card
	end
end

sgs.ai_use_value.ShenfenCard = 8
sgs.ai_use_priority.ShenfenCard = 5.3

sgs.dynamic_value.damage_card.ShenfenCard = true
sgs.dynamic_value.control_card.ShenfenCard = true

local longhun_skill = {}
longhun_skill.name = "longhun"
table.insert(sgs.ai_skills, longhun_skill)
longhun_skill.getTurnUseCard = function(self)
	if self.player:getHp() > 1 then return end
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByUseValue(cards, true)
	for _, card in ipairs(cards) do
		if card:getSuit() == sgs.Card_Diamond and self:slashIsAvailable() then
			return sgs.Card_Parse(("fire_slash:longhun[%s:%s]=%d"):format(card:getSuitString(), card:getNumberString(), card:getId()))
		end
	end
end

sgs.ai_view_as.longhun = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if player:getHp() > 1 then return end
	if card:getSuit() == sgs.Card_Diamond then
		return ("fire_slash:longhun[%s:%s]=%d"):format(suit, number, card_id)
	elseif card:getSuit() == sgs.Card_Club then
		return ("jink:longhun[%s:%s]=%d"):format(suit, number, card_id)
	elseif card:getSuit() == sgs.Card_Heart then
		return ("peach:longhun[%s:%s]=%d"):format(suit, number, card_id)
	elseif card:getSuit() == sgs.Card_Spade then
		return ("nullification:longhun[%s:%s]=%d"):format(suit, number, card_id)
	end
end

sgs.longhun_suit_value = {
	heart = 6.7,
	spade = 5,
	club = 4.2,
	diamond = 3.9,
}

function sgs.ai_cardneed.longhun(to, card, self)
	if to:getCardCount(true) > 3 then return false end
	if to:isNude() then return true end
	return card:getSuit() == sgs.Card_Heart or card:getSuit() == sgs.Card_Spade
end

sgs.ai_skill_invoke.lianpo = true

function SmartAI:needBear(player)
	player = player or self.player
	return player:hasSkill("renjie") and not player:hasSkill("jilve") and player:getMark("@bear") < 4
end

sgs.ai_skill_invoke.jilve = function(self, data)
	local n = self.player:getMark("@bear")
	local use = (n > 2 or self:getOverflow() > 0)
	local event = self.player:getMark("JilveEvent")
	if event == sgs.AskForRetrial then
		local judge = data:toJudge()
		if not self:needRetrial(judge) then return false end
		return (use or judge.who == self.player or judge.reason == "lightning")
				and self:getRetrialCardId(sgs.QList2Table(self.player:getHandcards()), judge) ~= -1
	elseif event == sgs.Damaged then
		if #self.enemies == 0 then return false end
		return self:askForUseCard("@@fangzhu", "@fangzhu") ~= "."
	elseif event == sgs.CardUsed or event == sgs.CardResponded then
		local card = data:toCardResponse().m_card
		card = card or data:toCardUse().card
		return use or card:isKindOf("ExNihilo")
	else
		assert(false)
	end
end

local jilve_skill = {}
jilve_skill.name = "jilve"
table.insert(sgs.ai_skills, jilve_skill)
jilve_skill.getTurnUseCard = function(self)
	if self.player:getMark("@bear") < 1 or (self.player:hasFlag("JilveWansha") and self.player:hasFlag("JilveZhiheng")) then return end
	local wanshadone = self.player:hasFlag("JilveWansha")
	if not wanshadone and not self.player:hasSkill("wansha") then
		self:sort(self.enemies, "hp")
		for _, enemy in ipairs(self.enemies) do
			if not (enemy:hasSkill("kongcheng") and enemy:isKongcheng()) and self:isWeak(enemy) and self:damageMinusHp(self, enemy, 1) > 0
				and #self.enemies > 1 then
				sgs.ai_skill_choice.jilve = "wansha"
				sgs.ai_use_priority.JilveCard = 8
				return sgs.Card_Parse("@JilveCard=.")
			end
		end
	end
	if not self.player:hasFlag("JilveZhiheng") then
		sgs.ai_skill_choice.jilve = "zhiheng"
		sgs.ai_use_priority.JilveCard = sgs.ai_use_priority.ZhihengCard
		local card = sgs.Card_Parse("@ZhihengCard=.")
		local dummy_use = { isDummy = true }
		self:useSkillCard(card, dummy_use)
		if dummy_use.card then return sgs.Card_Parse("@JilveCard=.") end
	elseif not wanshadone and not self.player:hasSkill("wansha") then
		self:sort(self.enemies, "hp")
		for _, enemy in ipairs(self.enemies) do
			if not (enemy:hasSkill("kongcheng") and enemy:isKongcheng()) and self:isWeak(enemy) and self:damageMinusHp(self, enemy, 1) > 0
				and #self.enemies > 1 then
				sgs.ai_skill_choice.jilve = "wansha"
				sgs.ai_use_priority.JilveCard = 8
				return sgs.Card_Parse("@JilveCard=.") 
			end
		end
	end
end

sgs.ai_skill_use_func.JilveCard = function(card, use, self)
	use.card = card
end

sgs.ai_skill_use["@zhiheng"] = function(self, prompt)
	local card = sgs.Card_Parse("@ZhihengCard=.")
	local dummy_use = { isDummy = true }
	self:useSkillCard(card, dummy_use)
	if dummy_use.card then return (dummy_use.card):toString() .. "->." end
	return "."
end
