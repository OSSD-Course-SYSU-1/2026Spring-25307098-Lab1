import { router } from '@kit.ArkUI';
import { AbilityConstant } from '@kit.AbilityKit';
import { GameConfig } from '../common/GameConfig';
import { GameManager } from '../common/GameManager';
import common from '@ohos.app.ability.common';

/**
 * 主菜单页面
 * 提供游戏模式选择和退出功能
 */
@Entry
@Component
struct MainMenu {
  @StorageLink('autoContinuation') private autoContinuation: boolean = false;

  /**
   * 页面创建时检查是否有跨端流转数据需要恢复
   */
  aboutToAppear(): void {
    const continuationData = GameManager.getContinuationData();
    if (continuationData) {
      console.info('MainMenu: detecting continuation data, navigating to GameView');
      // 延迟一帧跳转，确保页面已渲染完成
      setTimeout(() => {
        router.replaceUrl({
          url: 'pages/GameView',
          params: {
            mode: 'continuation'
          }
        }).catch((error: Error) => {
          console.error('Continuation navigation failed:', error.message);
        });
      }, 100);
    }
  }

  /**
   * 流转开关变化时，同步设置 Ability 的流转状态
   */
  private onContinuationToggle(value: boolean): void {
    this.autoContinuation = value;
    GameManager.setAutoContinuation(value);
    console.info(`Auto continuation set to: ${value}`);

    // 同步更新 Ability 的流转能力状态
    try {
      const context = getContext(this) as common.UIAbilityContext;
      context.setMissionContinueState(
        value ? AbilityConstant.ContinueState.ACTIVE : AbilityConstant.ContinueState.INACTIVE,
        (result) => {
          console.info(`setMissionContinueState result: ${JSON.stringify(result)}`);
        }
      );
    } catch (error) {
      console.error('Failed to set mission continue state:', JSON.stringify(error));
    }
  }

  build() {
    Column() {
      // 标题区域
      Column() {
        Text('弹球游戏')
          .fontSize(48)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 10 })
        
        Text('Pong Game')
          .fontSize(20)
          .fontColor('#AAAAAA')
      }
      .margin({ top: 100, bottom: 80 })

      // 菜单选项区域
      Column({ space: 20 }) {
        // 单人游戏按钮
        this.MenuButton('单人游戏', () => {
          this.startSinglePlayer();
        })

        // 双人游戏按钮
        this.MenuButton('双人游戏', () => {
          this.startMultiPlayer();
        })

        // 退出游戏按钮
        this.MenuButton('退出游戏', () => {
          this.exitGame();
        }, true)
      }
      .width('80%')

      // 自动流转开关
      Row() {
        Column() {
          Text('自动流转')
            .fontSize(16)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Medium)
          Text('开启后可将游戏无缝转到其他设备')
            .fontSize(11)
            .fontColor('#AAAAAA')
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Toggle({ type: ToggleType.Switch, isOn: this.autoContinuation })
          .onChange((isOn: boolean) => {
            this.onContinuationToggle(isOn);
          })
      }
      .width('80%')
      .padding({ top: 20, bottom: 20, left: 16, right: 16 })
      .backgroundColor('#223366')
      .borderRadius(12)
      .margin({ top: 30 })

      // 底部信息
      Column() {
        Text('触摸屏幕控制挡板移动')
          .fontSize(14)
          .fontColor('#888888')
          .margin({ top: 40 })
        
        Text('点击发射按钮发射子弹')
          .fontSize(14)
          .fontColor('#888888')
          .margin({ top: 8 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(GameConfig.BACKGROUND_COLOR)
    .justifyContent(FlexAlign.Start)
  }

  /**
   * 菜单按钮组件
   */
  @Builder
  MenuButton(text: string, onClick: () => void, isExit: boolean = false) {
    Button(text)
      .width('100%')
      .height(60)
      .fontSize(24)
      .fontColor(Color.White)
      .backgroundColor(isExit ? '#AA3333' : '#3388FF')
      .borderRadius(12)
      .shadow({
        radius: 8,
        color: isExit ? '#662222' : '#224488',
        offsetX: 0,
        offsetY: 4
      })
      .onClick(onClick)
  }

  /**
   * 开始单人游戏
   */
  private startSinglePlayer(): void {
    router.pushUrl({
      url: 'pages/GameView',
      params: {
        mode: 'single'
      }
    }).catch((error: Error) => {
      console.error('跳转失败:', error.message);
    });
  }

  /**
   * 开始双人游戏
   */
  private startMultiPlayer(): void {
    router.pushUrl({
      url: 'pages/GameView',
      params: {
        mode: 'multi'
      }
    }).catch((error: Error) => {
      console.error('跳转失败:', error.message);
    });
  }

  /**
   * 退出游戏
   */
  private exitGame(): void {
    // 调用系统API退出应用
    const context = getContext(this) as common.UIAbilityContext;
    context.terminateSelf();
  }
}
