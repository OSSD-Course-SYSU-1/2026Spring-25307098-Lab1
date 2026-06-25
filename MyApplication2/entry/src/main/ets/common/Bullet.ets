import { GameConfig, PlayerSide } from './GameConfig';

/**
 * 子弹类
 * 管理子弹的位置、速度和生命周期
 */
export class Bullet {
  // ==================== 属性 ====================
  
  /** 子弹中心点X坐标 */
  private _x: number;
  
  /** 子弹中心点Y坐标 */
  private _y: number;
  
  /** 子弹半径 */
  private _radius: number;
  
  /** X方向速度 (像素/秒) */
  private _vx: number;
  
  /** Y方向速度 (像素/秒) */
  private _vy: number;
  
  /** 所属玩家侧边 */
  private _side: PlayerSide;
  
  /** 是否激活 (未超出边界) */
  private _active: boolean;
  
  /** 游戏区域宽度 */
  private _gameWidth: number;
  
  /** 游戏区域高度 */
  private _gameHeight: number;

  // ==================== 构造函数 ====================
  
  /**
   * 构造函数
   * 从挡板中心位置出发，方向垂直于挡板向外
   * @param paddleX 挡板中心X坐标
   * @param paddleY 挡板中心Y坐标
   * @param side 所属玩家侧边
   * @param gameWidth 游戏区域宽度
   * @param gameHeight 游戏区域高度
   * @param radius 子弹半径 (默认使用GameConfig配置)
   * @param speed 子弹速度 (默认使用GameConfig配置)
   */
  constructor(
    paddleX: number,
    paddleY: number,
    side: PlayerSide,
    gameWidth: number,
    gameHeight: number,
    radius: number = GameConfig.BULLET_RADIUS,
    speed: number = GameConfig.BULLET_SPEED
  ) {
    this._radius = radius;
    this._side = side;
    this._gameWidth = gameWidth;
    this._gameHeight = gameHeight;
    this._active = true;
    
    // 设置初始位置和速度
    if (side === PlayerSide.Bottom) {
      // 下挡板：向上发射
      this._x = paddleX;
      this._y = paddleY;
      this._vx = 0;
      this._vy = -speed; // 向上为负
    } else {
      // 上挡板：向下发射
      this._x = paddleX;
      this._y = paddleY;
      this._vx = 0;
      this._vy = speed; // 向下为正
    }
  }

  // ==================== Getter方法 ====================
  
  /** 获取中心点X坐标 */
  get x(): number {
    return this._x;
  }
  
  /** 获取中心点Y坐标 */
  get y(): number {
    return this._y;
  }
  
  /** 获取半径 */
  get radius(): number {
    return this._radius;
  }
  
  /** 获取X方向速度 */
  get vx(): number {
    return this._vx;
  }
  
  /** 获取Y方向速度 */
  get vy(): number {
    return this._vy;
  }
  
  /** 获取所属玩家侧边 */
  get side(): PlayerSide {
    return this._side;
  }
  
  /** 获取是否激活 */
  get active(): boolean {
    return this._active;
  }
  
  /** 获取当前速度大小 */
  get speed(): number {
    return Math.sqrt(this._vx * this._vx + this._vy * this._vy);
  }
  
  /** 获取左边界坐标 (子弹左边缘) */
  get left(): number {
    return this._x - this._radius;
  }
  
  /** 获取右边界坐标 (子弹右边缘) */
  get right(): number {
    return this._x + this._radius;
  }
  
  /** 获取上边界坐标 (子弹上边缘) */
  get top(): number {
    return this._y - this._radius;
  }
  
  /** 获取下边界坐标 (子弹下边缘) */
  get bottom(): number {
    return this._y + this._radius;
  }

  // ==================== Setter方法 ====================
  
  /**
   * 设置是否激活
   */
  set active(value: boolean) {
    this._active = value;
  }

  // ==================== 核心方法 ====================
  
  /**
   * 更新子弹位置
   * 根据速度和时间增量计算新位置
   * @param dt 时间增量 (秒)
   */
  update(dt: number): void {
    if (!this._active) {
      return;
    }
    
    // 根据速度和时间增量更新位置
    this._x += this._vx * dt;
    this._y += this._vy * dt;
    
    // 检查是否超出边界
    this.checkBounds();
  }
  
  /**
   * 检查是否超出游戏区域
   * 超出则标记为销毁 (active = false)
   * @returns 是否超出边界
   */
  isOutOfBounds(): boolean {
    // 检查是否超出游戏区域边界
    const outOfBounds = this.left > this._gameWidth ||
                        this.right < 0 ||
                        this.top > this._gameHeight ||
                        this.bottom < 0;
    
    if (outOfBounds) {
      this._active = false;
    }
    
    return outOfBounds;
  }
  
  /**
   * 检查边界并更新激活状态
   */
  private checkBounds(): void {
    this.isOutOfBounds();
  }
  
  /**
   * 销毁子弹
   * 标记为不激活
   */
  destroy(): void {
    this._active = false;
  }

  // ==================== 辅助方法 ====================
  
  /**
   * 检查点是否在子弹范围内
   * @param px 点的X坐标
   * @param py 点的Y坐标
   * @returns 是否在范围内
   */
  containsPoint(px: number, py: number): boolean {
    const dx = px - this._x;
    const dy = py - this._y;
    const distance = Math.sqrt(dx * dx + dy * dy);
    return distance <= this._radius;
  }
  
  /**
   * 计算到点的距离
   * @param px 点的X坐标
   * @param py 点的Y坐标
   * @returns 距离
   */
  distanceTo(px: number, py: number): number {
    const dx = px - this._x;
    const dy = py - this._y;
    return Math.sqrt(dx * dx + dy * dy);
  }
  
  /**
   * 获取子弹状态快照
   * @returns 子弹状态对象
   */
  getState(): BulletState {
    return {
      x: this._x,
      y: this._y,
      vx: this._vx,
      vy: this._vy,
      radius: this._radius,
      side: this._side,
      active: this._active
    };
  }
  
  /**
   * 从状态恢复子弹
   * @param state 子弹状态
   */
  restoreState(state: BulletState): void {
    this._x = state.x;
    this._y = state.y;
    this._vx = state.vx;
    this._vy = state.vy;
    this._radius = state.radius;
    this._side = state.side;
    this._active = state.active;
  }
}

/**
 * 子弹状态接口
 * 用于保存和传递子弹状态
 */
export interface BulletState {
  /** 中心点X坐标 */
  x: number;
  /** 中心点Y坐标 */
  y: number;
  /** X方向速度 */
  vx: number;
  /** Y方向速度 */
  vy: number;
  /** 半径 */
  radius: number;
  /** 所属玩家侧边 */
  side: PlayerSide;
  /** 是否激活 */
  active: boolean;
}
