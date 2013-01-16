sgs.ai_skill_invoke.gh_tuxi = function(self, data)
	return true
end

sgs.ai_skill_playerchosen.gh_tuxi = function(self, targets)
	local targetlist = sgs.QList2Table(targets)
	self:sort(targetlist, "defense")
	local target
	for _, player in ipairs(targetlist) do
		if self:isEnemy(player) and (not target:getHandcardNum() == 1 and self:needKongcheng(target)) then
			return target
		end
	end
	return targetlist[1]
end

sgs.ai_playerchosen_intention.gh_tuxi = 80
sgs.ai_chaofeng.gh_zhangliao = 4
