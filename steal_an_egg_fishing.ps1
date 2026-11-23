# ============================================================
#  Steal An Egg - Alien Planet fishing macro (PowerShell, no install)
#  Same logic as the AutoHotkey version. Needs only Windows PowerShell,
#  which is already built into Windows 10/11.
#
#  Start it with run_fishing.bat (double-click), keep the window open.
#
#  F1 = start/stop      F4 = save "Hold to Cast" prompt position
#  F5 / F6 = charge hold -/+ 25 ms     F2 = status     F3 = quit
#  (hotkeys work even while Roblox is focused)
# ============================================================

# ---- positions (fraction of Roblox window) ----
$promptX = 0.570; $promptY = 0.219      # overwritten by F4
$stopX1 = 0.66;  $stopY1 = 0.85         # STOP button search box
$stopX2 = 0.82;  $stopY2 = 0.96
$clickX = 0.50;  $clickY = 0.60         # where to spam-click while reeling

# ---- tuning ----
$stopR = 0xCF; $stopG = 0x33; $stopB = 0x48   # red STOP button color
$colTol        = 50
$chargeHoldMs  = 1000      # F5/F6 adjust live
$castAnimMs    = 1200
$biteTimeoutMs = 40000
$reelClickGap  = 45
$reelMaxMs     = 15000
$afterReelMs   = 2500

Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @"
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;
using System.Diagnostics;

public static class W {
    [StructLayout(LayoutKind.Sequential)] public struct POINT { public int X; public int Y; }
    [StructLayout(LayoutKind.Sequential)] public struct RECT { public int L; public int T; public int R; public int B; }

    [DllImport("user32.dll")] static extern bool SetCursorPos(int x, int y);
    [DllImport("user32.dll")] static extern void mouse_event(uint f, int dx, int dy, uint d, UIntPtr e);
    [DllImport("user32.dll")] static extern short GetAsyncKeyState(int k);
    [DllImport("user32.dll")] static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
    [DllImport("user32.dll")] static extern bool GetClientRect(IntPtr h, out RECT r);
    [DllImport("user32.dll")] static extern bool ClientToScreen(IntPtr h, ref POINT p);
    [DllImport("user32.dll")] static extern bool GetCursorPos(out POINT p);
    [DllImport("user32.dll")] static extern bool SetProcessDPIAware();

    public static void Init() { SetProcessDPIAware(); }

    public static bool Key(int vk) { return (GetAsyncKeyState(vk) & 0x8000) != 0; }

    // returns {x, y, w, h} of the Roblox client area, or null if Roblox is not the active window
    public static int[] Roblox() {
        IntPtr h = GetForegroundWindow();
        if (h == IntPtr.Zero) return null;
        uint pid; GetWindowThreadProcessId(h, out pid);
        try {
            if (Process.GetProcessById((int)pid).ProcessName != "RobloxPlayerBeta") return null;
        } catch { return null; }
        RECT r; if (!GetClientRect(h, out r)) return null;
        POINT p = new POINT(); p.X = 0; p.Y = 0; ClientToScreen(h, ref p);
        return new int[] { p.X, p.Y, r.R - r.L, r.B - r.T };
    }

    public static int[] Cursor() { POINT p; GetCursorPos(out p); return new int[] { p.X, p.Y }; }

    public static void MoveTo(int x, int y) {
        SetCursorPos(x, y);
        System.Threading.Thread.Sleep(15);
        mouse_event(0x0001, 1, 0, 0, UIntPtr.Zero);    // tiny jiggle so Roblox registers movement
        mouse_event(0x0001, -1, 0, 0, UIntPtr.Zero);
        System.Threading.Thread.Sleep(15);
    }
    public static void Down() { mouse_event(0x0002, 0, 0, 0, UIntPtr.Zero); }
    public static void Up()   { mouse_event(0x0004, 0, 0, 0, UIntPtr.Zero); }
    public static void Click(){ Down(); System.Threading.Thread.Sleep(8); Up(); }

