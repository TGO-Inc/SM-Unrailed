TrackBuilder = class()
TrackBuilder.maxParentCount = 10
TrackBuilder.maxChildCount = 0
TrackBuilder.connectionInput = 4096
TrackBuilder.connectionOutput = sm.interactable.connectionType.none
TrackBuilder.colorNormal = sm.color.new("#8b00a1")
TrackBuilder.colorHighlight = sm.color.new("#a226b5")

function TrackBuilder.client_onCreate( self, dt )
    self.offset = sm.vec3.new(0,0,0)
    self.selected_index = 1
    self.gui = sm.gui.createSeatGui()
    self.overlay = sm.gui.createGuiFromLayout("$CONTENT_DATA/Gui/Layouts/controls.layout", false, {isHud = true, isInteractive = false, needsCursor = false})
    self:client_initialize()
end

function TrackBuilder.client_initialize(self)
    self.active_character = nil
    self.visual_rotation = nil
    self.visual_position = nil
    self.WisOn = false
	self.AisOn = false
	self.SisOn = false
	self.DisOn = false
    self.LeftCliclisOn = false
    self.MoveTicker = 0
    self.reset_lock = false
    self.rotation_index = 0
    self.random_rotation = false
    self.visual_offset = sm.vec3.zero()
end

function TrackBuilder.client_onFixedUpdate( self, dt )
    if self.past_connetion_count ~= #self.interactable:getChildren() + #self.interactable:getParents() then
        self:client_updateVisualIndex()
        self.past_connetion_count = #self.interactable:getChildren() + #self.interactable:getParents()
    end
    if self.reset_lock then
        sm.localPlayer.setLockedControls( false )
    end
    if (self.last_position ~= FloorDecimalPlaces(self.shape.worldPosition, 2)
        or self.last_rotation ~= FloorDecimalPlaces(self.shape.worldRotation, 2))
        and self.active_character ~= nil then
        self:client_UpdateVisualRotation()
    end
    if self.MoveTicker > 0 then
        self.MoveTicker = self.MoveTicker - 1
    else
        if self.WisOn then
            self.offset = self.offset + sm.vec3.new(0,0,1)
        end
        if self.SisOn then
            self.offset = self.offset + sm.vec3.new(0,0,-1)
        end
        if self.AisOn then
            self.offset = self.offset + sm.vec3.new(1,0,0)
        end
        if self.DisOn then
            self.offset = self.offset + sm.vec3.new(-1,0,0)
        end
        if self.AisOn or self.WisOn or self.SisOn or self.DisOn then
            self.MoveTicker = 4
            if self.offset.x > 0 then
                self.offset.x = 0
            end
            if self.offset.y < 0 then
                self.offset.y = 0
            end
            if self.offset.z < 0 then
                self.offset.z = 0
            end
            self:client_UpdateVisualPosition()
            if self.LeftCliclisOn then
                local world = self.active_character:getWorld()
                if self.random_rotation then self:client_UpdateVisualRotation() end
                self.network:sendToServer("server_spawnTrack", {player=self.active_character:getPlayer(),world=world, last_position=self.visual_position,offset=self.visual_offset, last_rotation=self.visual_rotation,index=self.selected_index})
            end
        end
    end
end

function FloorDecimalPlaces(vector, places)
    places = places - 1
    local factor = math.pow(10, places)
    local x = math.floor(vector.x * factor) / factor
    local y = math.floor(vector.y * factor) / factor
    local z = math.floor(vector.z * factor) / factor
    if type(vector) == "Quat" then
        local w = math.floor(vector.w * factor) / factor
        return sm.quat.new(x, y, z, w)
    elseif type(vector) == "Vec3" then
        return sm.vec3.new(x, y, z)
    end
end

local LocalNorth = sm.vec3.getRotation( sm.vec3.new(0,0,1), sm.vec3.new(0,0,-1) )

