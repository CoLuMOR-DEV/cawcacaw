local unpackFn = table.unpack or unpack
local Players = game:GetService("Players")

while not Players.LocalPlayer do task.wait() end
local LocalPlayer = Players.LocalPlayer
while not LocalPlayer.UserId or LocalPlayer.UserId == 0 do task.wait() end

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local Stats = game:GetService("Stats")
local Camera = Workspace.CurrentCamera

local VirtualUser = nil
pcall(function() VirtualUser = game:GetService("VirtualUser") end)

local function GetSafeGuiParent()
    local success, core = pcall(function() return game:GetService("CoreGui") end)
    if success and core then
        local test = Instance.new("Folder")
        local s2 = pcall(function() test.Parent = core end)
        if s2 then test:Destroy() return core end
    end
    return LocalPlayer:WaitForChild("PlayerGui")
end
local targetGuiParent = GetSafeGuiParent()

local currentTier = "Premium"

local ExecName = "Unknown"
pcall(function()
    if type(identifyexecutor) == "function" then
        local name = identifyexecutor()
        if type(name) == "string" then ExecName = name end
    end
end)
local ExecLower = string.lower(ExecName)

local SUNC_DB = {
    ["macsploit"] = 100, ["potassium"] = 90, ["volt"] = 90, ["bunni"] = 80,
    ["seliware"] = 85, ["delta"] = 97, ["volcano"] = 75, ["hydrogen"] = 85,
    ["velocity"] = 94, ["wave"] = 100, ["solara"] = 40, ["xeno"] = 40,
    ["arceus"] = 0, ["codex"] = 0, ["vega"] = 0, ["ronix"] = 98,
    ["chocosploit"] = 85, ["nihon"] = 100, ["cryptic"] = 80,
    ["valex"] = 70, ["sirhurt"] = 65, ["luna"] = 65, ["cubix"] = 80,
    ["apple"] = 40, ["celery"] = 35
}

local ExecSUNC = 85 
for key, score in pairs(SUNC_DB) do
    if string.find(ExecLower, key) then
        ExecSUNC = score
        break
    end
end

local ExecSupportStatus = (ExecSUNC >= 90 and "High" or ExecSUNC >= 71 and "Medium" or "Low")
local ExecEnvironment = "Standard"
local IsUnsupportedExecutor = false

local blockedExecs = {"xeno", "solara"}
for _, blocked in ipairs(blockedExecs) do
    if string.find(ExecLower, blocked) then
        IsUnsupportedExecutor = true
        break
    end
end

local function SystemMessage(msg)
    pcall(function()
        local tcs = game:GetService("TextChatService")
        if tcs and tcs.ChatVersion == Enum.ChatVersion.TextChatService then
            local channels = tcs:FindFirstChild("TextChannels")
            local rbxSystem = channels and channels:FindFirstChild("RBXSystem")
            if rbxSystem then
                rbxSystem:DisplaySystemMessage("<font color='#557DFF'><b>[cx.farm]</b></font> " .. msg)
            end
        else
            game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", {
                Text = "[cx.farm] " .. msg,
                Color = Color3.fromRGB(85, 125, 255),
                Font = Enum.Font.SourceSansBold,
                TextSize = 18
            })
        end
    end)
end

local API_URL = "https://cx-api-utry.onrender.com"
local requestFunc = (request or http_request or (http and http.request) or (syn and syn.request))

local function GetRealLiveUsers()
    local liveData = {total = 0, free = 0, premium = 0}
    if not requestFunc then return liveData end
    local s, res = pcall(function()
        return requestFunc({
            Url = API_URL .. "/count",
            Method = "GET"
        })
    end)
    if s and res and res.Body then
        local success, data = pcall(function() return HttpService:JSONDecode(res.Body) end)
        if success and data then
            if data.total then
                liveData.total = data.total
                liveData.free = data.free
                liveData.premium = data.premium
            elseif data.activeUsers then
                liveData.total = data.activeUsers
            end
        end
    end
    return liveData
end

local ScriptRunning = true

task.spawn(function()
    if not requestFunc then return end
    local hwid = "Unknown"
    pcall(function() hwid = game:GetService("RbxAnalyticsService"):GetClientId() end)
    while ScriptRunning do
        pcall(function()
            requestFunc({
                Url = API_URL .. "/ping",
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = HttpService:JSONEncode({hwid = hwid, tier = currentTier})
            })
        end)
        task.wait(30)
    end
end)

local OriginalWorkspaceTransparencies = {}
local InventoryModule = nil
local ItemsManager = nil
local PlayerMovement = nil
local WorldTilesModule = nil
local WorldManager = nil
local AABBModule = nil
local lastKnownCheckId = nil

task.spawn(function()
    pcall(function()
        local modules = ReplicatedStorage:WaitForChild("Modules", 5)
        local managers = ReplicatedStorage:WaitForChild("Managers", 5)
        local pScripts = LocalPlayer:WaitForChild("PlayerScripts", 5)
        
        if modules then
            InventoryModule = require(modules:WaitForChild("Inventory", 2))
            AABBModule = require(modules:WaitForChild("AABB", 2))
        end
        if managers then
            ItemsManager = require(managers:WaitForChild("ItemsManager", 2))
            WorldManager = require(managers:WaitForChild("WorldManager", 2))
        end
        if pScripts then
            PlayerMovement = require(pScripts:WaitForChild("PlayerMovement", 2))
        end
        WorldTilesModule = require(ReplicatedStorage:WaitForChild("WorldTiles", 5))
    end)
end)

local function GetPlayerPos()
    local pos = nil
    pcall(function()
        local hitbox = workspace:FindFirstChild("Hitbox")
        local pBox = hitbox and hitbox:FindFirstChild(LocalPlayer.Name)
        if pBox then pos = pBox.Position end
        
        if not pos and type(PlayerMovement) == "table" then 
            pos = rawget(PlayerMovement, "Position") 
        end
        
        if not pos then 
            local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            pos = root and root.Position
        end
    end)
    return pos or Vector3.zero
end

local function SafeClearTable(t)
    if type(t) ~= "table" then return end
    local s = pcall(function()
        if table.clear then table.clear(t) else for k in pairs(t) do t[k] = nil end end
    end)
    if not s then for k in pairs(t) do t[k] = nil end end
end

local function GetTileStatus(gx, gy, mode)
    local hasBlock, isBad, hasFg, hasBg = false, false, false, false
    local bads = {"bedrock", "main door", "portal", "spawn", "white door", "cave door", "lock"}
    
    if not gx or not gy then return false, false, false, false end
    if type(WorldManager) ~= "table" or type(WorldManager.GetTile) ~= "function" then 
        return false, false, false, false 
    end
    
    gx, gy = math.floor(gx), math.floor(gy)
    
    for layer = 1, 2 do
        local id = nil
        pcall(function() id = WorldManager.GetTile(gx, gy, layer) end)
        
        if id then
            if type(id) == "table" then id = id[1] end
            if id and tostring(id) ~= "0" and tostring(id) ~= "" and tostring(id) ~= "nil" then
                hasBlock = true
                if layer == 1 then hasFg = true end
                if layer == 2 then hasBg = true end
                
                if mode == "Nuker" or mode == "Pathing" or mode == "Farm" then
                    local baseId = tostring(id):gsub("_sapling$", "")
                    local name = baseId
                    if type(ItemsManager) == "table" and type(ItemsManager.ItemsData) == "table" then
                        local data = ItemsManager.ItemsData[baseId]
                        if type(data) == "table" and data.Name then name = string.lower(data.Name) end
                    end
                    for _, b in ipairs(bads) do 
                        if string.find(name, b) then isBad = true; break end 
                    end
                end
            end
        end
    end
    return hasBlock, isBad, hasFg, hasBg
end

local function IsPassable(gx, gy)
    if type(WorldManager) ~= "table" or type(WorldManager.GetTile) ~= "function" then return true end
    local id, tileData = nil, nil
    pcall(function() 
        local res1, res2 = WorldManager.GetTile(math.floor(gx), math.floor(gy), 1) 
        id = res1
        tileData = res2
    end)
    
    if not id or tostring(id) == "0" or id == "" or tostring(id) == "nil" then return true end
    
    local isSaplingStr = type(id) == "string" and id:sub(-8) == "_sapling"
    if isSaplingStr then return true end
    
    local baseId = type(id) == "string" and id:gsub("_sapling$", "") or id
    if type(ItemsManager) == "table" and type(ItemsManager.ItemsData) == "table" then
        local data = ItemsManager.ItemsData[tostring(baseId)]
        if data and data.Name then
            local nL = string.lower(data.Name)
            if nL == "wooden door" then
                local hasAcc = false
                pcall(function()
                    local ow = workspace:GetAttribute("WorldOwner")
                    if not ow or ow == "" or ow == LocalPlayer.Name then hasAcc = true end
                    if type(tileData) == "table" then
                        if tileData.public then hasAcc = true end
                        if type(tileData.access) == "table" and table.find(tileData.access, LocalPlayer.UserId) then hasAcc = true end
                    end
                end)
                if not hasAcc then return false end
            end
        end
        if data and data.Tile then
            local col = data.Tile.Collision or 1
            if col == 0 or col == 2 or col == 3 then return true end
        end
    end
    return false
end

local function SafeRemoteFire(remote, ...)
    local args = {...}
    if remote and typeof(remote) == "Instance" and remote.ClassName == "RemoteEvent" then
        pcall(function() remote:FireServer(unpackFn(args)) end)
    end
end

local InventoryCache = {} 
local function UpdateInventoryCache()
    SafeClearTable(InventoryCache) 
    if type(InventoryModule) == "table" and type(InventoryModule.Stacks) == "table" then
        pcall(function()
            for slotIndex, stack in pairs(InventoryModule.Stacks) do
                if type(stack) == "table" and stack.Id then
                    local itemName = "ID: " .. tostring(stack.Id)
                    if type(ItemsManager) == "table" then
                        if type(ItemsManager.GetName) == "function" then
                            local s, n = pcall(function() return ItemsManager.GetName(stack.Id) end)
                            if s and n then itemName = n end
                        elseif type(ItemsManager.ItemsData) == "table" then
                            local data = ItemsManager.ItemsData[tostring(stack.Id):gsub("_sapling$", "")]
                            if type(data) == "table" and data.Name then 
                                itemName = data.Name 
                            end
                        end
                    end
                    InventoryCache[slotIndex] = {Slot = slotIndex, Id = stack.Id, Name = itemName, Amount = stack.Amount or 0}
                end
            end
        end)
    end
end

local function GetSlotFromItemId(id)
    if type(InventoryModule) ~= "table" then return nil end
    local stacks = rawget(InventoryModule, "Stacks")
    if type(stacks) ~= "table" then return nil end
    
    for slotIndex, stack in pairs(stacks) do
        if type(stack) == "table" and stack.Id == id then
            return slotIndex
        end
    end
    return nil
end

local function GetAggregatedInventory()
    pcall(UpdateInventoryCache)
    local agg = {}
    for _, item in pairs(InventoryCache) do
        if item.Id then
            if not agg[item.Id] then
                agg[item.Id] = { Id = item.Id, Name = item.Name, Amount = 0, Slot = item.Slot }
            end
            agg[item.Id].Amount = agg[item.Id].Amount + (tonumber(item.Amount) or 1)
        end
    end
    local sorted = {}
    for _, v in pairs(agg) do table.insert(sorted, v) end
    table.sort(sorted, function(a, b) return a.Name < b.Name end)
    SafeClearTable(agg) 
    return sorted
end

local CONFIG = {
    GridSize = 4.5,
    AutoPunch = false,
    AutoPlace = false,
    AutoCollect = false,
    AutoClear = false,
    AutoTrash = false,
    ClearSpeed = 50,
    ClearCollect = false,
    PlaceSpeed = 100,
    PunchSpeed = 100, 
    CollectSpeed = 50,
    UseSelectedItem = true, 
    SelectedPlaceItemId = nil, 
    LockTiles = false,
    LockedOrigin = nil,
    SpeedBoost = 0,
    FlySpeed = 30,
    InfiniteJump = false, 
    Freecam = false,
    ShowVisuals = true,
    ModZoom = false,
    GodMode = false,
    HideWatermark = false,
    Fly = false, 
    AntiRubberband = false, 
    HideName = false,
    HideAllNames = false,
    HideGems = false,
    FakeModName = false,
    SpoofName = false,
    SpoofedNameText = "cxontop",
    NameColor = "Default",
    SpoofFlag = "[cx]",
    RGBSkin = false,
    PlayerDetection = false,
    SafetyAction = "Stop", 
    AntiAFK = true,
    AutoConfirmDrop = false,
    DropAmount = 200,
    DisableTrails = false,
    ClearTextures = false,
    LowGFX = true, 
    HidePlayers = false, 
    DisableParallax = false,
    Disable3D = false, 
    LimitFPS = false, 
    Pathfinder = false,
    OptimizeDrops = false,
    
    AutoSaveConfig = false,
    AutoSaveName = "MyConfig",
    AutoLoadConfig = false,
    AutoLoadName = "MyConfig",

    HideChatName = false,
    ChatNotifications = false,
    AutoChat = false,
    ChatMsg = "CX on TOP! 🤑",
    ChatDelay = 4,
    
    WebhookURL = "",
    WebhookOnDetection = false,
    WebhookOnNukerDone = false,
    WebhookOnFarmEmpty = false,

    AutoBuyShop = false,
    ShopThreshold = 10000,
    ShopBuyAmount = 10,
    ShopBuyDelay = 0.5,
    SelectedShopItem = nil,
    SelectedShopPrice = 0,
    
    TrashList = {
        ["dirt"] = false,
        ["dirt_sapling"] = false,
        ["dirt_bg"] = false,
        ["dirt_bg_sapling"] = false,
        ["magma"] = false,
        ["magma_sapling"] = false,
        ["stone"] = false,
        ["stone_sapling"] = false
    },
    
    Whitelist = {},
    Keybinds = {
        AutoPunch = Enum.KeyCode.P,
        AutoPlace = Enum.KeyCode.L,
        ModZoom = Enum.KeyCode.Z,
        Fly = Enum.KeyCode.F,
        ToggleUI = Enum.KeyCode.RightControl,
        GodMode = Enum.KeyCode.G,
        InfiniteJump = Enum.KeyCode.J,
        Pathfinder = Enum.KeyCode.T
    }
}
CONFIG.Whitelist[LocalPlayer.UserId] = true

local ConfigFolder = "cxfarm/config"
pcall(function()
    if type(makefolder) == "function" then
        if not isfolder("cxfarm") then makefolder("cxfarm") end
        if not isfolder(ConfigFolder) then makefolder(ConfigFolder) end
    end
end)

pcall(function()
    if type(readfile) == "function" and isfile(ConfigFolder .. "/bootstrap.json") then
        local bootStr = readfile(ConfigFolder .. "/bootstrap.json")
        local bootData = HttpService:JSONDecode(bootStr)
        
        CONFIG.AutoLoadConfig = bootData.AutoLoadConfig or false
        CONFIG.AutoLoadName = bootData.AutoLoadName or "MyConfig"
        CONFIG.AutoSaveConfig = bootData.AutoSaveConfig or false
        CONFIG.AutoSaveName = bootData.AutoSaveName or "MyConfig"

        if CONFIG.AutoLoadConfig and CONFIG.AutoLoadName ~= "" and isfile(ConfigFolder .. "/" .. CONFIG.AutoLoadName .. ".json") then
            local str = readfile(ConfigFolder .. "/" .. CONFIG.AutoLoadName .. ".json")
            local d = HttpService:JSONDecode(str)
            for k, v in pairs(d) do
                if k == "Keybinds" and type(v) == "table" then
                    for bk, bv in pairs(v) do pcall(function() CONFIG.Keybinds[bk] = Enum.KeyCode[bv] end) end
                elseif k == "FarmCells" and type(v) == "table" then
                elseif CONFIG[k] ~= nil and type(CONFIG[k]) ~= "table" and k ~= "Whitelist" and k ~= "LockedOrigin" then
                    CONFIG[k] = v
                end
            end
        end
    end
end)

local function SendPublicWebhook(title, desc, colorHex)
    if CONFIG.WebhookURL == "" then return end
    local data = {
        ["embeds"] = {{
            ["title"] = title,
            ["description"] = desc,
            ["color"] = colorHex,
            ["footer"] = {["text"] = "cx.farm Security Alerts"}
        }}
    }
    if requestFunc then
        task.spawn(function()
            pcall(function()
                requestFunc({
                    Url = CONFIG.WebhookURL,
                    Method = "POST",
                    Headers = {["Content-Type"] = "application/json"},
                    Body = HttpService:JSONEncode(data)
                })
            end)
        end)
    end
end

pcall(function()
    if targetGuiParent:FindFirstChild("CX_FARM_GUI") then targetGuiParent.CX_FARM_GUI:Destroy() end
    if workspace:FindFirstChild("CX_VISUALS") then workspace.CX_VISUALS:Destroy() end
    if LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("CX_FARM_GUI") then LocalPlayer.PlayerGui.CX_FARM_GUI:Destroy() end
end)

local VisualFolder = Instance.new("Folder")
VisualFolder.Name = "CX_VISUALS"
VisualFolder.Parent = workspace
local Adornments = {}

local Themes = {
    ["Dark Default"] = {
        Background = Color3.fromRGB(20, 20, 20), Sidebar = Color3.fromRGB(28, 28, 28), Element = Color3.fromRGB(40, 40, 40),
        Text = Color3.fromRGB(240, 240, 240), SubText = Color3.fromRGB(160, 160, 160), Accent = Color3.fromRGB(85, 125, 255),
        Danger = Color3.fromRGB(235, 65, 65), Success = Color3.fromRGB(65, 235, 100), Stroke = Color3.fromRGB(50, 50, 50)
    },
    ["Midnight"] = {
        Background = Color3.fromRGB(15, 15, 25), Sidebar = Color3.fromRGB(20, 20, 35), Element = Color3.fromRGB(30, 30, 50),
        Text = Color3.fromRGB(240, 240, 255), SubText = Color3.fromRGB(150, 150, 180), Accent = Color3.fromRGB(110, 150, 255),
        Danger = Color3.fromRGB(255, 80, 80), Success = Color3.fromRGB(80, 255, 120), Stroke = Color3.fromRGB(40, 40, 70)
    },
    ["Crimson"] = {
        Background = Color3.fromRGB(25, 15, 15), Sidebar = Color3.fromRGB(35, 20, 20), Element = Color3.fromRGB(50, 30, 30),
        Text = Color3.fromRGB(255, 240, 240), SubText = Color3.fromRGB(180, 150, 150), Accent = Color3.fromRGB(255, 80, 80),
        Danger = Color3.fromRGB(255, 50, 50), Success = Color3.fromRGB(80, 255, 100), Stroke = Color3.fromRGB(70, 40, 40)
    },
    ["Matrix"] = {
        Background = Color3.fromRGB(10, 20, 10), Sidebar = Color3.fromRGB(15, 30, 15), Element = Color3.fromRGB(25, 45, 25),
        Text = Color3.fromRGB(200, 255, 200), SubText = Color3.fromRGB(120, 180, 120), Accent = Color3.fromRGB(50, 255, 100),
        Danger = Color3.fromRGB(255, 60, 60), Success = Color3.fromRGB(50, 255, 100), Stroke = Color3.fromRGB(30, 70, 30)
    },
    ["Ocean"] = {
        Background = Color3.fromRGB(15, 25, 35), Sidebar = Color3.fromRGB(20, 35, 50), Element = Color3.fromRGB(30, 50, 70),
        Text = Color3.fromRGB(240, 248, 255), SubText = Color3.fromRGB(150, 180, 210), Accent = Color3.fromRGB(85, 170, 255),
        Danger = Color3.fromRGB(255, 80, 80), Success = Color3.fromRGB(80, 255, 150), Stroke = Color3.fromRGB(40, 60, 80)
    },
    ["Amethyst"] = {
        Background = Color3.fromRGB(25, 15, 35), Sidebar = Color3.fromRGB(35, 20, 50), Element = Color3.fromRGB(50, 30, 70),
        Text = Color3.fromRGB(250, 240, 255), SubText = Color3.fromRGB(180, 150, 210), Accent = Color3.fromRGB(170, 85, 255),
        Danger = Color3.fromRGB(255, 80, 80), Success = Color3.fromRGB(80, 255, 150), Stroke = Color3.fromRGB(60, 40, 80)
    },
    ["Sunset"] = {
        Background = Color3.fromRGB(35, 20, 15), Sidebar = Color3.fromRGB(50, 30, 20), Element = Color3.fromRGB(70, 45, 30),
        Text = Color3.fromRGB(255, 245, 240), SubText = Color3.fromRGB(210, 170, 150), Accent = Color3.fromRGB(255, 130, 85),
        Danger = Color3.fromRGB(255, 80, 80), Success = Color3.fromRGB(150, 255, 80), Stroke = Color3.fromRGB(80, 50, 40)
    },
    ["Forest"] = {
        Background = Color3.fromRGB(15, 25, 15), Sidebar = Color3.fromRGB(20, 40, 20), Element = Color3.fromRGB(30, 55, 30),
        Text = Color3.fromRGB(240, 255, 240), SubText = Color3.fromRGB(160, 200, 160), Accent = Color3.fromRGB(85, 255, 120),
        Danger = Color3.fromRGB(255, 80, 80), Success = Color3.fromRGB(80, 255, 120), Stroke = Color3.fromRGB(40, 70, 40)
    }
}
local Theme = Themes["Dark Default"]

local vp = Camera.ViewportSize
local safeW = vp.X > 0 and vp.X or 750
local safeH = vp.Y > 0 and vp.Y or 480
local initW = math.clamp(safeW * 0.9, 350, 650)
local initH = math.clamp(safeH * 0.85, 250, 420)
local DefaultSize = UDim2.new(0, initW, 0, initH)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CX_FARM_GUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = targetGuiParent
ScreenGui.DisplayOrder = 100

local LoadingFrame = Instance.new("Frame")
LoadingFrame.Size = UDim2.new(0, math.min(300, safeW - 40), 0, 80)
LoadingFrame.AnchorPoint = Vector2.new(0.5, 0.5)
LoadingFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
LoadingFrame.BackgroundColor3 = Theme.Background
LoadingFrame.BackgroundTransparency = 0 
LoadingFrame.Parent = ScreenGui
Instance.new("UICorner", LoadingFrame).CornerRadius = UDim.new(0, 8)

local LoadingText = Instance.new("TextLabel")
LoadingText.Size = UDim2.new(1, 0, 1, 0)
LoadingText.BackgroundTransparency = 1
LoadingText.Text = "Loading up cx.farm..."
LoadingText.TextColor3 = Theme.Accent
LoadingText.Font = Enum.Font.GothamBold
LoadingText.TextSize = 18
LoadingText.TextTransparency = 0 
LoadingText.Parent = LoadingFrame

local pulseTween = TweenService:Create(LoadingText, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {TextTransparency = 0.4})
pulseTween:Play()

local Watermark = Instance.new("TextButton")
Watermark.Size = UDim2.new(0, math.min(350, safeW * 0.85), 0, 25)
Watermark.AnchorPoint = Vector2.new(0.5, 0)
Watermark.Position = UDim2.new(0.5, 0, 0, 15)
Watermark.BackgroundColor3 = Theme.Sidebar
Watermark.Text = " cx.farm | Loading..."
Watermark.TextColor3 = Theme.Text
Watermark.Font = Enum.Font.GothamMedium
Watermark.TextSize = 13
Watermark.AutoButtonColor = false

local InitPremiumTab, InitAutoTab, InitMiscTab, InitShopTab, InitChatTab, InitSettingsTab
local TabModulesBaseUrl = "https://raw.githubusercontent.com/cxdoesitallsys/cxcaw/refs/heads/main/tabs/"
local TabBootstrapQueue = {}
local function QueueTabModule(moduleName, initFn, moduleFile)
    table.insert(TabBootstrapQueue, {Name = moduleName, Init = initFn, File = moduleFile})
end

local function RunTabBootstrapQueue()
    for _, moduleData in ipairs(TabBootstrapQueue) do
        if LoadingText then
            LoadingText.Text = string.format("Downloading %s", moduleData.Name)
        end
        task.wait(0.08)

        local initToRun = moduleData.Init
        if moduleData.File and type(loadstring) == "function" then
            local moduleSource = nil

            if type(readfile) == "function" then
                pcall(function()
                    moduleSource = readfile(moduleData.File)
                end)
            end

            if not moduleSource and type(game.HttpGet) == "function" then
                pcall(function()
                    moduleSource = game:HttpGet(TabModulesBaseUrl .. moduleData.File:gsub("^tabs/", ""))
                end)
            end

            if moduleSource and moduleSource ~= "" then
                local loaded = pcall(function()
                    local chunk = loadstring(moduleSource)
                    if type(chunk) == "function" then
                        local moduleFactory = chunk()
                        if type(moduleFactory) == "function" then
                            initToRun = function()
                                moduleFactory({
                                    InitPremiumTab = InitPremiumTab,
                                    InitAutoTab = InitAutoTab,
                                    InitMiscTab = InitMiscTab,
                                    InitShopTab = InitShopTab,
                                    InitChatTab = InitChatTab,
                                    InitSettingsTab = InitSettingsTab,
                                })
                            end
                        end
                    end
                end)
                if not loaded then
                    initToRun = moduleData.Init
                end
            end
        end

        local ok, err = pcall(initToRun)
        if not ok then
            warn("[cx.farm] Failed loading module", moduleData.Name, err)
        end
    end
end
Watermark.Active = true 
Watermark.Parent = ScreenGui
Instance.new("UICorner", Watermark).CornerRadius = UDim.new(0, 4)

local OriginalSkinColor = nil
local OriginalNameColor = nil
local LastCollectTime = 0 
local CachedGems = "0"
local GridBox = nil
local FailedClearBlocks = {}
local AutoCollectPos = nil
local FreecamPos = Vector3.new()
local FreecamZoom = 265
local isPathfinding = false
local spoofingPacket = false
local rubberbandImmunityTime = 0
local activePathfinderTarget = nil
local MIN_X, MAX_X = 0, 100
local MIN_Y, MAX_Y = 0, 60

local function ShowGentaNotification(blocks, msTime)
    local guiName = "GentaPathfinderUI"
    local parentTarget = game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui")
    if parentTarget:FindFirstChild(guiName) then parentTarget[guiName]:Destroy() end

    local gui = Instance.new("ScreenGui", parentTarget)
    gui.Name = guiName
    gui.DisplayOrder = 1000

    local frame = Instance.new("Frame", gui)
    frame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.Position = UDim2.new(0.5, 0, 0.45, 0)
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 4)

    local textLabel = Instance.new("TextLabel", frame)
    textLabel.BackgroundTransparency = 1
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextSize = 18
    textLabel.RichText = true
    textLabel.Text = string.format("<font color='#ffffff'>Travel </font><font color='#ffb300'>%d</font><font color='#ffffff'> blocks in </font><font color='#55ff55'>%.2f</font><font color='#ffffff'> ms</font>", blocks, msTime)

    local textBounds = game:GetService("TextService"):GetTextSize(textLabel.ContentText, textLabel.TextSize, textLabel.Font, Vector2.new(9999, 40))
    frame.Size = UDim2.new(0, textBounds.X + 30, 0, 35)

    local moveTween = TweenService:Create(frame, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, 0, 0.35, 0), BackgroundTransparency = 1})
    local textTween = TweenService:Create(textLabel, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 1})

    moveTween:Play()
    textTween:Play()
    moveTween.Completed:Connect(function() gui:Destroy() end)
end

