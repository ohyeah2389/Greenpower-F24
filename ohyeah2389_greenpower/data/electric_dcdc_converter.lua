-- Greenpower F24 CSP Physics Script - DC-DC Converter Module
-- Authored by ohyeah2389

local DCDCConverter = class("DCDCConverter")

function DCDCConverter:initialize(params)
    -- Conversion parameters
    self.conversionRatio = params.conversionRatio or 0.5 -- Vout/Vin ratio
    self.efficiency = params.efficiency or 0.90          -- Power conversion efficiency
    self.maxPower = params.maxPower or 1000              -- Maximum power rating (W)

    -- Operating modes
    self.mode = params.mode or "buck" -- "buck", "boost", or "buck-boost"

    -- Control parameters
    self.enabled = params.enabled or true
    self.minInputVoltage = params.minInputVoltage or 10  -- Minimum input voltage to operate
    self.maxInputVoltage = params.maxInputVoltage or 100 -- Maximum input voltage

    -- Switching characteristics
    self.switchingFrequency = params.switchingFrequency or 100000 -- 100kHz default
    self.rippleFactor = params.rippleFactor or 0.01               -- 1% ripple

    -- Internal state
    self.inputVoltage = 0
    self.outputVoltage = 0
    self.inputCurrent = 0
    self.outputCurrent = 0
    self.inputPower = 0
    self.outputPower = 0
    self.powerLoss = 0

    -- Equivalent circuit parameters
    self.inputResistance = 0.1   -- Input side resistance
    self.outputResistance = 0.05 -- Output side resistance

    -- State variables for circuit solver
    self.voltage = 0
    self.amperage = 0

    -- Voltage regulation parameters
    self.targetOutputVoltage = params.targetOutputVoltage or 48.0
    self.voltageRegulationEnabled = params.voltageRegulationEnabled or true
    self.regulationError = 0
    self.integralError = 0

    -- PI controller parameters for voltage regulation
    self.kP = params.kP or 0.1  -- Proportional gain
    self.kI = params.kI or 0.01 -- Integral gain

    -- Add smoothing for stability
    self.previousOutputVoltage = 0
    self.voltageSmoothing = 0.8 -- Smoothing factor (0.8 = 80% old value, 20% new)
end

function DCDCConverter:getConductance()
    if not self.enabled or self.inputVoltage < self.minInputVoltage then
        return 1e-9
    end

    -- Simple resistive model - let the circuit solver handle voltage source behavior
    local equivalentResistance = self.inputResistance + (self.outputResistance / (self.conversionRatio * self.conversionRatio))
    return 1 / equivalentResistance
end

function DCDCConverter:getCurrentContribution()
    if not self.enabled or self.inputVoltage < self.minInputVoltage then
        return 0
    end

    -- We need to estimate how much current the motor will draw at 48V
    -- This is a simplified approach - in reality we'd need iterative solving

    -- If we have stored information about motor current from previous cycle
    if self.outputCurrent and self.outputCurrent > 0 then
        -- Calculate input current needed to supply this output current
        local inputCurrentNeeded = (self.outputVoltage * self.outputCurrent) / (self.inputVoltage * self.efficiency)

        -- Limit to reasonable values
        inputCurrentNeeded = math.clamp(inputCurrentNeeded, 0, self.maxPower / self.inputVoltage)

        return inputCurrentNeeded
    end

    return 0
end

function DCDCConverter:calculateConversion(inputVoltage, outputLoad)
    -- Determine actual output voltage based on mode and input conditions
    local targetOutputVoltage = inputVoltage * self.conversionRatio

    -- Apply operating limits
    if inputVoltage < self.minInputVoltage or inputVoltage > self.maxInputVoltage then
        return 0, 0, 0 -- Shutdown
    end

    -- Calculate maximum output current based on power limit
    local maxOutputCurrent = self.maxPower / targetOutputVoltage

    -- Actual output current is limited by load and power rating
    local actualOutputCurrent = math.min(outputLoad, maxOutputCurrent)

    -- Calculate actual power transfer
    local outputPower = targetOutputVoltage * actualOutputCurrent
    local inputPower = outputPower / self.efficiency
    local inputCurrent = inputPower / inputVoltage

    return targetOutputVoltage, actualOutputCurrent, inputCurrent
end