function TrackBuilder.client_UpdateVisualRotation(self)
    self.visual_rotation = self.shape.worldRotation
    self.visual_rotation = sm.quat.lookRotation(sm.quat.getUp(self.visual_rotation), sm.quat.getRight(self.visual_rotation))
    self.last_rotation = FloorDecimalPlaces(self.shape.worldRotation, 2)

    local turn = sm.quat.lookRotation( sm.vec3.new(0,-1,0), sm.vec3.new(1,0,0) )
    sm.camera.setRotation( self.visual_rotation * turn )

    if self.random_rotation == true then
        local new = math.random(0,3)
        while new == self.rotation_index do new = math.random(0,3) end
        self.rotation_index = new
    end

    if self.rotation_index == 2 then
        local nturn = sm.vec3.getRotation( sm.vec3.new(-1,0,0), sm.vec3.new(0,-1,0) )
        self.visual_rotation = self.visual_rotation * nturn * nturn
        self.visual_offset = self.shape.worldRotation * sm.vec3.new(0,0,-3.25)
    elseif self.rotation_index == 3 then
        local nturn = sm.vec3.getRotation( sm.vec3.new(0,1,0), sm.vec3.new(1,0,0) )
        self.visual_rotation = self.visual_rotation * nturn
        self.visual_offset = self.shape.worldRotation * sm.vec3.new(3.25,0,-3.25)
    elseif self.rotation_index == 1 then
        local nturn = sm.vec3.getRotation( sm.vec3.new(1,0,0), sm.vec3.new(0,1,0) )
        self.visual_rotation = self.visual_rotation * nturn
        self.visual_offset = self.shape.worldRotation * sm.vec3.new(0,0,0)
    else
        self.visual_offset = self.shape.worldRotation * sm.vec3.new(3.25,0,0)
    end

    self.visual_rotation = self.visual_rotation * LocalNorth
    if self.visualization ~= nil then
        self.visualization:setRotation( self.visual_rotation )
    end

    self:client_UpdateVisualPosition()
end

function TrackBuilder.client_UpdateVisualPosition(self)
    local d_vec = self.shape.worldRotation * (sm.vec3.new(-0.5,0,0.5) + (self.offset * 3.25))
    local position = self.shape.worldPosition - d_vec
    self.visual_position = position
    if self.visualization ~= nil then
        self.visualization:setPosition( position + self.visual_offset )
    end
    self.last_position = FloorDecimalPlaces(self.shape.worldPosition, 2)
    local b4posFlip = self.shape.worldRotation * sm.vec3.new(-1.625,0,1.625)
    if b4posFlip.z > 0 then
        b4posFlip.y = b4posFlip.z
        b4posFlip.z = 0
    end
    local offset_dir_p = b4posFlip + sm.vec3.new(0,0,-24)
    sm.camera.setPosition( position - offset_dir_p)
end

function TrackBuilder.client_UpdateVisualBlueprint( self, blueprint )
    if self.visualization ~= nil then
        self.visualization:destroy()
    end
    self.visualization = sm.visualization.createBlueprint(blueprint)
    self:client_UpdateVisualRotation()
end

function TrackBuilder.client_onInteract( self, character, state )
	if state == true then
        self:client_initialize()
        if self.visualization == nil then
            self.visualization = sm.visualization.createBlueprint("$CONTENT_DATA/Blueprints/g_13x13_concrete.blueprint")
        end
        self.network:sendToServer("server_getBlueprintData", {player=character:getPlayer(),index=self.selected_index})
        self.active_character = character
        character:setLockingInteractable( self.interactable )
        sm.camera.setCameraState( 3 )
        self.gui:open()
        self.overlay:open()
        sm.localPlayer.setLockedControls( true )
        self.reset_lock = true
	end
end

function TrackBuilder.client_updateVisualIndex( self )
    local parents = #self.interactable:getParents()
    for i=1, 10 do
        if i <= parents then
            self.gui:setGridItem( "ButtonGrid", i-1, {
                ["itemId"] = "2a002066-f0b0-4707-bf51-5aa69b9f032"..tostring(math.fmod(i,10)),
                ["active"] = i == self.selected_index
            })
        else
            self.gui:setGridItem( "ButtonGrid", i-1, {
                ["itemId"] = tostring(sm.uuid.getNil()),
                ["active"] = false
            })
        end
    end
    if self.active_character ~= nil then
        self.network:sendToServer("server_getBlueprintData", {player=self.active_character:getPlayer(),index=self.selected_index})
    end
end

