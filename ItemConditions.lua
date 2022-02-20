LootReserve = LootReserve or { };
LootReserve.ItemConditions = LootReserve.ItemConditions or { };

local DefaultConditions =
{
    Hidden    = nil,
    Custom    = nil,
    Faction   = nil,
    ClassMask = nil,
    Limit     = nil,
};

function LootReserve.ItemConditions:Get(itemID, server)
    if server and LootReserve.Server.CurrentSession then
        return LootReserve.Server.CurrentSession.ItemConditions[itemID] or LootReserve.Data.ItemConditions[itemID];
    elseif server then
        return LootReserve.Server:GetNewSessionItemConditions()[itemID] or LootReserve.Data.ItemConditions[itemID];
    else
        return LootReserve.Client.ItemConditions[itemID] or LootReserve.Data.ItemConditions[itemID];
    end
end

function LootReserve.ItemConditions:Make(itemID, server)
    if server and LootReserve.Server.CurrentSession then
        LootReserve:ShowError("Cannot edit loot during an active session");
        return nil;
    elseif server then
        local container = LootReserve.Server:GetNewSessionItemConditions();
        local conditions = container[itemID];
        if not conditions then
            conditions = LootReserve:Deepcopy(LootReserve.Data.ItemConditions[itemID]);
            if not conditions then
                conditions = LootReserve:Deepcopy(DefaultConditions);
            end
            container[itemID] = conditions;
        end
        return conditions;
    else
        LootReserve:ShowError("Cannot edit loot on client");
        return nil;
    end
end

function LootReserve.ItemConditions:Save(itemID, server)
    if server and LootReserve.Server.CurrentSession then
        LootReserve:ShowError("Cannot edit loot during an active session");
    elseif server then
        local container = LootReserve.Server:GetNewSessionItemConditions();
        local conditions = container[itemID];
        if conditions then
            -- Coerce conditions
            if conditions.ClassMask == 0 then
                conditions.ClassMask = nil;
            end
            if conditions.Hidden == false then
                conditions.Hidden = nil;
            end
            if conditions.Custom == false then
                conditions.Custom = nil;
            end
            if conditions.Limit and conditions.Limit <= 0 then
                conditions.Limit = nil;
            end
        end

        -- If conditions are no different from the default - delete the table
        if conditions then
            local different = false;
            local default = LootReserve.Data.ItemConditions[itemID];
            if default then
                for k, v in pairs(conditions) do
                    if v ~= default[k] then
                        different = true;
                        break;
                    end
                end
                for k, v in pairs(default) do
                    if v ~= conditions[k] then
                        different = true;
                        break;
                    end
                end
            else
                if next(conditions) then
                    different = true;
                end
            end

            if not different then
                conditions = nil;
                container[itemID] = nil;
            end
        end

        LootReserve.Server.LootEdit:UpdateLootList();
        LootReserve.Server.Import:SessionSettingsUpdated();
    else
        LootReserve:ShowError("Cannot edit loot on client");
    end
end

function LootReserve.ItemConditions:Delete(itemID, server)
    if server and LootReserve.Server.CurrentSession then
        LootReserve:ShowError("Cannot edit loot during an active session");
    elseif server then
        LootReserve.Server:GetNewSessionItemConditions()[itemID] = nil;

        LootReserve.Server.LootEdit:UpdateLootList();
        LootReserve.Server.Import:SessionSettingsUpdated();
    else
        LootReserve:ShowError("Cannot edit loot on client");
    end
end

function LootReserve.ItemConditions:Clear(server)
    if server and LootReserve.Server.CurrentSession then
        LootReserve:ShowError("Cannot edit loot during an active session");
    elseif server then
        table.wipe(LootReserve.Server:GetNewSessionItemConditions());

        LootReserve.Server.LootEdit:UpdateLootList();
        LootReserve.Server.Import:SessionSettingsUpdated();
    else
        LootReserve:ShowError("Cannot edit loot on client");
    end
end

function LootReserve.ItemConditions:HasCustom(server)
    local container;
    if server and LootReserve.Server.CurrentSession then
        container = LootReserve.Server.CurrentSession.ItemConditions
    elseif server then
        container = LootReserve.Server:GetNewSessionItemConditions();
    else
        container = LootReserve.Client.ItemConditions;
    end

    if container then
        for _, conditions in pairs(container) do
            if conditions.Custom then
                return true;
            end
        end
    end
    return false;
end



local UNUSABLE_EQUIPMENT = { };

local armorClasses = {"Miscellaneous", "Cloth", "Leather", "Mail", "Shields", "Plate", "Librams", "Idols", "Totems"};

