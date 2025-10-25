-- Greenpower F24 CSP Physics Script - Electric Motor Module
-- Authored by ohyeah2389

local ElectricMotor = class("ElectricMotor")

function ElectricMotor:initialize(params)
    -- Core physical parameters
    self.nominalVoltage = params.nominalVoltage or 400 -- Nominal voltage (V)
    self.peakPower = params.peakPower or 150000        -- Peak power output (W)
    self.peakTorque = params.peakTorque or 500         -- Peak torque (Nm)
    self.maxRPM = params.maxRPM or 15000               -- Maximum RPM

    -- Calculate derived parameters
    self.baseRPM = (self.peakPower * 60) / (2 * math.pi * self.peakTorque)
    self.kV = self.maxRPM / self.nominalVoltage                        -- Motor velocity constant (RPM/V)
    self.kT = self.peakTorque / (self.peakPower / self.nominalVoltage) -- Torque constant (Nm/A)

    -- Winding characteristics
    self.resistance = (self.nominalVoltage * self.nominalVoltage) / (4 * self.peakPower)
    self.inductance = params.inductance or (self.resistance / 100)

    -- Loss parameters
    self.copperLossFactor = params.copperLossFactor or 1.0
    self.ironLossFactor = params.ironLossFactor or 0.01
    self.mechanicalLossFactor = params.mechanicalLossFactor or 0.005
    self.regenEfficiency = params.regenEfficiency or 0.7

    -- State variables
    self.currentRPM = 0
    self.engineRPM = 0 -- Always connected to engine
    self.currentTorque = 0
    self.currentPower = 0
    self.voltage = 0
    self.amperage = 0
    self.mode = "drive"

    -- External control inputs (set by motor controller)
    self.commandedTorque = 0
    self.externalRPM = 0

    -- Internal drag when not powered
    self.dragTorque = params.dragTorque or 0.1 -- Small drag torque when unpowered
end

-- Always connect motor to engine RPM
function ElectricMotor:setEngineRPM(rpm)
    self.engineRPM = rpm
    self.currentRPM = rpm -- Motor is always mechanically connected
end

-- Calculate actual torque output considering electrical limitations
function ElectricMotor:calculateActualTorque(availableVoltage, dt)
    -- Update voltage
    self.voltage = availableVoltage

    -- If voltage is essentially zero (switch open), no operation possible
    if availableVoltage < 0.5 then -- Very low threshold for switch-open detection
        self.currentTorque = -math.sign(self.engineRPM) * self.dragTorque
        self.currentPower = 0
        self.amperage = 0
        return self.currentTorque
    end

    -- If no command or insufficient voltage, apply drag
    local minOperatingVoltage = self.nominalVoltage * 0.2
    if math.abs(self.commandedTorque) < 0.1 or availableVoltage < minOperatingVoltage then
        -- Motor unpowered - apply drag torque
        local dragDirection = math.sign(self.engineRPM)
        self.currentTorque = -dragDirection * self.dragTorque
        self.currentPower = 0
        self.amperage = 0
        return self.currentTorque
    end

    -- Calculate maximum torque available at current speed and voltage
    local speedRatio = math.abs(self.engineRPM) / self.baseRPM
    local maxTorqueAtSpeed

    if speedRatio <= 1.0 then
        -- Constant torque region
        maxTorqueAtSpeed = self.peakTorque
    else
        -- Constant power region
        maxTorqueAtSpeed = self.peakTorque / speedRatio
    end

    -- Apply voltage derating
    local voltageRatio = math.min(availableVoltage / self.nominalVoltage, 1.0)
    maxTorqueAtSpeed = maxTorqueAtSpeed * voltageRatio

    -- Limit commanded torque to what's physically possible
    local actualTorque = math.clamp(self.commandedTorque, -maxTorqueAtSpeed, maxTorqueAtSpeed)

    -- Calculate power consumption/generation
    if self.mode == "drive" and actualTorque * self.engineRPM >= 0 then
        -- Motor mode - consuming power
        local mechanicalPower = math.abs(actualTorque * self.engineRPM * (2 * math.pi / 60))
        local copperLoss, ironLoss, mechanicalLoss = self:calculateLosses(math.abs(self.engineRPM), math.abs(actualTorque))

        self.currentPower = mechanicalPower + copperLoss + ironLoss + mechanicalLoss
        self.amperage = math.clamp(self.currentPower / math.max(availableVoltage, 1.0), 0, 2000)
    elseif self.mode == "regen" and actualTorque * self.engineRPM < 0 then
        -- Regen mode - generating power
        local mechanicalPower = math.abs(actualTorque * self.engineRPM * (2 * math.pi / 60))
        local copperLoss, ironLoss, mechanicalLoss = self:calculateLosses(math.abs(self.engineRPM), math.abs(actualTorque))

        local recoveredPower = math.max(0, mechanicalPower - ironLoss - mechanicalLoss)
        self.currentPower = -recoveredPower * self.regenEfficiency
        self.amperage = math.clamp(self.currentPower / math.max(availableVoltage, 1.0), -500, 0)
    else
        -- No power transfer
        self.currentPower = 0
        self.amperage = 0
    end

    self.currentTorque = actualTorque
    return actualTorque
