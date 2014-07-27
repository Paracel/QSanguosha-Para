local function card_for_qiaobian(self, who, return_prompt)
	local card, target
	if self:isFriend(who) then
		local judges = who:getJudgingArea()
		if not judges:isEmpty() then
			for _, judge in sgs.qlist(judges) do
				card = sgs.Sanguosha:getCard(judge:getEffectiveId())
				if not judge:isKindOf("YanxiaoCard") then
					for _, enemy in ipairs(self.enemies) do
						if not enemy:containsTrick(judge:objectName()) and not enemy:containsTrick("YanxiaoCard")
							and not self.room:isProhibited(self.player, enemy, judge)
							and not (enemy:hasSkills("hongyan|wuyan") and judge:isKindOf("Lightning")) then
							target = enemy
							break
						end
					end
					if target then break end
				end
			end
		end

		local equips = who:getCards("e")
		local weak = false
		if not target and not equips:isEmpty() and who:hasSkills(sgs.lose_equip_skill) then
			for _, equip in sgs.qlist(equips) do
				if equip:isKindOf("OffensiveHorse") then card = equip break
				elseif equip:isKindOf("Weapon") then card = equip break
				elseif equip:isKindOf("DefensiveHorse") and not self:isWeak(who) then
					card = equip
					break
				elseif equip:isKindOf("Armor") and (not self:isWeak(who) or self:needToThrowArmor(who)) then
					card = equip
					break
				end
			end

			if card then
				if card:isKindOf("Armor") or card:isKindOf("DefensiveHorse") then
					self:sort(self.friends, "defense")
				else
					self:sort(self.friends, "handcard")
					self.friends = sgs.reverse(self.friends)
				end
				for _, friend in ipairs(self.friends) do
					if not self:getSameEquip(card, friend) and friend:objectName() ~= who:objectName()
						and friend:hasSkills(sgs.need_equip_skill .. "|" .. sgs.lose_equip_skill) then
						target = friend
						break
					end
				end
				for _, friend in ipairs(self.friends) do
					if not self:getSameEquip(card, friend) and friend:objectName() ~= who:objectName() then
						target = friend
						break
					end
				end
			end
		end
	else
		local judges = who:getJudgingArea()
		if who:containsTrick("YanxiaoCard") then
			for _, judge in sgs.qlist(judges) do
				if judge:isKindOf("YanxiaoCard") then
					card = sgs.Sanguosha:getCard(judge:getEffectiveId())
					for _, friend in ipairs(self.friends) do
						if not friend:containsTrick(judge:objectName()) and not self.room:isProhibited(self.player, friend, judge)
							and not friend:getJudgingArea():isEmpty() then
							target = friend
							break
						end
					end
					if target then break end
					for _, friend in ipairs(self.friends) do
						if not friend:containsTrick(judge:objectName()) and not self.room:isProhibited(self.player, friend, judge) then
							target = friend
							break
						end
					end
					if target then break end
				end
			end
		end

		if card == nil or target == nil then
			if not who:hasEquip() or (who:hasSkills(sgs.lose_equip_skill) and not who:getTreasure()) then return nil end
			local card_id = self:askForCardChosen(who, "e", "dummy")
			if who:hasEquip(sgs.Sanguosha:getCard(card_id)) then card = sgs.Sanguosha:getCard(card_id) end
			if card then
				if card:isKindOf("Armor") or card:isKindOf("DefensiveHorse") or card:isKindOf("WoodenOx") then
					self:sort(self.friends, "defense")
				else
					self:sort(self.friends, "handcard")
					self.friends = sgs.reverse(self.friends)
				end
				for _, friend in ipairs(self.friends) do
					if not self:getSameEquip(card, friend) and friend:objectName() ~= who:objectName() and friend:hasSkills(sgs.lose_equip_skill .. "|shensu") then
						target = friend
						break
					end
				end
				if not target then
					for _, friend in ipairs(self.friends) do
						if not self:getSameEquip(card, friend) and friend:objectName() ~= who:objectName() then
							target = friend
							break
						end
					end
				end
			end
		end
	end

	if return_prompt == "card" then return card
	elseif return_prompt == "target" then return target
	else
		return (card and target)
	end
end

sgs.ai_skill_cardchosen.qiaobian = function(self, who, flags)
	if flags == "ej" then
		return card_for_qiaobian(self, who, "card")
	end
end

sgs.ai_skill_playerchosen.qiaobian = function(self, targets)
	local who = self.room:getTag("QiaobianTarget"):toPlayer()
	if who then
		if not card_for_qiaobian(self, who, "target") then self.room:writeToConsole("NULL") end
		return card_for_qiaobian(self, who, "target")
	end
end

