sgs.ai_skill_invoke.cv_caopi = function(self, data)
	return math.random(0, 2) == 0
end

sgs.ai_skill_invoke.cv_zhugeliang = function(self, data)
	if math.random(0, 2) > 0 then return false end
	if math.random(0, 4) == 0 then sgs.ai_skill_choice.cv_zhugeliang = "tw_zhugeliang"
	else sgs.ai_skill_choice.cv_zhugeliang = "heg_zhugeliang" end
	return true
end

sgs.ai_skill_invoke.cv_nos_huangyueying = function(self, data)
	if math.random(0, 2) > 0 then return false end
	if math.random(0, 4) == 0 then sgs.ai_skill_choice.cv_nos_huangyueying = "tw_huangyueying"
	else sgs.ai_skill_choice.cv_nos_huangyueying = "heg_huangyueying" end
	return true
end

sgs.ai_skill_invoke.cv_sunshangxiang = function(self, data)
	local lord = self.room:getLord()
	if lord and not self.player:getGeneral2Name() == "sunshangxiang" and lord:hasLordSkill("shichou") then
		return self:isFriend(lord)
	end
	return lord:getKingdom() == "shu"
end

sgs.ai_skill_invoke.cv_caiwenji = function(self, data)
	local lord = self.room:getLord()
	if lord and not self.player:getGeneral2Name() == "caiwenji" and lord:hasLordSkill("xueyi") then
		return not self:isFriend(lord)
	end
	return lord:getKingdom() == "wei"
end

sgs.ai_skill_invoke.cv_machao = function(self, data)
	local lord = self.room:getLord()
	if lord and not self.player:getGeneral2Name() == "machao"
		and ((lord:hasLordSkill("xueyi") and self:isFriend(lord))
			or (self.player:getKingdom() == "shu" and lord:hasLordSkill("shichou") and not self:isFriend(lord))
			or (lord:getKingdom() == "qun" and not lord:hasLordSkill("xueyi"))) then
		sgs.ai_skill_choice.cv_machao = "sp_machao"
		return true
	end
	if math.random(0, 2) == 0 then
		sgs.ai_skill_choice.cv_machao = "tw_machao"
		return true
	end
end

sgs.ai_skill_invoke.cv_diaochan = function(self, data)
	if math.random(0, 2) == 0 then return false
	elseif math.random(0, 3) == 0 then sgs.ai_skill_choice.cv_diaochan = "tw_diaochan"
	elseif math.random(0, 3) == 0 then sgs.ai_skill_choice.cv_diaochan = "heg_diaochan"
	else sgs.ai_skill_choice.cv_diaochan = "sp_diaochan" end
	return true
end

sgs.ai_skill_invoke.cv_pangde = sgs.ai_skill_invoke.cv_caiwenji
sgs.ai_skill_invoke.cv_jiaxu = sgs.ai_skill_invoke.cv_caiwenji

sgs.ai_skill_invoke.cv_yuanshu = sgs.ai_skill_invoke.cv_caopi
sgs.ai_skill_invoke.cv_nos_zhaoyun = sgs.ai_skill_invoke.cv_caopi
sgs.ai_skill_invoke.cv_ganning = sgs.ai_skill_invoke.cv_caopi
sgs.ai_skill_invoke.cv_shenlvbu = sgs.ai_skill_invoke.cv_caopi

sgs.ai_skill_invoke.cv_daqiao = function(self, data)
	if math.random(0, 3) >= 1 then return false
	elseif math.random(0, 4) == 0 then sgs.ai_skill_choice.cv_daqiao = "tw_daqiao"
	else sgs.ai_skill_choice.cv_daqiao = "wz_daqiao" end
	return true
end

sgs.ai_skill_invoke.cv_xiaoqiao = function(self, data)
	if math.random(0, 3) >= 1 then return false
	elseif math.random(0, 4) == 0 then sgs.ai_skill_choice.cv_xiaoqiao = "wz_xiaoqiao"
	elseif math.random(0, 2) > 0 then sgs.ai_skill_choice.cv_xiaoqiao = "heg_xiaoqiao"
	else sgs.ai_skill_choice.cv_xiaoqiao = "sp_heg_xiaoqiao" end
	return true
end

sgs.ai_skill_invoke.cv_nos_zhouyu = function(self, data)
	if math.random(0, 3) >= 1 then return false
	elseif math.random(0, 4) == 0 then sgs.ai_skill_choice.cv_zhouyu = "heg_zhouyu"
	else sgs.ai_skill_choice.cv_zhouyu = "sp_heg_zhouyu" end
	return true
end

sgs.ai_skill_invoke.cv_zhenji = function(self, data)
	if math.random(0, 3) >= 2 then return false
	elseif math.random(0, 4) == 0 then sgs.ai_skill_choice.cv_zhenji = "sp_zhenji"
	elseif math.random(0, 4) == 0 then sgs.ai_skill_choice.cv_zhenji = "tw_zhenji"
	else sgs.ai_skill_choice.cv_zhenji = "heg_zhenji" end
	return true
end

sgs.ai_skill_invoke.cv_lvbu = function(self, data)
	if math.random(0, 3) >= 1 then return false
	elseif math.random(0, 4) == 0 then sgs.ai_skill_choice.cv_lvbu = "tw_lvbu"
	else sgs.ai_skill_choice.cv_lvbu = "heg_lvbu" end
	return true
end

sgs.ai_skill_invoke.cv_huanggai = function(self, data)
	return math.random(0, 4) == 0
end

sgs.ai_skill_invoke.cv_nos_zhangliao = sgs.ai_skill_invoke.cv_huanggai
sgs.ai_skill_invoke.cv_nos_luxun = sgs.ai_skill_invoke.cv_huanggai
sgs.ai_skill_invoke.cv_nos_guojia = sgs.ai_skill_invoke.cv_huanggai
sgs.ai_skill_invoke.cv_zhugeke = sgs.ai_skill_invoke.cv_huanggai
sgs.ai_skill_invoke.cv_yuejin = sgs.ai_skill_invoke.cv_huanggai
sgs.ai_skill_invoke.cv_madai = sgs.ai_skill_invoke.cv_huanggai
sgs.ai_skill_invoke.cv_panfeng = sgs.ai_skill_invoke.cv_huanggai
sgs.ai_skill_invoke.cv_xushu = sgs.ai_skill_invoke.cv_huanggai
sgs.ai_skill_invoke.cv_fazheng = sgs.ai_skill_invoke.cv_huanggai

sgs.ai_skill_invoke.cv_zhugejin = function(self, data)
	return math.random(0, 4) > 1
end