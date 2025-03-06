local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Notification = require(ReplicatedStorage.UI.Notification)
local PartyMenu = require(ReplicatedStorage.UI.PartyMenu)

local events = ReplicatedStorage:WaitForChild("Events") :: Folder
local sendInvite = events:WaitForChild("SendInvite") :: RemoteEvent

local PartyUIController = {}
local scope = Fusion:scoped({
	Notification = Notification,
	PartyMenu = PartyMenu,
})

local inviter = scope:Value(nil)
local isPartyCaptain = scope:Value(Players.LocalPlayer:GetAttribute("PartyCaptain") or false)
local inParty = scope:Value(Players.LocalPlayer:GetAttribute("Party") or nil)

scope:New("ScreenGui")({
	Name = "Main",
	Parent = Players.LocalPlayer.PlayerGui,

	[Fusion.Children] = {
		scope:PartyMenu({
			InParty = inParty,
			PartyCaptain = isPartyCaptain,
		}),

		scope:Notification({
			Inviter = inviter,
			Visible = scope:Computed(function(use)
				return use(inviter) ~= nil
			end),
		}),
	},
})

----- Connections

table.insert(
	scope,
	sendInvite.OnClientEvent:Connect(function(inviterPlayer: Player?)
		inviter:set(inviterPlayer)
	end)
)

table.insert(
	scope,
	Players.LocalPlayer:GetAttributeChangedSignal("PartyCaptain"):Connect(function()
		isPartyCaptain:set(Players.LocalPlayer:GetAttribute("PartyCaptain") or false)
	end)
)

table.insert(
	scope,
	Players.LocalPlayer:GetAttributeChangedSignal("Party"):Connect(function()
		inParty:set(Players.LocalPlayer:GetAttribute("Party") or nil)
	end)
)

return PartyUIController
