--!nocheck
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)

local controls = {
	Visible = true,
}

local story = {
	fusion = Fusion,
	controls = controls,
	story = function(props)
		local scope = props.scope

		local component = require(ReplicatedStorage.UI.Notification)(scope, {
			Inviter = { UserId = 3184111, CharacterAppearanceId = 3184111, DisplayName = "Papabos" },
			Visible = props.controls.Visible,
		})
		component.Parent = props.target
		-- cleanup function is not needed
	end,
}

return story
