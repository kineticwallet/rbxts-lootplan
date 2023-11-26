--!strict
--!optimize 2

--[[
$$\       $$\                      $$\     $$\                                   $$\ $$\            $$\
$$ |      \__|                     $$ |    \__|                                  $$ |$$ |           $$ |
$$ |  $$\ $$\ $$$$$$$\   $$$$$$\ $$$$$$\   $$\  $$$$$$$\ $$\  $$\  $$\  $$$$$$\  $$ |$$ | $$$$$$\ $$$$$$\
$$ | $$  |$$ |$$  __$$\ $$  __$$\\_$$  _|  $$ |$$  _____|$$ | $$ | $$ | \____$$\ $$ |$$ |$$  __$$\\_$$  _|
$$$$$$  / $$ |$$ |  $$ |$$$$$$$$ | $$ |    $$ |$$ /      $$ | $$ | $$ | $$$$$$$ |$$ |$$ |$$$$$$$$ | $$ |
$$  _$$<  $$ |$$ |  $$ |$$   ____| $$ |$$\ $$ |$$ |      $$ | $$ | $$ |$$  __$$ |$$ |$$ |$$   ____| $$ |$$\
$$ | \$$\ $$ |$$ |  $$ |\$$$$$$$\  \$$$$  |$$ |\$$$$$$$\ \$$$$$\$$$$  |\$$$$$$$ |$$ |$$ |\$$$$$$$\  \$$$$  |
\__|  \__|\__|\__|  \__| \_______|  \____/ \__| \_______| \_____\____/  \_______|\__|\__| \_______|  \____/
]]
--

-- >>PRIVATE_TYPES << --
type LootplanType = "Multi" | "MultiLootplan" | "Single" | "SingleLootplan"

type LootItem = {
	Chance: number,
	Name: string,
}

-- >>SINGLE_LOOTPLAN<< --
local SingleLootplan = {}

-- Create a new SingeLootplan.
function SingleLootplan.new(lootplanSeed: number?)
	-- Validate the parameters.
	if typeof(lootplanSeed) ~= "number" then
		lootplanSeed = math.round(tick() % 1) * math.pow(10, 10)
	end
	-- Set the metable.
	local self = setmetatable(SingleLootplan, {})
	-- Add the attributes the metatable.
	self.Randomizer = Random.new(lootplanSeed)
	self.Loot = {} :: { [string]: LootItem }
	self.LootList = {} :: { LootItem }
	self.LootCount = 0
	self.TotalChance = 0
	-- Return the metatable.
	return self
end

-- (Private) Update the LootList.
function SingleLootplan:_updateLootList()
	-- Cache the new LootList.
	local lootList: { LootItem } = {}
	-- Iterate over all the given loot.
	for _: string, lootItem: LootItem in pairs(self.Loot) do
		table.insert(lootList, lootItem)
	end
	-- Sort the new LootList.
	table.sort(lootList, function(a: LootItem, b: LootItem)
		return a.Chance < b.Chance
	end)
	-- Set the new LootList.
	self.LootList = lootList
end

-- Add an item to the loot.
function SingleLootplan:AddLoot(chance: number, name: string): LootItem?
	-- Validate the parameters.
	if typeof(name) ~= "string" then
		return nil
	end
	if typeof(chance) ~= "number" then
		return nil
	end
	if chance <= 0 then
		return nil
	end
	-- Create the new item.
	local newLootItem: LootItem = {
		["Chance"] = chance,
		["Name"] = name,
	}
	-- Add the new item to the loot.
	self.Loot[name] = newLootItem
	self.LootCount += 1
	self.TotalChance += chance
	-- Update the LootList.
	self:_updateLootList()
	-- Return the new item.
	return table.freeze(newLootItem)
end

-- Add items to the loot in a bulk way.
function SingleLootplan:AddLootInBulk(bulkLoot: { [string]: number }): { [string]: LootItem }
	-- Validate the parameters
	if typeof(bulkLoot) ~= "table" then
		return {}
	end
	-- Create an chace for all the added items.
	local bulkLootItems: { [string]: LootItem } = {}
	-- Iterate over all the given items to create and create those.
	for name: string, chance: number in pairs(bulkLoot) do
		bulkLootItems[name] = self:AddLoot(chance, name)
	end
	-- Return the cache.
	return table.freeze(bulkLootItems)
end

