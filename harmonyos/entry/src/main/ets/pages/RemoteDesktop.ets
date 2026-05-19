import router from '@ohos.router'
import { rustDeskCore } from '../utils/RustDeskCore'
import { logger } from '@ohos.hilog'

const TAG: string = '[RustDesk.Remote]'

@Entry
@Component
struct RemoteDesktop {
  @State remoteStream: any = null
  @State isConnected: boolean = false
  @State showKeyboard: boolean = false
  private peerId: string = ''
  private scroller: Scroller = new Scroller()

  aboutToAppear() {
    const params = router.getParams() as Record<string, string>
    if (params && params['peerId']) {
      this.peerId = params['peerId']
    }
    
    logger.info(TAG, `Remote desktop for peer: ${this.peerId}`)
  }

  build() {
    Column() {
      // 顶部控制栏
      Row() {
        Button('断开连接')
          .fontSize(14)
          .backgroundColor('#FF4444')
          .onClick(() => {
            this.disconnect()
          })

        Blank()

        Text('连接到: ' + this.peerId)
          .fontSize(14)
          .fontColor('#FFFFFF')
      }
      .width('100%')
      .padding(12)
      .backgroundColor('#333333')

      // 远程桌面显示区域
      Stack() {
        if (this.remoteStream) {
          // 视频表面组件
          Text('远程桌面显示')
            .fontSize(20)
            .width('100%')
            .height('100%')
            .textAlign(TextAlign.Center)
        } else {
          Column() {
            LoadingProgress()
              .width(50)
              .height(50)
              .color('#007DFF')

            Text('等待画面...')
              .fontSize(16)
              .fontColor('#666666')
              .margin({ top: 20 })
          }
        }
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor('#000000')
      .gesture(
        PanGesture()
          .onActionUpdate((event: GestureEvent) => {
            this.handleMouseMove(event.fingerList[0].localX, event.fingerList[0].localY)
          })
          .onActionEnd((event: GestureEvent) => {
            this.handleMouseClick(event.fingerList[0].localX, event.fingerList[0].localY)
          })
      )

      // 底部控制栏
      Row() {
        Button('键盘')
          .fontSize(12)
          .margin({ right: 8 })
          .onClick(() => {
            this.showKeyboard = !this.showKeyboard
          })

        Button('文件传输')
          .fontSize(12)
          .margin({ right: 8 })

        Button('聊天')
          .fontSize(12)
          .margin({ right: 8 })

        Button('设置')
          .fontSize(12)
      }
      .width('100%')
      .padding(12)
      .backgroundColor('#EEEEEE')
    }
    .width('100%')
    .height('100%')
  }

  async handleMouseMove(x: number, y: number) {
    try {
      await rustDeskCore.injectMouseMove(x, y)
    } catch (e) {
      logger.error(TAG, `Failed to inject mouse move: ${JSON.stringify(e)}`)
    }
  }

  async handleMouseClick(x: number, y: number) {
    try {
      // 先按下再释放
      await rustDeskCore.injectMouseClick(x, y, 1, true)
      await new Promise(resolve => setTimeout(resolve, 50))
      await rustDeskCore.injectMouseClick(x, y, 1, false)
    } catch (e) {
      logger.error(TAG, `Failed to inject mouse click: ${JSON.stringify(e)}`)
    }
  }

  async disconnect() {
    try {
      await rustDeskCore.disconnect()
      router.back()
    } catch (e) {
      logger.error(TAG, `Failed to disconnect: ${JSON.stringify(e)}`)
      router.back()
    }
  }
}
