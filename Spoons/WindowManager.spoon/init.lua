local obj={}
obj.__index=obj

local log = hs.logger.new('WindowsManager','debug')

local hyper={"cmd"}
local desktop_hyper={"cmd","shift"}
local space_hyper={"ctrl","cmd"}
local move_space_hyper={"shift","ctrl","cmd"}
local space_mods={"ctrl"}

-- don't use left or right
-- not work here and i don't konw why
local space_left=","
local space_right="."


-- store frame size with windows Id
local prevFrameSizes = {}

local function near(a ,b)
  local tolerence=20
  return math.abs(a-b)<tolerence
end

local function isLeft(f,max)
  local re = near(f.x,max.x) and near(f.y,max.y) and  near( f.h,max.h) and near(f.w,max.w/2)
  return re
end

local function isRight(f,max)
   local re=near(f.x,(max.x+ max.w/2)) and near(f.y,max.y) and near(f.h,max.h) and near(f.w,max.w/2)
   return re
end

local function isLeftOrRight(f,max)
  return isLeft(f,max) or isRight(f,max)
end

local function isFull(f,max)
  return  near(f.x,max.x) and  near(f.y,max.y) and near(f.h,max.h) and near(f.w,max.w)
end

local function isQuater(f,max)
  return near(f.w,max.w/2) and near(f.h,max.h/2)
end

local function isLeftUp(f,max)
  return isQuater(f,max) and near(f.x,max.x) and near(f.y,max.y)
end

local function isLeftDown(f,max)
  return isQuater(f,max) and near(f.x,max.x) and near(f.y-max.y,max.h/2)
end

local function isRightUp(f,max)
  return isQuater(f,max) and near(f.x,(max.x+ max.w/2)) and near(f.y,max.y)
end

local function isRightDown(f,max)
  return isQuater(f,max) and near(f.x,(max.x+max.w/2)) and near(f.y-max.y,max.h/2)
end

local function hideDock()
  hs.osascript.applescript("\
    tell application \"System Events\"\
    set the autohide of the dock preferences to true\
    end tell\
    ")
end

local function unHideDock()
  hs.osascript.applescript("\
    tell application \"System Events\"\
    set the autohide of the dock preferences to false\
    end tell\
    ")
end


local function getNormal(id,max)
  if prevFrameSizes[id] then
    local re=prevFrameSizes[id]
    re.x=max.x+ max.w/2-re.w/2
    re.y=max.y+ max.h/2-re.h/2
    return re

  else
    max.x=max.x+max.w*15/100
    max.y=max.h*15/100
    max.w=max.w*70/100
    max.h=max.h*70/100
    prevFrameSizes[id]=max
    return max
  end
end

local function getCurrentUserSpace()
  local win = hs.window.focusedWindow()      -- current window
  local uuid = win:screen():spacesUUID()     -- uuid for current screen

  return table.filter(
    spaces.layout()[uuid],
    function(k,v)
      return spaces.spaceType(v)==spaces.types.user
    end
  )
end

local function printCurrentUserSpace()
  print_r(getCurrentUserSpace())
end

local function getNextSpaceId(curr)
  local currentSpaceid=curr
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
  -- error("NoCurrent Found",2)
  return nil
end

local function getPreviousSpaceId(curr)
  local currentSpaceid=curr
  local cus=getCurrentUserSpace()
  local last=nil
  for k,v in pairs(cus) do
    if(v==currentSpaceid)then
      return last
    else
      last=v
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
  -- local apps={'Google Chrome','网易云音乐','Dash','iTerm2'}
  return true
  -- for k,v in pairs(apps) do
  --   if v==name then
  --     return true
  --   end
  -- end
  -- return false
end

local inMove=0
local win=0
local currentSpaceid=0

