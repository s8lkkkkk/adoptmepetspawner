if not game:IsLoaded() then
    game.Loaded:Wait() -- Wait for game to load
end

-- Roblox Services
local HttpServ = game:GetService("HttpService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local bb = game:GetService("VirtualUser") -- Anti AFK

-- Anti-AFK
game:GetService("Players").LocalPlayer.Idled:Connect(function()
    bb:CaptureController()
    bb:ClickButton2(Vector2.new())
end)

-- Files and NPC setup
local npcFile = isfile("user.txt")
local joinedFile = isfile("joined_ids.txt")

if not npcFile then
    writefile("user.txt", "npc username")
end

if not joinedFile then
    writefile("joined_ids.txt", "[]") -- Initialize empty JSON array
end

local npcUser = readfile("user.txt")
local joinedIds = HttpServ:JSONDecode(readfile("joined_ids.txt"))
local didNpcLeave = false
local timer = 0

-- Discord Webhook URL
local webhook = "PASTE_YOUR_WEBHOOK_URL_HERE" -- Add your webhook here

-- Send a message to Discord
local function sendWebhookMessage(text)
    request({
        Url = webhook,
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = HttpServ:JSONEncode({content = text})
    })
end

-- Save joined message IDs
local function saveJoinedId(messageId)
    table.insert(joinedIds, messageId)
    writefile("joined_ids.txt", HttpServ:JSONEncode(joinedIds))
end

-- Detect NPC leaving the server
local function waitForNpcLeave()
    local playerRemovedConnection
    playerRemovedConnection = game.Players.PlayerRemoving:Connect(function(removedPlayer)
        if removedPlayer.Name == npcUser then
            if playerRemovedConnection then
                playerRemovedConnection:Disconnect()
            end
            didNpcLeave = true
            sendWebhookMessage("NPC left the server: "..npcUser)
        end
    end)
end

waitForNpcLeave() -- Start listening

-- Auto-join function (logs to webhook instead of Discord API)
local function unifiedAutoJoin()
    if didNpcLeave or timer >= 10 then
        sendWebhookMessage("NPC left or timer reached 10, ready to join new server")
        -- If you have placeId/jobId logic, you can call TeleportService here
        -- Example:
        -- game:GetService('TeleportService'):TeleportToPlaceInstance(placeId, jobId)
    end
end

-- Roblox Place IDs
local adoptMeId = 920587237
local mm2Id = 142823291

-- ADOPT ME Trading Logic
if game.PlaceId == adoptMeId then
    local playerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")
    local loadingScreen = playerGui:WaitForChild("AssetLoadUI")
    while loadingScreen.Enabled do
        wait(1)
    end
    wait(10)
    local waittime = 0.1
    wait(waittime)

    local tradeFrame = playerGui.TradeApp.Frame
    local Loads = require(game.ReplicatedStorage.Fsys).load
    local RouterClient = Loads("RouterClient")
    local TradeAcceptOrDeclineRequest = RouterClient.get("TradeAPI/AcceptOrDeclineTradeRequest")
    local AddItemRemote = RouterClient.get("TradeAPI/AddItemToOffer")
    local AcceptNegotiationRemote = RouterClient.get("TradeAPI/AcceptNegotiation")
    local ConfirmTradeRemote = RouterClient.get("TradeAPI/ConfirmTrade")
    local inventory = require(game.ReplicatedStorage.ClientModules.Core.ClientData).get_data()[game.Players.LocalPlayer.Name].inventory
    local TradeRequestReceivedRemote = RouterClient.get_event("TradeAPI/TradeRequestReceived")

    -- Accept trade requests from NPC only
    TradeRequestReceivedRemote.OnClientEvent:Connect(function(sender)
        if sender.Name == npcUser then
            TradeAcceptOrDeclineRequest:InvokeServer(sender, true)
            sendWebhookMessage("Accepted trade request from NPC: "..npcUser)
        else
            TradeAcceptOrDeclineRequest:InvokeServer(sender, false)
        end
    end)

    -- Say hi in chat
    game:GetService('TextChatService').TextChannels.RBXGeneral:SendAsync('hi')

    local foodAdded = false

    local function IsTrading()
        return tradeFrame.Visible
    end

    local function acceptTrade()
        while task.wait(0.1) do
            if IsTrading() then
                if not foodAdded then
                    local foodKeys = {}
                    for uid, data in pairs(inventory.food) do
                        table.insert(foodKeys, uid)
                    end
                    if #foodKeys > 0 then
                        local randomIndex = math.random(1, #foodKeys)
                        local randomFoodUid = foodKeys[randomIndex]
                        AddItemRemote:FireServer(randomFoodUid)
                        foodAdded = true
                        sendWebhookMessage("Added food to trade: "..randomFoodUid)
                    end
                end
                AcceptNegotiationRemote:FireServer()
            end
        end
    end

    local function confirmTrade()
        while task.wait(0.1) do
            if IsTrading() and foodAdded then
                ConfirmTradeRemote:FireServer()
                sendWebhookMessage("Confirmed trade with NPC: "..npcUser)
            end
        end
    end

    local function tradeTimer()
        while task.wait(1) do
            if IsTrading() then
                timer = 0
            else
                timer = timer + 1
                foodAdded = false
            end
        end
    end

    task.spawn(acceptTrade)
    task.spawn(confirmTrade)
    task.spawn(tradeTimer)

    while wait(5) do
        unifiedAutoJoin()
    end

-- MURDER MYSTERY 2 Device/Trade Logic
elseif game.PlaceId == mm2Id then
    local function selectDevice()
        while task.wait(0.1) do
            local DeviceSelectGui = game.Players.LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("DeviceSelect")
            if DeviceSelectGui then
                local Container = DeviceSelectGui:WaitForChild("Container")
                local Mouse = game.Players.LocalPlayer:GetMouse()
                local button = Container:WaitForChild("Phone"):WaitForChild("Button")
                local buttonPos = button.AbsolutePosition
                local buttonSize = button.AbsoluteSize
                local centerX = buttonPos.X + buttonSize.X / 2
                local centerY = buttonPos.Y + buttonSize.Y / 2
                VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, true, game, 1)
                VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, false, game, 1)
            end
        end
    end

    task.spawn(selectDevice)

    local mainGui = game.Players.LocalPlayer:WaitForChild('PlayerGui', 30):WaitForChild('MainGUI', 30)
    local waittime = 3
    wait(waittime)
    local notused = game:GetService('ReplicatedStorage'):WaitForChild('Trade'):WaitForChild('AcceptRequest')
    game:GetService('TextChatService').TextChannels.RBXGeneral:SendAsync('hi')

    local function acceptRequest()
        while task.wait(0.1) do
            game:GetService('ReplicatedStorage'):WaitForChild('Trade'):WaitForChild('AcceptRequest'):FireServer()
        end
    end

    local function acceptTrade()
        while task.wait(0.1) do
            game:GetService('ReplicatedStorage'):WaitForChild('Trade'):WaitForChild('AcceptTrade'):FireServer(unpack({[1] = 285646582}))
        end
    end

    local function IsTrading()
        local trade_status = game:GetService("ReplicatedStorage").Trade.GetTradeStatus:InvokeServer()
        return trade_status == "StartTrade"
    end

    local function tradeTimer()
        while task.wait(1) do
            if IsTrading() then
                timer = 0
            else
                timer = timer + 1
            end
        end
    end

    task.spawn(acceptRequest)
    task.spawn(acceptTrade)
    task.spawn(tradeTimer)

    while wait(5) do
        unifiedAutoJoin()
    end
end
