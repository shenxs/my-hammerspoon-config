local obj={}
obj.__index=obj

wifiWatcher = nil
classroomWifi= "CST_WLAN"
labWifi="LEDE"
lastSSID = hs.wifi.currentNetwork()

function ssidChangedCallback()
  local newSSID = hs.wifi.currentNetwork()
  if newSSID == classroomWifi and lastSSID ~= classroomWifi then
    local result=hs.execute("auth",true)
    -- hs.alert(result)
    -- print(result)
    hs.notify.new({title="自动登录", informativeText=result}):send()
  elseif(newSSID ==labWifi and lastSSID ~= labWifi) then
    hs.alert("Hello Lab! ，加油")
  end
  lastSSID = newSSID
end

wifiWatcher = hs.wifi.watcher.new(ssidChangedCallback)
wifiWatcher:start()

return obj
