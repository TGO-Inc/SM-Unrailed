PottedPlant = class()
PottedPlant.maxParentCount = 0
PottedPlant.maxChildCount = 9999
PottedPlant.connectionInput = sm.interactable.connectionType.none
PottedPlant.connectionOutput = 8192

PottedPlant.colorHighlight = sm.color.new( "#916640" )
PottedPlant.colorNormal = sm.color.new( "#704621" )

function PottedPlant.server_onCreate( self )
    self.health = 3
    self.interactable:setActive( true )
end

function PottedPlant.server_onProjectile( self, position, airTime, velocity, projectileName, shooter, damage, customData, normal, uuid )
    self.health = self.health - 1
    self:server_checkHealth("Tree - DefaultHit")
end

function PottedPlant.server_onMelee( self, position, attacker, damage, power, direction, normal )
    if damage == 10000 then
        local nh = self.health - 0.035
        if math.floor(nh) < math.floor(self.health) then
            self:server_checkHealth("Tree - DefaultHit")
        end
        self.health = nh
    elseif damage == 94 or damage == 20 then
        self.health = self.health - 1
        self:server_checkHealth("Tree - BreakTrunk SpruceHalf")
    else
        self.health = self.health - 0.35
        self:server_checkHealth("Tree - DefaultHit")
    end
end

function PottedPlant.server_checkHealth(self, hit)
    local worldPosition = self.shape.worldPosition
    local rotation = self.shape.worldRotation
    local halfTurn = sm.vec3.getRotation( sm.vec3.new( 1, math.random(-1,1), 0 ), sm.vec3.new( math.random(-1,1), 1, 0 ) )
    sm.effect.playEffect( hit, worldPosition, sm.vec3.one(), self.shape.worldRotation * halfTurn )
    if self.health <= 0 then
        body = self.shape:getBody()
        self.shape:destroyShape(0)
    end
end

function PottedPlant.client_onCreate( self  )
	self.cl = {}
end

function PottedPlant.server_onExplosion( self, center, destructionLevel )
	self.health = 0
    self:server_checkHealth("Tree - BreakTrunk SpruceHalf")
end