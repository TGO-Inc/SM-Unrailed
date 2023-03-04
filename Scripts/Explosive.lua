Explosive = class()

Explosive.maxParentCount = 1
Explosive.maxChildCount = 0
Explosive.connectionInput = sm.interactable.connectionType.logic
Explosive.connectionOutput = sm.interactable.connectionType.none
Explosive.colorHighlight = sm.color.new( "#ff0000" )
Explosive.colorNormal = sm.color.new( "#ff0000" )

function Explosive.server_onFixedUpdate( self )
    if self.fired ~= nil then
        self.fired = self.fired - 1
        if self.fired == 0 then
            self.shape:destroyShape(0)
        end
    end
    parent = self.interactable:getSingleParent()
    if parent ~= nil and self.fired == nil then
        if parent:isActive() then
            local velocity = sm.vec3.new(-1,-1,-1)
            sm.projectile.shapeFire( self.shape, sm.uuid.new("31b92b9a-a9f8-4f6d-988b-04ad479978ec"), sm.vec3.zero(), velocity, 0 )
            self.fired = 5
        end
    end
end