local function moveWindowOneSpace(direction)
  local function moveOneSpace()
    if(direction=="left")then
      hs.eventtap.keyStroke(space_mods,space_left)
    elseif(direction=="right")then
      hs.eventtap.keyStroke(space_mods,space_right)
    end
  end
  local window = require "hs.window"
  local mouse = require "hs.mouse"
  if inMove == 0 then
    win = window.focusedWindow()
    currentSpaceid=spaces.activeSpace()
  end
  if not win then return end
  local clickPoint = win:zoomButtonRect()
  local mouseOrigin = hs.mouse.getAbsolutePosition()

  if incaseApp(win:application():title()) then

    local target=nil
    if(direction=="right")then
      target=getNextSpaceId(currentSpaceid)
    elseif(direction=="left") then
      target=getPreviousSpaceId(currentSpaceid)
    end

    if(target~=nil) then
      currentSpaceid=target
      spaces.moveWindowToSpace(win:id(),target)
      -- spaces.changeToSpace(target,false)
    end
    inMove=inMove+1
    moveOneSpace()
    hs.timer.doAfter(0.4,function()
                       inMove=math.max(0,inMove-1)
                         end
    )
    return
  end

  if win:title()~="" then
    win:focus()
  end

  clickPoint.x = clickPoint.x+clickPoint.w+5
  clickPoint.y = clickPoint.y+clickPoint.h/2
  local mouseClickEvent = hs.eventtap.event.newMouseEvent(hs.eventtap.event.types.leftMouseDown, clickPoint)
  local mouseReleaseEvent = hs.eventtap.event.newMouseEvent(hs.eventtap.event.types.leftMouseUp, clickPoint)

  mouseClickEvent:post()
  moveOneSpace()
  inMove=inMove+1
  hs.timer.doAfter(.1,function()
                     hs.timer.doAfter(.3 ,function()
                                        mouseReleaseEvent:post()
                                        inMove=math.max(0,inMove-1)
                                        if inMove==0 then
                                          hs.mouse.setAbsolutePosition(mouseOrigin)
                                        end
                                          end
                     )
                      end
  )

end

local function moveLeft()
  local win=hs.window.focusedWindow()
  local f=win:frame()
  local screen=win:screen()
  local max =screen:fullFrame()
  local sf = screen:frame()
  max.y=sf.y
  max.h=max.h-sf.y

  if(isRightDown(f,max) or isRightUp(f,max))then
    f.x=max.x
  elseif(isLeftUp(f,max) or isLeftDown(f,max))then
    f.y=max.y
    f.h=max.h
  elseif(isRight(f,max))then
    unHideDock()
    f=getNormal(win:id(), max)
  elseif(isLeft(f,max)) then
    hideDock()
    return
  elseif(isFull(f,max)) then
    f.x=max.x
    f.y=max.y
    f.w=max.w/2
    f.h=max.h
  else
    hideDock()
    prevFrameSizes[win:id()] = hs.geometry.copy(f)
    f.x=max.x
    f.y=max.y
    f.w=max.w/2
    f.h=max.h
  end
  win:setFrame(f)
end

local function moveRight()
  local win=hs.window.focusedWindow()
  local f=win:frame()
  local screen=win:screen()
  local max =screen:fullFrame()
  local sf = screen:frame()
  max.y=sf.y
  max.h=max.h-sf.y

  unHideDock()
  if(isLeftDown(f,max) or isLeftUp(f,max))then
    f.x=max.x+max.w/2
  elseif(isRightUp(f,max) or isRightDown(f,max))then
    f.y=max.y
    f.h=max.h
  elseif(isRight(f,max)) then
    return
  elseif(isFull(f,max))then
    f.x=max.x+max.w/2
    f.y=max.y
    f.w=max.w/2
    f.h=max.h
  elseif(isLeft(f,max))then
    f=getNormal(win:id(),max)
  else
    prevFrameSizes[win:id()] = hs.geometry.copy(f)
    f.x=max.x+max.w/2
    f.y=max.y
    f.w=max.w/2
    f.h=max.h
  end
  win:setFrame(f)
end

local function moveDown()
  local win=hs.window.focusedWindow()
  local f=win:frame()
  local screen=win:screen()
  local sf = screen:frame()
  local max =screen:fullFrame()
  max.y=sf.y
  max.h=max.h-sf.y

  if(isFull(f,max))then
    f=getNormal(win:id(),max)
    unHideDock()
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
  local sf = screen:frame()
  local max =screen:fullFrame()
  max.y=sf.y
  max.h=max.h-sf.y

  if(isLeftOrRight(f,max))then
    f.h=max.h/2
  elseif(isLeftDown(f,max) or isRightDown(f,max))then
    f.y=max.y
    f.h=max.h
  elseif(isLeftUp(f,max) or isRightUp(f,max)) then
    hideDock()
    f=max
  elseif(isFull(f,max)) then
    hideDock()
    return
  else
    hideDock()
    prevFrameSizes[win:id()] = hs.geometry.copy(f)
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
                 hideDock()
                 local win=hs.window.focusedWindow()
                 win:moveOneScreenWest()
end)

hs.hotkey.bind(desktop_hyper,"up",function()
                 hideDock()
                 local win=hs.window.focusedWindow()
                 win:moveOneScreenNorth(true)
end)

hs.hotkey.bind(desktop_hyper,"down",function()
                 hideDock()
                 local win=hs.window.focusedWindow()
                 win:moveOneScreenSouth(true)
end)


hs.hotkey.bind(desktop_hyper,"right",function()
                 hideDock()
                 local win=hs.window.focusedWindow()
                 win:moveOneScreenEast()
                 -- unHideDock()
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
