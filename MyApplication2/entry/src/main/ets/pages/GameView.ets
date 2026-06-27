import {
  GameConfig,
  GameMode,
  GameState,
  PlayerSide,
  Direction,
  BallState,
  BulletState,
  PlayerState,
  BlockEvent
} from '../common/GameConfig';
import { GameManager } from '../common/GameManager';
import ResultDialog from './ResultDialog';
import { router, display, window } from '@kit.ArkUI';
import { AbilityConstant } from '@kit.AbilityKit';
import common from '@ohos.app.ability.common';

/**
 * 粒子数据接口
 */
interface ParticleData {
  x: number;
  y: number;
  vx: number;
  vy: number;
  life: number;
  maxLife: number;
  size: number;
  color: string;
}

/**
 * 浮动文字数据接口
 */
interface FloatingTextData {
  x: number;
  y: number;
  text: string;
  color: string;
  life: number;
  maxLife: number;
}

/**
 * 游戏主场景页面
 * 使用GameManager管理游戏逻辑
 */
/**
 * 触摸按下信息接口
 */
interface FingerDownInfo {
  x: number;
  y: number;
  time: number;
}
@Entry
@Component
export default struct GameView {
  // ==================== 状态变量 ====================
  @State private gameMode: GameMode = GameMode.Single;
  @State private showResultDialog: boolean = false;
  @State private isWin: boolean = false;
  @State private winner: PlayerSide = PlayerSide.Bottom;
  @State private ballX: number = 0;
  @State private ballY: number = 0;
  @State private ballActive: boolean = false;
  @State private ballRadius: number = GameConfig.BALL_RADIUS;
  @State private player1Score: number = 0;
  @State private player1Bullets: number = 0;
  @State private player2Score: number = 0;
  @State private player2Bullets: number = 0;
  @State private timeLeft: number = GameConfig.GAME_DURATION;
  @State private gameState: GameState = GameState.Paused;
  @State private bottomPaddleX: number = 0;
  @State private topPaddleX: number = 0;
  @State private bottomBullets: string = '';
  @State private topBullets: string = '';
  @State private bottomPaddleY: number = 0;
  @State private topPaddleY: number = 0;
  
  // 挡板移动检测（用于自动开始游戏）
  private bottomPaddleMoved: boolean = false;
  private topPaddleMoved: boolean = false;
  private initialBottomPaddleX: number = 0;
  private initialTopPaddleX: number = 0;
  
  // ==================== 多指触摸跟踪 ====================
  // 记录每根手指按下时的位置和时间
  private fingerDownMap: Map<number, FingerDownInfo> = new Map();
  private static readonly TAP_MOVE_THRESHOLD: number = 10;   // tap 最大允许移动像素
  private static readonly TAP_TIME_THRESHOLD: number = 300;  // tap 最大允许时间（毫秒）
  
  // 双击检测（计时器互斥方案：第一次点击启动300ms计时器，超时发射；第二次点击取消发射，触发格挡）
  private tapTimer: number = -1;
  private tapCount: number = 0;
  private isWaitingForDoubleTap: boolean = false;
  private static readonly TAP_MAX_DELAY: number = 300; // 单击/双击判定超时（毫秒），禁止低于200ms或高于400ms
  
  // ==================== 格挡可视化状态 ====================
  @State bottomBlockActive: boolean = false;
  @State topBlockActive: boolean = false;
  @State bottomBlockSuccess: boolean = false;
  @State topBlockSuccess: boolean = false;
  @State blockParticles: string = '';
  @State blockFloatingTexts: string = '';
  
  // 格挡成功闪烁定时器
  private bottomBlockSuccessTimer: number = -1;
  private topBlockSuccessTimer: number = -1;
  
  // 粒子与浮动文字数据（私有，用于每帧更新）
  private activeParticles: ParticleData[] = [];
  private activeFloatingTexts: FloatingTextData[] = [];
  
  // GameManager实例
  private gameManager: GameManager = GameManager.getInstance();
  
  // 游戏循环定时器
  private gameTimer: number = -1;
  private lastTime: number = 0;
  
  // 实际屏幕尺寸
  @State private screenWidth: number = GameConfig.SCREEN_WIDTH;
  @State private screenHeight: number = GameConfig.SCREEN_HEIGHT;

