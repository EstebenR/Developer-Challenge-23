--!nolint LocalShadow
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local OnyxUI = require(ReplicatedStorage.Packages["Onyx-ui"])
local Fusion = require(ReplicatedStorage.Packages.Fusion)

local Themer = OnyxUI.Themer
local Children, OnEvent = Fusion.Children, Fusion.OnEvent

local events = ReplicatedStorage:WaitForChild("Events") :: Folder
local sendInvite = events:WaitForChild("SendInvite") :: RemoteEvent
local createParty = events:WaitForChild("CreateParty") :: RemoteEvent

return function(
	scope: Fusion.Scope,
	props: {
		InParty: Fusion.UsedAs<string?>,
		PartyCaptain: Fusion.UsedAs<boolean>,
	}
)
	local scope = scope:innerScope(OnyxUI.Util, OnyxUI.Components)
	local theme = Themer.Theme:now()

	local players = scope:Value(table.freeze(Players:GetPlayers()))
	local function updatePlayers()
		players:set(table.freeze(Players:GetPlayers()))
	end
	table.insert(scope, Players.PlayerAdded:Connect(updatePlayers))
	table.insert(scope, Players.PlayerRemoving:Connect(updatePlayers))

	return scope:Card({
		Name = "Party Menu",
		AnchorPoint = Vector2.new(0, 0.5),
		Size = UDim2.fromOffset(200, 300),
		Position = UDim2.new(0, 10, 0.5),
		AutomaticSize = Enum.AutomaticSize.Y,

		ListEnabled = true,
		ListFillDirection = Enum.FillDirection.Vertical,
		ListSortOrder = Enum.SortOrder.LayoutOrder,
		ListHorizontalAlignment = Enum.HorizontalAlignment.Center,
		ListVerticalFlex = Enum.UIFlexAlignment.SpaceBetween,

		[Children] = {
			scope:Heading({
				LayoutOrder = 1,
				Text = "Party",
				TextWrapped = false,
				TextXAlignment = Enum.TextXAlignment.Center,
			}),

			scope:Scroller({
				LayoutOrder = 2,
				Size = UDim2.fromScale(1, 1),
				FlexMode = Enum.UIFlexMode.Fill,

				CanvasSize = UDim2.fromScale(1, 0.5),
				AutomaticCanvasSize = Enum.AutomaticSize.Y,

				ListEnabled = true,
				ListFillDirection = Enum.FillDirection.Vertical,
				ListSortOrder = Enum.SortOrder.LayoutOrder,
				ListPadding = UDim.new(0, 4),

				[Children] = {

					scope:ForValues(players, function(use, scope: Fusion.Scope, player: Player)
						local playerParty = scope:Value(player:GetAttribute("Party") or nil)
						table.insert(
							scope,
							player:GetAttributeChangedSignal("Party"):Connect(function()
								playerParty:set(player:GetAttribute("Party"))
							end)
						)

						local playerInv = scope:Value(player:GetAttribute("InvitedBy") or nil)
						table.insert(
							scope,
							player:GetAttributeChangedSignal("InvitedBy"):Connect(function()
								playerInv:set(player:GetAttribute("InvitedBy"))
							end)
						)

						local playerIsCaptain = scope:Value(player:GetAttribute("PartyCaptain"))
						table.insert(
							scope,
							player:GetAttributeChangedSignal("PartyCaptain"):Connect(function()
								playerIsCaptain:set(player:GetAttribute("PartyCaptain"))
							end)
						)

						local playerInvitedToOwnParty = scope:Computed(function(use)
							return use(props.InParty) == use(playerInv)
						end)

						return scope:Frame({
							Size = UDim2.fromScale(1, 1),
							BackgroundTransparency = 1,
							AspectRatio = 4,

							LayoutOrder = if player == Players.LocalPlayer then 0 else 1,

							ListEnabled = true,
							ListFillDirection = Enum.FillDirection.Horizontal,
							ListSortOrder = Enum.SortOrder.LayoutOrder,
							ListVerticalAlignment = Enum.VerticalAlignment.Center,
							ListPadding = UDim.new(0, 8),

							[Children] = {
								scope:Avatar({
									LayoutOrder = 1,
									Size = UDim2.fromScale(0.2, 0.8),
									Image = `rbxthumb://type=AvatarHeadShot&id={player.CharacterAppearanceId}&w=100&h=100`,
									AspectRatio = 1,
								}),

								scope:Text({
									LayoutOrder = 2,
									Text = player.DisplayName,
									TextWrapped = false,
									FlexMode = Enum.UIFlexMode.Fill,
								}),

								scope:New("ImageLabel")({
									Name = "Captain crown",
									LayoutOrder = 3,
									BackgroundTransparency = 1,
									Size = UDim2.fromScale(0.5, 0.5),

									Visible = scope:Computed(function(use)
										return use(props.InParty) == use(playerParty) and use(playerIsCaptain)
									end),

									Image = "rbxassetid://8445470189",
									ImageColor3 = theme.Colors.Warning.Light,
									ImageRectOffset = Vector2.new(704, 504),
									ImageRectSize = Vector2.new(96, 96),

									[Children] = {
										scope:New("UIAspectRatioConstraint")({}),
									},
								}),

								scope:New("ImageButton")({
									LayoutOrder = 3,
									Size = UDim2.fromScale(0.7, 0.7),
									BackgroundColor3 = theme.Colors.Primary.Main,

									Visible = scope:Computed(function(use)
										return use(props.PartyCaptain)
											and not use(playerParty)
											and (not use(playerInv) or use(playerInvitedToOwnParty))
									end),

									Image = scope:Computed(function(use)
										return if use(playerInvitedToOwnParty)
											then "rbxassetid://8445471173"
											else "rbxassetid://8445470984"
									end),
									ImageRectOffset = scope:Computed(function(use)
										return if use(playerInvitedToOwnParty)
											then Vector2.new(504, 604)
											else Vector2.new(804, 704)
									end),
									ImageRectSize = scope:Computed(function(use)
										return if use(playerInvitedToOwnParty)
											then Vector2.new(96, 96)
											else Vector2.new(96, 96)
									end),
									ScaleType = Enum.ScaleType.Stretch,

									[OnEvent("Activated")] = function()
										if not Fusion.peek(playerInv) then
											sendInvite:FireServer(player)
										end
									end,

									[Children] = {
										scope:New("UIAspectRatioConstraint")({}),

										scope:New("UICorner")({
											CornerRadius = UDim.new(0, 4),
										}),
									},
								}),
							},
						})
					end),
				},
			}),

			scope:Button({
				LayoutOrder = 10,
				Content = { "Create Party" },
				BackgroundColor3 = theme.Colors.Primary.Main,
				StrokeColor = theme.Colors.Primary.Dark,
				Visible = scope:Computed(function(use)
					return use(props.InParty) == nil
				end),

				OnActivated = function()
					createParty:FireServer(true)
				end,
			}),

			scope:Button({
				LayoutOrder = 10,
				Content = { "Disband Party" },
				BackgroundColor3 = theme.Colors.Error.Main,
				StrokeColor = theme.Colors.Error.Dark,
				Visible = scope:Computed(function(use)
					return use(props.InParty) ~= nil and use(props.PartyCaptain)
				end),

				OnActivated = function()
					createParty:FireServer(false)
				end,
			}),
		},
	})
end
