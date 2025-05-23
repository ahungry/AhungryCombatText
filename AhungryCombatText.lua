local AhuCTConfig = {
   anchors = {
      dmg  = { x = 30,  y = -150 },
      heal = { x = -30,  y = -150 },
   },
   duration = 4,
   fontSize = 16,
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
local stats = {
   heal = {min = 0, max = 0, sum = 0, hits = 0},
   dmg = {min = 0, max = 0, sum = 0, hits = 0}
}

local function getAverage(dmgType)
   local s = stats[dmgType]
   return s.sum / s.hits
end

local function getFirstQuartile(dmgType)
   local s = stats[dmgType]
   local avg = getAverage(dmgType)
   return (avg - s.min) / 2
end

local function getThirdQuartile(dmgType)
   local s = stats[dmgType]
   local avg = getAverage(dmgType)
   return (s.max - avg) / 2
end

local function incStats(dmgType, amount)
   local m = stats[dmgType]
   m.hits = m.hits + 1
   m.sum = m.sum + amount
   if amount > m.max then
      m.max = amount
   end
   if amount > m.min or m.min == 0 then
      m.min = amount
   end
end

local function getPercent(amount, maxHealth)
   local percent = math.floor((amount/maxHealth)*1000) / 10
   return percent
end

local function getPercentHeal(amount, destName)
   if not destName then
      return nil
   end
   local maxHealth = UnitHealthMax(destName)
   if maxHealth == 0 then
      return nil
   end
   incStats("heal", amount)
   return getPercent(amount, maxHealth)
end

local function getPercentDmg(amount, destGUID)
   if not destGUID then
      return nil
   end
   local target = UnitTokenFromGUID(destGUID)
   if not target then
      return nil
   end
   local maxHealth = UnitHealthMax(target)
   if maxHealth == 0 then
      return nil
   end
   incStats("dmg", amount)
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

function showText(text, amount, color, dmgType)
   dmgType = dmgType or "dmg"
   local anchor = AhuCTConfig.anchors[dmgType] or { x=0, y=0 }
   -- local anchor = {x=math.random(-100,100), y=math.random(-100,100)}
   local fontSize = AhuCTConfig.fontSize
   local duration = AhuCTConfig.duration
   local average = getAverage(dmgType)
   local firstQuartile = getFirstQuartile(dmgType)
   local thirdQuartile = getThirdQuartile(dmgType)
   local anchorY = anchor.y

   if amount >= thirdQuartile then
      fontSize = math.floor(fontSize * 1.5)
      duration = math.floor(duration * 2)
      anchorY = anchorY + 0
   elseif amount >= average then
      fontSize = math.floor(fontSize * 1.25)
      duration = math.floor(duration * 1.5)
      anchorY = anchorY - 20
   elseif amount >= firstQuartile then
      fontSize = math.floor(fontSize * 1)
      duration = math.floor(duration * 1)
      anchorY = anchorY - 40
   else
      fontSize = math.floor(fontSize * 0.75)
      duration = math.floor(duration * 0.5)
      anchorY = anchorY - 60
   end

   local f = CreateFrame("Frame", nil, UIParent)
   f:SetSize(200, 50)
   f:SetPoint("CENTER", UIParent, "CENTER", anchor.x, anchorY)

   local finalText, iconID, texW, texH, atlasMode = getTexture(tostring(text))
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
   local xOffset = -600
   if dmgType == "dmg" then
      xOffset = 600
   end
   local anim = f:CreateAnimationGroup()

   local move = anim:CreateAnimation("Translation")
   -- move:SetOffset(xOffset, -300)
   move:SetOffset(xOffset, 0)
   move:SetDuration(duration)
   move:SetSmoothing("OUT")

   local fadeOut = anim:CreateAnimation("Alpha")
   fadeOut:SetFromAlpha(1)
   fadeOut:SetToAlpha(0)
   local half = duration / 2
   fadeOut:SetStartDelay(half)
   fadeOut:SetDuration(half)
   fadeOut:SetSmoothing("OUT")

   anim:SetScript(
      "OnFinished",
      function()
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

AhuCTFrame:SetScript(
   "OnEvent",
   function(_, event, ...)
      if event == "ADDON_LOADED" then
         local addonName = ...
         if addonName == "AhungryCombatText" then
            -- Can load config here
         end

      elseif event == "PLAYER_ENTERING_WORLD" then
         myGUID = UnitGUID("player")
         stats = {
            heal = {min = 0, max = 0, sum = 0, hits = 0},
            dmg = {min = 0, max = 0, sum = 0, hits = 0}
         }

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
            local text = getPercentHeal(amount, destName)
            if not text then
               return
            end

            if spellID then
               local iconPath = C_Spell.GetSpellTexture(spellID)
               if iconPath then
                  text = text .. " |T" .. iconPath .. ":16:16:0:0|t"
               end
            end

            showText(text, amount, AhuCTConfig.color.healing, "heal")
            return
         end

         -- DoT
         if subEvent == "SPELL_PERIODIC_DAMAGE" and amount and amount > 0 then
            local text = getPercentDmg(amount, destGUID)
            if not text then
               return
            end

            if spellID then
               local iconPath = C_Spell.GetSpellTexture(spellID)
               if iconPath then
                  text = text .. " |T" .. iconPath .. ":16:16:0:0|t"
               end
            end

            showText(text, amount, AhuCTConfig.color.dot, "dmg")
            return
         end

         -- Destructuring the events, the amount for an auto attack is in a diff slot
         if subEvent == "SWING_DAMAGE" and amount == nil and spellID and spellID > 0 then
            local text = getPercentDmg(spellID, destGUID)
            return showText(text, spellID, AhuCTConfig.color.default, "dmg")
         end

         if (subEvent == "SWING_DAMAGE" or subEvent == "SPELL_DAMAGE" or subEvent == "RANGE_DAMAGE")
            and amount and amount > 0 then

            if critical then
               local text = getPercentDmg(amount, destGUID)
               if not text then
                  return
               end

               if (subEvent ~= "SWING_DAMAGE") and spellID then
                  local iconPath = C_Spell.GetSpellTexture(spellID)
                  if iconPath then
                     text = text .. " |T" .. iconPath .. ":16:16:0:0|t"
                  end
               end

               showText(text, amount, AhuCTConfig.color.crits, "dmg")
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

            local text = getPercentDmg(amount, destGUID)
            if not text then
               return
            end

            if (subEvent ~= "SWING_DAMAGE") and spellID then
               local iconPath = C_Spell.GetSpellTexture(spellID)
               if iconPath then
                  text = text .. " |T" .. iconPath .. ":16:16:0:0|t"
               end
            end

            showText(text, amount, AhuCTConfig.color[dmgType], "dmg")
         end
      end
   end
)

SLASH_AhuCT1 = "/ahuct"
function SlashCmdList.AhuCT(msg)
   print("|cffff0000[AhuCT]: Unknown option|r")
end
