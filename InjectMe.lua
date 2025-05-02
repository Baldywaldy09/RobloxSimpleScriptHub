local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()
local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local scriptsFolder = "BaldySimpleScriptHub/scripts"
local Options = Fluent.Options
local inputBeganConnection
local inputEndedConnection
local jumpRequestConnection
local humanoidStateChangedConnected

local currentVer = "1.0.0"

-- ========== Globaly Used Functions ==========
local function readfilesafe(path) return readfile(path) end

local function log(level, message)
    if (level == 0) then print("[Simple-Script-Hub] " .. message) end
    if (level == 1) then warn ("[Simple-Script-Hub] " .. message) end
    if (level == 3) then error("[Simple-Script-Hub] " .. message) end
end

local function notification(message, duration)
    Fluent:Notify({
        Title = "Simple Script Hub",
        Content = message,
        Duration = duration
    })
end

local scriptFiles = {}
local function returnAllScripts(reloading)
    if not reloading then
        if next(scriptFiles) ~= nil then
            return scriptFiles
        end
    end

    scriptFiles = {}

    local function listFiles(dir)
        local filesList = {}
        for _, file in ipairs(listfiles(dir)) do
            if file:match("%.luau$") or file:match("%.lua$") or file:match("%.txt$") then
                table.insert(filesList, file)
            end
        end
        return filesList
    end

    local filesList  = listFiles(scriptsFolder)

    for _, file in ipairs(filesList) do
        local fileName = file:match("([^/]+)$") -- Extract the file name from the path
        table.insert(scriptFiles, fileName)
    end

    return scriptFiles
end

local function execute(lua_code)
    local func, errorMsg = loadstring(lua_code)

    if func then
        local success, result = pcall(func)

        if success then
            log(0, "Execution successful!")
            return "NO_ERROR"
        else
            log(2, "Error during execution: " .. result)
            return result
        end
    else
        log(2, "Failed to load code: " .. errorMsg)
        return errorMsg
    end
end
-- ========== Globaly Used Functions ==========



-- ========== GUI Functions ==========
local Window
local Tabs

local function loadMainGUI()
    Window = Fluent:CreateWindow({
        Title = "Simple Script Hub",
        SubTitle = "by Baldy09",
        TabWidth = 130,
        Size = UDim2.fromOffset(600, 320),
        Acrylic = true,
        Theme = "Darker",
        MinimizeKey = Enum.KeyCode.RightControl
    })

    Tabs = {
        Main = Window:AddTab({ Title = "Home", Icon = "layout-grid" }),
        localScripts = Window:AddTab({ Title = "Local Scripts", Icon = "file-code" }),
        universalScripts = Window:AddTab({ Title = "Universal Scripts", Icon = "file-code" }),
        playerTools = Window:AddTab({ Title = "Player Tools", Icon = "wrench" }),
        Settings = Window:AddTab({ Title = "Customisation", Icon = "settings" })
    }
end

local function loadTabMain()
    Tabs.Main:AddToggle("AutoExecToggle", {
        Title = "Enable Auto Exec Scripts", 
        Default = false
    })

    Tabs.Main:AddDropdown("AutoExecDropdown", {
        Title = "Auto Exec Scripts:",
        Values = returnAllScripts(false),
        Multi = true,
        Default = { }
    })

    Tabs.Main:AddParagraph({
        Title = "Scripts not reloading / Missing Scripts?",
        Content = "If your missing scripts or they are not realoading head over to the tab \"Local Scripts\" and press the \"Reload All Scripts\" button"
    })
end

local function loadTabLocalScripts()
    Tabs.localScripts:AddDropdown("ExecDropdown", {
        Title = "Scripts to execute",
        Values = returnAllScripts(false),
        Multi = true,
        Default = { }
    })

    Tabs.localScripts:AddButton({
        Title = "Execute Scripts",
        Description = "Click to execute the selected scripts above",
        Callback = function()
            Window:Dialog({
                Title = "Confirmation",
                Content = "Are you sure you want to execute the selected scripts?",
                Buttons = {
                    {
                        Title = "Yes",
                        Callback = function()
                            log(0, "Executing Selected Scripts...")
                            notification("Executing Selected Scripts...", 4)

                            local wasError = false
                            local total = 0
                            for fileName, _ in pairs(Options.ExecDropdown.Value) do
                                total = total + 1

                                local success, scriptContent = pcall(readfilesafe, scriptsFolder .. "/" .. fileName)
                                local exeResult = execute(scriptContent)

                                if exeResult ~= "NO_ERROR" then
                                    wasError = true
                                    notification(exeResult .. "\n\nYou can view the above error in your log [F9]", 5)
                                end
                            end

                            if not wasError then
                                log(0, "Successfully executed " .. total .. " scripts") 
                                notification("Successfully executed " .. total .. " scripts", 4)
                            end
                        end
                    },
                    {
                        Title = "No"
                    }
                }
            })
        end
    })
