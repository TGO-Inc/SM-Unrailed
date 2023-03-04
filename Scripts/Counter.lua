Counter = class()
Counter.maxParentCount = 9999
Counter.maxChildCount = 9999
Counter.connectionInput = 8192 + sm.interactable.connectionType.logic + 16384
Counter.connectionOutput = 16384
Counter.poseWeightCount = 1
Counter.colorHighlight = sm.color.new( "#51e073" )
Counter.colorNormal = sm.color.new( "#20bd45" )

function Counter.server_onCreate( self, dt )
    self.full_resource_table = {}
    self.offset = 0
    self.resource_counter = 0
    self.auto_child = true
    self.interactable:setActive(true)
end

function TableContains( _table, item )
    for k,v in pairs(_table) do
        if (v == item or k == item) then
            return true
        end
    end
    return false
end

function Counter.client_onCreate( self, dt)
    self.wait_timer = 0
end


function Counter.client_onInteract( self, character, state )
    if state then
        self.network:sendToServer("server_connectCounters", {})
    end
end

function Counter.server_connectCounters ( self, data )
    local closest_x = nil
    local closest_y = nil
    local closest_z = nil
    if data ~= nil then self.auto_child = false end
    for _,_body in pairs(self.shape:getBody():getCreationBodies()) do
        for _,shape in pairs(_body:getCreationShapes()) do
            if shape.uuid == self.shape:getShapeUuid() and self.shape ~= shape and shape.color == self.shape.color then
                if #shape:getInteractable():getParents(16384) <= 0 then
                    if math.abs(shape.worldPosition.x - self.shape.worldPosition.x) < 0.1 then
                        if closest_y == nil then closest_y = shape end
                        if math.abs(closest_y.worldPosition.y - self.shape.worldPosition.y) > math.abs(shape.worldPosition.y - self.shape.worldPosition.y) then
                            closest_y = shape
                        end
                    end
                    if math.abs(shape.worldPosition.y - self.shape.worldPosition.y) < 0.1 then
                        if closest_x == nil then closest_x = shape end
                        if math.abs(closest_x.worldPosition.x - self.shape.worldPosition.x) > math.abs(shape.worldPosition.x - self.shape.worldPosition.x) then
                            closest_x = shape
                        end
                    end
                    if math.abs(shape.worldPosition.z - self.shape.worldPosition.z) < 0.1 then
                        if closest_z == nil then closest_z = shape end
                        if math.abs(closest_z.worldPosition.z - self.shape.worldPosition.z) > math.abs(shape.worldPosition.z - self.shape.worldPosition.z) then
                            closest_z = shape
                        end
                    end
                end
            end
        end
    end
    local has_connected = false
    local p_count = #self.interactable:getParents(16384)
    if p_count <= 0 then
        if closest_x ~= nil then
            closest_x = closest_x:getInteractable()
            if #closest_x:getChildren() <= 0 then
                local p = closest_x:getParents()
                if #p > 0 then
                    for _,parent in pairs(p) do
                        if parent == self.interactable then return end
                    end
                end
                closest_x:connect(self.interactable)
                sm.event.sendToInteractable(closest_x, "server_connectCounters" )
                has_connected = true
            end
        end
        if closest_y ~= nil then
            closest_y = closest_y:getInteractable()
            if #closest_y:getChildren() <= 0 then
                local p = closest_y:getParents()
                if #p > 0 then
                    for _,parent in pairs(p) do
                        if parent == self.interactable then return end
                    end
                end
                closest_y:connect(self.interactable)
                sm.event.sendToInteractable(closest_y, "server_connectCounters" )
                has_connected = true
            end
        end
    end
    if not has_connected then
        local closest_shape = nil
        local closest_mag = nil
        for _,_body in pairs(self.shape:getBody():getCreationBodies()) do
            for _,shape in pairs(_body:getCreationShapes()) do
                if shape.uuid == self.shape:getShapeUuid() then
                    if self.shape ~= shape and shape.color == self.shape.color then
                        if #shape:getInteractable():getParents(16384) == 0 and #shape:getInteractable():getChildren(16384) == 0 then
                            if closest_shape == nil then closest_shape = shape end
                            local difference = shape.worldPosition - self.shape.worldPosition
                            local mag = math.pow(difference.x,2) + math.pow(difference.y,2) + math.pow(difference.z,2)
                            if closest_mag == nil then closest_mag = mag end
                            if mag < closest_mag then
                                closest_mag = mag
                                closest_shape = shape
                            end
                        end
                    end
                end
            end
        end
        if closest_shape ~= nil then
            closest_shape = closest_shape:getInteractable()
            has_connected = true
            sm.event.sendToInteractable(closest_shape, "server_connectCounters" )
        end
    end
    if not has_connected and #self.interactable:getChildren(16384) == 0 then
        self:server_findAllWithout()
    end
end

