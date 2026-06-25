import { Popup } from '@kit.ArkUI';
import ResultDialog from './ResultDialog';

interface PopupStateChangeEvent {
  isVisible: boolean;
}

enum PopupPlacement {
  Top = 'top',
  Bottom = 'bottom',
  Left = 'left',
  Right = 'right',
  TopLeft = 'topLeft',
  TopRight = 'topRight',
  BottomLeft = 'bottomLeft',
  BottomRight = 'bottomRight',
  Center = 'center'
}

@Entry
@Component
export default struct GameView {
  @State score: number = 0;
  @State highScore: number = 0;
  @State timeLeft: number = 60; // 60 seconds game
  @State gameActive: boolean = false;
  @State showResultDialog: boolean = false;
  @State clickPower: number = 1;
  @State autoClickerLevel: number = 0;
  @State autoClickerInterval: number = 0;
  @State coins: number = 100; // In-game currency

  private timerId: number | undefined = undefined;
  private autoClickerId: number | undefined = undefined;

  aboutToAppear() {
    // Load saved high score
    // In a real app, you would use Preferences or other persistence
    this.highScore = 0;
  }

  aboutToDisappear() {
    this.stopTimers();
  }

  startGame() {
    this.score = 0;
    this.timeLeft = 60;
    this.gameActive = true;
    this.startTimer();
    this.startAutoClicker();
  }

  startTimer() {
    this.timerId = setInterval(() => {
      if (this.timeLeft > 0) {
        this.timeLeft -= 1;
      } else {
        this.endGame();
      }
    }, 1000);
  }

  startAutoClicker() {
    if (this.autoClickerLevel > 0) {
      this.autoClickerId = setInterval(() => {
        if (this.gameActive) {
          this.score += this.autoClickerLevel;
          this.coins += Math.floor(this.autoClickerLevel / 2);
        }
      }, 1000 / this.autoClickerLevel); // Faster with higher level
    }
  }

  stopTimers() {
    if (this.timerId !== undefined) {
      clearInterval(this.timerId);
      this.timerId = undefined;
    }
    if (this.autoClickerId !== undefined) {
      clearInterval(this.autoClickerId);
      this.autoClickerId = undefined;
    }
  }

  handleClick() {
    if (this.gameActive) {
      this.score += this.clickPower;
      this.coins += 1;
      
      // Random chance to get bonus
      if (Math.random() < 0.1) { // 10% chance
        this.score += 5;
        this.coins += 5;
      }
    }
  }

  upgradeClickPower() {
    const cost = 50 * (this.clickPower);
    if (this.coins >= cost) {
      this.coins -= cost;
      this.clickPower += 1;
    }
  }

  upgradeAutoClicker() {
    const cost = 100 * (this.autoClickerLevel + 1);
    if (this.coins >= cost) {
      this.coins -= cost;
      this.autoClickerLevel += 1;
      
      // Restart auto clicker with new level
      if (this.autoClickerId !== undefined) {
        clearInterval(this.autoClickerId);
      }
      this.startAutoClicker();
    }
  }

  endGame() {
    this.stopTimers();
    this.gameActive = false;
    
    // Update high score
    if (this.score > this.highScore) {
      this.highScore = this.score;
    }
    
    this.showResultDialog = true;
  }

  restartGame() {
    this.showResultDialog = false;
    this.startGame();
  }

  exitToMenu() {
    this.showResultDialog = false;
    this.gameActive = false;
    this.score = 0;
    this.timeLeft = 60;
    this.stopTimers();
  }

  getTimeColor(): ResourceColor {
    if (this.timeLeft <= 10) {
      return Color.Red;
    } else if (this.timeLeft <= 30) {
      return Color.Orange;
    } else {
      return Color.Green;
    }
  }

