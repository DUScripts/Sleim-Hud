showWeapons            = true  --export: Shows Weapon Widgets in 3rd person
showShield             = true  --export: shows Shield Status
showAllies             = true  --export: adds info about allies
showThreats            = true  --export: adds info about Threats
printSZContacts        = false --export: print new Contacs in Safezone, default off
printLocationOnContact = true  --export: print own location on new target
showTime               = true  --export: Shows Time when new Targets enter radar range or leave
maxAllies              = 10    --export: max Amount for detailed info about Allies, reduce if overlapping with threat info
tempRadarTime          = 200   --export: temporary Radar time in seconds until it gets destroyed
printHitAndMiss        = true  --export:
autoTargets            = false
lshiftPressed          = false
probil                 = 0
targetSpeed            = 0
oldSpeed               = 0
targetDistance         = 0
oldTargetDistance      = 0
targetName             = "Target"
speedChangeIcon        = ""
distanceChangeIcon     = ""
maxCoreStress          = core.getMaxCoreStress()
venting                = ""
stressBarHeight        = "5"
newRadarContacts       = {}
newRadarCounter        = 0
newTargetId            = 0
healthHtml             = ""
alliesHtml             = ""
threatsHtml            = ""
html                   = ""
allies                 = {}
threats                = {}
zone                   = construct.isInPvPZone()
radar                  = radar_1
screenHeight           = system.getScreenHeight()
screenWidth            = system.getScreenWidth()
if radar_size == 0 then
    system.print("Connect a space radar and run config again!")
    unit.exit()
end
if weapon_size == 0 then
    system.print("No Weapons connected")
    unit.exit()
end
local kSkipCharSet = { ["O"] = true,["Q"] = true,["0"] = true }
local kCharSet = {}