sgs.ai_skill_discard.qiaobian = function(self, discard_num, min_num, optional, include_equip)
	local current_phase = self.player:getMark("qiaobianPhase")
	local to_discard = {}
	self:updatePlayers()
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	local card
	for i = 1, #cards, 1 do
		local isPeach = cards[i]:isKindOf("Peach")
		if isPeach then
			local stealer = self.room:findPlayerBySkillName("nostuxi") or self.room:findPlayerBySkillName("tuxi")
			if stealer and self:isEnemy(stealer)
				and self.player:getHandcardNum() <= 2 and (stealer:hasSkill("nostuxi") or self.player:getHandcardNum() - 1 >= stealer:getHandcardNum())
				and not self:willSkipDrawPhase(stealer) then
				card = cards[i]
				break
			end
		else
			card = cards[i]
			break
		end
	end
	if not card then return {} end
	table.insert(to_discard, card:getEffectiveId())

	if current_phase == sgs.Player_Judge and not self.player:isSkipped(sgs.Player_Judge) then
		if (self.player:containsTrick("lightning") and not self:hasWizard(self.friends) and self:hasWizard(self.enemies))
			or (self.player:containsTrick("lightning") and #self.friends > #self.enemies) then
			return to_discard
		elseif self.player:containsTrick("supply_shortage") then
			if self.player:getHp() > self.player:getHandcardNum() then return to_discard end
			local targets = self:getTuxiTargets("nostuxi", true)
			if #targets == 2 then
				return to_discard
			end
		elseif self.player:containsTrick("indulgence") then 
			if self.player:getHandcardNum() > 3 or self.player:getHandcardNum() > self.player:getHp() - 1 then return to_discard end
			for _, friend in ipairs(self.friends_noself) do
				if not friend:containsTrick("YanxiaoCard") and (friend:containsTrick("indulgence") or friend:containsTrick("supply_shortage")) then
					return to_discard
				end
			end
		end
	elseif current_phase == sgs.Player_Draw and not self.player:isSkipped(sgs.Player_Draw) then
		self.qiaobian_draw_targets = {}
		if self.player:hasSkill("nostuxi") and not self:willSkipDrawPhase() then return {} end
		if self.player:hasSkill("tuxi") and not self:willSkipDrawPhase() then
			local count = 0
			for _, enemy in ipairs(self.enemies) do
				if enemy:getHandcardNum() >= self.player:getHandcardNum() then count = count + 1 end
				if count == 2 then return {} end
			end
		end
		local cardstr = sgs.ai_skill_use["@@nostuxi"](self, "@nostuxi")
		if cardstr:match("->") then
			local targets = self:getTuxiTargets("nostuxi", true)
			if #targets == 2 then
				local t1, t2 = findPlayerByObjectName(self.room, targets[1]), findPlayerByObjectName(self.room, targets[2])
				table.insert(self.qiaobian_draw_targets, t1:objectName())
				table.insert(self.qiaobian_draw_targets, t2:objectName())
				return to_discard
			end
		end
		return {}
	elseif current_phase == sgs.Player_Play and not self.player:isSkipped(sgs.Player_Discard) then
		self:sortByKeepValue(cards)
		table.remove(to_discard)
		table.insert(to_discard, cards[1]:getEffectiveId())

		self:sort(self.enemies, "defense")
		self:sort(self.friends, "defense")
		self:sort(self.friends_noself, "defense")

		for _, friend in ipairs(self.friends) do
			if not friend:getCards("j"):isEmpty() and not friend:containsTrick("YanxiaoCard") and card_for_qiaobian(self, friend, ".") then
				return to_discard
			end
		end

		for _, enemy in ipairs(self.enemies) do
			if not enemy:getCards("j"):isEmpty() and enemy:containsTrick("YanxiaoCard") and card_for_qiaobian(self, enemy, ".") then
				return to_discard
			end
		end

		for _, friend in ipairs(self.friends_noself) do
			if not friend:getCards("e"):isEmpty() and friend:hasSkills(sgs.lose_equip_skill) and card_for_qiaobian(self, friend, ".") then
				return to_discard
			end
		end

		local top_value = 0
		for _, hcard in ipairs(cards) do
			if not hcard:isKindOf("Jink") then
				if self:getUseValue(hcard) > top_value then top_value = self:getUseValue(hcard) end
			end
		end
		if top_value >= 3.7 and #(self:getTurnUse()) > 0 then return {} end

		local targets = {}
		for _, enemy in ipairs(self.enemies) do
			if not enemy:hasSkills(sgs.lose_equip_skill) and card_for_qiaobian(self, enemy, ".") then
				table.insert(targets, enemy)
			end
		end

		if #targets > 0 then
			return to_discard
		end
	elseif current_phase == sgs.Player_Discard then
		if self:needBear() then return {} end
		self:sortByKeepValue(cards)
		if self.player:getHandcardNum() - 1 > self.player:getMaxCards() then
			return { cards[1]:getEffectiveId() }
		end
	end

	return {}
end

sgs.ai_skill_use["@@qiaobian"] = function(self, prompt)
	self:updatePlayers()

	if prompt == "@qiaobian-2" then
		if #self.qiaobian_draw_targets == 2 then
			return "@QiaobianCard=.->" .. table.concat(self.qiaobian_draw_targets, "+")
		end
		return "."
	end

	if prompt == "@qiaobian-3" then
		self:sort(self.enemies, "hp")
		local has_armor = true
		local judge
		for _, friend in ipairs(self.friends) do
			if not friend:getCards("j"):isEmpty() and card_for_qiaobian(self, friend, ".") then
				return "@QiaobianCard=.->" .. friend:objectName()
			end
		end

		for _, enemy in ipairs(self.enemies) do
			if not enemy:getCards("j"):isEmpty() and enemy:containsTrick("YanxiaoCard") and card_for_qiaobian(self, enemy, ".") then
				return "@QiaobianCard=.->" .. enemy:objectName()
			end
		end

		for _, friend in ipairs(self.friends_noself) do
			if not friend:getCards("e"):isEmpty() and friend:hasSkills(sgs.lose_equip_skill) and card_for_qiaobian(self, friend, ".") then
				return "@QiaobianCard=.->" .. friend:objectName()
			end
			if not friend:getArmor() then has_armor = false end
		end

		local targets = {}
		for _, enemy in ipairs(self.enemies) do
			if card_for_qiaobian(self, enemy, ".") then
				table.insert(targets, enemy)
			end
		end

		if #targets > 0 then
			self:sort(targets, "defense")
			return "@QiaobianCard=.->" .. targets[#targets]:objectName()
		end
	end

	return "."
end

sgs.ai_card_intention.QiaobianCard = function(self, card, from, tos)
	if from:getMark("qiaobianPhase") == 3 then return sgs.ai_card_intention.NosTuxiCard(self, card, from, tos) end
end

function sgs.ai_cardneed.qiaobian(to, card)
	return to:getCardCount() <= 2
end

sgs.ai_skill_invoke.tuntian = function(self, data)
	if self.player:hasSkill("zaoxian") and self.player:getPile("field"):length() < 3 and self.player:getMark("zaoxian") == 0 then
		for _, enemy in ipairs(self.enemies) do
			if not enemy:hasSkills("nosqianxun|noswuyan") then return true end
		end
		return false
	end
	return true
end

sgs.ai_slash_prohibit.tuntian = function(self, from, to, card)
	if self:isFriend(to, from) or not to:hasSkill("zaoxian") then return false end
	local enemies = self:getEnemies(to)
	local good_enemy = false
	for _, enemy in ipairs(enemies) do
		if not enemy:hasSkills("nosqianxun|noswuyan|weimu") then
			good_enemy = true
			break
		end
	end
	if not good_enemy then return false end
	if not sgs.isJinkAvailable(from, to, card) then return false end
	if getCardsNum("Jink", to, from) < 1 or sgs.card_lack[to:objectName()]["Jink"] == 1 or self:isWeak(to) then return false end
	if to:getHandcardNum() >= 3 then return true end
	return false
end

local jixi_skill = {}
jixi_skill.name = "jixi"
table.insert(sgs.ai_skills, jixi_skill)
jixi_skill.getTurnUseCard = function(self)
	if self.player:getPile("field"):isEmpty()
		or (self.player:getHandcardNum() >= self.player:getHp() + 2
			and self.player:getPile("field"):length() <= self.room:getAlivePlayers():length() / 2 - 1) then
		return
	end
	local can_use = false
	for i = 0, self.player:getPile("field"):length() - 1, 1 do
		local snatch = sgs.Sanguosha:getCard(self.player:getPile("field"):at(i))
		local snatch_str = ("snatch:jixi[%s:%s]=%d"):format(snatch:getSuitString(), snatch:getNumberString(), self.player:getPile("field"):at(i))
		local jixisnatch = sgs.Card_Parse(snatch_str)

		for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if (self.player:distanceTo(player, 1) <= 1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_DistanceLimit, self.player, jixisnatch))
				and not self.room:isProhibited(self.player, player, jixisnatch) and self:hasTrickEffective(jixisnatch, player) then

				local suit = snatch:getSuitString()
				local number = snatch:getNumberString()
				local card_id = snatch:getEffectiveId()
				local card_str = ("snatch:jixi[%s:%s]=%d"):format(suit, number, card_id)
				local snatch = sgs.Card_Parse(card_str)
				assert(snatch)
				return snatch
			end
		end
	end
end

sgs.ai_view_as.jixi = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card_place == sgs.Player_PlaceSpecial and player:getPileName(card_id) == "field" then
		return ("snatch:jixi[%s:%s]=%d"):format(suit, number, card_id)
	end
end

sgs.ai_skill_cardask["@xiangle-discard"] = function(self, data)
	local target = data:toPlayer()
	if self:isFriend(target) and not self:findLeijiTarget(target, 50, self.player) then return "." end
	local has_peach, has_analeptic, has_slash, has_jink
	for _, card in sgs.qlist(self.player:getHandcards()) do
		if card:isKindOf("Peach") then has_peach = card
		elseif card:isKindOf("Analeptic") then has_analeptic = card
		elseif card:isKindOf("Slash") then has_slash = card
		elseif card:isKindOf("Jink") then has_jink = card
		end
	end

	if has_slash then return "$" .. has_slash:getEffectiveId()
	elseif has_jink then return "$" .. has_jink:getEffectiveId()
	elseif has_analeptic or has_peach then
		if getCardsNum("Jink", target, self.player) == 0 and self.player:getMark("drank") > 0 and self:getAllPeachNum(target) == 0 then
			if has_analeptic then return "$" .. has_analeptic:getEffectiveId()
			else return "$" .. has_peach:getEffectiveId()
			end
		end
	else return "."
	end
end

function sgs.ai_slash_prohibit.xiangle(self, from, to)
	if self:isFriend(to, from) then return false end
	local slash_num, analeptic_num, jink_num
	if from:objectName() == self.player:objectName() then
		slash_num = self:getCardsNum("Slash")
		analeptic_num = self:getCardsNum("Analeptic")
		jink_num = self:getCardsNum("Jink")
	else
		slash_num = getCardsNum("Slash", from, to)
		analeptic_num = getCardsNum("Analpetic", from, to)
		jink_num = getCardsNum("Jink", from, to)
	end
	if self:needKongcheng() and self.player:getHandcardNum() == 2 then return slash_num + analeptic_num + jink_num < 2 end
	return slash_num + analeptic_num + math.max(jink_num - 1, 0) < 2
end

sgs.ai_skill_invoke.fangquan = function(self, data)
	self.fangquan_card_str = nil
	if #self.friends == 1 then
		return false
	end

	-- First we'll judge whether it's worth skipping the Play Phase
	local cards = sgs.QList2Table(self.player:getHandcards())
	local shouldUse, range_fix = 0, 0
	local hasCrossbow, slashTo = false, false
	for _, card in ipairs(cards) do
		if card:isKindOf("TrickCard") and self:getUseValue(card) > 3.69 then
			local dummy_use = { isDummy = true }
			self:useTrickCard(card, dummy_use)
			if dummy_use.card then shouldUse = shouldUse + (card:isKindOf("ExNihilo") and 2 or 1) end
		end
		if card:isKindOf("Weapon") then
			local new_range = sgs.weapon_range[card:getClassName()] or 0
			local current_range = self.player:getAttackRange()
			range_fix = math.min(current_range - new_range, 0)
		end
		if card:isKindOf("OffensiveHorse") and not self.player:getOffensiveHorse() then range_fix = range_fix - 1 end
		if card:isKindOf("DefensiveHorse") or card:isKindOf("Armor") and not self:getSameEquip(card) and (self:isWeak() or self:getCardsNum("Jink") == 0) then shouldUse = shouldUse + 1 end
		if card:isKindOf("Crossbow") or self:hasCrossbowEffect() then hasCrossbow = true end
	end

	local slashs = self:getCards("Slash")
	for _, enemy in ipairs(self.enemies) do
		for _, slash in ipairs(slashs) do
			if hasCrossbow and self:getCardsNum("Slash") > 1 and self:slashIsEffective(slash, enemy)
				and self.player:canSlash(enemy, slash, true, range_fix) then
				shouldUse = shouldUse + 2
				hasCrossbow = false
				break
			elseif not slashTo and self:slashIsAvailable() and self:slashIsEffective(slash, enemy)
				and self.player:canSlash(enemy, slash, true, range_fix) and getCardsNum("Jink", enemy, self.player) < 1 then
				shouldUse = shouldUse + 1
				slashTo = true
			end
		end
	end
	if shouldUse >= 2 then return end

	-- Then we need to find the card to be discarded
	local limit = self.player:getMaxCards()
	if self.player:isKongcheng() then return false end
	if self:getCardsNum("Peach") >= limit - 2 and self.player:isWounded() then return false end

	local to_discard = nil

	local index = 0
	local all_peaches = 0
	for _, card in ipairs(cards) do
		if isCard("Peach", card, self.player) then
			all_peaches = all_peaches + 1
		end
	end
	if all_peaches >= 2 and self:getOverflow() <= 0 then return false end
	self:sortByKeepValue(cards)
	cards = sgs.reverse(cards)

	for i = #cards, 1, -1 do
		local card = cards[i]
		if not isCard("Peach", card, self.player) and not self.player:isJilei(card) then
			to_discard = card:getEffectiveId()
			break
		end
	end
	if to_discard == nil then return false end

	-- At last we try to find the target
	self:sort(self.friends_noself, "handcard")
	self.friends_noself = sgs.reverse(self.friends_noself)
	for _, target in ipairs(self.friends_noself) do
		if not target:hasSkill("dawu") and target:hasSkills("yongsi|zhiheng|" .. sgs.priority_skill .. "|shensu")
			and (not self:willSkipPlayPhase(target) or target:hasSkill("shensu")) then
			self.fangquan_card_str = "@FangquanCard=" .. to_discard .. "->" .. target:objectName()
			return true
		end
	end
	for _, target in ipairs(self.friends_noself) do
		if target:hasSkill("dawu") then
			local use = true
			for _, p in ipairs(self.friends_noself) do
				if p:getMark("@fog") > 0 then use = false break end
			end
			if use then
				self.fangquan_card_str = "@FangquanCard=" .. to_discard .. "->" .. target:objectName()
				return true
			end
		end
	end
	return false
end

sgs.ai_skill_use["@@fangquan"] = function(self, prompt)
	return self.fangquan_card_str or "."
end

sgs.ai_card_intention.FangquanCard = -120

local tiaoxin_skill = {}
tiaoxin_skill.name = "tiaoxin"
table.insert(sgs.ai_skills, tiaoxin_skill)
tiaoxin_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("TiaoxinCard") then return end
	return sgs.Card_Parse("@TiaoxinCard=.")
end

sgs.ai_skill_use_func.TiaoxinCard = function(card, use, self)
	local distance = use.defHorse and 1 or 0
	local targets = {}
	for _, enemy in ipairs(self.enemies) do
		if enemy:inMyAttackRange(self.player, distance)
			and ((getCardsNum("Slash", enemy, self.player) < 1 and self.player:getHp() > 1)
					or getCardsNum("Slash", enemy, self.player) == 0
					or self:getCardsNum("Jink") > 0
					or self:findLeijiTarget(self.player, 50, enemy)
					or not enemy:canSlash(self.player))
			and not enemy:isNude() and not self:doNotDiscard(enemy) then
			table.insert(targets, enemy)
		end
	end

	if #targets == 0 then return end

	sgs.ai_use_priority.TiaoxinCard = 8
	if not self.player:getArmor() and not self.player:isKongcheng() then
		for _, card in sgs.qlist(self.player:getCards("h")) do
			if card:isKindOf("Armor") and self:evaluateArmor(card) > 3 then
				sgs.ai_use_priority.TiaoxinCard = 5.9
				break
			end
		end
	end

	if use.to then
		self:sort(targets, "defenseSlash")
		use.to:append(targets[1])
	end
	use.card = sgs.Card_Parse("@TiaoxinCard=.")
end

sgs.ai_skill_cardask["@tiaoxin-slash"] = function(self, data, pattern, target)
	if target then
		for _, slash in ipairs(self:getCards("Slash")) do
			if self:slashIsEffective(slash, target) and self:isFriend(target) and target:hasSkills("leiji|nosleiji") then
				return slash:toString()
			end
			if (self:slashIsEffective(slash, target) and not (self:getDamagedEffects(target, self.player, true) or self:needToLoseHp(target, self.player, true, true)))
				and self:isEnemy(target) then
				return slash:toString()
			end
			if (not self:slashIsEffective(slash, target) or self:getDamagedEffects(target, self.player, true) or self:needToLoseHp(target, self.player, true))
				and self:isFriend(target) then
				return slash:toString()
			end
		end
		for _, slash in ipairs(self:getCards("Slash")) do
			if (not (self:getDamagedEffects(target, self.player) or self:needToLoseHp(target)) or not self:slashIsEffective(slash, target))
				and not self:isFriend(target) then
				return slash:toString()
			end
		end
	end
	return "."
end

sgs.ai_card_intention.TiaoxinCard = 80
sgs.ai_use_priority.TiaoxinCard = 4

sgs.ai_skill_choice.zhiji = function(self, choice)
	if self.player:getHp() < self.player:getMaxHp() - 1 then return "recover" end
	return "draw"
end

sgs.ai_cardneed.jiang = function(to, card, self)
	return isCard("Duel", card, to) or (isCard("Slash", card, to) and card:isRed())
end

local zhiba_pindian_skill = {}
zhiba_pindian_skill.name = "zhiba_pindian"
table.insert(sgs.ai_skills, zhiba_pindian_skill)
zhiba_pindian_skill.getTurnUseCard = function(self)
	if self.player:isKongcheng() or self:needBear() or self:getOverflow() <= 0 or self.player:getKingdom() ~= "wu"
		or self.player:hasFlag("ForbidZhiba") then return end
	return sgs.Card_Parse("@ZhibaCard=.")
end

sgs.ai_use_priority.ZhibaCard = 0

sgs.ai_skill_use_func.ZhibaCard = function(card, use, self)
	local lords = {}
	for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if player:hasLordSkill("zhiba") and not player:isKongcheng() and not player:hasFlag("ZhibaInvoked")
			and not (self:isEnemy(player) and player:getMark("hunzi") > 0) then
			table.insert(lords, player)
		end
	end
	if #lords == 0 then return end
	local max_card, min_card = self:getMaxCard(), self:getMinCard()
	local max_num = self.player:hasSkill("yingyang") and math.min(max_card:getNumber() + 3, 13) or max_card:getNumber()
	local min_num = self.player:hasSkill("yingyang") and math.max(1, min_card:getNumber() - 3) or min_card:getNumber()
	self:sort(lords, "defense")
	for _, lord in ipairs(lords) do
		local zhiba_str
		local lord_max_card, lord_min_card = self:getMaxCard(lord), self:getMinCard(lord)
		local lord_max_num, lord_min_num = (lord_max_card and lord_max_card:getNumber() or 0), (lord_min_card and lord_min_card:getNumber() or 14)
		if lord_max_card and lord:hasSkill("yingyang") then lord_max_num = math.min(lord_max_num + 3, 13) end
		if lord_min_card and lord:hasSkill("yingyang") then lord_min_num = math.max(1, lord_min_num - 3) end

		if self:isEnemy(lord) and max_num > 10 and max_num > lord_max_num then
			if isCard("Jink", max_card, self.player) and self:getCardsNum("Jink") == 1 then return end
			if isCard("Peach", max_card, self.player) or isCard("Analeptic", max_card, self.player) then return end
			self.zhiba_pindian_card = max_card:getEffectiveId()
			zhiba_str = "@ZhibaCard=."
		end
		if self:isFriend(lord) and not lord:hasSkill("manjuan") and ((lord_max_num > 0 and min_num <= lord_max_num) or min_num < 7) then
			if isCard("Jink", min_card, self.player) and self:getCardsNum("Jink") == 1 then return end
			self.zhiba_pindian_card = min_card:getEffectiveId()
			zhiba_str = "@ZhibaCard=."
		end

		if zhiba_str then
			use.card = sgs.Card_Parse(zhiba_str)
			if use.to then use.to:append(lord) end
			return
		end
	end
end

sgs.ai_need_damaged.hunzi = function(self, attacker, player)
	if player:hasSkill("hunzi") and player:getMark("hunzi") == 0 and not player:hasSkill("chanyuan")
		and self:getEnemyNumBySeat(self.room:getCurrent(), player, player, true) < player:getHp()
		and (player:getHp() > 2 or (player:getHp() == 2 and (player:faceUp() or player:hasSkill("guixin")))) then
		return true
	end
	return false
end

sgs.ai_skill_choice.zhiba_pindian = function(self, choices)
	local who = self.room:getCurrent()
	local cards = self.player:getHandcards()
	local has_large_number, all_small_number = false, true
	for _, c in sgs.qlist(cards) do
		if c:getNumber() > 11 then
			has_large_number = true
			break
		end
	end
	for _, c in sgs.qlist(cards) do
		if c:getNumber() > 4 then
			all_small_number = false
			break
		end
	end
	if all_small_number or (self:isEnemy(who) and not has_large_number) then return "reject"
	else return "accept"
	end
end

function sgs.ai_skill_pindian.zhiba_pindian(minusecard, self, requestor, maxcard)
	local cards, maxcard = sgs.QList2Table(self.player:getHandcards())
	local function compare_func(a, b)
		return a:getNumber() > b:getNumber()
	end
	table.sort(cards, compare_func)
	for _, card in ipairs(cards) do
		if self:getUseValue(card) < 6 then maxcard = card break end
	end
	return maxcard or cards[1]
end

sgs.ai_card_intention.ZhibaCard = 0
sgs.ai_choicemade_filter.pindian.zhiba_pindian = function(self, from, promptlist)
	local number = sgs.Sanguosha:getCard(tonumber(promptlist[4])):getNumber()
	local lord = findPlayerByObjectName(self.room, promptlist[5])
	if not lord then return end
	local lord_max_card = self:getMaxCard(lord)
	if lord_max_card and lord_max_card:getNumber() >= number then sgs.updateIntention(from, lord, -60)
	elseif lord_max_card and lord_max_card:getNumber() < number then sgs.updateIntention(from, lord, 60)
	elseif number < 6 then sgs.updateIntention(from, lord, -60)
	elseif number > 8 then sgs.updateIntention(from, lord, 60)
	end
end

local zhijian_skill = {}
zhijian_skill.name = "zhijian"
table.insert(sgs.ai_skills, zhijian_skill)
zhijian_skill.getTurnUseCard = function(self)
	local equips = {}
	for _, card in sgs.qlist(self.player:getHandcards()) do
		if card:getTypeId() == sgs.Card_TypeEquip then
			table.insert(equips, card)
		end
	end
	if #equips == 0 then return end

	return sgs.Card_Parse("@ZhijianCard=.")
end

sgs.ai_skill_use_func.ZhijianCard = function(card, use, self)
	local equips = {}
	for _, card in sgs.qlist(self.player:getHandcards()) do
		if card:isKindOf("Armor") or card:isKindOf("Weapon") then
			if not self:getSameEquip(card) then
			elseif card:isKindOf("GudingBlade") and self:getCardsNum("Slash") > 0 then
				local HeavyDamage
				local slash = self:getCard("Slash")
				for _, enemy in ipairs(self.enemies) do
					if self.player:canSlash(enemy, slash, true) and not self:slashProhibit(slash, enemy)
						and self:slashIsEffective(slash, enemy) and self:hasHeavySlashDamage(self.player, slash, enemy) then
						HeavyDamage = true
						break
					end
				end
				if not HeavyDamage then table.insert(equips, card) end
			else
				table.insert(equips, card)
			end
		elseif card:getTypeId() == sgs.Card_TypeEquip then
			table.insert(equips, card)
		end
	end

	if #equips == 0 then return end
	for _, equip in ipairs(equips) do
		if equip:isKindOf("SilverLion") then
			for _, enemy in ipairs(self.enemies) do
				if not enemy:getArmor() and enemy:hasSkills("bazhen|yizhong|bossmanjia") then
					use.card = sgs.Card_Parse("@ZhijianCard=" .. equip:getId())
					if use.to then use.to:append(enemy) end
					return
				end
			end
		end
	end

	local select_equip, target
	for _, friend in ipairs(self.friends_noself) do
		for _, equip in ipairs(equips) do
			if not self:getSameEquip(equip, friend) and friend:hasSkills(sgs.need_equip_skill .. "|" .. sgs.lose_equip_skill)
				and not (equip:isKindOf("Armor") and self:evaluateArmor(equip, friend) > self:evaluateArmor(nil, friend)) then
				target = friend
				select_equip = equip
				break
			end
		end
		if target then break end
	end
	if not target then
		for _, friend in ipairs(self.friends_noself) do
			for _, equip in ipairs(equips) do
				if not self:getSameEquip(equip, friend)
					and not (equip:isKindOf("Armor") and self:evaluateArmor(equip, friend) > self:evaluateArmor(nil, friend)) then
					target = friend
					select_equip = equip
					break
				end
			end
			if target then break end
		end
	end

	if not target then return end
	if use.to then
		use.to:append(target)
	end
	local zhijian = sgs.Card_Parse("@ZhijianCard=" .. select_equip:getId())
	use.card = zhijian
end

sgs.ai_card_intention.ZhijianCard = function(self, card, from, tos)
	local to = tos[1]
	local equip = sgs.Sanguosha:getCard(card:getEffectiveId())
	if equip:isKindOf("Armor") and to:hasSkills("bazhen|yizhong|bossmanjia") then
	else sgs.updateIntention(from, to, -80) end
end

sgs.ai_cardneed.zhijian = sgs.ai_cardneed.equip

sgs.ai_skill_invoke.guzheng = function(self, data)
	if self:isLihunTarget(self.player, data:toInt() - 1) then return false end
	local player = self.room:getCurrent()
	local invoke = (self:isFriend(player) and not self:needKongcheng(player, true))
					or (not self.player:hasSkill("manjuan") and (data:toInt() >= 3 or (data:toInt() == 2 and not player:hasSkills(sgs.cardneed_skill))))
					or (self:isEnemy(player) and self:needKongcheng(player, true))
	return invoke
end

sgs.ai_skill_askforag.guzheng = function(self, card_ids)
	local who = self.room:getCurrent()

	local wulaotai = self.room:findPlayerBySkillName("buyi")
	local Need_buyi = wulaotai and who:getHp() == 1 and self:isFriend(who, wulaotai)

	local cards, except_Equip, except_Key = {}, {}, {}
	for _, card_id in ipairs(card_ids) do
		local card = sgs.Sanguosha:getCard(card_id)
		if self.player:hasSkill("zhijian") and not card:isKindOf("EquipCard") then
			table.insert(except_Equip, card)
		end
		if not card:isKindOf("Peach") and not card:isKindOf("Jink") and not card:isKindOf("Analeptic") and
			not card:isKindOf("Nullification") and not (card:isKindOf("EquipCard") and self.player:hasSkill("zhijian")) then
			table.insert(except_Key, card)
		end
		table.insert(cards, card)
	end

	if self:isFriend(who) then
		if Need_buyi then
			local buyicard1, buyicard2
			self:sortByKeepValue(cards)
			for _, card in ipairs(cards) do
				if card:isKindOf("TrickCard") and not buyicard1 then
					buyicard1 = card:getEffectiveId()
				end
				if not card:isKindOf("BasicCard") and not buyicard2 then
					buyicard2 = card:getEffectiveId()
				end
				if buyicard1 then break end
			end
			if buyicard1 or buyicard2 then
				return buyicard1 or buyicard2
			end
		end

		local peach_num, peach, jink, analeptic, slash = 0
		for _, card in ipairs(cards) do
			if card:isKindOf("Peach") then peach = card:getEffectiveId() peach_num = peach_num + 1 end
			if card:isKindOf("Jink") then jink = card:getEffectiveId() end
			if card:isKindOf("Analeptic") then analeptic = card:getEffectiveId() end
			if card:isKindOf("Slash") then slash = card:getEffectiveId() end
		end
		if peach then
			if peach_num > 1
				or (self:getCardsNum("Peach") >= self.player:getMaxCards())
				or (who:getHp() < getBestHp(who) and who:getHp() < self.player:getHp()) then
					return peach
			end
		end
		if self:isWeak(who) and (jink or analeptic) then
			return jink or analeptic
		end

		for _, card in ipairs(cards) do
			if not card:isKindOf("EquipCard") then
				for _, askill in ipairs(sgs.getPlayerSkillList(who)) do
					local callback = sgs.ai_cardneed[askill:objectName()]
					if type(callback)=="function" and callback(who, card, self) then
						return card:getEffectiveId()
					end
				end
			end
		end

		if jink or analeptic or slash then
			return jink or analeptic or slash
		end

		for _, card in ipairs(cards) do
			if not card:isKindOf("EquipCard") and not card:isKindOf("Peach") then
				return card:getEffectiveId()
			end
		end
	else
		if Need_buyi then
			for _, card in ipairs(cards) do
				if card:isKindOf("Slash") then
					return card:getEffectiveId()
				end
			end
		end
		for _, card in ipairs(cards) do
			if card:isKindOf("EquipCard") and self.player:hasSkill("zhijian") then
				local Cant_Zhijian = true
				for _, friend in ipairs(self.friends) do
					if not self:getSameEquip(card, friend) then
						Cant_Zhijian = false
					end
				end
				if Cant_Zhijian then
					return card:getEffectiveId()
				end
			end
		end

		local new_cards = (#except_Key > 0 and except_Key) or (#except_Equip > 0 and except_Equip) or cards

		self:sortByKeepValue(new_cards)
		local valueless, slash
		for _, card in ipairs(new_cards) do
			if card:isKindOf("Lightning") and not who:hasSkills(sgs.wizard_harm_skill) then
				return card:getEffectiveId()
			end

			if card:isKindOf("Slash") then slash = card:getEffectiveId() end

			if not valueless and not card:isKindOf("Peach") then
				for _, askill in ipairs(sgs.getPlayerSkillList(who)) do
					local callback = sgs.ai_cardneed[askill:objectName()]
					if (type(callback) == "function" and not callback(who, card, self)) or not callback then
						valueless = card:getEffectiveId()
						break
					end
				end
			end
		end

		if slash or valueless then
			return slash or valueless
		end

		return new_cards[1]:getEffectiveId()
	end

	return card_ids[1]
end

sgs.ai_skill_cardask["@beige"] = function(self, data)
	local damage = data:toDamage()
	if not self:isFriend(damage.to) or self:isFriend(damage.from) then return "." end
	local to_discard = self:askForDiscard("beige", 1, 1, false, true)
	if #to_discard > 0 then return "$" .. to_discard[1] else return "." end
end

function sgs.ai_cardneed.beige(to, card)
	return to:getCardCount() <= 2
end

function sgs.ai_slash_prohibit.duanchang(self, from, to)
	if from:hasSkill("jueqing") or (from:hasSkill("nosqianxi") and from:distanceTo(to) == 1) then return false end
	if from:hasFlag("NosJiefanUsed") then return false end
	if to:getHp() > 1 or #(self:getEnemies(from)) == 1 then return false end
	if from:getMaxHp() == 3 and from:getArmor() and from:getDefensiveHorse() then return false end
	if from:getMaxHp() <= 3 or (from:isLord() and self:isWeak(from)) then return true end
	if from:getMaxHp() <= 3 or (self.room:getLord() and from:getRole() == "renegade") then return true end
	return false
end

sgs.ai_skill_invoke.huashen = function(self)
	local huashen_skill = self.player:getTag("HuashenSkills"):toString()
	if (huashen_skill == "lianpo" and self.player:getMark("lianpo") > 0) or (huashen_skill == "botu" and self.player:getMark("botu") == 15) then return false end
	return self.player:getHp() > 0
end

function sgs.ai_skill_choice.huashen(self, choices, data, xiaode_choice)
	local str = choices
	choices = str:split("+")
	if not xiaode_choice and self.player:getHp() < 1 and str:matchOne("nosbuqu") then return "nosbuqu" end
	if (xiaode_choice and xiaode_choice > 0) or self.player:getPhase() == sgs.Player_RoundStart then
		if not xiaode_choice and self.player:getHp() < 1 and str:matchOne("nosbuqu") then return "nosbuqu" end
		if (self.player:getHandcardNum() >= self.player:getHp() and self.player:getHandcardNum() < 10 and not self:isWeak()) or self.player:isSkipped(sgs.Player_Play) then
			if str:matchOne("keji") then return "keji" end
		end
		if self.player:getHandcardNum() > 4 then
			for _, askill in ipairs(("shuangxiong|duwu|nosfuhun|tianyi|xianzhen|qiaoshui|paoxiao|luanji|huoji|qixi|" ..
									"duanliang|nosguose|guose|luoyi|nosluoyi|dangxian|fuluan|longyin"):split("|")) do
				if str:matchOne(askill) then return askill end
			end
			if self:findFriendsByType(sgs.Friend_Draw) then
				for _, askill in ipairs(("nosrende|rende|lirang"):split("|")) do
					if str:matchOne(askill) then return askill end
				end
			end
		end

		if self.player:getLostHp() >= 2 then
			if str:matchOne("qingnang") then return "qingnang" end
			if str:matchOne("jieyin") and self:findFriendsByType(sgs.Friend_MaleWounded) then return "jieyin" end
			if str:matchOne("nosrende") and self:findFriendsByType(sgs.Friend_Draw) then return "nosrende" end
			if str:matchOne("rende") and self:findFriendsByType(sgs.Friend_Draw) then return "rende" end
			for _, askill in ipairs(("juejing|nosmiji|nosshangshi|shangshi|kuiwei|nosjushou|zaiqi|kuanggu|kofkuanggu"):split("|")) do
				if str:matchOne(askill) then return askill end
			end
			if str:matchOne("miji") and self:findFriendsByType(sgs.Friend_Draw) then return "miji" end
		end

		if self.player:getHandcardNum() < 2 then
			if str:matchOne("haoshi") then return "haoshi" end
		end

		if self.player:isWounded() then
			if str:matchOne("drqingnang") then return "drqingnang" end
			if str:matchOne("qingnang") then return "qingnang" end
			if str:matchOne("jieyin") and self:findFriendsByType(sgs.Friend_MaleWounded) then return "jieyin" end
			if str:matchOne("nosrende") and self:findFriendsByType(sgs.Friend_Draw) then return "nosrende" end
			if str:matchOne("rende") and self:findFriendsByType(sgs.Friend_Draw) then return "rende" end
			for _, askill in ipairs(("juejing|nosmiji"):split("|")) do
				if str:matchOne(askill) then return askill end
			end
			if self.player:getHp() < 2 and self.player:getHandcardNum() == 1 and self:getCardsNum("Peach") == 0 then
				if str:matchOne("shenzhi") then return "shenzhi" end
			end
		end

		if self.player:getCards("e"):length() > 1 then
			for _, askill in ipairs(("kofxiaoji|xiaoji|xuanfeng|nosxuanfeng|shensu|gongqi"):split("|")) do
				if str:matchOne(askill) then return askill end
			end
			if self:findFriendsByType(sgs.Friend_All) then
				for _, askill in ipairs(("yuanhu|huyuan"):split("|")) do
					if str:matchOne(askill) then return askill end
				end
			end
		end

		if self.player:getWeapon() and str:matchOne("qiangxi") then return "qiangxi" end

		for _, askill in ipairs(("manjuan|xiansi|tuxi|nostuxi|dimeng|haoshi|guanxing|zhiheng|qiaobian|qice|tanhu|noslijian|lijian|shelie|xunxun|luoshen|" ..
								"yongsi|dujin|shude|zhiyan|biyue|yingzi|nosyingzi|qingnang"):split("|")) do
			if str:matchOne(askill) then return askill end
		end

		if self:findFriendsByType(sgs.Friend_Draw) then
			for _, askill in ipairs(("nosrende|rende|anxu|mingce"):split("|")) do
				if str:matchOne(askill) then return askill end
			end
		end

		for _, askill in ipairs(("hongyuan|fangquan|mizhao|quhu|fanjian|nosfanjian|junxing|hengzheng|duanliang|nosguose|guose|baobian|ganlu|" ..
								"tiaoxin|zhaolie|chuanxin|fengshi|nostieji|moukui|liegong|mengjin|tieji|kofliegong|wushuang|niaoxiang|" ..
								"juejing|nosfuhun|nosqianxi|yanxiao|guhuo|nosguhuo|xuanhuo|nosxuanhuo|qiangxi|huangen|nosjujian|lieren|pojun|" ..
								"yishi|nosdanshou|chuli|yinling|qixi|puji|gongxin|shangyi|duoshi|nosjizhi|jizhi|zhaoxin|gongqi|qiangwu|jingce|shengxi|" ..
								"wangxi|luoyi|nosluoyi|jie|anjian|jiangchi|wusheng|longdan|jueqing|xueji|duwu|yinghun|longhun|jiuchi|qingcheng|" ..
								"shuangren|kuangfu|qiaomeng|nosgongqi|wushen|lianhuan|duanxie|qianxi|jujian|shensu|luanji|zhijian|shuangxiong|" ..
								"fuluan|yanyu|qingyi|huoshui|zhoufu|bifa|xinzhan|jieyuan|duanbing|fenxun|guidao|guicai|nosguicai|noszhenlie|" ..
								"noskurou|wansha|lianpo|botu|qiluan|xiaode|qingjian|yicong|zhenwei|heyi|nosshangshi|shangshi|lianying|noslianying|tianyi|" ..
								"xianzhen|qiaoshui|nosjuece|sijian|chunlao|zongshi|keji|paoxiao|kuiwei|yuanhu|huyuan|nosjushou|fenming|huoji|roulin|lihuo|" ..
								"kofxiaoji|xiaoji|xuanfeng|nosxuanfeng|jiushi|shushen|longyin|shoucheng|qicai|dangxian|tannang|mashu|nosqicai|" ..
								"hongyan|zongxuan|nosmieji|suishi|qinyin|tianfu|jinjiu|yicheng|jushou|gongao|nosguixin|yinbing|shenfen"):split("|")) do
			if askill == "yinghun" and not self.player:isWounded() then continue end
			if askill == "hengzheng" and (self.room:alivePlayerCount() <= 3 or self.player:getHp() > 1 or not self.player:isKongcheng()) then continue end
			if askill == "chunlao" and not self.player:getPile("wine"):isEmpty() then continue end
			if str:matchOne(askill) then return askill end
		end
		if str:matchOne("juedi") and not self.player:getPile("yinbing"):isEmpty() then return "juedi" end
	else
		if self.player:getHp() == 1 then
			if str:matchOne("wuhun") then return "wuhun" end
			if str:matchOne("buqu") and self.player:getPile("buqu"):length() <= 3 then return "buqu" end
			for _, askill in ipairs(("wuhun|duanchang|chunlao|jijiu|longhun|jiushi|jiuchi|buyi|huilei|juejing|nosbuqu|zhuiyi"):split("|")) do
				if askill == "chunlao" and self.player:getPile("wine"):isEmpty() then continue end
				if str:matchOne(askill) then return askill end
			end
		end

		if str:matchOne("nosqiuyuan") and self.room:alivePlayerCount() > 2 then return "nosqiuyuan" end

		if self:getAllPeachNum() > 0 or self.player:getHp() > 1 or not self:isWeak() then
			if str:matchOne("guixin") and self.room:alivePlayerCount() > 3 then return "guixin" end
			if str:matchOne("nosyiji") then return "nosyiji" end
			if str:matchOne("yiji") then return "yiji" end
			if str:matchOne("yuce") and not self.player:isKongcheng() then return "yuce" end
			for _, askill in ipairs(("fankui|nosfankui|jieming|chengxiang|noschengxiang|ganglie|vsganglie|nosganglie|enyuan|fangzhu|nosenyuan|duodao|langgu"):split("|")) do
				if str:matchOne(askill) then return askill end
			end
		end

		if self.player:isKongcheng() then
			if str:matchOne("kongcheng") then return "kongcheng" end
		end

		if not self.player:getArmor() then
			for _, askill in ipairs(("yizhong|bazhen"):split("|")) do
				if str:matchOne(askill) then return askill end
			end
		end

		if self.player:getHandcardNum() > self.player:getHp() and self.player:getCards("e"):length() > 0 then
			if str:matchOne("yanzheng") then return "yanzheng" end
		end

		if self.player:getCards("e"):length() > 1 then
			for _, askill in ipairs(sgs.lose_equip_skill:split("|")) do
				if str:matchOne(askill) then return askill end
			end
		end

		if not self.player:faceUp() then
			for _, askill in ipairs(("guixin|jiushi"):split("|")) do
				if str:matchOne(askill) then return askill end
			end
		end

		for _, askill in ipairs(("noswuyan|wuyan|weimu|mingshi|qianhuan|guzheng|luoying|aocai|kanpo|liuli|beige|qingguo|mingzhe|yajiao|" ..
								"yicheng|xiangle|renwang|feiying|longdan"):split("|")) do
			if str:matchOne(askill) then return askill end
		end
		if str:matchOne("kofqingguo") and not self.player:getEquips():isEmpty() then return "kofqingguo" end

		for _, askill in ipairs(("nosyiji|yiji|yuce|fankui|nosfankui|jieming|chengxiang|noschengxiang|ganglie|vsganglie|nosganglie|enyuan|fangzhu|nosenyuan|" ..
								"wangxi|hengjiang|duodao|langgu"):split("|")) do
			if str:matchOne(askill) then return askill end
		end

		for _, askill in ipairs(("huangen|jianxiong|nosjianxiong|jiang|nosqianxun|qianxun|danlao|juxiang|huoshou|zhichi|" ..
								"lirang|qingjian|yicong|wusheng|wushuang|tianxiang|leiji|nosleiji|guhuo|nosguhuo|nosshangshi|shangshi|" ..
								"zhiyu|guidao|guicai|nosguicai|chunlao|jijiu|buyi|nosrenxin|lianying|noslianying|shoucheng|shenxian|sijian|tianming|" ..
								"jieyuan|yanyu|zhendu|xiaoguo|tianfu|shushen|niaoxiang|zhenlie|tiandu|yingyang|noszhenlie"):split("|")) do
			if askill == "chunlao" and self.player:getPile("wine"):isEmpty() then continue end
			if str:matchOne(askill) then return askill end
		end

		if self.player:getCards("e"):length() > 0 then
			for _, askill in ipairs(sgs.lose_equip_skill:split("|")) do
				if str:matchOne(askill) then return askill end
			end
			if str:matchOne("qicai") then return "qicai" end
		end

		if str:matchOne("buqu") and self.player:getPile("buqu"):length() <= 3 then return "buqu" end
		for _, askill in ipairs(("xingshang|weidi|jilei|sijian|nosjizhi|jizhi|anxian|zhuhai|wuhun|hongyan|nosbuqu|zhuiyi|huilei|yanzheng|" ..
								"kofxiaoji|xiaoji|xuanfeng|nosxuanfeng|longhun|jiushi|jiuchi|nosrenxin|nosjiefan|zongshih|zongxuan|kuanggu|kofkuanggu|" ..
								"noszhuikong|lianpo|qiluan|zhaxiang|suishi|gongao|xiaode"):split("|")) do
			if str:matchOne(askill) then return askill end
		end
	end
	for index = #choices, 1, -1 do
		if ("benghuai|wumou|shiyong|yaowu"):match(choices[index]) then
			table.remove(choices, index)
		end
	end
	if not xiaode_choice and #choices > 0 then
		return choices[math.random(1, #choices)]
	end
end
