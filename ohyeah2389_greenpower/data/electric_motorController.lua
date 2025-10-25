-- Greenpower F24 CSP Physics Script - Motor Controller Module
-- Authored by ohyeah2389

local MotorController = class("MotorController")

function MotorController:initialize(params)
    self.motor = params.motor                                -- Reference to motor being controlled
    self.minRegenSpeed = params.minRegenSpeed or 0.001       -- Minimum speed for regen (as fraction of base RPM)
    self.regenTorqueFactor = params.regenTorqueFactor or 0.7 -- Max regen torque as fraction of peak torque
    self.mode = "drive"                                      -- Current operating mode
end

function MotorController:determineMode(throttle, rpm)
    if (rpm > 0 and throttle < -0.01) or (rpm < 0 and throttle > 0.01) then
        return "regen"
    end
    return "drive"
end

function MotorController:calculateDriveTorque(throttle, rpm, availableVoltage)
    local motor = self.motor

    -- Ensure we have a reasonable minimum voltage
    if availableVoltage < 5.0 then
        print(string.format("Motor Controller: Insufficient voltage %.1fV, no torque", availableVoltage))
        return 0
    end

    local speedRatio = math.abs(rpm) / motor.baseRPM
    local maxTorqueAtSpeed

    -- Calculate torque limit based on speed
    if speedRatio <= 1.0 then
        -- Constant torque region
        maxTorqueAtSpeed = motor.peakTorque
    else
        -- Constant power region
        maxTorqueAtSpeed = motor.peakTorque / speedRatio
    end

    -- Direct battery connection - voltage will vary with battery SOC
    -- Calculate voltage ratio based on available voltage vs nominal
    local voltageRatio = math.min(availableVoltage / motor.nominalVoltage, 1.0)

    local finalTorque = maxTorqueAtSpeed * throttle * voltageRatio

    -- Enhanced debug output
    --print(string.format("Drive Torque: RPM=%.0f, SpeedRatio=%.2f, MaxT@Speed=%.1fNm, VoltRatio=%.2f, FinalT=%.1fNm", rpm, speedRatio, maxTorqueAtSpeed, voltageRatio, finalTorque))

    return finalTorque
end

function MotorController:calculateRegenTorque(throttle, rpm)
    local motor = self.motor

    -- Only allow regen above minimum speed
    if math.abs(rpm) > (motor.baseRPM * self.minRegenSpeed) then
        local maxRegenTorque = motor.peakTorque * self.regenTorqueFactor
        local speedRatio = rpm / motor.baseRPM

        if speedRatio > 1.0 then
            maxRegenTorque = maxRegenTorque / speedRatio -- Maintain power limit
        end

        return -math.sign(rpm) * maxRegenTorque * math.abs(throttle)
    else
        -- Below minimum speed: provide braking torque without regeneration
        return -math.sign(throttle) * motor.peakTorque * 0.2 * math.abs(throttle)
    end
end

function MotorController:update(throttle, rpm, motorTerminalVoltage, batteryVoltage)
    -- Determine operating mode
    self.mode = self:determineMode(throttle, rpm)

    -- Apply voltage-based limits
    local commandedTorque = 0

    if self.mode == "drive" then
        commandedTorque = self:calculateDriveTorque(throttle, rpm, motorTerminalVoltage)
    else -- regen mode
        commandedTorque = self:calculateRegenTorque(throttle, rpm)
    end

    -- Debug output
    --print(string.format("Motor Controller: Mode=%s, CapV=%.1fV, Throttle=%.1f, Torque=%.1fNm", self.mode, capacitorVoltage, throttle, commandedTorque))

    return commandedTorque, self.mode
end

return MotorController
