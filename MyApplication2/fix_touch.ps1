$file = 'C:\Users\ming\DevEcoStudioProjects\MyApplication2\entry\src\main\ets\pages\GameView.ets'
$content = Get-Content $file -Raw

$startMarker = "  /**`r`n   * 处理触摸事件`r`n   * 触摸移动时移动挡板`r`n   */"

$idx = $content.IndexOf($startMarker)
if ($idx -eq -1) { Write-Host "Could not find start marker"; exit 1 }

$content2 = $content.Substring($idx)
$endMarker = "  // ==================== 格挡视觉效果更新 ===================="
$endIdx = $content2.IndexOf($endMarker)
if ($endIdx -eq -1) { Write-Host "Could not find end marker"; exit 1 }

# Find the start of clearClickTimer within this range
$cctSub = $content2.Substring(0, $endIdx)
$cctIdx = $cctSub.IndexOf("  private clearClickTimer(): void {")
if ($cctIdx -ge 0) {
  # Extend to include clearClickTimer method (find next method start or end marker)
  $afterCct = $cctSub.Substring($cctIdx)
  $nextMethod = $afterCct.IndexOf("  `r`n  /**")
  if ($nextMethod -ge 0) {
    $endIdx = $cctIdx + $nextMethod
  }
}

$oldBlock = $content2.Substring(0, $endIdx)

$newBlock = @"
  /**
   * 统一触摸事件处理
   * - 多指支持：每根手指独立跟踪，互不干扰
   * - 挡板拖拽：在 TouchMove 中即时响应（无延迟）
   * - 单击发射：手指抬起时即时判定、即时发射（无 setTimeout 延迟）
   * - 双击格挡：跟随后续抬起手指快速追加格挡
   */
  private handleTouch(event: TouchEvent): void {
    if (!event.touches || event.touches.length === 0) {
      return;
    }

    // === Phase 1: 手指按下 — 记录每根手指的位置和时间 ===
    if (event.type === TouchType.Down) {
      for (let i = 0; i < event.touches.length; i++) {
        const touch = event.touches[i];
        this.fingerDownMap.set(touch.fingerId, {
          x: touch.x,
          y: touch.y,
          time: Date.now()
        });
      }
      return;
    }

    // === Phase 2: 手指滑动 — 挡板拖拽（即时响应，无延迟） ===
    if (event.type === TouchType.Move) {
      for (let i = 0; i < event.touches.length; i++) {
        const touch = event.touches[i];
        this.handlePaddleMove(touch.x, touch.y);

        // 如果手指移动量超过阈值，撤消其 tap 资格
        const down = this.fingerDownMap.get(touch.fingerId);
        if (down) {
          const dist = Math.hypot(touch.x - down.x, touch.y - down.y);
          if (dist > GameView.TAP_MOVE_THRESHOLD) {
            this.fingerDownMap.delete(touch.fingerId);
          }
        }
      }
      return;
    }

    // === Phase 3: 手指抬起 — 单击/双击检测（即时触发，无 setTimeout） ===
    if (event.type === TouchType.Up) {
      for (let i = 0; i < event.touches.length; i++) {
        const touch = event.touches[i];
        const down = this.fingerDownMap.get(touch.fingerId);
        if (!down) {
          continue;
        }

        const elapsed = Date.now() - down.time;
        const moved = Math.hypot(touch.x - down.x, touch.y - down.y);

        // 判定条件：未显著移动 + 在时间阈值内 = 有效点击
        if (moved < GameView.TAP_MOVE_THRESHOLD &&
            elapsed < GameView.TAP_TIME_THRESHOLD) {
          const now = Date.now();
          const tapY = down.y;

          if (now - this.lastTapTime < GameView.DOUBLE_TAP_THRESHOLD) {
            // 双击 → 格挡（即时触发，不取消第一次的子弹）
            this.handleDoubleTapBlock(tapY);
            this.lastTapTime = 0;
          } else {
            // 单击 → 发射子弹（即时触发，零延迟）
            this.lastTapTime = now;
            this.lastTapY = tapY;
            this.handleTapShoot(tapY);
          }
        }

        this.fingerDownMap.delete(touch.fingerId);
      }
      return;
    }
  }

  /**
   * 处理挡板拖拽（独立方法，与点击检测互不阻塞）
   */
  private handlePaddleMove(x: number, y: number): void {
    if (this.gameMode === GameMode.Single) {
      this.gameManager.movePaddleTo(PlayerSide.Bottom, x, y);
      this.updateUIState();

      if (!this.bottomPaddleMoved &&
          Math.abs(this.bottomPaddleX - this.initialBottomPaddleX) > 5) {
        this.bottomPaddleMoved = true;
        if (this.gameState === GameState.Paused && !this.ballActive) {
          this.handleStartGame();
        }
      }
    } else {
      const midY = this.screenHeight / 2;

      if (y < midY) {
        this.gameManager.movePaddleTo(PlayerSide.Top, x, y);
        this.updateUIState();

        if (!this.topPaddleMoved &&
            Math.abs(this.topPaddleX - this.initialTopPaddleX) > 5) {
          this.topPaddleMoved = true;
          if (this.bottomPaddleMoved &&
              this.gameState === GameState.Paused && !this.ballActive) {
            this.handleStartGame();
          }
        }
      } else {
        this.gameManager.movePaddleTo(PlayerSide.Bottom, x, y);
        this.updateUIState();

        if (!this.bottomPaddleMoved &&
            Math.abs(this.bottomPaddleX - this.initialBottomPaddleX) > 5) {
          this.bottomPaddleMoved = true;
          if (this.topPaddleMoved &&
              this.gameState === GameState.Paused && !this.ballActive) {
            this.handleStartGame();
          }
        }
      }
    }
  }

  /**
   * 处理单击发射子弹（零延迟即时触发）
   * @param tapY 单击位置的Y坐标
   */
  private handleTapShoot(tapY: number): void {
    if (this.gameMode === GameMode.Single) {
      this.gameManager.shootBullet(PlayerSide.Bottom);
    } else {
      const midY = this.screenHeight / 2;
      if (tapY < midY) {
        this.gameManager.shootBullet(PlayerSide.Top);
      } else {
        this.gameManager.shootBullet(PlayerSide.Bottom);
      }
    }
    this.updateUIState();
  }

  /**
   * 处理双击格挡（即时触发，不取消之前发射的子弹）
   * @param tapY 双击位置的Y坐标
   */
  private handleDoubleTapBlock(tapY: number): void {
    if (this.gameMode === GameMode.Single) {
      this.gameManager.attemptBlock(PlayerSide.Bottom);
    } else {
      const midY = this.screenHeight / 2;
      if (tapY < midY) {
        this.gameManager.attemptBlock(PlayerSide.Top);
      } else {
        this.gameManager.attemptBlock(PlayerSide.Bottom);
      }
    }
    this.updateUIState();
  }
"@

$newContent = $content.Substring(0, $idx) + $newBlock + $content2.Substring($endIdx)
Set-Content $file -Value $newContent -NoNewline
Write-Host "Replaced touch handling code successfully"
