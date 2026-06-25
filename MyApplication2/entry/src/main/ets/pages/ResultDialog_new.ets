@Component
export default struct ResultDialog {
  private score: number = 0;
  private highScore: number = 0;
  private onRestart: () => void = () => {};
  private onExit: () => void = () => {};

  build() {
    Column({ space: 25 }) {
      // Header
      Text('GAME OVER')
        .fontSize(32)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.Red)
        .margin({ bottom: 10 })

      // Score Section
      Column({ space: 10 }) {
        Text('YOUR SCORE')
          .fontSize(18)
          .fontColor(Color.Gray)
        
        Text(this.score.toString())
          .fontSize(64)
          .fontColor(Color.Blue)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 5, bottom: 5 })
        
        // Performance rating
        if (this.score >= 1000) {
          Text('LEGENDARY! 🏆')
            .fontSize(20)
            .fontColor(Color.Gold)
            .fontWeight(FontWeight.Bold)
        } else if (this.score >= 500) {
          Text('EXCELLENT! ⭐⭐⭐')
            .fontSize(20)
            .fontColor(Color.Green)
            .fontWeight(FontWeight.Bold)
        } else if (this.score >= 200) {
          Text('GOOD JOB! ⭐⭐')
            .fontSize(20)
            .fontColor(Color.Blue)
            .fontWeight(FontWeight.Bold)
        } else if (this.score >= 100) {
          Text('NOT BAD! ⭐')
            .fontSize(20)
            .fontColor(Color.Orange)
            .fontWeight(FontWeight.Bold)
        } else {
          Text('KEEP PRACTICING! 💪')
            .fontSize(20)
            .fontColor(Color.Gray)
            .fontWeight(FontWeight.Bold)
        }
      }
      .alignItems(HorizontalAlign.Center)

      // High Score Section
      if (this.score === this.highScore && this.highScore > 0) {
        Column({ space: 5 }) {
          Text('🎉 NEW HIGH SCORE! 🎉')
            .fontSize(18)
            .fontColor(Color.Gold)
            .fontWeight(FontWeight.Bold)
            .margin({ top: 10 })
        }
        .backgroundColor(0x20FFD700) // Gold with transparency
        .padding({ left: 20, right: 20, top: 10, bottom: 10 })
        .borderRadius(10)
        .margin({ top: 10, bottom: 10 })
      }

      // Stats Section
      Row({ space: 30 }) {
        Column({ space: 5 }) {
          Text('HIGH SCORE')
            .fontSize(14)
            .fontColor(Color.Gray)
          Text(this.highScore.toString())
            .fontSize(24)
            .fontColor(Color.Purple)
            .fontWeight(FontWeight.Bold)
        }
        
        Column({ space: 5 }) {
          Text('RANK')
            .fontSize(14)
            .fontColor(Color.Gray)
          if (this.score >= 1000) {
            Text('S')
              .fontSize(24)
              .fontColor(Color.Gold)
              .fontWeight(FontWeight.Bold)
          } else if (this.score >= 500) {
            Text('A')
              .fontSize(24)
              .fontColor(Color.Green)
              .fontWeight(FontWeight.Bold)
          } else if (this.score >= 200) {
            Text('B')
              .fontSize(24)
              .fontColor(Color.Blue)
              .fontWeight(FontWeight.Bold)
          } else if (this.score >= 100) {
            Text('C')
              .fontSize(24)
              .fontColor(Color.Orange)
              .fontWeight(FontWeight.Bold)
          } else {
            Text('D')
              .fontSize(24)
              .fontColor(Color.Red)
              .fontWeight(FontWeight.Bold)
          }
        }
        
        Column({ space: 5 }) {
          Text('POINTS/SEC')
            .fontSize(14)
            .fontColor(Color.Gray)
          Text((this.score / 60).toFixed(1))
            .fontSize(24)
            .fontColor(Color.Blue)
            .fontWeight(FontWeight.Bold)
        }
      }
      .margin({ top: 20, bottom: 20 })

      // Action Buttons
      Column({ space: 15 }) {
        Button('PLAY AGAIN') {
          Row({ space: 10 }) {
            Image($r('app.media.startIcon'))
              .width(24)
              .height(24)
            Text('RESTART GAME')
              .fontSize(18)
          }
        }
        .width(250)
        .height(55)
        .fontColor(Color.White)
        .backgroundColor(Color.Green)
        .borderRadius(15)
        .onClick(() => {
          this.onRestart();
        })

        Button('BACK TO MENU') {
          Row({ space: 10 }) {
            Text('EXIT TO MENU')
              .fontSize(18)
          }
        }
        .width(250)
        .height(55)
        .fontColor(Color.White)
        .backgroundColor(Color.Red)
        .borderRadius(15)
        .onClick(() => {
          this.onExit();
        })
      }
      .margin({ top: 20 })

      // Tips
      Text('Tip: Upgrade your click power and auto-clicker for higher scores!')
        .fontSize(12)
        .fontColor(Color.Gray)
        .textAlign(TextAlign.Center)
        .margin({ top: 25, left: 20, right: 20 })
        .opacity(0.7)
    }
    .width(350)
    .padding({ top: 30, bottom: 30, left: 25, right: 25 })
    .backgroundColor(Color.White)
    .borderRadius(25)
    .shadow({ radius: 30, color: 0x33000000, offsetX: 0, offsetY: 5 })
  }
}