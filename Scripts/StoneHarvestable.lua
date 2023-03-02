-- StoneHarvestable.lua --
dofile("$SURVIVAL_DATA/Scripts/game/survival_constants.lua")
dofile("$SURVIVAL_DATA/Scripts/game/survival_shapes.lua")
dofile("$SURVIVAL_DATA/Scripts/util.lua")

StoneHarvestable = class( nil )
StoneHarvestable.ChunkHealth = 3
StoneHarvestable.DamagerPerHit = 1
StoneHarvestable.maxParentCount = 0
StoneHarvestable.maxChildCount = 9999
StoneHarvestable.connectionInput = sm.interactable.connectionType.none
StoneHarvestable.connectionOutput = 8192

function StoneHarvestable.server_onCreate( self )
	self:sv_init()
	self.interactable:setActive( true )
end

function StoneHarvestable.server_onRefresh( self ) 
	self:sv_init()
end

function StoneHarvestable.sv_init( self )
	self.stoneParts = nil
end

function StoneHarvestable.server_onMelee( self, hitPos, attacker, damage, power, hitDirection )
	self:sv_onHit( self.DamagerPerHit, hitPos )
end

function StoneHarvestable.sv_onHit( self, damage, position, s )
	self.ChunkHealth = self.ChunkHealth - damage

	if s == nil then
		s = 0.015
	end

	local angleaxis = sm.quat.getUp( self.shape.worldRotation )
	local rot = sm.quat.angleAxis( math.random(-math.pi,math.pi), angleaxis )
	local pos = self.shape.worldPosition  + (sm.quat.getUp( self.shape.worldRotation ) * -1)

	sm.effect.playEffect( "Stone - BreakChunk small", pos, nil, rot, nil, { size = s } )

	if self.ChunkHealth <= 0 then
		self.shape:destroyShape(0)
	end
end

function StoneHarvestable.server_onExplosion( self, center, destructionLevel )
	self:sv_onHit( 5, center, 10 )
end