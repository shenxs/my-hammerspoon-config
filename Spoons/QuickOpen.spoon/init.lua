local application = require 'hs.application'

local obj={}
obj.__index=obj

-- Toggle an application between being the frontmost app, and being hidden
function toggle_application(_app)
  -- finds a running applications
  local app = application.find(_app)

  if not app then
    -- application not running, launch app
    application.launchOrFocus(_app)
    return
  end

  -- application running, toggle hide/unhide
  local mainwin = app:mainWindow()
  if mainwin then
    if true == app:isFrontmost() then
      mainwin:application():hide()
    else
      mainwin:application():activate(true)
      mainwin:application():unhide()
      mainwin:focus()
    end
  else
    -- no windows, maybe hide
    if true == app:hide() then
      -- focus app
      application.launchOrFocus(_app)
    else
      -- nothing to do
    end
  end
end


function open(name)
  return function()
    toggle_application(name)
    -- hs.application.launchOrFocus(name)
    -- if name == "Finder" then
    --   local f=hs.appfinder.appFromName("Finder")
    --   if(f~=nil) then
    --     f:activate()
    --   else
    --     print(f)
    --     hs.eventtap.keyStroke({"cmd"},"N")
    --   end

    -- end
  end
end

hs.hotkey.bind({"alt"}, "F", open("Finder"))
hs.hotkey.bind({"alt"}, "W", open("WeChat"))
hs.hotkey.bind({"alt"}, "G", open("Google Chrome"))
hs.hotkey.bind({"alt"}, ".", open("iTerm"))
hs.hotkey.bind({"alt"}, "I", open("IntelliJ IDEA"))
hs.hotkey.bind({"alt"}, "M", open("NeteaseMusic"))
hs.hotkey.bind({"alt"}, "E",
  function()
    os.execute("/usr/local/bin/emacsclient -c &")
    hs.application.launchOrFocus("Emacs")
  end
)

return obj
