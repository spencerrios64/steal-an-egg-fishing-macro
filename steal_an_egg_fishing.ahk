#Requires AutoHotkey v2.0
#SingleInstance Force
; ============================================================
;  Steal An Egg - Alien Planet fishing macro  (v3, from both clips)
;
;  F1 = start/stop
;  F4 = SET PROMPT: hover the mouse over the "Hold to Cast" prompt, press F4
;  F5 / F6 = charge hold shorter / longer (25 ms steps) - tune for PERFECT
;  F2 = show what it currently sees     F3 = quit
;
;  What varies between casts is DETECTED, not timed:
;    - bite wait  : waits for the red STOP button (adaptive timeout, recasts right away)
;    - reel length: clicks until the STOP button is gone
;    - popup time : retries the cast until the charge bar really starts
;  Only the charge hold is a fixed time, because in both clips the bar
;  fills in ~1.0 s every time. Nudge it with F5/F6 if you miss PERFECT.
;
;  Everything is stored as a fraction of the Roblox window, so it works
;  in a small window or fullscreen (your two clips were different sizes).
; ============================================================

; ---- positions (fraction of Roblox window) ----
promptX := 0.570, promptY := 0.219            ; overwritten by F4
stopX1 := 0.66, stopY1 := 0.85                ; STOP button search box
stopX2 := 0.82, stopY2 := 0.96                ;   (same place in both clips)
clickX := 0.50, clickY := 0.60                ; where to spam-click while reeling

; ---- tuning ----
stopColor     := 0xCF3348   ; red STOP button
colTol        := 50
chargeHoldMs  := 1000       ; F5/F6 adjust this live
castAnimMs    := 1200       ; pause after releasing the cast
biteTimeoutMs := 12000     ; start value; adapts to the longest bite seen (10-25 s)
reelClickGap  := 45
reelMaxMs     := 15000
afterReelMs   := 1500       ; initial wait for reward popup; retries cover longer ones

running := false
casts := 0
lastBite := 0, lastReel := 0, maxBite := 0
CoordMode "Pixel", "Screen"
CoordMode "Mouse", "Screen"

Tip(t, ms := 1500) {
    ToolTip t
    SetTimer () => ToolTip(), -ms
}

Geo() {
    if !WinActive("ahk_exe RobloxPlayerBeta.exe")
        return false
    WinGetClientPos &x, &y, &w, &h, "A"
    return {x: x, y: y, w: w, h: h}
}

StopVisible(g) {
    return PixelSearch(&px, &py, g.x + Round(g.w * stopX1), g.y + Round(g.h * stopY1)
        , g.x + Round(g.w * stopX2), g.y + Round(g.h * stopY2), stopColor, colTol)
}

MoveTo(x, y) {
    MouseMove x, y, 0
    Sleep 15
    MouseMove x + 1, y, 0    ; tiny jiggle so Roblox registers the position
    MouseMove x, y, 0
    Sleep 15
}

F1:: {
    global running
    running := !running
    if running {
        SetTimer FishLoop, -10
        Tip("Fishing ON (F1 = stop)")
    } else {
        Click "Up"
        Tip("Fishing OFF")
    }
}
F3::ExitApp

F4:: {
    global promptX, promptY
    g := Geo()
    if !g {
        Tip("Click into Roblox first")
        return
    }
    MouseGetPos &mx, &my
    promptX := (mx - g.x) / g.w
    promptY := (my - g.y) / g.h
    Tip("Prompt position saved")
}
F5:: {
    global chargeHoldMs
    chargeHoldMs -= 25
    Tip("Charge hold: " chargeHoldMs " ms")
}
F6:: {
    global chargeHoldMs
    chargeHoldMs += 25
    Tip("Charge hold: " chargeHoldMs " ms")
}
F2:: {
    g := Geo()
    if !g {
        Tip("Roblox window not found / not active")
        return
    }
    Tip("Window " g.w "x" g.h "`nSTOP button visible: " (StopVisible(g) ? "YES" : "no")
        . "`nCharge hold: " chargeHoldMs " ms`nCasts: " casts
        . "`nLast bite wait: " lastBite " ms   last reel: " lastReel " ms", 5000)
}

FishLoop() {
    global running, casts, lastBite, lastReel, maxBite, biteTimeoutMs
    while running {
        g := Geo()
        if !g {
            Tip("Click into Roblox...")
            Sleep 500
            continue
        }

        ; 1. hold on the Hold-to-Cast prompt for the charge time, then release
        MoveTo(g.x + Round(g.w * promptX), g.y + Round(g.h * promptY))
        Click "Down"
        Sleep chargeHoldMs
        Click "Up"
        casts++

        ; 2. wait for the bite = red STOP button (random length)
        Sleep castAnimMs
        t0 := A_TickCount, bit := false
        while running && A_TickCount - t0 < biteTimeoutMs {
            g := Geo()
            if g && StopVisible(g) {
                bit := true
                break
            }
            Sleep 20
        }
        if !bit {
            continue          ; no bite: recast immediately
        }
        lastBite := A_TickCount - t0 + castAnimMs
        maxBite := Max(maxBite, lastBite)
        biteTimeoutMs := Min(25000, Max(10000, Round(maxBite * 1.8)))

        ; 3. spam click until the STOP button is gone (random length)
        MoveTo(g.x + Round(g.w * clickX), g.y + Round(g.h * clickY))
        t1 := A_TickCount, gone := 0
        while running && A_TickCount - t1 < reelMaxMs {
            Click
            Sleep reelClickGap
            g := Geo()
            if g && !StopVisible(g) {
                gone++
                if gone >= 4
                    break
            } else
                gone := 0
        }
        lastReel := A_TickCount - t1

        ; 4. reward popup, then loop (a too-early cast just retries)
        Sleep afterReelMs
    }
}
#Requires AutoHotkey v2.0
#SingleInstance Force
; ============================================================
;  Steal An Egg - Alien Planet fishing macro  (v3, from both clips)
;
;  F1 = start/stop
;  F4 = SET PROMPT: hover the mouse over the "Hold to Cast" prompt, press F4
;  F5 / F6 = charge hold shorter / longer (25 ms steps) - tune for PERFECT
;  F2 = show what it currently sees     F3 = quit
;
;  What varies between casts is DETECTED, not timed:
;    - bite wait  : waits for the red STOP button (any length, 40 s max)
;    - reel length: clicks until the STOP button is gone
;    - popup time : retries the cast until the charge bar really starts
;  Only the charge hold is a fixed time, because in both clips the bar
;  fills in ~1.0 s every time. Nudge it with F5/F6 if you miss PERFECT.
;
;  Everything is stored as a fraction of the Roblox window, so it works
;  in a small window or fullscreen (your two clips were different sizes).
; ============================================================

