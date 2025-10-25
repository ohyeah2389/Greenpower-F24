-- Greenpower F24 CSP Physics Script - Battery Module
-- Authored by ohyeah2389

local Battery = class("Battery")

function Battery:initialize(params)
    -- Ensure proper class identification for circuit solver
    self.class = self.class or {}
    self.class.name = "Battery"

    -- Core parameters
    self.capacity = params.capacity                            -- Watt-hours
    self.ratedVoltage = params.ratedVoltage                    -- Nominal voltage
    self.internalResistance = params.internalResistance or 0.1 -- Internal resistance in ohms
    self.socCurve = params.socCurve                            -- State of charge curve

    -- Performance limits
    self.maxChargePower = params.maxChargePower or (self.capacity * 1.5)     -- Default to 1.5C charge rate
    self.maxDischargePower = params.maxDischargePower or (self.capacity * 3) -- Default to 3C discharge rate

    -- State variables
    self.storedEnergy = self.capacity        -- Start at full charge
    self.soc = 1.0                           -- State of charge (0.0 to 1.0)
    self.voltage = self.ratedVoltage         -- Current open-circuit voltage (EMF)
    self.terminalVoltage = self.ratedVoltage -- Terminal voltage after voltage drop
    self.current = 0                         -- Current in amps (positive = discharging)
    self.amperage = 0                        -- Alias for current (expected by circuit solver)
    self.power = 0                           -- Power in watts
end

-- Circuit solver interface methods
function Battery:getConductance()
    -- Battery conductance is the inverse of internal resistance
    return 1 / math.max(self.internalResistance, 1e-6)
end

function Battery:getCurrentContribution()
    -- Batteries don't typically act as current sources in normal operation
    -- The voltage source behavior is handled by the circuit solver treating
    -- the battery node as a fixed voltage source
    return 0
end

function Battery:update(voltageDiff, dt)
    -- voltageDiff is the voltage across the battery terminals (terminal voltage - EMF)
    -- Positive voltageDiff means terminal voltage > EMF (charging)
    -- Negative voltageDiff means terminal voltage < EMF (discharging)

    -- Calculate current based on voltage difference and internal resistance
    -- I = (V_terminal - V_emf) / R_internal
    self.current = voltageDiff / self.internalResistance
    self.amperage = self.current -- Alias for circuit solver

    -- Calculate power (positive = charging, negative = discharging)
    self.power = self.current * self.voltage

    -- Apply power limits
    if self.power > 0 then -- Charging
        if self.power > self.maxChargePower then
            self.power = self.maxChargePower
            self.current = self.power / self.voltage
            self.amperage = self.current
        end
    else -- Discharging
        if math.abs(self.power) > self.maxDischargePower then
            self.power = -self.maxDischargePower
            self.current = self.power / self.voltage
            self.amperage = self.current
        end
    end

    -- Convert power (watts) to energy (watt-hours) for this timestep
    local energyChange = self.power * (dt / 3600)

    -- Update stored energy (positive power = charging = increasing energy)
    self.storedEnergy = self.storedEnergy + energyChange

    -- Update state of charge
    self.soc = math.clamp(self.storedEnergy / self.capacity, 0.0, 1.0)

    -- Update open-circuit voltage (EMF) based on SoC curve
    self.voltage = self.ratedVoltage * self.socCurve:get(self.soc)

    -- Calculate terminal voltage (what's actually measured at the terminals)
    local voltageDrop = math.abs(self.current) * self.internalResistance
    if self.current > 0 then -- Charging
        self.terminalVoltage = self.voltage + voltageDrop
    else                     -- Discharging
        self.terminalVoltage = self.voltage - voltageDrop
    end

    -- Clamp terminal voltage to reasonable limits
    local minVoltage = self.ratedVoltage * 0.5 -- 50% of rated voltage
    local maxVoltage = self.ratedVoltage * 1.3 -- 130% of rated voltage
    self.terminalVoltage = math.clamp(self.terminalVoltage, minVoltage, maxVoltage)

    return string.format("Battery: SOC=%.1f%%, EMF=%.1fV, Terminal=%.1fV, I=%.1fA, P=%.1fW\n",
        self.soc * 100, self.voltage, self.terminalVoltage, self.current, self.power)
end

-- Legacy method for backward compatibility
function Battery:updateLegacy(power, dt)
    -- Legacy update method that takes power as input
    -- Calculate equivalent voltage difference that would produce this power
    local targetCurrent = power / self.voltage
    local voltageDiff = targetCurrent * self.internalResistance
    return self:update(voltageDiff, dt)
end

-- Circuit solver interface - update from current
function Battery:updateFromCurrent(current, dt)
    -- Set current directly (from circuit solver accumulation)
    self.current = current
    self.amperage = current

    -- Calculate power (positive = charging, negative = discharging)
    self.power = self.current * self.voltage

    -- Apply power limits
    if self.power > 0 then -- Charging
        if self.power > self.maxChargePower then
            self.power = self.maxChargePower
            self.current = self.power / self.voltage
            self.amperage = self.current
        end
    else -- Discharging
        if math.abs(self.power) > self.maxDischargePower then
            self.power = -self.maxDischargePower
            self.current = self.power / self.voltage
            self.amperage = self.current
        end
    end

    -- Convert power (watts) to energy (watt-hours) for this timestep
    local energyChange = self.power * (dt / 3600)

    -- Update stored energy (positive power = charging = increasing energy)
    self.storedEnergy = self.storedEnergy + energyChange

    -- Update state of charge
    self.soc = math.clamp(self.storedEnergy / self.capacity, 0.0, 1.0)

    -- Update open-circuit voltage (EMF) based on SoC curve
    self.voltage = self.ratedVoltage * self.socCurve:get(self.soc)

    -- Calculate terminal voltage (what's actually measured at the terminals)
    local voltageDrop = math.abs(self.current) * self.internalResistance
    if self.current > 0 then -- Charging
        self.terminalVoltage = self.voltage + voltageDrop
    else                     -- Discharging
        self.terminalVoltage = self.voltage - voltageDrop
    end

    -- Clamp terminal voltage to reasonable limits
    local minVoltage = self.ratedVoltage * 0.5 -- 50% of rated voltage
    local maxVoltage = self.ratedVoltage * 1.3 -- 130% of rated voltage
    self.terminalVoltage = math.clamp(self.terminalVoltage, minVoltage, maxVoltage)

    return string.format("Battery: SOC=%.1f%%, EMF=%.1fV, Terminal=%.1fV, I=%.1fA, P=%.1fW\n",
        self.soc * 100, self.voltage, self.terminalVoltage, self.current, self.power)
end

return Battery