function DCDCConverter:updateControlLoop(inputVoltage, targetOutputVoltage)
    if not self.voltageRegulationEnabled then return end

    self.targetOutputVoltage = targetOutputVoltage

    -- Calculate required conversion ratio to achieve target output voltage
    if inputVoltage > self.minInputVoltage then
        local requiredRatio = self.targetOutputVoltage / inputVoltage

        -- Clamp ratio to reasonable limits (0.2 to 2.0 for buck-boost)
        requiredRatio = math.clamp(requiredRatio, 0.2, 2.0)

        -- Apply smoothing to prevent rapid ratio changes
        local smoothedRatio = self.conversionRatio * self.voltageSmoothing +
            requiredRatio * (1 - self.voltageSmoothing)

        self.conversionRatio = smoothedRatio

        -- Debug output
        --print(string.format("DC-DC Converter: Input=%.1fV, Target=%.1fV, Ratio=%.3f", inputVoltage, targetOutputVoltage, smoothedRatio))
    else
        -- Input voltage too low - converter shuts down
        self.conversionRatio = 0
        --print("DC-DC Converter: Input voltage too low, shutting down")
    end
end

function DCDCConverter:update(voltageDiff, dt)
    self.voltage = voltageDiff

    if not self.enabled or self.inputVoltage < self.minInputVoltage then
        -- Converter is off
        self.outputVoltage = 0
        self.inputCurrent = 0
        self.outputCurrent = 0
        self.inputPower = 0
        self.outputPower = 0
        self.powerLoss = 0
        self.amperage = 0
        return string.format("DC-DC Converter: OFF (Vin=%.1fV < %.1fV)\n", self.inputVoltage, self.minInputVoltage)
    end

    -- Output current is set by the circuit solver based on motor demand
    -- Calculate input current based on power conservation
    if self.outputVoltage > 0 and self.inputVoltage > 0 and math.abs(self.outputCurrent) > 0.1 then
        -- Calculate power flow with proper signs
        self.outputPower = self.outputVoltage * self.outputCurrent

        if self.outputCurrent > 0 then
            -- Motor drawing power (motoring) - we consume power from input
            self.inputPower = self.outputPower / self.efficiency
        else
            -- Motor generating power (regen) - we send power to input
            -- FIXED: In regen, motor generates power, converter receives it and sends it to capacitor
            -- Motor power (negative) goes through converter with efficiency loss
            self.inputPower = self.outputPower * self.efficiency -- Both negative, so inputPower < outputPower in magnitude
        end

        self.inputCurrent = self.inputPower / self.inputVoltage
        self.powerLoss = math.abs(self.inputPower) - math.abs(self.outputPower)

        -- Limit current to converter's power rating
        local maxCurrent = self.maxPower / self.inputVoltage
        if math.abs(self.inputCurrent) > maxCurrent then
            local limitFactor = maxCurrent / math.abs(self.inputCurrent)
            self.inputCurrent = self.inputCurrent * limitFactor
            self.outputCurrent = self.outputCurrent * limitFactor
            self.inputPower = self.inputVoltage * self.inputCurrent
            self.outputPower = self.outputVoltage * self.outputCurrent
            self.powerLoss = math.abs(self.inputPower) - math.abs(self.outputPower)
        end
    else
        self.outputCurrent = 0
        self.outputPower = 0
        self.inputPower = 0
        self.inputCurrent = 0
        self.powerLoss = 0
    end

    -- Set current for circuit solver (input side current draw)
    self.amperage = self.inputCurrent

    -- Debug output with corrected efficiency
    local efficiency = 0
    if math.abs(self.outputPower) > 1 then
        efficiency = (math.abs(self.inputPower) / math.abs(self.outputPower)) * 100
    end

    return string.format("DC-DC: Vin=%.1fV, Vout=%.1fV, Iin=%.1fA, Iout=%.1fA, Pin=%.0fW, Pout=%.0fW, Eff=%.1f%%\n",
        self.inputVoltage, self.outputVoltage, self.inputCurrent, self.outputCurrent,
        self.inputPower, self.outputPower, efficiency)
end

-- Additional utility functions
function DCDCConverter:setConversionRatio(ratio)
    self.conversionRatio = math.clamp(ratio, 0.01, 10.0) -- Reasonable limits
end

function DCDCConverter:setEnabled(enabled)
    self.enabled = enabled
end

function DCDCConverter:getEfficiencyAtLoad(loadPercentage)
    -- Efficiency curve - typically highest at mid-load
    local baseEfficiency = self.efficiency
    local loadFactor = loadPercentage / 100

    -- Simple efficiency curve (peak at 50% load)
    local efficiencyMultiplier = 1.0 - 0.1 * math.abs(loadFactor - 0.5)

    return baseEfficiency * efficiencyMultiplier
end

return DCDCConverter