function IsInChain( start, target )
    for _,parent in pairs(start:getParents(16384)) do
        if parent == target then return true end
        if IsInChain( parent, target ) then return true end
    end
    return false
end

function Counter.server_findAllWithout( self )
    local closest_shape = nil
    local closest_mag = nil
    local __closest_shape = nil
    local __closest_mag = nil
    local atuoo = nil
    for _,_body in pairs(self.shape:getBody():getCreationBodies()) do
        for _,shape in pairs(_body:getCreationShapes()) do
            if shape.uuid == self.shape:getShapeUuid() then
                if self.shape ~= shape and shape.color == self.shape.color then
                    local interactable = shape:getInteractable()
                    local difference = shape.worldPosition - self.shape.worldPosition
                    local mag = math.pow(difference.x,2) + math.pow(difference.y,2) + math.pow(difference.z,2)
                    if not IsInChain(self.interactable, interactable) and #interactable:getChildren(16384) > 0 then
                        if closest_shape == nil then closest_shape = shape end
                        if closest_mag == nil then closest_mag = mag end
                        if mag < closest_mag then
                            closest_mag = mag
                            closest_shape = shape
                        end
                    elseif #interactable:getChildren(16384) == 0 and #interactable:getParents(16384) > 0 then
                        if interactable:getPublicData().auto then
                            if __closest_shape == nil then __closest_shape = shape end
                            if __closest_mag == nil then __closest_mag = mag end
                            if mag < __closest_mag then
                                __closest_mag = mag
                                __closest_shape = shape
                            end
                        else
                            atuoo = {s=shape,m=mag}
                        end
                    end
                end
            end
        end
    end
    if __closest_shape ~= nil then
        __closest_shape = __closest_shape:getInteractable()
        sm.event.sendToInteractable(__closest_shape, "server_findAllWithout" )
    end
    if atuoo ~= nil then
        if atuoo.m < closest_mag then
            self.interactable:connect(atuoo.s:getInteractable())
            return
        end
    end
    if closest_shape ~= nil and #self.interactable:getChildren(16384) == 0 then
        closest_shape = closest_shape:getInteractable()
        if self.auto_child then
            self.interactable:connect(closest_shape)
        end
    end
end

function Counter.server_onFixedUpdate( self, dt )
    local children = self.interactable:getParents(Counter.connectionInput)
    self.resource_children = {}
    self.other_counters = {}
    self.other_resources = {}

    for i,child in pairs(children) do
        if (child.shape.uuid == sm.uuid.new("97b064db-f293-4ade-9c2e-8644d694e850")
            or child.shape.uuid == sm.uuid.new("d2aeffb8-13a8-4bb3-bda1-6f4e2a3765b1")) then
                table.insert(self.resource_children, child)
        end
        if (child.shape.uuid == sm.uuid.new("96de8dce-5b70-4c49-9984-e2c2cd1093da")) then
            table.insert(self.other_counters, child)
        end
        if (child.shape.uuid == sm.uuid.new("9f0f56e8-2c31-4d83-996c-d00a9b296c3f")) then
            if child:isActive() then
                self.offset = self.offset + 1
            end
        end
    end
    local tmp_table = {}
    for k,c in pairs(self.resource_children) do
        table.insert(tmp_table, c)
    end

    if #self.full_resource_table > #tmp_table then
        local diff = #self.full_resource_table - #tmp_table
        self.resource_counter = self.resource_counter + diff
        self.network:sendToClients("client_TickVisual")
    end

    local resource_count = self.resource_counter

    for k,c in pairs(self.other_counters) do
        local pdata = c:getPublicData()
        if pdata ~= nil then
            resource_count = resource_count + pdata.c
        end
    end

    self.interactable:setPublicData({c=resource_count,auto=self.auto_child})

    if (resource_count - self.offset) < 0 then
        self.offset = resource_count
    end
    
    self.full_resource_table = tmp_table

    self.last_sub_children = self.interactable:getChildren()
    for q,g in pairs(self.last_sub_children) do
        if g.shape.uuid == sm.uuid.new("16de3dce-5b50-4c49-9884-e2c2cd1093da") then
            if q <= (resource_count - self.offset) then
                g:setPublicData({active=true})
            else
                g:setPublicData({active=false})
            end
        end
    end
end

function Counter.client_TickVisual(self, dt)
    self.interactable:setUvFrameIndex(6)
    self.interactable:setPoseWeight(0,2)
    self.wait_timer = 4
end

function Counter.client_onFixedUpdate(self, dt)
    if self.wait_timer > 0 then
        self.wait_timer = self.wait_timer - 1
        return
    end
    if self.wait_timer == 0 then
        self.interactable:setUvFrameIndex(0)
        self.interactable:setPoseWeight(0,0)
        self.wait_timer = -1
    end
end

function GetMegaParent( start )
    local parents = start:getParents(16384)
    if #parents > 0 then
        return GetMegaParent(parents[1])
    else
        return start
    end
end