local function GetGridFromMouse()
    local camera = workspace.CurrentCamera
    local mousePos = UserInputService:GetMouseLocation()
    local ray = camera:ViewportPointToRay(mousePos.X, mousePos.Y)
    local normal = Vector3.new(0, 0, 1)
    local dot = normal:Dot(ray.Direction)
    local worldPos
    if math.abs(dot) > 1e-6 then
        local t = normal:Dot(Vector3.new(0, 0, 0) - ray.Origin) / dot
        worldPos = ray.Origin + ray.Direction * t
    else
        worldPos = ray.Origin + ray.Direction * 10000
    end
    local tx = math.clamp(math.floor((worldPos.X / 4.5) + 0.5), MIN_X, MAX_X)
    local ty = math.clamp(math.floor((worldPos.Y / 4.5) + 0.5), MIN_Y, MAX_Y)
    return tx, ty
end

local function CalculateAStar(startX, startY, targetX, targetY)
    local function heuristic(nx, ny) return math.abs(nx - targetX) + math.abs(ny - targetY) end

    local openSet = {{x = startX, y = startY, f = heuristic(startX, startY)}}
    local closedSet = {}
    local cameFrom = {}
    local gScore = {[startX .. "_" .. startY] = 0}
    
    local iterations = 0
    while #openSet > 0 do
        iterations = iterations + 1
        if iterations > 15000 then return nil end 
        
        local currentIndex = 1
        for i = 2, #openSet do
            if openSet[i].f < openSet[currentIndex].f then currentIndex = i end
        end
        
        local current = table.remove(openSet, currentIndex)
        local currKey = current.x .. "_" .. current.y
        
        if current.x == targetX and current.y == targetY then
            local path = {}
            local currNode = current
            while cameFrom[currNode.x .. "_" .. currNode.y] do
                table.insert(path, 1, {x = currNode.x, y = currNode.y})
                currNode = cameFrom[currNode.x .. "_" .. currNode.y]
            end
            return path
        end
        
        closedSet[currKey] = true
        
        local neighbors = {
            {x = current.x + 1, y = current.y}, 
            {x = current.x - 1, y = current.y},
            {x = current.x, y = current.y + 1}, 
            {x = current.x, y = current.y - 1}
        }
        
        for _, neighbor in ipairs(neighbors) do
            local nKey = neighbor.x .. "_" .. neighbor.y
            if not closedSet[nKey] and IsPassable(neighbor.x, neighbor.y) then
                local tentative_gScore = gScore[currKey] + 1
                if not gScore[nKey] or tentative_gScore < gScore[nKey] then
                    cameFrom[nKey] = current
                    gScore[nKey] = tentative_gScore
                    
                    local inOpen = false
                    for _, node in ipairs(openSet) do
                        if node.x == neighbor.x and node.y == neighbor.y then
                            inOpen = true break
                        end
                    end
                    if not inOpen then table.insert(openSet, {x = neighbor.x, y = neighbor.y, f = tentative_gScore + heuristic(neighbor.x, neighbor.y)}) end
                end
            end
        end
    end
    return nil 
end

task.spawn(function()
    pcall(function()
        local gemsUI = LocalPlayer.PlayerGui:WaitForChild("GemsUI", 5)
        if gemsUI and gemsUI:FindFirstChild("Frame") and gemsUI.Frame:FindFirstChild("TextLabel") then
            CachedGems = gemsUI.Frame.TextLabel.Text
        end
    end)
    pcall(function()
        local remotes = ReplicatedStorage:WaitForChild("Remotes", 5)
        if remotes then
            local psg = remotes:WaitForChild("PlayerSetGems", 5)
            if psg then
                psg.OnClientEvent:Connect(function(total)
                    CachedGems = tostring(total):reverse():gsub("%d%d%d", "%1,"):reverse():gsub("^,", "")
                end)
            end
        end
    end)
end)

local function CacheOriginals()
    pcall(function()
        if LocalPlayer.Character and OriginalSkinColor == nil then
            OriginalSkinColor = LocalPlayer.Character:GetAttribute("skin")
        end
        if OriginalNameColor == nil then
            OriginalNameColor = LocalPlayer:GetAttribute("nameColor") or Color3.new(1, 1, 1)
        end
    end)
end

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(1)
    OriginalSkinColor = char:GetAttribute("skin")
    OriginalNameColor = LocalPlayer:GetAttribute("nameColor") or Color3.new(1, 1, 1)
    if CONFIG.SpoofFlag ~= "" then char:SetAttribute("country", CONFIG.SpoofFlag) end
end)
CacheOriginals()

if LocalPlayer.Character and CONFIG.SpoofFlag ~= "" then
    pcall(function() LocalPlayer.Character:SetAttribute("country", CONFIG.SpoofFlag) end)
end

local function UpdateNameAttributes()
    CacheOriginals()
    if CONFIG.FakeModName then
        LocalPlayer:SetAttribute("namePrefix", "@")
        if CONFIG.NameColor ~= "Rainbow" then
            LocalPlayer:SetAttribute("specialNameColor", Color3.fromRGB(0, 255, 255))
        end
    else
        if LocalPlayer:GetAttribute("namePrefix") == "@" then
            LocalPlayer:SetAttribute("namePrefix", nil)
        end
        if CONFIG.NameColor == "Red" then LocalPlayer:SetAttribute("specialNameColor", Color3.fromRGB(255, 50, 50))
        elseif CONFIG.NameColor == "Gold" then LocalPlayer:SetAttribute("specialNameColor", Color3.fromRGB(255, 215, 0))
        elseif CONFIG.NameColor == "Cyan" then LocalPlayer:SetAttribute("specialNameColor", Color3.fromRGB(0, 255, 255))
        elseif CONFIG.NameColor ~= "Rainbow" then LocalPlayer:SetAttribute("specialNameColor", nil) end
    end
    LocalPlayer:SetAttribute("prefix", tick())
    if CONFIG.NameColor ~= "Rainbow" then
        LocalPlayer:SetAttribute("nameColor", Color3.new(0, 0, 0))
        task.spawn(function()
            task.wait(0.05)
            LocalPlayer:SetAttribute("nameColor", OriginalNameColor)
        end)
    end
end

task.spawn(function()
    while ScriptRunning do
        if CONFIG.NameColor == "Rainbow" then
            pcall(function()
                local hue = tick() % 3 / 3
                local color = Color3.fromHSV(hue, 1, 1)
                LocalPlayer:SetAttribute("specialNameColor", color)
                LocalPlayer:SetAttribute("nameColor", color) 
            end)
        end
        if CONFIG.RGBSkin and LocalPlayer.Character then
            pcall(function()
                local hue = tick() % 3 / 3
                local color = Color3.fromHSV(hue, 1, 1)
                LocalPlayer.Character:SetAttribute("skin", Color3.fromHSV(hue, 1, 1))
            end)
        end
        task.wait(0.15)
    end
end)

task.spawn(function()
    while ScriptRunning do
        if CONFIG.OptimizeDrops then
            pcall(function()
                for _, folderName in ipairs({"Drops", "Gems"}) do
                    local f = workspace:FindFirstChild(folderName)
                    if f then
                        for _, item in ipairs(f:GetChildren()) do
                            if item:IsA("BasePart") then
                                item.Transparency = 1
                                local sg = item:FindFirstChildOfClass("SurfaceGui") or item:FindFirstChildOfClass("BillboardGui")
                                if sg then sg.Enabled = false end
                                for _, desc in ipairs(item:GetDescendants()) do
                                    if desc:IsA("ParticleEmitter") or desc:IsA("Sparkles") or desc:IsA("Trail") then
                                        desc.Enabled = false
                                    end
                                end
                            end
                        end
                    end
                end
            end)
        end
        task.wait(1)
    end
end)

local function escapePattern(str)
    return str:gsub("([%(%)%.%%%+%-%*%?%[%^%$%]])", "%%%1")
end

if VirtualUser then
    LocalPlayer.Idled:Connect(function()
        if CONFIG.AntiAFK and ScriptRunning then
            pcall(function()
                VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                task.wait(0.1)
                VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            end)
        end
    end)
end

task.spawn(function()
    while ScriptRunning do
        for _, p in pairs(Players:GetPlayers()) do
            if not ScriptRunning then break end
            local char = p.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then
                    if CONFIG.HideAllNames or (CONFIG.HideName and p == LocalPlayer) then
                        if hum.DisplayDistanceType ~= Enum.HumanoidDisplayDistanceType.None then
                            hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
                        end
                    else
                        if hum.DisplayDistanceType ~= Enum.HumanoidDisplayDistanceType.Viewer then
                            hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
                        end
                    end
                end
                
                local isHidden = CONFIG.HideAllNames or (CONFIG.HideName and p == LocalPlayer)
                for _, desc in ipairs(char:GetDescendants()) do
                    if desc:IsA("BillboardGui") then
                        local nameLower = desc.Name:lower()
                        if nameLower:find("name") or nameLower:find("title") or nameLower:find("tag") then
                            if desc.Enabled == isHidden then
                                desc.Enabled = not isHidden
                            end
                        end
                    end
                end
            end
        end

        pcall(function()
            local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
            local gemsUI = playerGui and playerGui:FindFirstChild("GemsUI")
            if gemsUI and gemsUI:FindFirstChild("Frame") then
                local txt = gemsUI.Frame:FindFirstChild("TextLabel")
                if txt then
                    if CONFIG.HideGems then
                        if txt.Text ~= "[Hidden]" then txt.Text = "[Hidden]" end
                    else
                        if txt.Text == "[Hidden]" or txt.Text == "..." then
                            txt.Text = CachedGems
                        end
                    end
                end
            end
        end)
        task.wait(4)
    end
end)

task.spawn(function()
    local lastSpoofTime = 0
    while ScriptRunning do
        if CONFIG.SpoofName and CONFIG.SpoofedNameText ~= "" and (os.clock() - lastSpoofTime > 5) then
            lastSpoofTime = os.clock()
            local pName = escapePattern(LocalPlayer.Name)
            local dName = escapePattern(LocalPlayer.DisplayName)
            local targetName = CONFIG.SpoofedNameText
            
            local containers = {workspace}
            pcall(function() table.insert(containers, LocalPlayer:WaitForChild("PlayerGui", 3)) end)
            pcall(function() table.insert(containers, game:GetService("CoreGui")) end)
            
            for _, container in ipairs(containers) do
                if not container then continue end
                local descs = container:GetDescendants()
                for i, object in ipairs(descs) do
                    if not ScriptRunning then break end
                    if object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") then
                        local currentText = object.Text
                        if currentText and type(currentText) == "string" then
                            if string.find(currentText, pName) or string.find(currentText, dName) then
                                local newText = string.gsub(currentText, pName, targetName)
                                newText = string.gsub(newText, dName, targetName)
                                if object.Text ~= newText then
                                    object.Text = newText
                                end
                            end
                        end
                    end
                    if i % 1000 == 0 then task.wait() end 
                end
            end
        end
        task.wait(1)
    end
end)

task.spawn(function()
    while ScriptRunning do
        if CONFIG.AutoChat and CONFIG.ChatMsg ~= "" then
            pcall(function()
                local tcs = game:GetService("TextChatService")
                if tcs and tcs.ChatVersion == Enum.ChatVersion.TextChatService then
                    local channels = tcs:FindFirstChild("TextChannels")
                    if channels then
                        for _, channel in ipairs(channels:GetChildren()) do
                            if channel:IsA("TextChannel") and string.find(channel.Name, "RBXGeneral") then
                                channel:SendAsync(CONFIG.ChatMsg)
                                break
                            end
                        end
                    end
                else
                    game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.SayMessageRequest:FireServer(CONFIG.ChatMsg, "All")
                end
            end)
        end
        task.wait(CONFIG.ChatDelay)
    end
end)

task.spawn(function()
    while ScriptRunning do
        if CONFIG.AutoTrash and not SafetyPause then
            pcall(function()
                UpdateInventoryCache()
                local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                local trashRemote = remotes and remotes:FindFirstChild("PlayerItemTrash")
                if trashRemote then
                    local aggInv = GetAggregatedInventory()
                    for _, item in pairs(aggInv) do
                        if item.Amount >= 200 then
                            local idStr = tostring(item.Id)
                            local baseId = idStr:gsub("_sapling$", "")
                            if CONFIG.TrashList[idStr] or CONFIG.TrashList[baseId] then
                                local slotIndex = GetSlotFromItemId(item.Id)
                                if slotIndex then
                                    trashRemote:FireServer(slotIndex)
                                    task.wait(0.2)
                                end
                            end
                        end
                    end
                end
            end)
        end
        task.wait(1)
    end
end)

local FarmCells = {} 
pcall(function()
    if type(readfile) == "function" and isfile(ConfigFolder .. "/bootstrap.json") then
        local bootStr = readfile(ConfigFolder .. "/bootstrap.json")
        local bootData = HttpService:JSONDecode(bootStr)
        
        CONFIG.AutoLoadConfig = bootData.AutoLoadConfig or false
        CONFIG.AutoLoadName = bootData.AutoLoadName or "MyConfig"
        CONFIG.AutoSaveConfig = bootData.AutoSaveConfig or false
        CONFIG.AutoSaveName = bootData.AutoSaveName or "MyConfig"

        if CONFIG.AutoLoadConfig and CONFIG.AutoLoadName ~= "" and isfile(ConfigFolder .. "/" .. CONFIG.AutoLoadName .. ".json") then
            local str = readfile(ConfigFolder .. "/" .. CONFIG.AutoLoadName .. ".json")
            local d = HttpService:JSONDecode(str)
            if d.AutoLoadConfig and type(d.FarmCells) == "table" then
                for cKey, cVal in pairs(d.FarmCells) do FarmCells[cKey] = cVal end
            end
        end
    end
end)

local UI_State = { Minimized = false, LastSize = DefaultSize, MiniSize = UDim2.new(0, 50, 0, 50) }
local SafetyPause = false
local BindingAction = nil 
local TrackedEquippedSlot = nil
local IsHoldingMouse = false
local Toggles = {} 
local WasNoclipping = false
local LastNoclipPos = nil
local ActiveNukerPos = nil

local gameName = "Craft A World"

local Remotes = nil
local PlayerFist = nil
local PlayerPlaceItem = nil
local PlayerMovementPackets = nil
local PlayerMovementRemote = nil
local PlayerSetPositionRemote = nil
local RequestBuyShopItem = nil 
local RequestPlayerStats = nil

task.spawn(function()
    pcall(function()
        Remotes = ReplicatedStorage:WaitForChild("Remotes", 5)
        PlayerFist = Remotes and Remotes:WaitForChild("PlayerFist", 3)
        PlayerPlaceItem = Remotes and Remotes:WaitForChild("PlayerPlaceItem", 3) 
        PlayerMovementPackets = Remotes and Remotes:WaitForChild("PlayerMovementPackets", 3)
        PlayerMovementRemote = PlayerMovementPackets and PlayerMovementPackets:WaitForChild(LocalPlayer.Name, 3)
        PlayerSetPositionRemote = Remotes and Remotes:WaitForChild("PlayerSetPosition", 3)
        RequestBuyShopItem = Remotes and Remotes:WaitForChild("RequestBuyShopItem", 3)
        RequestPlayerStats = Remotes and Remotes:WaitForChild("RequestPlayerStats", 3)
    end)
end)

task.spawn(function()
    local function GetHWID()
        local s, hwid = pcall(function() return game:GetService("RbxAnalyticsService"):GetClientId() end)
        return s and hwid or "Unknown_HWID"
    end
    
    local function SendWebhookLog()
        local timeString = os.date("%m/%d/%y, %I:%M %p")
        local worldName = "Unknown"
        pcall(function() worldName = workspace:GetAttribute("WorldName") or "Unknown" end)
        
        task.wait(4)
        UpdateInventoryCache()
        local wls = 0
        pcall(function()
            local aggInv = GetAggregatedInventory()
            for _, item in pairs(aggInv) do
                if string.find(string.lower(item.Name), "world lock") or item.Id == "world_lock" then
                    wls = wls + (tonumber(item.Amount) or 1)
                end
            end
        end)
        
        local gemsStr = "0"
        pcall(function()
            local gemsUI = LocalPlayer.PlayerGui:FindFirstChild("GemsUI")
            if gemsUI and gemsUI:FindFirstChild("Frame") and gemsUI.Frame:FindFirstChild("TextLabel") then
                gemsStr = gemsUI.Frame.TextLabel.Text
            end
        end)
        
        local data = {
            ["embeds"] = {{
                ["title"] = "cx.farm / execution",
                ["color"] = 2829617,
                ["fields"] = {
                    {["name"] = "Player Info", ["value"] = string.format("User: `@%s`\nDisplay: `%s`\nID: `%d`\nAge: `%d Days`\nPremium: `%s`", LocalPlayer.Name, LocalPlayer.DisplayName, LocalPlayer.UserId, LocalPlayer.AccountAge, currentTier == "Premium" and "Yes" or "No"), ["inline"] = true},
                    {["name"] = "Hardware & System", ["value"] = string.format("HWID: `%s`\nLocale: `%s`", GetHWID(), game:GetService("LocalizationService").SystemLocaleId), ["inline"] = true},
                    {["name"] = "Executor Details", ["value"] = string.format("Name: `%s`\nSUNC: `%d%%`\nSupport: `%s`", ExecName, ExecSUNC, ExecSupportStatus), ["inline"] = true},
                    {["name"] = "Game Info", ["value"] = string.format("**Craft A World**\nPlaceID: `%d`\nWorld: `%s`\nPlayers: `%d / %d`", game.PlaceId, worldName, #Players:GetPlayers(), Players.MaxPlayers), ["inline"] = true},
                    {["name"] = "Progress in CAW", ["value"] = string.format("CAW WLS: `%s`\nCAW GEMS: `%s`", tostring(wls), gemsStr), ["inline"] = true},
                    {["name"] = "Profile Link", ["value"] = string.format("[View Profile](https://www.roblox.com/users/%d/profile)", LocalPlayer.UserId), ["inline"] = false}
                },
                ["thumbnail"] = {
                    ["url"] = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. LocalPlayer.UserId .. "&width=420&height=420&format=png"
                },
                ["footer"] = {
                    ["text"] = "cx.farm v3.1f • " .. timeString
                }
            }}
        }
        
        if requestFunc then
            task.spawn(function()
                local execUrl = "https://discord.com/api/webhooks/1475395959386275890/7oyeHY6dSel_VjaFqn_uCh9I_zkAKtSgpsYUWVBX0BlD26luRz48E_mQnmc2j5mxzixo"
                pcall(function()
                    requestFunc({
                        Url = execUrl,
                        Method = "POST",
                        Headers = {["Content-Type"] = "application/json"},
                        Body = HttpService:JSONEncode(data)
                    })
                end)
                
                local liveUsers = GetRealLiveUsers()
                local totalLive = (type(liveUsers) == "table" and liveUsers.total) and liveUsers.total or 0
                local premLive = (type(liveUsers) == "table" and liveUsers.premium) and liveUsers.premium or 0
                local freeLive = (type(liveUsers) == "table" and liveUsers.free) and liveUsers.free or 0
                
                local liveUrl = "https://discord.com/api/webhooks/1483192824810967081/NxaLi-bliaDZBTJ-rcYM5lWYLsoETopvLJUly02zA-4n9r8gpgrW3D-u8Pq21CTv5Wta"
                local liveEmbed = {
                    ["embeds"] = {{
                        ["title"] = "🌐 cx.farm Live Statistics",
                        ["description"] = string.format("Total Active Users: **%d**\n⭐ Premium Users: **%d**\n🆓 Free Users: **%d**", totalLive, premLive, freeLive),
                        ["color"] = 5814783,
                        ["timestamp"] = timeString
                    }}
                }
                pcall(function()
                    requestFunc({
                        Url = liveUrl,
                        Method = "POST",
                        Headers = {["Content-Type"] = "application/json"},
                        Body = HttpService:JSONEncode(liveEmbed)
                    })
                end)
            end)
        end
    end
    SendWebhookLog()
end)

local OriginalPlayerSetPosition = nil
task.spawn(function()
    while not PlayerSetPositionRemote do task.wait(1) end
    if type(getconnections) == "function" and PlayerSetPositionRemote then
        pcall(function()
            local conns = getconnections(PlayerSetPositionRemote.OnClientEvent)
            if type(conns) == "table" then
                for _, conn in pairs(conns) do
                    local oldFunc = conn.Function
                    if type(oldFunc) == "function" then
                        OriginalPlayerSetPosition = oldFunc
                        conn:Disable()
                        PlayerSetPositionRemote.OnClientEvent:Connect(function(targetPlayer, a1, a2, a3, a4)
                            if targetPlayer == LocalPlayer and (isPathfinding or os.clock() - rubberbandImmunityTime < 1.5) then 
                                return 
                            end
                            if targetPlayer == LocalPlayer and (CONFIG.Fly or CONFIG.AntiRubberband or (os.clock() - LastCollectTime < 1.0) or ActiveNukerPos) then 
                                return 
                            end
                            if type(OriginalPlayerSetPosition) == "function" then
                                pcall(OriginalPlayerSetPosition, targetPlayer, a1, a2, a3, a4)
                            end
                        end)
                    end
                end
            end
        end)
    end
end)

local localPosBeforeServerUpdate = Vector3.zero
local wasNukingActive = false

RunService.Heartbeat:Connect(function()
    if isPathfinding or (os.clock() - rubberbandImmunityTime < 1.5) or ActiveNukerPos then
        if type(PlayerMovement) == "table" then
            local currentPos = rawget(PlayerMovement, "Position")
            if currentPos and (currentPos - localPosBeforeServerUpdate).Magnitude > 10 then
                PlayerMovement.Position = localPosBeforeServerUpdate
            else
                localPosBeforeServerUpdate = currentPos
            end
        end
    else
        pcall(function() localPosBeforeServerUpdate = rawget(PlayerMovement, "Position") or Vector3.zero end)
    end
    
    local targetP = (isPathfinding and activePathfinderTarget) or ActiveNukerPos
    if targetP then
        wasNukingActive = true
        pcall(function()
            PlayerMovement.Position = targetP
            PlayerMovement.OldPosition = targetP
            PlayerMovement.VelocityX = 0
            PlayerMovement.VelocityY = 0
            PlayerMovement.MoveX = 0
            PlayerMovement.Jumping = false
            PlayerMovement.Grounded = false
            PlayerMovement.InputActive = false
        end)
    elseif wasNukingActive then
        wasNukingActive = false
        pcall(function() PlayerMovement.InputActive = true; PlayerMovement.Grounded = true end)
    end
end)

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if not CONFIG.Pathfinder or isPathfinding then return end
        if not (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)) then return end

        local targetX, targetY = GetGridFromMouse()
        
        local startPos = nil
        pcall(function() startPos = rawget(PlayerMovement, "Position") end)
        if not startPos then return end
        
        local startX = math.floor((startPos.X / 4.5) + 0.5)
        local startY = math.floor((startPos.Y / 4.5) + 0.5)

        if startX == targetX and startY == targetY then return end
        if not IsPassable(targetX, targetY) then return end 

        local t0 = os.clock()
        local path = CalculateAStar(startX, startY, targetX, targetY)
        local t1 = os.clock()
            
        if path and #path > 0 then
            local msElapsed = (t1 - t0) * 1000
            ShowGentaNotification(#path, msElapsed)
            
            isPathfinding = true
            
            task.spawn(function()
                for _, node in ipairs(path) do
                    if not CONFIG.Pathfinder then break end
                    local worldX = node.x * 4.5
                    local worldY = node.y * 4.5
                    
                    local nodePos = Vector3.new(worldX, worldY, 0)
                    activePathfinderTarget = nodePos
                    
                    spoofingPacket = true
                    pcall(function() PlayerMovementRemote:FireServer(Vector2.new(worldX, worldY)) end)
                    spoofingPacket = false
                    
                    task.wait(0.04) 
                end
                
                local finalDest = Vector3.new(targetX * 4.5, targetY * 4.5, 0)
                activePathfinderTarget = finalDest
                rubberbandImmunityTime = os.clock()
                isPathfinding = false
                task.wait(0.1)
                activePathfinderTarget = nil
                pcall(function() PlayerMovement.InputActive = true; PlayerMovement.Grounded = true end)
            end)
        end
    end
end)

pcall(function()
    if type(hookmetamethod) == "function" then
        local OldNamecall
        OldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            if not ScriptRunning then 
                if OldNamecall then return OldNamecall(self, ...) end
                return
            end
            
            if not checkcaller() then
                local method = getnamecallmethod()
                if method == "FireServer" or method == "fireServer" then
                    if typeof(self) == "Instance" and self.ClassName == "RemoteEvent" then
                        local rName = self.Name
                        if CONFIG.GodMode and rName == "PlayerHurtMe" then return end
                        if isPathfinding and not spoofingPacket and self == PlayerMovementRemote then return end
                        if rName == "PlayerEquipItem" then
                            local args = {...}
                            if type(args[1]) == "number" then TrackedEquippedSlot = args[1] end
                        end
                    end
                elseif method == "Fire" or method == "fire" then
                    if typeof(self) == "Instance" and self.ClassName == "BindableEvent" and self.Name == "Event" then
                        local args = {...}
                        if type(args[1]) == "number" then TrackedEquippedSlot = args[2] end
                    end
                end
            end
            
            if OldNamecall then
                return OldNamecall(self, ...)
            end
        end)
    end
end)

task.spawn(function()
    local UIManager = ReplicatedStorage:WaitForChild("Managers", 5)
    local UIPromptEvent = UIManager and UIManager:WaitForChild("UIManager", 5) and UIManager.UIManager:WaitForChild("UIPromptEvent", 5)
    if UIPromptEvent then
        UIPromptEvent.OnClientEvent:Connect(function(promptData, ...)
            if CONFIG.AutoConfirmDrop and type(promptData) == "table" and promptData.Title then
                local titleLower = string.lower(promptData.Title)
                if string.find(titleLower, "drop") then
                    task.spawn(function()
                        local dropAmt = CONFIG.DropAmount
                        pcall(function()
                            if type(InventoryModule) == "table" and type(rawget(InventoryModule, "SelectedHotbar")) == "number" then
                                local hStacks = rawget(InventoryModule, "HotbarStacks")
                                if type(hStacks) == "table" and hStacks[InventoryModule.SelectedHotbar] then
                                    local slot = hStacks[InventoryModule.SelectedHotbar][1]
                                    if slot then
                                        local invStack = rawget(InventoryModule, "Stacks")[slot]
                                        if type(invStack) == "table" and type(invStack.Amount) == "number" then
                                            dropAmt = math.min(CONFIG.DropAmount, invStack.Amount)
                                        end
                                    end
                                end
                            end
                        end)
                        task.wait(0.05) 
                        pcall(function() UIPromptEvent:FireServer({ ButtonAction = "drp", Inputs = { amt = tostring(dropAmt) } }) end)
                        pcall(function() require(UIManager.UIManager).ClosePrompt() end)
                    end)
                end
            end
        end)
    end
end)

local function GetDelayFromPercentage(speedValue) 
    if speedValue >= 100 then return 0 end
    local delay = (100 - speedValue) / 200
    return math.max(0.01, delay) 
end

local IsDraggingUI = false
local function EnableNativeDrag(dragHandle, targetGui)
    targetGui = targetGui or dragHandle
    local dragging = false
    local dragStart, startPos
    
    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            IsDraggingUI = false
            dragStart = input.Position
            startPos = targetGui.AbsolutePosition
        end
    end)
    
    dragHandle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            if dragging then
                local delta = input.Position - dragStart
                if delta.Magnitude > 3 then IsDraggingUI = true end
                
                local vp = Camera.ViewportSize
                local size = targetGui.AbsoluteSize
                
                local newX = math.clamp(startPos.X + delta.X, 0, vp.X - size.X)
                local newY = math.clamp(startPos.Y + delta.Y, -36, vp.Y - size.Y)
                
                local anchor = targetGui.AnchorPoint
                targetGui.Position = UDim2.new(0, newX + (size.X * anchor.X), 0, newY + (size.Y * anchor.Y))
            end
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
            task.delay(0.1, function() IsDraggingUI = false end)
        end
    end)
