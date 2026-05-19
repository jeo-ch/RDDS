import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { rustDeskCore } from '../utils/RustDeskCore';
import { logger } from '@ohos.hilog';

const TAG: string = '[RustDesk.Remote]';

@Entry
@Component
struct RemoteDesktop {
  @State isConnected: boolean = true;
  @State showKeyboard: boolean = false;
  @State isMouseDown: boolean = false;
  private peerId: string = '';
  private lastMouseX: number = 0;
  private lastMouseY: number = 0;

  aboutToAppear() {
    const params = router.getParams() as Record<string, string>;
    if (params && params['peerId']) {
      this.peerId = params['peerId'];
      logger.info(TAG, 'Remote desktop for peer: ' + this.peerId);
    }
  }

  build() {
    Column() {
      // 顶部控制栏
      Row() {
        Button('断开')
          .fontSize(14)
          .backgroundColor('#FF4444')
          .onClick(() => {
            this.disconnect();
          })
        
        Blank()
        
        Text(this.peerId)
          .fontSize(14)
          .fontColor('#FFFFFF')
        
        Blank()
        
        Button('隐藏')
          .fontSize(14)
          .backgroundColor('#666666')
          .onClick(() => {
            promptAction.showToast({
              message: '已隐藏控制栏',
              duration: 1500
            });
          })
      }
      .width('100%')
      .height(50)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#333333')

      // 远程桌面显示区域
      Stack() {
        Column() {
          if (this.isConnected) {
            Text('远程桌面画面\n\n连接到: ' + this.peerId)
              .fontSize(18)
              .textAlign(TextAlign.Center)
              .fontColor('#CCCCCC')
          } else {
            Column() {
              LoadingProgress()
                .width(50)
                .height(50)
                .color('#007DFF')
              
              Text('正在连接...')
                .fontSize(16)
                .fontColor('#666666')
                .margin({ top: 20 })
            }
          }
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor('#000000')
      .gesture(
        // 鼠标/触摸事件处理
        GestureGroup(GestureMode.Exclusive, [
          PanGesture()
            .onActionUpdate((event: GestureEvent) => {
              if (event.fingerList && event.fingerList.length > 0) {
                this.handleMouseMove(
                  event.fingerList[0].localX, 
                  event.fingerList[0].localY
                );
              }
            })
            .onActionEnd((event: GestureEvent) => {
              if (event.fingerList && event.fingerList.length > 0) {
                if (this.isMouseDown) {
                  // 释放鼠标
                  this.handleMouseClick(
                    event.fingerList[0].localX, 
                    event.fingerList[0].localY,
                    1, // 左键
                    false
                  );
                } else {
                  // 点击
                  this.handleMouseClick(
                    event.fingerList[0].localX, 
                    event.fingerList[0].localY,
                    1, // 左键
                    true
                  );
                  setTimeout(() => {
                    this.handleMouseClick(
                      event.fingerList[0].localX, 
                      event.fingerList[0].localY,
                      1, // 左键
                      false
                    );
                  }, 50);
                }
              }
            })
        ])
      )

      // 底部控制栏
      Row() {
        Button('键盘')
          .fontSize(12)
          .margin({ right: 8 })
          .onClick(() => {
            this.showKeyboard = !this.showKeyboard;
            if (this.showKeyboard) {
              promptAction.showToast({
                message: '键盘功能演示',
                duration: 1500
              });
            }
          })
        
        Button('文件')
          .fontSize(12)
          .margin({ right: 8 })
          .onClick(() => {
            promptAction.showToast({
              message: '文件传输功能',
              duration: 1500
            });
          })
        
        Button('聊天')
          .fontSize(12)
          .margin({ right: 8 })
          .onClick(() => {
            promptAction.showToast({
              message: '聊天功能',
              duration: 1500
            });
          })
        
        Button('设置')
          .fontSize(12)
          .onClick(() => {
            router.pushUrl({ url: 'pages/Settings' });
          })
      }
      .width('100%')
      .height(50)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#EEEEEE')
    }
    .width('100%')
    .height('100%')
  }

  async handleMouseMove(x: number, y: number) {
    this.lastMouseX = x;
    this.lastMouseY = y;
    try {
      await rustDeskCore.injectMouseMove(x, y);
    } catch (e) {
      logger.error(TAG, 'Failed to inject mouse move: ' + JSON.stringify(e));
    }
  }

  async handleMouseClick(x: number, y: number, button: number, down: boolean) {
    this.isMouseDown = down;
    try {
      await rustDeskCore.injectMouseClick(x, y, button, down);
    } catch (e) {
      logger.error(TAG, 'Failed to inject mouse click: ' + JSON.stringify(e));
    }
  }

  async disconnect() {
    try {
      await rustDeskCore.disconnectPeer(this.peerId);
      logger.info(TAG, 'Disconnected from peer: ' + this.peerId);
      router.back();
    } catch (e) {
      logger.error(TAG, 'Failed to disconnect: ' + JSON.stringify(e));
      router.back();
    }
  }
}
