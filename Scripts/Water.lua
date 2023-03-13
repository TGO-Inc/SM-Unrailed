Water = class()

function Water.server_onCreate( self )
    self.triggeredCharacters = {}
    self.water = sm.areaTrigger.createBoxWater( sm.vec3.new(1.625,0.5,1.625), self.shape.worldPosition+sm.vec3.new(0,0,1), self.shape.worldRotation, nil, {water=true} )
    self.water:bindOnEnter("onEnter")
    self.water:bindOnExit("onExit")
    self.water:bindOnStay("onStay")
    self.height = self.storage:load()
    if self.height == nil then self.height = 1
    else self.height = self.height.height end
    self.network:sendToClients("client_setHeight", self.height)
end

function Water.server_setHeight( self, height )
    self.height = height+1
    self.storage:save({height=self.height})
end

function Water.client_setHeight( self, height )
    self.height = height;
end

function Water.client_onCreate( self )
    self.water_effect = sm.effect.createEffect("ShapeRenderable")
    self.water_effect:setParameter("uuid", sm.uuid.new("5f41af56-df4c-4837-9b3c-10781335757f"))
    self.water_effect:setScale(sm.vec3.new(3.25,1,3.25))
    self.water_effect:setPosition(self.shape.worldPosition)
    self.water_effect:setRotation(self.shape.worldRotation)
    self.water_effect:start()
    self.height = 1
    self.position_gui = sm.gui.createEngineGui()
    self.position_gui:setText( "Name", "Water Height" )
	self.position_gui:setText( "Interaction", "Adjust the slider to change the water height" )
	self.position_gui:setOnCloseCallback( "client_onGuiClosed" )
	self.position_gui:setSliderCallback( "Setting", "client_onSliderChange" )
	self.position_gui:setIconImage( "Icon", self.shape:getShapeUuid() )
    self.position_gui:setVisible( "BackgroundGas", false )
	self.position_gui:setVisible( "FuelGrid", false )
    self.position_gui:setSliderPosition("Setting", 0 )
    self.position_gui:setSliderData( "Setting", 4, 0 )
    self.position_gui:setSliderRangeLimit( "Setting", 4 )
    self.position_gui:setVisible( "Upgrade", false )
    self.position_gui:setText( "SubTitle", "Height: 0")
end

function Water.client_onSliderChange( self, button, value )
    self.height = value + 1
    self.position_gui:setText( "SubTitle", "Height: "..self.height)
    self.network:sendToServer("server_setHeight", value)
end

function Water.client_onGuiClosed( self, button )
    self.position_gui:close()
end

function Water.client_onFixedUpdate( self )
    self.water_effect:setPosition(self.shape.worldPosition+(self.shape.worldRotation*sm.vec3.new(0,0.25+(self.height/8),0)))
    self.water_effect:setRotation(self.shape.worldRotation)
    self.water_effect:setScale(sm.vec3.new(3.249,self.height/4,3.249))
end

function Water.client_onDestroy( self )
    self.water_effect:stop()
    self.water_effect:destroy()
end

function Water.client_onInteract( self, char, state )
    if state then
        self.position_gui:setText( "SubTitle", "Height: "..self.height)
        self.position_gui:setSliderPosition("Setting", self.height - 1 )
        self.position_gui:open()
    end
end

local function PlaySplashEffect( pos, velocity, mass )

	local energy = 0.5*velocity:length()*velocity:length()*mass

	local params = {
		["Size"] = min( 1.0, mass / 76800.0 ),
		["Velocity_max_50"] = velocity:length(),
		["Phys_energy"] = energy / 1000.0
	}

	if energy > 8000 then
		sm.effect.playEffect( "Water - HitWaterMassive", pos, sm.vec3.zero(), sm.quat.identity(), sm.vec3.one(), params )
	elseif energy > 4000 then
		sm.effect.playEffect( "Water - HitWaterBig", pos, sm.vec3.zero(), sm.quat.identity(), sm.vec3.one(), params )
	elseif energy > 150 then
		sm.effect.playEffect( "Water - HitWaterSmall", pos, sm.vec3.zero(), sm.quat.identity(), sm.vec3.one(), params )
	elseif energy > 1 then
		sm.effect.playEffect( "Water - HitWaterTiny", pos, sm.vec3.zero(), sm.quat.identity(), sm.vec3.one(), params )
	end
		
end