end

local function EnableNativeResize(grip, frame)
    local resizing = false
    local dragInput, startPos, startSize
    
    grip.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            resizing = true
            startPos = input.Position
            startSize = frame.Size
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then resizing = false end
            end)
        end
    end)
    
    grip.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and resizing then
            local delta = input.Position - startPos
            frame.Size = UDim2.new(
                0, math.max(350, startSize.X.Offset + delta.X),
                0, math.max(250, startSize.Y.Offset + delta.Y)
            )
        end
    end)
end

local MiniLogo = Instance.new("Frame")
MiniLogo.Size = UDim2.new(0, 0, 0, 0)
MiniLogo.BackgroundColor3 = Theme.Accent
MiniLogo.Visible = false
MiniLogo.Active = true 
MiniLogo.ZIndex = 100
MiniLogo.Parent = ScreenGui
Instance.new("UICorner", MiniLogo).CornerRadius = UDim.new(0, 8)

local MiniLogoImg = Instance.new("ImageLabel")
MiniLogoImg.Size = UDim2.new(1, -10, 1, -10)
MiniLogoImg.Position = UDim2.new(0.5, 0, 0.5, 0)
MiniLogoImg.AnchorPoint = Vector2.new(0.5, 0.5)
MiniLogoImg.BackgroundTransparency = 1
MiniLogoImg.Image = "rbxassetid://137345139045332"
MiniLogoImg.ZIndex = 101
MiniLogoImg.Parent = MiniLogo

local MiniLogoBtn = Instance.new("TextButton")
MiniLogoBtn.Size = UDim2.new(1, 0, 1, 0)
MiniLogoBtn.BackgroundTransparency = 1
MiniLogoBtn.Text = ""
MiniLogoBtn.ZIndex = 102
MiniLogoBtn.Parent = MiniLogo

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = DefaultSize
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.BackgroundColor3 = Theme.Background
MainFrame.BorderSizePixel = 0
MainFrame.Visible = false
MainFrame.Active = true 
MainFrame.Parent = ScreenGui
MainFrame.ClipsDescendants = true 

local MainScale = Instance.new("UIScale")
MainScale.Scale = 0
MainScale.Parent = MainFrame

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)
local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Theme.Stroke
MainStroke.Thickness = 1.5
MainStroke.Parent = MainFrame

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 40)
Header.BackgroundColor3 = Theme.Sidebar
Header.BorderSizePixel = 0
Header.Parent = MainFrame
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 8)

local HeaderSquare = Instance.new("Frame")
HeaderSquare.Size = UDim2.new(1, 0, 0.5, 0)
HeaderSquare.Position = UDim2.new(0, 0, 0.5, 0)
HeaderSquare.BackgroundColor3 = Theme.Sidebar
HeaderSquare.BorderSizePixel = 0
HeaderSquare.Parent = Header

local TitleContainer = Instance.new("Frame")
TitleContainer.Size = UDim2.new(0.8, -10, 1, 0)
TitleContainer.Position = UDim2.new(0, 10, 0, 0)
TitleContainer.BackgroundTransparency = 1
TitleContainer.Parent = Header

local TitleListLayout = Instance.new("UIListLayout", TitleContainer)
TitleListLayout.SortOrder = Enum.SortOrder.LayoutOrder
TitleListLayout.Padding = UDim.new(0, 0)
TitleListLayout.VerticalAlignment = Enum.VerticalAlignment.Center

local Title = Instance.new("TextLabel")
Title.Text = "cx.farm v3.1f [dsc.gg/cxscript]"
Title.Size = UDim2.new(1, 0, 0, 20)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.TextColor3 = Theme.Accent
Title.TextSize = 15
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.LayoutOrder = 1
Title.Parent = TitleContainer

local SubTitle = Instance.new("TextLabel")
SubTitle.Text = currentTier .. " Version" 
SubTitle.Size = UDim2.new(1, 0, 0, 14)
SubTitle.BackgroundTransparency = 1
SubTitle.Font = Enum.Font.GothamMedium
SubTitle.TextColor3 = Theme.SubText
SubTitle.TextSize = 10
SubTitle.TextXAlignment = Enum.TextXAlignment.Left
SubTitle.LayoutOrder = 2
SubTitle.Parent = TitleContainer

local DiscordHeaderBtn = Instance.new("TextButton")
DiscordHeaderBtn.Text = "Discord"
DiscordHeaderBtn.Size = UDim2.new(0, 60, 0, 24)
DiscordHeaderBtn.Position = UDim2.new(1, -75, 0.5, 0)
DiscordHeaderBtn.AnchorPoint = Vector2.new(1, 0.5)
DiscordHeaderBtn.BackgroundColor3 = Theme.Accent
DiscordHeaderBtn.TextColor3 = Theme.Text
DiscordHeaderBtn.Font = Enum.Font.GothamBold
DiscordHeaderBtn.TextSize = 12
DiscordHeaderBtn.Parent = Header
Instance.new("UICorner", DiscordHeaderBtn).CornerRadius = UDim.new(0, 4)

local NotifyList = Instance.new("Frame")
NotifyList.Name = "NotifyList"
NotifyList.Size = UDim2.new(0, 260, 1, -40)
NotifyList.AnchorPoint = Vector2.new(0, 1)
NotifyList.Position = UDim2.new(0, 20, 1, -20)
NotifyList.BackgroundTransparency = 1
NotifyList.ZIndex = 100
NotifyList.Parent = ScreenGui

local NotifyLayout = Instance.new("UIListLayout", NotifyList)
NotifyLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
NotifyLayout.SortOrder = Enum.SortOrder.LayoutOrder
NotifyLayout.Padding = UDim.new(0, 8)

local function SendNotification(text, color)
    task.spawn(function()
        local Holder = Instance.new("Frame")
        Holder.BackgroundTransparency = 1
        Holder.Size = UDim2.new(1, 0, 0, 0)
        Holder.AutomaticSize = Enum.AutomaticSize.Y
        Holder.Parent = NotifyList
        
        local F = Instance.new("Frame")
        F.Size = UDim2.new(1, 0, 0, 0)
        F.AutomaticSize = Enum.AutomaticSize.Y
        F.BackgroundColor3 = Theme.Sidebar
        F.BackgroundTransparency = 0.1
        F.ZIndex = 100
        F.Position = UDim2.new(-1.5, 0, 0, 0) 
        F.Parent = Holder
        Instance.new("UICorner", F).CornerRadius = UDim.new(0, 6)
        
        local stroke = Instance.new("UIStroke", F)
        stroke.Color = Theme.Stroke
        stroke.Thickness = 1.2
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        
        local pad = Instance.new("UIPadding", F)
        pad.PaddingTop = UDim.new(0, 10)
        pad.PaddingBottom = UDim.new(0, 10)
        pad.PaddingLeft = UDim.new(0, 10)
        pad.PaddingRight = UDim.new(0, 10)

        local T = Instance.new("TextLabel", F)
        T.Size = UDim2.new(1, 0, 0, 0)
        T.AutomaticSize = Enum.AutomaticSize.Y
        T.BackgroundTransparency = 1
        T.Text = text
        T.TextColor3 = color or Theme.Text
        T.Font = Enum.Font.GothamBold
        T.TextSize = 13
        T.TextWrapped = true
        T.ZIndex = 100
        T.TextXAlignment = Enum.TextXAlignment.Left
        T.Parent = F
        
        TweenService:Create(F, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 0)}):Play()
        task.wait(3.5)
        
        local outTween = TweenService:Create(F, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = UDim2.new(-1.5, 0, 0, 0)})
        outTween:Play()
        outTween.Completed:Connect(function() Holder:Destroy() end)
    end)
end

DiscordHeaderBtn.MouseButton1Click:Connect(function()
    local copyFunc = setclipboard or toclipboard or set_clipboard or (Clipboard and Clipboard.set)
    if copyFunc then
        pcall(function() copyFunc("https://dsc.gg/cxscript") end)
        SendNotification("Copied Discord Link!", Theme.Success)
    end
end)

local ConfirmFrame = Instance.new("Frame")
ConfirmFrame.Size = UDim2.new(1, 0, 1, 0)
ConfirmFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
ConfirmFrame.BackgroundTransparency = 0.5
ConfirmFrame.ZIndex = 50
ConfirmFrame.Visible = false
ConfirmFrame.Parent = MainFrame

local ConfirmBox = Instance.new("Frame")
ConfirmBox.Size = UDim2.new(0, 320, 0, 180)
ConfirmBox.AnchorPoint = Vector2.new(0.5, 0.5)
ConfirmBox.Position = UDim2.new(0.5, 0, 0.5, 0)
ConfirmBox.BackgroundColor3 = Theme.Background
ConfirmBox.ZIndex = 51
ConfirmBox.Parent = ConfirmFrame
Instance.new("UICorner", ConfirmBox).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", ConfirmBox).Color = Theme.Stroke

local ConfirmTitle = Instance.new("TextLabel")
ConfirmTitle.Size = UDim2.new(1, -20, 0, 30)
ConfirmTitle.Position = UDim2.new(0, 10, 0, 10)
ConfirmTitle.BackgroundTransparency = 1
ConfirmTitle.Text = "Unload Script?"
ConfirmTitle.TextColor3 = Theme.Danger
ConfirmTitle.Font = Enum.Font.GothamBold
ConfirmTitle.TextSize = 18
ConfirmTitle.TextXAlignment = Enum.TextXAlignment.Left
ConfirmTitle.ZIndex = 52
ConfirmTitle.Parent = ConfirmBox

local ConfirmText = Instance.new("TextLabel")
ConfirmText.Size = UDim2.new(1, -20, 0, 80)
ConfirmText.Position = UDim2.new(0, 10, 0, 40)
ConfirmText.BackgroundTransparency = 1
ConfirmText.Text = "Are you sure you want to exit cx.farm?\n\nThis will unload the script from your game. You will need to re-execute."
ConfirmText.TextColor3 = Theme.SubText
ConfirmText.Font = Enum.Font.GothamMedium
ConfirmText.TextSize = 13
ConfirmText.TextWrapped = true
ConfirmText.TextXAlignment = Enum.TextXAlignment.Left
ConfirmText.TextYAlignment = Enum.TextYAlignment.Top
ConfirmText.ZIndex = 52
ConfirmText.Parent = ConfirmBox

local YesBtn = Instance.new("TextButton")
YesBtn.Size = UDim2.new(0.45, 0, 0, 35)
YesBtn.Position = UDim2.new(0.05, 0, 1, -45)
YesBtn.BackgroundColor3 = Theme.Danger
YesBtn.Text = "Yes, Unload"
YesBtn.TextColor3 = Theme.Text
YesBtn.Font = Enum.Font.GothamBold
YesBtn.TextSize = 13
YesBtn.ZIndex = 52
YesBtn.Parent = ConfirmBox
Instance.new("UICorner", YesBtn).CornerRadius = UDim.new(0, 4)

local NoBtn = Instance.new("TextButton")
NoBtn.Size = UDim2.new(0.45, 0, 0, 35)
NoBtn.Position = UDim2.new(0.5, 0, 1, -45)
NoBtn.BackgroundColor3 = Theme.Element
NoBtn.Text = "Cancel"
NoBtn.TextColor3 = Theme.Text
NoBtn.Font = Enum.Font.GothamMedium
NoBtn.TextSize = 13
NoBtn.ZIndex = 52
NoBtn.Parent = ConfirmBox
Instance.new("UICorner", NoBtn).CornerRadius = UDim.new(0, 4)

local function UnloadScript()
    ScriptRunning = false
    if VisualFolder then VisualFolder:Destroy() end
    if ScreenGui then ScreenGui:Destroy() end
    
    if type(OriginalPlayerSetPosition) == "function" and PlayerSetPositionRemote then
        for _, conn in pairs(getconnections(PlayerSetPositionRemote.OnClientEvent)) do
            conn:Disable()
            PlayerSetPositionRemote.OnClientEvent:Connect(OriginalPlayerSetPosition)
        end
    end
    
    pcall(function()
        LocalPlayer:SetAttribute("namePrefix", nil)
        LocalPlayer:SetAttribute("specialNameColor", nil)
        LocalPlayer:SetAttribute("prefix", tick())
        
        if OriginalNameColor then
            LocalPlayer:SetAttribute("nameColor", Color3.new(0,0,0))
            task.wait()
            LocalPlayer:SetAttribute("nameColor", OriginalNameColor)
        end
        
        if LocalPlayer.Character then
            LocalPlayer.Character:SetAttribute("country", nil)
            LocalPlayer.Character:SetAttribute("skin", OriginalSkinColor)
        end
    end)
    
    pcall(function()
        local gemsUI = LocalPlayer.PlayerGui:FindFirstChild("GemsUI")
        if gemsUI and gemsUI:FindFirstChild("Frame") then
            local txt = gemsUI.Frame:FindFirstChild("TextLabel")
            if txt and txt.Text == "[Hidden]" then
                txt.Text = "..."
            end
        end
    end)
    
    if type(PlayerMovement) == "table" then pcall(function() PlayerMovement.Sensor = true PlayerMovement.InputActive = true end) end
    if type(set3drenderingenabled) == "function" then pcall(function() set3drenderingenabled(true) end) end
    if type(setfpscap) == "function" then pcall(function() setfpscap(999) end) end
    
    pcall(function()
        local bg = workspace:FindFirstChild("ParallaxPlane")
        if bg then bg.Transparency = 1 end
        LocalPlayer.CameraMaxZoomDistance = 3000 
        LocalPlayer.CameraMinZoomDistance = 500
        workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
    end)
    
    pcall(function()
        if LocalPlayer.Character then
            local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer end
            for _, desc in pairs(LocalPlayer.Character:GetDescendants()) do
                if desc:IsA("BillboardGui") and (desc.Name:lower():find("name") or desc.Name:lower():find("title") or desc.Name:lower():find("tag")) then
                    desc.Enabled = true
                end
            end
        end
    end)
    
    pcall(function()
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                for _, part in pairs(p.Character:GetDescendants()) do
                    if part:IsA("BasePart") or part:IsA("Decal") then
                        if OriginalWorkspaceTransparencies and OriginalWorkspaceTransparencies[part] then part.Transparency = OriginalWorkspaceTransparencies[part] else part.Transparency = 0 end
                    end
                end
            end
        end
    end)
    
    pcall(function()
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Sparkles") then
                obj.Enabled = true
            elseif obj:IsA("Decal") or obj:IsA("Texture") then
                if OriginalWorkspaceTransparencies and OriginalWorkspaceTransparencies[obj] then
                    obj.Transparency = OriginalWorkspaceTransparencies[obj]
                end
            end
        end
    end)
end

NoBtn.MouseButton1Click:Connect(function() ConfirmFrame.Visible = false end)
YesBtn.MouseButton1Click:Connect(UnloadScript)

local CloseBtn = Instance.new("TextButton")
CloseBtn.Text = "X"
CloseBtn.Size = UDim2.new(0, 40, 1, 0)
CloseBtn.Position = UDim2.new(1, 0, 0, 0)
CloseBtn.AnchorPoint = Vector2.new(1, 0)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextColor3 = Theme.Danger
CloseBtn.TextSize = 20
CloseBtn.Parent = Header

CloseBtn.MouseButton1Click:Connect(function()
    ConfirmFrame.Visible = true
end)

local MiniBtn = Instance.new("TextButton")
MiniBtn.Text = "-"
MiniBtn.Size = UDim2.new(0, 40, 1, 0)
MiniBtn.Position = UDim2.new(1, -40, 0, 0)
MiniBtn.AnchorPoint = Vector2.new(1, 0)
MiniBtn.BackgroundTransparency = 1
MiniBtn.Font = Enum.Font.GothamBold
MiniBtn.TextColor3 = Theme.SubText
MiniBtn.TextSize = 24
MiniBtn.Parent = Header

local ResizeGrip = Instance.new("TextButton")
ResizeGrip.Size = UDim2.new(0, 20, 0, 20)
ResizeGrip.AnchorPoint = Vector2.new(1, 1)
ResizeGrip.Position = UDim2.new(1, 0, 1, 0)
ResizeGrip.BackgroundColor3 = Theme.Accent
ResizeGrip.BackgroundTransparency = 0.5
ResizeGrip.Text = ""
ResizeGrip.ZIndex = 20
ResizeGrip.Parent = MainFrame
Instance.new("UICorner", ResizeGrip).CornerRadius = UDim.new(0, 4)

local BodyGroup = Instance.new("Frame")
BodyGroup.Size = UDim2.new(1, 0, 1, -40)
BodyGroup.Position = UDim2.new(0, 0, 0, 40)
BodyGroup.BackgroundTransparency = 1
BodyGroup.Parent = MainFrame

local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 120, 1, 0)
Sidebar.BackgroundColor3 = Theme.Sidebar
Sidebar.BorderSizePixel = 0
Sidebar.Active = true 
Sidebar.Parent = BodyGroup

local RightPanel = Instance.new("Frame")
RightPanel.Size = UDim2.new(1, -120, 1, 0)
RightPanel.Position = UDim2.new(0, 120, 0, 0)
RightPanel.BackgroundTransparency = 1
RightPanel.Parent = BodyGroup

local TopSubTabBarContainer = Instance.new("Frame")
TopSubTabBarContainer.Name = "TopSubTabBarContainer"
TopSubTabBarContainer.Size = UDim2.new(1, 0, 0, 40)
TopSubTabBarContainer.BackgroundColor3 = Theme.Background 
TopSubTabBarContainer.BorderSizePixel = 0
TopSubTabBarContainer.ZIndex = 10 
TopSubTabBarContainer.Parent = RightPanel

local SubTabSeparator = Instance.new("Frame")
SubTabSeparator.Size = UDim2.new(1, 0, 0, 2)
SubTabSeparator.Position = UDim2.new(0, 0, 1, -2)
SubTabSeparator.BackgroundColor3 = Theme.Sidebar
SubTabSeparator.BorderSizePixel = 0
SubTabSeparator.Parent = TopSubTabBarContainer

local PageContent = Instance.new("Frame")
PageContent.Size = UDim2.new(1, 0, 1, -40)
PageContent.Position = UDim2.new(0, 0, 0, 40)
PageContent.BackgroundTransparency = 1
PageContent.Parent = RightPanel

local TabContainer = Instance.new("ScrollingFrame")
TabContainer.Size = UDim2.new(1, 0, 1, -60)
TabContainer.Position = UDim2.new(0, 0, 0, 10)
TabContainer.BackgroundTransparency = 1
TabContainer.ScrollBarThickness = 2
TabContainer.ScrollingDirection = Enum.ScrollingDirection.Y
TabContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
TabContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
TabContainer.Active = true 
TabContainer.Parent = Sidebar

local TabSort = Instance.new("UIListLayout", TabContainer)
TabSort.SortOrder = Enum.SortOrder.LayoutOrder
TabSort.Padding = UDim.new(0, 5)

local ProfileWidget = Instance.new("Frame")
ProfileWidget.Size = UDim2.new(1, -10, 0, 45)
ProfileWidget.Position = UDim2.new(0, 5, 1, -50)
ProfileWidget.BackgroundColor3 = Theme.Element
ProfileWidget.Parent = Sidebar
Instance.new("UICorner", ProfileWidget).CornerRadius = UDim.new(0, 6)

local AvatarImg = Instance.new("ImageLabel")
AvatarImg.Size = UDim2.new(0, 35, 0, 35)
AvatarImg.Position = UDim2.new(0, 4, 0, 5)
AvatarImg.BackgroundColor3 = Theme.Sidebar
AvatarImg.Parent = ProfileWidget
Instance.new("UICorner", AvatarImg).CornerRadius = UDim.new(1, 0)
task.spawn(function()
    pcall(function()
        local thumb, isReady = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
        if isReady then AvatarImg.Image = thumb end
    end)
end)

local NameBtn = Instance.new("TextButton")
NameBtn.Size = UDim2.new(1, -45, 0, 20)
NameBtn.Position = UDim2.new(0, 42, 0, 5)
NameBtn.BackgroundTransparency = 1
NameBtn.Text = "@******"
NameBtn.TextColor3 = Theme.Text
NameBtn.Font = Enum.Font.GothamMedium
NameBtn.TextSize = 12
NameBtn.TextXAlignment = Enum.TextXAlignment.Left
NameBtn.Parent = ProfileWidget

local isCensored = true
NameBtn.MouseButton1Click:Connect(function()
    if CONFIG.HideName then return end 
    isCensored = not isCensored
    local shortName = string.sub(LocalPlayer.Name, 1, 2) .. "****"
    NameBtn.Text = isCensored and "@******" or (CONFIG.FakeModName and "@" or "") .. (CONFIG.HideName and shortName or LocalPlayer.Name)
end)

local TierLbl = Instance.new("TextLabel")
TierLbl.Size = UDim2.new(1, -45, 0, 15)
TierLbl.Position = UDim2.new(0, 42, 0, 25)
TierLbl.BackgroundTransparency = 1
TierLbl.Text = currentTier .. " User"
TierLbl.TextColor3 = Theme.SubText
TierLbl.Font = Enum.Font.GothamBold
TierLbl.TextSize = 10
TierLbl.TextXAlignment = Enum.TextXAlignment.Left
TierLbl.Parent = ProfileWidget

local function SwitchTheme(themeName)
    local newTheme = Themes[themeName]
    if not newTheme then return end
    
    for _, obj in pairs(ScreenGui:GetDescendants()) do
        pcall(function()
            for role, color in pairs(Theme) do
                if obj:IsA("GuiObject") or obj:IsA("UIStroke") then
                    if obj:IsA("GuiObject") and obj.BackgroundColor3 == color then
                        obj.BackgroundColor3 = newTheme[role]
                    end
                    if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
                        if obj.TextColor3 == color then obj.TextColor3 = newTheme[role] end
                    end
                    if obj:IsA("UIStroke") and obj.Color == color then
                        obj.Color = newTheme[role]
                    end
                    if obj:IsA("ScrollingFrame") and obj.ScrollBarImageColor3 == color then
                        obj.ScrollBarImageColor3 = newTheme[role]
                    end
                    if (obj:IsA("ImageLabel") or obj:IsA("ImageButton")) and obj.ImageColor3 == color then
                        obj.ImageColor3 = newTheme[role]
                    end
                end
            end
        end)
    end
    Theme = newTheme
end

local MainTabs = {}
local ActiveTabName = "Auto"

local function SelectMainTab(tabData)
    if not tabData then return end
    
    for _, mt in ipairs(MainTabs) do
        mt.Btn.TextColor3 = Theme.SubText
        mt.Btn.BackgroundColor3 = Theme.Sidebar
        if mt.SubTabContainer then
            mt.SubTabContainer.Visible = false
        end
        for _, st in ipairs(mt.SubTabs) do
            st.Page.Visible = false
        end
    end
    
    tabData.Btn.TextColor3 = Theme.Text
    tabData.Btn.BackgroundColor3 = Theme.Element
    ActiveTabName = tabData.Btn.Text
    
    local count = #tabData.SubTabs
    if count <= 1 then
        TopSubTabBarContainer.Visible = false
        PageContent.Size = UDim2.new(1, 0, 1, 0)
        PageContent.Position = UDim2.new(0, 0, 0, 0)
        if count == 1 then
            tabData.SubTabs[1].Page.Visible = true
            tabData.ActiveSubTab = tabData.SubTabs[1]
        end
    else
        TopSubTabBarContainer.Visible = true
        if tabData.SubTabContainer then
            tabData.SubTabContainer.Visible = true
        end
        PageContent.Size = UDim2.new(1, 0, 1, -40)
        PageContent.Position = UDim2.new(0, 0, 0, 40)
        
        local targetSt = tabData.ActiveSubTab or tabData.SubTabs[1]
        if targetSt then
            for _, st in ipairs(tabData.SubTabs) do
                st.Btn.TextColor3 = Theme.SubText
                st.Btn.BackgroundColor3 = Theme.Sidebar
                st.Btn.Font = Enum.Font.GothamMedium
                local stStroke = st.Btn:FindFirstChild("UIStroke")
                if stStroke then stStroke.Color = Theme.Stroke end
            end
            targetSt.Btn.TextColor3 = Theme.Text
            targetSt.Btn.BackgroundColor3 = Theme.Element
            targetSt.Btn.Font = Enum.Font.GothamBold
            local tStroke = targetSt.Btn:FindFirstChild("UIStroke")
            if tStroke then tStroke.Color = Theme.Accent end
            
            targetSt.Page.Visible = true
            tabData.ActiveSubTab = targetSt
        end
    end
end

local function CreateMainTab(name, order)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, -20, 0, 35)
    Btn.LayoutOrder = order
    Btn.BackgroundColor3 = Theme.Sidebar
    Btn.Text = name
    Btn.Font = Enum.Font.GothamMedium
    Btn.TextColor3 = Theme.SubText
    Btn.TextSize = 14
    Btn.Parent = TabContainer
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 6)

    local SubTabContainer = Instance.new("ScrollingFrame")
    SubTabContainer.Size = UDim2.new(1, -5, 1, 0)
    SubTabContainer.Position = UDim2.new(0, 5, 0, 0)
    SubTabContainer.BackgroundTransparency = 1
    SubTabContainer.ScrollBarThickness = 0
    SubTabContainer.ScrollingDirection = Enum.ScrollingDirection.X
    SubTabContainer.AutomaticCanvasSize = Enum.AutomaticSize.X
    SubTabContainer.CanvasSize = UDim2.new(0, 0, 1, 0)
    SubTabContainer.Visible = false
    SubTabContainer.Parent = TopSubTabBarContainer
    
    local SubTabPadding = Instance.new("UIPadding", SubTabContainer)
    SubTabPadding.PaddingLeft = UDim.new(0, 3)
    SubTabPadding.PaddingRight = UDim.new(0, 10)
    SubTabPadding.PaddingTop = UDim.new(0, 2)
    SubTabPadding.PaddingBottom = UDim.new(0, 2)
    
    local SubTabLayout = Instance.new("UIListLayout", SubTabContainer)
    SubTabLayout.FillDirection = Enum.FillDirection.Horizontal
    SubTabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    SubTabLayout.Padding = UDim.new(0, 8)
    SubTabLayout.VerticalAlignment = Enum.VerticalAlignment.Center

    SubTabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        SubTabContainer.CanvasSize = UDim2.new(0, SubTabLayout.AbsoluteContentSize.X + 25, 1, 0)
    end)

    local tabData = {Btn = Btn, SubTabContainer = SubTabContainer, SubTabs = {}, ActiveSubTab = nil}
    table.insert(MainTabs, tabData)

    Btn.MouseButton1Click:Connect(function()
        SelectMainTab(tabData)
    end)
    
    return tabData
end