end

-- Circuit solver interface methods
function ElectricMotor:getConductance()
    -- Motor acts as a variable resistor based on operating conditions
    local baseResistance = self.resistance

    -- Adjust resistance based on speed (back-EMF effect)
    if math.abs(self.currentRPM) > 0 then
        local backEMF = math.abs(self.currentRPM) / self.kV
        local effectiveVoltage = math.max(self.voltage - backEMF, 0.1)
        local speedFactor = effectiveVoltage / self.nominalVoltage
        baseResistance = baseResistance / math.max(speedFactor, 0.1)
    end

    return 1 / baseResistance
end

function ElectricMotor:getCurrentContribution()
    -- During regen mode, motor acts as a current source
    if self.mode == "regen" and math.abs(self.currentRPM) > 0 then
        -- Calculate generated current based on speed and torque
        local backEMF = math.abs(self.currentRPM) / self.kV
        local generatedCurrent = math.abs(self.currentTorque * self.kT) / self.nominalVoltage
        return -generatedCurrent * self.regenEfficiency -- Negative for charging
    end

    return 0
end

function ElectricMotor:update(voltageDiff, dt)
    -- Store voltage for calculations
    self.voltage = math.abs(voltageDiff)

    -- Use engine RPM (always connected)
    self.currentRPM = self.engineRPM

    -- The actual torque and current calculation should be handled by calculateActualTorque
    -- This method just needs to provide circuit solver interface

    -- If voltage is essentially zero (switch open), absolutely no current
    if self.voltage < 0.5 then
        self.currentTorque = 0
        self.currentPower = 0
        self.amperage = 0
        return string.format("Motor: Switch open, no current\n")
    end

    -- Check if we have a torque command and sufficient voltage
    local minOperatingVoltage = self.nominalVoltage * 0.2
    if math.abs(self.commandedTorque) < 0.1 or self.voltage < minOperatingVoltage then
        -- No torque command or insufficient voltage = no current draw
        self.currentTorque = 0
        self.currentPower = 0
        self.amperage = 0
        return string.format("Motor: No command/insufficient voltage, no current draw\n")
    end

    -- If we have a command, the actual current should already be calculated by calculateActualTorque
    -- Just ensure our stored values are consistent
    if self.currentPower > 0 then
        -- Motor consuming power - calculate current
        self.amperage = math.clamp(self.currentPower / math.max(self.voltage, 1.0), 0, 2000)
    elseif self.currentPower < 0 then
        -- Motor generating power (regen)
        self.amperage = math.clamp(self.currentPower / math.max(self.voltage, 1.0), -500, 0)
    else
        self.amperage = 0
    end

    return string.format("Motor: T=%.1fNm, P=%.1fW, I=%.1fA, V=%.1fV, Mode=%s\n", self.currentTorque, self.currentPower, self.amperage, self.voltage, self.mode)
end

function ElectricMotor:calculateLosses(rpm, torque)
    local angularVelocity = rpm * (2 * math.pi / 60)
    local mechanicalPower = math.abs(torque * angularVelocity)

    -- Calculate various losses
    local copperLoss = (mechanicalPower / self.nominalVoltage) ^ 2 * self.resistance * self.copperLossFactor
    local ironLoss = (rpm / self.maxRPM) ^ 2 * self.peakPower * self.ironLossFactor
    local mechanicalLoss = (rpm / self.maxRPM) ^ 2 * self.peakPower * self.mechanicalLossFactor

    return copperLoss, ironLoss, mechanicalLoss
end

function ElectricMotor:setControlInputs(commandedTorque, rpm, mode)
    self.commandedTorque = commandedTorque
    self.externalRPM = rpm -- Keep for compatibility but use engineRPM primarily
    self.mode = mode or "drive"
end

return ElectricMotor