local usableArmor = {
    WARRIOR = {Leather = true, Mail = true, Plate = true, Shields = true},
    ROGUE   = {Leather = true},
    MAGE    = {},
    PRIEST  = {},
    WARLOCK = {},
    HUNTER  = {Leather = true, Mail = true},
    DRUID   = {Leather = true, Idols = true},
    SHAMAN  = {Leather = true, Mail = true, Shields = true, Totems = true},
    PALADIN = {Leather = true, Mail = true, Plate = true, Shields = true, Librams = true},
};
for _, armorTypes in pairs(usableArmor) do
    armorTypes.Miscellaneous = true;
    armorTypes.Cloth = true;
end
for class in pairs(usableArmor) do
    UNUSABLE_EQUIPMENT[class] = {
        [ARMOR]  = {},
        [WEAPON] = {},
    };
    for _, armorType in ipairs(armorClasses) do
        UNUSABLE_EQUIPMENT[class][ARMOR][armorType] = not usableArmor[class][armorType];
    end
end

local function setClassWeapons(class, ...)
    for _, weapon in ipairs{...} do
        UNUSABLE_EQUIPMENT[class][WEAPON][weapon] = nil;
    end
end

for class in pairs(usableArmor) do
    for _, weapon in ipairs{"Two-Handed Axes", "One-Handed Axes", "Two-Handed Swords", "One-Handed Swords",
                            "Two-Handed Maces", "One-Handed Maces", "Polearms", "Staves", "Daggers",
                            "Fist Weapons", "Bows", "Crossbows", "Guns", "Thrown", "Wands", "Relic"} do
        UNUSABLE_EQUIPMENT[class][WEAPON][weapon] = true;
    end
end

setClassWeapons("DRUID",   "Two-Handed Maces", "One-Handed Maces", "Staves", "Daggers", "Fist Weapons", "Relic");
setClassWeapons("HUNTER",  "Two-Handed Axes", "One-Handed Axes", "Two-Handed Swords", "One-Handed Swords",
                           "Polearms", "Staves", "Daggers", "Fist Weapons", "Bows", 
                           "Crossbows", "Guns", "Thrown");
setClassWeapons("MAGE",    "One-Handed Swords", "Staves", "Daggers", "Wands");
setClassWeapons("PALADIN", "Two-Handed Axes", "One-Handed Axes", "Two-Handed Swords", "One-Handed Swords",
                           "Two-Handed Maces", "One-Handed Maces", "Polearms", "Relic");
setClassWeapons("PRIEST",  "One-Handed Maces", "Staves", "Daggers", "Wands");
setClassWeapons("ROGUE",   "One-Handed Swords", "One-Handed Maces", "Daggers", "Fist Weapons",
                           "Bows", "Crossbows", "Guns", "Thrown");
setClassWeapons("SHAMAN",  "Two-Handed Axes", "One-Handed Axes", "Two-Handed Maces", "One-Handed Maces",
                           "Staves", "Daggers", "Fist Weapons", "Relic");
setClassWeapons("WARLOCK", "One-Handed Swords", "Staves", "Daggers", "Wands");
setClassWeapons("WARRIOR", "Two-Handed Axes", "One-Handed Axes", "Two-Handed Swords", "One-Handed Swords",
                           "Two-Handed Maces", "One-Handed Maces", "Polearms", "Staves", "Daggers", "Fist Weapons", 
                           "Bows", "Crossbows", "Guns", "Thrown");


