local obj={}
obj.__index=obj


function showPosition(f)
  hs.alert(f.x)
  hs.alert(f.y)
  hs.alert(f.h)
  hs.alert(f.w)
end

function isLeft(f,max)
  return f.x==max.x and f.y==max.y and f.h==max.h and math.abs(f.w-max.w/2)<2
end

function isRight(f,max)
  return math.abs(f.x-(max.x+ max.w/2))<2 and f.y==max.y and f.h==max.h and math.abs(f.w-max.w/2)<2
end

function isLeftOrRight(f,max)
  return isLeft(f,max) or isRight(f,max)
end

function isFull(f,max)
  return f.x==max.x and f.y==max.y and f.h==max.h and f.w==max.w
end

function isQuater(f,max)
  return math.abs(f.w-max.w/2)<2 and math.abs(f.h-max.h/2)<2
end

function isLeftUp(f,max)
  return isQuater(f,max) and f.x==max.x and f.y==max.y
end

function isLeftDown(f,max)
  return isQuater(f,max) and f.x==max.x and math.abs(f.y-max.y-max.h/2)<2
end

function isRightUp(f,max)
  return isQuater(f,max) and math.abs(f.x-(max.x+ max.w/2))<2 and f.y==max.y
end

function isRightDown(f,max)
  return isQuater(f,max) and math.abs(f.x-(max.x+max.w/2))<2 and math.abs(f.y-max.y-max.h/2)<2
end

function getNormal(max)
  -- showPosition(max)
  max.x=max.x+max.w*15/100
  max.y=max.h*15/100
  max.w=max.w*70/100
  max.h=max.h*70/100
  return max
end


hs.hotkey.bind({"cmd"},"left",
  function()
    local win=hs.window.focusedWindow()
    local f=win:frame()
    local screen=win:screen()
    local max =screen:frame()

    if(isRightDown(f,max) or isRightUp(f,max))then
      f.x=max.x
      win:setFrame(f)
    elseif(isLeftUp(f,max) or isLeftDown(f,max))then
      f.y=max.y
      f.h=max.h
      win:setFrame(f)
    elseif(isRight(f,max))then
      f=getNormal(max)
      win:moveToUnit'[15,15,70,70]'
    else
      win:moveToUnit'[0,0,50,100]'
    end

  end
)

hs.hotkey.bind({"cmd"},"right",
  function()
    local win=hs.window.focusedWindow()
    local f=win:frame()
    local screen=win:screen()
    local max =screen:frame()

    if(isLeftDown(f,max) or isLeftUp(f,max))then
      f.x=max.x+max.w/2
      win:setFrame(f)
    elseif(isRightUp(f,max) or isRightDown(f,max))then
      f.y=max.y
      f.h=max.h
      win:setFrame(f)
    elseif(isLeft(f,max))then
      f=getNormal(max)
      win:setFrame(f)
    else
      win:moveToUnit'[50,0,100,100]'
    end
  end
)

hs.hotkey.bind({"cmd"},"up",
  function()
    local win=hs.window.focusedWindow()
    local f=win:frame()
    local screen=win:screen()
    local max =screen:frame()
    if(isLeftOrRight(f,max))then
      f.h=max.h/2
    elseif(isLeftDown(f,max) or isRightDown(f,max))then
      f.y=max.y
      f.h=max.h
    else
      f=max
    end
    win:setFrame(f)
  end
)

hs.hotkey.bind({"cmd"},"down",
  function()
    local win=hs.window.focusedWindow()
    local f=win:frame()
    local screen=win:screen()
    local max =screen:frame()

    if(isFull(f,max))then
      f=getNormal(max)
    elseif(isLeftOrRight(f,max))then
      f.y=(max.y+max.h/2)
      f.h=max.h/2
    elseif(isLeftUp(f,max)or isRightUp(f,max))then
      f.h=max.h
    end
    win:setFrame(f)
  end
)

hs.hotkey.bind({"shift","cmd"},"left",
  function()
    local win=hs.window.focusedWindow()
    win:moveOneScreenWest()
  end
)

