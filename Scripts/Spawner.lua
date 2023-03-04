
Spawner = class()
Spawner.maxParentCount = 2
Spawner.maxChildCount = 0
Spawner.connectionInput = sm.interactable.connectionType.logic + 4096
Spawner.connectionOutput = sm.interactable.connectionType.none
Spawner.poseWeightCount = 1
Spawner.colorNormal = sm.color.new( "#c21d38" )
Spawner.colorHighlight = sm.color.new( "#e34660" )

function Spawner.server_onCreate( self )
    self.has_spawned = false
end

function Spawner.client_onCreate( self  )
	self.cl = {}
end

function Spawner.inputActive( self )
    local parents = self.interactable:getParents()
    for _, parent in pairs(parents) do
        if parent then
            if parent:hasOutputType( sm.interactable.connectionType.logic ) then
                return parent:isActive()
            end
        end
    end

	return false
end

function Spawner.client_onFixedUpdate( self, dt )
	
end

function Spawner.server_onFixedUpdate( self, dt )
    if self:inputActive() and self.has_spawned == false then
        self.has_spawned = true
        local child = self.interactable:getParents(4096)[1]
        self:server_LoadBody(child:getPublicData())
    elseif self:inputActive() == false then
        self.has_spawned = false
    end
end

function Spawner.server_LoadBody(self, data)
    if data.creationString ~= nil then
        local min = sm.vec3.new(16,16,16)
        local creation = sm.json.parseJsonString(data.creationString)
        for i=1,#creation.bodies do
            for c=1,#creation.bodies[i].childs do
                local pos = creation.bodies[i].childs[c].pos
                if math.abs(min.x) > math.abs(pos.x) then
                    min = sm.vec3.new(pos.x,pos.y,pos.z)
                end
                if math.abs(min.y) > math.abs(pos.y) then
                    min = sm.vec3.new(pos.x,pos.y,pos.z)
                end
                if math.abs(min.z) > math.abs(pos.z) then
                    min = sm.vec3.new(pos.x,pos.y,pos.z)
                end
            end
        end
        min = min * 0.25
        local rot = self.interactable:getShape():getWorldRotation()
        rot = sm.quat.new(math.floor(rot.x*100)/100,math.floor(rot.y*100)/100,math.floor(rot.z*100)/100,math.floor(rot.w*100)/100)
        local pos = self.interactable:getShape():getWorldPosition()
        local npos = pos - (rot * min) + (rot * sm.vec3.new(2,2,0))
        --creation
        sm.creation.importFromString(sm.world.getCurrentWorld(), data.creationString, npos, rot, false, false )
    end
end