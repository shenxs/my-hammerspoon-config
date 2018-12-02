local obj={}
obj.__index=obj

local hyper={"cmd"}
local desktop_hyper={"cmd","shift"}
local space_hyper={"ctrl","cmd"}
local move_space_hyper={"shift","ctrl","cmd"}
local space_mods={"ctrl"}

-- don't use left or right
-- not work here and i don't konw why
local space_left=","
local space_right="."

local function showPosition(f)
  hs.alert(f.x)
  hs.alert(f.y)
  hs.alert(f.h)
  hs.alert(f.w)
end

local function isLeft(f,max)
  return f.x==max.x and f.y==max.y and f.h==max.h and math.abs(f.w-max.w/2)<2
end

local function isRight(f,max)
  return math.abs(f.x-(max.x+ max.w/2))<2 and f.y==max.y and f.h==max.h and math.abs(f.w-max.w/2)<2
end

local function isLeftOrRight(f,max)
  return isLeft(f,max) or isRight(f,max)
end

local function isFull(f,max)
  return f.x==max.x and f.y==max.y and f.h==max.h and f.w==max.w
end

local function isQuater(f,max)
  return math.abs(f.w-max.w/2)<2 and math.abs(f.h-max.h/2)<2
end

local function isLeftUp(f,max)
  return isQuater(f,max) and f.x==max.x and f.y==max.y
end

local function isLeftDown(f,max)
  return isQuater(f,max) and f.x==max.x and math.abs(f.y-max.y-max.h/2)<2
end

local function isRightUp(f,max)
  return isQuater(f,max) and math.abs(f.x-(max.x+ max.w/2))<2 and f.y==max.y
end

local function isRightDown(f,max)
  return isQuater(f,max) and math.abs(f.x-(max.x+max.w/2))<2 and math.abs(f.y-max.y-max.h/2)<2
end

local function getNormal(max)
  -- showPosition(max)
  max.x=max.x+max.w*15/100
  max.y=max.h*15/100
  max.w=max.w*70/100
  max.h=max.h*70/100
  return max
end

local function moveLeft()
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
    win:moveToUnit'[15,15,85,85]'
  else
    win:moveToUnit'[0,0,50,100]'
  end

end

local function getCurrentUserSpace()
  return table.filter(
    spaces.query(),
    function(k,v)
      return spaces.spaceType(v)==spaces.types.user
    end
  )
end

local function printCurrentUserSpace()
  print_r(getCurrentUserSpace())
end

local function getNextSpaceId()
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

local function getPreviousSpaceId()
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

local function MoveWindowToSpace(sp)
  local win = hs.window.focusedWindow()      -- current window
  local uuid = win:screen():spacesUUID()     -- uuid for current screen
  local spaceID = spaces.layout()[uuid][sp]  -- internal index for sp
  if(spaceID==space.activeSpace()) then return end -- do nothing if the same screen
  spaces.moveWindowToSpace(win:id(), spaceID) -- move window to new space
  spaces.changeToSpace(spaceID,true)              -- follow window to new space
end

local function MoveWindowOneSpace(direction)
  if(direction=="left")then
    local sp=getPreviousSpaceId()
    MoveWindowToSpace(sp)
  elseif(direction=="right")then
    MoveWindowToSpace(getNextSpaceId())
  else
    hs.alert(direction+"Error")
  end
end


local function incaseApp(name)
  local apps={'Google Chrome','网易云音乐'}
  for k,v in pairs(apps) do
    if v==name then
      return true
    end
  end
  return false

end


local function moveWindowOneSpace(direction)
  local window = require "hs.window"
  local mouse = require "hs.mouse"
  local win = window.focusedWindow()
  if not win then return end
  local clickPoint = win:zoomButtonRect()
  local mouseOrigin = hs.mouse.getAbsolutePosition()

  if inMove==0 then mouseOrigin = mouse.getAbsolutePosition() end
  clickPoint.x = clickPoint.x+clickPoint.w+3
  clickPoint.y = clickPoint.y+clickPoint.h -3
  if incaseApp(win:application():title()) then
    local target=nil
    if(direction=="right")then
      target=getNextSpaceId()
    elseif(direction=="left") then
      target=getPreviousSpaceId()
    end

    if(target~=nil) then
      spaces.moveWindowToSpace(win:id(),target)
      -- spaces.changeToSpace(target,false)
    end

    if(direction=="left")then
      hs.eventtap.keyStroke(space_mods,space_left)
    elseif(direction=="right")then
      hs.eventtap.keyStroke(space_mods,space_right)
    end

    return
  end
  local mouseClickEvent = hs.eventtap.event.newMouseEvent(
    hs.eventtap.event.types.leftMouseDown, clickPoint)
  mouseClickEvent:post()
  if(direction=="left")then
    hs.eventtap.keyStroke(space_mods,space_left)
  elseif(direction=="right")then
    hs.eventtap.keyStroke(space_mods,space_right)
  end

  local mouseReleaseEvent = hs.eventtap.event.newMouseEvent(hs.eventtap.event.types.leftMouseUp, clickPoint):post()
  hs.mouse.setAbsolutePosition(mouseOrigin)
end

local function moveRight()
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

local function moveDown()
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


local function moveUp()
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

hs.hotkey.bind({"ctrl","cmd"},"R",function()  t.reset() end)
hs.hotkey.bind(hyper,"left",moveLeft)
hs.hotkey.bind(hyper,"right",moveRight)
hs.hotkey.bind(hyper,"up",moveUp)
hs.hotkey.bind(hyper,"down",moveDown)

hs.hotkey.bind(desktop_hyper,"left",function()
                 local win=hs.window.focusedWindow()
                 win:moveOneScreenWest()
end)

hs.hotkey.bind(desktop_hyper,"right",function()
                 local win=hs.window.focusedWindow()
                 win:moveOneScreenEast()
end)

hs.hotkey.bind(space_hyper,"left",function()
                 hs.eventtap.keyStroke(space_mods,space_left)
               end)

hs.hotkey.bind(space_hyper,"right",function()
                 hs.eventtap.keyStroke(space_mods,space_right)
end)

hs.hotkey.bind(move_space_hyper,"left",function()
                 moveWindowOneSpace("left")
               end)

hs.hotkey.bind(move_space_hyper,"right",function()
                 moveWindowOneSpace("right")
end)

return obj
