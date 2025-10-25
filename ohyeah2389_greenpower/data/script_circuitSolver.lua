-- Greenpower F24 CSP Physics Script - Circuit Solver Module
-- Modified Nodal Analysis Implementation
-- Authored by ohyeah2389


local matrix = require('script_matrix')


local CircuitSolver = class("CircuitSolver")


function CircuitSolver:initialize(params)
    params = params or {}
    self.nodes = {}
    self.components = {}
    self.nextNodeId = 1
    self.groundNodeId = 1 -- Node 1 is always ground (0V)
    self.batteryPos = nil -- Store battery positive node
    self.battery = nil    -- Store battery component
    self.debug = params.debug or false
end

function CircuitSolver:addNode(fixedVoltage)
    local nodeId = self.nextNodeId
    self.nextNodeId = self.nextNodeId + 1
    self.nodes[nodeId] = {
        voltage = fixedVoltage or 0,
        connections = {},
        isFixed = fixedVoltage ~= nil,
        fixedVoltage = fixedVoltage or 0
    }
    return nodeId
end

function CircuitSolver:addComponent(component, nodeA, nodeB)
    local debug_output = ""

    -- Debug what we're getting
    if self.debug then
        debug_output = debug_output .. string.format("Adding component: %s\n",
            component.class and component.class.name or "NO CLASS NAME")
        if component.class then
            debug_output = debug_output .. string.format("  Class exists, name: %s\n", component.class.name or "NIL")
        else
            debug_output = debug_output .. "  No class found\n"
        end
    end

    -- Track battery component and its positive terminal
    if component.class and component.class.name == "Battery" then
        if self.debug then
            debug_output = debug_output .. "Found battery component, positive terminal at node " .. nodeA .. "\n"
        end
        self.battery = component
        self.batteryPos = nodeA
        -- Set initial node voltages for battery
        self.nodes[nodeA].voltage = component.voltage
        self.nodes[nodeB].voltage = 0
        -- Also track capacitors as energy storage devices
    elseif component.class and component.class.name == "Capacitor" then
        if self.debug then
            debug_output = debug_output .. "Found capacitor component, positive terminal at node " .. nodeA .. "\n"
        end
        -- If no battery exists, use capacitor as primary energy storage
        if not self.battery then
            self.battery = component
            self.batteryPos = nodeA
            -- Set initial node voltages for capacitor
            self.nodes[nodeA].voltage = component.voltage
            self.nodes[nodeB].voltage = 0
        end
        -- Handle DC-DC converter as a voltage source
    elseif component.class and component.class.name == "DCDCConverter" then
        if self.debug then
            debug_output = debug_output .. "Found DC-DC converter component, setting output node as voltage source\n"
        end
        -- DC-DC converter output (nodeB) should be a fixed voltage source
        -- We'll set this voltage in the solve loop, not here
    else
        -- Try alternative detection methods
        if component.capacitance then
            if self.debug then
                debug_output = debug_output .. string.format("Found capacitor by capacitance property, voltage=%.1fV, positive terminal at node %d\n",
                    component.voltage, nodeA)
            end
            if not self.battery then
                self.battery = component
                self.batteryPos = nodeA
                self.nodes[nodeA].voltage = component.voltage
                self.nodes[nodeB].voltage = 0
                if self.debug then
                    debug_output = debug_output .. string.format("Set capacitor node %d to %.1fV\n", nodeA, component.voltage)
                end
            end
        elseif component.peakPower then
            if self.debug then
                debug_output = debug_output .. "Found motor by peakPower property\n"
            end
        elseif component.maxPower and component.efficiency then
            if self.debug then
                debug_output = debug_output .. "Found DC-DC converter by maxPower and efficiency properties\n"
            end
            -- DC-DC converter found - we'll handle it in the solve loop
        end
    end

    table.insert(self.components, {
        component = component,
        nodeA = nodeA,
        nodeB = nodeB,
        name = component.class and component.class.name or (component.capacitance and "Capacitor" or (component.peakPower and "ElectricMotor" or "Unknown"))
    })

    return debug_output
end

function CircuitSolver:solve(dt)
    local debug_output = ""

    -- Add error handling
    local success, result = pcall(function()
        return self:solveInternal(dt)
    end)

    if success then
        return result
    else
        return "ERROR in circuit solver: " .. tostring(result)
    end
end

