local ReplicatedStorage = game:GetService("ReplicatedStorage")

local events = ReplicatedStorage:WaitForChild("Events") :: Folder
local inviteResponse = events:WaitForChild("InviteResponse") :: RemoteEvent
local sendInvite = events:WaitForChild("SendInvite") :: RemoteEvent
local createParty = events:WaitForChild("CreateParty") :: RemoteEvent

local MAX_PARTY_SIZE = 2

local PartyHandler = {}
local nextPartyId = 1
local parties: { [string]: { Captain: Player, Members: { Player }, Invites: { Player } } } = {}
local invitees: { [Player]: string } = {}

local function cancelInvites(id: string)
	local party = parties[id]
	if not party then
		return
	end

	for _, invitee in party.Invites do
		invitees[invitee] = nil
		sendInvite:FireClient(invitee, nil)
		invitee:SetAttribute("InvitedBy", nil)
	end

	table.clear(party.Invites)
end

local function disbandParty(id: string)
	local party = parties[id]
	if not party then
		return
	end

	--Remove attribute from every member
	for _, member in party.Members do
		member:SetAttribute("Party", nil)
	end
	party.Captain:SetAttribute("Party", nil)
	party.Captain:SetAttribute("PartyCaptain", nil)

	cancelInvites(id)

	parties[id] = nil
end

local function onInviteResponse(player: Player, answer: boolean)
	if answer == nil or typeof(answer) ~= "boolean" then
		warn("Malformed InviteResponse")
		return
	end

	local inviteId = invitees[player]
	if not inviteId then
		return
	end

	local party = parties[inviteId]

	if answer then
		--Add player to party
		table.insert(party.Members, player)
		player:SetAttribute("Party", inviteId)
	end

	--Update state
	table.remove(party.Invites, table.find(party.Invites, player))
	invitees[player] = nil
	sendInvite:FireClient(player, nil)
	player:SetAttribute("InvitedBy", nil)

	--If party is full cancel remaining invites invites
	if #party.Members + 1 == MAX_PARTY_SIZE then
		cancelInvites(inviteId)
	end
end

local function onSendInvite(player: Player, targetPlayer: Player)
	print(targetPlayer)
	if not targetPlayer or not targetPlayer:IsA("Player") then
		warn("Malformed SendInvite")
		return
	end

	local inviterPartyId = player:GetAttribute("Party") :: string?
	if not inviterPartyId then
		print("Inviter has no party")
		return
	end

	local party = parties[inviterPartyId]
	if party.Captain ~= player then
		print("Only captain can invite others")
		return
	end

	if #party.Members + 1 == MAX_PARTY_SIZE then
		print("Max party size reached")
		return
	end

	local targetPartyId = targetPlayer:GetAttribute("Party") :: string?
	if targetPartyId then
		print(`Target player {targetPlayer.DisplayName} is already in a party`)
		return
	end

	if invitees[targetPlayer] then
		print(`Target player {targetPlayer.DisplayName} has already been invited`)
		return
	end

	invitees[targetPlayer] = inviterPartyId
	table.insert(party.Invites, targetPlayer)
	targetPlayer:SetAttribute("InvitedBy", inviterPartyId)
	sendInvite:FireClient(targetPlayer, player)
end

local function onCreateParty(player: Player, create: boolean)
	if create == nil or typeof(create) ~= "boolean" then
		warn("Malformed CreateParty")
		return
	end

	--If player not in party allow them to create one
	local partyId = player:GetAttribute("Party") :: string?
	if create and not partyId then
		local id = tostring(nextPartyId)
		nextPartyId += 1

		--Setup party and invites tracking
		parties[id] = { Captain = player, Members = {}, Invites = {} }

		player:SetAttribute("Party", id)
		player:SetAttribute("PartyCaptain", true)
	elseif not create and partyId and parties[partyId].Captain == player then
		print("Disbanding")
		--Attempting to disband
		disbandParty(partyId)
	end
end

----- Connections

inviteResponse.OnServerEvent:Connect(onInviteResponse)
sendInvite.OnServerEvent:Connect(onSendInvite)
createParty.OnServerEvent:Connect(onCreateParty)

return PartyHandler
