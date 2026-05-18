@Entry
@Component
struct Index {
  @State localId: string = '';
  @State remoteId: string = '';
  @State isConnecting: boolean = false;
  @State connectionStatus: string = '';
  
  build() {
    Column() {
      Text('RustDesk')
        .fontSize(30)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 40, bottom: 20 })
      
      // 本地ID显示
      Column() {
        Text('您的ID')
          .fontSize(16)
          .fontColor('#666666')
          .margin({ bottom: 8 })
        
        Text(this.localId)
          .fontSize(24)
          .fontWeight(FontWeight.Medium)
          .margin({ bottom: 4 })
      }
      .width('90%')
      .padding(20)
      .backgroundColor('#F5F5F5')
      .borderRadius(12)
      .margin({ bottom: 20 })
      
      // 远程ID输入
      Column() {
        Text('远程ID')
          .fontSize(16)
          .fontColor('#666666')
          .width('100%')
          .margin({ bottom: 8 })
        
        TextInput({ placeholder: '输入远程设备ID' })
          .onChange((value: string) => {
            this.remoteId = value;
          })
          .margin({ bottom: 12 })
        
        Text('密码 (可选)')
          .fontSize(16)
          .fontColor('#666666')
          .width('100%')
          .margin({ bottom: 8 })
        
        TextInput({ placeholder: '输入密码' })
          .type(InputType.Password)
        
        Button(this.isConnecting ? '连接中...' : '连接')
          .width('100%')
          .height(48)
          .margin({ top: 20 })
          .enabled(!this.isConnecting)
          .onClick(() => {
            this.connectToPeer();
          })
        
        if (this.connectionStatus) {
          Text(this.connectionStatus)
            .fontSize(14)
            .fontColor(this.connectionStatus.includes('失败') ? '#FF0000' : '#00AA00')
            .margin({ top: 12 })
        }
      }
      .width('90%')
      .padding(20)
      .backgroundColor('#FFFFFF')
      .border({ width: 1, color: '#E0E0E0' })
      .borderRadius(12)
      
      Blank()
      
      // 设置按钮
      Row() {
        Button('设置')
          .fontSize(14)
          .backgroundColor('transparent')
          .fontColor('#666666')
          .onClick(() => {
            router.pushUrl({ url: 'pages/Settings' });
          })
      }
      .margin({ bottom: 20 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FAFAFA')
    .onAppear(() => {
      this.loadLocalId();
    })
  }
  
  loadLocalId() {
    try {
      const rustCore = requireNapi('rustdesk_core');
      this.localId = rustCore.getLocalId();
    } catch (e) {
      this.localId = '加载失败';
    }
  }
  
  async connectToPeer() {
    if (!this.remoteId) {
      this.connectionStatus = '请输入远程ID';
      return;
    }
    
    this.isConnecting = true;
    this.connectionStatus = '正在连接...';
    
    try {
      const rustCore = requireNapi('rustdesk_core');
      const success = await rustCore.connectToPeer(this.remoteId, '');
      
      if (success) {
        this.connectionStatus = '连接成功!';
        router.pushUrl({
          url: 'pages/RemoteDesktop',
          params: { peerId: this.remoteId }
        });
      } else {
        this.connectionStatus = '连接失败，请检查网络';
      }
    } catch (e) {
      this.connectionStatus = '连接出错: ' + JSON.stringify(e);
    } finally {
      this.isConnecting = false;
    }
  }
}
