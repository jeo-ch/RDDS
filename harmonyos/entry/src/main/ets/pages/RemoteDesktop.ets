@Entry
@Component
struct RemoteDesktop {
  @State remoteStream: any = null;
  @State isConnected: boolean = false;
  private peerId: string = '';
  private scroller: Scroller = new Scroller();
  
  aboutToAppear() {
    const params = router.getParams() as Record<string, string>;
    if (params && params['peerId']) {
      this.peerId = params['peerId'];
    }
  }
  
  build() {
    Column() {
      // 顶部控制栏
      Row() {
        Button('断开连接')
          .fontSize(14)
          .backgroundColor('#FF4444')
          .onClick(() => {
            this.disconnect();
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
          VideoSurface()
            .width('100%')
            .height('100%')
            .objectFit(ImageFit.Contain)
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
      .gesture(
        PanGesture()
          .onActionUpdate((event: GestureEvent) => {
            this.handleMouseMove(event.fingerList[0].localX, event.fingerList[0].localY);
          })
          .onActionEnd((event: GestureEvent) => {
            this.handleMouseClick(event.fingerList[0].localX, event.fingerList[0].localY);
          })
      )
      
      // 底部控制栏
      Row() {
        Button('键盘')
          .fontSize(12)
          .margin({ right: 8 })
          .onClick(() => {
            this.showKeyboard();
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
  
  handleMouseMove(x: number, y: number) {
    try {
      const rustCore = requireNapi('rustdesk_core');
      rustCore.injectMouseMove(x, y);
    } catch (e) {
      console.error('Failed to inject mouse move: ' + e);
    }
  }
  
  handleMouseClick(x: number, y: number) {
    try {
      const rustCore = requireNapi('rustdesk_core');
      rustCore.injectMouseClick(x, y, 1); // 1 = left button
    } catch (e) {
      console.error('Failed to inject mouse click: ' + e);
    }
  }
  
  disconnect() {
    try {
      const rustCore = requireNapi('rustdesk_core');
      rustCore.disconnect();
      router.back();
    } catch (e) {
      console.error('Failed to disconnect: ' + e);
      router.back();
    }
  }
  
  showKeyboard() {
    // 显示键盘界面
  }
}