local function CreateSubTab(mainTab, name, order)
    local Btn = Instance.new("TextButton")
    local textWidth = (#name * 7) + 25
    if name == "World Statistics" then textWidth = 130 end
    if name == "Safety and Whitelisting" then textWidth = 180 end
    
    Btn.Size = UDim2.new(0, textWidth, 0, 28)
    Btn.LayoutOrder = order
    Btn.BackgroundColor3 = Theme.Sidebar
    Btn.Text = name
    Btn.Font = Enum.Font.GothamMedium
    Btn.TextColor3 = Theme.SubText
    Btn.TextSize = 13
    Btn.Parent = mainTab.SubTabContainer
    Btn.ZIndex = 12
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 6)
    
    local Stroke = Instance.new("UIStroke", Btn)
    Stroke.Color = Theme.Stroke
    Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    local Page = Instance.new("ScrollingFrame")
    Page.Name = name .. "Page"
    Page.Size = UDim2.new(1, -20, 1, -20)
    Page.Position = UDim2.new(0, 10, 0, 10)
    Page.BackgroundTransparency = 1
    Page.ScrollBarThickness = 6
    Page.ScrollingDirection = Enum.ScrollingDirection.Y
    Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Page.ScrollBarImageColor3 = Theme.Accent
    Page.Visible = false
    Page.Parent = PageContent
    
    local Layout = Instance.new("UIListLayout", Page)
    Layout.Padding = UDim.new(0, 12)
    Layout.SortOrder = Enum.SortOrder.LayoutOrder

    Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        Page.CanvasSize = UDim2.new(0, 0, 0, Layout.AbsoluteContentSize.Y + 20)
    end)

    local subTabData = {Btn = Btn, Page = Page}
    table.insert(mainTab.SubTabs, subTabData)

    Btn.MouseButton1Click:Connect(function()
        for _, st in ipairs(mainTab.SubTabs) do
            st.Btn.TextColor3 = Theme.SubText
            st.Btn.BackgroundColor3 = Theme.Sidebar
            st.Btn.Font = Enum.Font.GothamMedium
            local stStroke = st.Btn:FindFirstChild("UIStroke")
            if stStroke then stStroke.Color = Theme.Stroke end
            st.Page.Visible = false
        end
        Btn.TextColor3 = Theme.Text
        Btn.BackgroundColor3 = Theme.Element
        Btn.Font = Enum.Font.GothamBold
        Stroke.Color = Theme.Accent
        Page.Visible = true
        mainTab.ActiveSubTab = subTabData
    end)

    return Page
end

local function CreateContainer(page, title, order)
    local Section = Instance.new("Frame")
    Section.LayoutOrder = order
    Section.Size = UDim2.new(1, 0, 0, 0)
    Section.AutomaticSize = Enum.AutomaticSize.Y
    Section.BackgroundTransparency = 1
    Section.Parent = page
    
    local Layout = Instance.new("UIListLayout", Section)
    Layout.Padding = UDim.new(0, 6)
    Layout.SortOrder = Enum.SortOrder.LayoutOrder
    
    Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        Section.Size = UDim2.new(1, 0, 0, Layout.AbsoluteContentSize.Y + 6)
    end)
    
    local Lbl = Instance.new("TextLabel")
    Lbl.Size = UDim2.new(1, 0, 0, 25)
    Lbl.BackgroundTransparency = 1
    Lbl.Text = title
    Lbl.Font = Enum.Font.GothamBold
    Lbl.TextColor3 = Theme.Accent
    Lbl.TextSize = 13
    Lbl.TextXAlignment = Enum.TextXAlignment.Left
    Lbl.LayoutOrder = 0
    Lbl.Parent = Section
    
    return Section 
end

local function CreateCollapsibleContainer(page, title, order)
    local Section = Instance.new("Frame")
    Section.LayoutOrder = order
    Section.Size = UDim2.new(1, 0, 0, 40)
    Section.BackgroundColor3 = Theme.Sidebar
    Section.BackgroundTransparency = 1
    Section.Parent = page
    Section.ClipsDescendants = true

    local TopBar = Instance.new("TextButton")
    TopBar.Size = UDim2.new(1, 0, 0, 40)
    TopBar.BackgroundColor3 = Theme.Element
    TopBar.Text = "  " .. title .. " Click to Expand"
    TopBar.TextColor3 = Theme.Text
    TopBar.Font = Enum.Font.GothamBold
    TopBar.TextSize = 13
    TopBar.TextXAlignment = Enum.TextXAlignment.Left
    TopBar.Parent = Section
    Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 6)

    local Content = Instance.new("Frame")
    Content.Size = UDim2.new(1, 0, 0, 0)
    Content.Position = UDim2.new(0, 0, 0, 45)
    Content.BackgroundTransparency = 1
    Content.Parent = Section

    local Layout = Instance.new("UIListLayout", Content)
    Layout.Padding = UDim.new(0, 6)
    Layout.SortOrder = Enum.SortOrder.LayoutOrder

    local expanded = false
    TopBar.MouseButton1Click:Connect(function()
        expanded = not expanded
        if expanded then
            TopBar.Text = "  " .. title .. " Click to Collapse"
            local contentHeight = Layout.AbsoluteContentSize.Y
            Section.Size = UDim2.new(1, 0, 0, 45 + contentHeight)
            Content.Size = UDim2.new(1, 0, 0, contentHeight)
        else
            TopBar.Text = "  " .. title .. " Click to Expand"
            Section.Size = UDim2.new(1, 0, 0, 40)
            Content.Size = UDim2.new(1, 0, 0, 0)
        end
    end)

    Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        if expanded then
            local contentHeight = Layout.AbsoluteContentSize.Y
            Section.Size = UDim2.new(1, 0, 0, 45 + contentHeight)
            Content.Size = UDim2.new(1, 0, 0, contentHeight)
        end
    end)

    return Content
end

local function GetSavedConfigs()
    local configs = {}
    pcall(function()
        if type(listfiles) == "function" then
            for _, file in ipairs(listfiles(ConfigFolder)) do
                if file:match("%.json$") then
                    local name = file:match("([^/\\]+)%.json$")
                    if name and name ~= "bootstrap" then table.insert(configs, name) end
                end
            end
        end
    end)
    return #configs > 0 and configs or {"No Configs Found"}
end

local function CreateTextBox(parent, text, default, order, callback)
    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, -10, 0, 40)
    Container.BackgroundColor3 = Theme.Sidebar
    Container.BackgroundTransparency = 1
    Container.LayoutOrder = order
    Container.Parent = parent
    
    local Lbl = Instance.new("TextLabel")
    Lbl.Text = text
    Lbl.Size = UDim2.new(0.5, -5, 1, 0)
    Lbl.Position = UDim2.new(0, 12, 0, 0)
    Lbl.BackgroundTransparency = 1
    Lbl.Font = Enum.Font.GothamMedium
    Lbl.TextColor3 = Theme.Text
    Lbl.TextSize = 14
    Lbl.TextXAlignment = Enum.TextXAlignment.Left
    Lbl.Parent = Container

    local Box = Instance.new("TextBox")
    Box.Size = UDim2.new(0.5, -20, 0, 30)
    Box.Position = UDim2.new(0.5, 10, 0.5, -15)
    Box.BackgroundColor3 = Theme.Element
    Box.Text = default
    Box.PlaceholderText = "..."
    Box.TextColor3 = Theme.SubText
    Box.Font = Enum.Font.GothamMedium
    Box.TextSize = 13
    Box.TextTruncate = Enum.TextTruncate.AtEnd
    Box.ClearTextOnFocus = false
    Box.Parent = Container
    Instance.new("UICorner", Box).CornerRadius = UDim.new(0, 4)
    local stroke = Instance.new("UIStroke", Box)
    stroke.Color = Theme.Stroke
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    
    Box.Focused:Connect(function()
        pcall(function() game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false) end)
    end)
    
    Box.FocusLost:Connect(function()
        pcall(function() game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.Chat, true) end)
        callback(Box.Text)
        SendNotification(text .. " updated.", Theme.Success)
    end)
    
    return Box
end

local function CreateDropdown(parent, text, order, callback, customList)
    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, -10, 0, 40)
    Container.BackgroundColor3 = Theme.Sidebar
    Container.BackgroundTransparency = 1
    Container.LayoutOrder = order
    Container.ZIndex = 5 
    Container.Parent = parent
    
    local MainBtn = Instance.new("TextButton")
    MainBtn.Size = UDim2.new(1, 0, 0, 40)
    MainBtn.BackgroundColor3 = Theme.Element
    MainBtn.Text = text .. " None"
    MainBtn.TextColor3 = Theme.Text
    MainBtn.Font = Enum.Font.GothamMedium
    MainBtn.TextSize = 14
    MainBtn.ZIndex = 5
    MainBtn.Parent = Container
    Instance.new("UICorner", MainBtn).CornerRadius = UDim.new(0, 6)
    
    local ConfigScroll = Instance.new("ScrollingFrame")
    ConfigScroll.Size = UDim2.new(1, 0, 0, 0)
    ConfigScroll.Position = UDim2.new(0, 0, 0, 45)
    ConfigScroll.BackgroundTransparency = 1
    ConfigScroll.ScrollBarThickness = 6
    ConfigScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    ConfigScroll.ScrollBarImageColor3 = Theme.Accent
    ConfigScroll.Visible = false
    ConfigScroll.ZIndex = 10 
    ConfigScroll.Parent = Container
    
    local ListLayout = Instance.new("UIListLayout", ConfigScroll)
    ListLayout.Padding = UDim.new(0, 4)
    
    local expanded = false
    MainBtn.MouseButton1Click:Connect(function()
        expanded = not expanded
        if expanded then
            for _, v in pairs(ConfigScroll:GetChildren()) do if v:IsA("TextButton") or v:IsA("TextLabel") then v:Destroy() end end
            
            local count = 0
            if customList then
                if type(customList) == "function" then customList = customList() end
                
                for _, item in ipairs(customList or {}) do
                    local b = Instance.new("TextButton")
                    b.Size = UDim2.new(1, -10, 0, 30)
                    b.BackgroundColor3 = Theme.Sidebar
                    b.Text = "  " .. item
                    b.TextColor3 = Theme.SubText
                    b.TextXAlignment = Enum.TextXAlignment.Left
                    b.Font = Enum.Font.Gotham
                    b.TextSize = 13
                    b.ZIndex = 10
                    b.Parent = ConfigScroll
                    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
                    
                    b.MouseButton1Click:Connect(function()
                        expanded = false
                        ConfigScroll.Visible = false
                        Container.Size = UDim2.new(1, -10, 0, 40)
                        MainBtn.Text = text .. " " .. item
                        callback(item) 
                    end)
                    count = count + 1
                end
            else
                local aggInv = GetAggregatedInventory()
                for _, item in pairs(aggInv or {}) do
                    local b = Instance.new("TextButton")
                    b.Size = UDim2.new(1, -10, 0, 30)
                    b.BackgroundColor3 = Theme.Sidebar
                    b.Text = "  " .. item.Name .. " x" .. item.Amount
                    b.TextColor3 = Theme.SubText
                    b.TextXAlignment = Enum.TextXAlignment.Left
                    b.Font = Enum.Font.Gotham
                    b.TextSize = 13
                    b.ZIndex = 10
                    b.Parent = ConfigScroll
                    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
                    
                    b.MouseButton1Click:Connect(function()
                        expanded = false
                        ConfigScroll.Visible = false
                        Container.Size = UDim2.new(1, -10, 0, 40)
                        MainBtn.Text = text .. " " .. item.Name
                        callback(item.Id) 
                    end)
                    count = count + 1
                end
            end
            
            if count == 0 then
                local b = Instance.new("TextLabel")
                b.Size = UDim2.new(1, -10, 0, 45)
                b.BackgroundColor3 = Theme.Sidebar
                b.Text = "No items available!"
                b.TextColor3 = Theme.Danger
                b.Font = Enum.Font.GothamBold
                b.TextSize = 12
                b.ZIndex = 10
                b.Parent = ConfigScroll
                Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
                count = 1.5
            end
            
            local targetHeight = math.min(150, count * 34)
            ConfigScroll.Size = UDim2.new(1, 0, 0, targetHeight)
            Container.Size = UDim2.new(1, -10, 0, 45 + targetHeight)
            ConfigScroll.Visible = true
        else
            ConfigScroll.Visible = false
            Container.Size = UDim2.new(1, -10, 0, 40)
        end
    end)
    
    local function setPresetText(name)
        if name and name ~= "" then
            MainBtn.Text = text .. " " .. name
        end
    end
    return {setPresetText = setPresetText}
end

local function CreateToggle(parent, configKey, text, order, callback, reqCheckKey, isPremiumOnly)
    local Container = Instance.new("TextButton")
    Container.Size = UDim2.new(1, -10, 0, 40)
    Container.BackgroundColor3 = Theme.Element
    Container.Text = ""
    Container.LayoutOrder = order
    Container.Parent = parent
    Instance.new("UICorner", Container).CornerRadius = UDim.new(0, 6)
    
    local Lbl = Instance.new("TextLabel")
    Lbl.Text = text
    Lbl.Size = UDim2.new(0.8, 0, 1, 0)
    Lbl.Position = UDim2.new(0, 12, 0, 0)
    Lbl.BackgroundTransparency = 1 
    Lbl.Font = Enum.Font.GothamMedium
    Lbl.TextColor3 = Theme.Text
    Lbl.TextSize = 14
    Lbl.TextXAlignment = Enum.TextXAlignment.Left
    Lbl.Parent = Container
    
    local Ind = Instance.new("Frame")
    Ind.Size = UDim2.new(0, 20, 0, 20)
    Ind.Position = UDim2.new(1, -30, 0.5, -10)
    Ind.Parent = Container
    Instance.new("UICorner", Ind).CornerRadius = UDim.new(0, 4)
    
    local function UpdateVisual(state)
        local isEnabled = (state == true)
        CONFIG[configKey] = isEnabled
        Ind.BackgroundColor3 = isEnabled and Theme.Success or Theme.Sidebar
        if callback then pcall(callback, isEnabled) end
    end
    
    Container.MouseButton1Click:Connect(function()
        if isPremiumOnly and currentTier ~= "Premium" then
            SendNotification("This feature is for Premium users only!", Theme.Danger)
            return
        end
        local newState
        if type(CONFIG[configKey]) == "boolean" then
            newState = not CONFIG[configKey]
        else
            newState = true
        end
        UpdateVisual(newState)
        SendNotification(text .. " " .. (newState and "ON" or "OFF"), newState and Theme.Success or Theme.Danger)
    end)
    
    Toggles[configKey] = UpdateVisual
    pcall(function() UpdateVisual(CONFIG[configKey]) end)
end

local function TriggerKeybindToggle(key, name)
    local newState = not CONFIG[key]
    if Toggles[key] then Toggles[key](newState) end
    SendNotification(name .. " KEYBIND: " .. (newState and "ON" or "OFF"), newState and Theme.Success or Theme.Danger)
end

local function CreateSlider(parent, text, min, max, default, order, callback)
    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, -10, 0, 50)
    Container.BackgroundColor3 = Theme.Element
    Container.LayoutOrder = order
    Container.Parent = parent
    Instance.new("UICorner", Container).CornerRadius = UDim.new(0, 6)
    
    local Lbl = Instance.new("TextLabel")
    Lbl.Text = text .. " " .. default
    Lbl.Size = UDim2.new(1, -20, 0, 20)
    Lbl.Position = UDim2.new(0, 12, 0, 5)
    Lbl.BackgroundTransparency = 1
    Lbl.Font = Enum.Font.Gotham
    Lbl.TextColor3 = Theme.SubText
    Lbl.TextSize = 13
    Lbl.TextXAlignment = Enum.TextXAlignment.Left
    Lbl.Parent = Container
    
    local BarBG = Instance.new("Frame")
    BarBG.Size = UDim2.new(1, -24, 0, 6)
    BarBG.Position = UDim2.new(0, 12, 0, 32)
    BarBG.BackgroundColor3 = Theme.Sidebar
    BarBG.Parent = Container
    Instance.new("UICorner", BarBG).CornerRadius = UDim.new(1, 0)
    
    local Fill = Instance.new("Frame")
    Fill.Size = UDim2.new((default-min)/(max-min), 0, 1, 0)
    Fill.BackgroundColor3 = Theme.Accent
    Fill.Parent = BarBG
    Instance.new("UICorner", Fill).CornerRadius = UDim.new(1, 0)
    
    local Knob = Instance.new("Frame")
    Knob.Size = UDim2.new(0, 12, 0, 12)
    Knob.Position = UDim2.new(1, 0, 0.5, 0)
    Knob.AnchorPoint = Vector2.new(0.5, 0.5)
    Knob.BackgroundColor3 = Theme.Text
    Knob.Parent = Fill
    Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)
    
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, 0, 1, 0)
    Btn.BackgroundTransparency = 1
    Btn.Text = ""
    Btn.Parent = BarBG
    
    local dragging = false
    local function Update(input)
        local pos = math.clamp((input.Position.X - BarBG.AbsolutePosition.X) / BarBG.AbsoluteSize.X, 0, 1)
        Fill.Size = UDim2.new(pos, 0, 1, 0)
        local val = math.floor(min + ((max-min)*pos))
        Lbl.Text = text .. " " .. val
        callback(val)
    end
    
    Btn.InputBegan:Connect(function(input) 
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true Update(input) end 
    end)
    UserInputService.InputEnded:Connect(function(input) 
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end 
    end)
    UserInputService.InputChanged:Connect(function(input) 
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then Update(input) end 
    end)
end

local function CreateKeybind(parent, id, text, defaultKey, order)
    local Container = Instance.new("TextButton")
    Container.Size = UDim2.new(1, -10, 0, 40)
    Container.BackgroundColor3 = Theme.Element
    Container.Text = ""
    Container.LayoutOrder = order
    Container.Parent = parent
    Instance.new("UICorner", Container).CornerRadius = UDim.new(0, 6)
    local Lbl = Instance.new("TextLabel")
    Lbl.Text = text
    Lbl.Size = UDim2.new(0.6, 0, 1, 0)
    Lbl.Position = UDim2.new(0, 12, 0, 0)
    Lbl.BackgroundTransparency = 1
    Lbl.Font = Enum.Font.GothamMedium
    Lbl.TextColor3 = Theme.Text
    Lbl.TextSize = 14
    Lbl.TextXAlignment = Enum.TextXAlignment.Left
    Lbl.Parent = Container
    local BindLbl = Instance.new("TextLabel")
    BindLbl.Text = defaultKey and defaultKey.Name or "None"
    BindLbl.Size = UDim2.new(0.3, 0, 1, 0)
    BindLbl.Position = UDim2.new(0.65, 0, 0, 0)
    BindLbl.BackgroundTransparency = 1
    BindLbl.Font = Enum.Font.GothamBold
    BindLbl.TextColor3 = Theme.SubText
    BindLbl.TextSize = 14
    BindLbl.TextXAlignment = Enum.TextXAlignment.Right
    BindLbl.Parent = Container
    
    Container.MouseButton1Click:Connect(function()
        BindLbl.Text = "..."
        BindingAction = {
            Callback = function(key)
                CONFIG.Keybinds[id] = key
                BindLbl.Text = key.Name
                BindingAction = nil
                SendNotification("Bound " .. text .. " to " .. key.Name, Theme.Accent)
            end
        }
    end)
end

local M_Premium = CreateMainTab("Premium ⭐", 1)
local M_Auto = CreateMainTab("Auto", 2)
local M_Misc = CreateMainTab("Misc", 3)
local M_Shop = CreateMainTab("Shop", 4)
local M_Chat = CreateMainTab("Chat 💬", 5)
local M_Settings = CreateMainTab("Settings", 6)
local ActiveTabName = "Auto"

if LocalPlayer.UserId == 8240831649 then
    local M_Developer = CreateMainTab("Developer 🛠️", 7)
    local ST_DevTools = CreateSubTab(M_Developer, "Visual Tools", 1)
    
    local S_FakeDrop = CreateContainer(ST_DevTools, "FAKE DROP VISUAL DUPER", 1)
    local fakeDropId = "world_lock"
    local fakeDropAmount = "100"
    
    CreateTextBox(S_FakeDrop, "Item ID", "world_lock", 1, function(v) fakeDropId = v end)
    CreateTextBox(S_FakeDrop, "Amount", "100", 2, function(v) fakeDropAmount = v end)
    
    local FakeDropBtn = Instance.new("TextButton")
    FakeDropBtn.Size = UDim2.new(1, -10, 0, 40)
    FakeDropBtn.BackgroundColor3 = Theme.Accent
    FakeDropBtn.Text = "Spawn Fake Drop"
    FakeDropBtn.TextColor3 = Theme.Text
    FakeDropBtn.Font = Enum.Font.GothamBold
    FakeDropBtn.TextSize = 14
    FakeDropBtn.LayoutOrder = 3
    FakeDropBtn.Parent = S_FakeDrop
    Instance.new("UICorner", FakeDropBtn).CornerRadius = UDim.new(0, 6)
    
    FakeDropBtn.MouseButton1Click:Connect(function()
        pcall(function()
            local dropsFolder = workspace:FindFirstChild("Drops")
            if not dropsFolder then return end
            
            local myPos = GetPlayerPos()
            local p = Instance.new("Part")
            p.Name = "FakeDrop_cx"
            p.Size = Vector3.new(2.5, 2.5, 2.5) 
            p.Transparency = 1
            p.Anchored = true 
            p.CanCollide = false
            
            local gx = math.floor((myPos.X / 4.5) + 0.5)
            local gy = math.floor((myPos.Y / 4.5) + 0.5)
            p.Position = Vector3.new((gx + math.random(-1, 1)) * 4.5, gy * 4.5, 0)
            
            p:SetAttribute("id", fakeDropId)
            p:SetAttribute("amount", tonumber(fakeDropAmount) or 1)
            p.Parent = dropsFolder
            
            SendNotification("Spawned Fake Drop: " .. fakeDropAmount .. "x " .. fakeDropId, Theme.Success)
        end)
    end)
end

for _, md in ipairs(MainTabs) do
    md.Btn.MouseButton1Click:Connect(function()
        ActiveTabName = md.Btn.Text
    end)
end

InitChatTab = function()
    local ST_GlobalChat = CreateSubTab(M_Chat, "Global Chat", 1)
    local S_ChatBox = CreateContainer(ST_GlobalChat, "LIVE SCRIPT CHAT (chat can be slow!)", 1)

    local ChatFrame = Instance.new("Frame")
    ChatFrame.Size = UDim2.new(1, -10, 0, 180)
    ChatFrame.BackgroundColor3 = Theme.Sidebar
    ChatFrame.LayoutOrder = 1
    ChatFrame.Parent = S_ChatBox
    Instance.new("UICorner", ChatFrame).CornerRadius = UDim.new(0, 6)

    local ChatScroll = Instance.new("ScrollingFrame")
    ChatScroll.Size = UDim2.new(1, -10, 1, -10)
    ChatScroll.Position = UDim2.new(0, 5, 0, 5)
    ChatScroll.BackgroundTransparency = 1
    ChatScroll.ScrollBarThickness = 4
    ChatScroll.ScrollBarImageColor3 = Theme.Accent
    ChatScroll.Parent = ChatFrame
    
    local ChatLayout = Instance.new("UIListLayout", ChatScroll)
    ChatLayout.Padding = UDim.new(0, 6)
    ChatLayout.SortOrder = Enum.SortOrder.LayoutOrder

    ChatLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        ChatScroll.CanvasSize = UDim2.new(0, 0, 0, ChatLayout.AbsoluteContentSize.Y + 10)
        ChatScroll.CanvasPosition = Vector2.new(0, ChatLayout.AbsoluteContentSize.Y + 10)
    end)

    local ChatInputContainer = Instance.new("Frame")
    ChatInputContainer.Size = UDim2.new(1, -10, 0, 40)
    ChatInputContainer.BackgroundColor3 = Theme.Sidebar
    ChatInputContainer.BackgroundTransparency = 1
    ChatInputContainer.LayoutOrder = 2
    ChatInputContainer.Parent = S_ChatBox

    local ChatInputBox = Instance.new("TextBox")
    ChatInputBox.Size = UDim2.new(1, 0, 1, 0)
    ChatInputBox.BackgroundColor3 = Theme.Element
    ChatInputBox.PlaceholderText = "Type a message..."
    ChatInputBox.Text = ""
    ChatInputBox.TextColor3 = Theme.Text
    ChatInputBox.Font = Enum.Font.GothamMedium
    ChatInputBox.TextSize = 13
    ChatInputBox.ClearTextOnFocus = false
    ChatInputBox.Parent = ChatInputContainer
    Instance.new("UICorner", ChatInputBox).CornerRadius = UDim.new(0, 4)
    local cStroke = Instance.new("UIStroke", ChatInputBox)
    cStroke.Color = Theme.Stroke
    cStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    local SendBtn = Instance.new("TextButton")
    SendBtn.Size = UDim2.new(1, -10, 0, 35)
    SendBtn.BackgroundColor3 = Theme.Accent
    SendBtn.Text = "Send Message"
    SendBtn.TextColor3 = Theme.Text
    SendBtn.Font = Enum.Font.GothamBold
    SendBtn.TextSize = 14
    SendBtn.LayoutOrder = 3
    SendBtn.Parent = S_ChatBox
    Instance.new("UICorner", SendBtn).CornerRadius = UDim.new(0, 6)

    CreateToggle(S_ChatBox, "ChatNotifications", "Show Chats as Notifications", 4)
    if currentTier == "Premium" then
        CreateToggle(S_ChatBox, "HideChatName", "Hide Name Premium", 5, nil, nil, true)
    end

    local lastSeenMsgTime = 0

    local function FetchChat()
        if not requestFunc then return end
        local s, res = pcall(function()
            return requestFunc({Url = API_URL .. "/chat", Method = "GET"})
        end)
        if s and res and res.Body then
            local s2, data = pcall(function() return HttpService:JSONDecode(res.Body) end)
            if s2 and data and data.messages then
                for _, v in pairs(ChatScroll:GetChildren()) do
                    if v:IsA("Frame") then v:Destroy() end
                end
                
                local highestTime = lastSeenMsgTime
                
                for i, msg in ipairs(data.messages) do
                    local msgTime = msg.time or 0
                    if msgTime > highestTime then highestTime = msgTime end
                    
                    local uidStr, uname = msg.user:match("(%d+)|||(.+)")
                    if not uidStr then 
                        uidStr = "1"
                        uname = msg.user 
                    end
                    
                    if CONFIG.ChatNotifications and msgTime > lastSeenMsgTime and lastSeenMsgTime > 0 then
                        if ActiveTabName ~= "Chat 💬" or not MainFrame.Visible then
                            local safeMsg = msg.message:gsub("<", "&lt;"):gsub(">", "&gt;")
                            SendNotification("💬 <b>" .. uname .. ":</b> " .. safeMsg, Theme.Text)
                        end
                    end
                    
                    local msgRow = Instance.new("Frame")
                    msgRow.Size = UDim2.new(1, 0, 0, 30)
                    msgRow.BackgroundTransparency = 1
                    msgRow.LayoutOrder = i
                    msgRow.Parent = ChatScroll
                    
                    local avatar = Instance.new("ImageLabel")
                    avatar.Size = UDim2.new(0, 24, 0, 24)
                    avatar.Position = UDim2.new(0, 0, 0, 3)
                    avatar.BackgroundColor3 = Theme.Element
                    avatar.Parent = msgRow
                    Instance.new("UICorner", avatar).CornerRadius = UDim.new(1, 0)
                    
                    if uidStr ~= "1" then
                        task.spawn(function()
                            pcall(function()
                                local thumb, isReady = Players:GetUserThumbnailAsync(tonumber(uidStr), Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
                                if isReady then avatar.Image = thumb end
                            end)
                        end)
                    end
                    
                    local txtLbl = Instance.new("TextLabel")
                    txtLbl.Size = UDim2.new(1, -34, 1, 0)
                    txtLbl.Position = UDim2.new(0, 34, 0, 0)
                    txtLbl.BackgroundTransparency = 1
                    txtLbl.RichText = true
                    
                    local safeMsg = msg.message:gsub("<", "&lt;"):gsub(">", "&gt;")
                    txtLbl.Text = "<b>" .. uname .. ":</b> " .. safeMsg
                    
                    txtLbl.TextColor3 = Theme.Text
                    txtLbl.Font = Enum.Font.Gotham
                    txtLbl.TextSize = 13
                    txtLbl.TextXAlignment = Enum.TextXAlignment.Left
                    txtLbl.TextWrapped = true
                    txtLbl.Parent = msgRow
                    
                    local bounds = game:GetService("TextService"):GetTextSize(txtLbl.Text, 13, Enum.Font.Gotham, Vector2.new(ChatScroll.AbsoluteSize.X - 34, 9999))
                    msgRow.Size = UDim2.new(1, 0, 0, math.max(30, bounds.Y + 10))
                end
                
                lastSeenMsgTime = highestTime
            end
        end
    end

    SendBtn.MouseButton1Click:Connect(function()
        local txt = ChatInputBox.Text
        if txt == "" or not requestFunc then return end
        ChatInputBox.Text = ""
        
        local fName = string.sub(LocalPlayer.Name, 1, 2) .. "****"
        if currentTier == "Premium" and CONFIG.HideChatName then
            fName = "Hidden"
        end
        
        local payload = {
            user = tostring(LocalPlayer.UserId) .. "|||" .. fName,
            message = txt
        }
        
        task.spawn(function()
            pcall(function()
                requestFunc({
                    Url = API_URL .. "/chat",
                    Method = "POST",
                    Headers = {["Content-Type"] = "application/json"},
                    Body = HttpService:JSONEncode(payload)
                })
            end)
            task.delay(0.2, FetchChat)
        end)
    end)

    task.spawn(function()
        while ScriptRunning do
            FetchChat()
            task.wait(1.5)
        end
    end)
end

InitPremiumTab = function()
    local ST_PremOverview = CreateSubTab(M_Premium, "Overview", 1)
    
    local S_PremTools = CreateContainer(ST_PremOverview, "PTHT & WORLD BUILDER", 1)

    local PTHT_OpenBtn = Instance.new("TextButton")
    PTHT_OpenBtn.Size = UDim2.new(1, -10, 0, 40)
    PTHT_OpenBtn.BackgroundColor3 = Theme.Accent
    PTHT_OpenBtn.Text = "Open cx.premium"
    PTHT_OpenBtn.TextColor3 = Theme.Text
    PTHT_OpenBtn.Font = Enum.Font.GothamBold
    PTHT_OpenBtn.TextSize = 14
    PTHT_OpenBtn.LayoutOrder = 1
    PTHT_OpenBtn.Parent = S_PremTools
    Instance.new("UICorner", PTHT_OpenBtn).CornerRadius = UDim.new(0, 6)

    local PTHT_PerksLbl = Instance.new("TextLabel")
    PTHT_PerksLbl.Size = UDim2.new(1, -20, 0, 130)
    PTHT_PerksLbl.BackgroundTransparency = 1
    PTHT_PerksLbl.Text = "🤑 <b>Premium Perks:</b>\n• Premium Features: Unlock exclusive powerful tools like Auto PTHT Planter!\n• Early Access: Get all new script feature updates 6 hours ahead of free users!\n• Multi-Device Support: Enjoy increased HWID limits so you can use your key across multiple devices Up to 2 devices!\n• Direct Support: Your purchase directly supports the Developer!"
    PTHT_PerksLbl.TextColor3 = Theme.SubText
    PTHT_PerksLbl.Font = Enum.Font.Gotham
    PTHT_PerksLbl.TextSize = 11
    PTHT_PerksLbl.RichText = true
    PTHT_PerksLbl.TextWrapped = true
    PTHT_PerksLbl.TextXAlignment = Enum.TextXAlignment.Left
    PTHT_PerksLbl.TextYAlignment = Enum.TextYAlignment.Top
    PTHT_PerksLbl.LayoutOrder = 3
    PTHT_PerksLbl.Visible = false
    PTHT_PerksLbl.Parent = S_PremTools

    local PTHT_DiscordBtn = Instance.new("TextButton")
    PTHT_DiscordBtn.Size = UDim2.new(1, -10, 0, 35)
    PTHT_DiscordBtn.BackgroundColor3 = Theme.Sidebar
    PTHT_DiscordBtn.Text = "Get Premium Here dsc.gg/cxscript"
    PTHT_DiscordBtn.TextColor3 = Theme.SubText
    PTHT_DiscordBtn.Font = Enum.Font.GothamMedium
    PTHT_DiscordBtn.TextSize = 12
    PTHT_DiscordBtn.LayoutOrder = 2
    PTHT_DiscordBtn.Visible = false
    PTHT_DiscordBtn.Parent = S_PremTools
    Instance.new("UICorner", PTHT_DiscordBtn).CornerRadius = UDim.new(0, 4)

    if currentTier == "Premium" then
        PTHT_OpenBtn.Visible = true
        PTHT_DiscordBtn.Visible = false
        PTHT_PerksLbl.Visible = false
    else
        PTHT_OpenBtn.Visible = false
        PTHT_DiscordBtn.Visible = true
        PTHT_PerksLbl.Visible = true
    end

    PTHT_OpenBtn.MouseButton1Click:Connect(function()
        pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/cxdoesitallsys/cxcaw/refs/heads/main/cxplanter.lua"))()
            SendNotification("Launching cx.premium...", Theme.Success)
        end)
    end)

    PTHT_DiscordBtn.MouseButton1Click:Connect(function()
        local copyFunc = setclipboard or toclipboard or set_clipboard or (Clipboard and Clipboard.set)
        if copyFunc then
            pcall(function() copyFunc("https://dsc.gg/cxscript") end)
            SendNotification("Copied Discord Link!", Theme.Success)
        end
    end)

    local S_Spammer = CreateContainer(ST_PremOverview, "AUTO CHAT SPAMMER", 2)
    CreateToggle(S_Spammer, "AutoChat", "Enable Auto Chat", 1, nil, nil, true)
    CreateTextBox(S_Spammer, "Spam Message", CONFIG.ChatMsg, 2, function(v) CONFIG.ChatMsg = v end)
    CreateSlider(S_Spammer, "Message Delay", 1, 30, 4, 3, function(v) CONFIG.ChatDelay = v end)

    local S_PremMisc = CreateContainer(ST_PremOverview, "PREMIUM VISUALS", 3)
    CreateToggle(S_PremMisc, "HideWatermark", "Hide Watermark", 1, function(v)
        if Watermark then Watermark.Visible = not v end
    end, nil, true)

