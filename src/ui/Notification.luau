--!nolint LocalShadow
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local OnyxUI = require(ReplicatedStorage.Packages["Onyx-ui"])
local Fusion = require(ReplicatedStorage.Packages.Fusion)

local Themer = OnyxUI.Themer
local Children = Fusion.Children

local events = ReplicatedStorage:WaitForChild("Events") :: Folder
local inviteResponse = events:WaitForChild("InviteResponse") :: RemoteEvent

return function(
	scope: Fusion.Scope,
	props: {
		Inviter: Fusion.UsedAs<Player?>,
		Visible: Fusion.UsedAs<boolean>,
	}
)
	local scope = scope:innerScope(OnyxUI.Util, OnyxUI.Components)
	local theme = Themer.Theme:now()

	local transpSring = scope:Spring(
		scope:Computed(function(use)
			return if use(props.Visible) then 0 else 1
		end),
		30
	)

	local posSpring = scope:Spring(scope:Value(UDim2.fromScale(0.5, 0.1)), 30)

	scope:Observer(props.Visible):onChange(function()
		posSpring:setVelocity(UDim2.fromScale(0, 2))
	end)

	return scope:MenuFrame({
		Name = "Notification",
		AnchorPoint = Vector2.new(0.5, 0),
		Size = UDim2.fromOffset(250, 175),
		Position = posSpring,
		AutomaticSize = Enum.AutomaticSize.None,

		GroupTransparency = transpSring,
		StrokeTransparency = transpSring,
		BackgroundColor3 = theme.Colors.Base.Main,
		StrokeColor = theme.Colors.Primary.Main,

		ListEnabled = true,
		ListFillDirection = Enum.FillDirection.Vertical,
		ListSortOrder = Enum.SortOrder.LayoutOrder,
		ListHorizontalAlignment = Enum.HorizontalAlignment.Center,

		[Children] = {
			scope:TitleBar({
				Content = { "Party Invite!" },
				LayoutOrder = 0,

				OnClose = function()
					inviteResponse:FireServer(false)
				end,
			}),
			scope:Frame({
				Size = UDim2.fromScale(1, 1),
				AutomaticSize = Enum.AutomaticSize.None,
				FlexMode = Enum.UIFlexMode.Shrink,
				LayoutOrder = 1,

				ListEnabled = true,
				ListFillDirection = Enum.FillDirection.Horizontal,
				ListSortOrder = Enum.SortOrder.LayoutOrder,
				ListVerticalAlignment = Enum.VerticalAlignment.Center,

				[Children] = {

					scope:Avatar({
						Size = UDim2.fromScale(0.3, 1),
						AspectRatio = 1,
						Image = scope:Computed(function(use)
							local plr = use(props.Inviter)
							if plr then
								return `rbxthumb://type=AvatarHeadShot&id={use(props.Inviter).CharacterAppearanceId}&w=100&h=100`
							else
								return ""
							end
						end),
					}),

					scope:Text({
						Size = UDim2.fromScale(0.6, 0.8),
						FlexMode = Enum.UIFlexMode.Fill,

						TextScaled = true,
						AutomaticSize = Enum.AutomaticSize.None,
						Text = scope:Computed(function(use)
							local plr = use(props.Inviter)
							if plr then
								return `{plr.DisplayName} would like you to join their party!`
							else
								return "No pending invite"
							end
						end),
						TextYAlignment = Enum.TextYAlignment.Center,
					}),
				},
			}),
			scope:Frame({
				Name = "Buttons",
				Size = UDim2.fromScale(1, 0.3),
				AutomaticSize = Enum.AutomaticSize.Y,
				LayoutOrder = 3,

				ListEnabled = true,
				ListFillDirection = Enum.FillDirection.Horizontal,
				ListHorizontalFlex = Enum.UIFlexAlignment.SpaceEvenly,

				[Children] = {
					scope:Button({
						Content = { "Accept" },
						BackgroundColor3 = theme.Colors.Success.Main,
						StrokeColor = theme.Colors.Success.Dark,

						OnActivated = function()
							inviteResponse:FireServer(true)
						end,
					}),

					scope:Button({
						Content = { "Cancel" },
						BackgroundColor3 = theme.Colors.Error.Main,
						StrokeColor = theme.Colors.Error.Dark,

						OnActivated = function()
							inviteResponse:FireServer(false)
						end,
					}),
				},
			}),
		},
	})
end
