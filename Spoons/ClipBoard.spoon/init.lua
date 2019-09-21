local obj={}
obj.__index=obj

local history = {}
function addHistoryFromPasteboard()
  local contentTypes = hs.pasteboard.contentTypes()

  local item = {}
  for index, uti in ipairs(contentTypes) do
    if uti == "public.utf8-plain-text" then
      local text = hs.pasteboard.readString()
      item.text = string.gsub(text, "[\r\n]+", " ")
      item.content = text;
      break
    end
  end
  table.insert(history,1,item)
end


local preChangeCount = hs.pasteboard.changeCount()
local watcher = hs.timer.new(0.5,
                             function ()
                               local changeCount = hs.pasteboard.changeCount()
                               if preChangeCount ~= changeCount then
                                 addHistoryFromPasteboard()
                                 preChangeCount = changeCount
                               end
end)

watcher:start()

clipboard = hs.chooser.new(function (choice)
    print(choice)
end)

hs.hotkey.bind({ "cmd", "alt" }, "c", function ()
    if clipboard:isVisible() then
      clipboard:hide()
    else
      clipboard:choices(history)
      clipboard:show()
    end
end)

clipboard = hs.chooser.new(function (choice)
    if choice then
      hs.pasteboard.setContents(choice.content)
      hs.eventtap.keyStroke({ "cmd" }, "v")
    end
end)

return obj