local function IsItemUsable(itemID, playerClass, isMe)
    local numOwned;
    if isMe then
        numOwned = GetItemCount(itemID, true) - LootReserve:GetTradeableItemCount(itemID);
    end
    
    local item = LootReserve.ItemSearch:Get(itemID);
    if not item or not item:GetID() then
        return nil;
    end
    
    -- If item is Armor or Weapon then fail if class cannot equip it
    local itemType, itemSubType = item:GetTypeAndSubType();
    if UNUSABLE_EQUIPMENT[playerClass][itemType] then
        if UNUSABLE_EQUIPMENT[playerClass][itemType][itemSubType] then
           return false; 
        end
    end
    
    -- If item starts a quest, make sure the quest is not completed or in progress
    if isMe then
        local questStartID = LootReserve.Data:GetQuestStarted(itemID);
        local questDropID  = LootReserve.Data:GetQuestDropRequirement(itemID);
        if questStartID or questDropID then
            if C_QuestLog.IsQuestFlaggedCompleted(questStartID or questDropID) then
                return false;
            end
            local found = false;
            local collapsedHeaders = { };
            local i = 1;
            while GetQuestLogTitle(i) do
                local name, _, _, isHeader, isCollapsed, _, _, questID = GetQuestLogTitle(i);
                if isHeader then
                    if isCollapsed then
                        table.insert(collapsedHeaders, 1, i);
                        ExpandQuestHeader(i);
                    end
                elseif questID == questStartID or questID == questDropID then
                    found = true;
                    break;
                end
                i = i + 1;
            end

            for _, i in ipairs(collapsedHeaders) do
                CollapseQuestHeader(i);
            end
            if (found and questStartID) or (not found and questDropID) then
                return false;
            end
        end
    end
    
    local classesAllowed = item:GetClassesAllowed();
    local unique = item:IsUnique();
    if classesAllowed ~= true and not classesAllowed:match(LOCALIZED_CLASS_NAMES_MALE[playerClass]) and not classesAllowed:match(LOCALIZED_CLASS_NAMES_FEMALE[playerClass]) then
        return false;
    end
    
    if isMe and item:Loaded() then
        -- If item is class-locked then make sure this class is listed
        -- Also make sure the item is not unique if I already own one
        if not LootReserve.TooltipScanner then
            LootReserve.TooltipScanner = CreateFrame("GameTooltip", "LootReserveTooltipScanner", UIParent, "GameTooltipTemplate");
            LootReserve.TooltipScanner:Hide();
        end
        if not LootReserve.TooltipScanner.Unique then
            LootReserve.TooltipScanner.Unique = format("^(%s)$", ITEM_UNIQUE);
        end
        if not LootReserve.TooltipScanner.AlreadyKnown then
            LootReserve.TooltipScanner.AlreadyKnown = format("^(%s)$", ITEM_SPELL_KNOWN);
        end
        if not LootReserve.TooltipScanner.ProfessionAllowed then
            LootReserve.TooltipScanner.ProfessionAllowed = format("^%s$", ITEM_MIN_SKILL:gsub("%d+%$",""):gsub("%%s ", "([%%u%%l%%s]+) "):gsub("%(%%d%)", "%%((%%d+)%%)"));
        end

        LootReserve.TooltipScanner:SetOwner(UIParent, "ANCHOR_NONE");
        LootReserve.TooltipScanner:SetHyperlink("item:" .. itemID);
        for i = 1, LootReserve.TooltipScanner:NumLines() do
            local line = _G[LootReserve.TooltipScanner:GetName() .. "TextLeft" .. i];
            if line and line:GetText() then
                local problem = false;
                    
                if line:GetText():match(LootReserve.TooltipScanner.AlreadyKnown) then
                    local r, g, b = line:GetTextColor();
                    r, g, b = r*255, g*255, b*255;
                    if r > 254 and r <= 255 and g > 31 and g <= 32 and b > 31 and b <= 32 then
                        problem = true;
                    end
                    
                elseif line:GetText():match(LootReserve.TooltipScanner.Unique) and numOwned > 0 then
                    problem = true;
                    
                elseif line:GetText():match(LootReserve.TooltipScanner.ProfessionAllowed) then
                    if numOwned > 0 then
                        problem = true;
                    else
                        local r, g, b = line:GetTextColor();
                        r, g, b = r*255, g*255, b*255;
                        if r > 254 and r <= 255 and g > 31 and g <= 32 and b > 31 and b <= 32 then
                            problem = true;
                        end
                    end
                end
                if problem then
                    LootReserve.TooltipScanner:Hide();
                    return false;
                end
            end
        end
        LootReserve.TooltipScanner:Hide();
    end
    
    return true, not item:Loaded();
end

local usableCache = { };
local usableCacheHooked = nil;
local function IsItemUsableByMe(itemID)
    if not usableCacheHooked then
        usableCacheHooked = true;
        LootReserve:RegisterEvent("QUEST_ACCEPTED", "QUEST_TURNED_IN", "BAG_UPDATE", "CHAT_MSG_SKILL", function()
            usableCache = { };
        end);
    end
    if not usableCache[itemID] then
        local usable, unloaded = IsItemUsable(itemID, select(2, LootReserve:UnitClass(LootReserve:Me())), true);
        if not unloaded then
            usableCache[itemID] = usable;
        else
            return usable, false;
        end
    end
    return usableCache[itemID], true;
end


function LootReserve.ItemConditions:IsItemUsable(itemID, playerClass)
    return IsItemUsable(itemID, playerClass, false);
end
function LootReserve.ItemConditions:IsItemUsableByMe(itemID)
    return IsItemUsableByMe(itemID);
end

function LootReserve.ItemConditions:TestClassMask(classMask, playerClass)
    return classMask and playerClass and bit.band(classMask, bit.lshift(1, playerClass - 1)) ~= 0;
end

