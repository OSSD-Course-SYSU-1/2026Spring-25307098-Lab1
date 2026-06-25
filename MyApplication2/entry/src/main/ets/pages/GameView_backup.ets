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
  @State timeLeft: number = 30; // 30 seconds game
  @State gameActive: boolean = false;
  @State showResultDialog: boolean = false;

  private timerId: number | undefined = undefined;

  aboutToAppear() {
    // Initialize game
  }

  aboutToDisappear() {
    this.stopTimer();
  }

  startGame() {
    this.score = 0;
    this.timeLeft = 30;
    this.gameActive = true;
    this.startTimer();
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

  stopTimer() {
    if (this.timerId !== undefined) {
      clearInterval(this.timerId);
      this.timerId = undefined;
    }
  }

  incrementScore() {
    if (this.gameActive) {
      this.score += 1;
    }
  }

  endGame() {
    this.stopTimer();
    this.gameActive = false;
    this.showResultDialog = true;
  }

  restartGame() {
    this.showResultDialog = false;
    this.startGame();
  }

  exitGame() {
    this.showResultDialog = false;
    this.gameActive = false;
    this.score = 0;
    this.timeLeft = 30;
  }

  build() {
    Column({ space: 20 }) {
      // Title
      Text('Simple Click Game')
        .fontSize(30)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.Black)

      // Score display
      Row({ space: 10 }) {
        Text('Score:')
          .fontSize(24)
        Text(this.score.toString())
          .fontSize(36)
          .fontColor(Color.Blue)
      }

      // Timer display
      Row({ space: 10 }) {
        Text('Time Left:')
          .fontSize(24)
        Text(this.timeLeft.toString() + 's')
          .fontSize(36)
          .fontColor(this.timeLeft <= 10 ? Color.Red : Color.Green)
      }

      // Click button
      Button('Click Me!')
        .width(200)
        .height(80)
        .fontSize(24)
        .fontColor(Color.White)
        .backgroundColor(Color.Blue)
        .enabled(this.gameActive)
        .onClick(() => {
          this.incrementScore();
        })

      // Start / Restart button
      Button(this.gameActive ? 'Game Running...' : 'Start Game')
        .width(200)
        .height(60)
        .fontSize(20)
        .fontColor(Color.White)
        .backgroundColor(this.gameActive ? Color.Gray : Color.Green)
        .enabled(!this.gameActive)
        .onClick(() => {
          this.startGame();
        })

      // Instructions
      Text('Click the button as many times as you can within 30 seconds!')
        .fontSize(16)
        .fontColor(Color.Gray)
        .textAlign(TextAlign.Center)
        .padding({ top: 30 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(Color.White)

    // Result Dialog
    .bindPopup(this.showResultDialog, {
      builder: () => {
        return ResultDialog({
          score: this.score,
          onRestart: () => {
            this.restartGame();
          },
          onExit: () => {
            this.exitGame();
          }
        });
      },
      placement: PopupPlacement.Bottom,
      maskColor: 0x33000000,
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