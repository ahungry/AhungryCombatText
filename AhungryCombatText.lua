local AhuCTConfig = {
    anchors = {
        damage  = { x = 300,  y = -150 },
        healing = { x = -300,  y = -150 },
    },
    duration = 4,
    fontSize = 24,
    fontFile = "Fonts\\FRIZQT__.TTF",
    color = {
       default = {1, 1, 1},
       absorb  = {0.7, 0.7, 1},
       arcane  = {1, 0.2, 1},
       crits   = {1, 1, 0},
       dot     = {1, 0, 0.5},
       fire    = {1, 0.5, 0},
       frost   = {0.4, 0.8, 1},
       healing = {0, 1, 0},
       holy    = {1, 1, 0.6},
       nature  = {0.3, 1, 0.3},
       shadow  = {0.6, 0.2, 0.8},
    }
}

local AhuCTFrame = CreateFrame("Frame", "AhuCTFrame", UIParent)
local myGUID = nil
local sumHeal = 0
local sumDmg = 0
local hitsHeal = 0
local hitsDmg = 0

-- This would grow indefinitely
-- local function getAverage()
--    local sum = 0
--    local total = 0
--    for k,v in pairs(hits) do
--       sum = sum + v
--       total = total + 1
--    end
--    return sum/total
-- end
local function getAverageHeal()
   return sumHeal/hitsHeal
end

local function getAverageDmg()
   return sumDmg/hitsDmg
end

local function getPercent(amount, maxHealth)
   local percent = math.floor((amount/maxHealth)*1000) / 10
   -- if percent > 1 then
   --    percent = math.floor(percent)
   -- else
   --    -- fmt: .8
   --    percent = string.sub(string.format("%.1f", percent), 2)
   -- end
   return percent
end

local function getHealPercent(amount, destName)
   hitsHeal = hitsHeal + 1
   sumHeal = sumHeal + amount
   local maxHealth = UnitHealthMax(destName)
   -- Still not sure how this comes through, but it does sometimes
   if maxHealth == 0 then
      return "+"
   end
   return getPercent(amount, maxHealth)
end

local function getDmgPercent(amount, destGUID)
   hitsDmg = hitsDmg + 1
   sumDmg = sumDmg + amount
   local maxHealth = UnitHealthMax(UnitTokenFromGUID(destGUID))
   return getPercent(amount, maxHealth)
end

local function getTexture(inText)
    if not inText then return inText end

    local tex, w, h = inText:match("|T([^:]+):(%d+):(%d+).-|t")
    if tex then
        local outText = inText:gsub("|T[^|]+|t", "")
        return outText, tex, tonumber(w), tonumber(h), false
    end

    local atlas, w2, h2 = inText:match("|A([^:]+):(%d+):(%d+)|a")
    if atlas then
        local outText = inText:gsub("|A[^|]+|a", "")
        return outText, atlas, tonumber(w2), tonumber(h2), true
    end

    return inText
end

function showText(text, amount, color, anchorType)
    anchorType = anchorType or "damage"
    local anchor = AhuCTConfig.anchors[anchorType] or { x=0, y=0 }
    -- local anchor = {x=math.random(-100,100), y=math.random(-100,100)}
    local fontSize = AhuCTConfig.fontSize
    local duration = AhuCTConfig.duration
    local average = 0

    if anchorType == "damage" then
       average = getAverageDmg()
    else
       average = getAverageHeal()
    end

    if amount >= average then
       fontSize = math.floor(fontSize * 1.5)
       duration = math.floor(duration * 2)
    else
       fontSize = math.floor(fontSize / 1.5)
       duration = math.floor(duration / 2)
    end

    local f = CreateFrame("Frame", nil, UIParent)
    f:SetSize(200, 50)
    f:SetPoint("CENTER", UIParent, "CENTER", anchor.x, anchor.y)

    local finalText, iconID, texW, texH, atlasMode = getTexture(text)
    finalText = finalText.."%"

    local fs = f:CreateFontString(nil, "OVERLAY")
    fs:SetFont(AhuCTConfig.fontFile, fontSize, "OUTLINE")
    fs:SetTextColor(unpack(color))
    fs:SetText(finalText or text)
    fs:SetPoint("CENTER", f, "CENTER")

    if iconID then
        local icon = f:CreateTexture(nil, "OVERLAY")
        icon:SetPoint("RIGHT", fs, "LEFT", -2, 0)

        local sizeratio = fontSize / 16
        local w = (texW and texW * sizeratio) or 16
        local h = (texH and texH * sizeratio) or 16
        icon:SetSize(w, h)

        if atlasMode then
            icon:SetAtlas(iconID)
        else
            icon:SetTexture(iconID)
        end
    end

    -- Animation
    local xOffset = -50
    if anchorType == "damage" then
       xOffset = 50
    end
    local anim = f:CreateAnimationGroup()

    local move = anim:CreateAnimation("Translation")
    -- move:SetOffset(0, AhuCTConfig.animation.moveOffset)
    move:SetOffset(xOffset, -300)
    -- move:SetOffset(math.random(-200,200), math.random(-200,200))
    move:SetDuration(duration)
    move:SetSmoothing("OUT")

    local fadeOut = anim:CreateAnimation("Alpha")
    fadeOut:SetFromAlpha(1)
    fadeOut:SetToAlpha(0)
    local half = duration / 2
    fadeOut:SetStartDelay(half)
    fadeOut:SetDuration(half)
    fadeOut:SetSmoothing("OUT")

    anim:SetScript("OnFinished", function()
        f:Hide()
        f:SetParent(nil)
    end)

    anim:Play()
