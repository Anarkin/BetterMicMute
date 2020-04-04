--- === BetterMicMute ===
---
--- Microphone mute toggle and status indicator
---
--- Additionally, whenever an external process changes input settings, the spoon will override to the user's original intention
---
--- To configure, override the spoon.config table, e.g.
---    spoon.BetterMicMute.config.menuTextMuted = "lalala"

local spoon = {}

spoon.name = "BetterMicMute"
spoon.version = "1.0"
spoon.author = "Adam Lengyel"
spoon.license = "MIT"

spoon.config = {
    menuTextMuted = "⚪",
    menuTextNotMuted = "🔴",
    detectChangesByOtherProcessesIntervalSeconds = 0.5
}

--- BetterMicMute:bindHotkeys(map)
--- Method
--- Binds hotkeys for BetterMicMute
---
--- Parameters:
---  * map - A table expecting toggleModifiers and toggleKey
function spoon:bindHotkeys(map)
    hs.hotkey.bind(map.toggleModifiers, map.toggleKey, function()
        self:toggleMute()
        self:applyMuteOnSystem()
    end)
end

spoon.isMuted = true
function spoon:toggleMute()
    self.isMuted = not self.isMuted
end
function spoon:applyMuteOnSystem()
    for _, device in pairs(hs.audiodevice.allInputDevices()) do
        device:setInputMuted(self.isMuted)
    end

    self:setMenuIconTitle()
end

spoon.menuIcon = nil
function spoon:setMenuIconTitle()
    if self.isMuted then
        self.menuIcon:setTitle(self.config.menuTextMuted)
    else
        self.menuIcon:setTitle(self.config.menuTextNotMuted)
    end
end

function spoon:init()
    self.overrideTimer = hs.timer.new(self.config.detectChangesByOtherProcessesIntervalSeconds, function()
        for _, device in pairs(hs.audiodevice.allInputDevices()) do
            local hasChangedByExternal = device:inputMuted() ~= self.isMuted
            if hasChangedByExternal then
                hs.alert.show("(input settings were changed)")
                self:applyMuteOnSystem()
                break
            end
        end
    end)

    self.menuIcon = hs.menubar.new()
    self.menuIcon:setClickCallback(function()
        self:toggleMute()
        self:applyMuteOnSystem()
    end)

    hs.audiodevice.watcher.setCallback(function()
        self:applyMuteOnSystem()
    end)
end

function spoon:start()
    self.overrideTimer:start()
    hs.audiodevice.watcher.start()
    self:applyMuteOnSystem()
end

function spoon:stop()
    self.overrideTimer:stop()
    hs.audiodevice.watcher.stop()
    self.menuIcon:removeFromMenuBar()
    self.menuIcon:delete()
end

return spoon
