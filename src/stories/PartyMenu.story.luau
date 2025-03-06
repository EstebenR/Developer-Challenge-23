--!nocheck
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)

local controls = {
	InParty = true,
	PartyLeader = true,
}

local story = {
	fusion = Fusion,
	controls = controls,
	story = function(props)
		local scope = props.scope

		local component = require(ReplicatedStorage.UI.PartyMenu)(scope, {
			Inviter = { UserId = 3184111, DisplayName = "Papabos" },
			InParty = props.controls.InParty,
			PartyLeader = props.controls.PartyLeader,
		})
		component.Parent = props.target
		-- cleanup function is not needed
	end,
}

return story