  build() {
    Column({ space: 20 }) {
      // Game Header
      Row({ space: 20 }) {
        Column({ space: 5 }) {
          Text('SCORE')
            .fontSize(14)
            .fontColor(Color.Gray)
          Text(this.score.toString())
            .fontSize(32)
            .fontColor(Color.Blue)
            .fontWeight(FontWeight.Bold)
        }
        
        Column({ space: 5 }) {
          Text('HIGH SCORE')
            .fontSize(14)
            .fontColor(Color.Gray)
          Text(this.highScore.toString())
            .fontSize(24)
            .fontColor(Color.Purple)
        }
        
        Column({ space: 5 }) {
          Text('COINS')
            .fontSize(14)
            .fontColor(Color.Gray)
          Text(this.coins.toString())
            .fontSize(24)
            .fontColor(Color.Gold)
        }
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .padding({ left: 20, right: 20, top: 10 })

      // Timer Bar
      Stack() {
        // Background bar
        Row()
          .width('100%')
          .height(20)
          .backgroundColor(Color.LightGray)
          .borderRadius(10)
        
        // Progress bar
        Row()
          .width(`${(this.timeLeft / 60) * 100}%`)
          .height(20)
          .backgroundColor(this.getTimeColor())
          .borderRadius(10)
        
        // Timer text
        Text(`${this.timeLeft}s`)
          .fontSize(14)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 10 })
      }
      .width('90%')
      .height(20)

      // Main Game Area
      Column({ space: 15 }) {
        Text('TAP FAST!')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.Black)
        
        Text('Click the button below to earn points')
          .fontSize(16)
          .fontColor(Color.Gray)
          .textAlign(TextAlign.Center)
        
        // Main Click Button
        Button() {
          Column({ space: 10 }) {
            Image($r('app.media.startIcon'))
              .width(80)
              .height(80)
            Text(`CLICK! (+${this.clickPower})`)
              .fontSize(18)
              .fontColor(Color.White)
          }
        }
        .width(200)
        .height(200)
        .backgroundColor(Color.Blue)
        .borderRadius(100)
        .enabled(this.gameActive)
        .onClick(() => {
          this.handleClick();
        })
        
        // Stats
        Row({ space: 30 }) {
          Column({ space: 5 }) {
            Text('Power')
              .fontSize(14)
              .fontColor(Color.Gray)
            Text(`Level ${this.clickPower}`)
              .fontSize(18)
              .fontColor(Color.Blue)
          }
          
          Column({ space: 5 }) {
            Text('Auto-Clicker')
              .fontSize(14)
              .fontColor(Color.Gray)
            Text(`Level ${this.autoClickerLevel}`)
              .fontSize(18)
              .fontColor(Color.Green)
          }
        }
        .margin({ top: 20 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
      .margin({ top: 20 })

      // Upgrades Section
      Column({ space: 15 }) {
        Text('UPGRADES')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.Black)
          .margin({ bottom: 10 })
        
        Row({ space: 20 }) {
          Button('Upgrade Power')
            .width(150)
            .height(60)
            .fontSize(14)
            .fontColor(Color.White)
            .backgroundColor(this.coins >= 50 * this.clickPower ? Color.Green : Color.Gray)
            .enabled(this.coins >= 50 * this.clickPower)
            .onClick(() => {
              this.upgradeClickPower();
            })
          
          Button('Auto-Clicker')
            .width(150)
            .height(60)
            .fontSize(14)
            .fontColor(Color.White)
            .backgroundColor(this.coins >= 100 * (this.autoClickerLevel + 1) ? Color.Blue : Color.Gray)
            .enabled(this.coins >= 100 * (this.autoClickerLevel + 1))
            .onClick(() => {
              this.upgradeAutoClicker();
            })
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
      .padding(20)
      .backgroundColor(0xF5F5F5)
      .borderRadius(20)
      .margin({ top: 20, left: 20, right: 20 })

      // Control Buttons
      Row({ space: 20 }) {
        Button(this.gameActive ? 'Game Running...' : 'START GAME')
          .width(180)
          .height(50)
          .fontSize(18)
          .fontColor(Color.White)
          .backgroundColor(this.gameActive ? Color.Gray : Color.Green)
          .enabled(!this.gameActive)
          .onClick(() => {
            this.startGame();
          })
        
        Button('RESET')
          .width(180)
          .height(50)
          .fontSize(18)
          .fontColor(Color.White)
          .backgroundColor(Color.Red)
          .onClick(() => {
            this.exitToMenu();
          })
      }
      .margin({ top: 20, bottom: 30 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(Color.White)

    // Result Dialog
    .bindPopup(this.showResultDialog, {
      builder: () => {
        return ResultDialog({
          score: this.score,
          highScore: this.highScore,
          onRestart: () => {
            this.restartGame();
          },
          onExit: () => {
            this.exitToMenu();
          }
        });
      },
      placement: PopupPlacement.Center,
      maskColor: 0x66000000,
      popupColor: Color.White,
      enableArrow: false,
      onStateChange: (e: PopupStateChangeEvent) => {
        if (!e.isVisible) {
          this.showResultDialog = false;
        }
      }
    })
  }
}