    // true if any pixel in the screen box is within tol of the color
    public static bool Find(int x1, int y1, int x2, int y2, int cr, int cg, int cb, int tol) {
        int w = x2 - x1, h = y2 - y1;
        if (w <= 0 || h <= 0) return false;
        using (Bitmap bmp = new Bitmap(w, h, PixelFormat.Format32bppArgb)) {
            using (Graphics g = Graphics.FromImage(bmp)) {
                g.CopyFromScreen(x1, y1, 0, 0, new Size(w, h));
            }
            BitmapData d = bmp.LockBits(new Rectangle(0, 0, w, h), ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
            try {
                int stride = d.Stride;
                byte[] buf = new byte[stride * h];
                Marshal.Copy(d.Scan0, buf, 0, buf.Length);
                for (int y = 0; y < h; y++) {
                    int row = y * stride;
                    for (int x = 0; x < w; x++) {
                        int i = row + x * 4;
                        if (Math.Abs(buf[i + 2] - cr) <= tol && Math.Abs(buf[i + 1] - cg) <= tol && Math.Abs(buf[i] - cb) <= tol)
                            return true;
                    }
                }
            } finally { bmp.UnlockBits(d); }
        }
        return false;
    }
}
"@

[W]::Init()

$script:running = $false
$script:quit = $false
$script:casts = 0
$script:lastBite = 0
$script:lastReel = 0
$script:prev = @{}

function Edge($vk) {
    $now = [W]::Key($vk)
    $was = $script:prev[$vk]
    $script:prev[$vk] = $now
    return ($now -and -not $was)
}

function Pump {
    if (Edge 0x70) {   # F1
        $script:running = -not $script:running
        if ($script:running) { Write-Host "Fishing ON" -ForegroundColor Green }
        else { [W]::Up(); Write-Host "Fishing OFF" -ForegroundColor Yellow }
    }
    if (Edge 0x72) { $script:quit = $true; $script:running = $false }   # F3
    if (Edge 0x73) {   # F4
        $g = [W]::Roblox()
        if ($g) {
            $c = [W]::Cursor()
            $script:promptX = ($c[0] - $g[0]) / $g[2]
            $script:promptY = ($c[1] - $g[1]) / $g[3]
            Write-Host ("Prompt position saved: {0:N3}, {1:N3}" -f $script:promptX, $script:promptY)
        } else { Write-Host "Click into Roblox first" -ForegroundColor Yellow }
    }
    if (Edge 0x74) { $script:chargeHoldMs -= 25; Write-Host "Charge hold: $($script:chargeHoldMs) ms" }   # F5
    if (Edge 0x75) { $script:chargeHoldMs += 25; Write-Host "Charge hold: $($script:chargeHoldMs) ms" }   # F6
    if (Edge 0x71) {   # F2
        $g = [W]::Roblox()
        if ($g) {
            Write-Host ("Window {0}x{1} | STOP visible: {2} | charge hold {3} ms | casts {4} | last bite {5} ms | last reel {6} ms" -f `
                $g[2], $g[3], (StopVisible $g), $script:chargeHoldMs, $script:casts, $script:lastBite, $script:lastReel)
        } else { Write-Host "Roblox window not found / not active" -ForegroundColor Yellow }
    }
}

# sleeps while still listening for hotkeys; returns $false if fishing was stopped meanwhile
function Wait-Ms($ms) {
    $sw = [Diagnostics.Stopwatch]::StartNew()
    while ($sw.ElapsedMilliseconds -lt $ms) {
        Pump
        if (-not $script:running) { return $false }
        Start-Sleep -Milliseconds 10
    }
    return $true
}

function StopVisible($g) {
    $x1 = $g[0] + [int][Math]::Round($g[2] * $stopX1); $y1 = $g[1] + [int][Math]::Round($g[3] * $stopY1)
    $x2 = $g[0] + [int][Math]::Round($g[2] * $stopX2); $y2 = $g[1] + [int][Math]::Round($g[3] * $stopY2)
    return [W]::Find($x1, $y1, $x2, $y2, $stopR, $stopG, $stopB, $colTol)
}

function Fish-Cycle {
    $g = [W]::Roblox()
    if (-not $g) { Write-Host "Click into Roblox..." -ForegroundColor Yellow; Start-Sleep -Milliseconds 500; return }

    # 1. hold on the Hold-to-Cast prompt for the charge time, then release
    [W]::MoveTo($g[0] + [int][Math]::Round($g[2] * $promptX), $g[1] + [int][Math]::Round($g[3] * $promptY))
    [W]::Down()
    $ok = Wait-Ms $chargeHoldMs
    [W]::Up()
    if (-not $ok) { return }
    $script:casts++
    Write-Host "Cast #$($script:casts)"

    # 2. wait for the bite = red STOP button (random length)
    if (-not (Wait-Ms $castAnimMs)) { return }
    $sw = [Diagnostics.Stopwatch]::StartNew()
    $bit = $false
    while ($script:running -and $sw.ElapsedMilliseconds -lt $biteTimeoutMs) {
        Pump
        $g = [W]::Roblox()
        if ($g -and (StopVisible $g)) { $bit = $true; break }
        Start-Sleep -Milliseconds 20
    }
    if (-not $script:running) { return }
    if (-not $bit) { Write-Host "No bite, recasting" -ForegroundColor Yellow; [void](Wait-Ms 800); return }
    $script:lastBite = $sw.ElapsedMilliseconds + $castAnimMs

    # 3. spam click until the STOP button is gone (random length)
    [W]::MoveTo($g[0] + [int][Math]::Round($g[2] * $clickX), $g[1] + [int][Math]::Round($g[3] * $clickY))
    $sw2 = [Diagnostics.Stopwatch]::StartNew()
    $gone = 0
    while ($script:running -and $sw2.ElapsedMilliseconds -lt $reelMaxMs) {
        [W]::Click()
        Start-Sleep -Milliseconds $reelClickGap
        Pump
        $g = [W]::Roblox()
        if ($g -and -not (StopVisible $g)) {
            $gone++
            if ($gone -ge 4) { break }
        } else { $gone = 0 }
    }
    $script:lastReel = $sw2.ElapsedMilliseconds
    Write-Host "Reeled in (bite wait $($script:lastBite) ms, reel $($script:lastReel) ms)"

    # 4. reward popup, then loop (a too-early cast just retries)
    [void](Wait-Ms $afterReelMs)
}

Clear-Host
Write-Host "Steal An Egg fishing macro (PowerShell)" -ForegroundColor Cyan
Write-Host "F1 start/stop | F2 status | F3 quit | F4 save prompt position | F5/F6 charge hold -/+"
Write-Host "Hover the 'Hold to Cast' prompt in Roblox and press F4 first. Keep this window open."
Write-Host ""

while (-not $script:quit) {
    Pump
    if ($script:running) { Fish-Cycle } else { Start-Sleep -Milliseconds 20 }
}
[W]::Up()
Write-Host "Bye"
