local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

-- URL สำหรับดึงข้อมูล Mirage
local serverUrl = "http://223.205.204.154:5000/Mirage"

local mirageExists = false -- ตัวแปรสถานะ Mirage
local attemptedServers = {} -- เก็บ jobid ที่ลองเข้าแล้วในรอบนี้

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

-- ฟังก์ชันสำหรับการดึงข้อมูลจาก API
local function getLatestMessagesFromServer(url)
    local success, response = pcall(function()
        return game:HttpGet(url)
    end)

    if success and response then
        local data = HttpService:JSONDecode(response)
        if data then
            return data
        else
            warn("ไม่พบข้อมูลในโหนด Mirage")
            return nil
        end
    else
        warn("ไม่สามารถดึงข้อมูลจากเซิร์ฟเวอร์ได้")
        return nil
    end
end

-- ฟังก์ชันสำหรับตรวจสอบว่า jobid ถูกลองแล้วหรือไม่
local function isJobIdAttempted(jobid)
    for _, attempted in pairs(attemptedServers) do
        if attempted == jobid then
            return true -- jobid นี้เคยลองเข้าแล้ว
        end
    end
    return false
end

-- ฟังก์ชันสำหรับไล่เข้าเซิร์ฟเวอร์ทั้งหมด
local function processAllServers(nodes)
    for _, node in ipairs(nodes) do
        if node.jobid and not isJobIdAttempted(node.jobid) then
            print("กำลังลองเข้าเซิร์ฟเวอร์: " .. node.jobid)
            local success, errorMessage = pcall(function()
                TeleportService:TeleportToPlaceInstance(game.PlaceId, node.jobid, Players.LocalPlayer)
            end)
            if not success then
                print("ไม่สามารถเข้าเซิร์ฟเวอร์: " .. node.jobid .. " ได้ (" .. errorMessage .. ")")
            end
            table.insert(attemptedServers, node.jobid) -- บันทึกว่าเคยลองเข้าแล้ว
            wait(2) -- รอ 2 วินาทีก่อนลองเซิร์ฟเวอร์ถัดไป
        end
    end
end

-- ฟังก์ชันหลักสำหรับดึงข้อมูลและไล่เข้าเซิร์ฟเวอร์
local function fetchAndProcessServers()
    local latestMessages = getLatestMessagesFromServer(serverUrl)

    if latestMessages then
        processAllServers(latestMessages)
    else
        warn("ไม่พบข้อมูลเซิร์ฟเวอร์หรือไม่สามารถดึงข้อมูลได้")
    end

    -- เคลียร์รายการ attemptedServers เพื่อเตรียมสำหรับรอบใหม่
    attemptedServers = {}
end

-- ฟังก์ชันสำหรับตรวจสอบ Mirage Island
local function checkMirageIsland()
    local mirageIsland = game:GetService("Workspace")["_WorldOrigin"].Locations:FindFirstChild("Mirage Island")
    if mirageIsland then
        mirageExists = true -- ตั้งสถานะว่า Mirage มีอยู่
        statusLabel.Text = "Mirage : 🟢"
    else
        mirageExists = false -- ตั้งสถานะว่า Mirage ไม่มี
        statusLabel.Text = "Mirage : 🔴"
    end
end

-- ตรวจสอบ PlaceId ก่อนเริ่มฟังก์ชันหลัก
while true do
    if game.PlaceId == 7449423635 then
        break
    else
        wait(1)
        game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("TravelZou")
    end
end

-- ลูปสำหรับการตรวจสอบ Mirage Island ทุกๆ 1 วินาที
coroutine.wrap(function()
    while true do
        checkMirageIsland()
        wait(1)
    end
end)()

-- ลูปสำหรับการตรวจสอบและย้ายเซิร์ฟเวอร์
coroutine.wrap(function()
    while true do
        if not mirageExists then -- ตรวจสอบว่า Mirage ไม่มีอยู่
            fetchAndProcessServers()
        else
            print("Mirage Island มีอยู่ ไม่ตรวจสอบเซิร์ฟเวอร์ใหม่")
        end
        wait(0.3) -- รอ 0.3 วินาทีก่อนตรวจสอบอีกครั้ง
    end
end)()