-- Get the set item chance.
function SingleLootplan:GetLootChance(name: string): number?
	-- Validate the parameters.
	if typeof(name) ~= "string" then
		return nil
	end
	if typeof(self.Loot[name]) ~= "table" then
		return nil
	end
	-- Return the set item chance.
	return self.Loot[name]["Chance"] or nil
end

-- Get the true item chance.
function SingleLootplan:GetTrueLootChance(name: string): number?
	-- Validate the parameters.
	if typeof(name) ~= "string" then
		return nil
	end
	if typeof(self.Loot[name]) ~= "table" then
		return nil
	end
	-- Calculate the true loot chance.
	return (self.Loot[name]["Chance"] / self.TotalChance) * math.pow(10, 2)
end

-- Remove an item from the loot.
function SingleLootplan:RemoveLoot(name: string): boolean
	-- Validate the parameters.
	if typeof(name) ~= "string" then
		return false
	end
	-- Get the item.
	local lootItem: LootItem? = self.Loot[name]
	-- Validate the item.
	if typeof(lootItem) ~= "table" then
		return false
	end
	-- Remove the item and do neede changes for the attributes.
	self.TotalChance -= lootItem["Chance"]
	self.LootCount -= 1
	self.Loot[name] = nil
	-- Update the LootList.
	self:_updateLootList()
	-- Return the success.
	return true
end

-- Change the chance of an item.
function SingleLootplan:ChangeLootChance(newChance: number, name: string): (boolean, LootItem?)
	-- Validate the parameters.
	if typeof(name) ~= "string" then
		return false, nil
	end
	if typeof(newChance) ~= "number" then
		return false, nil
	end
	if newChance <= 0 then
		return false, nil
	end
	-- Get the item.
	local lootItem: LootItem? = self.Loot[name]
	-- Validate the item.
	if typeof(lootItem) ~= "table" then
		return false, nil
	end
	-- Do the changes.
	self.TotalChance += newChance - lootItem["Chance"]
	lootItem["Chance"] = newChance
	-- Update the LotoList to fit the new changes.
	self:_updateLootList()
	-- Return the new item.
	return true, lootItem
end

-- Get an random item from the loot.
function SingleLootplan:GetRandomLoot(luckMultiplier: number?): LootItem?
	-- Validate the parameters.
	if typeof(luckMultiplier) ~= "number" then
		luckMultiplier = 1
	end
	-- Check for negative or positive luck.
	if luckMultiplier >= 1 then
		-- Create needed variables.
		local result: number = self.Randomizer:NextNumber()
		local aggregate: number = 0
		-- Iterate over all the items in the LootList.
		for _: number, loot: LootItem in ipairs(self.LootList) do
			-- Validate the given item.
			if typeof(loot) ~= "table" then
				continue
			end
			-- Calculate the chance for this given item.
			local chance: number = loot["Chance"] * luckMultiplier :: number
			-- Check if this item fits the chance.
			if result < (chance + aggregate) / self.TotalChance then
				return loot
			end
			-- Increase the variables if it doesnt fit.
			aggregate += chance
		end
		-- If no item fits the chances, nil gets returned.
		return nil
	else
		-- Adjust the luck multiplier.
		local newLuckMultiplier: number = 1 / luckMultiplier :: number
		-- Create needed variables.
		local result: number = self.Randomizer:NextNumber()
		local aggregate: number = 0
		-- Iterate over the length of the LootList.
		for i = self.LootCount, 1, -1 do
			-- Get the given item from the LootList.
			local loot: LootItem? = self.LootList[i :: number]
			-- Validate the given item.
			if typeof(loot) ~= "table" then
				continue
			end
			-- Calculate the chance for this given item.
			local chance: number = loot["Chance"] * newLuckMultiplier
			-- Check if this item fits the chance.
			if result < (chance + aggregate) / self.TotalChance then
				return loot
			end
			-- Increase the variables if it doesnt fit.
			aggregate += chance
		end
		-- If no item fits the chances, nil gets returned.
		return nil
	end
end

-- >>MULTI_LOOTPLAN<< --
local MultiLootplan = {}

-- Create a new MultiLootplan.
function MultiLootplan.new(lootplanSeed: number?)
	-- Validate the given parameters.
	if typeof(lootplanSeed) ~= "number" then
		lootplanSeed = math.round(tick() % 1) * math.pow(10, 10)
	end
	-- Create the needed metatable.
	local self = setmetatable(MultiLootplan, {})
	-- Set the attributes.
	self.Randomizer = Random.new(lootplanSeed)
	self.Loot = {}
	-- Return the metatable.
	return self
end