function TrackBuilder.client_onAction( self, input, active )
    if (input == 4 and active) then
		self.SisOn = true
	elseif (input == 4 and not active) then
		self.SisOn = false
        self.MoveTicker = 0
	end
	if (input == 3 and active) then
		self.WisOn = true
	elseif (input == 3 and not active) then
		self.WisOn = false
        self.MoveTicker = 0
	end
	if (input == 1 and active) then
		self.AisOn = true
	elseif (input == 1 and not active) then
		self.AisOn = false
        self.MoveTicker = 0
	end
	if (input == 2 and active) then
		self.DisOn = true
	elseif (input == 2 and not active) then
		self.DisOn = false
        self.MoveTicker = 0
	end
    if input == 19 and active then
        self.LeftCliclisOn = true
        local world = self.active_character:getWorld()
        if self.random_rotation then self:client_UpdateVisualRotation() end
        self.network:sendToServer("server_spawnTrack", {player=self.active_character:getPlayer(),world=world, last_position=self.visual_position,offset=self.visual_offset, last_rotation=self.visual_rotation,index=self.selected_index})
    elseif input == 19 and not active then
        self.LeftCliclisOn = false
    end
    if input == 18 and active then
        self.network:sendToServer("server_DeleteAtPos", {last_position=self.visual_position,player=self.active_character:getPlayer()})
    end
    if input == 20 then
        self.rotation_index = self.rotation_index - 1
        self:client_ClampRotationIndex()
    elseif input == 21 then
        self.rotation_index = self.rotation_index + 1
        self:client_ClampRotationIndex()
    end
    
    if input >= 5 and input <= 14 and active then
        local number = input - 4
        self.selected_index = number
        self:client_updateVisualIndex()
    end
    if input == 15 and active then
        self.network:sendToServer("server_GlueTogether", {rotation=self.visual_rotation})
    end
    if input == 16 and active then
        self.random_rotation = self.random_rotation ~= true
        print(self.random_rotation)
    end
    if input == 0 then
        if self.visualization ~= nil then
            self.visualization:destroy()
        end
        self.active_character:setLockingInteractable( nil )
        self:client_initialize()
        sm.localPlayer.setLockedControls( false )
        sm.camera.setCameraState( 0 )
        self.gui:close()
        self.overlay:close()
    end

    self:updateOverlay()
    return true
end

function TrackBuilder.updateOverlay( self )
    if not self.overlay:isActive() then return end
    print(self.overlay)
    local data = ""
    local color = "ffffff"
    local add = function(text)data = data .. text .."\n#" .. color end

    local random = self.random_rotation and "#00ff00ON" or "#ff0000OFF"
    add("[#ffa500"..sm.gui.getKeyBinding( "Use", false ).."#ffffff] to finalize build")
    add("[#ffa500"..sm.gui.getKeyBinding( "Jump", false ).."#ffffff] random rotate "..string.format("%s", random))
    add("[#ffa500"..sm.gui.getKeyBinding( "Forward", false )..sm.gui.getKeyBinding( "StrafeLeft", false )..sm.gui.getKeyBinding( "Backward", false )..sm.gui.getKeyBinding( "StrafeRight", false ).."#ffffff] to move")
    add("[#ffa500Scroll#ffffff] to rotate")
    add("[#ffa500"..sm.gui.getKeyBinding( "Attack", false ).."#ffffff] to place")
    add("[#ffa500"..sm.gui.getKeyBinding( "Create", false ).."#ffffff] to delete")
    add("[#ffa500Any#ffffff] to exit")

    self.overlay:setText( "BOTTOMLEFT", data )
end

local blk_glue_md_rmv = sm.uuid.new("8521a2a2-6da6-4167-a439-28eed83dc50f")

function TrackBuilder.constructionRayCast( self, dta )
	local start = dta.r_s
	local stop = dta.r_e
	local valid, result = sm.physics.raycast( start, stop, nil, 4611 )
	if valid then
		local groundPointOffset = -( sm.construction.constants.subdivideRatio_2 - 0.04 + sm.construction.constants.shapeSpacing + 0.005 )
		local pointLocal = result.pointLocal
		if result.type ~= "body" and result.type ~= "joint" then
			pointLocal = pointLocal + result.normalLocal * groundPointOffset
		end

		local n = sm.vec3.closestAxis( result.normalLocal )
		local a = pointLocal * sm.construction.constants.subdivisions - n * 0.5
		local gridPos = sm.vec3.new( math.floor( a.x ), math.floor( a.y ), math.floor( a.z ) ) + n

		local function getTypeData()
			local shapeOffset = sm.vec3.new( sm.construction.constants.subdivideRatio_2, sm.construction.constants.subdivideRatio_2, sm.construction.constants.subdivideRatio_2 )
			local localPos = gridPos * sm.construction.constants.subdivideRatio + shapeOffset
			if result.type == "body" then
				local shape = result:getShape()
				if shape and sm.exists( shape ) then
					return shape:getBody():transformPoint( localPos ), shape
				else
					valid = false
				end
			elseif result.type == "joint" then
				local joint = result:getJoint()
				if joint and sm.exists( joint ) then
					return joint:getShapeA():getBody():transformPoint( localPos ), joint
				else
					valid = false
				end
			elseif result.type == "lift" then
				local lift, topShape = result:getLiftData()
				if lift and ( not topShape or lift:hasBodies() ) then
					valid = false
				end
				return localPos, lift
			elseif result.type == "character" then
				valid = false
			elseif result.type == "harvestable" then
				valid = false
			end
			return localPos
		end

		local worldPos, obj = getTypeData()
		return valid, gridPos, result.normalLocal, worldPos, obj
	end
	return valid