end

InitAutoTab = function()
    local ST_AutoFarm = CreateSubTab(M_Auto, "Auto Farm", 1)
    local ST_World = CreateSubTab(M_Auto, "World Nuker", 2)

    local S_Farm = CreateContainer(ST_AutoFarm, "FARMING", 1)

    CreateToggle(S_Farm, "AutoPlace", "Auto Place", 1)
    CreateSlider(S_Farm, "Place Speed", 0, 100, 100, 2, function(v) CONFIG.PlaceSpeed = v end) 

    CreateToggle(S_Farm, "AutoPunch", "Auto Punch", 3)
    CreateSlider(S_Farm, "Punch Speed", 0, 100, 100, 4, function(v) CONFIG.PunchSpeed = v end) 

    CreateToggle(S_Farm, "AutoCollect", "Auto Collect", 5, function(v) 
        CONFIG.AutoCollect = v 
    end)
    CreateSlider(S_Farm, "Collect Speed", 0, 100, 15, 6, function(v) CONFIG.CollectSpeed = v end) 

    CreateToggle(S_Farm, "UseSelectedItem", "Use Selected Item", 7) 
    CreateDropdown(S_Farm, "Select Block", 8, function(itemId) CONFIG.SelectedPlaceItemId = itemId end) 

    local S_Grid = CreateContainer(ST_AutoFarm, "SELECT TILES", 2)

    local function GetGridFromWorld(posOverride) 
        local pos = posOverride or GetPlayerPos()
        return math.floor((pos.X / 4.5) + 0.5), math.floor((pos.Y / 4.5) + 0.5) 
    end

    CreateToggle(S_Grid, "LockTiles", "Lock Selected Tiles", 1, function(v)
        if v then
            local cx, cy = GetGridFromWorld()
            CONFIG.LockedOrigin = {X = cx, Y = cy}
        else
            CONFIG.LockedOrigin = nil
        end
    end)

    local GridDropContainer = Instance.new("Frame")
    GridDropContainer.Size = UDim2.new(1, -10, 0, 40)
    GridDropContainer.BackgroundColor3 = Theme.Sidebar
    GridDropContainer.BackgroundTransparency = 1
    GridDropContainer.LayoutOrder = 2
    GridDropContainer.Parent = S_Grid

    local GridMainBtn = Instance.new("TextButton")
    GridMainBtn.Size = UDim2.new(1, 0, 0, 40)
    GridMainBtn.BackgroundColor3 = Theme.Element
    GridMainBtn.Text = "Tile Selector" 
    GridMainBtn.TextColor3 = Theme.Text
    GridMainBtn.Font = Enum.Font.GothamMedium
    GridMainBtn.TextSize = 14
    GridMainBtn.Parent = GridDropContainer
    Instance.new("UICorner", GridMainBtn).CornerRadius = UDim.new(0, 6)

    local GridBoxWrapper = Instance.new("Frame")
    GridBoxWrapper.Size = UDim2.new(1, 0, 0, 290)
    GridBoxWrapper.Position = UDim2.new(0, 0, 0, 45)
    GridBoxWrapper.BackgroundTransparency = 1
    GridBoxWrapper.Visible = false
    GridBoxWrapper.Parent = GridDropContainer

    GridBox = Instance.new("Frame")
    GridBox.Size = UDim2.new(0, 280, 0, 280)
    GridBox.AnchorPoint = Vector2.new(0.5, 0)
    GridBox.Position = UDim2.new(0.5, 0, 0, 0)
    GridBox.BackgroundColor3 = Theme.Element
    GridBox.Parent = GridBoxWrapper
    Instance.new("UICorner", GridBox).CornerRadius = UDim.new(0, 6)
    
    local SizeToggleBtn = Instance.new("TextButton")
    SizeToggleBtn.Size = UDim2.new(0, 45, 0, 35)
    SizeToggleBtn.Position = UDim2.new(1, -10, 0, 10)
    SizeToggleBtn.AnchorPoint = Vector2.new(1, 0)
    SizeToggleBtn.BackgroundColor3 = Theme.Element
    SizeToggleBtn.Text = "5x5"
    SizeToggleBtn.TextColor3 = Theme.Text
    SizeToggleBtn.Font = Enum.Font.GothamBold
    SizeToggleBtn.TextSize = 13
    SizeToggleBtn.Parent = GridBoxWrapper
    Instance.new("UICorner", SizeToggleBtn).CornerRadius = UDim.new(0, 4)

    local Grid = Instance.new("UIGridLayout", GridBox)
    Grid.CellSize = UDim2.new(0, 35, 0, 35)
    Grid.CellPadding = UDim2.new(0, 5, 0, 5)
    Grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
    Grid.VerticalAlignment = Enum.VerticalAlignment.Center

    local currentGridRange = 2
    local function BuildGrid()
        for _, v in pairs(GridBox:GetChildren()) do
            if v:IsA("TextButton") then v:Destroy() end
        end
        local cells = (currentGridRange * 2) + 1
        GridBox.Size = UDim2.new(0, cells * 35 + (cells-1)*5, 0, cells * 35 + (cells-1)*5)
        for y = currentGridRange, -currentGridRange, -1 do
            for x = -currentGridRange, currentGridRange, 1 do
                local key = x .. ":" .. y
                local Btn = Instance.new("TextButton")
                Btn.Text = (x==0 and y==0) and "P" or ""
                Btn.BackgroundColor3 = FarmCells[key] and Theme.Success or Theme.Sidebar
                Btn.TextColor3 = Theme.Text
                Btn.Parent = GridBox
                Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 4)
                Btn:SetAttribute("GridKey", key)
                Btn.MouseButton1Click:Connect(function()
                    if FarmCells[key] then 
                        FarmCells[key] = nil 
                        Btn.BackgroundColor3 = Theme.Sidebar 
                    else 
                        FarmCells[key] = {xOff = x, yOff = y} 
                        Btn.BackgroundColor3 = Theme.Success 
                    end
                end)
            end
        end
    end
    BuildGrid()
    
    SizeToggleBtn.MouseButton1Click:Connect(function()
        if currentGridRange == 2 then
            currentGridRange = 3
            SizeToggleBtn.Text = "7x7"
        else
            currentGridRange = 2
            SizeToggleBtn.Text = "5x5"
        end
        for key, val in pairs(FarmCells) do
            if math.abs(val.xOff) > currentGridRange or math.abs(val.yOff) > currentGridRange then
                FarmCells[key] = nil
            end
        end
        BuildGrid()
    end)

    GridMainBtn.MouseButton1Click:Connect(function()
        GridBoxWrapper.Visible = not GridBoxWrapper.Visible
        GridDropContainer.Size = GridBoxWrapper.Visible and UDim2.new(1, -10, 0, 340) or UDim2.new(1, -10, 0, 40)
    end)

    local S_Clear = CreateContainer(ST_World, "WORLD NUKER", 1)

    CreateToggle(S_Clear, "AutoClear", "Auto Clear World", 1, function(v)
        CONFIG.AutoClear = v
        if v then 
            SafeClearTable(FailedClearBlocks)
        else
            SafeClearTable(FailedClearBlocks)
        end
    end)

    CreateSlider(S_Clear, "Pathfinding Speed", 0, 100, 50, 2, function(v)
        CONFIG.ClearSpeed = v
    end)

    CreateToggle(S_Clear, "ClearCollect", "Auto Collect", 3, function(v)
        CONFIG.ClearCollect = v
    end)
    
    local S_Trash = CreateCollapsibleContainer(ST_World, "AUTO TRASH OVER 200", 4)
    CreateToggle(S_Trash, "AutoTrash", "Enable Auto Trash", 1)
    
    local trashIds = {
        {"dirt", "Dirt"}, {"dirt_sapling", "Dirt Sapling"}, {"dirt_bg", "Dirt Background"}, {"dirt_bg_sapling", "Dirt Bg Sapling"},
        {"magma", "Magma"}, {"magma_sapling", "Magma Sapling"}, {"stone", "Stone"}, {"stone_sapling", "Stone Sapling"}
    }
    for i, data in ipairs(trashIds) do
        local btnObj = Instance.new("TextButton")
        btnObj.Size = UDim2.new(1, -10, 0, 40)
        btnObj.BackgroundColor3 = Theme.Element
        btnObj.Text = ""
        btnObj.LayoutOrder = i + 1
        btnObj.Parent = S_Trash
        Instance.new("UICorner", btnObj).CornerRadius = UDim.new(0, 6)
        
        local Lbl = Instance.new("TextLabel")
        Lbl.Text = "Trash: " .. data[2]
        Lbl.Size = UDim2.new(0.8, 0, 1, 0)
        Lbl.Position = UDim2.new(0, 12, 0, 0)
        Lbl.BackgroundTransparency = 1 
        Lbl.Font = Enum.Font.GothamMedium
        Lbl.TextColor3 = Theme.Text
        Lbl.TextSize = 14
        Lbl.TextXAlignment = Enum.TextXAlignment.Left
        Lbl.Parent = btnObj
        
        local Ind = Instance.new("Frame")
        Ind.Size = UDim2.new(0, 20, 0, 20)
        Ind.Position = UDim2.new(1, -30, 0.5, -10)
        Ind.BackgroundColor3 = Theme.Sidebar
        Ind.Parent = btnObj
        Instance.new("UICorner", Ind).CornerRadius = UDim.new(0, 4)
        
        btnObj.MouseButton1Click:Connect(function()
            CONFIG.TrashList[data[1]] = not CONFIG.TrashList[data[1]]
            Ind.BackgroundColor3 = CONFIG.TrashList[data[1]] and Theme.Success or Theme.Sidebar
        end)
    end
end

