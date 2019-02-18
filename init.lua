spaces= require("hs._asm.undocumented.spaces")
t=dofile("transition.lua")

dofile("utility.lua")

-- global setting
hs.hotkey.showHotkeys({"alt","ctrl"},"s")
hs.hotkey.bind({"alt", "ctrl"}, "R", function() hs.reload() end)
hs.window.animationDuration=0

hs.hotkey.bind({"alt"},"B",
  function()
    result= hs.execute("auth",true)
    hs.alert(result)
  end
)

hs.loadSpoon("Wifi")
hs.loadSpoon("QuickOpen")
hs.loadSpoon("AutoReload")
hs.loadSpoon("WindowManager")
-- hs.loadSpoon("SpeedMenu")