end

-- Events
AhuCTFrame:RegisterEvent("ADDON_LOADED")
AhuCTFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
AhuCTFrame:RegisterEvent("PLAYER_LOGOUT")
AhuCTFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

AhuCTFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...
        if addonName == "AhungryCombatText" then
           -- Can load config here
        end

    elseif event == "PLAYER_ENTERING_WORLD" then
        myGUID = UnitGUID("player")
        hits = 0
        sum = 0

    elseif event == "PLAYER_LOGOUT" then
       -- can save config vars here

    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local timestamp,
              subEvent,
              hideCaster,
              sourceGUID,
              sourceName,
              sourceFlags,
              sourceRaidFlags,
              destGUID,
              destName,
              destFlags,
              destRaidFlags,
              spellID,
              spellName,
              spellSchool,
              amount,
              overkill,
              school,
              resisted,
              blocked,
              absorbed,
              critical,
              glancing,
              crushing,
              isOffHand = CombatLogGetCurrentEventInfo()

        if sourceGUID ~= myGUID then
            return
        end

        if (subEvent == "SPELL_HEAL" or subEvent == "SPELL_PERIODIC_HEAL") and amount and amount > 0 then
            local text = getHealPercent(amount, destName)

            if spellID then
                local iconPath = C_Spell.GetSpellTexture(spellID)
                if iconPath then
                    text = text .. " |T" .. iconPath .. ":16:16:0:0|t"
                end
            end

            showText(text, amount, AhuCTConfig.color.healing, "healing")
            return
        end

        -- DoT
        if subEvent == "SPELL_PERIODIC_DAMAGE" and amount and amount > 0 then
            local text = getDmgPercent(amount, destGUID)

            if spellID then
               local iconPath = C_Spell.GetSpellTexture(spellID)
               if iconPath then
                  text = text .. " |T" .. iconPath .. ":16:16:0:0|t"
               end
            end

            showText(text, amount, AhuCTConfig.color.dot, "damage")
            return
        end

        if (subEvent == "SWING_DAMAGE" or subEvent == "SPELL_DAMAGE" or subEvent == "RANGE_DAMAGE")
           and amount and amount > 0 then

           if critical then
              local text = getDmgPercent(amount, destGUID)

              if (subEvent ~= "SWING_DAMAGE") and spellID then
                 local iconPath = C_Spell.GetSpellTexture(spellID)
                 if iconPath then
                    text = text .. " |T" .. iconPath .. ":16:16:0:0|t"
                 end
              end

              showText(text, amount, AhuCTConfig.color.crits, "damage")
              return
            end

            local dmgType = "default"
            if spellSchool == 4 then dmgType = "fire"
            elseif spellSchool == 8 then dmgType = "nature"
            elseif spellSchool == 16 then dmgType = "frost"
            elseif spellSchool == 32 then dmgType = "shadow"
            elseif spellSchool == 64 then dmgType = "arcane"
            elseif spellSchool == 2 then dmgType = "holy"
            end

            local text = getDmgPercent(amount, destGUID)

            if (subEvent ~= "SWING_DAMAGE") and spellID then
               local iconPath = C_Spell.GetSpellTexture(spellID)
               if iconPath then
                  text = text .. " |T" .. iconPath .. ":16:16:0:0|t"
               end
            end

            showText(text, amount, AhuCTConfig.color[dmgType], "damage")
        end
    end
end)

SLASH_AhuCT1 = "/ahuct"
function SlashCmdList.AhuCT(msg)
   print("|cffff0000[AhuCT]: Unknown option|r")
end
