local Switch = class("Switch")


function Switch:initialize(params)
    self.state = params.initialState or false    -- false = open, true = closed
    self.resistance = params.resistance or 0.001 -- Small resistance when closed
end

function Switch:getConductance()
    if self.state then
        return 1 / self.resistance
    else
        return 1e-12 -- Extremely small conductance to ensure complete isolation
    end
end

function Switch:getCurrentContribution()
    return 0 -- it's a switch, it doesn't create energy
end

function Switch:update(voltageDiff, dt)
    -- Calculate current through switch when closed
    if self.state then
        self.amperage = voltageDiff / self.resistance
    else
        self.amperage = 0
    end
end

function Switch:setState(newState)
    self.state = newState
end

return Switch
