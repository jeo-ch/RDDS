import router from '@ohos.router'
import { rustDeskCore } from '../utils/RustDeskCore'
import { logger } from '@ohos.hilog'
import promptAction from '@ohos.promptAction'

const TAG: string = '[RustDesk.Remote]'

// 鼠标按键常量
const MOUSE_BUTTON_LEFT: number = 1
const MOUSE_BUTTON_MIDDLE: number = 2
const MOUSE_BUTTON_RIGHT: number = 3

@Entry
@Component
struct RemoteDesktop {
  @State isConnected: boolean = false
  @State connectionStatus: string = '正在连接...'
  @State frameCount: number = 0
  @State fps: number = 0
  private peerId: string = ''
  private lastFrameTime: number = 0
  private frameTimer: number = -1
  private captureActive: boolean = false

  aboutToAppear() {
    const params = router.getParams() as Record<string, string>
    if (params && params['peerId']) {
      this.peerId = params['peerId']
    }

    logger.info(TAG, `Remote desktop for peer: ${this.peerId}`)
    // 进入页面后立即开始帧捕获循环
    this.startCaptureLoop()
  }

  aboutToDisappear() {
    this.stopCaptureLoop()
  }

  build() {
    Column() {
      // 顶部控制栏
      Row() {
        Button('断开连接')
          .fontSize(14)
          .backgroundColor('#FF4444')
          .fontColor('#FFFFFF')
          .onClick(() => {
            this.disconnect()
          })

        Blank()

        Column() {
          Text(`连接到: ${this.peerId}`)
            .fontSize(14)
            .fontColor('#FFFFFF')
          if (this.fps > 0) {
            Text(`FPS: ${this.fps}`)
              .fontSize(11)
              .fontColor('#AAAAAA')
              .margin({ top: 2 })
          }
        }
        .alignItems(HorizontalAlign.End)
      }
      .width('100%')
      .padding(12)
      .backgroundColor('#333333')

      // 远程桌面显示区域
      Stack() {
        if (this.connectionStatus === '已连接') {
          // 真实场景下此处应该使用 XComponent 渲染视频帧。
          // 当前 NAPI 还在占位阶段，用占位文本展示连接成功状态。
          Text(`远程桌面\n帧计数: ${this.frameCount}`)
            .fontSize(20)
            .fontColor('#FFFFFF')
            .textAlign(TextAlign.Center)
        } else {
          Column() {
            LoadingProgress()
              .width(50)
              .height(50)
              .color('#007DFF')

            Text(this.connectionStatus)
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
        // 单指拖动 = 鼠标移动；抬起 = 鼠标左键点击
        PanGesture()
          .onActionUpdate((event: GestureEvent) => {
            if (event.fingerList.length > 0) {
              this.handleMouseMove(event.fingerList[0].localX, event.fingerList[0].localY)
            }
          })
          .onActionEnd((event: GestureEvent) => {
            if (event.fingerList.length > 0) {
              this.handleMouseClick(event.fingerList[0].localX, event.fingerList[0].localY, MOUSE_BUTTON_LEFT)
            }
          })
      )

      // 底部控制栏
      Row() {
        Button('键盘')
          .fontSize(12)
          .margin({ right: 8 })
          .onClick(() => {
            promptAction.showToast({ message: '键盘功能待实现', duration: 1500 })
          })

        Button('右键')
          .fontSize(12)
          .margin({ right: 8 })
          .onClick(() => {
            // 触发一次右键点击（在屏幕中心位置）
            this.handleMouseClick(640, 360, MOUSE_BUTTON_RIGHT)
          })

        Button('文件传输')
          .fontSize(12)
          .margin({ right: 8 })
          .onClick(() => {
            promptAction.showToast({ message: '文件传输待实现', duration: 1500 })
          })

        Button('断开')
          .fontSize(12)
          .backgroundColor('#FF4444')
          .fontColor('#FFFFFF')
          .onClick(() => {
            this.disconnect()
          })
      }
      .width('100%')
      .padding(12)
      .backgroundColor('#EEEEEE')
    }
    .width('100%')
    .height('100%')
  }

  /**
   * 启动帧捕获循环，用于：
   * 1. 检查连接状态
   * 2. 统计 FPS（仅占位，真实渲染应通过 XComponent）
   */
  private startCaptureLoop(): void {
    this.captureActive = true
    this.lastFrameTime = Date.now()

    const tick = () => {
      if (!this.captureActive) return

      const now = Date.now()
      const delta = now - this.lastFrameTime
      this.lastFrameTime = now

      // 更新 FPS（每秒最多更新一次显示）
      this.frameCount++
      if (delta > 0) {
        const instantFps = Math.round(1000 / delta)
        // 平滑 FPS 显示
        this.fps = this.fps === 0 ? instantFps : Math.round((this.fps + instantFps) / 2)
      }

      if (this.connectionStatus !== '已连接') {
        // 模拟连接成功（真实场景由 NAPI 回调驱动）
        rustDeskCore.getConnectionState(this.peerId).then((state: string) => {
          if (state.includes('Connected')) {
            this.connectionStatus = '已连接'
            this.isConnected = true
          }
        }).catch((e: Error) => {
          logger.error(TAG, `Failed to get connection state: ${JSON.stringify(e)}`)
        })
      }

      // 控制约 30 FPS 的轮询频率
      this.frameTimer = setTimeout(tick, 33) as unknown as number
    }
    tick()
  }

  private stopCaptureLoop(): void {
    this.captureActive = false
    if (this.frameTimer !== -1) {
      clearTimeout(this.frameTimer)
      this.frameTimer = -1
    }
  }

  async handleMouseMove(x: number, y: number) {
    try {
      await rustDeskCore.injectMouseMove(x, y)
    } catch (e) {
      logger.error(TAG, `Failed to inject mouse move: ${JSON.stringify(e)}`)
    }
  }

  async handleMouseClick(x: number, y: number, button: number) {
    try {
      // 先按下再释放，模拟完整点击动作
      await rustDeskCore.injectMouseClick(x, y, button, true)
      await new Promise(resolve => setTimeout(resolve, 50))
      await rustDeskCore.injectMouseClick(x, y, button, false)
    } catch (e) {
      logger.error(TAG, `Failed to inject mouse click: ${JSON.stringify(e)}`)
    }
  }

  async disconnect() {
    this.stopCaptureLoop()
    try {
      await rustDeskCore.disconnect()
      logger.info(TAG, 'Disconnected successfully')
    } catch (e) {
      logger.error(TAG, `Failed to disconnect: ${JSON.stringify(e)}`)
    } finally {
      router.back()
    }
  }
}