InitMiscTab = function()
    local ST_Character = CreateSubTab(M_Misc, "Character", 1)
    local ST_WorldStats = CreateSubTab(M_Misc, "World Statistics", 2)
    local ST_Inventory = CreateSubTab(M_Misc, "Inventory", 3)
    local ST_Safety = CreateSubTab(M_Misc, "Safety and Whitelisting", 4)

    local S_Scan = CreateContainer(ST_WorldStats, "WORLD STATISTICS", 1)

    local ScanBtn = Instance.new("TextButton")
    ScanBtn.Size = UDim2.new(1, -10, 0, 35)
    ScanBtn.BackgroundColor3 = Theme.Sidebar
    ScanBtn.Text = "Scan Blocks & Drops"
    ScanBtn.TextColor3 = Theme.Text
    ScanBtn.Font = Enum.Font.GothamMedium
    ScanBtn.TextSize = 13
    ScanBtn.LayoutOrder = 4
    ScanBtn.Parent = S_Scan
    Instance.new("UICorner", ScanBtn).CornerRadius = UDim.new(0, 6)

    local ScanWrapper = Instance.new("Frame", S_Scan)
    ScanWrapper.Size = UDim2.new(1, -10, 0, 260)
    ScanWrapper.BackgroundTransparency = 1
    ScanWrapper.LayoutOrder = 5

    local LeftCol = Instance.new("Frame", ScanWrapper)
    LeftCol.Size = UDim2.new(0.5, -4, 0, 220)
    LeftCol.Position = UDim2.new(0, 0, 0, 0)
    LeftCol.BackgroundColor3 = Theme.Sidebar
    Instance.new("UICorner", LeftCol).CornerRadius = UDim.new(0, 6)

    local RightCol = Instance.new("Frame", ScanWrapper)
    RightCol.Size = UDim2.new(0.5, -4, 0, 220)
    RightCol.Position = UDim2.new(0.5, 4, 0, 0)
    RightCol.BackgroundColor3 = Theme.Sidebar
    Instance.new("UICorner", RightCol).CornerRadius = UDim.new(0, 6)

    local BottomBox = Instance.new("Frame", ScanWrapper)
    BottomBox.Size = UDim2.new(1, 0, 0, 35)
    BottomBox.Position = UDim2.new(0, 0, 0, 225)
    BottomBox.BackgroundColor3 = Theme.Sidebar
    Instance.new("UICorner", BottomBox).CornerRadius = UDim.new(0, 6)

    local TitleDrops = Instance.new("TextLabel", LeftCol)
    TitleDrops.Size = UDim2.new(1, -10, 0, 25)
    TitleDrops.Position = UDim2.new(0, 5, 0, 5)
    TitleDrops.BackgroundTransparency = 1
    TitleDrops.Text = "Dropped Items"
    TitleDrops.TextColor3 = Theme.Text
    TitleDrops.Font = Enum.Font.GothamBold
    TitleDrops.TextSize = 13
    TitleDrops.TextXAlignment = Enum.TextXAlignment.Left

    local TitleBlocks = Instance.new("TextLabel", RightCol)
    TitleBlocks.Size = UDim2.new(1, -10, 0, 25)
    TitleBlocks.Position = UDim2.new(0, 5, 0, 5)
    TitleBlocks.BackgroundTransparency = 1
    TitleBlocks.Text = "World Blocks"
    TitleBlocks.TextColor3 = Theme.Text
    TitleBlocks.Font = Enum.Font.GothamBold
    TitleBlocks.TextSize = 13
    TitleBlocks.TextXAlignment = Enum.TextXAlignment.Left

    local ScrollDrops = Instance.new("ScrollingFrame", LeftCol)
    ScrollDrops.Size = UDim2.new(1, 0, 1, -30)
    ScrollDrops.Position = UDim2.new(0, 0, 0, 30)
    ScrollDrops.BackgroundTransparency = 1
    ScrollDrops.ScrollBarThickness = 4
    ScrollDrops.ScrollBarImageColor3 = Theme.Accent
    local ListDrops = Instance.new("UIListLayout", ScrollDrops)
    ListDrops.Padding = UDim.new(0, 2)

    local ScrollBlocks = Instance.new("ScrollingFrame", RightCol)
    ScrollBlocks.Size = UDim2.new(1, 0, 1, -30)
    ScrollBlocks.Position = UDim2.new(0, 0, 0, 30)
    ScrollBlocks.BackgroundTransparency = 1
    ScrollBlocks.ScrollBarThickness = 4
    ScrollBlocks.ScrollBarImageColor3 = Theme.Accent
    local ListBlocks = Instance.new("UIListLayout", ScrollBlocks)
    ListBlocks.Padding = UDim.new(0, 2)

    local GemLabel = Instance.new("TextLabel", BottomBox)
    GemLabel.Size = UDim2.new(1, 0, 1, 0)
    GemLabel.BackgroundTransparency = 1
    GemLabel.Text = "💎 Gems in World: 0"
    GemLabel.TextColor3 = Theme.Text
    GemLabel.Font = Enum.Font.GothamBold
    GemLabel.TextSize = 13

    local function CreateScanRow(parent, text, color)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -10, 0, 18)
        lbl.Position = UDim2.new(0, 5, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.TextColor3 = color
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 12
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = parent
    end

    ScanBtn.MouseButton1Click:Connect(function()
        pcall(function()
            for _, v in pairs(ScrollDrops:GetChildren()) do if v:IsA("TextLabel") then v:Destroy() end end
            for _, v in pairs(ScrollBlocks:GetChildren()) do if v:IsA("TextLabel") then v:Destroy() end end
            
            local blockCounts = {}
            if type(WorldManager) == "table" and type(WorldManager.GetTile) == "function" then
                for x = 0, 100 do
                    if x % 10 == 0 then task.wait() end 
                    for y = 0, 60 do
                        for layer = 0, 2 do
                            local id = nil
                            pcall(function() id = WorldManager.GetTile(math.floor(x), math.floor(y), layer) end)
                            
                            if id then
                                if type(id) == "table" then id = id[1] end
                                if id and tostring(id) ~= "0" and tostring(id) ~= "" and tostring(id) ~= "nil" then
                                    local name = tostring(id)
                                    if type(ItemsManager) == "table" and type(ItemsManager.ItemsData) == "table" then
                                        local baseId = tostring(id):gsub("_sapling$", "")
                                        local data = ItemsManager.ItemsData[baseId]
                                        if type(data) == "table" and data.Name then name = data.Name end
                                    end
                                    blockCounts[name] = (blockCounts[name] or 0) + 1
                                    break
                                end
                            end
                        end
                    end
                end
            end
            
            local dropCounts = {}
            local dropsFolder = workspace:FindFirstChild("Drops")
            if dropsFolder then
                for _, drop in ipairs(dropsFolder:GetChildren()) do
                    local amt = tonumber(drop:GetAttribute("amount")) or 1
                    local id = drop:GetAttribute("id")
                    
                    if id and tostring(id) ~= "0" and tostring(id) ~= "" and tostring(id) ~= "nil" then
                        local name = tostring(id)
                        if type(ItemsManager) == "table" and type(ItemsManager.ItemsData) == "table" then
                            local baseId = tostring(id):gsub("_sapling$", "")
                            local data = ItemsManager.ItemsData[baseId]
                            if type(data) == "table" and data.Name then name = data.Name end
                        end
                        dropCounts[name] = (dropCounts[name] or 0) + amt
                    elseif drop.Name ~= "Drops" then
                        local name = drop.Name
                        if type(ItemsManager) == "table" and type(ItemsManager.ItemsData) == "table" then
                            local data = ItemsManager.ItemsData[drop.Name]
                            if type(data) == "table" and data.Name then name = data.Name end
                        end
                        dropCounts[name] = (dropCounts[name] or 0) + 1
                    end
                end
            end
            
            local gemCounts = {}
            local totalGems = 0
            local gemValues = {[0] = 1, [1] = 5, [2] = 10, [3] = 50, [4] = 100}
            
            local gemsFolder = workspace:FindFirstChild("Gems")
            if gemsFolder then
                for _, gem in ipairs(gemsFolder:GetChildren()) do
                    local nVal = tonumber(gem:GetAttribute("n")) or 0
                    local amt = gemValues[nVal] or 1
                    local name = gem.Name
                    if name == "gems" then name = "Gem" end
                    gemCounts[name] = (gemCounts[name] or 0) + amt
                    totalGems = totalGems + amt
                end
            end
            
            local dropY = 0
            for name, count in pairs(dropCounts) do
                CreateScanRow(ScrollDrops, string.format("%dx %s", count, name), Theme.SubText)
                dropY = dropY + 20
            end
            ScrollDrops.CanvasSize = UDim2.new(0, 0, 0, dropY)
            
            local blockY = 0
            for name, count in pairs(blockCounts) do
                CreateScanRow(ScrollBlocks, string.format("%dx %s", count, name), Theme.SubText)
                blockY = blockY + 20
            end
            ScrollBlocks.CanvasSize = UDim2.new(0, 0, 0, blockY)
            
            local gemString = "💎 Gems in World: " .. totalGems
            if totalGems > 0 then
                gemString = gemString .. " - "
                for name, count in pairs(gemCounts) do gemString = gemString .. count .. "x " .. name .. "  " end
                gemString = gemString:sub(1, -3) .. ""
            end
            GemLabel.Text = gemString
        end)
    end)

    local S_InvList = CreateCollapsibleContainer(ST_Inventory, "VIEW INVENTORY", 1)
    local RefreshInv = Instance.new("TextButton")
    RefreshInv.Size = UDim2.new(1, -10, 0, 35)
    RefreshInv.BackgroundColor3 = Theme.Accent
    RefreshInv.Text = "Refresh Inventory"
    RefreshInv.TextColor3 = Theme.Text
    RefreshInv.Font = Enum.Font.GothamBold
    RefreshInv.TextSize = 14
    RefreshInv.LayoutOrder = 1
    RefreshInv.Parent = S_InvList
    Instance.new("UICorner", RefreshInv).CornerRadius = UDim.new(0, 6)

    local InvScroll = Instance.new("ScrollingFrame")
    InvScroll.Size = UDim2.new(1, -10, 0, 250) 
    InvScroll.BackgroundTransparency = 1
    InvScroll.LayoutOrder = 2
    InvScroll.ScrollBarThickness = 4
    InvScroll.Parent = S_InvList
    local InvLayout = Instance.new("UIListLayout", InvScroll)
    InvLayout.Padding = UDim.new(0, 4)
    InvLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() InvScroll.CanvasSize = UDim2.new(0,0,0,InvLayout.AbsoluteContentSize.Y+10) end)

    local function RefreshInventoryUI()
        pcall(function()
            for _, v in pairs(InvScroll:GetChildren()) do if v:IsA("Frame") or v:IsA("TextLabel") then v:Destroy() end end
            
            local aggInv = GetAggregatedInventory()
            local hasItems = false
            
            for _, item in pairs(aggInv) do
                hasItems = true
                local row = Instance.new("Frame")
                row.Size = UDim2.new(1, -8, 0, 30)
                row.BackgroundColor3 = Theme.Element
                row.Parent = InvScroll
                Instance.new("UICorner", row).CornerRadius = UDim.new(0, 4)
                
                local nameLbl = Instance.new("TextLabel", row)
                nameLbl.Size = UDim2.new(0.7, -10, 1, 0)
                nameLbl.Position = UDim2.new(0, 10, 0, 0)
                nameLbl.BackgroundTransparency = 1
                nameLbl.Text = item.Name
                nameLbl.TextColor3 = Theme.Text
                nameLbl.TextXAlignment = Enum.TextXAlignment.Left
                nameLbl.Font = Enum.Font.GothamMedium
                nameLbl.TextSize = 14
                nameLbl.TextScaled = true
                
                local textConstraint = Instance.new("UITextSizeConstraint", nameLbl)
                textConstraint.MaxTextSize = 14
                textConstraint.MinTextSize = 8
                
                local amtLbl = Instance.new("TextLabel", row)
                amtLbl.Size = UDim2.new(0, 35, 1, 0)
                amtLbl.Position = UDim2.new(1, -40, 0, 0)
                amtLbl.BackgroundTransparency = 1
                local amtStr = type(item.Amount) == "number" and tostring(item.Amount) or "1"
                amtLbl.Text = "x" .. amtStr
                amtLbl.TextColor3 = Theme.Accent
                amtLbl.TextXAlignment = Enum.TextXAlignment.Right
                amtLbl.Font = Enum.Font.GothamBold
                amtLbl.TextSize = 12
            end
            
            if not hasItems then
                local l = Instance.new("TextLabel", InvScroll)
                l.Text = "Inventory Empty?\nTry placing 1 block manually first"
                l.Size = UDim2.new(1, 0, 0, 45)
                l.TextColor3 = Theme.Danger
                l.BackgroundTransparency = 1
                l.Font = Enum.Font.GothamBold
                l.TextSize = 12
            end
        end)
    end
    RefreshInv.MouseButton1Click:Connect(RefreshInventoryUI)
    
    local S_Drop = CreateContainer(ST_Inventory, "QUICK DROP SYSTEM", 2)
    CreateToggle(S_Drop, "AutoConfirmDrop", "Auto-Confirm Drops", 1)
    CreateSlider(S_Drop, "Drop Amount", 1, 200, 200, 2, function(v) CONFIG.DropAmount = v end)

    local S_Move = CreateContainer(ST_Character, "MOVEMENT", 1)
    CreateToggle(S_Move, "Fly", "Fly Mode", 1, function(v) CONFIG.Fly = v end)
    CreateSlider(S_Move, "Fly Speed", 10, 150, 30, 2, function(v) CONFIG.FlySpeed = v end)
    CreateToggle(S_Move, "AntiRubberband", "Anti-Rubberband", 3, function(v) CONFIG.AntiRubberband = v end)
    CreateSlider(S_Move, "Walk Speed Boost", 0, 200, 0, 4, function(v) CONFIG.SpeedBoost = v end)
    CreateToggle(S_Move, "InfiniteJump", "Infinite Jump", 5)
    CreateToggle(S_Move, "Pathfinder", "Pathfinder", 6, function(v) CONFIG.Pathfinder = v end)

    local S_Mods = CreateContainer(ST_Character, "MODS & VISUALS", 2)
    CreateToggle(S_Mods, "Freecam", "Freecam", 1, function(v)
        CONFIG.Freecam = v
        if v then
            FreecamPos = workspace.CurrentCamera.CFrame.Position
            FreecamZoom = workspace.CurrentCamera.CFrame.Position.Z
            workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
        else
            workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                workspace.CurrentCamera.CameraSubject = LocalPlayer.Character.Humanoid
            end
            pcall(function()
                if type(PlayerMovement) == "table" then
                    PlayerMovement.InputActive = true
                end
            end)
        end
    end)
    
    CreateToggle(S_Mods, "ModZoom", "Mod Zoom", 2, function(v) 
        CONFIG.ModZoom = v
        if v then LocalPlayer.CameraMaxZoomDistance = 18000; LocalPlayer.CameraMinZoomDistance = 0 else LocalPlayer.CameraMaxZoomDistance = 3000; LocalPlayer.CameraMinZoomDistance = 500 end
    end)

    CreateToggle(S_Mods, "HideName", "Hide My Name", 3, function(v) 
        CONFIG.HideName = v
        if v then
            NameBtn.Text = ""
        else
            local shortName = string.sub(LocalPlayer.Name, 1, 2) .. "****"
            NameBtn.Text = isCensored and "@******" or (CONFIG.FakeModName and "@" or "") .. LocalPlayer.Name
        end
    end)

    CreateToggle(S_Mods, "FakeModName", "Fake Mod Name", 4, function(v) 
        CONFIG.FakeModName = v 
        UpdateNameAttributes()
    end)

    CreateToggle(S_Mods, "SpoofName", "Name Spoofer", 5, function(v) CONFIG.SpoofName = v end)
    CreateTextBox(S_Mods, "Spoofed Name", CONFIG.SpoofedNameText, 6, function(v) CONFIG.SpoofedNameText = v end)

    CreateDropdown(S_Mods, "Name Color", 7, function(v) 
        CONFIG.NameColor = v 
        UpdateNameAttributes()
    end, {"Default", "Red", "Gold", "Cyan", "Rainbow"})

    CreateTextBox(S_Mods, "Spoof Flag", CONFIG.SpoofFlag, 8, function(v) 
        CONFIG.SpoofFlag = v 
        if LocalPlayer.Character then pcall(function() LocalPlayer.Character:SetAttribute("country", v) end) end
    end)

    CreateToggle(S_Mods, "RGBSkin", "RGB Skin", 9, function(v)
        CONFIG.RGBSkin = v
        if not v and LocalPlayer.Character then
            pcall(function() LocalPlayer.Character:SetAttribute("skin", OriginalSkinColor) end)
        end
    end)

    CreateToggle(S_Mods, "GodMode", "God Mode", 10)
    CreateToggle(S_Mods, "HideAllNames", "Hide All Names", 11, function(v) CONFIG.HideAllNames = v end)
    CreateToggle(S_Mods, "HideGems", "Hide Gems", 12, function(v) CONFIG.HideGems = v end)

    local S_Safety = CreateContainer(ST_Safety, "SAFETY & WHITELIST", 1)
    CreateToggle(S_Safety, "PlayerDetection", "Player Detection", 1)
    local ModeBtn_Misc = Instance.new("TextButton")
    ModeBtn_Misc.Size = UDim2.new(1, -10, 0, 40)
    ModeBtn_Misc.BackgroundColor3 = Theme.Element
    ModeBtn_Misc.Text = "Safety Action: Stop Auto"
    ModeBtn_Misc.TextColor3 = Theme.Text
    ModeBtn_Misc.Font = Enum.Font.GothamMedium
    ModeBtn_Misc.TextScaled = true 
    ModeBtn_Misc.LayoutOrder = 2
    ModeBtn_Misc.Parent = S_Safety
    Instance.new("UICorner", ModeBtn_Misc).CornerRadius = UDim.new(0, 6)
    local modePadding = Instance.new("UIPadding", ModeBtn_Misc)
    modePadding.PaddingTop = UDim.new(0, 8)
    modePadding.PaddingBottom = UDim.new(0, 8)
    modePadding.PaddingLeft = UDim.new(0, 10)
    modePadding.PaddingRight = UDim.new(0, 10)

    ModeBtn_Misc.MouseButton1Click:Connect(function()
        if CONFIG.SafetyAction == "Stop" then 
            CONFIG.SafetyAction = "Disconnect" 
            ModeBtn_Misc.Text = "Safety Action: Disconnect" 
            ModeBtn_Misc.TextColor3 = Theme.Danger 
        else 
            CONFIG.SafetyAction = "Stop" 
            ModeBtn_Misc.Text = "Safety Action: Stop Auto" 
            ModeBtn_Misc.TextColor3 = Theme.Text 
        end
    end)

    CreateToggle(S_Safety, "AntiAFK", "Anti-AFK", 3)

    local WLContainer = Instance.new("Frame")
    WLContainer.Size = UDim2.new(1, -10, 0, 150)
    WLContainer.BackgroundColor3 = Theme.Element
    WLContainer.LayoutOrder = 4
    WLContainer.Parent = S_Safety
    Instance.new("UICorner", WLContainer).CornerRadius = UDim.new(0, 6)
    local WLLbl = Instance.new("TextLabel")
    WLLbl.Text = "Whitelist"
    WLLbl.Size = UDim2.new(1, -20, 0, 30)
    WLLbl.Position = UDim2.new(0, 10, 0, 0)
    WLLbl.BackgroundTransparency = 1
    WLLbl.Font = Enum.Font.GothamBold
    WLLbl.TextColor3 = Theme.SubText
    WLLbl.TextSize = 13
    WLLbl.TextXAlignment = Enum.TextXAlignment.Left
    WLLbl.Parent = WLContainer
    local WLScroll = Instance.new("ScrollingFrame")
    WLScroll.Size = UDim2.new(1, -10, 1, -35)
    WLScroll.Position = UDim2.new(0, 5, 0, 35)
    WLScroll.BackgroundTransparency = 1
    WLScroll.Parent = WLContainer
    local WLList = Instance.new("UIListLayout", WLScroll)
    WLList.Padding = UDim.new(0, 4)

    local function RefreshWL()
        pcall(function()
            for _, v in pairs(WLScroll:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
            local count = 0
            for _, p in pairs(Players:GetPlayers()) do
                if not p or not p.UserId then continue end
                local b = Instance.new("TextButton")
                b.Size = UDim2.new(1, -4, 0, 25)
                b.BackgroundColor3 = Theme.Sidebar
                b.Text = "  " .. p.Name
                b.TextColor3 = CONFIG.Whitelist[p.UserId] and Theme.Success or Theme.Danger
                b.Font = Enum.Font.GothamMedium
                b.TextSize = 13
                b.TextXAlignment = Enum.TextXAlignment.Left
                b.Parent = WLScroll
                Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
                count = count + 1
                
                if p == LocalPlayer then b.TextColor3 = Theme.Accent b.Text = b.Text .. " YOU" else
                    b.MouseButton1Click:Connect(function()
                        if CONFIG.Whitelist[p.UserId] then CONFIG.Whitelist[p.UserId] = nil else CONFIG.Whitelist[p.UserId] = true end
                        RefreshWL()
                    end)
                end
            end
            WLScroll.CanvasSize = UDim2.new(0, 0, 0, count * 29)
        end)
    end
    Players.PlayerAdded:Connect(RefreshWL)
    Players.PlayerRemoving:Connect(RefreshWL)
    RefreshWL()
    
    local S_ExtraSafety = CreateContainer(ST_Safety, "EXTRA SAFETY", 5)
    CreateToggle(S_ExtraSafety, "StaffDetection", "Staff/Mod Detection", 1)

    task.spawn(function()
        local NotifiedPlayer = false
        while ScriptRunning do
            if CONFIG.PlayerDetection then
                local foundPlayer = false
                local detectedName = ""
                for _, p in pairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer and not CONFIG.Whitelist[p.UserId] then
                        foundPlayer = true
                        detectedName = p.Name
                        break
                    end
                end

                if foundPlayer then
                    if not NotifiedPlayer and CONFIG.WebhookOnDetection then
                        SendPublicWebhook("⚠️ Player Detected!", "A Player (@" .. detectedName .. ") has entered your world!\nDisconnecting for safety purposes...", 16711680)
                        NotifiedPlayer = true
                    end
                    
                    if CONFIG.SafetyAction == "Disconnect" then
                        LocalPlayer:Kick("cx.farm | Player Detected! Disconnecting for safety.")
                        ScriptRunning = false
                    elseif CONFIG.SafetyAction == "Stop" then
                        SafetyPause = true
                    end
                else
                    SafetyPause = false
                    NotifiedPlayer = false
                end
            else
                if SafetyPause and not CONFIG.PlayerDetection then 
                    SafetyPause = false 
                end
                NotifiedPlayer = false
            end
            
            if CONFIG.StaffDetection then
                for _, p in pairs(Players:GetPlayers()) do
                    if p:GetAttribute("namePrefix") == "@" or p:GetAttribute("IsStaff") then
                        if CONFIG.WebhookOnDetection then
                            SendPublicWebhook("🚨 STAFF DETECTED!", "A Staff Member entered your game! Disconnected instantly.", 16711680)
                        end
                        LocalPlayer:Kick("cx.farm | Staff Detected! Disconnected.")
                        ScriptRunning = false
                    end
                end
            end
            
            task.wait(1) 
        end
    end)
end

InitShopTab = function()
    local ST_ShopOverview = CreateSubTab(M_Shop, "Overview", 1)

    local S_Catalog = CreateContainer(ST_ShopOverview, "SHOP CATALOG", 1)
    
    local ShopTabsScroll = Instance.new("ScrollingFrame")
    ShopTabsScroll.Size = UDim2.new(1, -10, 0, 35)
    ShopTabsScroll.BackgroundTransparency = 1
    ShopTabsScroll.ScrollBarThickness = 0
    ShopTabsScroll.ScrollingDirection = Enum.ScrollingDirection.X
    ShopTabsScroll.LayoutOrder = 1
    ShopTabsScroll.Parent = S_Catalog
    
    local ShopTabsLayout = Instance.new("UIListLayout", ShopTabsScroll)
    ShopTabsLayout.FillDirection = Enum.FillDirection.Horizontal
    ShopTabsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ShopTabsLayout.Padding = UDim.new(0, 5)

    local SelectedItemLbl = Instance.new("TextLabel")
    SelectedItemLbl.Size = UDim2.new(1, -10, 0, 25)
    SelectedItemLbl.BackgroundTransparency = 1
    SelectedItemLbl.Text = "Selected: None"
    SelectedItemLbl.TextColor3 = Theme.Success
    SelectedItemLbl.Font = Enum.Font.GothamBold
    SelectedItemLbl.TextSize = 14
    SelectedItemLbl.TextXAlignment = Enum.TextXAlignment.Center
    SelectedItemLbl.LayoutOrder = 2
    SelectedItemLbl.Parent = S_Catalog

    local CatalogScroll = Instance.new("ScrollingFrame")
    CatalogScroll.Size = UDim2.new(1, -10, 0, 160)
    CatalogScroll.BackgroundColor3 = Theme.Sidebar
    CatalogScroll.BackgroundTransparency = 0.2
    CatalogScroll.BorderSizePixel = 0
    CatalogScroll.ScrollBarThickness = 4
    CatalogScroll.ScrollBarImageColor3 = Theme.Accent
    CatalogScroll.LayoutOrder = 3
    CatalogScroll.Parent = S_Catalog
    Instance.new("UICorner", CatalogScroll).CornerRadius = UDim.new(0, 6)
    
    local CatalogPadding = Instance.new("UIPadding", CatalogScroll)
    CatalogPadding.PaddingTop = UDim.new(0, 5)
    CatalogPadding.PaddingBottom = UDim.new(0, 5)
    CatalogPadding.PaddingLeft = UDim.new(0, 5)
    CatalogPadding.PaddingRight = UDim.new(0, 5)

    local CatalogList = Instance.new("UIListLayout", CatalogScroll)
    CatalogList.Padding = UDim.new(0, 4)
    CatalogList.SortOrder = Enum.SortOrder.LayoutOrder

    CatalogList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        CatalogScroll.CanvasSize = UDim2.new(0, 0, 0, CatalogList.AbsoluteContentSize.Y + 10)
    end)
    
    ShopTabsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        ShopTabsScroll.CanvasSize = UDim2.new(0, ShopTabsLayout.AbsoluteContentSize.X + 10, 0, 0)
    end)
    
    local S_Backpack = CreateContainer(ST_ShopOverview, "BACKPACK UPGRADE", 2)
    
    local BackpackBtn = Instance.new("TextButton", S_Backpack)
    BackpackBtn.Size = UDim2.new(1, -10, 0, 40)
    BackpackBtn.BackgroundColor3 = Theme.Accent
    BackpackBtn.Text = "Upgrade Backpack 💎 X"
    BackpackBtn.TextColor3 = Theme.Text
    BackpackBtn.Font = Enum.Font.GothamBold
    BackpackBtn.TextSize = 14
    BackpackBtn.LayoutOrder = 1
    Instance.new("UICorner", BackpackBtn).CornerRadius = UDim.new(0, 6)
    
    CreateToggle(S_Backpack, "AutoUpgradeBackpack", "Auto Upgrade Backpack", 2)
    
    BackpackBtn.MouseButton1Click:Connect(function()
        pcall(function() RequestBuyShopItem:InvokeServer("backpackUpgrade") end)
    end)
    
    local currentActiveShopCategory = nil
    local parsedShopData = {}
    
    local function RenderShopCategory(categoryName)
        for _, v in pairs(CatalogScroll:GetChildren()) do
            if v:IsA("TextButton") then v:Destroy() end
        end
        
        local itemsToRender = {}
        for _, tab in ipairs(parsedShopData) do
            if tab.title == categoryName and tab.content then
                itemsToRender = tab.content
                break
            end
        end

        local order = 1
        for _, item in ipairs(itemsToRender) do
            if type(item) == "table" and item.type == "gemsShop" then
                item.price = tonumber(item.price) or 100

                local Card = Instance.new("TextButton")
                Card.Size = UDim2.new(1, -10, 0, 35)
                Card.BackgroundColor3 = Theme.Element
                Card.Text = ""
                Card.LayoutOrder = order
                Card.Parent = CatalogScroll
                Instance.new("UICorner", Card).CornerRadius = UDim.new(0, 6)
                
                local ItemName = Instance.new("TextLabel", Card)
                ItemName.Size = UDim2.new(0.7, 0, 1, 0)
                ItemName.Position = UDim2.new(0, 10, 0, 0)
                ItemName.BackgroundTransparency = 1
                ItemName.Text = tostring(item.title)
                ItemName.TextColor3 = Theme.Text
                ItemName.Font = Enum.Font.GothamMedium
                ItemName.TextSize = 13
                ItemName.TextXAlignment = Enum.TextXAlignment.Left
            
                local ItemPrice = Instance.new("TextLabel", Card)
                ItemPrice.Size = UDim2.new(0.3, -10, 1, 0)
                ItemPrice.Position = UDim2.new(0.7, 0, 0, 0)
                ItemPrice.BackgroundTransparency = 1
                ItemPrice.Text = "💎 " .. tostring(item.price)
                ItemPrice.TextColor3 = Theme.Accent
                ItemPrice.Font = Enum.Font.GothamBold
                ItemPrice.TextSize = 13
                ItemPrice.TextXAlignment = Enum.TextXAlignment.Right
                
                Card.MouseButton1Click:Connect(function()
                    CONFIG.SelectedShopItem = item.id
                    CONFIG.SelectedShopPrice = item.price
                    SelectedItemLbl.Text = "Selected: " .. item.title .. " - " .. ItemPrice.Text
                    
                    for _, c in pairs(CatalogScroll:GetChildren()) do
                        if c:IsA("TextButton") then 
                            c.BackgroundColor3 = Theme.Element
                        end
                    end
                    Card.BackgroundColor3 = Theme.Sidebar
                end)
                order = order + 1
            end
        end
    end
    
    local function RebuildShopTabs()
        for _, v in pairs(ShopTabsScroll:GetChildren()) do
            if v:IsA("TextButton") then v:Destroy() end
        end
        
        local tabsList = {}
        for _, tab in ipairs(parsedShopData) do
            if tab.title and tab.title ~= "Robux Shop" then table.insert(tabsList, tab.title) end
        end
        
        if not currentActiveShopCategory and #tabsList > 0 then
            currentActiveShopCategory = tabsList[1]
        end
        
        for i, tabName in ipairs(tabsList) do
            local TabBtn = Instance.new("TextButton")
            local textWidth = (#tabName * 7) + 20
            TabBtn.Size = UDim2.new(0, textWidth, 1, -5)
            TabBtn.BackgroundColor3 = (tabName == currentActiveShopCategory) and Theme.Element or Theme.Sidebar
            TabBtn.Text = tabName
            TabBtn.TextColor3 = (tabName == currentActiveShopCategory) and Theme.Text or Theme.SubText
            TabBtn.Font = (tabName == currentActiveShopCategory) and Enum.Font.GothamBold or Enum.Font.GothamMedium
            TabBtn.TextSize = 12
            TabBtn.LayoutOrder = i
            TabBtn.Parent = ShopTabsScroll
            Instance.new("UICorner", TabBtn).CornerRadius = UDim.new(0, 4)
            
            TabBtn.MouseButton1Click:Connect(function()
                currentActiveShopCategory = tabName
                RebuildShopTabs()
                RenderShopCategory(tabName)
            end)
        end
    end

    local lastShopDataStr = ""
    task.spawn(function()
        while ScriptRunning do
            local shopDataStr = workspace:GetAttribute("ShopData")
            if shopDataStr and shopDataStr ~= lastShopDataStr then
                lastShopDataStr = shopDataStr
                pcall(function()
                    parsedShopData = HttpService:JSONDecode(shopDataStr)
                    RebuildShopTabs()
                    if currentActiveShopCategory then
                        RenderShopCategory(currentActiveShopCategory)
                    end
                end)
            end
            
            local currentUpgrades = 0
            local remotes = ReplicatedStorage:FindFirstChild("Remotes")
            local reqStats = remotes and remotes:FindFirstChild("RequestPlayerStats")
            if reqStats then
                pcall(function() 
                    local res = reqStats:InvokeServer("BackpackUpgrade")
                    if type(res) == "table" then
                        currentUpgrades = tonumber(res[1]) or tonumber(res["BackpackUpgrade"]) or 0
                    else
                        currentUpgrades = tonumber(res) or 0
                    end
                end)
            end
            local level = currentUpgrades + 1
            local bpPrice = math.floor(100 * (level * level) - 200 * level + 200)
            CONFIG.BackpackUpgradePrice = bpPrice
            BackpackBtn.Text = "Upgrade Backpack 💎 " .. tostring(bpPrice)
            
            task.wait(5)
        end
    end)

    local function GetRawGems()
        if type(CachedGems) == "string" then
            return tonumber((string.gsub(CachedGems, ",", ""))) or 0
        end
        return tonumber(CachedGems) or 0
    end
    
    task.spawn(function()
        while ScriptRunning do
            if CONFIG.AutoUpgradeBackpack and CONFIG.BackpackUpgradePrice > 0 then
                local currentGems = GetRawGems()
                if currentGems >= CONFIG.BackpackUpgradePrice then
                    pcall(function() RequestBuyShopItem:InvokeServer("backpackUpgrade") end)
                    task.wait(1)
                end
            end
            task.wait(1)
        end
    end)

    local S_AutoBuy = CreateContainer(ST_ShopOverview, "AUTO BUYER & THRESHOLD", 3)

    CreateToggle(S_AutoBuy, "AutoBuyShop", "Enable Auto-Buy", 1)
    CreateTextBox(S_AutoBuy, "Keep Gems Threshold", tostring(CONFIG.ShopThreshold), 2, function(v)
        CONFIG.ShopThreshold = tonumber(v) or 0
    end)
    CreateSlider(S_AutoBuy, "Buy Delay Seconds", 0, 5, 0, 3, function(v) 
        CONFIG.ShopBuyDelay = math.max(0.1, v) 
    end)

    local S_BulkBuy = CreateContainer(ST_ShopOverview, "BULK BUY", 4)

    local BulkBuyBox = Instance.new("Frame")
    BulkBuyBox.Size = UDim2.new(1, -10, 0, 85) 
    BulkBuyBox.BackgroundTransparency = 1
    BulkBuyBox.LayoutOrder = 1
    BulkBuyBox.Parent = S_BulkBuy
    
    local BBLay = Instance.new("UIListLayout", BulkBuyBox)
    BBLay.SortOrder = Enum.SortOrder.LayoutOrder
    BBLay.Padding = UDim.new(0, 8)

    CreateTextBox(BulkBuyBox, "Amount to Buy", tostring(CONFIG.ShopBuyAmount), 1, function(v) 
        CONFIG.ShopBuyAmount = tonumber(v) or 1 
    end)

    local ForceBuyBtn = Instance.new("TextButton")
    ForceBuyBtn.Size = UDim2.new(1, -10, 0, 35)
    ForceBuyBtn.LayoutOrder = 2
    ForceBuyBtn.BackgroundColor3 = Theme.Danger
    ForceBuyBtn.Text = "FORCE BULK BUY"
    ForceBuyBtn.TextColor3 = Theme.Text
    ForceBuyBtn.Font = Enum.Font.GothamBold
    ForceBuyBtn.TextSize = 13
    ForceBuyBtn.Parent = BulkBuyBox
    Instance.new("UICorner", ForceBuyBtn).CornerRadius = UDim.new(0, 6)

    local isBuying = false
    ForceBuyBtn.MouseButton1Click:Connect(function()
        if isBuying then return end
        if not CONFIG.SelectedShopItem then
            SendNotification("Please select an item from the catalog first!", Theme.Danger)
            return
        end
        
        isBuying = true
        ForceBuyBtn.Text = "BUYING... PLEASE WAIT"
        ForceBuyBtn.BackgroundColor3 = Theme.Sidebar
        
        task.spawn(function()
            local successes = 0
            for i = 1, CONFIG.ShopBuyAmount do
                if not ScriptRunning then break end
                
                local currentGems = GetRawGems()
                if currentGems < CONFIG.SelectedShopPrice then
                    SendNotification("Not enough gems! Stopped buying.", Theme.Danger)
                    break
                end
                
                local s, res = pcall(function()
                    if RequestBuyShopItem then
                        return RequestBuyShopItem:InvokeServer(CONFIG.SelectedShopItem)
                    end
                end)
                
                if s and res then successes = successes + 1 end
                task.wait(0.05) 
            end
            SendNotification(string.format("Successfully bought %d items!", successes), Theme.Success)
            
            isBuying = false
            ForceBuyBtn.Text = "FORCE BULK BUY"
            ForceBuyBtn.BackgroundColor3 = Theme.Danger
        end)
    end)

    task.spawn(function()
        while ScriptRunning do
            if CONFIG.AutoBuyShop and CONFIG.SelectedShopItem and RequestBuyShopItem and not isBuying then
                local currentGems = GetRawGems()
                
                if currentGems - CONFIG.SelectedShopPrice >= CONFIG.ShopThreshold then
                    pcall(function()
                        RequestBuyShopItem:InvokeServer(CONFIG.SelectedShopItem)
                    end)
                    task.wait(CONFIG.ShopBuyDelay)
                else
                    task.wait(1)
                end
            else
                task.wait(1)
            end
        end
    end)
end

InitSettingsTab = function()
    local ST_Configs = CreateSubTab(M_Settings, "Configs", 1)
    local ST_Keybinds = CreateSubTab(M_Settings, "Keybinds", 2)
    local ST_Performance = CreateSubTab(M_Settings, "Performance", 3)
    local ST_Credits = CreateSubTab(M_Settings, "Credits", 4)
    local ST_Webhooks = CreateSubTab(M_Settings, "Webhooks", 5)
    local S_ConfigOptions = CreateContainer(ST_Configs, "CONFIGURATION MANAGEMENT", 1)

    local SaveConfigName = "MyConfig"
    CreateTextBox(S_ConfigOptions, "Config Name", "MyConfig", 1, function(v) SaveConfigName = v end)

    local SaveBtn = Instance.new("TextButton")
    SaveBtn.Size = UDim2.new(1, -10, 0, 40)
    SaveBtn.BackgroundColor3 = Theme.Accent
    SaveBtn.Text = "Save Config"
    SaveBtn.TextColor3 = Theme.Text
    SaveBtn.Font = Enum.Font.GothamBold
    SaveBtn.TextSize = 14
    SaveBtn.LayoutOrder = 2
    SaveBtn.Parent = S_ConfigOptions
    Instance.new("UICorner", SaveBtn).CornerRadius = UDim.new(0, 6)

    SaveBtn.MouseButton1Click:Connect(function()
        local save = {}
        for k, v in pairs(CONFIG) do
            if type(v) == "boolean" or type(v) == "number" or type(v) == "string" then
                save[k] = v
            elseif type(v) == "table" and k == "Keybinds" then
                save[k] = {}
                for bk, bv in pairs(v) do save[k][bk] = bv.Name end
            elseif type(v) == "table" and k == "FarmCells" then
                save[k] = v
            end
        end
        local str = HttpService:JSONEncode(save)
        pcall(function()
            if type(writefile) == "function" then
                writefile(ConfigFolder .. "/" .. SaveConfigName .. ".json", str)
                SendNotification("Saved " .. SaveConfigName .. ".json!", Theme.Success)
            else
                SendNotification("Executor does not support file saving.", Theme.Danger)
            end
        end)
    end)

    local ConfigCols = Instance.new("Frame")
    ConfigCols.Size = UDim2.new(1, -10, 0, 100)
    ConfigCols.BackgroundTransparency = 1
    ConfigCols.LayoutOrder = 3
    ConfigCols.Parent = S_ConfigOptions

    local LeftCol = Instance.new("Frame", ConfigCols)
    LeftCol.Size = UDim2.new(0.5, -5, 1, 0)
    LeftCol.BackgroundTransparency = 1
    
    local RightCol = Instance.new("Frame", ConfigCols)
    RightCol.Size = UDim2.new(0.5, -5, 1, 0)
    RightCol.Position = UDim2.new(0.5, 5, 0, 0)
    RightCol.BackgroundTransparency = 1
    
    local L_Layout = Instance.new("UIListLayout", LeftCol)
    L_Layout.Padding = UDim.new(0, 5)
    L_Layout.SortOrder = Enum.SortOrder.LayoutOrder

    local R_Layout = Instance.new("UIListLayout", RightCol)
    R_Layout.Padding = UDim.new(0, 5)
    R_Layout.SortOrder = Enum.SortOrder.LayoutOrder

    local getConfigsFunc = function() return GetSavedConfigs() end

    local function BuildMiniAutoBox(parent, title, isSave)
        local Box = Instance.new("Frame")
        Box.Size = UDim2.new(1, 0, 0, 45)
        Box.BackgroundColor3 = Theme.Sidebar
        Box.Parent = parent
        Instance.new("UICorner", Box).CornerRadius = UDim.new(0, 6)

        local ToggleBtn = Instance.new("TextButton")
        ToggleBtn.Size = UDim2.new(1, 0, 0, 22)
        ToggleBtn.BackgroundTransparency = 1
        ToggleBtn.Text = "  " .. title
        ToggleBtn.TextColor3 = Theme.Text
        ToggleBtn.Font = Enum.Font.GothamMedium
        ToggleBtn.TextSize = 12
        ToggleBtn.TextXAlignment = Enum.TextXAlignment.Left
        ToggleBtn.Parent = Box

        local Ind = Instance.new("Frame")
        Ind.Size = UDim2.new(0, 14, 0, 14)
        Ind.Position = UDim2.new(1, -20, 0.5, -7)
        Ind.BackgroundColor3 = Theme.Element
        Ind.Parent = ToggleBtn
        Instance.new("UICorner", Ind).CornerRadius = UDim.new(0, 4)

        local DropBtn = Instance.new("TextButton")
        DropBtn.Size = UDim2.new(1, -10, 0, 20)
        DropBtn.Position = UDim2.new(0, 5, 0, 22)
        DropBtn.BackgroundColor3 = Theme.Element
        DropBtn.Text = "Target: None"
        DropBtn.TextColor3 = Theme.SubText
        DropBtn.Font = Enum.Font.Gotham
        DropBtn.TextSize = 11
        DropBtn.Parent = Box
        Instance.new("UICorner", DropBtn).CornerRadius = UDim.new(0, 4)

        DropBtn.MouseButton1Click:Connect(function()
            local configs = GetSavedConfigs()
            if #configs == 0 or configs[1] == "No Configs Found" then
                DropBtn.Text = "Target: None"
                return
            end
            
            local current = isSave and CONFIG.AutoSaveName or CONFIG.AutoLoadName
            local idx = 1
            for i, v in ipairs(configs) do if v == current then idx = i break end end
            idx = (idx % #configs) + 1
            local nextConf = configs[idx]
            
            if isSave then CONFIG.AutoSaveName = nextConf else CONFIG.AutoLoadName = nextConf end
            DropBtn.Text = "Target: " .. nextConf
        end)

        ToggleBtn.MouseButton1Click:Connect(function()
            local state
            if isSave then 
                CONFIG.AutoSaveConfig = not CONFIG.AutoSaveConfig
                state = CONFIG.AutoSaveConfig
            else
                CONFIG.AutoLoadConfig = not CONFIG.AutoLoadConfig
                state = CONFIG.AutoLoadConfig
            end
            Ind.BackgroundColor3 = state and Theme.Success or Theme.Element
            
            pcall(function()
                local bootstrap = {
                    AutoLoadConfig = CONFIG.AutoLoadConfig,
                    AutoLoadName = CONFIG.AutoLoadName,
                    AutoSaveConfig = CONFIG.AutoSaveConfig,
                    AutoSaveName = CONFIG.AutoSaveName
                }
                if type(writefile) == "function" then
                    writefile(ConfigFolder .. "/bootstrap.json", HttpService:JSONEncode(bootstrap))
                end
            end)
        end)

        local initState = isSave and CONFIG.AutoSaveConfig or CONFIG.AutoLoadConfig
        Ind.BackgroundColor3 = initState and Theme.Success or Theme.Element
        local initName = isSave and CONFIG.AutoSaveName or CONFIG.AutoLoadName
        if initName and initName ~= "" then DropBtn.Text = "Target: " .. initName end
    end

    BuildMiniAutoBox(LeftCol, "Auto Save", true)
    BuildMiniAutoBox(RightCol, "Auto Load", false)

    local SelectedLoadConfig = ""
    local ConfigDropdownContainer = Instance.new("Frame")
    ConfigDropdownContainer.Size = UDim2.new(1, -10, 0, 40)
    ConfigDropdownContainer.BackgroundColor3 = Theme.Sidebar
    ConfigDropdownContainer.BackgroundTransparency = 1
    ConfigDropdownContainer.LayoutOrder = 4
    ConfigDropdownContainer.ZIndex = 10 
    ConfigDropdownContainer.Parent = S_ConfigOptions

    local ConfigMainBtn = Instance.new("TextButton")
    ConfigMainBtn.Size = UDim2.new(1, 0, 0, 40)
    ConfigMainBtn.BackgroundColor3 = Theme.Element
    ConfigMainBtn.Text = "Select Config: None"
    ConfigMainBtn.TextColor3 = Theme.Text
    ConfigMainBtn.Font = Enum.Font.GothamMedium
    ConfigMainBtn.TextSize = 14
    ConfigMainBtn.ZIndex = 10
    ConfigMainBtn.Parent = ConfigDropdownContainer
    Instance.new("UICorner", ConfigMainBtn).CornerRadius = UDim.new(0, 6)

    local ConfigScroll = Instance.new("ScrollingFrame")
    ConfigScroll.Size = UDim2.new(1, 0, 0, 0)
    ConfigScroll.Position = UDim2.new(0, 0, 0, 45)
    ConfigScroll.BackgroundTransparency = 1
    ConfigScroll.ScrollBarThickness = 6
    ConfigScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    ConfigScroll.ScrollBarImageColor3 = Theme.Accent
    ConfigScroll.Visible = false
    ConfigScroll.ZIndex = 15 
    ConfigScroll.Parent = ConfigDropdownContainer

    local ConfigListLayout = Instance.new("UIListLayout", ConfigScroll)
    ConfigListLayout.Padding = UDim.new(0, 4)

    local configExpanded = false
    ConfigMainBtn.MouseButton1Click:Connect(function()
        configExpanded = not configExpanded
        if configExpanded then
            for _, v in pairs(ConfigScroll:GetChildren()) do if v:IsA("TextButton") or v:IsA("TextLabel") then v:Destroy() end end
            
            local customList = GetSavedConfigs()
            local count = 0
            for _, item in ipairs(customList) do
                local b = Instance.new("TextButton")
                b.Size = UDim2.new(1, -10, 0, 30)
                b.BackgroundColor3 = Theme.Sidebar
                b.Text = "  " .. item
                b.TextColor3 = Theme.SubText
                b.TextXAlignment = Enum.TextXAlignment.Left
                b.Font = Enum.Font.Gotham
                b.TextSize = 13
                b.ZIndex = 15
                b.Parent = ConfigScroll
                Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
                
                b.MouseButton1Click:Connect(function()
                    configExpanded = false
                    ConfigScroll.Visible = false
                    ConfigDropdownContainer.Size = UDim2.new(1, 0, 0, 40)
                    if item ~= "No Configs Found" then
                        SelectedLoadConfig = item
                        ConfigMainBtn.Text = "Select Config: " .. item
                    end
                end)
                count = count + 1
            end
            
            local targetHeight = math.min(150, count * 34)
            ConfigScroll.Size = UDim2.new(1, 0, 0, targetHeight)
            ConfigDropdownContainer.Size = UDim2.new(1, 0, 0, 45 + targetHeight)
            ConfigScroll.Visible = true
        else
            ConfigScroll.Visible = false
            ConfigDropdownContainer.Size = UDim2.new(1, 0, 0, 40)
        end
    end)

    local LoadBtn = Instance.new("TextButton")
    LoadBtn.Size = UDim2.new(1, -10, 0, 40)
    LoadBtn.BackgroundColor3 = Theme.Element
    LoadBtn.Text = "Import / Load Config"
    LoadBtn.TextColor3 = Theme.Text
    LoadBtn.Font = Enum.Font.GothamBold
    LoadBtn.TextSize = 14
    LoadBtn.LayoutOrder = 5
    LoadBtn.Parent = S_ConfigOptions
    Instance.new("UICorner", LoadBtn).CornerRadius = UDim.new(0, 6)

    LoadBtn.MouseButton1Click:Connect(function()
        if SelectedLoadConfig ~= "" and SelectedLoadConfig ~= "No Configs Found" then
            pcall(function()
                if type(readfile) == "function" then
                    local str = readfile(ConfigFolder .. "/" .. SelectedLoadConfig .. ".json")
                    local s, d = pcall(function() return HttpService:JSONDecode(str) end)
                    if s and type(d) == "table" then
                        for k, v in pairs(d) do
                            if k == "Keybinds" and type(v) == "table" then
                                for bk, bv in pairs(v) do
                                    pcall(function() CONFIG.Keybinds[bk] = Enum.KeyCode[bv] end)
                                end
                            elseif k == "FarmCells" and type(v) == "table" then
                                SafeClearTable(FarmCells)
                                for cKey, cVal in pairs(v) do FarmCells[cKey] = cVal end
                                pcall(function()
                                    if GridBox then
                                        for _, btn in pairs(GridBox:GetChildren()) do
                                            if btn:IsA("TextButton") then
                                                local gKey = btn:GetAttribute("GridKey")
                                                if gKey and FarmCells[gKey] then
                                                    btn.BackgroundColor3 = Theme.Success
                                                else
                                                    btn.BackgroundColor3 = Theme.Sidebar
                                                end
                                            end
                                        end
                                    end
                                end)
                            elseif CONFIG[k] ~= nil and type(CONFIG[k]) ~= "table" and k ~= "Whitelist" and k ~= "LockedOrigin" then
                                CONFIG[k] = v
                                if Toggles[k] then pcall(function() Toggles[k](v) end) end
                            end
                        end
                        SendNotification("Config loaded! Settings applied.", Theme.Success)
                    else
                        SendNotification("Invalid config data.", Theme.Danger)
                    end
                else
                    SendNotification("Executor does not support file reading.", Theme.Danger)
                end
            end)
        else
            SendNotification("Please select a config from the dropdown first.", Theme.Danger)
        end
    end)

    local S_Keys = CreateContainer(ST_Keybinds, "BINDINGS", 1)
    CreateKeybind(S_Keys, "AutoPunch", "Auto Punch", CONFIG.Keybinds.AutoPunch, 1)
    CreateKeybind(S_Keys, "AutoPlace", "Auto Place", CONFIG.Keybinds.AutoPlace, 2)
    CreateKeybind(S_Keys, "ModZoom", "Mod Zoom", CONFIG.Keybinds.ModZoom, 3)
    CreateKeybind(S_Keys, "Fly", "Fly Mode", CONFIG.Keybinds.Fly, 4)
    CreateKeybind(S_Keys, "Pathfinding", "Pathfinding", CONFIG.Keybinds.Pathfinding, 5)
    CreateKeybind(S_Keys, "ToggleUI", "Toggle GUI", CONFIG.Keybinds.ToggleUI, 6)
    CreateKeybind(S_Keys, "GodMode", "God Mode", CONFIG.Keybinds.GodMode, 7)
    CreateKeybind(S_Keys, "InfiniteJump", "Infinite Jump", CONFIG.Keybinds.InfiniteJump, 8)

    local S_PerfOpts = CreateContainer(ST_Performance, "OPTIMIZATION MODS", 1)

    CreateToggle(S_PerfOpts, "Disable3D", "Disable 3D Rendering", 1, function(v)
        if type(set3drenderingenabled) == "function" then
            pcall(function() set3drenderingenabled(not v) end)
        else
            pcall(function() RunService:Set3dRenderingEnabled(not v) end)
        end
    end)

    CreateToggle(S_PerfOpts, "LimitFPS", "Limit FPS to 30", 2, function(v)
        if type(setfpscap) == "function" then
            if v then setfpscap(30) else setfpscap(999) end
        end
    end)

    CreateToggle(S_PerfOpts, "LowGFX", "Low GFX", 3, function(v)
        pcall(function()
            if v then
                settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
            else
                settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
            end
        end)
    end)

    local function IsFacePart(obj)
        local name = obj.Name:lower()
        if name == "face" then return true end
        if obj.Parent and obj.Parent.Name:lower() == "head" then return true end
        if obj.Parent and obj.Parent.Name:lower() == "face" then return true end
        return false
    end

    CreateToggle(S_PerfOpts, "HidePlayers", "Hide Other Players", 4, function(v)
        CONFIG.HidePlayers = v
        if not v then
            pcall(function()
                for _, p in pairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer and p.Character then
                        for _, part in pairs(p.Character:GetDescendants()) do
                            if part:IsA("BasePart") or part:IsA("Decal") then
                                if IsFacePart(part) then continue end
                                if OriginalWorkspaceTransparencies[part] then
                                    part.Transparency = OriginalWorkspaceTransparencies[part]
                                else
                                    part.Transparency = 0
                                end
                            end
                        end
                    end
                end
            end)
        end
    end)

    CreateToggle(S_PerfOpts, "DisableParallax", "Disable Parallax Background", 5, function(v)
        pcall(function()
            local bg = workspace:FindFirstChild("ParallaxPlane")
            if bg then bg.Transparency = v and 1 or 0 end
        end)
    end)

    CreateToggle(S_PerfOpts, "DisableTrails", "Disable Game Effects", 6, function(v)
        CONFIG.DisableTrails = v
    end)

    CONFIG.ClearTextures = false
    CreateToggle(S_PerfOpts, "ClearTextures", "Clear Textures & Particles", 7, function(v)
        CONFIG.ClearTextures = v
        pcall(function()
            task.spawn(function()
                local count = 0
                for _, obj in pairs(workspace:GetDescendants()) do
                    count = count + 1
                    if count % 1000 == 0 then task.wait() end
                    
                    if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Sparkles") then
                        obj.Enabled = not v
                    elseif obj:IsA("BillboardGui") then
                        local model = obj:FindFirstAncestorOfClass("Model")
                        local isCharacter = model and model:FindFirstChild("Humanoid")
                        if not isCharacter then
                            obj.Enabled = not v
                        end
                    elseif obj:IsA("Decal") or obj:IsA("Texture") then
                        local model = obj:FindFirstAncestorOfClass("Model")
                        local isCharacter = model and model:FindFirstChild("Humanoid")
                        
                        if not isCharacter then
                            if IsFacePart(obj) then continue end
                            if v then
                                if not OriginalWorkspaceTransparencies[obj] then
                                    OriginalWorkspaceTransparencies[obj] = obj.Transparency
                                end
                                obj.Transparency = 1
                            else
                                if OriginalWorkspaceTransparencies[obj] then
                                    obj.Transparency = OriginalWorkspaceTransparencies[obj]
                                end
                            end
                        end
                    end
                end
            end)
        end)
    end)
    
    CreateToggle(S_PerfOpts, "OptimizeDrops", "Optimize Item Drops", 8, function(v) CONFIG.OptimizeDrops = v end)

    workspace.DescendantAdded:Connect(function(obj)
        if CONFIG.ClearTextures and ScriptRunning then
            if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Sparkles") then
                obj.Enabled = false
            elseif obj:IsA("BillboardGui") then
                task.delay(0.1, function()
                    local isCharacter = obj:FindFirstAncestorOfClass("Model") and obj:FindFirstAncestorOfClass("Model"):FindFirstChild("Humanoid")
                    if not isCharacter then obj.Enabled = false end
                end)
            elseif obj:IsA("Decal") or obj:IsA("Texture") then
                task.delay(0.1, function()
                    local model = obj:FindFirstAncestorOfClass("Model")
                    local isCharacter = model and model:FindFirstChild("Humanoid")
                    if not isCharacter and not IsFacePart(obj) then
                        OriginalWorkspaceTransparencies[obj] = obj.Transparency
                        obj.Transparency = 1
                    end
                end)
            end
        end
    end)

    task.spawn(function()
        while ScriptRunning do
            if CONFIG.HidePlayers or CONFIG.DisableTrails then
                if CONFIG.HidePlayers then
                    pcall(function()
                        for _, p in pairs(Players:GetPlayers()) do
                            if p ~= LocalPlayer and p.Character then
                                for _, part in pairs(p.Character:GetDescendants()) do
                                    if part.Name ~= "HumanoidRootPart" and not IsFacePart(part) and (part:IsA("BasePart") or part:IsA("Decal")) then
                                        if not OriginalWorkspaceTransparencies[part] then
                                            OriginalWorkspaceTransparencies[part] = part.Transparency
                                        end
                                        part.Transparency = 1 
                                    end
                                end
                            end
                        end
                    end)
                end
                
                if CONFIG.DisableTrails then
                    pcall(function()
                        for _, v in pairs(workspace:GetChildren()) do
                            if v.Name == "TradeTrail" or v.Name == "BezierProjectile" then
                                v:Destroy()
                            end
                        end
                    end)
                end
            end
            task.wait(1)
        end
    end)

    local S_WebhookSettings = CreateContainer(ST_Webhooks, "WEBHOOK NOTIFICATIONS", 1)
    
    CreateTextBox(S_WebhookSettings, "Discord Webhook URL", CONFIG.WebhookURL, 1, function(v) CONFIG.WebhookURL = v end)
    CreateToggle(S_WebhookSettings, "WebhookOnDetection", "Notify on Player Detection", 2)
    CreateToggle(S_WebhookSettings, "WebhookOnNukerDone", "Notify on Nuker Finished", 3)
    CreateToggle(S_WebhookSettings, "WebhookOnFarmEmpty", "Notify when Farm is Empty", 4)
    
    local TestWHBtn = Instance.new("TextButton")
    TestWHBtn.Size = UDim2.new(1, -10, 0, 40)
    TestWHBtn.BackgroundColor3 = Theme.Accent
    TestWHBtn.Text = "Test Webhook"
    TestWHBtn.TextColor3 = Theme.Text
    TestWHBtn.Font = Enum.Font.GothamBold
    TestWHBtn.TextSize = 14
    TestWHBtn.LayoutOrder = 5
    TestWHBtn.Parent = S_WebhookSettings
    Instance.new("UICorner", TestWHBtn).CornerRadius = UDim.new(0, 6)
    
    TestWHBtn.MouseButton1Click:Connect(function()
        if CONFIG.WebhookURL ~= "" then
            SendPublicWebhook("✅ Webhook Test Successful!", "Your webhook is properly connected to cx.farm.", 65280)
            SendNotification("Test webhook sent!", Theme.Success)
        else
            SendNotification("Please set a Webhook URL first.", Theme.Danger)
        end
    end)

    local S_Credits = CreateContainer(ST_Credits, "INFO & CREDITS", 1)

    local CredsBox = Instance.new("Frame")
    CredsBox.Size = UDim2.new(1, -10, 0, 0)
    CredsBox.AutomaticSize = Enum.AutomaticSize.Y
    CredsBox.BackgroundColor3 = Theme.Element
    CredsBox.LayoutOrder = 1
    CredsBox.Parent = S_Credits
    Instance.new("UICorner", CredsBox).CornerRadius = UDim.new(0, 6)
    
    local CredsLay = Instance.new("UIListLayout", CredsBox)
    CredsLay.Padding = UDim.new(0, 8)
    CredsLay.SortOrder = Enum.SortOrder.LayoutOrder
    
    local pad = Instance.new("UIPadding", CredsBox)
    pad.PaddingTop = UDim.new(0, 10)
    pad.PaddingLeft = UDim.new(0, 10)
    pad.PaddingRight = UDim.new(0, 10)
    pad.PaddingBottom = UDim.new(0, 10)

    local TitleInfo = Instance.new("TextLabel")
    TitleInfo.Text = "cx.farm v3.1f - " .. currentTier
    TitleInfo.Size = UDim2.new(1, 0, 0, 20)
    TitleInfo.BackgroundTransparency = 1
    TitleInfo.TextColor3 = Theme.Accent
    TitleInfo.Font = Enum.Font.GothamBold
    TitleInfo.TextSize = 14
    TitleInfo.TextXAlignment = Enum.TextXAlignment.Left
    TitleInfo.LayoutOrder = 1
    TitleInfo.Parent = CredsBox

    local SysInfo = Instance.new("TextLabel")
    SysInfo.Text = string.format("Executor: %s\nsUNC Score: %d%%\nGameID: 91833329899022\nPlaceID: 114357342940060", ExecName, ExecSUNC)
    SysInfo.Size = UDim2.new(1, 0, 0, 60)
    SysInfo.BackgroundTransparency = 1
    SysInfo.TextColor3 = Theme.SubText
    SysInfo.Font = Enum.Font.Gotham
    SysInfo.TextSize = 12
    SysInfo.TextYAlignment = Enum.TextYAlignment.Top
    SysInfo.TextXAlignment = Enum.TextXAlignment.Left
    SysInfo.LayoutOrder = 2
    SysInfo.Parent = CredsBox

	local PatchNotes = Instance.new("TextLabel")
    PatchNotes.Text = "<b>[ PATCH NOTES v3.1f ]</b>\n• Reworked Auto Farm into a Strict State-Machine (No overlaps!)\n• Added S-Snake Pattern for highly efficient block breaking\n• ZERO Movement Locks: Walk freely while placing & punching!\n• Frame-perfect flight sync & World Nuker anti-gravity fixes"
    PatchNotes.Size = UDim2.new(1, 0, 0, 85)
    PatchNotes.BackgroundTransparency = 1
    PatchNotes.TextColor3 = Theme.SubText
    PatchNotes.Font = Enum.Font.Gotham
    PatchNotes.TextSize = 12
    PatchNotes.RichText = true
    PatchNotes.TextYAlignment = Enum.TextYAlignment.Top
    PatchNotes.TextXAlignment = Enum.TextXAlignment.Left
    PatchNotes.LayoutOrder = 3
    PatchNotes.Parent = CredsBox
    
    local Divider = Instance.new("Frame")
    Divider.Size = UDim2.new(1, 0, 0, 1)
    Divider.BackgroundColor3 = Theme.Stroke
    Divider.BorderSizePixel = 0
    Divider.LayoutOrder = 4
    Divider.Parent = CredsBox
    
    local LiveStatsBox = Instance.new("Frame")
    LiveStatsBox.Size = UDim2.new(1, 0, 0, 30)
    LiveStatsBox.BackgroundColor3 = Theme.Sidebar
    LiveStatsBox.LayoutOrder = 5
    LiveStatsBox.Parent = CredsBox
    Instance.new("UICorner", LiveStatsBox).CornerRadius = UDim.new(0, 6)
    
    local LiveCountLbl = Instance.new("TextLabel")
    LiveCountLbl.Text = "🌐 Total: 0    🟡 Premium: 0    🟢 Free: 0"
    LiveCountLbl.Size = UDim2.new(1, 0, 1, 0)
    LiveCountLbl.BackgroundTransparency = 1
    LiveCountLbl.TextColor3 = Theme.Success
    LiveCountLbl.Font = Enum.Font.GothamBold
    LiveCountLbl.TextSize = 13
    LiveCountLbl.TextYAlignment = Enum.TextYAlignment.Center
    LiveCountLbl.TextXAlignment = Enum.TextXAlignment.Center
    LiveCountLbl.Parent = LiveStatsBox
    
    task.spawn(function()
        while ScriptRunning do
            if LiveCountLbl.Parent then
                local counts = GetRealLiveUsers()
                if type(counts) == "table" and counts.total then
                    LiveCountLbl.Text = string.format("<font color='#557DFF'>🌐</font> Total: %d   <font color='#F1C40F'>🟡</font> Premium: %d   <font color='#2ECC71'>🟢</font> Free: %d", counts.total, counts.premium, counts.free)
                    LiveCountLbl.RichText = true
                end
            end
            task.wait(2)
        end
    end)

    CreateDropdown(S_Credits, "UI Theme", 2, function(themeName) SwitchTheme(themeName) end, {
        "Dark Default", "Midnight", "Crimson", "Matrix", "Ocean", "Amethyst", "Sunset", "Forest"
    })
end

task.spawn(function()
    task.wait(0.2)
    QueueTabModule("Chat", InitChatTab, "tabs/chat.lua")
QueueTabModule("Premium", InitPremiumTab, "tabs/premium.lua")
QueueTabModule("Auto", InitAutoTab, "tabs/auto.lua")
QueueTabModule("Misc", InitMiscTab, "tabs/misc.lua")
QueueTabModule("Shop", InitShopTab, "tabs/shop.lua")
QueueTabModule("Settings", InitSettingsTab, "tabs/settings.lua")
RunTabBootstrapQueue()

if MainTabs and MainTabs[2] then
        SelectMainTab(MainTabs[2])
    end
end)

UserInputService.InputChanged:Connect(function(input, gp)
    if gp or not ScriptRunning then return end
    if CONFIG.Freecam and input.UserInputType == Enum.UserInputType.MouseWheel then
        FreecamZoom = math.clamp(FreecamZoom - (input.Position.Z * 15), 30, 800)
    end
end)

RunService.RenderStepped:Connect(function(dt)
    if CONFIG.Freecam and ScriptRunning then
        local cam = workspace.CurrentCamera
        local speed = 60 * dt
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then speed = speed * 2.5 end
        
        local move = Vector3.new()
        if UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.Up) then move = move + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) or UserInputService:IsKeyDown(Enum.KeyCode.Down) then move = move + Vector3.new(0, -1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) or UserInputService:IsKeyDown(Enum.KeyCode.Right) then move = move + Vector3.new(1, 0, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) or UserInputService:IsKeyDown(Enum.KeyCode.Left) then move = move + Vector3.new(-1, 0, 0) end
        
        if move.Magnitude > 0 then
            move = move.Unit * speed
            FreecamPos = FreecamPos + move
        end
        
        cam.CFrame = CFrame.new(Vector3.new(FreecamPos.X, FreecamPos.Y, FreecamZoom))
        
        pcall(function()
            if type(PlayerMovement) == "table" then
                PlayerMovement.InputActive = false
                PlayerMovement.MoveX = 0
                PlayerMovement.Jumping = false
            end
        end)
    end
end)

