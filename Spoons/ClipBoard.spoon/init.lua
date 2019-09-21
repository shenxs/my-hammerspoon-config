local obj={}
obj.__index=obj

clipboard = hs.chooser.new(function (choice)
    print(choice)
end)

hs.hotkey.bind({ "cmd", "alt" }, "c", function ()
    clipboard:show()
end)

return obj
