# FlipbookAnimator

A lightweight class for playing sprite-sheet animations on `ImageLabel` and other 2D UI elements in Roblox.

Given a sprite sheet's dimensions and grid layout, `FlipbookAnimator` handles all frame calculations internally and advances through frames at a target FPS.

## Features

- **One-Shot** – Plays through the sprite sheet once and stops.
- **Infinite Loop** – Continuously loops until paused or destroyed.
- **Finite Repeat** – Plays through the sprite sheet a specified number of times and stops automatically.
- **Pause/Resume** – Playback can be paused and resumed at any time, retaining its current frame position (and repeat count for finite-repeat animations).
- **Completion Signal** – One-shot and finite-repeat animations fire `_Completed` when playback finishes.

## Dependencies

- [Trove](https://github.com/Sleitnick/RbxUtil) by Cody Nelson — used for cleanup/connection management.
- [GoodSignal](https://github.com/stravant/goodsignal) by stravant — used for the completion signal.

Both are expected to be located in `script.Parent.Parent` (the `Packages` folder).

## Installation

Place `FlipbookAnimator` inside a `Packages` (or similarly named) folder alongside `Trove` and `GoodSignal`, then require it:

```lua
local FlipbookAnimator = require(Packages.FlipbookAnimator)
```

## API

### Constructor

```lua
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
```

Returns a `Flipbook` instance.

| Field | Type | Default | Description |
|---|---|---|---|
| `Image` | `ImageLabel` | — | The image element to animate. |
| `ImageWidth` | `number` | — | Total width of the sprite sheet, in pixels. |
| `ImageHeight` | `number` | — | Total height of the sprite sheet, in pixels. |
| `Rows` | `number` | — | Number of rows in the sprite sheet grid. |
| `Columns` | `number` | — | Number of columns in the sprite sheet grid. |
| `FPS` | `number?` | `30` | Playback speed, in frames per second. |
| `Loop` | `boolean?` | `false` | If `true`, plays infinitely until paused/destroyed. |
| `RepeatCount` | `number?` | `0` | If greater than `0`, plays the sheet this many times then stops. |

### Methods

#### `:Play()`
Starts or resumes playback. Warns and does nothing if already playing.

#### `:Pause()`
Pauses playback while preserving the current frame (and repeat progress, for finite-repeat animations).

#### `:Destroy()`
Cleans up all resources and connections. Once destroyed, a new `Flipbook` must be created — the instance cannot be reused.

#### `:_DoLoop()`
Internal playback function. Exposed publicly but intended for internal use only.

### Signals

#### `._Completed`
Fires when a one-shot or finite-repeat animation completes.

```lua
flipbook._Completed:Connect(function()
    print("Animation Complete")
end)
```

## Usage Examples

### One-Shot

```lua
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
```

### Infinite Loop

```lua
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
```

### Finite Repeat

```lua
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
```

## Notes

- `Pause` stops playback at the current frame; calling `Play` again resumes from that position.
- `Destroy` fully tears down the Trove and disconnects all `_Completed` listeners — instances are not reusable after destruction.
- The `_Completed` signal does **not** fire for infinite-loop animations, since they have no natural end point.

## Author

**Grunion**
- Roblox: `@Grunionnn`
- Discord: `@grunion`
