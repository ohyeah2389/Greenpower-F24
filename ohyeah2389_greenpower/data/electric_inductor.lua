-- Greenpower F24 CSP Physics Script - Inductor Module
-- Authored by ohyeah2389

local Inductor = class("Inductor")

function Inductor:initialize(params)
    self.inductance = params.inductance or 1e-3 -- Inductance in Henries (default 1mH)
    self.current = params.initialCurrent or 0   -- Initial current through inductor
    self.voltage = 0                            -- Voltage across inductor
    self.previousCurrent = self.current         -- For calculating dI/dt

    -- DCR (DC resistance)
    self.dcr = params.dcr or 0.1 -- DC resistance in ohms (default 0.1Ω)

    -- Energy storage
    self.storedEnergy = 0.5 * self.inductance * self.current * self.current
end

function Inductor:getConductance()
    local impedance = self.dcr

    -- Add inductive reactance based on recent current change rate
    local dt = 0.001 -- Assume small timestep for reactance calculation
    if dt > 0 then
        local inductiveReactance = 2 * math.pi * self.inductance / dt
        impedance = math.sqrt(self.dcr * self.dcr + inductiveReactance * inductiveReactance)
    end

    return 1 / impedance
end

function Inductor:getCurrentContribution()
    -- Inductors try to maintain current flow
    -- This acts as a current source equal to the previous current
    return self.current
end

function Inductor:update(voltageDiff, dt)
    if dt <= 0 then return end

    -- Inductor voltage: V = L * dI/dt + I * DCR
    -- Rearranging: dI/dt = (V - I * DCR) / L
    local resistiveVoltage = self.current * self.dcr
    local inductiveVoltage = voltageDiff - resistiveVoltage

    -- Calculate current change rate
    local dIdt = inductiveVoltage / self.inductance

    -- Update current using simple Euler integration
    local newCurrent = self.current + (dIdt * dt)

    -- Apply some damping to prevent oscillations
    local dampingFactor = 0.99
    self.current = self.current * dampingFactor + newCurrent * (1 - dampingFactor)

    self.voltage = voltageDiff

    -- Update stored energy: E = 0.5 * L * I²
    self.storedEnergy = 0.5 * self.inductance * self.current * self.current

    -- Store current for next iteration
    self.previousCurrent = self.current

    -- Set amperage for circuit solver
    self.amperage = self.current
end

return Inductor
