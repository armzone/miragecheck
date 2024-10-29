local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

-- URL ของ Firebase ที่เก็บข้อมูลล่าสุด
local serverUrl = "https://jobid-1e3dc-default-rtdb.asia-southeast1.firebasedatabase.app/All-mirage/Mirage.json"

-- สร้าง ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

-- สร้าง TextLabel สำหรับแสดงสถานะของ Mirage Island
local statusLabel = Instance.new("TextLabel")
statusLabel.Parent = screenGui
statusLabel.Size = UDim2.new(0, 200, 0, 50)
statusLabel.Position = UDim2.new(0, 10, 0, 10)
statusLabel.BackgroundColor3 = Color3.new(0.8, 0.8, 0.8)
statusLabel.TextColor3 = Color3.new(0, 0, 0)
statusLabel.Font = Enum.Font.SourceSansBold
statusLabel.TextSize = 24
statusLabel.Text = "Mirage : 🔴"
statusLabel.BackgroundTransparency = 0.3

-- เพิ่ม UICorner เพื่อทำให้พื้นหลังมีขอบโค้งมน
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = statusLabel

-- ฟังก์ชันสำหรับการดึงข้อมูลจาก Firebase
local function getLatestMessagesFromFirebase(url)
    local response = game:HttpGet(url)
    if response then
        local data = HttpService:JSONDecode(response)
        if data then
            return data
        else
            warn("ไม่พบข้อมูลในโหนด Mirage")
            return nil
        end
    else
        warn("ไม่สามารถดึงข้อมูลจาก Firebase ได้")
        return nil
    end
end

-- ฟังก์ชันสำหรับตรวจสอบเวลาให้อยู่ระหว่าง 13:00 ถึง 02:00
local function isTimeInRange(timeStr)
    local hour, minute = timeStr:match("(%d+):(%d+)")
    hour = tonumber(hour)
    minute = tonumber(minute)

    if (hour >= 13 and hour < 24) or (hour >= 0 and hour < 2) then
        return true
    else
        return false
    end
end

-- ฟังก์ชันสำหรับสุ่มเลือกโหนดที่มี players น้อยกว่า 12 และเวลาตรงตามเงื่อนไข
local function selectRandomNode(nodes)
    local validNodes = {}

    for _, node in pairs(nodes) do
        if node.player_in_server and node.time then
            local playersCount = tonumber(node.player_in_server:match("^(%d+)/%d+"))
            if playersCount and playersCount < 12 and isTimeInRange(node.time) then
                table.insert(validNodes, node)
            end
        end
    end

    if #validNodes > 0 then
        local randomIndex = math.random(1, #validNodes)
        return validNodes[randomIndex]
    else
        return nil
    end
end

-- ฟังก์ชันหลักสำหรับตรวจสอบและเทเลพอร์ต
local function checkForBestNodeAndTeleport()
    local latestMessages = getLatestMessagesFromFirebase(serverUrl)

    if latestMessages then
        local selectedNode = selectRandomNode(latestMessages)

        if selectedNode and selectedNode.jobid then
            local player = Players.LocalPlayer
            TeleportService:TeleportToPlaceInstance(game.PlaceId, selectedNode.jobid, player)
        else
            print("ไม่พบเซิร์ฟเวอร์ที่ตรงตามเงื่อนไข, กำลังรอ 10 วินาทีก่อนตรวจสอบอีกครั้ง...")
            wait(10)
        end
    else
        warn("ไม่พบข้อมูลจาก Firebase หรือไม่สามารถดึงข้อมูลได้")
        wait(10)
    end
end

-- ฟังก์ชันสำหรับตรวจสอบ Mirage Island
local function checkMirageIsland()
    local mirageIsland = game:GetService("Workspace")["_WorldOrigin"].Locations:FindFirstChild("Mirage Island")
    if mirageIsland then
        statusLabel.Text = "Mirage : 🟢"
        mirageIsland.AncestryChanged:Wait()
        checkForBestNodeAndTeleport()
    else
        statusLabel.Text = "Mirage : 🔴"
        checkForBestNodeAndTeleport()
    end
end

-- ตรวจสอบ PlaceId ก่อนเริ่มฟังก์ชันหลัก
while true do
    if game.PlaceId == 7449423635 then
        break
    else
        wait(20)
        game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("TravelZou")
    end
end

-- เริ่มต้นการตรวจสอบ Mirage Island
checkMirageIsland()

-- ติดตามการเปลี่ยนแปลงของ Mirage Island
RunService.Heartbeat:Connect(checkMirageIsland)