end

local function loadTabUniversalScripts()
    local scriptsJson = HttpService:JSONDecode(game:HttpGet("https://raw.githubusercontent.com/Baldywaldy09/RobloxSimpleScriptHub/main/universal_scripts.json"))

    for scriptName, scriptJson in pairs (scriptsJson) do
        Tabs.universalScripts:AddButton({
            Title = scriptName, 
            Description = scriptJson.description,
            Callback = function()
                log(0, "Executing universal script: " .. scriptName)

                local scriptContent = scriptJson.script
                execute(scriptContent)
            end
        })
    end

end


local function loadTabPlayerTools()
    Tabs.playerTools:AddToggle("ShiftToRunToggle", {
        Title = "Enable \"Shift To Run\"",
        Default = false
    })

    Tabs.playerTools:AddToggle("DoubleJumpToggle", {
        Title = "Double Jump",
        Default = false
    })


    Tabs.playerTools:AddSlider("WalkSpeedSlider", {
        Title = "Walk Speed",
        Default = 16,
        Min = 16,
        Max = 70,
        Rounding = 2,
        Callback = function(Value)
            local player = game.Players.LocalPlayer
            local character = player.Character or player.CharacterAdded:Wait()
            local humanoid = character:WaitForChild("Humanoid")

            humanoid.WalkSpeed = Value
        end
    })

    Tabs.playerTools:AddSlider("WalkSpeedSlider", {
        Title = "Jump Power",
        Default = 16,
        Min = 16,
        Max = 70,
        Rounding = 2,
        Callback = function(Value)
            local player = game.Players.LocalPlayer
            local character = player.Character or player.CharacterAdded:Wait()
            local humanoid = character:WaitForChild("Humanoid")

           -- humanoid.WalkSpeed = Value
        end
    })
end

local function loadTabSettings()
    InterfaceManager:BuildInterfaceSection(Tabs.Settings)
end
-- ========== GUI Functions ==========



-- ========== Shift To Run ==========
local function onInputBegan(input, isProcessed)
    if isProcessed then return end
    if not Options.ShiftToRunToggle.Value then return end
    
    if input.KeyCode == Enum.KeyCode.LeftShift then
		local player = game.Players.LocalPlayer
		local character = player.Character or player.CharacterAdded:Wait()
		local humanoid = character:WaitForChild("Humanoid")
		
        humanoid.WalkSpeed = 32
    end
end

local function onInputEnded(input, isProcessed)
    if not Options.ShiftToRunToggle.Value then return end

    if input.KeyCode == Enum.KeyCode.LeftShift then
		local player = game.Players.LocalPlayer
		local character = player.Character or player.CharacterAdded:Wait()
		local humanoid = character:WaitForChild("Humanoid")

		humanoid.WalkSpeed = 16
    end
end
-- ========== Shift To Run ==========



-- ========== Double Jump ==========
local jumpPower = 50 -- Customize this value to adjust double jump height
local hasDoubleJumped = false

local function onJumpRequest()
    local player = game.Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoid = character:WaitForChild("Humanoid")

    if humanoid:GetState() == Enum.HumanoidStateType.Freefall and not hasDoubleJumped then
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        humanoid:Move(Vector3.new(0, jumpPower, 0), true)
        hasDoubleJumped = true
    end
end

local function onHumanoidStateChanged(oldState, newState)
    if newState == Enum.HumanoidStateType.Landed then
        hasDoubleJumped = false
    end
end

-- ========== Double Jump ==========



-- ========== Config Functions ==========
local function loadConfig()
    SaveManager:SetLibrary(Fluent)
    SaveManager:SetFolder("BaldySimpleScriptHub")
    InterfaceManager:SetLibrary(Fluent)
    InterfaceManager:SetFolder("BaldySimpleScriptHub")
    SaveManager:Load("main")