end

function TrackBuilder.isValidPlacement(self ,r_s, r_e)
    local hit, gridPos, normalLocal, worldPos, obj = self:constructionRayCast({r_s=r_s,r_e=r_e})
    if hit then
        local function countTerrain()
            if type(obj) == "Shape" then
                return obj:getBody():isDynamic()
            end
            return false
        end
        return sm.physics.sphereContactCount( worldPos, 0.125, countTerrain() ) == 0 and
        sm.construction.validateLocalPosition( blk_glue_md_rmv, gridPos, normalLocal, obj ), gridPos, obj
    end
end

function TrackBuilder.server_GlueTogether(self, data)
    self.glue_counter = 3
    self.gluing = true
end

function TrackBuilder.client_ClampRotationIndex(self)
    if self.rotation_index > 3 then
        self.rotation_index = 0
    end
    if self.rotation_index < 0 then
        self.rotation_index = 3
    end
    self:client_UpdateVisualRotation()
end

function TrackBuilder.client_onDestroy( self )
    if self.active_character ~= nil then
        self.visualization:destroy()
    end
end

function CenterBlueprint(blueprint, state, reset_trans)
    if state == nil then state = 1 end
    local smpos = sm.vec3.new(512,512,512)
    for _,body in pairs(blueprint.bodies) do
        for _,child in pairs(body.childs) do
            if smpos.x > child.pos.x or 
            smpos.y > child.pos.y or 
            smpos.z > child.pos.z then
                smpos.x = child.pos.x
                smpos.y = child.pos.y
                smpos.z = child.pos.z
            end
        end
    end
    for _,body in pairs(blueprint.bodies) do
        body.type = state
        body.transform.pos = {x=0,y=0,z=0}
        if (body.transform ~= nil and reset_trans == nil) then
            local r = body.transform.rot
            local tmpq = sm.quat.new(r.x,r.y,r.z,r.w)
            tmpq = sm.quat.round90( tmpq )
            body.transform.rot = {tmpq.x,tmpq.y,tmpq.z,tmpq.w}
        end
        for _,child in pairs(body.childs) do
            child.pos.x = child.pos.x - smpos.x
            child.pos.y = child.pos.y - smpos.y
            child.pos.z = child.pos.z - smpos.z
        end
    end
    return blueprint
end

function TrackBuilder.server_getBlueprintData( self, data )
    local parent = self.interactable:getParents()[data.index]
    if parent ~= nil and parent:getPublicData().creationString ~= nil then
        local blueprint_data = sm.json.parseJsonString(parent:getPublicData().creationString)
        blueprint_data = CenterBlueprint(blueprint_data)
        self.network:sendToClient(data.player, "client_UpdateVisualBlueprint", blueprint_data)
    end
end

function TrackBuilder.server_DeleteAtPos(self, data)
    local offset = self.shape.worldRotation * sm.vec3.new(1.625,0,-1.625)
    if offset.z ~= 0 then
        offset.y = offset.z
        offset.z = 0
    end

    for i,vec in ipairs(self.valid_tile_positions) do
        if vec == data.last_position then
            table.remove(self.valid_tile_positions, i)
        end
    end

    local ray_start = data.last_position + sm.vec3.new(0,0,12) + offset
    local ray_end = data.last_position + sm.vec3.new(0,0,-2) + offset
    local valid, result = sm.physics.raycast( ray_start, ray_end, nil, 4611 )
    if valid then
        if result.type == "body" then
            for _,shape in pairs(result:getBody():getShapes()) do
                shape:destroyShape(0)
            end
        end
        self.network:sendToClient(data.player, "client_deleteNoise")
    end
end

