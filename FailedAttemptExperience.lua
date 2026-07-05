--[[
	Anri's Failed Attempt Experience
		version 1.0.0 (for TES3MP 0.8.1)
	
	DESCRIPTION:
        - Grants XP upon failed actions for Security, Armorer, Enchant, Alchemy, Persuasion*
        - Grants XP on any successful barter with a merchant (including non-bargains)

    CONFIG:
        - `skillGrantEnabled`: Enable/disable for certain skills.
        - `progressGrant`: XP values to grant upon failed actions. This is not 1-1 with the ingame 0/100 progress meter, as far as I know.
        - `debugChatGains`: Enable chat debug messages.
    KNOWN ISSUES:
        - Bonus XP can overflow past 100 progress without triggering a skillup. XP granted from successful actions will trigger a skillup as expected.
        - Persuasion XP is granted upon opening the Persuasion submenu (I couldn't find an event on any Persuasion action/Disposition change)
        - Security XP is granted upon equipping a lockpick. I can probably compare `item.charge`'s but that's a TODO for now
	
	INSTALLATION:
		1) Place this file as `FailedAttemptExperience.lua` inside your TES3MP servers `server\scripts\custom` folder.
		2) Open your `customScripts.lua` file in a text editor. 
				(It can be found in `server\scripts` folder.)
		3) Add the below line to your `customScripts.lua` file:
				require("custom.FailedAttemptExperience")
		4) Be sure there are no `--` symbols to the left of it, else it will not work.
		5) Save `customScripts.lua` and restart your server.
	
	VERSION HISTORY:
		1.0.0 (07/04/2024)		- Initial public release.
		
	My Public TES3MP 0.8.1 Scripts Github:
        https://github.com/nguyen-darianhuy/Morrowind-TES3MP-0.8.1-plugins
--]]

local FailedAttemptExperience = {}

FailedAttemptExperience.config = {
    debugChatGains = false,
    skillGrantEnabled = {
        Security = true,
        Alchemy = true,
        Enchant = true,
        Armorer = true,
        Speechcraft = true,
        Mercantile = true
    },
    progressGrant = {
        Security = 3,
        Alchemy = 1,
        Enchant = 5,
        Armorer = 0.4,
        Speechcraft = 1,
        Mercantile = 2
    }
}

local grantSkillProgress

local function isLoggedIn(pid)
    return Players[pid] ~= nil and Players[pid]:IsLoggedIn()
end

local function isSecurityEquipment(item)
    if item == nil or item.refId == nil then
        return false
    end

    local normalizedRefId = string.lower(item.refId)

    return string.find(normalizedRefId, "pick", 1, true) ~= nil or
        string.find(normalizedRefId, "probe", 1, true) ~= nil or
        string.find(normalizedRefId, "skeleton_key", 1, true) ~= nil
end

local function handleSoundSkillGrants(pid, senderSoundId)
    if senderSoundId == nil then
        return
    end

    local normalizedSoundId = string.lower(senderSoundId)

    if FailedAttemptExperience.config.skillGrantEnabled.Armorer and normalizedSoundId == "repair fail" then
        local grant = FailedAttemptExperience.config.progressGrant.Armorer or 0
        grantSkillProgress(pid, "Armorer", grant, normalizedSoundId)
    end

    if FailedAttemptExperience.config.skillGrantEnabled.Alchemy and string.find(normalizedSoundId, "potion fail", 1, true) ~= nil then
        local grant = FailedAttemptExperience.config.progressGrant.Alchemy or 0
        grantSkillProgress(pid, "Alchemy", grant, normalizedSoundId)
    end

    if FailedAttemptExperience.config.skillGrantEnabled.Enchant and normalizedSoundId == "enchant fail" then
        local grant = FailedAttemptExperience.config.progressGrant.Enchant or 0
        grantSkillProgress(pid, "Enchant", grant, normalizedSoundId)
    end
end

local function sendDebugGain(pid, message)
    if not FailedAttemptExperience.config.debugChatGains then
        return
    end

    if isLoggedIn(pid) then
        tes3mp.SendMessage(pid, "[FailedAttemptXP][debug] " .. message .. "\n", false)
    end
end

