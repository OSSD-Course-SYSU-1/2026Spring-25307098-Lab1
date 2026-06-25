import { GameMode, PlayerSide } from '../common/GameConfig';

@Component
struct ResultDialog {
  @Prop isWin: boolean = false;
  @Prop winner: PlayerSide = PlayerSide.Bottom;
  @Prop gameMode: GameMode = GameMode.Single;
  private onRestart: () => void = () => {};
  private onExit: () => void = () => {};

  build() {
    Column() {
      // 结果文字
      if (this.gameMode === GameMode.Single) {
        Text(this.isWin ? '🎉 胜利！' : '💀 失败')
          .fontSize(48)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.isWin ? '#00FF88' : '#FF4444')
          .margin({ bottom: 40 })
      } else {
        Text(this.winner === PlayerSide.Bottom ? '🔵 蓝方胜利！' : '🔴 红方胜利！')
          .fontSize(48)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.winner === PlayerSide.Bottom ? '#007DFF' : '#FF3B30')
          .margin({ bottom: 40 })
      }

      // 按钮区域
      Row() {
        Button('重新开始')
          .width(120)
          .height(44)
          .fontSize(16)
          .fontColor(Color.White)
          .backgroundColor('#4CAF50')
          .onClick(() => {
            this.onRestart();
          })

        Button('退出游戏')
          .width(120)
          .height(44)
          .fontSize(16)
          .fontColor(Color.White)
          .backgroundColor('#FF6B6B')
          .margin({ left: 20 })
          .onClick(() => {
            this.onExit();
          })
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#B3000000')
  }
}

export default ResultDialog;
