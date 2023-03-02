CounterDisplay = class()
CounterDisplay.maxParentCount = 1
CounterDisplay.maxChildCount = 9999
CounterDisplay.connectionInput = 16384
CounterDisplay.connectionOutput = sm.interactable.connectionType.logic
CounterDisplay.poseWeightCount = 1

CounterDisplay.colorHighlight = sm.color.new( "#5147bf" )
CounterDisplay.colorNormal = sm.color.new( "#30278c" )

function CounterDisplay.server_onCreate(self, dt)
    self.interactable:setActive(false)
    self.state = false
end

function CounterDisplay.server_onFixedUpdate(self, dt)
    local data = self.interactable:getPublicData()
    if data ~= nil then
        isActive = data.active and #self.interactable:getParents() > 0
        self.interactable:setActive(isActive)
        if isActive and isActive ~= self.state then
            self.state = isActive
            self.network:sendToClients("client_turnOn")
        elseif not isActive and isActive ~= self.state then
            self.state = isActive
            self.network:sendToClients("client_turnOff")
        end
    end
end

function CounterDisplay.client_turnOn(self)
    self.interactable:setUvFrameIndex(6)
    self.interactable:setPoseWeight(0,2)
end

function CounterDisplay.client_turnOff(self)
    self.interactable:setUvFrameIndex(0)
    self.interactable:setPoseWeight(0,0)
end