function LootReserve.ItemConditions:TestFaction(faction)
    return faction and UnitFactionGroup("player") == faction;
end

function LootReserve.ItemConditions:TestLimit(limit, itemID, player, server)
    if limit <= 0 then
        -- Has no limiton the number of reserves
        return true;
    end

    if server then
        local reserves = LootReserve.Server.CurrentSession.ItemReserves[itemID];
        if not reserves then
            -- Not reserved by anyone yet
            return true;
        end

        return #reserves.Players < limit;
    else
        return #LootReserve.Client:GetItemReservers(itemID) < limit;
    end
end

function LootReserve.ItemConditions:TestPlayer(player, itemID, server)
    if not server and not LootReserve.Client.SessionServer then
        -- Show all items until connected to a server
        return true;
    end
    local playerClass, playerClassID = select(2, LootReserve:UnitClass(player))

    local conditions = self:Get(itemID, server);
    local equip
    if server then
        if LootReserve.Server.CurrentSession then
            equip = LootReserve.Server.CurrentSession.Settings.Equip;
        else
            equip = LootReserve.Server.NewSessionSettings.Equip or false;
        end
    else
        equip = LootReserve.Client.Equip;
    end
    if conditions and conditions.Hidden then
        return false, LootReserve.Constants.ReserveResult.ItemNotReservable;
    end
    if conditions and conditions.ClassMask and playerClass and not self:TestClassMask(conditions.ClassMask, playerClassID) then
        return false, LootReserve.Constants.ReserveResult.FailedClass;
    end
    if equip and playerClass and not self:IsItemUsable(itemID, playerClass) then
        return false, LootReserve.Constants.ReserveResult.FailedUsable;
    end
    if conditions and conditions.Faction and not self:TestFaction(conditions.Faction) then
        return false, LootReserve.Constants.ReserveResult.FailedFaction;
    end
    if conditions and conditions.Limit and not self:TestLimit(conditions.Limit, itemID, player, server) then
        return false, LootReserve.Constants.ReserveResult.FailedLimit;
    end
    return true;
end

function LootReserve.ItemConditions:TestServer(itemID)
    local conditions = self:Get(itemID, true);
    if conditions then
        if conditions.Hidden then
            return false;
        end
        if conditions.Faction and not self:TestFaction(conditions.Faction) then
            return false;
        end
    end
    return true;
end

function LootReserve.ItemConditions:IsItemVisibleOnClient(itemID)
    local canReserve, conditionResult = self:TestPlayer(LootReserve.Client.Masquerade or LootReserve:Me(), itemID, false);
    return canReserve or conditionResult == LootReserve.Constants.ReserveResult.FailedLimit
           or ((conditionResult == LootReserve.Constants.ReserveResult.FailedClass or conditionResult == LootReserve.Constants.ReserveResult.FailedUsable) and (LootReserve.Client.Locked or not LootReserve.Client.AcceptingReserves));
end

function LootReserve.ItemConditions:IsItemReservableOnClient(itemID)
    local canReserve, conditionResult = self:TestPlayer(LootReserve.Client.Masquerade or LootReserve:Me(), itemID, false);
    return canReserve;
end

function LootReserve.ItemConditions:Pack(conditions)
    local text = "";
    if conditions.Hidden then
        text = text .. "-";
    elseif conditions.Custom then
        text = text .. "+";
    end
    if conditions.Faction == "Alliance" then
        text = text .. "A";
    elseif conditions.Faction == "Horde" then
        text = text .. "H";
    end
    if conditions.ClassMask and conditions.ClassMask ~= 0 then
        text = text .. "C" .. conditions.ClassMask;
    end
    if conditions.Limit and conditions.Limit ~= 0 then
        text = text .. "L" .. conditions.Limit;
    end
    return text;
end

function LootReserve.ItemConditions:Unpack(text)
    local conditions = LootReserve:Deepcopy(DefaultConditions);

    for i = 1, #text do
        local char = text:sub(i, i);
        if char == "-" then
            conditions.Hidden = true;
        elseif char == "+" then
            conditions.Custom = true;
        elseif char == "A" then
            conditions.Faction = "Alliance";
        elseif char == "H" then
            conditions.Faction = "Horde";
        elseif char == "C" then
            for len = 1, 10 do
                local mask = text:sub(i + 1, i + len);
                if tonumber(mask) then
                    conditions.ClassMask = tonumber(mask);
                else
                    break;
                end
            end
        elseif char == "L" then
            for len = 1, 10 do
                local limit = text:sub(i + 1, i + len);
                if tonumber(limit) then
                    conditions.Limit = tonumber(limit);
                else
                    break;
                end
            end
        end
    end
    return conditions;
end