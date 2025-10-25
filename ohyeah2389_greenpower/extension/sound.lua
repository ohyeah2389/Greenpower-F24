-- Greenpower F24 CSP Sound Script
-- Authored by ohyeah2389

local car_phys = ac.getCarPhysics(0)

local last_accelbutton = false
local last_horn

local audio_accelbutton = ac.AudioEvent("/cars/ohyeah2389_greenpower/button", true, true)
audio_accelbutton.cameraInteriorMultiplier = 1.0
audio_accelbutton.cameraExteriorMultiplier = 0.4
audio_accelbutton.volume = 1.0
audio_accelbutton:setPosition(vec3(-0.104, 0.725, 0.775), vec3(0, 0, 1), vec3(0, 1, 0))

local audio_hornbutton = ac.AudioEvent("/cars/ohyeah2389_greenpower/button", true, true)
audio_hornbutton.cameraInteriorMultiplier = 1.0
audio_hornbutton.cameraExteriorMultiplier = 0.4
audio_hornbutton.volume = 1.0
audio_hornbutton:setPosition(vec3(0.0752, 0.557, 0.889), vec3(0, 0, 1), vec3(0, 1, 0))

---@diagnostic disable-next-line: duplicate-set-field
function script.update(dt)
    local accelbutton = car.gas > 0.1

    if accelbutton and (not last_accelbutton) then
        audio_accelbutton:setParam("position", 1.0)
        audio_accelbutton:start()
    elseif (not accelbutton) and last_accelbutton then
        audio_accelbutton:setParam("position", 0.0)
        audio_accelbutton:start()
    end

    if car.hornActive and (not last_horn) then
        audio_hornbutton:setParam("position", 1.0)
        audio_hornbutton:start()
    elseif (not car.hornActive) and last_horn then
        audio_hornbutton:setParam("position", 0.0)
        audio_hornbutton:start()
    end

    last_accelbutton = accelbutton
    last_horn = car.hornActive
end