local function addRangeToCharSet(a, b)
    for i = a, b do
        local c = string.char(i)
        if not kSkipCharSet[c] then
            kCharSet[#kCharSet + 1] = c
        end
    end
end

-- 0 - 9
addRangeToCharSet(48, 57)
-- A - Z
addRangeToCharSet(65, 90)

local kCharSetSize = #kCharSet

local function getHash(x)
    if x == nil then
        return 0
    end
    x = ((x >> 16) ~ x) * 0x45d9f3b
    x = ((x >> 16) ~ x) * 0x45d9f3b
    x = (x >> 16) ~ x
    if x < 0 then x = ~x end
    return x
end

function getShortName(id)
    local seed = getHash(id) % 8388593
    local a = (seed * 653276) % 8388593
    local b = (a * 653276) % 8388593
    local c = (b * 653276) % 8388593
    return kCharSet[a % kCharSetSize + 1] .. kCharSet[b % kCharSetSize + 1] .. kCharSet[c % kCharSetSize + 1]
end

function seconds_to_clock(time_amount)
    local start_seconds = time_amount
    local start_minutes = math.modf(start_seconds / 60)
    local seconds = start_seconds - start_minutes * 60
    local start_hours = math.modf(start_minutes / 60)
    local minutes = start_minutes - start_hours * 60
    local start_days = math.modf(start_hours / 24)
    local hours = start_hours - start_days * 24
    local wrapped_time = { h = hours, m = minutes, s = seconds }
    if hours > 0 then
        return string.format('%02.f:%02.f:%02.f', wrapped_time.h, wrapped_time.m, wrapped_time.s)
    else
        return string.format('%02.f:%02.f', wrapped_time.m, wrapped_time.s)
    end
end

function WeaponWidgetCreate()
    if type(weapon) == 'table' and #weapon > 0 then
        local WeaponPanaelIdList = {}
        for i = 1, #weapon do
            if (#weapon == 6 and i == 4 or i == 1) or (#weapon < 6 and i % 2 ~= 0) then
                table.insert(WeaponPanaelIdList, system.createWidgetPanel(''))
            end
            local WeaponWidgetDataId = weapon[i].getWidgetDataId()
            local WeaponWidgetType = weapon[i].getWidgetType()
            system.addDataToWidget(WeaponWidgetDataId,
                system.createWidget(WeaponPanaelIdList[#WeaponPanaelIdList], WeaponWidgetType))
        end
    end
end

if showWeapons then
    WeaponWidgetCreate()
end

function getFriendlyDetails(id)
    owner = radar.getConstructOwnerEntity(id)
    if owner.isOrganization then
        return system.getOrganization(owner.id).name
    else
        return system.getPlayerName(owner.id)
    end
end

function printNewRadarContacts()
    if zone == 1 or printSZContacts then
        local newTargetCounter = 0
        for k, v in pairs(newRadarContacts) do
            if newTargetCounter > 10 then
                system.print("Didnt print all new Contacts to prevent overload!")
                break
            end
            newTargetCounter = newTargetCounter + 1
            newTargetName = "[" .. radar.getConstructCoreSize(v) ..
                "]-" .. getShortName(v) .. "- " .. radar.getConstructName(v)
            if showTime then
                newTargetName = newTargetName .. ' - Time: ' .. seconds_to_clock(system.getArkTime())
            end
            if radar.hasMatchingTransponder(v) == 1 then
                newTargetName = newTargetName .. " - [Ally] Owner: " .. getFriendlyDetails(v)
                if not borderActive then
                    borderColor = "green"
                    borderWidth = 200
                    borderActive = true
                    unit.setTimer("cleanBorder", 1)
                end
            elseif radar.isConstructAbandoned(v) == 1 then
                newTargetName = newTargetName .. " - Abandoned"
            else
                if not borderActive then
                    play("newContact")
                    borderActive = true
                    borderColor = "red"
                    borderWidth = 200
                    unit.setTimer("cleanBorder", 1)
                end
            end
            system.print("New Target: " .. newTargetName)
            if printLocationOnContact then
                system.print(system.getWaypointFromPlayerPos())
            end
        end
        newRadarContacts = {}
    else
        newRadarContacts = {}
    end
end

function getMaxCorestress()
    if maxCoreStress > 1000000 then
        maxCoreStress = string.format('%0.3f', (maxCoreStress / 1000000)) .. "M"
    elseif maxCoreStress > 1000 then
        maxCoreStress = string.format('%0.2f', (maxCoreStress / 1000)) .. "k"
    end
    system.print("Max Core Stress: " .. maxCoreStress)
end

function drawShield()
    shieldHp = shield_1.getShieldHitpoints()
    shieldPercent = shieldHp / shieldMax * 100
    if shieldPercent == 100 then
        shieldPercent = "100"
    else
        shieldPercent = string.format('%0.2f', shieldPercent)
    end
    coreStressPercent = string.format('%0.2f', core.getCoreStressRatio() * 100)
    local shieldHealthBar = [[
                    <style>
                    .health-bar {
                        position: fixed;
                        width: 13em;
                        padding: 1vh;
                        bottom: 5vh;
                        left: 50%;
                        transform: translateX(-50%);
                        text-align: center;
                        background: #142027;
                        opacity: 0.8;
                        color: white;
                        font-family: "Lucida" Grande, sans-serif;
                        font-size: 1.5em;
                        border-radius: 5vh;
                        border: 0.2vh solid;
                        border-color: #098dfe;
                    }
                    .bar {
                        padding: 5px;
                        border-radius: 5vh;
                        background: #09c3fe;
                        opacity: 0.8;
                        width: ]] .. shieldPercent .. [[%;
                        height: 40px;
                        position: relative;
                    }


                    </style>
                    <html>
                        <div class="health-bar">
                            <div class="bar">]] .. venting .. shieldPercent .. [[%</div>
                        </div>
                    </html>
                    ]]
    local coreStressBar = [[
                    <style>
                    .stress-health-bar {
                        position: fixed;
                        width: 13em;
                        padding: 1vh;
                        bottom:]] .. stressBarHeight .. [[vh;
                        left: 50%;
                        transform: translateX(-50%);
                        text-align: center;
                        background: #142027;
                        opacity: 0.8;
                        color: white;
                        font-family: "Lucida" Grande, sans-serif;
                        font-size: 1.5em;
                        border-radius: 5vh;
                        border: 0.2vh solid;
                        border-color: #a00000;
                    }
                    .stress-bar {
                        padding: 5px;
                        border-radius: 5vh;
                        background: #ff0000;
                        opacity: 0.8;
                        width: ]] .. coreStressPercent .. [[%;
                        height: 40px;
                        position: relative;
                    }


                    </style>
                    <html>
                        <div class="stress-health-bar">
                            <div class="stress-bar">]] .. coreStressPercent .. [[%</div>
                        </div>
                    </html>
                    ]]
    if shield_1.isVenting() == 1 then
        stressBarHeight = "15"
        venting = "Venting "
        healthHtml = coreStressBar .. shieldHealthBar
    elseif shield_1.isActive() == 0 or shield_1.getShieldHitpoints() == 0 then
        stressBarHeight = "5"
        healthHtml = coreStressBar
    else
        stressBarHeight = "5"
        venting = ""
        healthHtml = shieldHealthBar
    end
end

requiredTargets = {}
function readRequiredValues()
    requiredTargets = {}
    if autoTargets then
        local targets = require("Targets")
        for _, v in pairs(targets) do
            local id = v.shortid[1]
            if id ~= targetCode then
                requiredTargets[#requiredTargets + 1] = v.shortid[1]
            end
        end
        package.loaded['Targets'] = nil

        local transponders = require("Transponder")
        local tablea = {}
        local i = 1

        for _, v in pairs(transponders) do
            local transtag = v.transponder[1]
            tablea[i] = v.transponder[1]
            i = i + 1
            transponder.setTags(tablea)
        end
        package.loaded['Transponder'] = nil
    end
end

if pcall(require, "Transponder") and pcall(require, "Targets") and transponder then
    unit.setTimer("loadRequired", 1)
end
specialRadarTargets = {}
local amountToFilterOutAbandonedConstructs = 50 --export:
knownContacts = { isEmpty = true }
targetcount = 0
function updateRadar(match)
    if radar_size > 1 then
        if radar_1 == radar and radar_1.getOperationalState() == -1 then radar = radar_2 end
        if radar_2 == radar and radar_2.getOperationalState() == -1 then radar = radar_1 end
    end
    allies = {}
    threats = {}
    targetcount = 0
    specialRadarTargets = {}
    local data = radar.getWidgetData()
    if string.len(data) < 120000 then
        local _, _, cl = data:find('"constructsList" *: *(%b[])')
        local constructList = cl:gmatch("%b{}")
        local list = {}
        targetcount = 0
        for str in constructList do
            local id = tonumber(str:match('"constructId":"([%d]*)"'))
            if not (knownContacts[id]) then
                local tagged = radar.hasMatchingTransponder(id) == 0 and true or false
                if radar.hasMatchingTransponder(id) == 1 and radar.isConstructAbandoned(id) == 0 then
                    allies[#allies + 1] = id
                end
                if radar.getThreatRateFrom(id) > 1 and radar.isConstructAbandoned(id) == 0 then
                    threats[#threats + 1] = id
                end
                local ident = radar.isConstructIdentified(id) == 1
                local randomid = getShortName(id)
                str = string.gsub(str, 'name":"', 'name":"' .. randomid .. ' - ')

                if match and tagged and
                    not
                    (
                    radar.isConstructAbandoned(id) == 1 and #radar.getConstructIds() > amountToFilterOutAbandonedConstructs
                    and
                    not (radar.isConstructIdentified(id) == 1
                    or id == radar.getTargetId())) then
                    targetcount = targetcount + 1
                    list[#list + 1] = str
                elseif not match and not tagged then
                    list[#list + 1] = str
                end
                if targetCode == randomid then
                    table.insert(specialRadarTargets, 1, str)
                end

                for i = 1, #requiredTargets do
                    local requiredTarget = requiredTargets[i]

                    if requiredTarget == randomid then
                        table.insert(specialRadarTargets, str)
                    end
                end

                if not specialRadar and #specialRadarTargets > 0 then
                    specialRadar = true
                    specialTargetRadar()
                end
            end
        end
        return '{"constructsList":[' .. table.concat(list, ',') .. '],' .. data:match('"elementId":".+')
    end
end

radarOnlyEnemeies = true
fm = 'Enemies'
rf = ''
FCS_locked = false
local customRadarData = updateRadar(radarOnlyEnemeies)

local customRadarPanel = system.createWidgetPanel("RADAR")
local customRadarWidget = system.createWidget(customRadarPanel, "value")
radarFilter = system.createData('{"label":"Filter","' .. fm .. '' .. rf .. '","unit": ""}')
system.addDataToWidget(radarFilter, customRadarWidget)
local customSecondRadarWidget = system.createWidget(customRadarPanel, "radar")
radarData = system.createData(customRadarData)
system.addDataToWidget(radarData, customSecondRadarWidget)

specialRadar = false
function specialTargetRadar()
    local widgetTitel = "Targets"
    if autoTargets then widgetTitel = widgetTitel .. " - AutoMode" end
    specialTimer = 0
    unit.setTimer("specialR", 0.1)
    local data = radar.getWidgetData()
    local _dataS = '{"constructsList":[' .. table.concat(specialRadarTargets, ',') .. '],' ..
        data:match('"elementId":".+')
    _panelS = system.createWidgetPanel(widgetTitel)
    local _widgetS = system.createWidget(_panelS, "radar")
    radarDataS = system.createData(_dataS)
    system.addDataToWidget(radarDataS, _widgetS)
end

allyAmount = 0
function getAlliedInfo()
    local htmlAllies = ""
    allyAmount = #allies
    local tooMany = false
    if allyAmount > maxAllies then tooMany = true end
    for i = 1, #allies do
        if i < (maxAllies + 1) then
            local id = allies[i]
            local allyShipInfo = "[" ..
                radar.getConstructCoreSize(id) .. "]-" .. getShortName(id) .. "- " .. radar.getConstructName(id)
            local owner = getFriendlyDetails(id)
            htmlAllies = htmlAllies .. [[<tr>
                                <td>]] .. allyShipInfo .. [[</td>
                                <td>]] .. owner .. [[</td>
                                </tr>]]
        end
    end
    if tooMany then
        htmlAllies = htmlAllies .. [[<tr>
                                <td colspan="2">Plus ]] .. (allyAmount - maxAllies) .. [[ more allies</td>
                                </tr>]]
    end
    return htmlAllies
end

function alliesHead()
    if allyAmount == 0 then
        return ""
    else
        local alliesHead = [[<tr>
                    <th style="width:max-content;max-width:80%">ShipInfo</th>
                      <th style="width:max-content;max-width:30%">Owner</th>
                    </tr>]]
        return alliesHead
    end
end

function drawAlliesHtml()
    alliesHtml = [[
                    <html>
                        <div class="allies">
                        <table class="customTable">
                            <thead>
                                <h2>Targets: ]] .. (targetcount) .. [[</h2><br>
                                <h2>Allies: ]] .. allyAmount .. [[</h2><br>]] .. alliesHead() .. [[</thead>
                            <tbody>]] .. getAlliedInfo() .. [[</tbody>
                        </table></div>
                    </html>]]
end

function drawThreatsHtml()
    threatsAmount = #threats
    function threatsHead()
        if threatsAmount == 0 then
            return ""
        else
            local threatsHead = [[
                            <tr>
                                <th style="width:max-content;max-width:80%">ShipInfo</th>
                                <th style="width:max-content;max-width:50%">Threat Lvl</th>
                            </tr>]]
            return threatsHead
        end
    end

    function getThreatsInfo()
        local threatInfo = ""
        for i = 1, threatsAmount do
            local id = threats[i]
            local threatDist = radar.getConstructDistance(id)

            if threatDist < 1000 then
                threatDist = string.format('%0.2f', threatDist) .. "m"
            elseif threatDist < 100000 then
                threatDist = string.format('%0.2f', threatDist / 1000) .. "km"
            else
                threatDist = string.format('%0.2f', threatDist / 200000) .. "su"
            end
            local threatShipInfo = "[" ..
                radar.getConstructCoreSize(id) ..
                "]-" .. getShortName(id) .. "- " .. radar.getConstructName(id) .. " - " .. threatDist
            local threat = radar.getThreatRateFrom(id)
            local threatRateString = { "None", "Identified", "Stopped shooting", "Threatened", "Attacked" }
            local color = "red"
            if threat == 1 or threat == 2 then
                color = "orange"
            end
            threatInfo = threatInfo .. [[<tr style=color:]] .. color .. [[>
                                    <td>]] .. threatShipInfo .. [[</td>
                                    <td>]] .. threatRateString[threat] .. [[</td>
                                    </tr>]]
        end
        return threatInfo
    end

    threatsHtml = [[
                    <div class="locked">
                        <table class="customTable">
                            <thead>
                                <h2 style="color:red;text-align:right">Threats: ]] ..
        threatsAmount .. [[</h2><br>]] .. threatsHead() .. [[
                                <tbody>]] .. getThreatsInfo() .. [[</tbody>
                        </table>
                    </div>]]
end

cssAllyLocked = [[<style>
                    .allies {
                        position: fixed;
                        top: 25px;
                        width: 15%;
                        color: white;
                    }
                    .locked {
                        position: fixed;
                        top: 14%;
                        right: 20px;
                        width: 15%;
                        color: red;
                    }
                    table.customTable {
                        border-collapse: collapse;
                        border-width: 2px;
                        background: #142027;
                        opacity: 0.8;
                        font-family: "Lucida" Grande, sans-serif;
                        font-size: 12px;
                        border-radius: 5px;
                        border: 0.2vh solid;
                        border-color: #098dfe
                    }

                    table.customTable td, table.customTable th {
                        border-width: 2px;
                        border-color: #7EA8F8;
                        border-style: solid;
                        border-radius: 5px;
                        padding: 5px;
                    }
                    .h2{
                        font-family: "Lucida" Grande, sans-serif;
                    }

                    </style>]]

ownShipId = construct.getId()
ownShipName = construct.getName()
own3Letter = getShortName(ownShipId)
ownInfoHtml = [[
                <style>
                .ownShipInfo{
                    font-family: "Lucida" Grande, sans-serif;
                    position: fixed;
                    bottom: 10px;
                }
                </style>
                <div class="ownShipInfo">
                    <h4>]] .. ownShipId .. " [" .. own3Letter .. "] " .. ownShipName .. [[<h4>
                </div>
                ]]
if shield_1 and showShield then
    shieldMax = shield_1.getMaxShieldHitpoints()
    drawShield()
end
if showAllies then
    drawAlliesHtml()
end
borderWidth = 0
borderColor = "red"
borderActive = false
function alarmBorder()
    alarmStyles = [[<style>
                .alarmBorder {
                    width:100%;
                    height:100%;
                    box-shadow: 0 0 ]] .. borderWidth .. [[px 0px ]] .. borderColor .. [[ inset;
                    }</style>
                    <html class='alarmBorder'></html>]]
end

function comma_value(amount)
    local formatted = amount
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if (k == 0) then
            break
        end
    end
    return formatted
end

local enemyInfoDmg = "";
dmgTable = {}
local dmgDone = 0;
local dmgDoneFormatted = "0";
local dmgPercent = 0;

function addDmgToTable(id, dmg, weapon)
    local ammoId = weapon.getAmmo()
    local ammoType = system.getItem(ammoId).displayName
    local displayType
    if string.find(ammoType, "Kinetic") then
        displayType = "Kinetic"
    elseif string.find(ammoType, "Thermic") then
        displayType = "Thermic"
    elseif string.find(ammoType, "Antimatter") then
        displayType = "Antimatter"
    elseif string.find(ammoType, "Electromagnetic") then
        displayType = "Electromagnetic"
    end
    if printHitAndMiss then
        system.print(radar.getConstructName(id) ..
            " hit for " .. string.format('%0.2f', (dmg / 1000)) .. "k damage (" .. displayType .. ")")
    end
    if not calculating then
        calculating = true
        unit.setTimer("DPS", 1)
    end
    local prevDmg = dmgTable[id]
    if prevDmg == nil then
        dmgTable[id] = dmg
    else
        dmgTable[id] = prevDmg + dmg
    end
end

counter = 1
dpsTable = {}
dps = "~"
ttTenMil = 0
ttTenMilString = "--:--"
calculating = false
lastDmgValue = 0
function enemyDPS()
    local incDmg = 0
    local newDmgValue = dmgTable[radar.getTargetId()] or 0
    local diff = newDmgValue - lastDmgValue
    if diff < 0 then
        unit.stopTimer("DPS")
        dpsTable = {}
        counter = 1
        dps = "~"
        ttTenMil = 0
        ttTenMilString = "--:--"
        calculating = false
        lastDmgValue = 0
    end
    dpsTable[counter] = diff
    counter = counter + 1
    lastDmgValue = newDmgValue
    local dpsTableLenght = #dpsTable
    for i = 1, dpsTableLenght do
        incDmg = incDmg + dpsTable[i]
    end

    if counter > 60 then
        counter = 1
    end
    if dpsTableLenght > 10 then
        dps = incDmg / dpsTableLenght
        if counter % 5 == 0 then
            ttTenMil = (10000000 - newDmgValue) / dps
            ttTenMilString = "~" .. seconds_to_clock(ttTenMil)
        elseif ttTenMil > 0 then
            ttTenMil = ttTenMil - 1
            ttTenMilString = "~" .. seconds_to_clock(ttTenMil)
        end
        if ttTenMil < 0 then ttTenMilString = "" end
        dps = round(dps / 1000, 2) .. "k"
    end
    if incDmg < 1 and dpsTableLenght == 60 then
        unit.stopTimer("DPS")
        dpsTable = {}
        counter = 1
        dps = "~"
        ttTenMil = 0
        ttTenMilString = "--:--"
        calculating = false
        lastDmgValue = 0
    end
end

function round(num, numDecimalPlaces)
    local mult = 10 ^ (numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end

function getMaxSpeedByMass(m)
    if m then
        local speed = 50000 / 3.6 - 10713 * (m - 10000) / (853926 + (m - 10000))
        speed = speed * 3.6
        if speed > 50000 then
            speed = 50000
        elseif speed < 20000 then
            speed = 20000
        end
        return speed
    end
end

local oldTargetSpeed = nil
local speedCounter = 0
local speedAnnounced = nil
local speedUpOrDown = ""
local callSpeed = true       --export:
local callSpeedChange = true --export:
local speedChange = ""
function drawEnemyInfoDmgBar()
    local targetId = radar.getTargetId()
    if targetId == 0 then
        enemyInfoDmg = "";
        oldTargetSpeed = nil
        speedCounter = 0
        speedAnnounced = nil
        speedUpOrDown = ""
        speedChange = ""
        maxSpeed = 0
        return
    end
    local isIdentified = radar.isConstructIdentified(targetId) == 1


    dmgDone = dmgTable[targetId] or 0;
    dmgPercent = (dmgDone / 100000)
    if dmgPercent > 100 then dmgPercent = 100 end
    if dmgDone > 1000000 then
        dmgDoneFormatted = string.format('%0.2f', (dmgDone / 1000000)) .. "M"
    elseif dmgDone > 1000 then
        dmgDoneFormatted = string.format('%0.2f', (dmgDone / 1000)) .. "k"
    else
        dmgDoneFormatted = ""
    end
    targetDistance = math.floor(radar.getConstructDistance(targetId))
    targetName = "[" ..
        radar.getConstructCoreSize(targetId) .. "]-" ..
        getShortName(targetId) .. "- " .. radar.getConstructName(targetId)
    targetSpeed = math.floor(radar.getConstructSpeed(targetId) * 3.6)
    if targetSpeed > oldSpeed then
        speedChangeIcon = "↑"
    elseif targetSpeed < oldSpeed then
        speedChangeIcon = "↓"
    else
        speedChangeIcon = "→"
    end
    if not oldTargetSpeed then oldTargetSpeed = targetSpeed end
    if callSpeed and isIdentified then
        local factor = math.floor(round(targetSpeed / 5000))
        if not speedAnnounced then speedAnnounced = 5000 * factor end
        if speedAnnounced ~= 5000 * factor and targetSpeed > 5000 * factor - 100 and
            targetSpeed < 5000 * factor + 100 then
            table.insert(Sound, "speed" .. 5000 * factor)
            oldTargetSpeed = targetSpeed
            speedAnnounced = 5000 * factor
        end
    end

    if callSpeedChange and isIdentified then
        local speedChangeLimit = 500
        if targetSpeed - oldTargetSpeed > speedChangeLimit then
            oldTargetSpeed = targetSpeed
            speedCounter = 0
            if speedUpOrDown ~= "up" then
                speedUpOrDown = "up"
                speedChange = "Increasing"
                table.insert(Sound, "speedup")
            end
        elseif oldTargetSpeed - targetSpeed > speedChangeLimit then
            oldTargetSpeed = targetSpeed
            speedCounter = 0
            if speedUpOrDown ~= "down" then
                speedUpOrDown = "down"
                speedChange = "Braking"
                table.insert(Sound, "speeddown")
            end
        else
            if speedCounter < 100 then
                speedCounter = speedCounter + 1
            else
                if speedUpOrDown ~= "holding" then
                    speedUpOrDown = "holding"
                    speedChange = "Holding"
                    table.insert(Sound, "speedholding")
                end
                speedCounter = 0
            end
        end
    end

    if targetDistance > oldTargetDistance then
        distanceChangeIcon = "↑"
    elseif targetDistance < oldTargetDistance then
        distanceChangeIcon = "↓"
    else
        distanceChangeIcon = "→"
    end
    oldTargetDistance = targetDistance
    oldSpeed = targetSpeed

    if targetDistance < 1000 then
        distanceUnit = "m"
    elseif targetDistance < 100000 then
        targetDistance = targetDistance / 1000
        distanceUnit = "km"
    else
        targetDistance = targetDistance / 200000
        distanceUnit = "su"
    end
    local maxSpeed = isIdentified and comma_value(math.floor(getMaxSpeedByMass(radar.getConstructMass(targetId)))) or 0
    probil = math.floor(json.decode(weapon_1.getWidgetData()).properties.hitProbability * 100)
    enemyInfoDmg = [[<style>
    .enemyInfoCss {
    position: fixed;
    top: 8%;
    left: 50%;
    transform: translateX(-50%);
    width: 560px;
    color: #80ffff;
    text-align: center;
}

    .enemySpeed{
    position: fixed;
    top: 50%;
    left: 35%;
}
    .dmgDoneLabels {
    display: grid;
    grid-template-columns: auto auto auto;
    font-size: 12px;
}
    .targetInfoLabels {
    display: grid;
    grid-template-columns: 25% 25% 25% 25%;
    font-size:14px;
}
    </style>
    <div class="enemySpeed">Speed: ]] .. comma_value(targetSpeed) .. [[km/h <br>]]
        .. speedChange .. [[</div>
    <div class="enemyInfoCss">
    <h3 style="text-align: center;">*]] .. targetName .. [[*</h3>
    <div>
    <svg width="100%" height="24px" style="font-family: Calibri;fill:white;stroke:#80ffff;font-weight:bold">
    <rect x="0" y="0" rx="10" ry="10" width="100%" height="24" style="fill:#142027;stroke:#098dfe;stroke-width:1;opacity:0.8" />

    <rect x="0" y="1" rx="10" ry="10" width="]] ..
        dmgPercent .. [[%" height="22" style="fill:red;stroke:black;stroke-width:0;opacity:0.5" />
    <text x="50%" y="18"  text-anchor="middle">]] .. dmgDoneFormatted .. [[</text>
    </svg>
    </div>
    <div class="dmgDoneLabels">
    <div style="text-align: left;">0</div>
    <div style="text-align: center;">5mil</div>
    <div style="text-align: right;">10mil</div>
    </div>]]
    if isIdentified then
        enemyInfoDmg = enemyInfoDmg ..
            [[<h3>Hitchance</h3>
        <div>
        <svg width="80%" height="24px" style="font-family: Calibri;fill:white;stroke:#80ffff;font-weight:bold">
        <rect x="0" y="0" rx="10" ry="10" width="100%" height="24"
        style="fill:#142027;stroke:#098dfe;stroke-width:1;opacity:0.8" />

        <rect x="0" y="1" rx="10" ry="10" width="]] .. probil .. [[%" height="22"
        style="fill:gray;stroke:black;stroke-width:0;opacity:0.5" />
        <text x="50%" y="18"  text-anchor="middle">]] .. probil .. [[%</text>
        </svg>
        </div>
        ]]
    end
    enemyInfoDmg = enemyInfoDmg .. [[
    <div class="targetInfoLabels">
    <div>]] ..
        distanceChangeIcon .. " " .. round(targetDistance, 2) .. distanceUnit .. [[</div>]]
    if isIdentified then
        enemyInfoDmg = enemyInfoDmg .. [[
        <div>]] .. "max: " .. maxSpeed .. [[km/h</div>
        <div>]] .. dps .. [[ dps</div>
        <div>]] .. ttTenMilString .. [[</div><div></div>
        <div>Current: ]] .. speedChangeIcon .. comma_value(targetSpeed) .. [[km/h</div>
        ]]
    end
    enemyInfoDmg = enemyInfoDmg .. [[ </div></div>]]
end

function crossHair()
    local l = targetDistance
    if l < 100000 then l = 100000 end
    local pcrossHair = vec3(construct.getWorldPosition()) + l * vec3(construct.getWorldForward())
    local ocrossHair = library.getPointOnScreen({ pcrossHair['x'], pcrossHair['y'], pcrossHair['z'] })
    local x = ocrossHair[1]
    local y = ocrossHair[2]
    if x > 0 and y > 0 then
        return [[<div style="position: fixed;left: ]] ..
            screenWidth * x ..
            [[px;top:]] ..
            screenHeight * y ..
            [[px;width:15px;height:15px;"><svg viewBox="0 0 1024 1024" ><path fill="currentColor" d="M512 896a384 384 0 1 0 0-768 384 384 0 0 0 0 768zm0 64a448 448 0 1 1 0-896 448 448 0 0 1 0 896z"></path><path fill="currentColor" d="M512 96a32 32 0 0 1 32 32v192a32 32 0 0 1-64 0V128a32 32 0 0 1 32-32zm0 576a32 32 0 0 1 32 32v192a32 32 0 1 1-64 0V704a32 32 0 0 1 32-32zM96 512a32 32 0 0 1 32-32h192a32 32 0 0 1 0 64H128a32 32 0 0 1-32-32zm576 0a32 32 0 0 1 32-32h192a32 32 0 1 1 0 64H704a32 32 0 0 1-32-32z"></path></svg></div>]]
    else
        return ""
    end
end

alliesAR = ""
function drawAlliesOnScreen()
    screenHeight = system.getScreenHeight()
    screenWidth = system.getScreenWidth()
    if lshiftPressed then
        alliesAR = [[<svg width="100%" height="100%" style="position: absolute;left:0%;top:0%;font-family: Calibri;">]]
        for _, v in ipairs(allies) do
            local point = vec3(radar.getConstructWorldPos(v))
            local allyPosOnScreen = library.getPointOnScreen({ point['x'], point['y'], point['z'] })
            local x = screenWidth * allyPosOnScreen[1]
            local y = screenHeight * allyPosOnScreen[2]
            if x > 0 and y > 0 then
                alliesAR = alliesAR ..
                    [[<circle cx="]] ..
                    x ..
                    [[" cy="]] ..
                    y ..
                    [[" r="5" stroke="green" stroke-width="2" style="fill-opacity:0" /><text x="]] ..
                    x + 10 .. [[" y="]] .. y + 10 .. [[" fill="white">]] .. getFriendlyDetails(v) .. [[</text>]]
            end
        end
        alliesAR = alliesAR .. "</svg>"
    else
        alliesAR = ""
    end
end

atlas = require('atlas')

planetList = {}
for k, nextPlanet in pairs(atlas[0]) do
    if nextPlanet.type[1] == "Planet" then
        planetList[#planetList + 1] = nextPlanet
        --system.print(nextPlanet.name[1])
    end
end
planetAR = ""
function drawPlanetsOnScreen()
    screenHeight = system.getScreenHeight()
    screenWidth = system.getScreenWidth()
    if lshiftPressed then
        planetAR = [[<svg width="100%" height="100%" style="position: absolute;left:0%;top:0%;font-family: Calibri;">]]
        for _, v in pairs(planetList) do
            local point = vec3(v.center)
            local distance = (point - vec3(construct.getWorldPosition())):len()
            local planetPosOnScreen = library.getPointOnScreen({ point['x'], point['y'], point['z'] })
            local xP = screenWidth * planetPosOnScreen[1]
            local yP = screenHeight * planetPosOnScreen[2]
            local deth = 12
            local su = (distance / 200 / 1000)
            if su < 10 then
                deth = 250 - 800 * (distance / 1000 / 200 / 40)
            elseif su < 40 then
                deth = 20
            end
            local pipeDist = getPipeDistance(point)
            local eta = getETA(distance, pipeDist, xP + deth, yP + deth)
            if xP > 0 and yP > 0 then
                planetAR = planetAR ..
                    [[<circle cx="]] ..
                    xP ..
                    [[" cy="]] ..
                    yP ..
                    [[" r="]] .. deth .. [[" stroke="orange" stroke-width="1" style="fill-opacity:0" /><text x="]] ..
                    xP + deth ..
                    [[" y="]] ..
                    yP + deth .. [[" fill="#c7dcff">]] .. v.name[1] ..
                    " " .. getDistanceDisplayString(distance) .. [[</text>]] .. eta
            end
        end
        planetAR = planetAR .. "</svg>"
    else
        planetAR = ""
    end
end

aliencores = {
    [1] = {
        name = "Alpha",
        pos = { 33946000.0000, 71381990.0000, 28850000.0000 }
    },
    [2] = {
        name = "Gamma",
        pos = { -64334000.0000, 55522000.0000, -14400000.0000 }
    },
}

alienAR = ""
function drawAlienCores()
    if lshiftPressed then
        alienAR = ""
        for _, v in pairs(aliencores) do
            local point = vec3(v.pos)
            local distance = (point - vec3(construct.getWorldPosition())):len()
            local alienPosOnScreen = library.getPointOnScreen({ point['x'], point['y'], point['z'] })
            local xP = screenWidth * alienPosOnScreen[1]
            local yP = screenHeight * alienPosOnScreen[2]
            if xP > 0 and yP > 0 then
                local eta = getETA(distance, pipeDist, xP + deth, yP + deth)
                alienAR = alienAR ..
                    [[<div style="position: fixed;left: ]] ..
                    xP .. [[px;top:]] .. yP .. [[px;"><svg height="30" width="15">
                                                <g>
                                                    <path style="fill:purple;" d="M8.472,0l-1.28,0.003c-2.02,0.256-3.679,1.104-4.671,2.386C1.685,3.47,1.36,4.78,1.553,6.283
                                                        c0.37,2.87,2.773,6.848,4.674,8.486c0.475,0.41,1.081,0.794,1.353,0.899c0.129,0.044,0.224,0.073,0.333,0.073
                                                        c0.11,0,0.217-0.031,0.319-0.091c1.234-0.603,2.438-1.88,3.788-4.02c0.936-1.485,2.032-3.454,2.2-5.495
                                                        C14.492,2.843,12.295,0.492,8.472,0z M8.435,0.69c3.431,0.447,5.337,2.462,5.097,5.391c-0.156,1.913-1.271,3.875-2.097,5.182
                                                        c-1.278,2.027-2.395,3.226-3.521,3.777c-0.005,0.002-0.009,0.004-0.012,0.005c-0.029-0.006-0.068-0.021-0.087-0.027
                                                        c-0.149-0.057-0.706-0.401-1.135-0.771c-1.771-1.525-4.095-5.375-4.44-8.052C2.07,4.879,2.348,3.741,3.068,2.812
                                                        c0.878-1.135,2.363-1.889,4.168-2.12L8.435,0.69z"/>
                                                    <path style="fill:purple;" d="M3.504,6.83C3.421,6.857,3.37,6.913,3.373,7.024c0.308,1.938,1.616,3.536,3.842,3.126
                                                        C7.002,8.019,5.745,6.933,3.504,6.83z"/>
                                                    <path style="fill:purple;" d="M8.778,10.215c2.196-0.125,3.61-1.379,3.776-3.319C10.321,6.727,8.55,7.923,8.778,10.215z"/>
                                                </g>
                                            </svg>]] ..
                    v.name .. " " .. getDistanceDisplayString(distance) .. eta [[</div>]]
            end
        end
    else
        alienAR = ""
    end
end

function getDistanceDisplayString(distance)
    local su = distance > 100000
    if su then
        -- Convert to SU
        return round(distance / 1000 / 200, 2) .. "SU"
    elseif distance < 1000 then
        return round(distance, 2) .. "M"
    else
        -- Convert to KM
        return round(distance / 1000, 2) .. "KM"
    end
end

function zeroConvertToWorldCoordinates(cl)
    local q = ' *([+-]?%d+%.?%d*e?[+-]?%d*)'
    local cm = '::pos{' .. q .. ',' .. q .. ',' .. q .. ',' .. q .. ',' .. q .. '}'
    local cn, co, ci, cj, ch = string.match(cl, cm)
    if cn == '0' and co == '0' then
        return vec3(tonumber(ci), tonumber(cj), tonumber(ch))
    end
    cj = math.rad(cj)
    ci = math.rad(ci)

    local planet = atlas[tonumber(cn)][tonumber(co)]

    local cp = math.cos(ci)
    local cq = vec3(cp * math.cos(cj), cp * math.sin(cj), math.sin(ci))
    return (vec3(planet.center) + (planet.radius + ch) * cq)
end

local hasCustomWaypoints, customWaypoints = pcall(require, "customWaypoints")
if hasCustomWaypoints then
    system.print("--------------")
    system.print("Loaded " .. #customWaypoints .. " Custom Waypoints for AR:")
    for _, v in pairs(customWaypoints) do
        system.print(v.name)
        v.pos = vec3(zeroConvertToWorldCoordinates(v.pos))
        v.offset = math.random(-10, 10)
    end
    system.print("--------------")
else
    customWaypoints = {}
end
filteredWaypoints = customWaypoints
customWaypointsAR = ""
function drawCustomWaypointsOnScreen()
    if lshiftPressed then
        customWaypointsAR =
        [[<svg width="100%" height="100%" style="position: absolute;left:0%;top:0%;font-family: Calibri;">]]
        for _, v in pairs(filteredWaypoints) do
            local point = v.pos
            local distance = (v.pos - vec3(construct.getWorldPosition())):len()
            local customWaypointsPosOnScreen = library.getPointOnScreen({ point['x'], point['y'], point['z'] })
            local x = screenWidth * customWaypointsPosOnScreen[1]
            local y = screenHeight * customWaypointsPosOnScreen[2]
            local color = v.color or "red"
            local pipeDist = getPipeDistance(point)
            local eta = getETA(distance, pipeDist, x, y)
            if x > 0 and y > 0 then
                customWaypointsAR = customWaypointsAR ..
                    [[<rect x="]] ..
                    x - 5 ..
                    [[" y="]] ..
                    y - 5 ..
                    [[" rx="2" ry="2" stroke="]] ..
                    color .. [[" width="10" height="10" stroke-width="2" style="fill-opacity:0" /><text x="]] ..
                    x + 10 ..
                    [[" y="]] ..
                    y + 10 + v.offset ..
                    [[" fill="white">]] .. v.name .. " " .. getDistanceDisplayString(distance) .. [[</text>]] .. eta
            end
        end
        customWaypointsAR = customWaypointsAR .. "</svg>"
    else
        customWaypointsAR = ""
    end
end

function getPipeDistance(worldPos)
    local origin = vec3(construct.getWorldPosition())
    local destination = origin + vec3(construct.getWorldVelocity())
    local pipeDistance
    local pipe = (destination - origin):normalize()
    local r = (worldPos - origin):dot(pipe) / pipe:dot(pipe)
    local L = origin + (r * pipe)
    pipeDistance = (L - worldPos):len()
    return pipeDistance
end

function getETA(distance, pipeDist, x, y)
    if distance / 200000 > 100 and pipeDist < 600000 or pipeDist < 100000 then
        local time = distance / vec3(construct.getWorldVelocity()):len()
        if time < 10 * 60 * 60 then
            return [[<text x="]] ..
                x + 10 ..
                [[" y="]] ..
                y + 30 .. [[" fill="#c7dcff">ETA ]] .. seconds_to_clock(time) .. [[</text>]]
        end
    end
    return ""
end

function radarRange()
    local radarIdentificationRange = radar.getIdentifyRanges()[1]
    if radarIdentificationRange == nil then return "" end
    local distanceUnit
    if radarIdentificationRange < 1000 then
        distanceUnit = "m"
    elseif radarIdentificationRange < 100000 then
        radarIdentificationRange = radarIdentificationRange / 1000
        distanceUnit = "km"
    else
        radarIdentificationRange = radarIdentificationRange / 200000
        distanceUnit = "su"
    end
    return [[<style> .radarInfo{
                        position: fixed;
                        top: 10px;
                        right: 10px;
                    }</style><div class="radarInfo">Radar-Range: ]] ..
        round(radarIdentificationRange, 2) .. distanceUnit .. [[</div>]]
end

function printMiss(id)
    if printHitAndMiss then
        system.print("Missed " .. radar.getConstructName(id))
    end
    if showFloatyText then
        table.insert(floatyText, { timer = 0, text = "Miss", hit = false })
    end
end

targetVektorPointInfront = 10 --export:
targetVektorFromTarget = {}
TargetVektorInfo = {}
function calculateVektor()
    local l = #targetVektorFromTarget
    local P = targetVektorFromTarget[l - 1]
    local Q = targetVektorFromTarget[l]
    local abstand = P:dist(Q)
    --system.print(abstand)
    local meter = 200000 * targetVektorPointInfront
    local lambda = meter / abstand
    local richtungsVerktor = Q - P
    local R = P + lambda * richtungsVerktor
    TargetVektorInfo.currentPoint = R
    TargetVektorInfo.vector = richtungsVerktor:normalize()
    --new
    -- v = s / t in m/s
    TargetVektorInfo.currentEstimatePosition = Q
    TargetVektorInfo.startPos = Q
    TargetVektorInfo.estimateSpeed = abstand / (TargetVektorInfo.secondTime - TargetVektorInfo.firstTime)
    TargetVektorInfo.displaySpeed = comma_value(math.floor(TargetVektorInfo.estimateSpeed * 3.6))
    TargetVektorInfo.displayName = targetName or "Target"
    setCalculatedWaypoint(R)
    TargetVektorInfo.isTracking = true
end

function calculateAcceleration()
    local P = targetVektorFromTarget[1]
    local Q = targetVektorFromTarget[2]
    local R = targetVektorFromTarget[3]
    local deltaT1 = TargetVektorInfo.thirdTime - TargetVektorInfo.firstTime
    local deltaT2 = TargetVektorInfo.thirdTime - TargetVektorInfo.secondTime
    local speed1 = P:dist(Q) / (TargetVektorInfo.secondTime - TargetVektorInfo.firstTime)
    local speed2 = Q:dist(R) / (TargetVektorInfo.thirdTime - TargetVektorInfo.secondTime)
    local acceleration = -(speed2 - speed1) / (deltaT2 - deltaT1)
    TargetVektorInfo.displayAcceleration = string.format("%.2f G's", acceleration / 9.81)
    system.print("Estimated Acceleration: " .. TargetVektorInfo.displayAcceleration)
    -- check if the target is moving in a straight line
    local angle = math.deg((Q - P):angle_between(R - Q))
    system.print(string.format("Angle difference of 2 Vectors %.2f°", angle))
end

function exportTargetVector()
    local p = TargetVektorInfo.startPos
    local v = TargetVektorInfo.vector
    local exportString = string.format(
        "estimateSpeed = %f,timestamp = %f,startpos = { %f , %f , %f },vector = { %f , %f , %f },",
        TargetVektorInfo.estimateSpeed, TargetVektorInfo.secondTime, p.x, p.y, p.z, v.x, v.y, v.z)
    system.print(exportString)
end

function importTargetVector()
    local hasTargetVector, TargetVector = pcall(require, "targetVectorExport")
    if not hasTargetVector then return end
    TargetVektorInfo.estimateSpeed = TargetVector.estimateSpeed
    TargetVektorInfo.displaySpeed = comma_value(math.floor(TargetVektorInfo.estimateSpeed * 3.6))
    TargetVektorInfo.secondTime = TargetVector.timestamp
    TargetVektorInfo.startPos = vec3(TargetVector.startpos)
    TargetVektorInfo.vector = vec3(TargetVector.vector)
    TargetVektorInfo.displayName = "Target"
    TargetVektorInfo.isTracking = true
    TargetVektorInfo.manualSpeed = nil
    TargetVektorInfo.currentPoint = TargetVektorInfo.startPos
end

function drawEstimatePos()
    if not (TargetVektorInfo.isTracking) then
        estiamtedPos = ""
        return
    end
    local newTime                            = system.getUtcTime()
    local speed                              = TargetVektorInfo.manualSpeed or TargetVektorInfo.estimateSpeed
    local distTraveled                       = speed * (newTime - TargetVektorInfo.secondTime)
    TargetVektorInfo.currentEstimatePosition = TargetVektorInfo.startPos +
        distTraveled * TargetVektorInfo.vector
    local point                              = vec3(TargetVektorInfo.currentEstimatePosition)
    local estimatePosDraw                    = library.getPointOnScreen({ point['x'], point['y'], point['z'] })
    local distance                           = (point - vec3(construct.getWorldPosition())):len()
    local x                                  = screenWidth * estimatePosDraw[1]
    local y                                  = screenHeight * estimatePosDraw[2]
    if x > 0 and y > 0 then
        local centerX = screenWidth / 2
        local centerY = screenHeight / 2
        local distanceFromCenter = math.sqrt((x - centerX) ^ 2 + (y - centerY) ^ 2)
        local opacity = distanceFromCenter /
            (screenWidth / 2)                                 -- opacity ranges from 0 to 1 as you move from the edge to the center of the screen
        opacity = math.max(1 - math.min(opacity * 2, 1), 0.5) -- double the opacity to increase the effect and ensure it doesn't exceed 1

        estiamtedPos = [[<div style="position: fixed;left: ]] ..
            x ..
            [[px;top:]] ..
            y ..
            [[px;opacity: ]] ..
            opacity ..
            [[;"><svg fill="gold" height="20px" width="20px" version="1.1" id="Capa_1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"
	 viewBox="0 0 384.772 384.772" xml:space="preserve">
<path d="M248.706,101.626c16.157-20.383,27.593-46.638,31.85-71.926c0.91-5.408-1.365-10.859-5.85-14.016
	c-4.486-3.156-10.384-3.46-15.168-0.777c-0.242,0.136-24.576,13.57-56.434,13.57c-21.202,0-40.67-6.049-57.86-17.979
	C134.921,3.336,126.693,0,119.348,0c-7.008,0-13.219,3.169-17.041,8.695c-2.786,4.028-4.199,9.11-4.199,15.105
	c0,19.444,14.778,48.827,27.433,68.08c2.548,3.876,5.347,7.888,8.353,11.858c-39.632,38.957-81.508,101.904-81.508,157.351
	c0,87.943,62.682,123.684,140,123.684c77.318,0,140-35.74,140-123.684C332.386,204.628,288.964,140.392,248.706,101.626z
	 M230.779,282.948c-6.581,6.251-15.387,10.417-26.217,12.432v20.075c0,6.892-5.587,12.479-12.479,12.479
	s-12.478-5.587-12.478-12.479v-19.41c-15.81-2.142-27.643-8.99-35.16-20.397c-2.302-3.491-2.701-7.904-1.063-11.751
	c1.638-3.849,5.093-6.621,9.204-7.384l9.42-1.749c4.819-0.896,9.719,1.116,12.52,5.141c3.543,5.093,9.539,7.674,17.819,7.674
	c12.755,0,12.755-5.071,12.755-6.737c0-2.416-0.906-4.175-2.853-5.531c-1.988-1.387-5.61-2.62-10.764-3.668
	c-20.721-4.223-34.068-9.704-39.682-16.294c-5.694-6.684-8.463-14.155-8.463-22.841c0-9.434,3.114-17.924,9.258-25.236
	c5.945-7.08,15.035-11.674,27.009-13.679v-14.367c0-6.892,5.586-12.479,12.478-12.479s12.479,5.587,12.479,12.479v14.633
	c10.719,2.047,19.085,6.378,25.44,13.176c2.931,3.135,4.045,7.556,2.951,11.703c-1.094,4.15-4.244,7.447-8.338,8.728l-6.464,2.023
	c-4.688,1.468-9.802,0.046-13.063-3.63c-3.251-3.666-8.077-5.524-14.343-5.524c-5.046,0-11.063,1.201-11.063,6.926
	c0,1.62,0.621,3.081,1.796,4.227c1.23,1.201,4.817,2.474,10.665,3.778c13.494,2.952,23.359,5.645,29.265,7.995
	c5.984,2.387,11.028,6.474,14.993,12.152c3.968,5.669,5.983,12.468,5.983,20.197C242.386,266.434,238.481,275.632,230.779,282.948z
	 M183.689,110c-2.628,0-10.756-3.764-22.7-18.01c-9.527-11.362-18.932-26.329-25.802-41.063c-3.368-7.223-5.472-13.002-6.754-17.406
	c0.186,0.126,0.373,0.256,0.564,0.389c22.053,15.304,46.986,23.063,74.106,23.063c16.069,0,30.572-2.771,42.183-6.091
	C232.265,84.407,206.971,110,183.689,110z"/></svg> ]]
        if opacity > 0.5 then
            estiamtedPos = estiamtedPos ..
                TargetVektorInfo.displayName ..
                [[<div style="margin-left: 25px">]] .. getDistanceDisplayString(distance) ..
                "<br>Speed: " .. TargetVektorInfo.displaySpeed .. "km/h</div>"
        else
            estiamtedPos = estiamtedPos .. getDistanceDisplayString(distance)
        end
        estiamtedPos = estiamtedPos .. [[</div>]]
    else
        estiamtedPos = ""
    end
end

function moveTargetVectorPoint(amount)
    if not (TargetVektorInfo.currentPoint and TargetVektorInfo.vector) then return end

    local newPoint = TargetVektorInfo.currentPoint + 200000 * amount * TargetVektorInfo.vector
    setCalculatedWaypoint(newPoint)
    TargetVektorInfo.currentPoint = newPoint
end

function getPointFromTarget()
    local targetId = radar.getTargetId()
    if targetId == 0 then
        system.print("No target")
        return
    end
    local l = radar.getConstructDistance(targetId)
    local targetPos = vec3(system.getCameraWorldPos()) + l * vec3(system.getCameraWorldForward())
    addPoint(targetPos)
end

function addPoint(point)
    table.insert(targetVektorFromTarget, point)
    if (#targetVektorFromTarget == 2) then
        system.print("Target Vektor Point 2 added")
        TargetVektorInfo.secondTime = system.getUtcTime()
        calculateVektor()
    elseif (#targetVektorFromTarget == 3) then
        system.print("Target Vektor Point 3 added")
        TargetVektorInfo.thirdTime = system.getUtcTime()
        calculateAcceleration()
        targetVektorFromTarget = {}
    else
        TargetVektorInfo.firstTime = system.getUtcTime()
        system.print("Target Vektor Point 1 added")
    end
end

function setCalculatedWaypoint(waypoint)
    system.setWaypoint("::pos{0,0," .. waypoint.x .. "," .. waypoint.y .. "," .. waypoint.z .. "}")
end

function drawHud()
    html = alarmStyles ..
        alienAR ..
        planetAR ..
        customWaypointsAR ..
        alliesAR ..
        cssAllyLocked .. healthHtml .. alliesHtml .. threatsHtml .. ownInfoHtml ..
        enemyInfoDmg .. crossHair() .. radarRange()
    system.setScreen(html)
end

getMaxCorestress()
system.setScreen(html)
system.showScreen(1)
Sound = {}
function play(path)
    system.playSound("SleimHud/" .. path .. ".mp3")
end

unit.setTimer("sound", 1)
unit.setTimer("hud", 0.1)
unit.setTimer("radar", 0.4)
unit.setTimer("clean", 30)
