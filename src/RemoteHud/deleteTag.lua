local fakeTagsActive = false
local checkIfFakeTagIsNeeded = false
local backupTags = {}
function fakeTags()
  if transponder and checkIfFakeTagIsNeeded and not fakeTagsActive  and coreStressPercent > 50 andshield.isActive() == 0 then
    setFakeTags()
  end

  if fakeTagsActive and shield.isActive() == 1 and shieldPercent > 50 then
    if transponder.setTags(backupTags) == 1 then
      system.print("Loading backup tags")
      fakeTagsActive = false
    end
  end
end

function setFakeTags()
  local time = math.floor(system.getUtcTime())
  local fakeTag = getShortName(time) .. getShortName(time % 1000)
  backupTags = transponder.getTags()
  if transponder.setTags({ fakeTag }) == 1 then
    system.print("Setting fake tags")
    checkIfFakeTagIsNeeded = false
    fakeTags = true
  end
end


-- gets called when shield goes down due to damage
function onDown()
  local maxCoreStress = core.getMaxCoreStress()
  if maxCoreStress < 500000 then
    setFakeTags()
  else
    checkIfFakeTagIsNeeded = true
  end
end

-- runs a timer that gets called every frame
function checkEveryFrame()
  fakeTags()
end