  async aboutToAppear() {
    // 获取实际屏幕尺寸
    this.initScreenSize();
    
    // 获取路由参数
    try {
      const params = router.getParams() as Record<string, string>;
      if (params && params['mode'] === 'multi') {
        this.gameMode = GameMode.Multi;
      } else {
        this.gameMode = GameMode.Single;
      }
    } catch (error) {
      // 默认单人模式
      this.gameMode = GameMode.Single;
    }
    
    // 设置实际屏幕尺寸到GameManager
    this.gameManager.setScreenSize(this.screenWidth, this.screenHeight);
    
    // 检查是否有流转数据需要恢复
    try {
      const continuationData = GameManager.getContinuationData();
      if (continuationData) {
        console.info('Restoring game state from continuation data');
        
        // 从流转数据恢复游戏状态
        this.gameManager.deserializeState(continuationData);
        
        // 清除流转数据，避免下次启动时重复恢复
        GameManager.clearContinuationData();
        
        // 更新游戏模式（从流转数据中恢复）
        this.gameMode = this.gameManager.getGameMode();
      } else {
        // 没有流转数据，正常初始化游戏
        this.gameManager.resetGame(this.gameMode);
      }
    } catch (error) {
      console.error('Failed to restore continuation data:', error);
      // 发生错误时正常初始化游戏
      this.gameManager.resetGame(this.gameMode);
    }
    
    this.updateUIState();
    
    // 记录挡板初始位置（用于检测移动）
    this.initialBottomPaddleX = this.bottomPaddleX;
    this.initialTopPaddleX = this.topPaddleX;
    this.bottomPaddleMoved = false;
    this.topPaddleMoved = false;

    // 同步自动流转开关状态到 Ability
    try {
      const ctx = getContext(this) as common.UIAbilityContext;
      const isAuto = GameManager.isAutoContinuation();
      ctx.setMissionContinueState(
        isAuto ? AbilityConstant.ContinueState.ACTIVE : AbilityConstant.ContinueState.INACTIVE,
        (result) => {
          console.info('GameView: setMissionContinueState result: ' + JSON.stringify(result));
        }
      );
      console.info('GameView: autoContinuation=' + isAuto);
    } catch (error) {
      console.error('GameView: failed to setMissionContinueState: ' + JSON.stringify(error));
    }
  }

  aboutToDisappear() {
    this.stopGameLoop();
    this.clearBlockTimers();
    this.resetTapState();
    this.fingerDownMap.clear();
    GameManager.destroyInstance();
  }

  /**
   * 初始化屏幕尺寸
   */
  private initScreenSize(): void {
    try {
      // 使用 display 获取屏幕尺寸
      const displayInfo = display.getDefaultDisplaySync();
      this.screenWidth = this.getUIContext().px2vp(displayInfo.width);
      this.screenHeight = this.getUIContext().px2vp(displayInfo.height);
      console.info(`Screen size: ${this.screenWidth} x ${this.screenHeight}`);
    } catch (error) {
      // 使用默认值
      console.error('Failed to get screen size, using default values');
      this.screenWidth = GameConfig.SCREEN_WIDTH;
      this.screenHeight = GameConfig.SCREEN_HEIGHT;
    }
  }

  /**
   * 更新UI状态
   */
  private updateUIState(): void {
    const gameData = this.gameManager.getGameData();
    const ball = gameData.ball;
    
    this.ballX = ball.x;
    this.ballY = ball.y;
    this.ballActive = ball.active;
    this.ballRadius = ball.radius;
    
    this.player1Score = gameData.playerBottom.score;
    this.player1Bullets = gameData.playerBottom.bulletCount;
    this.bottomPaddleX = gameData.playerBottom.paddle.x;
    this.bottomPaddleY = gameData.playerBottom.paddle.y;
    this.bottomBullets = this.serializeBullets(gameData.playerBottom.bullets);
    this.bottomBlockActive = gameData.playerBottom.blockWindowActive;
    
    if (gameData.playerTop) {
      this.player2Score = gameData.playerTop.score;
      this.player2Bullets = gameData.playerTop.bulletCount;
      this.topPaddleX = gameData.playerTop.paddle.x;
      this.topPaddleY = gameData.playerTop.paddle.y;
      this.topBullets = this.serializeBullets(gameData.playerTop.bullets);
      this.topBlockActive = gameData.playerTop.blockWindowActive;
    }
    
    this.timeLeft = gameData.timeLeft;
    this.gameState = gameData.state;
  }