function TrackBuilder.server_spawnTrack( self, data )
    local offset = self.shape.worldRotation * sm.vec3.new(1.625,0,-1.625)
    if offset.z ~= 0 then
        offset.y = offset.z
        offset.z = 0
    end
    local ray_start = data.last_position + sm.vec3.new(0,0,12) + offset
    local ray_end = data.last_position + sm.vec3.new(0,0,-2) + offset
    local valid, result = sm.physics.raycast( ray_start, ray_end, nil, 4611 )
    if not valid then
        local parent = self.interactable:getParents()[data.index]
        if parent ~= nil and parent:getPublicData().creationString ~= nil then
            local blueprint_data = sm.json.parseJsonString(parent:getPublicData().creationString)
            blueprint_data = CenterBlueprint(blueprint_data)
            local jsonString = sm.json.writeJsonString( blueprint_data )
            bodies = sm.creation.importFromString(data.world, jsonString, data.last_position+data.offset, data.last_rotation, true )        
            for _,body in pairs(bodies) do
                body:setConvertibleToDynamic(false)
            end
            table.insert(self.valid_tile_positions, data.last_position)
            self.network:sendToClient(data.player, "client_buildNoise")
        else
            self.network:sendToClient(data.player, "client_errorBuildNoise")
        end
    else
        self.network:sendToClient(data.player, "client_errorBuildNoise")
    end
end

function TrackBuilder.client_deleteNoise( self, data )
    sm.audio.play( "Destruction - Block destroyed", sm.camera.getPosition() + sm.vec3.new(0,0,-8) )
end

function TrackBuilder.client_buildNoise( self, data )
    sm.audio.play( "WeldTool - Sparks", sm.camera.getPosition() + sm.vec3.new(0,0,-12) )
    sm.audio.play( "WeldTool - Weld", sm.camera.getPosition() + sm.vec3.new(0,0,-8) )
end

function TrackBuilder.client_errorBuildNoise( self, data )
    sm.effect.playEffect( "Sensor off - Level 5", sm.camera.getPosition(), sm.vec3.one(), sm.quat.identity(), sm.vec3.one(), nil )
end

local glueing_positions = {
    sm.vec3.new(6,0,-1),
    sm.vec3.new(12,6,-1),
    sm.vec3.new(6,12,-1),
    sm.vec3.new(0,6,-1)
}

function TrackBuilder.server_onFixedUpdate( self, dt )
    if self.pending_deletion then
        for _,body in pairs(sm.body.getAllBodies()) do
            for _,shape in pairs(body:getShapes()) do
                if shape.uuid == blk_glue_md_rmv then
                    shape:destroyShape(0)
                end
            end
        end
    end
    if self.gluing then
        if self.glue_counter > 0 then
            local factor = sm.vec3.new(3.225,0,-3.225)
            
            local positions = {
                sm.vec3.new(1,0,1),
                sm.vec3.new(0,0,1),
                sm.vec3.new(0,0,0),
                sm.vec3.new(1,0,0)
            }

            if self.glue_index < #self.valid_tile_positions then
                self.glue_index = self.glue_index + 1 
                local position = self.valid_tile_positions[self.glue_index]
                --for _,position in pairs(self.valid_tile_positions) do

                for _,p_offset in pairs(positions) do

                    local ftt = (p_offset * factor) + sm.vec3.new(0.01,0,-0.01)

                    local offset = self.shape.worldRotation * ftt
                    if offset.z ~= 0 then
                        offset.y = offset.z
                        offset.z = 0
                    end

                    local ray_start = position + sm.vec3.new(0,0,12) + offset
                    local ray_end = position + sm.vec3.new(0,0,-2) + offset
                    local valid, gridPos, obj = self:isValidPlacement(ray_end, ray_start)

                    if valid then
                        sm.construction.buildBlock( blk_glue_md_rmv, gridPos, obj )
                    end
                end
                
                --end
            else
                self.glue_index = 0
                self.glue_counter = self.glue_counter - 1
            end
        elseif self.glue_counter == 0 then
            local position = self.valid_tile_positions[1]
            local offset = self.shape.worldRotation * sm.vec3.new(1.625,0,-1.625)
            if offset.z ~= 0 then
                offset.y = offset.z
                offset.z = 0
            end
            local ray_start = position + sm.vec3.new(0,0,12) + offset
            local ray_end = position + sm.vec3.new(0,0,-2) + offset
            local valid, gridPos, obj = self:isValidPlacement(ray_end, ray_start)
            if obj ~= nil then
                obj:getBody():setConvertibleToDynamic(true)
            end
            for _,body in pairs(sm.body.getAllBodies()) do
                for _,shape in pairs(body:getShapes()) do
                    if shape.uuid == blk_glue_md_rmv then
                        shape:destroyShape(0)
                    end
                end
            end
            self.gluing = false
        end
    end
end

function TrackBuilder.server_onCreate( self, dt )
    self.valid_tile_positions = {}
    self.gluing = false
    self.pending_deletion = false
    self.glue_counter = 0
    self.glue_index = 0
end