-- Add an item to the loot.
function MultiLootplan:AddLoot(chance: number, name: string): LootItem?
	-- Validate the parameters.
	if typeof(name) ~= "string" then
		return nil
	end
	if typeof(chance) ~= "number" then
		return nil
	end
	if chance <= 0 then
		return nil
	end
	-- Create the item.
	local newLootItem: LootItem = {
		["Chance"] = chance,
		["Name"] = name,
	}
	-- Add the item to the loot.
	self.Loot[name] = newLootItem
	-- Return the new item.
	return table.freeze(newLootItem)
end

-- Add items to the loot in a bulk way.
function MultiLootplan:AddLootInBulk(bulkLoot: { [string]: number }): { [string]: LootItem }
	-- Validate the parameters
	if typeof(bulkLoot) ~= "table" then
		return {}
	end
	-- Create an chace for all the added items.
	local bulkLootItems: { [string]: LootItem } = {}
	-- Iterate over all the given items to create and create those.
	for name: string, chance: number in pairs(bulkLoot) do
		bulkLootItems[name] = self:AddLoot(chance, name)
	end
	-- Return the cache.
	return table.freeze(bulkLootItems)
end

-- Get the chance of an item.
function MultiLootplan:GetLootChance(name: string): number?
	-- Validate teh parameters.
	if typeof(name) ~= "string" then
		return nil
	end
	-- Check if the item exists.
	if typeof(self.Loot[name]) ~= "table" then
		return nil
	end
	-- Return the chance of the item.
	return self.Loot[name]["Chance"] or nil
end

-- Remove an item from the loot.
function MultiLootplan:RemoveLoot(name: string): boolean
	-- Validate the parameters.
	if typeof(name) ~= "string" then
		return false
	end
	if typeof(self.Loot[name]) ~= "table" then
		return false
	end
	-- Remove the item by the given name.
	self.Loot[name] = nil
	return true
end

-- Change the chance of an item.
function MultiLootplan:ChangeLootChance(newChance: number, name: string): (boolean, LootItem?)
	-- Validate the given parameters.
	if typeof(name) ~= "string" then
		return false, nil
	end
	if typeof(newChance) ~= "number" then
		return false, nil
	end
	if newChance <= 0 then
		return false, nil
	end
	-- Get the wanted item & validate it.
	local lootItem: LootItem? = self.Loot[name]
	if typeof(lootItem) ~= "table" then
		return false, nil
	end
	-- Change the loot chance.
	lootItem["Chance"] = newChance
	-- Return the changed item.
	return true, lootItem
end

-- Get an set amount of random items from the loot.
function MultiLootplan:GetRandomLoot(amount: number?, luckMulitplier: number?): { LootItem }
	-- If no amount is given, default to one.
	if typeof(amount) ~= "number" or amount <= 0 then
		amount = 1
	end
	-- If no luck multiplier is given, default to one.
	if typeof(luckMulitplier) ~= "number" then
		luckMulitplier = 1
	end
	-- Create an cache for all the calculated items.
	local lootItems: { LootItem } = {}
	-- Iterate of the amount of items to calculate.
	for i = 1, amount :: number, 1 do
		-- Iterate over all the items in the loot.
		for name: string, lootItem: LootItem in pairs(self.Loot) do
			-- Calculate the chances.
			local result: number = self.Randomizer:NextNumber()
			local chance: number = (lootItem["Chance"] / 100) * luckMulitplier :: number
			-- Either added this item to the cache or retry.
			if result < chance and #lootItems < amount :: number then
				table.insert(lootItems, lootItem)
			else
				i -= 1
			end
		end
	end
	-- Return the cache.
	return lootItems
end

-- >>PUBLIC_TYPES<< --
export type SingleLootplan = typeof(SingleLootplan.new())
export type MultiLootplan = typeof(MultiLootplan.new())

-- >>CORE<< --
-- Main callback to create a lootplan.
local function createLootplan(lootplanType: LootplanType, lootplanSeed: number?): SingleLootplan | MultiLootplan
	-- Check which lootplan should be created and return it, parse the lootplanSeed to the selected lootplan class.
	if typeof(lootplanType) == "string" and lootplanType == "Multi" or lootplanType == "MultiLootplan" then
		return MultiLootplan.new(lootplanSeed)
	end
	-- If no preferred lootplan is selected return this default one.
	return SingleLootplan.new(lootplanSeed)
end

-- >>RETURN<< --
return table.freeze({
	["default"] = createLootplan,
	["createLootplan"] = createLootplan,
})