function CircuitSolver:solveInternal(dt)
    local debug_output = ""

    self.debug = {
        nodes = {},
        components = {},
        battery = {
            voltage = 0,
            current = 0,
            power = 0,
            regenComponents = {}
        }
    }

    -- Track node voltages
    for nodeId, node in pairs(self.nodes) do
        self.debug.nodes[nodeId] = {
            voltage = node.voltage,
            isFixed = node.isFixed,
            connections = #node.connections
        }
    end

    -- Set energy storage as voltage source BEFORE matrix building
    if self.battery and self.batteryPos then
        self.nodes[self.batteryPos].isFixed = true
        self.nodes[self.batteryPos].fixedVoltage = self.battery.voltage
        self.nodes[self.batteryPos].voltage = self.battery.voltage
        if self.debug then
            debug_output = debug_output .. string.format("Set capacitor node %d as fixed voltage source at %.1fV\n",
                self.batteryPos, self.battery.voltage)
        end
    end

    -- Handle DC-DC converter voltage sources
    for _, comp in ipairs(self.components) do
        local isDCDC = (comp.component.class and comp.component.class.name == "DCDCConverter") or
            (comp.component.maxPower and comp.component.efficiency)

        if isDCDC and comp.component.enabled then
            -- Make sure the converter knows its input voltage
            local inputVoltage = self.nodes[comp.nodeA].voltage
            comp.component.inputVoltage = inputVoltage

            -- Only set as voltage source if input voltage is sufficient
            if inputVoltage >= comp.component.minInputVoltage then
                -- Calculate what the output voltage should be
                local targetOutput = comp.component.targetOutputVoltage or 48.0
                comp.component.outputVoltage = targetOutput

                -- Set the output node as a fixed voltage source
                self.nodes[comp.nodeB].isFixed = true
                self.nodes[comp.nodeB].fixedVoltage = targetOutput
                self.nodes[comp.nodeB].voltage = targetOutput

                if self.debug then
                    debug_output = debug_output .. string.format("Set DC-DC converter output node %d as fixed voltage source at %.1fV\n",
                        comp.nodeB, targetOutput)
                end
            else
                -- Input voltage too low - converter is off
                comp.component.outputVoltage = 0
                if self.debug then
                    debug_output = debug_output .. string.format("DC-DC converter input voltage %.1fV too low, converter off\n", inputVoltage)
                end
            end
        end
    end

    -- Track component states
    for _, comp in ipairs(self.components) do
        if comp.component.mode == "regen" then
            -- Calculate motor-side power
            local motorVoltage = math.abs(comp.component.voltage)
            local motorCurrent = math.abs(comp.component.amperage)
            local motorPower = motorVoltage * motorCurrent

            -- Calculate battery-side power with losses
            local efficiency = comp.component.regenEfficiency or 0.7 -- Default to 70% if not specified
            local batteryPower = motorPower * efficiency

            -- Calculate battery current from power (P = VI)
            local currentContribution = 0
            if self.battery and self.battery.voltage > 0 then
                local batteryCurrent = batteryPower / self.battery.voltage
                -- Ensure current is negative for charging and reasonable
                currentContribution = -math.min(batteryCurrent, motorCurrent)
            end

            -- Store debug info
            if self.debug then
                table.insert(self.debug.battery.regenComponents, {
                    name = comp.name,
                    motorVoltage = motorVoltage,
                    motorCurrent = motorCurrent,
                    motorPower = motorPower,
                    batteryPower = batteryPower,
                    efficiency = efficiency,
                    currentContribution = currentContribution
                })
            end
        end

        table.insert(self.debug.components, {
            name = comp.name,
            nodeA = comp.nodeA,
            nodeB = comp.nodeB,
            voltage = comp.component.voltage,
            current = comp.component.amperage,
            mode = comp.component.mode,
            conductance = comp.component:getConductance()
        })
    end

    -- Count non-ground, non-fixed nodes
    local n = 0
    local nodeToIndex = {} -- Map node IDs to matrix indices
    local indexToNode = {} -- Map matrix indices to node IDs

    -- Build node mapping, skipping ground and fixed voltage nodes
    for nodeId = 2, self.nextNodeId - 1 do
        if not self.nodes[nodeId].isFixed then
            n = n + 1
            nodeToIndex[nodeId] = n
            indexToNode[n] = nodeId
        end
    end

    -- If no free variables, that's OK - all voltages are determined
    if n < 1 then
        if self.debug then
            debug_output = debug_output .. "No free nodes to solve, all nodes are fixed voltage sources\n"
        end
        -- Skip matrix solving but continue with component updates
    else
        -- Create and solve matrices only if there are free variables
        local G = matrix.new(n, n)
        local I = matrix.new(n, 1)

        -- Build matrices
        for _, comp in ipairs(self.components) do
            local nodeA = comp.nodeA
            local nodeB = comp.nodeB
            local conductance = comp.component:getConductance()
            if conductance < 1e-12 then
                conductance = 1e-12
            end

            -- Get current contribution from component
            local currentContribution = comp.component:getCurrentContribution()

            -- Handle connections to non-fixed nodes
            if nodeToIndex[nodeA] then
                local idxA = nodeToIndex[nodeA]
                G[idxA][idxA] = G[idxA][idxA] + conductance
                -- Add current contribution to node A
                I[idxA][1] = I[idxA][1] + currentContribution

                -- Current contribution from fixed nodes
                if self.nodes[nodeB].isFixed then
                    I[idxA][1] = I[idxA][1] + conductance * self.nodes[nodeB].fixedVoltage
                end
            end

            if nodeToIndex[nodeB] then
                local idxB = nodeToIndex[nodeB]
                G[idxB][idxB] = G[idxB][idxB] + conductance
                -- Add current contribution to node B (opposite direction)
                I[idxB][1] = I[idxB][1] - currentContribution

                -- Current contribution from fixed nodes
                if self.nodes[nodeA].isFixed then
                    I[idxB][1] = I[idxB][1] + conductance * self.nodes[nodeA].fixedVoltage
                end
            end

            -- Connection between two non-fixed nodes
            if nodeToIndex[nodeA] and nodeToIndex[nodeB] then
                local idxA = nodeToIndex[nodeA]
                local idxB = nodeToIndex[nodeB]
                G[idxA][idxB] = G[idxA][idxB] - conductance
                G[idxB][idxA] = G[idxB][idxA] - conductance
            end
        end

        -- Debug matrix state
        --print("Conductance Matrix G:")
        --for i = 1, n do
        --    local row = ""
        --    for j = 1, n do
        --        row = row .. string.format(" %.3f", G[i][j])
        --    end
        --    print(row)
        --end
        --
        --print("Current Vector I:")
        --for i = 1, n do
        --    print(string.format("%.3f", I[i][1]))
        --end

        -- Solve system GV = I for node voltages
        local V = matrix.solve(G, I)

        -- Check for NaN values
        if V then
            for i = 1, n do
                if V[i] and V[i][1] then
                    local voltage = V[i][1]
                    if voltage ~= voltage then -- NaN check
                        if self.debug then
                            debug_output = debug_output .. string.format("NaN detected at node %d\n", indexToNode[i])
                        end
                        V[i][1] = 0 -- Set to 0 if NaN
                    end
                end
            end
        end

        -- Update node voltages from matrix solution
        for i = 1, n do
            local nodeId = indexToNode[i]
            if V and V[i] and V[i][1] then
                self.nodes[nodeId].voltage = V[i][1]
            else
                self.nodes[nodeId].voltage = 0
            end
        end
    end

    -- Debug battery current calculation
    if self.battery then
        if self.debug then
            debug_output = debug_output .. "Battery found, current before update: " .. (self.battery.amperage or 0) .. "\n"
        end
        -- CRITICAL FIX: Reset accumulated current at start of each solve cycle
        self.battery.amperage = 0
        if self.debug then
            debug_output = debug_output .. "Reset battery current to 0 for this solve cycle\n"
        end
    elseif self.debug then
        debug_output = debug_output .. "No battery component found!\n"
    end

    -- Continue with component updates regardless
    if self.debug then
        debug_output = debug_output .. "\nNode voltages:\n"
        for nodeId, node in pairs(self.nodes) do
            debug_output = debug_output .. string.format("Node %d: %.1fV\n", nodeId, node.voltage)
        end
    end

    -- Update components with solved voltages and calculate total currents
    for _, comp in ipairs(self.components) do
        local vA = self.nodes[comp.nodeA].voltage
        local vB = self.nodes[comp.nodeB].voltage
        local vDiff = vB - vA

        if self.debug then
            debug_output = debug_output .. string.format("Component %s: vA=%.1fV, vB=%.1fV, vDiff=%.1fV\n",
                comp.name, -- Use stored component name
                vA, vB, vDiff)
        end

        -- Special handling for DC-DC converter to enforce current coupling
        local isDCDC = (comp.component.class and comp.component.class.name == "DCDCConverter") or
            (comp.component.maxPower and comp.component.efficiency)

        if isDCDC then
            -- For DC-DC converter, we need to update it AFTER the motor to get proper current coupling
            -- Skip for now, we'll handle it after the motor
        elseif comp.component == self.battery then
            -- Skip battery update here - it's acting as a voltage source
            if self.debug then
                debug_output = debug_output .. string.format("Skipping battery update (voltage source)\n")
            end
        else
            -- Update non-DC-DC, non-battery components normally
            comp.component:update(vDiff, dt)

            -- Debug current from each component
            if self.debug and comp.component.amperage then
                debug_output = debug_output .. string.format("  -> Component %s amperage: %.1fA\n",
                    comp.name, comp.component.amperage)
            end
        end

        -- Calculate branch current for energy storage (battery or capacitor)
        if self.battery and (comp.nodeA == self.batteryPos or comp.nodeB == self.batteryPos) then
            -- Skip the battery itself - it shouldn't contribute to its own current
            if comp.component ~= self.battery and comp.component.amperage and not isDCDC then
                local currentContribution = comp.component.amperage

                -- Debug before limiting
                if self.debug then
                    debug_output = debug_output .. string.format("  -> Raw current contribution: %.1fA\n", currentContribution)
                end

                -- Limit current contribution to prevent instability
                currentContribution = math.clamp(currentContribution, -4000, 4000)

                if self.debug then
                    debug_output = debug_output .. string.format("  -> Clamped current contribution: %.1fA\n", currentContribution)
                end

                -- CORRECT: Add current contributions with proper signs
                -- If component nodeA is connected to battery positive, current flows OUT of battery (positive = discharging)
                -- If component nodeB is connected to battery positive, current flows INTO battery (negative = charging)
                if comp.nodeA == self.batteryPos then
                    -- Current flowing from battery to component = positive current = discharging
                    self.battery.amperage = (self.battery.amperage or 0) + currentContribution
                else
                    -- Current flowing from component to battery = negative contribution = charging
                    self.battery.amperage = (self.battery.amperage or 0) - currentContribution
                end

                if self.debug then
                    debug_output = debug_output .. string.format(
                        "Component %s contributing %.1fA to energy storage (total now: %.1fA)\n",
                        comp.name, currentContribution, self.battery.amperage
                    )
                end
            elseif comp.component == self.battery and self.debug then
                debug_output = debug_output .. string.format("Skipping battery self-contribution\n")
            end
        end
    end

    -- Now handle DC-DC converter with proper current coupling
    for _, comp in ipairs(self.components) do
        local isDCDC = (comp.component.class and comp.component.class.name == "DCDCConverter") or
            (comp.component.maxPower and comp.component.efficiency)

        if isDCDC then
            -- Find the motor connected to the DC-DC converter output
            local motorCurrent = 0
            for _, motorComp in ipairs(self.components) do
                if motorComp.nodeA == comp.nodeB and motorComp.component.peakPower then
                    -- Motor is connected to DC-DC output
                    motorCurrent = motorComp.component.amperage or 0
                    break
                end
            end

            -- Update DC-DC converter with motor current constraint
            local vA = self.nodes[comp.nodeA].voltage
            local vB = self.nodes[comp.nodeB].voltage
            local vDiff = vB - vA

            -- Set the DC-DC converter's output current to match motor current
            comp.component.outputCurrent = motorCurrent

            -- Update the DC-DC converter
            comp.component:update(vDiff, dt)

            -- Add DC-DC converter input current to energy storage with CORRECT signs
            if self.battery and (comp.nodeA == self.batteryPos or comp.nodeB == self.batteryPos) then
                local currentContribution = comp.component.amperage
                currentContribution = math.clamp(currentContribution, -4000, 4000)

                -- DC-DC converter nodeA is connected to capacitor (battery)
                -- Positive DC-DC input current = drawing from capacitor = positive capacitor current = discharging
                if comp.nodeA == self.batteryPos then
                    self.battery.amperage = (self.battery.amperage or 0) + currentContribution
                else
                    self.battery.amperage = (self.battery.amperage or 0) - currentContribution
                end

                if self.debug then
                    debug_output = debug_output .. string.format(
                        "DC-DC converter contributing %.1fA to energy storage (motor draws %.1fA)\n",
                        currentContribution, motorCurrent
                    )
                end
            end
        end
    end

    -- Now update energy storage with accumulated current
    if self.battery then
        -- Additional safeguard: clamp the total accumulated current
        local totalCurrent = math.clamp(self.battery.amperage or 0, -4000, 4000)

        if self.debug then
            debug_output = debug_output .. string.format("Final energy storage current: %.1fA\n", totalCurrent)
        end

        -- Use current-driven update method for circuit solver
        local storage_debug = self.battery:updateFromCurrent(totalCurrent, dt)
        if self.debug then
            debug_output = debug_output .. storage_debug
        end
    end

    return debug_output
end

return CircuitSolver