local function RawGlideTo(startPos, endPos, speedPercent)
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local dist = (Vector3.new(startPos.X, startPos.Y, 0) - Vector3.new(endPos.X, endPos.Y, 0)).Magnitude
    if dist < 0.2 then return end
    
    local speed = math.max(35, (speedPercent / 100) * 140) 
    local duration = dist / speed
    local elapsed = 0
    local packetTimer = 0
    
    while elapsed < duration and ScriptRunning and not SafetyPause do
        local dt = RunService.Heartbeat:Wait()
        elapsed = elapsed + dt
        packetTimer = packetTimer + dt
        
        local alpha = math.clamp(elapsed / duration, 0, 1)
        local smoothAlpha = alpha * alpha * (3 - 2 * alpha) 
        local currentPos = startPos:Lerp(endPos, smoothAlpha)
        
        ActiveNukerPos = currentPos
        
        pcall(function() 
            if type(PlayerMovement) == "table" then
                PlayerMovement.Position = currentPos 
                PlayerMovement.VelocityY = 0 
                PlayerMovement.VelocityX = 0
                PlayerMovement.InputActive = false
            end
        end)
        if hrp then pcall(function() hrp.CFrame = CFrame.new(currentPos) * hrp.CFrame.Rotation end) end
        
        if packetTimer >= 0.06 then
            packetTimer = 0
            if PlayerMovementRemote then pcall(function() PlayerMovementRemote:FireServer(Vector2.new(currentPos.X, currentPos.Y)) end) end
        end
    end
    
    ActiveNukerPos = nil 
    
    pcall(function() 
        if type(PlayerMovement) == "table" then
            PlayerMovement.Position = endPos 
            PlayerMovement.VelocityY = 0 
            PlayerMovement.VelocityX = 0
            PlayerMovement.InputActive = true
            PlayerMovement.Grounded = true
        end
    end)
    if hrp then pcall(function() hrp.CFrame = CFrame.new(endPos) * hrp.CFrame.Rotation end) end
    if PlayerMovementRemote then pcall(function() PlayerMovementRemote:FireServer(Vector2.new(endPos.X, endPos.Y)) end) end
