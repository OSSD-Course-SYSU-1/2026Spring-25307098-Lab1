/**
 * 游戏全局配置常量类
 * 存储游戏运行所需的所有配置参数
 */
export class GameConfig {
  // ==================== 屏幕适配 ====================
  /** 屏幕基准宽度 (vp) */
  static readonly SCREEN_WIDTH: number = 360;
  
  /** 屏幕基准高度 (vp) */
  static readonly SCREEN_HEIGHT: number = 640;

  // ==================== 弹球配置 ====================
  /** 弹球基准速率 (像素/秒) */
  static readonly BALL_BASE_SPEED: number = 500;
  
  /** 弹球半径 (像素) */
  static readonly BALL_RADIUS: number = 6;

  // ==================== 子弹配置 ====================
  /** 子弹速度 (像素/秒) */
  static readonly BULLET_SPEED: number = 800;
  
  /** 子弹半径 (像素) */
  static readonly BULLET_RADIUS: number = 3;
  
  /** 子弹上限数量 */
  static readonly BULLET_MAX_COUNT: number = 3;

  // ==================== 挡板配置 ====================
  /** 挡板宽度 (像素) */
  static readonly PADDLE_WIDTH: number = 60;
  
  /** 挡板高度 (像素) */
  static readonly PADDLE_HEIGHT: number = 10;
  
  /** 挡板移动速度 (像素/秒) */
  static readonly PADDLE_SPEED: number = 400;

  // ==================== 游戏机制 ====================
  /** 偏移调制幅度 (像素/秒) */
  static readonly OFFSET_MODULATION: number = 250;
  
  /** AI发射子弹间隔 (毫秒) */
  static readonly AI_SHOOT_INTERVAL: number = 2000;
  
  /** 格挡冷却时间 (毫秒) */
  static readonly BLOCK_COOLDOWN: number = 1000;
  
  /** 格挡有效窗口持续时间 (毫秒) */
  static readonly BLOCK_WINDOW_DURATION: number = 200;
  
  /** 弹球无敌时间 (毫秒) */
  static readonly BALL_INVINCIBLE_DURATION: number = 200;
  
  /** 触球充能次数 */
  static readonly CHARGE_COUNT: number = 5;
  
  /** 胜利分数 */
  static readonly WIN_SCORE: number = 11;

  // ==================== 格挡可视化配置 ====================
  /** 格挡区域高度倍数（相对于挡板高度） */
  static readonly BLOCK_AREA_HEIGHT_MULTIPLIER: number = 2;
  /** 格挡区域圆角 */
  static readonly BLOCK_AREA_BORDER_RADIUS: number = 6;
  /** 格挡区域激活填充色 */
  static readonly BLOCK_AREA_ACTIVE_COLOR: string = 'rgba(0, 255, 100, 0.25)';
  /** 格挡区域激活边框色 */
  static readonly BLOCK_AREA_BORDER_COLOR: string = 'rgba(0, 255, 100, 0.7)';
  /** 格挡区域激活发光色 */
  static readonly BLOCK_AREA_GLOW_COLOR: string = 'rgba(0, 255, 100, 0.6)';
  /** 格挡区域成功填充色（金色） */
  static readonly BLOCK_AREA_SUCCESS_COLOR: string = 'rgba(255, 215, 0, 0.6)';
  /** 格挡区域成功边框色（金色） */
  static readonly BLOCK_AREA_SUCCESS_BORDER_COLOR: string = 'rgba(255, 215, 0, 0.8)';
  /** 格挡成功粒子数量 */
  static readonly BLOCK_PARTICLE_COUNT: number = 20;
  /** 格挡成功粒子持续时间（毫秒） */
  static readonly BLOCK_PARTICLE_DURATION: number = 500;
  /** 浮动文字持续时间（毫秒） */
  static readonly BLOCK_FLOATING_TEXT_DURATION: number = 800;
  /** 格挡成功金色闪烁持续时间（毫秒） */
  static readonly BLOCK_SUCCESS_FLASH_DURATION: number = 300;

  // ==================== 游戏状态 ====================
  /** 游戏时长 (秒) */
  static readonly GAME_DURATION: number = 120;
  
  /** 初始生命数 */
  static readonly INITIAL_LIVES: number = 3;

  // ==================== 颜色配置 ====================
  /** 弹球颜色 */
  static readonly BALL_COLOR: string = '#FF4488FF';
  
  /** 子弹颜色 */
  static readonly BULLET_COLOR: string = '#FFFF4444';
  
  /** 挡板颜色 */
  static readonly PADDLE_COLOR: string = '#FF44FF44';
  
