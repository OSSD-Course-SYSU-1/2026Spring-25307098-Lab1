/*
 * Copyright (c) 2026 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import { hilog } from '@kit.PerformanceAnalysisKit';
import { WindowUtil } from '../common/WindowUtil';
import { VideoDataModel } from '../common/VideoDataModel';
import { formatVideoTime } from '../common/TimeUtils';
import { SetVolume } from '../view/SetVolume';
import { VideoData } from '../common/VideoData';
import CommonConstants from '../constants/CommonConstants';

const DOMAIN = 0x0000; // Tag domain.

@Component
export struct VideoPlayer {
  // [Start isForeGround]
  @Watch('foregroundStatus') @StorageLink('isForeGround') isForeGround: boolean = false;
  // [End isForeGround]
  // [Start activeIndexChange]
  @Prop @Watch('activeIndexChange') activeIndex: number = 0; // Index of the currently playing video
  // [End activeIndexChange]
  @Prop isFullLandscapeScreen: boolean = false; // FullLandscapeScreen state
  @Prop videoIndex: number = 0; // Video index
  @Prop screenWidth: number = 0; // Screen width
  @Prop videoList: Array<VideoDataModel> = []; // Video resource list from parent
  @State swiperController: SwiperController | undefined = undefined;
  @State currentTime: number = 0; // Current play time point
  @State durationTime: number = 0; // Video total time
  @State isStart: boolean = true; // Video state
  @State volume: number = 5; // Video volume
  @State volumeVisible: boolean = false; // AVVolumePanel visibility state
  @State windowHeight: number = 300; // Window height
  @State curRate: PlaybackSpeed = PlaybackSpeed.Speed_Forward_1_00_X; // Video play speed
  @State isAccelerate: boolean = false; // SpeedDialog visibility state
  @State leftRateOpacity: number = 0; // SpeedDialog left opacity
  @State rightRateOpacity: number = 1; // SpeedDialog right opacity
  @State isProgressBarVisible: boolean = false; // 进度条可见性状态
  @State isProgressBarAutoHide: boolean = false; // 是否自动隐藏进度条
  @State isRightIconsVisible: boolean = false; // 右边图标可见性状态
  @State playbackSpeed: number = 1.0; // 当前播放倍数（0.5-5.0）
  @State isSpeedSelectorVisible: boolean = false; // 倍数选择器可见性状态
  private windowUtil: WindowUtil = WindowUtil.getInstance(); // Window-related utility class
  private controller: VideoController = new VideoController();
  private lastClickTime: number = 0; // 上次点击时间（用于双击检测）
  private progressBarHideTimer: number = -1; // 进度条自动隐藏定时器
  private speedSelectorHideTimer: number = -1; // 倍数选择器自动隐藏定时器

  aboutToAppear(): void {
    this.swiperController = AppStorage.get('swiperController');
  }

  // [Start activeIndexChange_func]
  // Monitor the change of activeIndex when the onchange event occurs.
  activeIndexChange() {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'activeIndexChange.' + this.activeIndex);
    this.currentTime = 0; // Reset currentTime
    this.controller.reset(); // Reset VideoController
    this.controller.start(); // Start playing
  }

  // [End activeIndexChange_func]

  // [Start foregroundStatus_func]
  // Perception of foreground and background.
  foregroundStatus() {
    if (this.isForeGround) {
      this.controller.start(); // Start playing when in the foreground.
      this.isStart = true;
    } else {
      this.controller.pause(); // Pause playback when in the background.
      this.isStart = false;
    }
  }

  // [End foregroundStatus_func]

  // 显示进度条和右边图标（3秒后自动隐藏）
  private showProgressBar(): void {
    this.isProgressBarVisible = true;
    // 横屏时不显示右边图标，竖屏时显示
    this.isRightIconsVisible = !this.isFullLandscapeScreen;
    this.clearProgressBarTimer();
    
    // 设置3秒后自动隐藏
    this.progressBarHideTimer = setTimeout(() => {
      this.isProgressBarVisible = false;
      this.isRightIconsVisible = false;
      this.progressBarHideTimer = -1;
    }, 3000);
  }

  // 清除进度条自动隐藏定时器
  private clearProgressBarTimer(): void {
    if (this.progressBarHideTimer !== -1) {
      clearTimeout(this.progressBarHideTimer);
      this.progressBarHideTimer = -1;
    }
  }

  // 显示倍数选择器（3秒后自动隐藏）
  private showSpeedSelector(): void {
    this.isSpeedSelectorVisible = true;
    this.clearSpeedSelectorTimer();
    
    // 设置3秒后自动隐藏
    this.speedSelectorHideTimer = setTimeout(() => {
      this.isSpeedSelectorVisible = false;
      this.speedSelectorHideTimer = -1;
    }, 3000);
  }

  // 清除倍数选择器自动隐藏定时器
  private clearSpeedSelectorTimer(): void {
    if (this.speedSelectorHideTimer !== -1) {
      clearTimeout(this.speedSelectorHideTimer);
      this.speedSelectorHideTimer = -1;
    }
  }

  // 更新视频播放速度
  private updatePlaybackSpeed(speed: number): void {
    // 将倍数转换为PlaybackSpeed枚举
    if (speed <= 0.5) {
      this.curRate = PlaybackSpeed.Speed_Forward_0_75_X; // 最慢速度
    } else if (speed <= 0.75) {
      this.curRate = PlaybackSpeed.Speed_Forward_0_75_X;
    } else if (speed <= 1.0) {
      this.curRate = PlaybackSpeed.Speed_Forward_1_00_X;
    } else if (speed <= 1.25) {
      this.curRate = PlaybackSpeed.Speed_Forward_1_25_X;
    } else if (speed <= 1.75) {
      this.curRate = PlaybackSpeed.Speed_Forward_1_75_X;
    } else if (speed <= 2.0) {
      this.curRate = PlaybackSpeed.Speed_Forward_2_00_X;
    } else {
      this.curRate = PlaybackSpeed.Speed_Forward_2_00_X; // 最快速度
    }
    
    hilog.info(DOMAIN, 'testTag', '%{public}s', '播放速度更新: ' + speed.toFixed(1) + 'X');
  }

  @Builder
  showFeatureIconInColumn(src: ResourceStr, content?: ResourceStr) {
    Column() {
      Image(src)
        .width(30)
      if (content) {
        Text(content)
          .fontSize(14)
          .lineHeight(19)
          .fontColor(Color.White)
          .margin({ top: 5 })
      }
    }
  }

  @Builder
  showFeatureIconInRow(src: ResourceStr, content?: ResourceStr) {
    Row({ space: 3 }) {
      Image(src)
        .width(22)
      if (content) {
        Text(content)
          .fontSize(14)
          .lineHeight(19)
          .fontColor(Color.White)
      }
    }
  }

  // SpeedGesture custom column component
  @Builder
  SpeedGestureColumn() {
    // [Start SpeedGestureColumn]
    Column()
      .width('20%')
      .height('100%')
      .gesture(
        LongPressGesture({ repeat: true })
          .onAction((event: GestureEvent | undefined) => {
            // The fast forward icon changes between visible and invisible states.
            this.leftRateOpacity = 1;
            this.rightRateOpacity = 0;
            if (!event) {
              return;
            }
            if (event.repeat) {
              this.isAccelerate = true;
              this.curRate = PlaybackSpeed.Speed_Forward_2_00_X;
              if (!this.isStart) {
                this.isStart = true;
                this.controller.start();
              }
            }
          })
          .onActionEnd(() => {
            this.isAccelerate = false;
            this.curRate = PlaybackSpeed.Speed_Forward_1_00_X;
          })
      );
    // [End SpeedGestureColumn]
  }

  // Use longPressGesture on both sides of the video screen to acceleration.
  @Builder
  SpeedGesture() {
    Row() {
      this.SpeedGestureColumn()
      Blank();
      this.SpeedGestureColumn()
    }
    .justifyContent(FlexAlign.SpaceBetween)
    .width('100%')
    .height('100%');
  }

  // Show dialog when accelerating.
  @Builder
  SpeedDialog() {
    Row() {
      Image($r('app.media.double_rate'))
        .width(10)
        .height(13)
        .opacity(this.leftRateOpacity)
        .animation({
          duration: 500,
          curve: Curve.Linear,
          delay: 500,
          iterations: -1,
          playMode: PlayMode.Alternate,
          expectedFrameRateRange: {
            min: 0,
            max: 1,
            expected: 1,
          }
        });
      Image($r('app.media.double_rate'))
        .width(10)
        .height(13)
        .opacity(this.rightRateOpacity)
        .animation({
          duration: 500,
          curve: Curve.Linear,
          delay: 500,
          iterations: -1,
          playMode: PlayMode.Alternate,
          expectedFrameRateRange: {
            min: 0,
            max: 1,
            expected: 0,
          }
        });

      Text($r('app.string.fast_forwarding'))
        .fontColor(Color.White);
    }
    .width(140)
    .height(32)
    .padding({
      left: 16,
      right: 16
    })
    .backgroundColor('rgba(31, 31, 38, 0.5)')
    .borderRadius(16)
    .visibility(this.isAccelerate ? Visibility.Visible : Visibility.Hidden)
    .position({
      left: (this.screenWidth - CommonConstants.RATE_DIALOG_WIDTH) / 2,
      top: 100
    });
  }

  // Playback progress bar.
  @Builder
  PlaybackProgressBar() {
    Row() {
      Text(formatVideoTime(this.currentTime))
        .fontColor(Color.White)
        .fontSize(12)
      Slider({
        value: this.currentTime,
        min: 0,
        max: this.durationTime
      })
        .trackColor(Color.White)
        .opacity(0.6)
        .onChange((value: number) => {
          // Set the video playback progress to jump to the value.
          this.controller.setCurrentTime(value, SeekMode.Accurate);
          // 拖拽时重置隐藏定时器
          this.showProgressBar();
        })
        .layoutWeight(1)
      Text(formatVideoTime(this.durationTime))
        .fontColor(Color.White)
        .fontSize(12)

      // 倍数按钮
      Stack() {
        Text(this.playbackSpeed.toFixed(1) + 'X')
          .fontColor(Color.White)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
      }
      .width(50)
      .height(30)
      .margin({ left: 12 })
      .backgroundColor('rgba(255, 255, 255, 0.2)')
      .borderRadius(15)
      .onClick(() => {
        // 切换倍数选择器显示状态
        if (this.isSpeedSelectorVisible) {
          // 如果已显示，则隐藏
          this.isSpeedSelectorVisible = false;
          this.clearSpeedSelectorTimer();
        } else {
          // 如果未显示，则显示并启动自动隐藏定时器
          this.showSpeedSelector();
        }
        hilog.info(DOMAIN, 'testTag', '%{public}s', '倍数按钮点击: ' + this.isSpeedSelectorVisible);
      })

      Stack() {
        Image($r('app.media.ic_video_menu_landscape_fullscreen'))
          .fillColor($r('sys.color.white'))
          .width($r('app.float.size_25'))
          .height($r('app.float.size_25'))
          .margin({ left: 20 })
      }
      .width(30)
      .height(30)
      .onClick(() => {
        this.windowUtil.handleFullScreen(true); // Set full screen.
      })
      .visibility(this.isFullLandscapeScreen ? Visibility.None : Visibility.Visible)
    }
    .padding({
      left: 25,
      right: 25
    })
    .zIndex(1)
    .height('auto')
    .width('100%')
    .position({ y: this.isFullLandscapeScreen ? 310 : 680 })
    .visibility(this.isProgressBarVisible ? Visibility.Visible : Visibility.Hidden)
    .opacity(this.isProgressBarVisible ? 1 : 0)
    .animation({
      duration: 200,
      curve: Curve.EaseInOut
    })
  }

  build() {
    Stack() {
      if (this.activeIndex === this.videoIndex && 
          this.activeIndex >= 0 && 
          this.activeIndex < this.videoList.length) {
        // [Start currentProgressRate]
        Video({
          src: this.videoList[this.activeIndex].uri,
          controller: this.controller,
          currentProgressRate: this.curRate
        })
        // [End currentProgressRate]
          .autoPlay(true)
          .loop(false)
          .controls(false)
          .objectFit(ImageFit.Contain)
          .width('100%')
          .height('100%')
          .onPrepared((event) => {
            if (event) {
              this.durationTime = event.duration;
            }
          })
          .onUpdate((event) => {
            if (event) {
              this.currentTime = event.time;
            }
          })
          // [Start showNext]
          .onFinish(() => {
            hilog.info(DOMAIN, 'testTag', '%{public}s', 'onFinish and showNext.');
            this.swiperController?.showNext();
          })
        // [End showNext]
      } else {
        Video({})
          .controls(false)
          .objectFit(ImageFit.Contain)
          .width('100%')
          .height('100%')
      }

      // Start and stop button.
      Button({ stateEffect: true }) {
        Image($r('app.media.play'))
      }
      .height(56)
      .aspectRatio(1)
      .opacity(0.2)
      .backgroundColor(Color.Transparent)
      .visibility(this.isStart ? Visibility.Hidden : Visibility.Visible)

      Button({ type: ButtonType.Circle }) {
        Image($r('sys.media.ohos_ic_public_arrow_left'))
          .fillColor(Color.White)
          .width($r('app.float.size_24'))
          .height($r('app.float.size_24'))
      }
      .width($r('app.float.button_back_size'))
      .height($r('app.float.button_back_size'))
      .backgroundColor('rgba(255,255,255,0.1)')
      .position({
        x: $r('app.float.size_25'),
        y: $r('app.float.size_25')
      })
      .zIndex(1)
      .onClick(() => {
        this.windowUtil.handleFullScreenExit(false); // Exit full screen
      })
      .visibility(this.isFullLandscapeScreen ? Visibility.Visible : Visibility.Hidden)

      this.PlaybackProgressBar() // The playback progress bar component

      // 倍数选择器（显示在倍数按钮上方）
      if (this.isSpeedSelectorVisible) {
        Column() {
          // 当前倍数显示（上方）
          Text(this.playbackSpeed.toFixed(1) + 'X')
            .fontColor(Color.White)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .margin({ bottom: 12 })
          
          // 倍数滑动条容器（可直接拖动）
          Stack() {
            // 背景轨道
            Row()
              .width('100%')
              .height(8)
              .backgroundColor('rgba(255, 255, 255, 0.3)')
              .borderRadius(4)
            
            // 已选择部分（高亮）
            Row()
              .width(((this.playbackSpeed - 0.5) / 4.5 * 100) + '%')
              .height(8)
              .backgroundColor('#FF4D4D')
              .borderRadius(4)
            
            // 节点标记（0.5、1、2、3、4、5倍数位置）
            Row() {
              ForEach([0.5, 1, 2, 3, 4, 5], (speed: number) => {
                Column() {
                  // 节点圆点
                  Column()
                    .width(12)
                    .height(12)
                    .backgroundColor(this.playbackSpeed >= speed - 0.25 && this.playbackSpeed <= speed + 0.25 ? 
                      '#FF4D4D' : 'rgba(255, 255, 255, 0.8)')
                    .borderRadius(6)
                    .border({ width: 2, color: Color.White })
                  
                  // 节点标签
                  Text(speed + 'X')
                    .fontColor(Color.White)
                    .fontSize(10)
                    .margin({ top: 4 })
                }
                .position({
                  x: ((speed - 0.5) / 4.5 * 100) + '%',
                  y: -6
                })
                .markAnchor({ x: speed === 0.5 ? '0%' : (speed === 5 ? '100%' : '50%'), y: '50%' })
              })
            }
            .width('100%')
          }
          .width(240)
          .height(50)
          .margin({ top: 8, bottom: 8 })
          .onClick((event: ClickEvent) => {
            // 点击进度条，直接跳转到对应位置
            if (event) {
              const localX = event.x;
              const sliderWidth = 240;
              
              // 计算点击位置对应的倍数
              const ratio = localX / sliderWidth;
              let newSpeed = 0.5 + ratio * 4.5;
              
              // 限制在0.5-5范围内
              newSpeed = Math.max(0.5, Math.min(5, newSpeed));
              
              // 四舍五入到小数点后一位
              newSpeed = Math.round(newSpeed * 10) / 10;
              
              // 检查是否靠近节点，自动吸附
              const nodes = [0.5, 1, 2, 3, 4, 5];
              for (const node of nodes) {
                if (Math.abs(newSpeed - node) <= 0.3) {
                  newSpeed = node;
                  break;
                }
              }
              
              // 更新倍数
              this.playbackSpeed = newSpeed;
              this.updatePlaybackSpeed(newSpeed);
              
              hilog.info(DOMAIN, 'testTag', '%{public}s', '点击倍数: ' + newSpeed.toFixed(1) + 'X');
              
              // 重新启动自动隐藏定时器
              this.showSpeedSelector();
            }
          })
          .gesture(
            PanGesture({ direction: PanDirection.Horizontal })
              .onActionStart(() => {
                // 开始滑动时，清除自动隐藏定时器
                this.clearSpeedSelectorTimer();
              })
              .onActionUpdate((event: GestureEvent) => {
                if (event) {
                  // 使用offsetX计算滑动距离
                  const offsetX = event.offsetX;
                  const sliderWidth = 240;
                  const speedRange = 4.5; // 倍数范围（5 - 0.5）
                  
                  // 计算新的倍数（基于当前倍数加上滑动偏移）
                  const speedChange = (offsetX / sliderWidth) * speedRange * 0.3;
                  let newSpeed = this.playbackSpeed + speedChange;
                  
                  // 限制在0.5-5范围内
                  newSpeed = Math.max(0.5, Math.min(5, newSpeed));
                  
                  // 四舍五入到小数点后一位
                  newSpeed = Math.round(newSpeed * 10) / 10;
                  
                  // 更新倍数
                  this.playbackSpeed = newSpeed;
                  
                  // 更新视频播放速度
                  this.updatePlaybackSpeed(newSpeed);
                  
                  hilog.info(DOMAIN, 'testTag', '%{public}s', '拖动倍数: ' + newSpeed.toFixed(1) + 'X');
                }
              })
              .onActionEnd(() => {
                // 滑动结束，检查是否靠近节点，自动吸附
                const nodes = [0.5, 1, 2, 3, 4, 5];
                for (const node of nodes) {
                  if (Math.abs(this.playbackSpeed - node) <= 0.3) {
                    // 吸附到最近的节点
                    this.playbackSpeed = node;
                    this.updatePlaybackSpeed(node);
                    hilog.info(DOMAIN, 'testTag', '%{public}s', '倍数吸附到节点: ' + node + 'X');
                    break;
                  }
                }
                
                // 滑动结束后，重新启动自动隐藏定时器
                this.showSpeedSelector();
              })
          )
        }
        .width(280)
        .height(110)
        .padding({ left: 20, right: 20, top: 15, bottom: 15 })
        .backgroundColor('rgba(0, 0, 0, 0.85)')
        .borderRadius(12)
        .position({
          x: this.isFullLandscapeScreen ? 180 : 60,
          y: this.isFullLandscapeScreen ? 230 : 570
        })
        .zIndex(10)
      }

      RelativeContainer() {
        Column({ space: 20 }) {
          Image($r('app.media.menu_icon_user_avatar')).width(44)
          this.showFeatureIconInColumn($r('app.media.menu_icon_like'), '1557')
          this.showFeatureIconInColumn($r('app.media.menu_icon_comment'), '566')
          this.showFeatureIconInColumn($r('app.media.menu_icon_share'), '147')
          Image($r('app.media.menu_icon_music_cover')).width(32)
        }
        .alignRules({
          right: { anchor: '__container__', align: HorizontalAlign.End },
          bottom: { anchor: '__container__', align: VerticalAlign.Bottom }
        })
        .margin({ right: 8, bottom: 90 })
        .visibility(Visibility.None) // 竖屏时隐藏右侧图标
      }

      Row({ space: 18 }) {
        this.showFeatureIconInRow($r('app.media.menu_icon_like'), '1557')
        this.showFeatureIconInRow($r('app.media.menu_icon_comment'), '566')
        this.showFeatureIconInRow($r('app.media.menu_icon_share'), '147')
      }
      .justifyContent(FlexAlign.Start)
      .width('100%')
      .position({
        x: $r('app.float.size_25'),
        y: 348
      })
      .visibility(Visibility.None) // 横屏时隐藏图标

      SetVolume({
        volume: this.volume,
        volumeVisible: this.volumeVisible,
        isFullLandscapeScreen: this.isFullLandscapeScreen
      }) // Volume setting component
      this.SpeedGesture(); // Speed adjustment gesture component
      this.SpeedDialog(); // Speed adjustment dialog
    }
    .backgroundColor('#D8D8D8')
    .width('100%')
    .height('100%')
    .layoutWeight(1)
    .align(Alignment.Center)
    .onClick(() => {
      // 单击显示进度条，双击暂停/播放
      const currentTime = Date.now();
      const timeDiff = currentTime - this.lastClickTime;
      
      if (timeDiff < 300) {
        // 双击：暂停/播放
        hilog.info(DOMAIN, 'testTag', '%{public}s', '双击: 暂停/播放');
        this.isStart ? this.controller.pause() : this.controller.start();
        this.isStart = !this.isStart;
        // 隐藏进度条和右边图标
        this.isProgressBarVisible = false;
        this.isRightIconsVisible = false;
        this.clearProgressBarTimer();
      } else {
        // 单击：显示进度条（横屏时不显示右边图标）
        hilog.info(DOMAIN, 'testTag', '%{public}s', '单击: 显示进度条');
        this.showProgressBar();
      }
      
      this.lastClickTime = currentTime;
    })
    .gesture(
      // Combined gesture: LongPressGesture and PanGesture.
      GestureGroup(GestureMode.Sequence,
        // [Start LongPressGesture]
        LongPressGesture({ repeat: true })
          .onAction((event: GestureEvent | undefined) => {
            hilog.info(DOMAIN, 'testTag', '%{public}s', 'LongPressGesture:' + event);
            if (event) {
              this.volumeVisible = true;
            }
          })
          .onActionEnd(() => {
            this.volumeVisible = false;
          }),
        // [End LongPressGesture]
        // [Start PanGesture]
        // When dragging after a long press, the PanGesture gesture is triggered.
        PanGesture({ direction: PanDirection.Vertical })
          .onActionUpdate((event: GestureEvent) => {
            let curVolume = this.volume - this.getUIContext().vp2px(event.offsetY) / this.windowHeight;
            curVolume = curVolume >= 15.0 ? 15.0 : curVolume;
            curVolume = curVolume <= 0.0 ? 0.0 : curVolume;
            this.volume = curVolume;
          })
          .onActionEnd(() => {
            setTimeout(() => {
              this.volumeVisible = false;
            }, 5000)
          })
        // [End PanGesture]
      )
    )
  }
}