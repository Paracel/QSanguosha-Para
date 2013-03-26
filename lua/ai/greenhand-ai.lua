sgs.ai_skill_playerchosen.gh_tuxi = function(self, targets)
	local cardstr = sgs.ai_skill_use["@@tuxi"](self, "@tuxi")
	if cardstr:match("->") then
		local targetstr = cardstr:split("->")[2]:split("+")
		if #targetstr > 0 then
			local target = self:findPlayerByObjectName(targetstr[1])
			return target
		end
	end
	return nil
end

sgs.ai_playerchosen_intention.gh_tuxi = function(from, to)
	local lord = self.room:getLord()
	if sgs.evaluatePlayerRole(from) == "neutral" and sgs.evaluatePlayerRole(to) == "neutral"
		and lord and not lord:isKongcheng()
		and not (lord:hasSkills("kongcheng|zhiji") and lord:getHandcardNum() == 1)
		and not (lord:hasSkill("lianying") and lord:getHandcardNum() == 1) and not lord:hasSkills("tuntian+zaoxian") and from:aliveCount() >= 4 then
		sgs.updateIntention(from, lord, -35)
		return
	end
	if from:getState() == "online" then
		if (to:hasSkills("kongcheng|zhiji|lianying") and to:getHandcardNum() == 1) or to:hasSkills("tuntian+zaoxian") then
		else
			sgs.updateIntention(from, to, 80)
		end
	else
		local intention = from:hasFlag("tuxi_isfriend_" .. to:objectName()) and -5 or 80
		sgs.updateIntention(from, to, intention)
	end
end

sgs.ai_chaofeng.gh_zhangliao = 4
