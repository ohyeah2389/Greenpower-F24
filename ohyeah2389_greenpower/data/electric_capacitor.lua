-- Greenpower F24 CSP Physics Script - Capacitor Module
-- Authored by ohyeah2389

local Capacitor = class("Capacitor")

function Capacitor:initialize(params)
    self.capacitance = params.capacitance or 1e-6 -- Capacitance in Farads (default 1μF)
    self.voltage = params.initialVoltage or 0     -- Initial voltage across capacitor
    self.current = 0                              -- Current through capacitor
    self.previousVoltage = self.voltage           -- For calculating dV/dt

    -- ESR (equivalent series resistance)
    self.esr = params.esr or 0.001 -- Small ESR in ohms (default 1mΩ)

    -- Energy storage - calculate initial stored energy
    self.storedEnergy = 0.5 * self.capacitance * self.voltage * self.voltage
    
    -- Initialize amperage
    self.amperage = 0
end

function Capacitor:getConductance()
    -- Capacitor should have very low resistance when acting as voltage source
    return 1000.0 -- High conductance = low resistance voltage source
end

function Capacitor:getCurrentContribution()
    -- The circuit solver handles this by making the node a fixed voltage
    return 0
end

function Capacitor:update(voltageDiff, dt)
    if dt <= 0 then return end

    -- If amperage is set by circuit solver, use that (for accumulated current from other components)
    if self.amperage and math.abs(self.amperage) > 0.1 then
        -- Use the accumulated current from circuit solver
        self.current = self.amperage

        -- Limit current to prevent numerical instability
        local maxCurrent = 4000
        self.current = math.clamp(self.current, -maxCurrent, maxCurrent)

        -- Update internal voltage based on current: I = C * dV/dt -> dV = I * dt / C
        local dV = (self.current * dt) / self.capacitance
        
        -- CORRECT Current sign convention: 
        -- Positive current = capacitor discharging (voltage decreases) 
        -- Negative current = capacitor charging (voltage increases)
        -- So dV = -I * dt / C (positive current decreases voltage)
        dV = -dV
        
        -- Limit voltage change per timestep for stability
        local maxDV = 2.0
        dV = math.clamp(dV, -maxDV, maxDV)
        
        -- Update internal capacitor voltage
        local newVoltage = self.voltage + dV
        newVoltage = math.clamp(newVoltage, 0, 80)
        
        self.voltage = newVoltage

        -- Update stored energy
        self.storedEnergy = 0.5 * self.capacitance * self.voltage * self.voltage

        -- FIXED SOC calculation: 30V = 0%, 60V = 100%
        local minVoltage = 30.0
        local maxVoltage = 60.0
        local soc = math.clamp((self.voltage - minVoltage) / (maxVoltage - minVoltage) * 100, 0, 200)

        return string.format("Capacitor: I=%.1fA, Vint=%.1fV, E=%.0fJ, SOC=%.1f%% (%s)\n",
            self.current, self.voltage, self.storedEnergy, soc,
            self.current > 0 and "DISCHARGING" or "CHARGING")
    else
        -- For voltage-driven updates, maintain the capacitor's internal voltage
        -- Don't let the circuit solver override the capacitor's stored voltage
        
        -- FIXED: Don't calculate any current in voltage-driven mode
        -- The capacitor acts as a perfect voltage source
        self.current = 0
        self.amperage = 0
        
        -- Update stored energy based on current internal voltage
        self.storedEnergy = 0.5 * self.capacitance * self.voltage * self.voltage
        
        return string.format("Capacitor: I=%.1fA, Vint=%.1fV, E=%.0fJ (voltage-driven, no current)\n",
            self.current, self.voltage, self.storedEnergy)
    end
end

return Capacitor
