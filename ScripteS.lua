local Notification = loadstring(game:HttpGet("https://api.irisapp.ca/Scripts/IrisBetterNotifications.lua"))()

local games = {
    [9292879820] = "https://raw.githubusercontent.com/Bolox102911/ScripteS/refs/heads/main/scripts/GrassCutting.lua"
}

local foundGame = false

for id, url in pairs(games) do
    if game.PlaceId == id then
        foundGame = true
        Notification.Notify("ScripteS Hub", "Loading ...", "rbxassetid://4483345998")
        loadstring(game:HttpGet(url))()
        break
    end
end

if not foundGame then
    local currentPlaceId = game.PlaceId
    Notification.Notify("ScripteS Hub", "Wrong game. Your current game ID is: " .. tostring(currentPlaceId), "rbxassetid://4483345998")
end
