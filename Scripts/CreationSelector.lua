
CreationSelector = class()
CreationSelector.maxParentCount = 0
CreationSelector.maxChildCount = 1
CreationSelector.connectionInput = sm.interactable.connectionType.none
CreationSelector.connectionOutput = 4096
CreationSelector.poseWeightCount = 1
CreationSelector.colorHighlight = sm.color.new( "#a12525" )
CreationSelector.colorNormal = sm.color.new( "#910d0d" )

function CreationSelector.server_onCreate( self )
	self.saved = self.storage:load()
	if self.saved == nil then
		self.saved = { distance = 5, creation = nil }
	end

	self:server_Save()
end

function CreationSelector.client_onFixedUpdate( self, dt )
	local pos = self.shape:getWorldPosition()
	local npos = (self.shape:getWorldRotation() * sm.vec3.new(0,0,2)) + pos
	local valid, result = sm.physics.raycast(self.shape:getWorldPosition(), npos )
	if valid == true and result.type == "body" then
		if result:getBody():isDynamic() then
			self.interactable:setPoseWeight( 0, 1 )
		end
	else
		self.interactable:setPoseWeight( 0, 0 )
	end
end

function CreationSelector.client_onInteract( self, character, state )
	if state == true then
		pos = self.shape:getWorldPosition()
		npos = (self.shape:getWorldRotation() * sm.vec3.new(0,0,2)) + pos
		valid, result = sm.physics.raycast(self.shape:getWorldPosition(), npos )
		if valid == true and result.type == "body" then
			body = result:getBody()
			if body:isDynamic() then
				self.network:sendToServer("server_SaveBody", body)
			end
		end
	end
end


function CreationSelector.server_Save( self )
	self.storage:save( self.saved )
	self.interactable:setPublicData( self.saved )
end

function CreationSelector.server_SaveBody(self, creation)
	local string = sm.creation.exportToString(creation, true, true)
	local shapes = creation:getCreationShapes()
	for i=1,#shapes do
		shapes[i]:destroyShape(0)
	end
	self.saved.creationString = string
	self:server_Save()
end