  /**
   * 序列化子弹数据
   */
  private serializeBullets(bullets: BulletState[]): string {
    const activeBullets: BulletState[] = bullets.filter((b: BulletState) => b.active);
    const result: string[] = activeBullets.map((b: BulletState) => `${b.x.toFixed(0)},${b.y.toFixed(0)},${b.radius}`);
    return result.join('|');
  }

  // ==================== 游戏循环控制 ====================

  /**
   * 启动游戏循环
   */
  private startGameLoop(): void {
    this.lastTime = Date.now();
    this.gameTimer = setInterval(() => {
      const currentTime = Date.now();
      const deltaTime = (currentTime - this.lastTime) / 1000;
      this.lastTime = currentTime;
      
      this.gameManager.updatePhysics(deltaTime);
      this.updateUIState();
      this.updateBlockEffects();
      
      // 检查游戏是否结束
      if (this.gameManager.isGameOver()) {
        this.stopGameLoop();
        this.showGameOver();
      }
    }, GameConfig.ANIMATION_INTERVAL);
  }

  /**
   * 停止游戏循环
   */
  private stopGameLoop(): void {
    if (this.gameTimer !== -1) {
      clearInterval(this.gameTimer);
      this.gameTimer = -1;
    }
  }

  /**
   * 显示游戏结束
   */
  private showGameOver(): void {
    const gameData = this.gameManager.getGameData();
    this.isWin = gameData.isWin;
    this.winner = gameData.winner ?? PlayerSide.Bottom;
    this.showResultDialog = true;
  }

  // ==================== 游戏控制方法 ====================

  /**
   * 开始游戏
   */
  private handleStartGame(): void {
    this.gameManager.resetGame(this.gameMode);
    this.gameManager.startGame();
    this.updateUIState();
    this.startGameLoop();
  }

  /**
   * 暂停/继续游戏
   */
  private handleTogglePause(): void {
    if (this.gameState === GameState.Playing) {
      this.gameManager.pauseGame();
      this.stopGameLoop();
    } else if (this.gameState === GameState.Paused) {
      this.gameManager.resumeGame();
      this.startGameLoop();
    }
    this.updateUIState();
  }

  /**
   * 重新开始游戏
   */
  private handleRestartGame(): void {
    this.showResultDialog = false;
    this.stopGameLoop();
    this.handleStartGame();
  }

  /**
   * 返回主菜单
   */
  private handleBackToMenu(): void {
    this.showResultDialog = false;
    this.stopGameLoop();
    this.gameManager.resetGame(this.gameMode);
    this.updateUIState();
  }

  /**
   * 发射子弹
   */
  private handleShootBullet(side: PlayerSide): void {
    this.gameManager.shootBullet(side);
    this.updateUIState();
  }

  /**
   * 移动挡板
   */
  private handleMovePaddle(side: PlayerSide, direction: Direction): void {
    this.gameManager.movePaddle(side, direction);
    this.updateUIState();
  }

  /**
   * 切换游戏模式
   */
  private handleSwitchMode(): void {
    this.gameMode = this.gameMode === GameMode.Single ? GameMode.Multi : GameMode.Single;
    this.stopGameLoop();
    this.gameManager.resetGame(this.gameMode);
    this.updateUIState();
  }

  /**
   * 获取发射按钮颜色
   */
  private getShootButtonColor(canShoot: boolean): ResourceColor {
    return canShoot ? Color.Green : Color.Gray;
  }

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
        this.fingerDownMap.set(touch.id, {
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
        const down = this.fingerDownMap.get(touch.id);
        if (down) {
          const dist = Math.hypot(touch.x - down.x, touch.y - down.y);
          if (dist > GameView.TAP_MOVE_THRESHOLD) {
            this.fingerDownMap.delete(touch.id);
          }
        }
      }
      return;
    }

