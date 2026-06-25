import { GameConfig } from './GameConfig';

/**
 * 弹球类
 * 管理弹球的位置、速度和运动逻辑
 */
export class Ball {
  // ==================== 属性 ====================
  
  /** 弹球中心点X坐标 */
  private _x: number;
  
  /** 弹球中心点Y坐标 */
  private _y: number;
  
  /** 弹球半径 */
  private _radius: number;
  
  /** X方向速度 (像素/秒) */
  private _vx: number;
  
  /** Y方向速度 (像素/秒) */
  private _vy: number;
  
  /** 是否激活 */
  private _active: boolean;
  
  /** 基准速度大小 (像素/秒) */
  private _baseSpeed: number;

  // ==================== 构造函数 ====================
  
  /**
   * 构造函数
   * @param centerX 初始中心点X坐标
   * @param centerY 初始中心点Y坐标
   * @param radius 弹球半径 (默认使用GameConfig配置)
   * @param baseSpeed 基准速度 (默认使用GameConfig配置)
   */
  constructor(
    centerX: number,
    centerY: number,
    radius: number = GameConfig.BALL_RADIUS,
    baseSpeed: number = GameConfig.BALL_BASE_SPEED
  ) {
    this._x = centerX;
    this._y = centerY;
    this._radius = radius;
    this._baseSpeed = baseSpeed;
    this._vx = 0;
    this._vy = 0;
    this._active = true;
    
    // 初始化随机方向
    this.reset(centerX, centerY);
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
  
  /** 获取是否激活 */
  get active(): boolean {
    return this._active;
  }
  
  /** 获取基准速度 */
  get baseSpeed(): number {
    return this._baseSpeed;
  }
  
  /** 获取当前速度大小 */
  get speed(): number {
    return Math.sqrt(this._vx * this._vx + this._vy * this._vy);
  }
  
  /** 获取运动方向角度 (弧度) */
  get angle(): number {
    return Math.atan2(this._vy, this._vx);
  }
  
  /** 获取运动方向角度 (度) */
  get angleDegrees(): number {
    return this.toDegrees(this.angle);
  }
  
  /** 获取左边界坐标 (弹球左边缘) */
  get left(): number {
    return this._x - this._radius;
  }
  
  /** 获取右边界坐标 (弹球右边缘) */
  get right(): number {
    return this._x + this._radius;
  }
  
  /** 获取上边界坐标 (弹球上边缘) */
  get top(): number {
    return this._y - this._radius;
  }
  
  /** 获取下边界坐标 (弹球下边缘) */
  get bottom(): number {
    return this._y + this._radius;
  }

  // ==================== Setter方法 ====================
  
  /**
   * 设置X坐标
   */
  set x(value: number) {
    this._x = value;
  }
  
  /**
   * 设置Y坐标
   */
  set y(value: number) {
    this._y = value;
  }
  
  /**
   * 设置X方向速度
   */
  set vx(value: number) {
    this._vx = value;
  }
  
  /**
   * 设置Y方向速度
   */
  set vy(value: number) {
    this._vy = value;
  }
  
  /**
   * 设置是否激活
   */
  set active(value: boolean) {
    this._active = value;
  }

  // ==================== 核心方法 ====================
  
  /**
   * 更新弹球位置
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
  }
  
  /**
   * 重置弹球到指定位置
   * 生成随机方向速度，排除几乎垂直朝向挡板的方向
   * @param centerX 中心点X坐标
   * @param centerY 中心点Y坐标
   */
  reset(centerX: number, centerY: number): void {
    // 重置位置
    this._x = centerX;
    this._y = centerY;
    
    // 生成随机方向速度
    this.setRandomVelocity();
    
    // 激活弹球
    this._active = true;
  }
  
  /**
   * 设置随机方向速度
   * 速度大小恒为基准速率
   * 排除几乎垂直朝向挡板的方向 (±15°或180±15°)
   */
  private setRandomVelocity(): void {
    // 生成有效的随机角度
    const angle = this.generateValidAngle();
    
    // 根据角度计算速度分量
    this._vx = this._baseSpeed * Math.cos(angle);
    this._vy = this._baseSpeed * Math.sin(angle);
  }
  
  /**
   * 生成有效的随机角度
   * 排除±15°和180±15°的范围
   * @returns 有效角度 (弧度)
   */
  private generateValidAngle(): number {
    // 排除的角度范围 (度)
    const excludeRange = 15; // ±15°
    
    // 有效的角度区间 (度):
    // [15, 165] 和 [195, 345]
    // 每个区间宽度: 150度
    const validRangeWidth = 180 - 2 * excludeRange; // 150度
    
    // 随机选择一个有效区间
    const randomValue = Math.random() * 2 * validRangeWidth; // 0 ~ 300
    
    let angleDegrees: number;
    if (randomValue < validRangeWidth) {
      // 第一个有效区间: [15, 165]
      angleDegrees = excludeRange + randomValue;
    } else {
      // 第二个有效区间: [195, 345]
      angleDegrees = 180 + excludeRange + (randomValue - validRangeWidth);
    }
    
    // 转换为弧度
    return this.toRadians(angleDegrees);
  }
  
  /**
   * 设置指定方向的速度
   * @param angle 方向角度 (弧度)
   */
  setVelocityByAngle(angle: number): void {
    this._vx = this._baseSpeed * Math.cos(angle);
    this._vy = this._baseSpeed * Math.sin(angle);
  }
  
  /**
   * 设置指定方向的速度 (角度制)
   * @param angleDegrees 方向角度 (度)
   */
  setVelocityByDegrees(angleDegrees: number): void {
    const angle = this.toRadians(angleDegrees);
    this.setVelocityByAngle(angle);
  }
  
  /**
   * 反转X方向速度
   */
  reverseX(): void {
    this._vx = -this._vx;
  }
  
  /**
   * 反转Y方向速度
   */
  reverseY(): void {
    this._vy = -this._vy;
  }
  
  /**
   * 反转指定方向的速度
   * @param direction 方向 ('x' 或 'y')
   */
  reverse(direction: 'x' | 'y'): void {
    if (direction === 'x') {
      this.reverseX();
    } else {
      this.reverseY();
    }
  }

  // ==================== 辅助方法 ====================
  
  /**
   * 角度转弧度
   * @param degrees 角度
   * @returns 弧度
   */
  private toRadians(degrees: number): number {
    return degrees * Math.PI / 180;
  }
  
  /**
   * 弧度转角度
   * @param radians 弧度
   * @returns 角度
   */
  private toDegrees(radians: number): number {
    return radians * 180 / Math.PI;
  }
  
  /**
   * 检查点是否在弹球范围内
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
   * 获取弹球状态快照
   * @returns 弹球状态对象
   */
  getState(): BallState {
    return {
      x: this._x,
      y: this._y,
      vx: this._vx,
      vy: this._vy,
      radius: this._radius,
      active: this._active
    };
  }
  
  /**
   * 从状态恢复弹球
   * @param state 弹球状态
   */
  restoreState(state: BallState): void {
    this._x = state.x;
    this._y = state.y;
    this._vx = state.vx;
    this._vy = state.vy;
    this._radius = state.radius;
    this._active = state.active;
  }
}

/**
 * 弹球状态接口
 * 用于保存和传递弹球状态
 */
export interface BallState {
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
  /** 是否激活 */
  active: boolean;
}
