-- Greenpower F24 CSP Physics Script
-- Authored by ohyeah2389

local CircuitSolver = require("script_circuitSolver")
local ElectricComponents = require("script_electric_components")

local sim = ac.getSim()
local car = ac.getCar(0) or 0
local cphys = ac.accessCarPhysics()
local solver = CircuitSolver({ debug = true })

local battery = ElectricComponents.Battery({
    capacity = 840, -- 35 Ah * 12v * 2
    ratedVoltage = 24,
    internalResistance = 0.011,
    socCurve = ac.DataLUT11.load("battery_voltage_soc.lut"),
    maxChargePower = 287.1,   -- 29v (charging voltage, which is cycle voltage * 2) * 9.9A
    maxDischargePower = 6489, -- (24V - (495A * 0.022ohm)) * 495A
})

local electricMotor = ElectricComponents.ElectricMotor({
    nominalVoltage = 24,
    peakPower = 700,   -- W
    peakTorque = 13.6, -- Nm
    maxRPM = 6000,
    resistance = 1.0,
    copperLossFactor = 0.8,
    ironLossFactor = 0.01
})

-- Simple switch controlled by throttle
local throttleSwitch = ElectricComponents.Switch({
    initialState = false,
    resistance = 0.001 -- Very low resistance when closed
})

-- Node setup
local ground = solver:addNode(0)
local batteryBus = solver:addNode()
local motorBus = solver:addNode()

-- Connect components: battery -> switch -> motor -> ground
solver:addComponent(battery, batteryBus, ground)
solver:addComponent(throttleSwitch, batteryBus, motorBus)
solver:addComponent(electricMotor, motorBus, ground)

---@diagnostic disable-next-line: duplicate-set-field
function script.reset()
    battery.storedEnergy = battery.capacity
end

script.reset()
ac.onCarJumped(0, script.reset)

---@diagnostic disable-next-line: duplicate-set-field
function script.update(dt)
    -- Always connect motor to engine RPM
    electricMotor:setEngineRPM(car.rpm)

    -- Control switch with gas pedal
    local switchClosed = cphys.gas > 0.1
    throttleSwitch:setState(switchClosed)

    -- Set motor to always try to produce torque when powered (simple brushed motor behavior)
    local commandedTorque = switchClosed and 13.6 or 0 -- Full torque when switch closed, none when open
    electricMotor:setControlInputs(commandedTorque, car.rpm, "drive")

    local result = solver:solve(dt)
    local debugOutput = {}

    -- Solver result output
    table.insert(debugOutput, "Solver returned: " .. tostring(result))
    if result then
        table.insert(debugOutput, tostring(result))
    else
        table.insert(debugOutput, "Solver returned nil!")
    end

    local batteryVoltage = battery.voltage
    local motorVoltage = solver.nodes[motorBus].voltage

    -- Debug switch and motor state
    if switchClosed then
        table.insert(debugOutput, string.format("Switch CLOSED (gas=%.2f) - motor powered", cphys.gas))
    else
        table.insert(debugOutput, "Switch OPEN - motor unpowered")
    end

    table.insert(debugOutput, string.format("Voltages: Battery=%.1fV, Motor=%.1fV", batteryVoltage, motorVoltage))

    -- Motor calculates actual torque output based on electrical conditions
    local actualTorque = electricMotor:calculateActualTorque(motorVoltage, dt)
    table.insert(debugOutput, string.format("Motor: voltage=%.1fV, torque=%.1fNm, power=%.1fW, current=%.1fA",
        motorVoltage, actualTorque, electricMotor.currentPower, electricMotor.amperage))

    table.insert(debugOutput, string.format("Battery: current=%.1fA, power=%.1fW, SOC=%.1f%%",
        battery.amperage, battery.power, battery.soc * 100))

    -- Apply the motor's calculated torque to the car
    ac.setExtraTorque(actualTorque)

    -- Single print statement with all debug information
    --print(table.concat(debugOutput, " | "))

    ac.debug("mguTorque", actualTorque)
    ac.debug("switchState", switchClosed)
    ac.debug("motorVoltage", motorVoltage)

    ac.debug("energyStorageSystem.voltage", battery.voltage)

    -- SOC calculation
    local currentVoltage = battery.voltage
    local minVoltage = 12.0 -- 0% SOC
    local maxVoltage = 24.0 -- 100% SOC
    local soc = math.clamp((currentVoltage - minVoltage) / (maxVoltage - minVoltage) * 100, 0, 200)

    ac.debug("energyStorageSystem.voltage", battery.voltage)
    ac.debug("energyStorageSystem.soc", soc)
    ac.debug("energyStorageSystem.storedEnergy", battery.storedEnergy)
    ac.debug("energyStorageSystem.current", battery.amperage)
end
