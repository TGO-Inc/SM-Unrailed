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
    self.network:sendToServer("server_connectCounters")
end

function Counter.server_connectCounters ( self )
    local closest_x = nil
    local closest_y = nil
    for _,body in pairs(sm.body.getAllBodies()) do
        for _,_body in pairs(body:getCreationBodies()) do
            for _,shape in pairs(_body:getCreationShapes()) do
                if shape.uuid == self.shape:getShapeUuid() and self.shape ~= shape then
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
                    end
                end
            end
        end
    end
    local p_count = #self.interactable:getParents(16384)
    if p_count <= 0 then
        --print(p_count)
        if closest_x ~= nil then
            --closest_x:setColor(sm.color.new(math.random(0,1),math.random(0,1),math.random(0,1),1))
            closest_x = closest_x:getInteractable()
            --print("X", #closest_x:getChildren())
            if #closest_x:getChildren() <= 0 then
                closest_x:connect(self.interactable)
                sm.event.sendToInteractable(closest_x, "server_connectCounters" )
                --return
            end
        end
        if closest_y ~= nil then
            --closest_y:setColor(sm.color.new(math.random(0,1),math.random(0,1),math.random(0,1),1))
            closest_y = closest_y:getInteractable()
            --print("Y", #closest_y:getChildren())
            if #closest_y:getChildren() <= 0 then
                closest_y:connect(self.interactable)
                sm.event.sendToInteractable(closest_y, "server_connectCounters" )
                --return
            end
        end
        
    end
    --print("====================================================")
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

    self.interactable:setPublicData({c=resource_count})

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