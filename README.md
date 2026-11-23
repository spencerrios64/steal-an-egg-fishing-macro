# Steal An Egg – Fishing Macro (AutoHotkey v2)

An auto-fishing macro for the **Alien Planet** fishing in the Roblox game *Steal An Egg*. It casts, releases the charge bar, waits for the bite, spam-clicks the "Click Fast!" / "Tap Fast!" reel, and repeats.

## Two versions: pick one

| Version | Files | Needs |
|---|---|---|
| **AutoHotkey** | `steal_an_egg_fishing.ahk` | AutoHotkey v2 installed (see [Install](#install)) |
| **No install (PowerShell)** | `steal_an_egg_fishing.ps1` + `run_fishing.bat` | Nothing. PowerShell is built into Windows 10/11 |

Both do exactly the same thing, use the same hotkeys and have the same settings. The rest of this README is written for the AutoHotkey version; the PowerShell differences are below.

### No-install version (PowerShell)

1. Download this repo (**Code → Download ZIP**) and extract it. Keep `run_fishing.bat` and `steal_an_egg_fishing.ps1` in the **same folder**.
2. Double-click **`run_fishing.bat`**. A console window opens. **Keep it open** while fishing.
3. Go to the fishing pier in Roblox, hover your mouse over the **"Hold to Cast"** prompt and press **`F4`**.
4. Press **`F1`** to start and stop. **`F3`** quits. The hotkeys work while Roblox has focus.

Differences from the AutoHotkey version:

- Status messages (casts, bite wait, reel time, `F2` status) print in the console window instead of as tooltips.
- Settings are the variables at the top of `steal_an_egg_fishing.ps1` (open it in Notepad). The names are the same but start with `$`, for example `$chargeHoldMs = 1000`. Save the file and run `run_fishing.bat` again to apply changes.
- The STOP button color is split into three numbers: `$stopR`, `$stopG`, `$stopB` (default `0xCF`, `0x33`, `0x48`).
- If Windows or your antivirus blocks the `.bat` file, right-click it and choose **Run anyway**, or open PowerShell in the folder and run `powershell -ExecutionPolicy Bypass -File .\steal_an_egg_fishing.ps1`.

> **Not tested on a live Windows machine yet.** Built from screen recordings of the game. Expect to tune it (see [Changing settings](#changing-settings)). Roblox's rules prohibit cheating tools; a simple auto-clicker like this is a gray area. **Use at your own risk.**

## How the game's fishing works (what the macro automates)

1. Stand at the pool. A **"Hold to Cast"** prompt appears. Hold the mouse on it.
2. A vertical **CHARGE** bar fills in about 1 second. Releasing when it reaches the gold zone gives **PERFECT!** (x1.5 Luck).
3. After a random wait (about 4–5 s in the recordings) a **red STOP button** appears with **"Click Fast!"**.
4. Click as fast as you can for a couple of seconds until the bar is full and the STOP button disappears.
5. A reward popup shows, then the prompt returns.

## What is adaptive and what is fixed

| Part | How it is handled |
|---|---|
| Bite wait | Detected: waits for the red STOP button (up to 40 s) |
| Reel length | Detected: clicks until the STOP button is gone |
| Reward popup | Retried: if it casts too early, nothing happens and it retries |
| Charge hold | **Fixed time** (default 1000 ms), because the bar fills in about 1 s every time. Tune with F5/F6 |

All positions are stored as a **fraction of the Roblox window**, so it works in a small window or fullscreen.

## Install

1. Use **Windows**. (AutoHotkey v2 is Windows-only.)
2. Install **AutoHotkey v2** from <https://www.autohotkey.com/> (choose **v2.0**, not v1.1).
3. Download this repo: click **Code → Download ZIP** on GitHub and extract it, or run `git clone https://github.com/spencerrios64/steal-an-egg-fishing-macro.git`.
4. Double-click **`steal_an_egg_fishing.ahk`**. A green **H** icon appears in the system tray. That means it is running.

## Use

1. Open Roblox, join *Steal An Egg*, and go to the **Alien Planet** fishing pier.
2. Equip the **fishing rod** and face the water so the **"Hold to Cast"** prompt is visible.
3. **Hover your mouse over the "Hold to Cast" prompt and press `F4`.** This saves the prompt position. Do this once per session, and again if you move or change the camera.
4. Make sure the Roblox window is the active window (click on it).
5. Press **`F1`** to start. Press **`F1`** again to stop.
6. Close any popup that covers the screen (for example the "Fishing Milestone" window). The macro does not close it.

### Hotkeys

| Key | What it does |
|---|---|
| `F1` | Start / stop fishing |
| `F2` | Show what the macro sees: window size, whether the STOP button is detected, charge hold, casts, last bite wait and reel time |
| `F3` | Quit the script |
| `F4` | Save the "Hold to Cast" prompt position (hover the mouse over it first) |
| `F5` | Shorten the charge hold by 25 ms |
| `F6` | Lengthen the charge hold by 25 ms |

### Getting PERFECT casts

If you do not get "PERFECT!" every time, press `F5` or `F6` while it runs to nudge the charge hold shorter or longer by 25 ms until it does. The tooltip shows the new value. To make it permanent, set `chargeHoldMs` in the file (see below).

## Changing settings

Open `steal_an_egg_fishing.ahk` in Notepad (right-click → Edit Script). The settings are at the top of the file. Save the file, then right-click the tray icon → **Reload Script** (or just double-click the file again).

| Setting | Default | Meaning |
|---|---|---|
| `promptX`, `promptY` | `0.570`, `0.219` | Position of the "Hold to Cast" prompt as a fraction of the window (0–1). `F4` overwrites this while running |
| `stopX1`, `stopY1`, `stopX2`, `stopY2` | `0.66, 0.85, 0.82, 0.96` | Search box where the red STOP button appears (top-left and bottom-right corners, as fractions of the window) |
| `clickX`, `clickY` | `0.50`, `0.60` | Where to click while reeling. Keep it away from the STOP button |
| `stopColor` | `0xCF3348` | Color of the STOP button |
| `colTol` | `50` | How much the color may differ (0–255). Raise it if the STOP button is missed, lower it if it reacts to other red things |
| `chargeHoldMs` | `1000` | How long to hold the cast charge, in ms |
| `castAnimMs` | `1200` | Pause after releasing the cast before looking for the bite |
| `biteTimeoutMs` | `40000` | How long to wait for a bite before recasting |
| `reelClickGap` | `45` | Milliseconds between clicks while reeling. Lower is faster |
| `reelMaxMs` | `15000` | Safety limit for the reel phase |
| `afterReelMs` | `2500` | Wait after a catch for the reward popup before casting again |

### Fraction coordinates

A fraction is the position divided by the window size. `0.5, 0.5` is the exact center, `0, 0` the top-left, `1, 1` the bottom-right. To find a spot, press `F2` for the window size, work out the pixel position, and divide by the width (x) and height (y).

## Troubleshooting

- **Nothing happens when I press F1:** click on the Roblox window first. The macro only acts while Roblox is the active window.
- **It never starts reeling:** press `F2` while the red STOP button is on screen. If it says "no", raise `colTol` or widen the `stop...` box.
- **It holds on the wrong spot:** hover over the "Hold to Cast" prompt and press `F4` again.
- **It casts, but not PERFECT:** use `F5` / `F6` to tune the charge hold.
- **The cursor does not move in Roblox:** run the script as administrator (right-click → Run as administrator) if Roblox is running as administrator.
- **Different screen layout or game update:** the colors and positions were measured from recordings and may change. Adjust the settings above.

## License

MIT. See [LICENSE](LICENSE).