    // === Phase 3: 手指抬起 — 单击/双击检测（即时触发，无 setTimeout） ===
    if (event.type === TouchType.Up) {
      for (let i = 0; i < event.touches.length; i++) {
        const touch = event.touches[i];
        const down = this.fingerDownMap.get(touch.id);
        if (!down) {
          continue;
        }

        const elapsed = Date.now() - down.time;
        const moved = Math.hypot(touch.x - down.x, touch.y - down.y);

        // 判定条件：未显著移动 + 在时间阈值内 = 有效点击
        if (moved < GameView.TAP_MOVE_THRESHOLD &&
            elapsed < GameView.TAP_TIME_THRESHOLD) {
          const tapY = down.y;
          this.tapCount++;

          if (this.tapCount === 1) {
            // 第一次点击：启动计时器，等待第二次点击
            this.isWaitingForDoubleTap = true;
            this.tapTimer = setTimeout(() => {
              // 超时未双击 → 视为单击 → 发射子弹
              if (this.isWaitingForDoubleTap) {
                this.fireBullet(tapY);
                this.resetTapState();
              }
            }, GameView.TAP_MAX_DELAY);
          } else if (this.tapCount === 2) {
            // 第二次点击 → 取消待执行的发射任务，触发格挡
            if (this.tapTimer !== -1) {
              clearTimeout(this.tapTimer);
              this.tapTimer = -1;
            }
            this.isWaitingForDoubleTap = false;
            this.tapCount = 0;
            this.handleDoubleTapBlock(tapY);
          } else {
            // 超出2次，重置状态（安全兜底）
            this.resetTapState();
          }
        }

        this.fingerDownMap.delete(touch.id);
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
   * 发射子弹（仅由单击计时器回调调用，双击时通过重置状态禁止调用）
   * @param tapY 单击位置的Y坐标
   */
  private fireBullet(tapY: number): void {
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
   * 重置双击检测状态（清除计时器，防止残余发射任务执行）
   */
  private resetTapState(): void {
    if (this.tapTimer !== -1) {
      clearTimeout(this.tapTimer);
      this.tapTimer = -1;
    }
    this.tapCount = 0;
    this.isWaitingForDoubleTap = false;
  }

  /**
   * 处理双击格挡（触发时先清除待执行的发射计时器，确保双击不发射子弹）
   * @param tapY 双击位置的Y坐标
   */
  private handleDoubleTapBlock(tapY: number): void {
    // 清除任何待执行的发射任务，确保双击只触发格挡，禁止发射子弹
    this.resetTapState();
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
  }  // ==================== 格挡视觉效果更新 ====================

  /**
   * 每帧更新格挡视觉效果
   * 轮询格挡成功事件，更新粒子与浮动文字
   */
  private updateBlockEffects(): void {
    // 1. 检查是否有新的格挡成功事件
    const event = this.gameManager.pollBlockSuccessEvent();
    if (event) {
      this.spawnBlockParticles(event.x, event.y);
      this.spawnFloatingText(event.x, event.y);
      
      // 触发金色闪烁
      if (event.side === PlayerSide.Bottom) {
        this.bottomBlockSuccess = true;
        if (this.bottomBlockSuccessTimer !== -1) {
          clearTimeout(this.bottomBlockSuccessTimer);
        }
        this.bottomBlockSuccessTimer = setTimeout(() => {
          this.bottomBlockSuccess = false;
          this.bottomBlockSuccessTimer = -1;
        }, GameConfig.BLOCK_SUCCESS_FLASH_DURATION);
      } else {
        this.topBlockSuccess = true;
        if (this.topBlockSuccessTimer !== -1) {
          clearTimeout(this.topBlockSuccessTimer);
        }
        this.topBlockSuccessTimer = setTimeout(() => {
          this.topBlockSuccess = false;
          this.topBlockSuccessTimer = -1;
        }, GameConfig.BLOCK_SUCCESS_FLASH_DURATION);
      }
    }
    
    // 2. 更新粒子位置与生命周期
    const deltaTime = 1 / GameConfig.ANIMATION_FPS; // 固定帧间隔
    const particleParts: string[] = [];
    for (let i = this.activeParticles.length - 1; i >= 0; i--) {
      const p = this.activeParticles[i];
      p.life -= deltaTime * 1000;
      if (p.life <= 0) {
        this.activeParticles.splice(i, 1);
        continue;
      }
      p.x += p.vx * deltaTime;
      p.y += p.vy * deltaTime;
      const opacity = Math.max(0, p.life / p.maxLife);
      particleParts.push(`${p.x},${p.y},${p.size},${p.color},${opacity}`);
    }
    this.blockParticles = particleParts.join('|');
    
    // 3. 更新浮动文字
    const textParts: string[] = [];
    for (let i = this.activeFloatingTexts.length - 1; i >= 0; i--) {
      const ft = this.activeFloatingTexts[i];
      ft.life -= deltaTime * 1000;
      if (ft.life <= 0) {
        this.activeFloatingTexts.splice(i, 1);
        continue;
      }
      ft.y -= 30 * deltaTime; // 每秒上移30像素
      const opacity = Math.max(0, ft.life / ft.maxLife);
      textParts.push(`${ft.x},${ft.y},${ft.text},${ft.color},${opacity}`);
    }
    this.blockFloatingTexts = textParts.join('|');
  }

  /**
   * 生成格挡成功粒子效果
   */
  private spawnBlockParticles(x: number, y: number): void {
    for (let i = 0; i < GameConfig.BLOCK_PARTICLE_COUNT; i++) {
      const angle = Math.random() * Math.PI * 2;
      const speed = Math.random() * 100 + 50;
      this.activeParticles.push({
        x: x,
        y: y,
        vx: Math.cos(angle) * speed,
        vy: Math.sin(angle) * speed,
        life: GameConfig.BLOCK_PARTICLE_DURATION,
        maxLife: GameConfig.BLOCK_PARTICLE_DURATION,
        size: Math.random() * 6 + 2,
        color: `hsl(${120 + Math.random() * 30}, 100%, ${50 + Math.random() * 30}%)`
      });
    }
  }

  /**
   * 生成格挡成功浮动文字
   */
  private spawnFloatingText(x: number, y: number): void {
    this.activeFloatingTexts.push({
      x: x - 60,
      y: y - 15,
      text: '🛡️ 格挡成功! +1子弹',
      color: '#00FF88',
      life: GameConfig.BLOCK_FLOATING_TEXT_DURATION,
      maxLife: GameConfig.BLOCK_FLOATING_TEXT_DURATION
    });
  }

  /**
   * 清除格挡相关定时器
   */
  private clearBlockTimers(): void {
    if (this.bottomBlockSuccessTimer !== -1) {
      clearTimeout(this.bottomBlockSuccessTimer);
      this.bottomBlockSuccessTimer = -1;
    }
    if (this.topBlockSuccessTimer !== -1) {
      clearTimeout(this.topBlockSuccessTimer);
      this.topBlockSuccessTimer = -1;
    }
  }

  build() {
    Stack() {
      Column() {
        // 游戏区域
        Stack() {
          // 弹球
          if (this.ballActive) {
            Circle()
              .width(this.ballRadius * 2)
              .height(this.ballRadius * 2)
              .position({
                x: this.ballX - this.ballRadius,
                y: this.ballY - this.ballRadius
              })
              .fill(GameConfig.BALL_COLOR)
          }
          
          // 下方挡板
          Row()
            .width(GameConfig.PADDLE_WIDTH)
            .height(GameConfig.PADDLE_HEIGHT)
            .position({
              x: this.bottomPaddleX,
              y: this.bottomPaddleY
            })
            .backgroundColor(GameConfig.PADDLE_COLOR)
            .borderRadius(5)
          
          // 下方子弹
          if (this.bottomBullets.length > 0) {
            ForEach(this.bottomBullets.split('|'), (bulletStr: string) => {
              BulletItem({ bulletStr: bulletStr, color: GameConfig.BULLET_COLOR })
            }, (bulletStr: string) => bulletStr)
          }
          
          // 上方挡板（双人模式或单人模式的AI）
          if (this.gameMode === GameMode.Multi || this.gameMode === GameMode.Single) {
            Row()
              .width(GameConfig.PADDLE_WIDTH)
              .height(GameConfig.PADDLE_HEIGHT)
              .position({
                x: this.topPaddleX,
                y: this.topPaddleY
              })
              .backgroundColor(this.gameMode === GameMode.Single ? '#FF888888' : GameConfig.PADDLE_COLOR) // 单人模式用灰色
              .borderRadius(5)
              
            // 上方子弹
            if (this.topBullets.length > 0) {
              ForEach(this.topBullets.split('|'), (bulletStr: string) => {
                BulletItem({ bulletStr: bulletStr, color: GameConfig.BULLET_COLOR })
              }, (bulletStr: string) => bulletStr)
            }
          }
          
          // 格挡区域 - 下方玩家
          BlockArea({
            show: this.bottomBlockActive || this.bottomBlockSuccess,
            posX: this.bottomPaddleX,
            posY: this.bottomPaddleY - GameConfig.PADDLE_HEIGHT * GameConfig.BLOCK_AREA_HEIGHT_MULTIPLIER,
            areaWidth: GameConfig.PADDLE_WIDTH,
            areaHeight: GameConfig.PADDLE_HEIGHT * GameConfig.BLOCK_AREA_HEIGHT_MULTIPLIER,
            isSuccess: this.bottomBlockSuccess
          })
          
          // 格挡区域 - 上方玩家
          if (this.gameMode === GameMode.Multi || this.gameMode === GameMode.Single) {
            BlockArea({
              show: this.topBlockActive || this.topBlockSuccess,
              posX: this.topPaddleX,
              posY: this.topPaddleY + GameConfig.PADDLE_HEIGHT,
              areaWidth: GameConfig.PADDLE_WIDTH,
              areaHeight: GameConfig.PADDLE_HEIGHT * GameConfig.BLOCK_AREA_HEIGHT_MULTIPLIER,
              isSuccess: this.topBlockSuccess
            })
          }
          
          // 格挡成功粒子效果
          if (this.blockParticles.length > 0) {
            ForEach(this.blockParticles.split('|'), (particleStr: string) => {
              ParticleItem({ particleStr: particleStr })
            }, (particleStr: string) => particleStr)
          }
          
          // 格挡成功浮动文字
          if (this.blockFloatingTexts.length > 0) {
            ForEach(this.blockFloatingTexts.split('|'), (textStr: string) => {
              FloatingTextItem({ textStr: textStr })
            }, (textStr: string) => textStr)
          }
          
          // 分数与子弹数显示 - 双向阅读计分板
          Row() {
            // 左侧：正常朝向当前玩家
            ScoreDisplay({
              score: this.player1Score,
              bulletCount: this.player1Bullets,
              color: '#007DFF'
            })

            Blank()

            // 右侧：旋转180度朝向对面玩家
            ScoreDisplay({
              score: this.player2Score,
              bulletCount: this.player2Bullets,
              color: '#FF3B30',
              isFlipped: true
            })
          }
          .width('100%')
          .height('100%')
          .alignItems(VerticalAlign.Center)
          .hitTestBehavior(HitTestMode.None)
        }
        .width('100%')
        .layoutWeight(1)
        .backgroundColor(GameConfig.BACKGROUND_COLOR)
        .onTouch((event: TouchEvent) => {
          this.handleTouch(event);
        })
      }
      .width('100%')
      .height('100%')

      // 结果弹窗
      if (this.showResultDialog) {
        ResultDialog({
          isWin: this.isWin,
          winner: this.winner,
          gameMode: this.gameMode,
          onRestart: () => {
            this.handleRestartGame();
          },
          onExit: () => {
            this.handleBackToMenu();
          }
        })
      }

      // 流转按钮 - 仅在自动流转开启时显示
      if (GameManager.isAutoContinuation() && !this.showResultDialog) {
        Button() {
          Text('↗')
            .fontSize(14)
            .fontColor('#FFFFFF')
        }
        .width(36)
        .height(36)
        .backgroundColor('#3366CC')
        .borderRadius(18)
        .shadow({ radius: 4, color: '#44000000', offsetY: 2 })
        .position({
          x: '92%',
          y: '2%'
        })
        .opacity(0.7)
        .onClick(() => {
          // 点击流转按钮 - 系统将自动弹出设备选择面板
          console.info('Continuation button clicked, saving state...');
          // 保存当前游戏状态以便流转
          this.gameManager.serializeState();
          // 流转由系统底层接管（continuable=true 时系统多任务卡片会展示流转入口）
          // 此处按钮作为视觉提示和快捷入口
        })
      }
    }
    .width('100%')
    .height('100%')
  }

  }

/**
 * 子弹项组件
 */
@Component
struct BulletItem {
  @Prop bulletStr: string = '';
  @Prop color: string = GameConfig.BULLET_COLOR;
  
  private getX(): number {
    const parts = this.bulletStr.split(',');
    return parts.length > 0 ? parseFloat(parts[0]) : 0;
  }
  
  private getY(): number {
    const parts = this.bulletStr.split(',');
    return parts.length > 1 ? parseFloat(parts[1]) : 0;
  }
  
  private getRadius(): number {
    const parts = this.bulletStr.split(',');
    return parts.length > 2 ? parseFloat(parts[2]) : GameConfig.BULLET_RADIUS;
  }

  build() {
    Circle()
      .width(this.getRadius() * 2)
      .height(this.getRadius() * 2)
      .position({
        x: this.getX() - this.getRadius(),
        y: this.getY() - this.getRadius()
      })
      .fill(this.color)
  }
}

/**
 * 分数与子弹数显示组件
 * 支持双向阅读：isFlipped=true时整体旋转180度，内部顺序自动反转
 */
@Component
struct ScoreDisplay {
  @Prop score: number = 0;
  @Prop bulletCount: number = 0;
  @Prop color: string = '#007DFF';
  @Prop isFlipped: boolean = false;

  build() {
    Column({ space: 4 }) {
      if (this.isFlipped) {
        // 翻转状态：分数在上，子弹在下（旋转180度后对面玩家看到的是子弹在上，分数在下）
        Text(`${this.score}`)
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.color)
        Text(`${this.getBulletDots()}`)
          .fontSize(18)
          .fontWeight(FontWeight.Normal)
          .fontColor(this.color)
      } else {
        // 正常状态：分数在上，子弹数在下
        Text(`${this.score}`)
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.color)
        Text(`${this.getBulletDots()}`)
          .fontSize(18)
          .fontWeight(FontWeight.Normal)
          .fontColor(this.color)
      }
    }
    .alignItems(HorizontalAlign.Center)
    .rotate({ angle: this.isFlipped ? 180 : 0 })
    .margin({
      left: this.isFlipped ? 0 : 16,
      right: this.isFlipped ? 16 : 0
    })
  }

  /**
   * 获取子弹圆点序列
   */
  private getBulletDots(): string {
    let dots = '';
    for (let i = 0; i < this.bulletCount; i++) {
      dots += '●';
    }
    return dots;
  }
}

/**
 * 格挡区域组件
 * 半透明高亮矩形，显示在挡板前方
 */
@Component
struct BlockArea {
  @Prop show: boolean = false;
  @Prop posX: number = 0;
  @Prop posY: number = 0;
  @Prop areaWidth: number = 60;
  @Prop areaHeight: number = 20;
  @Prop isSuccess: boolean = false;

