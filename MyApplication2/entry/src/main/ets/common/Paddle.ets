import { GameConfig, PlayerSide } from './GameConfig';

/**
 * 移动范围接口
 * 定义挡板可移动的矩形区域
 */
export interface MovementBounds {
  /** 左边界 (x最小值) */
  minX: number;
  /** 右边界 (x最大值) */
  maxX: number;
  /** 上边界 (y最小值) */
  minY: number;
  /** 下边界 (y最大值) */
  maxY: number;
}

/**
 * 挡板类
 * 管理挡板的位置、尺寸和移动范围
 */
export class Paddle {
  // ==================== 属性 ====================
  
  /** 挡板所属侧边 */
  private _side: PlayerSide;
  
  /** 挡板中心点X坐标 */
  private _x: number;
  
  /** 挡板中心点Y坐标 */
  private _y: number;
  
  /** 挡板宽度 */
  private _width: number;
  
  /** 挡板高度 */
  private _height: number;
  
  /** 移动范围边界 */
  private _bounds: MovementBounds;
  
  /** 游戏区域宽度 */
  private _gameWidth: number;
  
  /** 游戏区域高度 */
  private _gameHeight: number;

  // ==================== 构造函数 ====================
  
  /**
   * 构造函数
   * @param side 挡板侧边 (Top/Bottom)
   * @param gameWidth 游戏区域宽度
   * @param gameHeight 游戏区域高度
   * @param width 挡板宽度 (默认使用GameConfig配置)
   * @param height 挡板高度 (默认使用GameConfig配置)
   * @param offsetLower 距离侧边的偏移下界 (默认40像素)
   * @param offsetUpper 距离侧边的偏移上界 (默认80像素)
   */
  constructor(
    side: PlayerSide,
    gameWidth: number,
    gameHeight: number,
    width: number = GameConfig.PADDLE_WIDTH,
    height: number = GameConfig.PADDLE_HEIGHT,
    offsetLower: number = 40,
    offsetUpper: number = 80
  ) {
    this._side = side;
    this._gameWidth = gameWidth;
    this._gameHeight = gameHeight;
    this._width = width;
    this._height = height;
    
    // 计算移动范围边界
    this._bounds = this.calculateBounds(offsetLower, offsetUpper);
    
    // 初始化位置到中心
    this._x = gameWidth / 2;
    this._y = this.getInitialY(offsetLower, offsetUpper);
  }

  // ==================== Getter方法 ====================
  
  /** 获取侧边 */
  get side(): PlayerSide {
    return this._side;
  }
  
  /** 获取中心点X坐标 */
  get x(): number {
    return this._x;
  }
  
  /** 获取中心点Y坐标 */
  get y(): number {
    return this._y;
  }
  
  /** 获取宽度 */
  get width(): number {
    return this._width;
  }
  
  /** 获取高度 */
  get height(): number {
    return this._height;
  }
  
  /** 获取移动范围 */
  get bounds(): MovementBounds {
    return this._bounds;
  }
  
  /** 获取左边界坐标 (挡板左边缘) */
  get left(): number {
    return this._x - this._width / 2;
  }
  
  /** 获取右边界坐标 (挡板右边缘) */
  get right(): number {
    return this._x + this._width / 2;
  }
  
  /** 获取上边界坐标 (挡板上边缘) */
  get top(): number {
    return this._y - this._height / 2;
  }
  
  /** 获取下边界坐标 (挡板下边缘) */
  get bottom(): number {
    return this._y + this._height / 2;
  }

  // ==================== Setter方法 ====================
  
  /**
   * 设置X坐标 (自动钳位到边界)
   */
  set x(value: number) {
    this._x = this.clampX(value);
  }
  
  /**
   * 设置Y坐标 (自动钳位到边界)
   */
  set y(value: number) {
    this._y = this.clampY(value);
  }

  // ==================== 核心方法 ====================
  
  /**
   * 移动挡板
   * 根据增量平移并钳位到边界范围内
   * @param dx X方向增量
   * @param dy Y方向增量
   */
  move(dx: number, dy: number): void {
    // 计算新位置
    const newX = this._x + dx;
    const newY = this._y + dy;
    
    // 钳位到边界范围
    this._x = this.clampX(newX);
    this._y = this.clampY(newY);
  }
  