hs.hotkey.bind({"shift","cmd"},"right",
  function()
    local win=hs.window.focusedWindow()
    win:moveOneScreenEast()
  end
)

hs.hotkey.bind({"ctrl","cmd"},"left",
  function()
    hs.eventtap.keyStroke({"ctrl"},",")
  end
)

hs.hotkey.bind({"ctrl","cmd"},"right",
  function()
    hs.eventtap.keyStroke({"ctrl"},".")
  end
)

function getCurrentUserSpace()
  return table.filter(
    spaces.query(),
    function(k,v)
      return spaces.spaceType(v)==spaces.types.user
    end
  )
end

function printCurrentUserSpace()
  print_r(getCurrentUserSpace())
end

function getNextSpaceId()
  local currentSpaceid=spaces.activeSpace()
  local cus=getCurrentUserSpace()
  local last=nil
  for k,v in pairs(cus) do
    if(v==currentSpaceid)then
      return last
    else
      last=v
    end
  end
  error("NoCurrent Found",2)
end

function getPreviousSpaceId()
  local currentSpaceid=spaces.activeSpace()
  local cus=getCurrentUserSpace()
  local flag=false
  for k,v in pairs(cus) do
    if(flag)then
      return v
    end
    if(v==currentSpaceid)then
      flag=true
    end
  end
  return nil
end



function MoveWindowToSpace(sp)
  local win = hs.window.focusedWindow()      -- current window
  local uuid = win:screen():spacesUUID()     -- uuid for current screen
  local spaceID = spaces.layout()[uuid][sp]  -- internal index for sp
  if(spaceID==space.activeSpace()) then return end -- do nothing if the same screen
  spaces.moveWindowToSpace(win:id(), spaceID) -- move window to new space
  spaces.changeToSpace(spaceID,true)              -- follow window to new space
end

function MoveWindowOneSpace(direction)
  if(direction=="left")then
    local sp=getPreviousSpaceId()
    MoveWindowToSpace(sp)
  elseif(direction=="right")then
    MoveWindowToSpace(getNextSpaceId())
  else
    hs.alert(direction+"Error")
  end

end

hs.hotkey.bind({"ctrl","cmd","shift"},"left",
  function()
    -- MoveWindowOneSpace("left")
    print_r(table.filter( space.query(),function(k,v) return space.spaceType(v)==space.types.user end ))
  end
)

hs.hotkey.bind({"ctrl","cmd"},"R",
  function()
    t.reset()
    hs.alert("ok")
  end
)

local window = require "hs.window"
local mouse = require "hs.mouse"

function moveWindowOneSpace(direction)
  local win = window.focusedWindow()
  if not win then return end
  local clickPoint = win:zoomButtonRect()
  local mouseOrigin = hs.mouse.getAbsolutePosition()

  if inMove==0 then mouseOrigin = mouse.getAbsolutePosition() end
  clickPoint.x = clickPoint.x+clickPoint.w+5
  clickPoint.y = clickPoint.y+clickPoint.h/2
  if win:application():title() == 'Google Chrome' then
    local target=nil
    if(direction==".")then
      target=getNextSpaceId()
    elseif(direction==",") then
      target=getPreviousSpaceId()
    end

    if(target~=nil) then
      spaces.moveWindowToSpace(win:id(),target)
      -- spaces.changeToSpace(target,false)
    end

    hs.eventtap.keyStroke({"ctrl"},direction)
    return
  end
  local mouseClickEvent = hs.eventtap.event.newMouseEvent(
    hs.eventtap.event.types.leftMouseDown, clickPoint)
  mouseClickEvent:post()
  hs.eventtap.keyStroke({"ctrl"},direction)
  local mouseReleaseEvent = hs.eventtap.event.newMouseEvent(hs.eventtap.event.types.leftMouseUp, clickPoint):post()
  hs.mouse.setAbsolutePosition(mouseOrigin)
end

hs.hotkey.bind({"ctrl","shift","cmd"},"left",
  function()
    moveWindowOneSpace(",")
  end
)


hs.hotkey.bind({"ctrl","cmd","shift"},"right",
  function()
    moveWindowOneSpace(".")
  end
)


return obj
