--[[
Author: Grunion
Referrals: @Grunionnn (Roblox), @*grunion* (Discord)
Creation Date: 5/9/2026

Script Description:
    FlipbookAnimator is a lightweight class for playing sprite-sheet animations on
    ImageLabels and other 2D UI elements.

    Given a sprite sheet's dimensions and grid layout, FlipbookAnimator handles all
    frame calculations internally and advances through frames at a target FPS.

    Supports 3 playback modes:

        - One-Shot
            Plays through the sprite sheet once and stops.

        - Infinite Loop
            Continuously loops until paused or destroyed.

        - Finite Repeat
            Plays through the sprite sheet a specified number of times and
            automatically stops afterwards.

    Playback can be paused and resumed at any time. When paused, the animation
    retains its current frame position. For finite-repeat animations, the current
    repeat count is also preserved, allowing playback to continue from the exact
    point it was paused.

    One-shot and finite-repeat animations will fire the OnCompleted signal when
    playback finishes.

    Cleanup is handled through Trove (by Cody Nelson) and signals are powered by
    GoodSignal (by stravant).

API:

    ============ CONSTRUCTOR ============

    FlipbookAnimator.new({
        Image = ImageLabel,
        ImageWidth = number,
        ImageHeight = number,
        Rows = number,
        Columns = number,
        FPS = number?,
        Loop = boolean?,
        RepeatCount = number?
    })

    Returns a Flipbook instance.

    ============ METHODS ============

    :Play()
        Starts or resumes playback.

    :Pause()
        Pauses playback while preserving the current frame.

    :Destroy()
        Cleans up all resources and connections.
        Once destroyed, a new Flipbook must be created.

    :_DoLoop()
        Internal playback function.
        Exposed publicly but intended for internal use only.

    ============ SIGNALS ============

    ._Completed
        Fires when a one-shot or finite-repeat animation completes.

Usage:

    ============ One-Shot ============

    local flipbook = FlipbookAnimator.new({
        Image = ImageLabel,
        ImageWidth = 1024,
        ImageHeight = 1024,
        Rows = 4,
        Columns = 4,
        FPS = 24,
    })

    flipbook._Completed:Connect(function()
        print("Animation Complete")
        flipbook:Destroy()
    end)

    flipbook:Play()

    ============ Infinite Loop ============

    local flipbook = FlipbookAnimator.new({
        Image = ImageLabel,
        ImageWidth = 1024,
        ImageHeight = 1024,
        Rows = 4,
        Columns = 4,
        FPS = 24,
        Loop = true,
    })

    flipbook:Play()

    task.delay(15, function()
        flipbook:Pause()
    end)

    ============ Finite Repeat ============

    local flipbook = FlipbookAnimator.new({
        Image = ImageLabel,
        ImageWidth = 1024,
        ImageHeight = 1024,
        Rows = 4,
        Columns = 4,
        FPS = 24,
        RepeatCount = 3,
    })

    flipbook._Completed:Connect(function()
        print("Animation Complete")
        flipbook:Destroy()
    end)

    flipbook:Play()
]]

local FlipbookAnimator = {}
FlipbookAnimator.__index = FlipbookAnimator

local Packages = script.Parent.Parent :: Folder
local Trove = require(Packages.Trove)
local GoodSignal = require(Packages.GoodSignal)

-->> Types
export type FlipbookParameter ={ 
    Image: ImageLabel;
    ImageWidth: number;
    ImageHeight: number;
    Rows: number;
    Columns: number;
    FPS: number?;
    Loop: boolean?;
    RepeatCount: number?
}

export type FlipbookData = { 
    _Image : ImageLabel;
    _Width : number;
    _Height : number;
    _Rows : number;
    _Columns : number;
    _FPS : number;
    _Loop : boolean;
    _RepeatCount : number;
    _SpriteWidth: number;
    _SpriteHeight: number;
    _CurrentRow: number;
    _CurrentColumn: number;
    _CurrentCount: number;
    _Trove: typeof(Trove.new());
    _Completed: GoodSignal.Signal;
    _Playing: boolean;
    _Paused: boolean;
    _Looping: boolean
}

type Flipbook = typeof(setmetatable({} :: FlipbookData, FlipbookAnimator))

function FlipbookAnimator.new(Data: FlipbookParameter): Flipbook
    local self = setmetatable({} :: FlipbookData, FlipbookAnimator)

    self._Image = Data.Image
    self._Width = Data.ImageWidth
    self._Height = Data.ImageHeight

    self._Rows = Data.Rows
    self._Columns = Data.Columns

    self._FPS = Data.FPS or 30
    self._Loop = Data.Loop or false
    self._RepeatCount = Data.RepeatCount or 0

    self._SpriteWidth = self._Width / self._Columns
    self._SpriteHeight = self._Height / self._Rows

    self._CurrentRow = 1
    self._CurrentColumn = 1
    self._CurrentCount = 0

    self._Trove = Trove.new()
    self._Completed = GoodSignal.new()

    self._Image.ImageRectSize = Vector2.new(self._SpriteWidth, self._SpriteHeight)


    return self 
end

function FlipbookAnimator._DoLoop(self: Flipbook)
    for i = self._CurrentRow, self._Rows do 
        self._CurrentRow = i
        for j = self._CurrentColumn, self._Columns do
            self._CurrentColumn = j
            local offset = Vector2.new(self._SpriteWidth * self._CurrentColumn, self._SpriteHeight * self._CurrentRow)
            self._Image.ImageRectOffset = offset
            task.wait(1/self._FPS)
            if self.Paused then 
                break
            end
        end
        if self.Paused then 
            break
        end
        self._CurrentColumn = 1
    end
    if not self._Paused then 
        self._CurrentRow = 1
        self._CurrentColumn = 1    
    end
end

function FlipbookAnimator.Play(self: Flipbook)
    if self._Playing then 
        warn("[FlipbookAnimator]: Already playing")
        return
    end

    self._Playing = true
    self._Paused = false 

    self._Trove:Destroy()
    if self._Loop then 
        self._Looping = true 
        local thread = task.spawn(function()
            self:_DoLoop()
        end)

        self._Trove:Add(thread)
    elseif self._RepeatCount > 0 then
        local thread = task.spawn(function()
            for _ = 1, self._RepeatCount do 
                self:_DoLoop()
                if self._Paused then 
                    break
                end
            end
            if not self._Paused then 
                self._Completed:Fire()
                self._Playing = false
            end
        end)

        self._Trove:Add(thread)
    else 
        local thread = task.spawn(function()
            self:_DoLoop()
            self._Completed:Fire()
            self._Playing = false
        end)

        self._Trove:Add(thread)
    end
end

function FlipbookAnimator.Pause(self: Flipbook)
    self._Paused = true
    self._Playing = false
    self._Looping = false
end

function FlipbookAnimator.Destroy(self: Flipbook)
    self._Trove:Destroy()
    self._Completed:DisconnectAll()
    self._Playing = false
    self._Paused = false
    self._Looping = false
end

return FlipbookAnimator
