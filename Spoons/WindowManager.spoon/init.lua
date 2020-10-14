local obj={}
obj.__index=obj

local log = hs.logger.new('WindowsManager','debug')
local spaces = require('hs._asm.undocumented.spaces')
local hyper={"alt"}
local desktop_hyper={"alt","shift"}
local move_space_hyper={"shift","ctrl"}
local space_mods={"ctrl"}
local space_hyper={"ctrl","cmd"}

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
   -- log.i("frame=",f)
   -- log.i("max=",max)
   local re = near(f.x,max.x) and near(f.y,max.y) and  near( f.h,max.h) and near(f.w,max.w/2)
   -- log.i("re= ",re)
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
   if false then
      hs.osascript.applescript("\
    tell application \"System Events\"\
    set the autohide of the dock preferences to true\
    end tell\
    ")
   end
end

local function unHideDock()
   if false then
      hs.osascript.applescript("\
    tell application \"System Events\"\
    set the autohide of the dock preferences to false\
    end tell\
    ")
   end
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

   local spacesLayout = spaces.layout()
   print_r(spacesLayout)
   -- log.i(uuid)
   print_r(spaces.layout())
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


   local target=nil
   if(direction=="right")then
      target=getNextSpaceId(currentSpaceid)
   elseif(direction=="left") then
      target=getPreviousSpaceId(currentSpaceid)
   end

   if(target~=nil) then
      currentSpaceid=target
      spaces.moveWindowToSpace(win:id(),target)
   end
   inMove=inMove+1
   moveOneSpace()
   hs.timer.doAfter(0.4,function()
		       inMove=math.max(0,inMove-1)
			end
   )
   return

end

local function moveLeft()
   local win=hs.window.focusedWindow()
   local f=win:frame()
   local screen=win:screen()
   local max = screen:frame()

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
      win:moveToUnit'[0,0,50,100]'
      return
   else
      hideDock()
      prevFrameSizes[win:id()] = hs.geometry.copy(f)
      win:moveToUnit'[0,0,50,100]'
      return
   end
   win:setFrame(f)
end

local function moveRight()
   local win=hs.window.focusedWindow()
   local f=win:frame()
   local screen=win:screen()
   local max = screen:frame()

   if(isLeftDown(f,max) or isLeftUp(f,max))then
      f.x=max.x+max.w/2
   elseif(isRightUp(f,max) or isRightDown(f,max))then
      f.y=max.y
      f.h=max.h
   elseif(isRight(f,max)) then
      return
   elseif(isFull(f,max))then
      win:moveToUnit'[50,0,100,100]'
      return
   elseif(isLeft(f,max))then
      f=getNormal(win:id(),max)
   else
      prevFrameSizes[win:id()] = hs.geometry.copy(f)
      win:moveToUnit'[50,0,100,100]'
      return
   end
   win:setFrame(f)
end

local function moveDown()
   local win=hs.window.focusedWindow()
   local f=win:frame()
   local screen=win:screen()
   local max = screen:frame()

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
   local max = screen:frame()

   if(isLeftOrRight(f,max))then
      f.h=max.h/2
   elseif(isLeftDown(f,max) or isRightDown(f,max))then
      f.y=max.y
      f.h=max.h
   elseif(isLeftUp(f,max) or isRightUp(f,max)) then
      hideDock()
      win:moveToUnit'[0,0,100,100]'
      return
   elseif(isFull(f,max)) then
      hideDock()
      return
   else
      hideDock()
      prevFrameSizes[win:id()] = hs.geometry.copy(f)
      win:moveToUnit'[0,0,100,100]'
      return
   end
   win:setFrame(f)
end

hs.hotkey.bind({"ctrl","cmd"},"R",function()  t.reset() end)
hs.hotkey.bind(hyper,"left",moveLeft)
hs.hotkey.bind(hyper,"right",moveRight)
hs.hotkey.bind(hyper,"up",moveUp)
hs.hotkey.bind(hyper,"down",moveDown)

hs.hotkey.bind(desktop_hyper,"left",function()
		  -- hideDock()
		  local win=hs.window.focusedWindow()
		  win:moveOneScreenWest()
end)

hs.hotkey.bind(desktop_hyper,"up",function()
		  -- hideDock()
		  local win=hs.window.focusedWindow()
		  win:moveOneScreenNorth()
end)

hs.hotkey.bind(desktop_hyper,"down",function()
		  -- hideDock()
		  local win=hs.window.focusedWindow()
		  win:moveOneScreenSouth(true)
end)


hs.hotkey.bind(desktop_hyper,"right",function()
		  -- hideDock()
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