  build() {
    if (this.show) {
      Row()
        .width(this.areaWidth)
        .height(this.areaHeight)
        .position({
          x: this.posX,
          y: this.posY
        })
        .backgroundColor(this.isSuccess ? GameConfig.BLOCK_AREA_SUCCESS_COLOR : GameConfig.BLOCK_AREA_ACTIVE_COLOR)
        .borderRadius(GameConfig.BLOCK_AREA_BORDER_RADIUS)
        .border({
          width: 2,
          color: this.isSuccess ? GameConfig.BLOCK_AREA_SUCCESS_BORDER_COLOR : GameConfig.BLOCK_AREA_BORDER_COLOR
        })
        .shadow({
          radius: 25,
          color: GameConfig.BLOCK_AREA_GLOW_COLOR
        })
      }
    }
  }

/**
 * 粒子项组件 - 用于格挡成功特效
 */
@Component
struct ParticleItem {
  @Prop particleStr: string = '';

  private getX(): number {
    return parseFloat(this.particleStr.split(',')[0]) || 0;
  }

  private getY(): number {
    return parseFloat(this.particleStr.split(',')[1]) || 0;
  }

  private getSize(): number {
    return parseFloat(this.particleStr.split(',')[2]) || 4;
  }

  private getColor(): string {
    return this.particleStr.split(',')[3] || '#00FF64';
  }

  private getOpacity(): number {
    return parseFloat(this.particleStr.split(',')[4]) || 1;
  }

  build() {
    Circle()
      .width(this.getSize())
      .height(this.getSize())
      .position({
        x: this.getX() - this.getSize() / 2,
        y: this.getY() - this.getSize() / 2
      })
      .fill(this.getColor())
      .opacity(this.getOpacity())
  }
}

/**
 * 浮动文字项组件 - 用于格挡成功提示
 */
@Component
struct FloatingTextItem {
  @Prop textStr: string = '';

  private getX(): number {
    return parseFloat(this.textStr.split(',')[0]) || 0;
  }

  private getY(): number {
    return parseFloat(this.textStr.split(',')[1]) || 0;
  }

  private getText(): string {
    return this.textStr.split(',')[2] || '';
  }

  private getColor(): string {
    return this.textStr.split(',')[3] || '#00FF88';
  }

  private getOpacity(): number {
    return parseFloat(this.textStr.split(',')[4]) || 1;
  }

  build() {
    Text(this.getText())
      .fontSize(14)
      .fontColor(this.getColor())
      .opacity(this.getOpacity())
      .textAlign(TextAlign.Center)
      .position({
        x: this.getX(),
        y: this.getY()
      })
  }
}