  /**
   * 移动到指定位置
   * 自动钳位到边界范围内
   * @param x 目标X坐标
   * @param y 目标Y坐标
   */
  moveTo(x: number, y: number): void {
    this._x = this.clampX(x);
    this._y = this.clampY(y);
  }
  
  /**
   * 重置到初始位置 (水平居中)
   */
  reset(): void {
    this._x = this._gameWidth / 2;
    // Y坐标保持在当前移动范围的中间
    this._y = (this._bounds.minY + this._bounds.maxY) / 2;
  }

  // ==================== 辅助方法 ====================
  
  /**
   * 计算移动范围边界
   * @param offsetLower 距离侧边的偏移下界
   * @param offsetUpper 距离侧边的偏移上界
   * @returns 移动范围边界
   */
  private calculateBounds(offsetLower: number, offsetUpper: number): MovementBounds {
    // 左右边界：游戏区域边界减去挡板半宽
    const minX = this._width / 2;
    const maxX = this._gameWidth - this._width / 2;
    
    // 上下边界：根据侧边计算
    let minY: number;
    let maxY: number;
    
    if (this._side === PlayerSide.Bottom) {
      // 下挡板：靠近底部
      // y范围：gameHeight - 偏移下界 - paddleHeight/2 至 gameHeight - 偏移上界 - paddleHeight/2
      maxY = this._gameHeight - offsetLower - this._height / 2;
      minY = this._gameHeight - offsetUpper - this._height / 2;
    } else {
      // 上挡板：靠近顶部
      // y范围：偏移上界 + paddleHeight/2 至 偏移下界 + paddleHeight/2
      minY = offsetUpper + this._height / 2;
      maxY = offsetLower + this._height / 2;
    }
    
    return { minX, maxX, minY, maxY };
  }
  
  /**
   * 获取初始Y坐标
   * @param offsetLower 距离侧边的偏移下界
   * @param offsetUpper 距离侧边的偏移上界
   * @returns 初始Y坐标
   */
  private getInitialY(offsetLower: number, offsetUpper: number): number {
    if (this._side === PlayerSide.Bottom) {
      // 下挡板初始位置：距离底部偏移下界
      return this._gameHeight - offsetLower - this._height / 2;
    } else {
      // 上挡板初始位置：距离顶部偏移下界
      return offsetLower + this._height / 2;
    }
  }
  
  /**
   * 钳位X坐标到边界范围
   * @param x 待钳位的X坐标
   * @returns 钳位后的X坐标
   */
  private clampX(x: number): number {
    return Math.max(this._bounds.minX, Math.min(this._bounds.maxX, x));
  }
  
  /**
   * 钳位Y坐标到边界范围
   * @param y 待钳位的Y坐标
   * @returns 钳位后的Y坐标
   */
  private clampY(y: number): number {
    return Math.max(this._bounds.minY, Math.min(this._bounds.maxY, y));
  }
  
  /**
   * 检查点是否在挡板范围内
   * @param px 点的X坐标
   * @param py 点的Y坐标
   * @returns 是否在范围内
   */
  containsPoint(px: number, py: number): boolean {
    return px >= this.left && px <= this.right &&
           py >= this.top && py <= this.bottom;
  }
  
  /**
   * 获取挡板状态快照
   * @returns 挡板状态对象
   */
  getState(): PaddleState {
    return {
      side: this._side,
      x: this._x,
      y: this._y,
      width: this._width,
      height: this._height,
      left: this.left,
      right: this.right,
      top: this.top,
      bottom: this.bottom
    };
  }
}

/**
 * 挡板状态接口
 * 用于保存和传递挡板状态
 */
export interface PaddleState {
  /** 挡板侧边 */
  side: PlayerSide;
  /** 中心点X坐标 */
  x: number;
  /** 中心点Y坐标 */
  y: number;
  /** 宽度 */
  width: number;
  /** 高度 */
  height: number;
  /** 左边缘坐标 */
  left: number;
  /** 右边缘坐标 */
  right: number;
  /** 上边缘坐标 */
  top: number;
  /** 下边缘坐标 */
  bottom: number;
}
