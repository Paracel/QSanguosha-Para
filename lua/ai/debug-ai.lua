sgs.ai_debug_func[sgs.EventPhaseStart] = function(self, player, data)
	if player:getPhase() == sgs.Player_RoundStart then
		debugFunc(self, self.room, player, data)
	end
end

sgs.ai_debug_func[sgs.CardUsed] = function(self, player, data)
	local card = data:toCardUse().card
	if card:isKindOf("Peach") or card:isKindOf("Nullification") then
		debugFunc(self, self.room, player, data)
	end
end

function debugFunc(self, room, player, data)
	local owner = room:getOwner()
	local choices = { "showVisiblecards", "showHandcards", "objectiveLevel", "getDefenseSlash" }
	local debugmsg = function(fmt, ...)
		if type(fmt) == "boolean" then fmt = fmt and "true" or "false" end
		local msg = string.format(fmt, ...)
		player:speak(msg)
	logmsg("ai.html", "<pre>" .. msg .. "</pre>")
	end

	local players = sgs.QList2Table(room:getAlivePlayers())
	repeat
		local choice = room:askForChoice(owner, "aidebug", "cancel+" .. table.concat(choices, "+"))
		if choice == "cancel" then break end
		if choice == "showVisiblecards" then
			debugmsg(" ")
			debugmsg("===================")
			debugmsg("查看已知牌。当前角色: %s[%s]", sgs.Sanguosha:translate(player:getGeneralName()), sgs.Sanguosha:translate(player:getRole()))
			for i = 1, #players, 1 do
				local msg = string.format("%s已知牌:", sgs.Sanguosha:translate(players[i]:getGeneralName()))
				local cards = sgs.QList2Table(players[i]:getHandcards())
				for _, card in ipairs(cards) do
					local flag = string.format("%s_%s_%s", "visible", player:objectName(), players[i]:objectName())
					if card:hasFlag("visible") or card:hasFlag(flag) then
						msg = msg .. card:getLogName() .. ", "
					end
				end
				debugmsg(msg)
			end
		end
		if choice == "showHandcards" then
			debugmsg(" ")
			debugmsg("===================")
			debugmsg("查看手牌。当前角色: %s[%s]", sgs.Sanguosha:translate(player:getGeneralName()), sgs.Sanguosha:translate(player:getRole()))
			for i = 1, #players, 1 do
				local msg = string.format("%s手牌:", sgs.Sanguosha:translate(players[i]:getGeneralName()))
				local cards = sgs.QList2Table(players[i]:getHandcards())
				for _, card in ipairs(cards) do
					msg = msg .. card:getLogName() .. ", "
				end
				debugmsg(msg)
			end
		end
		if choice == "objectiveLevel" then
			debugmsg(" ")
			debugmsg("============%s(%.1f)", sgs.gameProcess(room), sgs.gameProcess(room, 1))
			debugmsg("查看身份关系。当前角色: %s[%s]", sgs.Sanguosha:translate(player:getGeneralName()), sgs.Sanguosha:translate(player:getRole()))
			for i = 1, #players, 1 do
				local level = self:objectiveLevel(players[i])
				local rel = level > 0 and "敌对" or (level < 0 and "友好" or "中立")
				rel = rel .. " " .. level

				debugmsg("%s[%s]: %d:%d:%d %s",
						sgs.Sanguosha:translate(players[i]:getGeneralName()),
						sgs.Sanguosha:translate(sgs.evaluatePlayerRole(players[i])),
						sgs.role_evaluation[players[i]:objectName()]["rebel"],
						sgs.role_evaluation[players[i]:objectName()]["loyalist"],
						sgs.role_evaluation[players[i]:objectName()]["renegade"],
						rel)
			end
		end
		if choice == "getDefenseSlash" then
			debugmsg(" ")
			debugmsg("===================")
			debugmsg("查看对【杀】防御值。当前角色: %s[%s]", sgs.Sanguosha:translate(player:getGeneralName()), sgs.Sanguosha:translate(player:getRole()))
			for i = 1, #players, 1 do
				debugmsg("%s:%.2f", sgs.Sanguosha:translate(players[i]:getGeneralName()), sgs.getDefenseSlash(players[i]))
			end
		end
	until false
end

function logmsg(fname, fmt, ...)
	local fp = io.open(fname, "ab")
	if type(fmt) == "boolean" then fmt = fmt and "true" or "false" end
	fp:write(fmt .. "\r\n", ...)
	fp:close()
end

function SmartAI:log(outString)
	self.room:output(outString)
end

local cardparse = sgs.Card_Parse
function sgs.Card_Parse(str)
	if not str then global_room:writeToConsole(debug.traceback()) end
	if type(str) ~= "string" and type(str) ~= "number" and str.toString() then
		global_room:writeToConsole(str:toString())
	end
	return cardparse(str)
end