end

local function startConfigSaveTick()
    while not Fluent.Unloaded do wait(0.5) end

    log(0, "Fluent Menu Unloaded | Unloading Script...")
    SaveManager:Save("main")

    inputBeganConnection:Disconnect()
    inputEndedConnection:Disconnect()
    jumpRequestConnection:Disconnect()
    humanoidStateChangedConnected:Disconnect()

	inputBeganConnection = nil
	inputEndedConnection = nil
    jumpRequestConnection = nil
    humanoidStateChangedConnected = nil

    log(0, "Script Unloaded Bye!")
end

-- ========== Config Functions ==========



-- ========== Startup Functions ==========
local function init()
    Window:SelectTab(1)
	
	inputBeganConnection = UserInputService.InputBegan:Connect(onInputBegan)
	inputEndedConnection = UserInputService.InputEnded:Connect(onInputEnded)
    jumpRequestConnection = UserInputService.JumpRequest:Connect(onJumpRequest)

    local player = game.Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoid = character:WaitForChild("Humanoid")
    humanoidStateChangedConnected = humanoid.StateChanged:Connect(onHumanoidStateChanged)

    if Options.AutoExecToggle.Value then
        log(0, "Auto Exec Enabled... Getting scripts to execute")
        notification("Auto executing scripts...", 4)
        wait(0.5)

        local AutoExecDropdownValues = {}
        for Value, State in next, Options.AutoExecDropdown.Value do
            log(0, Value)
            table.insert(AutoExecDropdownValues, Value)
        end


        local wasError = false
        local total = 0
        for _, fileName in pairs(AutoExecDropdownValues) do
            total = total + 1
            
            local success, scriptContent = pcall(readfilesafe, scriptsFolder .. "/" .. fileName)

            log(0, "Executing: " .. fileName)
            local exeSuccess, exeResult = pcall(function() return execute(scriptContent) end)            
            if not exeSuccess or exeResult ~= "NO_ERROR" then
                wasError = true
                notification((exeSuccess and exeResult or "Execution error") .. "\n\nYou can view the above error in your log [F9]", 5)
            end
        end
		

        if not wasError then
            log(0, "Successfully executed " .. total .. " scripts") 
            notification("Successfully executed " .. total .. " scripts", 4)
        end
    end
end
-- ========== Startup Functions ==========


-- ========== Load Script ==========
local function loadScript()
    log(0, "Simple Script Hub v" .. currentVer .. " | By Baldy09")
    notification("Simple Script Hub v" .. currentVer .. " | By Baldy09", 8)

    log(0, "Starting GUI...")
    loadMainGUI()

    log(0, "Loading tab: Home...")
    loadTabMain()

    log(0, "Loading tab: Local Scripts...")
    loadTabLocalScripts()

    log(0, "Loading tab: Universal Scripts...")
    loadTabUniversalScripts()

    log(0, "Loading tab: Player Tools...")
    loadTabPlayerTools()

    log(0, "Loading Config...")
    loadConfig()
    log(0, "Config Loaded")

    log(0, "Loading tab: Settings...")
    loadTabSettings()
    
    log(0, "GUI Started")

    log(0, "Checking Version...")
    local mainJson = HttpService:JSONDecode(game:HttpGet("https://raw.githubusercontent.com/Baldywaldy09/RobloxSimpleScriptHub/main/main.json"))
    
    if mainJson.newestVer ~= currentVer then
        log(1, "Outdated Script! | Newest Version At: https://github.com/Baldywaldy09/RobloxSimpleScriptHub")

        Window:Dialog({
            Title = "Outdated Script",
            Content = "Your script is outdated! We recommend to update it asap",
            Buttons = {
                {
                    Title = "Ok",
                    Callback = function()
                        Window:Dialog({
                            Title = "Where to update?",
                            Content = "https://github.com/Baldywaldy09/RobloxSimpleScriptHub",
                            Buttons = {
                                {
                                    Title = "Ok"
                                }
                            }
                        })
                    end
                }
            }
        })
    else 
        log(0, "Using Newest Version")
    end

    log(0, "Finishing initialisation...")
    init()

    log(0, "Menu Loaded! Enjoy")
end
-- ========== Load Script ==========


-- Start the menu:
loadScript()
startConfigSaveTick()