  /** 背景颜色 */
  static readonly BACKGROUND_COLOR: string = '#FF1A1A2E';
  
  /** 边框颜色 */
  static readonly BORDER_COLOR: string = '#FF16213E';

  // ==================== 动画配置 ====================
  /** 动画帧率 */
  static readonly ANIMATION_FPS: number = 60;
  
  /** 动画间隔 (毫秒) */
  static readonly ANIMATION_INTERVAL: number = 1000 / GameConfig.ANIMATION_FPS;
}

/**
 * 游戏模式枚举
 */
export enum GameMode {
  /** 单人模式 - 玩家控制底部挡板 */
  Single = 'single',
  /** 双人模式 - 玩家分别控制上下挡板 */
  Multi = 'multi'
}

/**
 * 游戏状态枚举
 */
export enum GameState {
  /** 游戏进行中 */
  Playing = 'playing',
  /** 游戏暂停 */
  Paused = 'paused',
  /** 游戏结束 */
  GameOver = 'gameOver'
}

/**
 * 玩家方位枚举
 */
export enum PlayerSide {
  /** 上方玩家 */
  Top = 'top',
  /** 下方玩家 */
  Bottom = 'bottom'
}

/**
 * 方向枚举
 */
export enum Direction {
  /** 向上 */
  UP = 'up',
  /** 向下 */
  DOWN = 'down',
  /** 向左 */
  LEFT = 'left',
  /** 向右 */
  RIGHT = 'right',
  /** 无方向 */
  NONE = 'none'
}

/**
 * 弹球状态接口
 */
export interface BallState {
  /** X坐标 */
  x: number;
  /** Y坐标 */
  y: number;
  /** X方向速度 */
  vx: number;
  /** Y方向速度 */
  vy: number;
  /** 半径 */
  radius: number;
  /** 是否激活 */
  active: boolean;
  /** 是否无敌（防止连续扣分） */
  invincible: boolean;
  /** 无敌开始时间（毫秒） */
  invincibleStartTime: number;
}

/**
 * 子弹状态接口
 */
export interface BulletState {
  /** X坐标 */
  x: number;
  /** Y坐标 */
  y: number;
  /** X方向速度 */
  vx: number;
  /** Y方向速度 */
  vy: number;
  /** 半径 */
  radius: number;
  /** 是否激活 */
  active: boolean;
  /** 所属玩家方位 */
  owner: PlayerSide;
}

/**
 * 挡板状态接口
 */
export interface PaddleState {
  /** X坐标 */
  x: number;
  /** Y坐标 */
  y: number;
  /** 宽度 */
  width: number;
  /** 高度 */
  height: number;
  /** 所属玩家方位 */
  side: PlayerSide;
  /** 上一帧X坐标（用于计算速度） */
  prevX: number;
  /** 上一帧Y坐标（用于计算速度） */
  prevY: number;
  /** X方向速度（像素/秒） */
  vx: number;
  /** Y方向速度（像素/秒） */
  vy: number;
}

/**
 * 玩家状态接口
 */
export interface PlayerState {
  /** 玩家方位 */
  side: PlayerSide;
  /** 分数 */
  score: number;
  /** 充能计数 */
  chargeCount: number;
  /** 子弹剩余数 */
  bulletCount: number;
  /** 挡板状态 */
  paddle: PaddleState;
  /** 子弹数组 */
  bullets: BulletState[];
  /** 上次格挡尝试时间（毫秒） */
  lastBlockTime: number;
  /** 格挡窗口是否激活 */
  blockWindowActive: boolean;
  /** 格挡窗口开始时间（毫秒） */
  blockWindowStartTime: number;
  /** 触球计数（用于充能） */
  touchCount: number;
}

/**
 * 格挡成功事件接口（用于视觉反馈）
 */
export interface BlockEvent {
  /** 防守方玩家方位 */
  side: PlayerSide;
  /** 子弹命中X坐标 */
  x: number;
  /** 子弹命中Y坐标 */
  y: number;
  /** 事件时间戳 */
  timestamp: number;
}

/**
 * 游戏数据接口
 */
export interface GameData {
  /** 游戏模式 */
  mode: GameMode;
  /** 游戏状态 */
  state: GameState;
  /** 弹球状态 */
  ball: BallState;
  /** 下方玩家状态 */
  playerBottom: PlayerState;
  /** 上方玩家状态（双人模式） */
  playerTop?: PlayerState;
  /** 剩余时间（秒） */
  timeLeft: number;
  /** 是否胜利 */
  isWin: boolean;
  /** 胜利玩家方位 */
  winner?: PlayerSide;
}