local function UpdateCharacterInWater( trigger, character )
	-- Update swim state
	local waterHeightPos = trigger:getWorldMax().z
	--local characterFloatHeight = character.worldPosition.z + character:getHeight() * 0.15
	--local characterDiveHeight = character.worldPosition.z + character:getHeight() * 0.5
	local characterFloatOffset = 0.2 + ( character:isCrouching() and 0.4 or 0.0 )
	local characterFloatHeight = character.worldPosition.z + characterFloatOffset
	local characterDiveOffset = 0.7 + ( character:isCrouching() and 0.4 or 0.0 )
	local characterDiveHeight = character.worldPosition.z + characterDiveOffset
	if sm.isHost and character:getCanSwim() then
		-- Update swimming state
		if not character:isSwimming() then
			if waterHeightPos > characterFloatHeight then
				character:setSwimming( true )
			end
		else
			if waterHeightPos <= characterFloatHeight then
				character:setSwimming( false )
			end
		end
		-- Update diving state
		if not character:isDiving() then
			if waterHeightPos > characterDiveHeight then
				character:setDiving( true )
			end
		else
			if waterHeightPos <= characterDiveHeight then
				character:setDiving( false )
			end
		end
	end

	-- Scaled movement slowdown when walking through water
	local waterMovementSpeedFraction = 1.0
	if not character:isSwimming() then
		local depthScale = 1 - math.max( math.min( ( ( character.worldPosition.z + characterDiveOffset ) - waterHeightPos ) / ( characterDiveOffset * 2 ), 1.0 ), 0.0 )
		waterMovementSpeedFraction = math.max( math.min( 1 - ( depthScale + 0.1 ), 1.0 ), 0.3 )
	end
	if sm.isHost then
		if character.publicData then
			character.publicData.waterMovementSpeedFraction = waterMovementSpeedFraction
		end
	else
		if character.clientPublicData then
			character.clientPublicData.waterMovementSpeedFraction = waterMovementSpeedFraction
		end
	end

	if character:isTumbling() then
		local worldPosition = character:getTumblingWorldPosition()
		local worldRotation = character:getTumblingWorldRotation()
		local velocity = character:getTumblingLinearVelocity()
		local halfExtent = character:getTumblingExtent() * 0.5
		local mass = character:getMass()
		-- local mass = 10.0
		local force = CalulateForce( waterHeightPos, worldPosition, worldRotation, velocity, halfExtent, mass )
		character:applyTumblingImpulse( force )
	else
		-- Push up if under surface
		local waterHeightFloatThreshold = waterHeightPos - character:getHeight() * 0.5
		if not character:getCanSwim()  then
			local characterForce = sm.vec3.new( 0, 0, character:getMass() * 15 )
			sm.physics.applyImpulse( character, characterForce * 0.025, true )
		elseif ( characterFloatHeight < waterHeightPos and characterFloatHeight > waterHeightFloatThreshold ) then
			-- Buoyancy force formula
			local fluidDensity = 1000
			local displacedVolume = 0.0664
			local buoyancyForce = fluidDensity * displacedVolume * GRAVITY
			local diveDepthScale = 1 - math.max( math.min( ( characterFloatHeight - waterHeightFloatThreshold ) / ( waterHeightPos - waterHeightFloatThreshold ) , 1.0 ), 0.0 )
			local characterForce = sm.vec3.new( 0, 0, buoyancyForce * diveDepthScale )
			sm.physics.applyImpulse( character, characterForce * 0.025, true )
		end
	end
end

function Water.onEnter( self, trigger, results )
    for _,result in pairs(results) do
        if sm.exists( result ) then
            if type(result) == "Character" then
                local triggerMax = trigger:getWorldMax()
                local characterPos = result:getWorldPosition()
                local splashPosition = sm.vec3.new( characterPos.x, characterPos.y, triggerMax.z )

                if not result:isSwimming() then
                    PlaySplashEffect( splashPosition, result:getVelocity(), result:getMass() )
                end

                -- Only trigger once per tick
                if self.triggeredCharacters[result.id] == nil then
                    self.triggeredCharacters[result.id] = true
                    UpdateCharacterInWater( trigger, result )
                end
            end
        end
    end
end

function Water.onExit( self, trigger, results )
    for _,result in pairs(results) do
        self:server_charExit(result)
    end
end

function Water.server_charExit( self, result )
    if sm.exists( result ) then
        if type(result) == "Character" then
            if sm.isHost then
                if result:isSwimming() then
                    result:setSwimming( false )
                end
                if result:isDiving() then
                    result:setDiving( false )
                end
                if sm.isHost then
                    if result.publicData then
                        result.publicData.waterMovementSpeedFraction = 1.0
                    end
                else
                    if result.clientPublicData then
                        result.clientPublicData.waterMovementSpeedFraction = 1.0
                    end
                end
            end
        end
    end
end

function Water.onStay( self, trigger, results )
    for _, result in ipairs( results ) do
		if sm.exists( result ) then
			if type( result ) == "Character" then
				if self.triggeredCharacters[result.id] == nil then
					self.triggeredCharacters[result.id] = true
					UpdateCharacterInWater( trigger, result )
				end
			end
		end
	end
end

function Water.server_onFixedUpdate( self )
    if self.height == nil then
        self.height = self.storage:load()
        if self.height == nil then self.height = 1
        else self.height = self.height.height end
        self.storage:save({height=self.height})
    end

    self.water:setWorldPosition( self.shape.worldPosition+(self.shape.worldRotation*sm.vec3.new(0,0.25+(self.height/8),0)) )
    self.water:setWorldRotation( self.shape.worldRotation )
    self.water:setSize(sm.vec3.new(1.62,self.height/8,1.62))
    self.triggeredCharacters = {}
end

function Water.server_onDestroy( self )
    for _,item in pairs(self.water:getContents()) do
        self:server_charExit(item)
    end
    sm.areaTrigger.destroy(self.water)
end