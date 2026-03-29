local Players = game:GetService("Players")
local lp = Players.LocalPlayer
local PlayerGui = lp:WaitForChild("PlayerGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- === CONFIGURATION ===
local ROBUX_LOGO_ID = "rbxassetid://11781210028"
local currentBalance = 208937198

local TARGET_ITEMS = {
    ["Korblox Deathspeaker"] = { Price = 17000, PriceStr = "17,000", Image = "rbxthumb://type=Asset&id=9240340386&w=420&h=420" },
    ["Poisoned Horns of the Toxic Wasteland"] = { Price = 2000000, PriceStr = "2,000,000", Image = "rbxthumb://type=Asset&id=15208730134&w=420&h=420" },
    ["Violet Valkyrie"] = { Price = 50000, PriceStr = "50,000", Image = "rbxthumb://type=Asset&id=83829157033334&w=420&h=420" },
    ["Super Super Happy Face"] = { Price = 280000, PriceStr = "280,000", Image = "rbxthumb://type=Asset&id=494290547&w=420&h=420" }
}

-- === UI SETUP ===
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "GiftingSystem_Final_V12"
ScreenGui.ResetOnSpawn = false
ScreenGui.Enabled = false
ScreenGui.DisplayOrder = 9999
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = PlayerGui

local Overlay = Instance.new("Frame", ScreenGui)
Overlay.Name = "Overlay"
Overlay.Size = UDim2.new(1, 0, 1, 0)
Overlay.BackgroundColor3 = Color3.new(0, 0, 0)
Overlay.BackgroundTransparency = 0.5
Overlay.BorderSizePixel = 0

local currentItemData = nil
local selectedName = ""

-- === HELPER FUNCTIONS ===
local function makeDraggable(frame)
    local dragging, dragInput, dragStart, startPos
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true dragStart = input.Position startPos = frame.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

local function addCloseButton(parent)
    local close = Instance.new("TextButton", parent)
    close.Name = "CloseBtn"; close.Size = UDim2.new(0, 30, 0, 30); close.Position = UDim2.new(1, -35, 0, 5)
    close.BackgroundTransparency = 1; close.Text = "X"; close.TextColor3 = Color3.new(1, 1, 1)
    close.Font = Enum.Font.GothamBold; close.TextSize = 20; close.ZIndex = 100
    close.MouseButton1Click:Connect(function() 
        parent.Visible = false
        ScreenGui.Enabled = false 
    end)
end

local function createFrame(name, size, pos)
    local f = Instance.new("Frame", ScreenGui)
    f.Name = name; f.Size = size; f.Position = pos; f.BackgroundColor3 = Color3.fromRGB(30, 31, 33); f.BorderSizePixel = 0; f.Visible = false; f.Active = true
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 12)
    Instance.new("UIStroke", f).Color = Color3.fromRGB(60, 61, 63)
    addCloseButton(f)
    makeDraggable(f)
    return f
end

-- === 1. SEARCH GUI ===
local SearchFrame = createFrame("SearchFrame", UDim2.new(0, 340, 0, 420), UDim2.new(0.5, -170, 0.5, -210))
local AvatarBg = Instance.new("Frame", SearchFrame); AvatarBg.Size = UDim2.new(0, 140, 0, 140); AvatarBg.Position = UDim2.new(0.5, -70, 0.1, 0); AvatarBg.BackgroundColor3 = Color3.fromRGB(40, 41, 43); Instance.new("UICorner", AvatarBg).CornerRadius = UDim.new(1, 0)
local AvatarPreview = Instance.new("ImageLabel", AvatarBg); AvatarPreview.Size = UDim2.new(0.8, 0, 0.8, 0); AvatarPreview.Position = UDim2.new(0.1, 0, 0.1, 0); AvatarPreview.BackgroundTransparency = 1; AvatarPreview.Image = "rbxassetid://15617260842"
local UserTagLabel = Instance.new("TextLabel", SearchFrame); UserTagLabel.Size = UDim2.new(0.9, 0, 0, 30); UserTagLabel.Position = UDim2.new(0.05, 0, 0.5, 0); UserTagLabel.BackgroundTransparency = 1; UserTagLabel.TextColor3 = Color3.new(1, 1, 1); UserTagLabel.Font = Enum.Font.GothamBold; UserTagLabel.TextSize = 20; UserTagLabel.Text = "Search User"
local SearchBar = Instance.new("TextBox", SearchFrame); SearchBar.Size = UDim2.new(0.8, 0, 0, 40); SearchBar.Position = UDim2.new(0.1, 0, 0.65, 0); SearchBar.PlaceholderText = "Username..."; SearchBar.BackgroundColor3 = Color3.fromRGB(45, 46, 48); SearchBar.TextColor3 = Color3.new(1, 1, 1); SearchBar.Font = Enum.Font.Gotham; Instance.new("UICorner", SearchBar)
local ConfirmBtn = Instance.new("TextButton", SearchFrame); ConfirmBtn.Size = UDim2.new(0.8, 0, 0, 45); ConfirmBtn.Position = UDim2.new(0.1, 0, 0.8, 0); ConfirmBtn.BackgroundColor3 = Color3.fromRGB(0, 140, 255); ConfirmBtn.Text = "SELECT RECIPIENT"; ConfirmBtn.TextColor3 = Color3.new(1, 1, 1); ConfirmBtn.Font = Enum.Font.GothamBold; Instance.new("UICorner", ConfirmBtn)