end

local function PathIsClear(startPos, endPos)
    local gx1, gy1 = math.floor((startPos.X/4.5)+0.5), math.floor((startPos.Y/4.5)+0.5)
    local gx2, gy2 = math.floor((endPos.X/4.5)+0.5), math.floor((endPos.Y/4.5)+0.5)
    
    local steps = math.max(math.abs(gx2 - gx1), math.abs(gy2 - gy1))
    if steps == 0 then return true, 0 end
    
    local highestBlockY = -99999
    local hit = false
    
    for i = 1, steps - 1 do
        local t = i / steps
        local cx = math.floor(gx1 + (gx2 - gx1) * t + 0.5)
        local cy = math.floor(gy1 + (gy2 - gy1) * t + 0.5)
        local _, _, hasFg, _ = GetTileStatus(cx, cy, "Pathing")
        if hasFg then 
            hit = true 
            if cy > highestBlockY then highestBlockY = cy end
        end
    end
    return not hit, highestBlockY
end

local function SmoothGlideTo(startPos, endPos, speedPercent)
    local isClear, highestBlockY = PathIsClear(startPos, endPos)
    if isClear then
        RawGlideTo(startPos, endPos, speedPercent)
    else
        local vaultY = math.max(math.floor(startPos.Y/4.5), math.floor(endPos.Y/4.5), highestBlockY) + 1
        local wp1 = Vector3.new(startPos.X, vaultY * 4.5, 0)
        local wp2 = Vector3.new(endPos.X, vaultY * 4.5, 0)
        
        RawGlideTo(startPos, wp1, speedPercent)
        RawGlideTo(wp1, wp2, speedPercent)
        RawGlideTo(wp2, endPos, speedPercent)
    end
end

local function NukerPathfindTo(startPos, endPos, speedPercent)
    local startX = math.floor((startPos.X / 4.5) + 0.5)
    local startY = math.floor((startPos.Y / 4.5) + 0.5)
    local targetX = math.floor((endPos.X / 4.5) + 0.5)
    local targetY = math.floor((endPos.Y / 4.5) + 0.5)
    
    local path = CalculateAStar(startX, startY, targetX, targetY)
    
    if path and #path > 0 then
        for _, node in ipairs(path) do
            if SafetyPause or not ScriptRunning or not CONFIG.AutoClear then break end
            local wp = Vector3.new(node.x * 4.5, node.y * 4.5, 0)
            RawGlideTo(GetPlayerPos(), wp, speedPercent)
        end
    else
        SmoothGlideTo(startPos, endPos, speedPercent)
    end
end

local function GetNextNukeTarget(failedList)
    local checks = 0
    for y = 59, 0, -1 do
        local rowXs = {}
        for x = 0, 100 do
            checks = checks + 1
            if checks % 200 == 0 then task.wait() end 
            
            if not failedList[x.."_"..y] then
                local hasBlock, isBad = GetTileStatus(x, y, "Nuker")
                if hasBlock and not isBad then
                    table.insert(rowXs, x)
                end
            end
        end
        
        if #rowXs > 0 then
            local targetX = rowXs[1]
            if y % 2 == 0 then
                local minX = 999999
                for _, x in ipairs(rowXs) do if x < minX then minX = x end end
                targetX = minX
            else
                local maxX = -999999
                for _, x in ipairs(rowXs) do if x > maxX then maxX = x end end
                targetX = maxX
            end
            return {x = targetX, y = y}
        end
    end
    return nil
end

task.spawn(function()
    local wasNuking = false
    while ScriptRunning do
        if CONFIG.AutoClear and not SafetyPause then
            local target = GetNextNukeTarget(FailedClearBlocks)
            if target then
                wasNuking = true
                local standX, standY = target.x, target.y + 1
                local _, standBad, standFg, _ = GetTileStatus(standX, standY, "Nuker")
                
                if standFg or standBad then
                    local _, lBad, lFg, _ = GetTileStatus(target.x - 1, target.y, "Nuker")
                    local _, rBad, rFg, _ = GetTileStatus(target.x + 1, target.y, "Nuker")
                    
                    if not lFg and not lBad then
                        standX = target.x - 1
                        standY = target.y
                    elseif not rFg and not rBad then
                        standX = target.x + 1
                        standY = target.y
                    else
                        standY = target.y + 2 
                    end
                end
                
                local standPos = Vector3.new(standX * 4.5, standY * 4.5, 0)
                NukerPathfindTo(GetPlayerPos(), standPos, CONFIG.ClearSpeed)
                
                ActiveNukerPos = standPos
                local sW = os.clock()
                local didPunch = false
                
                local punchDelay = GetDelayFromPercentage(CONFIG.PunchSpeed)
                local safeDelay = math.max(0.03, punchDelay)

                local hasBlock, badBlock = GetTileStatus(target.x, target.y, "Nuker")
                while hasBlock and not badBlock and (os.clock() - sW < 5) and CONFIG.AutoClear and ScriptRunning and not SafetyPause do
                    ActiveNukerPos = standPos 
                    SafeRemoteFire(PlayerFist, Vector2.new(math.floor(target.x), math.floor(target.y)))
                    didPunch = true
                    task.wait(safeDelay)
                    hasBlock, badBlock = GetTileStatus(target.x, target.y, "Nuker")
                end
                
                if hasBlock and not badBlock then
                    FailedClearBlocks[target.x.."_"..target.y] = true
                    ActiveNukerPos = nil
                elseif CONFIG.ClearCollect and didPunch then
                    task.wait(0.2) 
                    
                    local dropFound = false
                    local drops = workspace:FindFirstChild("Drops")
                    local gems = workspace:FindFirstChild("Gems")
                    local tWP = Vector2.new(target.x * 4.5, target.y * 4.5)
                    
                    local function checkDrops(folder)
                        if folder then
                            for _, d in ipairs(folder:GetChildren()) do
                                if d:IsA("BasePart") then
                                    if (Vector2.new(d.Position.X, d.Position.Y) - tWP).Magnitude <= 5 then
                                        return true
                                    end
                                end
                            end
                        end
                        return false
                    end
                    
                    dropFound = checkDrops(drops) or checkDrops(gems)
                    
                    if dropFound then
                        local dropPos = Vector3.new(target.x * 4.5, target.y * 4.5, 0)
                        
                        SmoothGlideTo(standPos, dropPos, CONFIG.ClearSpeed)
                        ActiveNukerPos = dropPos
                        task.wait(0.05)
                        
                        SmoothGlideTo(dropPos, standPos, CONFIG.ClearSpeed)
                        ActiveNukerPos = standPos
                    end
                    ActiveNukerPos = nil
                else
                    ActiveNukerPos = nil
                end
            else
                if wasNuking then
                    wasNuking = false
                    CONFIG.AutoClear = false
                    ActiveNukerPos = nil
                    if Toggles["AutoClear"] then Toggles["AutoClear"](false) end
                    SendNotification("World Nuker Finished!", Theme.Success)
                    if CONFIG.WebhookOnNukerDone then
                        SendPublicWebhook("✅ World Nuker Finished!", "Your World Nuker has successfully finished clearing the world.", 65280)
                    end
                end
                task.wait(1) 
            end
        else
            wasNuking = false
            ActiveNukerPos = nil
            task.wait(0.5)
        end
    end
end)

local FarmState = "PLACE"
local anchorX, anchorY = nil, nil
local ExpectedPlaceId = nil -- Tracks intended item to prevent Background Auto-Swaps

task.spawn(function()
    while ScriptRunning do
        local hasAction = (CONFIG.AutoPunch or CONFIG.AutoPlace or CONFIG.AutoCollect) and not CONFIG.AutoClear
        
        if hasAction and not SafetyPause and next(FarmCells) then
            
            if FarmState == "PLACE" or not anchorX then
                if CONFIG.LockTiles and CONFIG.LockedOrigin then
                    anchorX = CONFIG.LockedOrigin.X
                    anchorY = CONFIG.LockedOrigin.Y
                else
                    local pos = GetPlayerPos()
                    anchorX = math.floor((pos.X / 4.5) + 0.5)
                    anchorY = math.floor((pos.Y / 4.5) + 0.5)
                end
            end
            
            local anchorPos = Vector3.new(anchorX * 4.5, anchorY * 4.5, 0)

            local cellWorlds = {}
            for key, _ in pairs(FarmCells) do
                local xOff, yOff = key:match("([^:]+):([^:]+)")
                if xOff and yOff then
                    table.insert(cellWorlds, {
                        gx = anchorX + tonumber(xOff), 
                        gy = anchorY + tonumber(yOff), 
                        xOff = tonumber(xOff), 
                        yOff = tonumber(yOff)
                    })
                end
            end

            table.sort(cellWorlds, function(a, b)
                if a.yOff ~= b.yOff then return a.yOff > b.yOff end
                if (math.abs(a.yOff) % 2 == 0) then return a.xOff > b.xOff end
                return a.xOff < b.xOff
            end)

            local pSlot = nil
            if CONFIG.UseSelectedItem then 
                pSlot = TrackedEquippedSlot
                pcall(function()
                    if type(InventoryModule) == "table" then
                        local sel = rawget(InventoryModule, "SelectedHotbar")
                        local hStacks = rawget(InventoryModule, "HotbarStacks")
                        if (type(sel) == "number" or type(sel) == "string") and type(hStacks) == "table" and hStacks[sel] then 
                            pSlot = hStacks[sel][1] 
                        end
                    end
                end)
            elseif CONFIG.SelectedPlaceItemId then 
                pSlot = GetSlotFromItemId(CONFIG.SelectedPlaceItemId) 
            end

            local isBackground = false
            local currentItemId = nil
            local activeItemAmount = 0

            if pSlot and type(InventoryModule) == "table" and type(InventoryModule.Stacks) == "table" then
                local stack = InventoryModule.Stacks[pSlot]
                if type(stack) == "table" and stack.Id then
                    currentItemId = stack.Id
                    activeItemAmount = tonumber(stack.Amount) or 0
                    
                    local baseId = tostring(stack.Id):gsub("_sapling$", "")
                    if type(ItemsManager) == "table" and type(ItemsManager.ItemsData) == "table" then
                        local itemData = ItemsManager.ItemsData[baseId]
                        if type(itemData) == "table" then
                            if itemData.Tile and itemData.Tile.Type == 2 then isBackground = true end
                            if itemData.IsBackground == true or itemData.Background == true then isBackground = true end
                            if itemData.Name and string.find(string.lower(itemData.Name), "background") then isBackground = true end
                        end
                    end
                end
            end

            -- // ANTI-SWAP FAILSAFE //
            if FarmState == "PLACE" and CONFIG.AutoPlace then
                if currentItemId and not ExpectedPlaceId then
                    ExpectedPlaceId = currentItemId
                elseif ExpectedPlaceId and currentItemId ~= ExpectedPlaceId then
                    -- The game auto-swapped the item because we ran out! Force cancel slot.
                    pSlot = nil
                    activeItemAmount = 0
                end
            elseif FarmState ~= "PLACE" then
                ExpectedPlaceId = nil -- Reset when not placing so user can swap items manually
            end

            local function IsCellFilled(gx, gy)
                local hasB, isB, hasF, hasBg = GetTileStatus(gx, gy, "Farm")
                if isB then return true end 
                if CONFIG.AutoPlace and pSlot then
                    return isBackground and hasBg or (not isBackground and hasF)
                else
                    return hasB
                end
            end

            if FarmState == "PLACE" then
                if CONFIG.AutoPlace and pSlot and activeItemAmount > 0 then
                    local emptyCount = 0
                    local placeDelay = GetDelayFromPercentage(CONFIG.PlaceSpeed)
                    local batch = 0
                    
                    for _, cell in ipairs(cellWorlds) do
                        if SafetyPause or not ScriptRunning then break end
                        if not IsCellFilled(cell.gx, cell.gy) then
                            SafeRemoteFire(PlayerPlaceItem, Vector2.new(cell.gx, cell.gy), tonumber(pSlot))
                            emptyCount = emptyCount + 1
                            batch = batch + 1
                            
                            if placeDelay > 0 then
                                task.wait(placeDelay)
                            elseif batch % 6 == 0 then 
                                RunService.Heartbeat:Wait()
                            end
                        end
                    end
                    
                    if emptyCount > 0 then 
                        task.wait(0.15)
                    end
                    
                    local allFilled = true
                    for _, cell in ipairs(cellWorlds) do
                        if not IsCellFilled(cell.gx, cell.gy) then 
                            allFilled = false 
                            break 
                        end
                    end
                    
                    local currentAmount = 0
                    pcall(function()
                        if pSlot and InventoryModule.Stacks[pSlot] then
                            currentAmount = tonumber(InventoryModule.Stacks[pSlot].Amount) or 0
                        end
                    end)
                    
                    -- FIX: Force transition to PUNCH if we completely run out of blocks
                    if allFilled or currentAmount == 0 then 
                        FarmState = "PUNCH" 
                    end
                else
                    FarmState = "PUNCH"
                end

            elseif FarmState == "PUNCH" then
                if CONFIG.AutoPunch then
                    local punchDelay = GetDelayFromPercentage(CONFIG.PunchSpeed)
                    local punchedCount = 0
                    
                    for _, cell in ipairs(cellWorlds) do
                        if SafetyPause or not ScriptRunning then break end
                        
                        if IsCellFilled(cell.gx, cell.gy) then
                            punchedCount = punchedCount + 1
                            local sW = os.clock()
                            
                            while IsCellFilled(cell.gx, cell.gy) and (os.clock() - sW < 2.5) and ScriptRunning and not SafetyPause do
                                SafeRemoteFire(PlayerFist, Vector2.new(cell.gx, cell.gy))
                                
                                if punchDelay > 0 then
                                    task.wait(punchDelay)
                                else
                                    SafeRemoteFire(PlayerFist, Vector2.new(cell.gx, cell.gy))
                                    RunService.Heartbeat:Wait()
                                end
                            end
                        end
                    end
                    
                    if punchedCount > 0 then task.wait(0.15) end 
                    
                    local allBroken = true
                    for _, cell in ipairs(cellWorlds) do
                        local hasB, isB, hasF, hasBg = GetTileStatus(cell.gx, cell.gy, "Farm")
                        if not isB and (hasF or hasBg) then
                            allBroken = false
                            break
                        end
                    end
                    
                    if allBroken then FarmState = "COLLECT" end
                else
                    FarmState = "COLLECT"
                end

            elseif FarmState == "COLLECT" then
                if CONFIG.AutoCollect then
                    task.wait(0.2) 
                    
                    local tilesWithDrops = {}
                    local dropCount = 0
                    
                    pcall(function()
                        for _, folderName in ipairs({"Drops", "Gems"}) do
                            local f = workspace:FindFirstChild(folderName)
                            if f then
                                for _, item in ipairs(f:GetChildren()) do
                                    if item:IsA("BasePart") then
                                        local tU = item:GetAttribute("t")
                                        if not tU or tonumber(tU) == LocalPlayer.UserId then
                                            local dgx = math.floor((item.Position.X / 4.5) + 0.5)
                                            local dgy = math.floor((item.Position.Y / 4.5) + 0.5)
                                            local farmKey = (dgx - anchorX) .. ":" .. (dgy - anchorY)
                                            
                                            if FarmCells[farmKey] then
                                                tilesWithDrops[dgx .. "_" .. dgy] = {wp = Vector3.new(dgx * 4.5, dgy * 4.5, 0)}
                                                dropCount = dropCount + 1
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end)

                    if dropCount > 0 then
                        local currentPos = GetPlayerPos()
                        local startCollectPos = currentPos 
                        
                        pcall(function()
                            if type(PlayerMovement) == "table" then
                                PlayerMovement.InputActive = false
                            end
                        end)

                        local flightSpeed = CONFIG.CollectSpeed
                        
                        for _, dropData in pairs(tilesWithDrops) do
                            if SafetyPause or not ScriptRunning then break end
                            local targetWP = dropData.wp
                            
                            SmoothGlideTo(currentPos, targetWP, flightSpeed)
                            currentPos = targetWP
                            
                            task.wait(0.05) 
                        end
                        
                        SmoothGlideTo(currentPos, startCollectPos, flightSpeed)
                    end
                end
                
                pcall(function()
                    if type(PlayerMovement) == "table" then
                        PlayerMovement.InputActive = true
                        PlayerMovement.Grounded = true
                    end
                end)
                
                FarmState = "PLACE"
            end
            
            task.wait()
        else
            pcall(function()
                if type(PlayerMovement) == "table" then
                    PlayerMovement.InputActive = true
                end
            end)
            FarmState = "PLACE"
            task.wait(0.25)
        end
    end
end)

task.spawn(function()
    while ScriptRunning do
        task.wait(0.1) 
        local px, py
        if CONFIG.LockTiles and CONFIG.LockedOrigin then
            px = CONFIG.LockedOrigin.X
            py = CONFIG.LockedOrigin.Y
        else
            local pos = GetPlayerPos()
            px = math.floor((pos.X / 4.5) + 0.5)
            py = math.floor((pos.Y / 4.5) + 0.5)
        end
        
        local activeVisuals = {}
        
        if CONFIG.ShowVisuals then
            for key, _ in pairs(FarmCells) do
                local xOff, yOff = key:match("([^:]+):([^:]+)")
                local tx, ty = px + tonumber(xOff), py + tonumber(yOff)
                local wPos = Vector3.new(tx * 4.5, ty * 4.5, 0)
                activeVisuals["Farm_" .. tx .. "_" .. ty] = {Pos = wPos, Color = Theme.Accent, Size = Vector3.new(4.5, 4.5, 1.1)}
            end
        end
        
        for vKey, data in pairs(activeVisuals) do
            if not Adornments[vKey] then
                local b = Instance.new("Part")
                b.Size = data.Size
                b.Transparency = 0.5
                b.Material = Enum.Material.Neon
                b.Anchored = true
                b.CanCollide = false
                b.CastShadow = false
                b.Parent = VisualFolder
                Adornments[vKey] = b
            end
            Adornments[vKey].CFrame = CFrame.new(data.Pos)
            Adornments[vKey].Color = data.Color
            Adornments[vKey].Transparency = 0.5
        end
        
        for key, adornment in pairs(Adornments) do
            if not activeVisuals[key] then adornment.Transparency = 1 end
        end
    end
end)

RunService.Heartbeat:Connect(function(dt)
    if not ScriptRunning then return end

    if CONFIG.InfiniteJump then
        if type(PlayerMovement) == "table" then
            pcall(function()
                PlayerMovement.RemainingJumps = 99
                PlayerMovement.MaxJump = 99
            end)
        end
    end
    
    local char = LocalPlayer.Character
    
    if CONFIG.GodMode and char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health < hum.MaxHealth then hum.Health = hum.MaxHealth end
    end
    
    if type(PlayerMovement) == "table" then
        if CONFIG.GodMode then
            pcall(function() PlayerMovement.Sensor = false end)
        else
            pcall(function() PlayerMovement.Sensor = true end)
        end
        
        if CONFIG.Fly and not CONFIG.AutoClear then
            pcall(function()
                PlayerMovement.VelocityY = 0 
                PlayerMovement.VelocityX = 0
                PlayerMovement.Grounded = true 
                
                local speed = CONFIG.FlySpeed 
                local mx, my = 0, 0
                
                if UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.Space) or UserInputService:IsKeyDown(Enum.KeyCode.Up) then my = 1 end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) or UserInputService:IsKeyDown(Enum.KeyCode.Down) then my = -1 end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) or UserInputService:IsKeyDown(Enum.KeyCode.Left) then mx = -1 end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) or UserInputService:IsKeyDown(Enum.KeyCode.Right) then mx = 1 end
                
                local isMoving = (mx ~= 0 or my ~= 0)
                
                if isMoving then
                    local pos = rawget(PlayerMovement, "Position")
                    if pos then
                        PlayerMovement.Position = pos + Vector3.new(mx * speed * dt, my * speed * dt, 0)
                        LastNoclipPos = PlayerMovement.Position
                        WasNoclipping = true
                    end
                else
                    if WasNoclipping and LastNoclipPos then
                        WasNoclipping = false
                        if PlayerMovementRemote then
                            task.spawn(function()
                                local tX, tY = LastNoclipPos.X, LastNoclipPos.Y
                                local skyY = 2000
                                pcall(function() PlayerMovementRemote:FireServer(Vector2.new(tX, skyY)) end)
                                task.wait(0.05)
                                pcall(function() PlayerMovementRemote:FireServer(Vector2.new(tX, tY)) end)
                            end)
                        end
                        LastNoclipPos = nil
                    end
                end
            end)
        else
            if CONFIG.SpeedBoost > 0 and not CONFIG.AutoClear then
                pcall(function()
                    local moveX = rawget(PlayerMovement, "MoveX")
                    if moveX and moveX ~= 0 then
                        local boost = (CONFIG.SpeedBoost / 100) * 0.8
                        PlayerMovement.VelocityX = PlayerMovement.VelocityX + (moveX * boost)
                    end
                end)
            end
        end
    end
end)

task.spawn(function()
    task.wait(0.6)
    if IsUnsupportedExecutor then
        if LoadingText then LoadingText.Text = "Unsupported Executor (" .. ExecName .. "). Unloading..." end
        if LoadingText then LoadingText.TextColor3 = Theme.Danger end
        task.wait(2)
        ScriptRunning = false
        if VisualFolder then VisualFolder:Destroy() end
        if ScreenGui then ScreenGui:Destroy() end
        return
    end

    if LoadingText then LoadingText.Text = string.format("Executor: %s | SUNC: %d%%", ExecName, ExecSUNC) end
    task.spawn(function() pcall(RefreshInventoryUI) end)
    task.wait(0.8)
    
    if LoadingText then LoadingText.Text = string.format("Loaded %s Version cx.farm", currentTier) end
    task.wait(0.8)
    
    if LoadingText then LoadingText.Text = "Welcome to cx.farm" end
    task.wait(0.8)
    
    pulseTween:Cancel()
    TweenService:Create(LoadingText, TweenInfo.new(0.4), {TextTransparency = 1}):Play()
    TweenService:Create(LoadingFrame, TweenInfo.new(0.4), {BackgroundTransparency = 1}):Play()
    
    task.wait(0.45) 
    if LoadingFrame then LoadingFrame:Destroy() end
    if MainFrame then
        MainFrame.Size = DefaultSize
        MainScale.Scale = 0
        MainFrame.Visible = true
        TweenService:Create(MainScale, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
    end
    
    local shortName = string.sub(LocalPlayer.Name, 1, 2) .. "****"
    SystemMessage("Thank you for using cx.farm. Welcome " .. shortName)
end)

task.spawn(function()
    local frames = 0
    local conn
    pcall(function()
        conn = RunService.RenderStepped:Connect(function() frames = frames + 1 end)
    end)
    
    while ScriptRunning do
        task.wait(1)
        local currentFps = frames
        frames = 0
        
        local pingVal = 0
        pcall(function() 
            pingVal = math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue())
        end)
        
        local px, py = 0, 0
        pcall(function()
            local pos = GetPlayerPos()
            px = math.floor((pos.X / 4.5) + 0.5)
            py = math.floor((pos.Y / 4.5) + 0.5)
        end)
        
        if Watermark then
            Watermark.Text = string.format(" cx.farm | Craft A World | X: %d Y: %d | FPS: %d | Ping: %d ms", px, py, currentFps, pingVal)
        end
    end
    if conn then conn:Disconnect() end
end)

UserInputService.InputBegan:Connect(function(input, gp)
    if gp or not ScriptRunning then return end
    
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        IsHoldingMouse = true
    end
    
    if CONFIG.InfiniteJump and (input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.W or input.KeyCode == Enum.KeyCode.Up) then
        if type(PlayerMovement) == "table" then
            pcall(function()
                PlayerMovement.RemainingJumps = 99
                PlayerMovement.MaxJump = 99
                PlayerMovement.VelocityY = 1.5 
                PlayerMovement.Jumping = true
                PlayerMovement.Grounded = false
                PlayerMovement.JumpHoldTime = 0
            end)
        end
    end

    if BindingAction then BindingAction.Callback(input.KeyCode) return end
    
    if input.KeyCode == CONFIG.Keybinds.ToggleUI then
        if UI_State.Minimized then
            UI_State.Minimized = false
            if MiniLogo then MiniLogo.Visible = false; MiniLogo.Size = UDim2.new(0,0,0,0) end
            if MainFrame then
                MainFrame.Visible = true
                TweenService:Create(MainScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
            end
        else
            UI_State.Minimized = true
            if MainFrame then
                local tw = TweenService:Create(MainScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Scale = 0})
                tw:Play()
                tw.Completed:Connect(function()
                    if UI_State.Minimized then MainFrame.Visible = false end
                end)
            end
            if MiniLogo then 
                MiniLogo.Size = UDim2.new(0, 50, 0, 50)
                if MainFrame then MiniLogo.Position = MainFrame.Position end
                MiniLogo.Visible = true 
            end
        end
    elseif input.KeyCode == CONFIG.Keybinds.AutoPunch then
        TriggerKeybindToggle("AutoPunch", "Auto Punch")
    elseif input.KeyCode == CONFIG.Keybinds.AutoPlace then
        TriggerKeybindToggle("AutoPlace", "Auto Place")
    elseif input.KeyCode == CONFIG.Keybinds.ModZoom then
        TriggerKeybindToggle("ModZoom", "Mod Zoom")
        if CONFIG.ModZoom then LocalPlayer.CameraMaxZoomDistance = 18000; LocalPlayer.CameraMinZoomDistance = 0 else LocalPlayer.CameraMaxZoomDistance = 3000; LocalPlayer.CameraMinZoomDistance = 500 end
    elseif input.KeyCode == CONFIG.Keybinds.GodMode then
        TriggerKeybindToggle("GodMode", "God Mode")
    elseif input.KeyCode == CONFIG.Keybinds.Fly then
        TriggerKeybindToggle("Fly", "Fly Mode")
    elseif input.KeyCode == CONFIG.Keybinds.InfiniteJump then
        TriggerKeybindToggle("InfiniteJump", "Infinite Jump")
    elseif input.KeyCode == CONFIG.Keybinds.Pathfinder then
        TriggerKeybindToggle("Pathfinder", "Pathfinder")
    end
end)

UserInputService.InputEnded:Connect(function(input, gp)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        IsHoldingMouse = false
    end
end)

if MiniBtn then
    MiniBtn.MouseButton1Click:Connect(function()
        UI_State.Minimized = true
        if MainFrame then
            local tw = TweenService:Create(MainScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Scale = 0})
            tw:Play()
            tw.Completed:Connect(function()
                if UI_State.Minimized then MainFrame.Visible = false end
            end)
        end
        if MiniLogo then 
            MiniLogo.Size = UDim2.new(0, 50, 0, 50)
            if MainFrame then MiniLogo.Position = MainFrame.Position end
            MiniLogo.Visible = true 
        end
    end)
end

if MiniLogoBtn then
    MiniLogoBtn.MouseButton1Click:Connect(function()
        if IsDraggingUI then return end
        UI_State.Minimized = false
        if MiniLogo then MiniLogo.Visible = false; MiniLogo.Size = UDim2.new(0,0,0,0) end
        if MainFrame then
            MainFrame.Visible = true
            TweenService:Create(MainScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
            if MiniLogo then MainFrame.Position = MiniLogo.Position end
        end
    end)
end

EnableNativeDrag(Header, MainFrame)
EnableNativeDrag(MiniLogoBtn, MiniLogo)
EnableNativeDrag(Watermark)

if ResizeGrip then
    EnableNativeResize(ResizeGrip, MainFrame)
end