; ---- positions (fraction of Roblox window) ----
promptX := 0.570, promptY := 0.219            ; overwritten by F4
stopX1 := 0.66, stopY1 := 0.85                ; STOP button search box
stopX2 := 0.82, stopY2 := 0.96                ;   (same place in both clips)
clickX := 0.50, clickY := 0.60                ; where to spam-click while reeling

; ---- tuning ----
stopColor     := 0xCF3348   ; red STOP button
colTol        := 50
chargeHoldMs  := 1000       ; F5/F6 adjust this live
castAnimMs    := 1200       ; pause after releasing the cast
biteTimeoutMs := 40000
reelClickGap  := 45
reelMaxMs     := 15000
afterReelMs   := 2500       ; initial wait for reward popup; retries cover longer ones

running := false
casts := 0
lastBite := 0, lastReel := 0
CoordMode "Pixel", "Screen"
CoordMode "Mouse", "Screen"

Tip(t, ms := 1500) {
    ToolTip t
    SetTimer () => ToolTip(), -ms
}

Geo() {
    if !WinActive("ahk_exe RobloxPlayerBeta.exe")
        return false
    WinGetClientPos &x, &y, &w, &h, "A"
    return {x: x, y: y, w: w, h: h}
}

StopVisible(g) {
    return PixelSearch(&px, &py, g.x + Round(g.w * stopX1), g.y + Round(g.h * stopY1)
        , g.x + Round(g.w * stopX2), g.y + Round(g.h * stopY2), stopColor, colTol)
}

MoveTo(x, y) {
    MouseMove x, y, 0
    Sleep 15
    MouseMove x + 1, y, 0    ; tiny jiggle so Roblox registers the position
    MouseMove x, y, 0
    Sleep 15
}

F1:: {
    global running
    running := !running
    if running {
        SetTimer FishLoop, -10
        Tip("Fishing ON (F1 = stop)")
    } else {
        Click "Up"
        Tip("Fishing OFF")
    }
}
F3::ExitApp

F4:: {
    global promptX, promptY
    g := Geo()
    if !g {
        Tip("Click into Roblox first")
        return
    }
    MouseGetPos &mx, &my
    promptX := (mx - g.x) / g.w
    promptY := (my - g.y) / g.h
    Tip("Prompt position saved")
}
F5:: {
    global chargeHoldMs
    chargeHoldMs -= 25
    Tip("Charge hold: " chargeHoldMs " ms")
}
F6:: {
    global chargeHoldMs
    chargeHoldMs += 25
    Tip("Charge hold: " chargeHoldMs " ms")
}
F2:: {
    g := Geo()
    if !g {
        Tip("Roblox window not found / not active")
        return
    }
    Tip("Window " g.w "x" g.h "`nSTOP button visible: " (StopVisible(g) ? "YES" : "no")
        . "`nCharge hold: " chargeHoldMs " ms`nCasts: " casts
        . "`nLast bite wait: " lastBite " ms   last reel: " lastReel " ms", 5000)
}

FishLoop() {
    global running, casts, lastBite, lastReel
    while running {
        g := Geo()
        if !g {
            Tip("Click into Roblox...")
            Sleep 500
            continue
        }

        ; 1. hold on the Hold-to-Cast prompt for the charge time, then release
        MoveTo(g.x + Round(g.w * promptX), g.y + Round(g.h * promptY))
        Click "Down"
        Sleep chargeHoldMs
        Click "Up"
        casts++

        ; 2. wait for the bite = red STOP button (random length)
        Sleep castAnimMs
        t0 := A_TickCount, bit := false
        while running && A_TickCount - t0 < biteTimeoutMs {
            g := Geo()
            if g && StopVisible(g) {
                bit := true
                break
            }
            Sleep 20
        }
        if !bit {
            Sleep 800
            continue          ; cast didn't land / timed out: try again
        }
        lastBite := A_TickCount - t0 + castAnimMs

        ; 3. spam click until the STOP button is gone (random length)
        MoveTo(g.x + Round(g.w * clickX), g.y + Round(g.h * clickY))
        t1 := A_TickCount, gone := 0
        while running && A_TickCount - t1 < reelMaxMs {
            Click
            Sleep reelClickGap
            g := Geo()
            if g && !StopVisible(g) {
                gone++
                if gone >= 4
                    break
            } else
                gone := 0
        }
        lastReel := A_TickCount - t1

        ; 4. reward popup, then loop (a too-early cast just retries)
        Sleep afterReelMs
    }
}