-- === 2. PROMPT GUI ===
local PromptFrame = createFrame("PromptFrame", UDim2.new(0, 420, 0, 240), UDim2.new(0.5, -210, 0.5, -120))
local ItemIcon = Instance.new("ImageLabel", PromptFrame); ItemIcon.Size = UDim2.new(0, 90, 0, 90); ItemIcon.Position = UDim2.new(0.06, 0, 0.2, 0); ItemIcon.BackgroundTransparency = 1; ItemIcon.ZIndex = 15

local BalCon = Instance.new("Frame", PromptFrame); BalCon.Size = UDim2.new(0, 180, 0, 30); BalCon.Position = UDim2.new(1, -190, 0, 10); BalCon.BackgroundTransparency = 1
local BalIcon = Instance.new("ImageLabel", BalCon); BalIcon.Size = UDim2.new(0, 20, 0, 20); BalIcon.Position = UDim2.new(1, -22, 0.5, -10); BalIcon.BackgroundTransparency = 1; BalIcon.Image = ROBUX_LOGO_ID
local BalLabel = Instance.new("TextLabel", BalCon); BalLabel.Size = UDim2.new(1, -25, 1, 0); BalLabel.Position = UDim2.new(0, 0, 0, 0); BalLabel.BackgroundTransparency = 1; BalLabel.TextColor3 = Color3.new(1, 1, 1); BalLabel.Font = Enum.Font.GothamBold; BalLabel.TextSize = 14; BalLabel.TextXAlignment = Enum.TextXAlignment.Right

local ItemNameLabel = Instance.new("TextLabel", PromptFrame); ItemNameLabel.Position = UDim2.new(0.35, 0, 0.2, 0); ItemNameLabel.Size = UDim2.new(0.6, 0, 0, 25); ItemNameLabel.BackgroundTransparency = 1; ItemNameLabel.TextColor3 = Color3.new(1, 1, 1); ItemNameLabel.Font = Enum.Font.GothamBold; ItemNameLabel.TextSize = 18; ItemNameLabel.TextXAlignment = Enum.TextXAlignment.Left; ItemNameLabel.TextTruncate = Enum.TextTruncate.AtEnd
local PriceCon = Instance.new("Frame", PromptFrame); PriceCon.Size = UDim2.new(0, 200, 0, 25); PriceCon.Position = UDim2.new(0.35, 0, 0.35, 0); PriceCon.BackgroundTransparency = 1
local PriceIcon = Instance.new("ImageLabel", PriceCon); PriceIcon.Size = UDim2.new(0, 18, 0, 18); PriceIcon.Position = UDim2.new(0, 0, 0.5, -9); PriceIcon.BackgroundTransparency = 1; PriceIcon.Image = ROBUX_LOGO_ID
local PriceLabel = Instance.new("TextLabel", PriceCon); PriceLabel.Position = UDim2.new(0, 22, 0, 0); PriceLabel.Size = UDim2.new(1, -22, 1, 0); PriceLabel.BackgroundTransparency = 1; PriceLabel.TextColor3 = Color3.fromRGB(0, 255, 127); PriceLabel.Font = Enum.Font.GothamBold; PriceLabel.TextSize = 16; PriceLabel.TextXAlignment = Enum.TextXAlignment.Left