grantSkillProgress = function(pid, skillName, grant, reason)
    if grant == nil or grant <= 0 then
        return false
    end

    local skillId = tes3mp.GetSkillId(skillName)
    local currentProgress = nil

    if Players[pid].data ~= nil and Players[pid].data.skills ~= nil and
        Players[pid].data.skills[skillName] ~= nil then
        currentProgress = Players[pid].data.skills[skillName].progress
    end

    if currentProgress == nil then
        currentProgress = tes3mp.GetSkillProgress(pid, skillId)
    end

    if currentProgress < 0 then
        currentProgress = 0
    end

    local newProgress = currentProgress + grant

    if newProgress <= currentProgress then
        return false
    end

    tes3mp.SetSkillProgress(pid, skillId, newProgress)
    tes3mp.SendSkills(pid)

    if Players[pid].data ~= nil and Players[pid].data.skills ~= nil and
        Players[pid].data.skills[skillName] ~= nil then
        Players[pid].data.skills[skillName].progress = newProgress
    end

    local reasonText = reason or "unspecified"
    sendDebugGain(pid, skillName .. " +" .. tostring(grant) .. " (" .. tostring(currentProgress) ..
        " -> " .. tostring(newProgress) .. ") reason=" .. reasonText)

    return true
end

FailedAttemptExperience.OnObjectMiscellaneous = function(eventStatus, pid, cellDescription, objects)
    if eventStatus.validCustomHandlers == false then return end
    if not isLoggedIn(pid) then return end

    if FailedAttemptExperience.config.skillGrantEnabled.Mercantile == false then
        return
    end

    local foundMerchantGoldChange = false

    for _, object in pairs(objects) do
        if object.goldPool ~= nil and object.goldPool > 0 then
            foundMerchantGoldChange = true
            break
        end
    end

    if foundMerchantGoldChange then
        local grant = FailedAttemptExperience.config.progressGrant.Mercantile or 0
        grantSkillProgress(pid, "Mercantile", grant, "barter complete")
    end
end

FailedAttemptExperience.OnObjectSound = function(eventStatus, pid, _, _, targetPlayers)
    if eventStatus.validCustomHandlers == false then return end
    if not isLoggedIn(pid) then return end

    local senderSoundId = nil

    if targetPlayers ~= nil and targetPlayers[pid] ~= nil then
        senderSoundId = targetPlayers[pid].soundId
    end

    handleSoundSkillGrants(pid, senderSoundId)
end

FailedAttemptExperience.OnPlayerEquipment = function(eventStatus, pid, playerPacket)
    if eventStatus.validCustomHandlers == false then return end
    if not isLoggedIn(pid) then return end
    if playerPacket == nil or playerPacket.equipment == nil then return end

    if FailedAttemptExperience.config.skillGrantEnabled.Security == false then
        return
    end

    --- If holding Security equipment, handle Security skill grants.
    for slot, item in pairs(playerPacket.equipment) do
        if slot == enumerations.equipment.CARRIED_RIGHT or slot == enumerations.equipment.CARRIED_LEFT then
            if isSecurityEquipment(item) then
                local grant = FailedAttemptExperience.config.progressGrant.Security or 0
                grantSkillProgress(pid, "Security", grant, "lockpick/probe equip")
                return
            end
        end
    end
end

FailedAttemptExperience.OnObjectDialogueChoice = function(eventStatus, pid, cellDescription, objects)
    if eventStatus.validCustomHandlers == false then return end
    if not isLoggedIn(pid) then return end

    if FailedAttemptExperience.config.skillGrantEnabled.Speechcraft == false then
        return
    end

    -- Treat opening the persuasion submenu itself as the trigger.
    for _, object in pairs(objects) do
        if object.dialogueChoiceType == enumerations.dialogueChoice.PERSUASION then
            local grant = FailedAttemptExperience.config.progressGrant.Speechcraft or 0

            grantSkillProgress(pid, "Speechcraft", grant, "persuasion submenu opened")
        end
    end
end


customEventHooks.registerHandler("OnObjectDialogueChoice", FailedAttemptExperience.OnObjectDialogueChoice)
customEventHooks.registerHandler("OnObjectMiscellaneous", FailedAttemptExperience.OnObjectMiscellaneous)
customEventHooks.registerHandler("OnObjectSound", FailedAttemptExperience.OnObjectSound)
customEventHooks.registerHandler("OnPlayerEquipment", FailedAttemptExperience.OnPlayerEquipment)

tes3mp.LogMessage(enumerations.log.INFO, "[FailedAttemptXP] Loaded")

return FailedAttemptExperience