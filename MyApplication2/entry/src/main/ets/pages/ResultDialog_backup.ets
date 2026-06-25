@Component
export default struct ResultDialog {
  private score: number = 0;
  private onRestart: () => void = () => {};
  private onExit: () => void = () => {};

  build() {
    Column({ space: 20 }) {
      Text('Game Over!')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.Black)

      Text('Your Score:')
        .fontSize(22)
        .fontColor(Color.Gray)

      Text(this.score.toString())
        .fontSize(48)
        .fontColor(Color.Blue)
        .fontWeight(FontWeight.Bold)

      Text('Great job!')
        .fontSize(18)
        .fontColor(Color.Gray)

      Row({ space: 30 }) {
        Button('Restart')
          .width(120)
          .height(50)
          .fontSize(18)
          .fontColor(Color.White)
          .backgroundColor(Color.Green)
          .onClick(() => {
            this.onRestart();
          })

        Button('Exit')
          .width(120)
          .height(50)
          .fontSize(18)
          .fontColor(Color.White)
          .backgroundColor(Color.Red)
          .onClick(() => {
            this.onExit();
          })
      }
      .margin({ top: 30 })
    }
    .width(300)
    .padding(30)
    .backgroundColor(Color.White)
    .borderRadius(20)
    .shadow({ radius: 20, color: 0x33000000 })
  }
}