local BuyBtnBar = Instance.new("Frame", PromptFrame); BuyBtnBar.Size = UDim2.new(0.9, 0, 0, 50); BuyBtnBar.Position = UDim2.new(0.05, 0, 0.65, 0); BuyBtnBar.BackgroundColor3 = Color3.fromRGB(45, 46, 48); Instance.new("UICorner", BuyBtnBar)
local ProgressFill = Instance.new("Frame", BuyBtnBar); ProgressFill.Size = UDim2.new(0, 0, 1, 0); ProgressFill.BackgroundColor3 = Color3.fromRGB(0, 140, 255); Instance.new("UICorner", ProgressFill)
local BuyBtnText = Instance.new("TextButton", BuyBtnBar); BuyBtnText.Size = UDim2.new(1, 0, 1, 0); BuyBtnText.BackgroundTransparency = 1; BuyBtnText.Text = "Processing..."; BuyBtnText.TextColor3 = Color3.new(1, 1, 1); BuyBtnText.Font = Enum.Font.GothamBold; BuyBtnText.ZIndex = 20

-- === Success Frame ===
local SuccessFrame = createFrame("SuccessFrame", UDim2.new(0, 300, 0, 120), UDim2.new(0.5, -150, 0.5, -60))
local SuccessLabel = Instance.new("TextLabel", SuccessFrame); SuccessLabel.Size = UDim2.new(1, 0, 1, 0); SuccessLabel.BackgroundTransparency = 1; SuccessLabel.TextColor3 = Color3.new(1, 1, 1); SuccessLabel.Font = Enum.Font.GothamBold; SuccessLabel.TextSize = 18; SuccessLabel.Text = "GIFT SENT SUCCESSFULLY!"

-- === LOGIC ===
local function updateBalance()
    BalLabel.Text = tostring(currentBalance):reverse():gsub("%d%d%d", "%1,"):reverse():gsub("^,", "")
end
updateBalance()

SearchBar.FocusLost:Connect(function()
    local success, userId = pcall(function() return Players:GetUserIdFromNameAsync(SearchBar.Text) end)
    if success and userId then
        selectedName = SearchBar.Text
        AvatarPreview.Image = Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.AvatarThumbnail, Enum.ThumbnailSize.Size420x420)
        UserTagLabel.Text = selectedName
    end
end)

ConfirmBtn.MouseButton1Click:Connect(function()
    if selectedName ~= "" then
        SearchFrame.Visible = false; PromptFrame.Visible = true
        ProgressFill.Size = UDim2.new(0,0,1,0); BuyBtnText.Text = "Wait..."
        local t = TweenService:Create(ProgressFill, TweenInfo.new(1.5, Enum.EasingStyle.Linear), {Size = UDim2.new(1,0,1,0)})
        t:Play()
        t.Completed:Connect(function() BuyBtnText.Text = "GIFT" end)
    end
end)

BuyBtnText.MouseButton1Click:Connect(function()
    if BuyBtnText.Text == "GIFT" and currentItemData then
        currentBalance = currentBalance - currentItemData.Price
        updateBalance()
        PromptFrame.Visible = false
        SuccessFrame.Visible = true
        task.wait(2)
        SuccessFrame.Visible = false
        ScreenGui.Enabled = false
    end
end)

-- === CATALOG LOOP ===
task.spawn(function()
    while true do
        task.wait(0.5)
        local list = PlayerGui:FindFirstChild("MainCatalogDisplayList", true) or PlayerGui:FindFirstChild("ScrollingFrame", true)
        if list then
            for _, item in pairs(list:GetChildren()) do
                local data = TARGET_ITEMS[item.Name]
                if data then
                    local buyBtn = item:FindFirstChild("Buy", true) or item:FindFirstChild("BuyButton", true) or item:FindFirstChildOfClass("TextButton", true)
                    if buyBtn and not buyBtn:FindFirstChild("GiftTrigger") then
                        local trigger = Instance.new("TextButton", buyBtn)
                        trigger.Name = "GiftTrigger"; trigger.Size = UDim2.new(1, 0, 1, 0); trigger.BackgroundTransparency = 0; trigger.BackgroundColor3 = Color3.fromRGB(0, 140, 255)
                        trigger.Text = "GIFT"; trigger.TextColor3 = Color3.new(1,1,1); trigger.Font = Enum.Font.GothamBold; trigger.ZIndex = 999
                        Instance.new("UICorner", trigger)
                        
                        trigger.MouseButton1Click:Connect(function()
                            currentItemData = data
                            ItemNameLabel.Text = item.Name
                            ItemIcon.Image = data.Image
                            PriceLabel.Text = data.PriceStr
                            ScreenGui.Enabled = true; SearchFrame.Visible = true; PromptFrame.Visible = false
                        end)
                    end
                end
            end
        end
    end
end)
