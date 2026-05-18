@Entry
@Component
struct Settings {
  @State serverAddress: string = 'rustdesk.com';
  @State serverPort: number = 21116;
  @State enableDirectAccess: boolean = true;
  @State autoStart: boolean = true;
  
  build() {
    Column() {
      // 标题栏
      Row() {
        Button('< 返回')
          .fontSize(16)
          .backgroundColor('transparent')
          .fontColor('#007DFF')
          .onClick(() => {
            router.back();
          })
        
        Blank()
        
        Text('设置')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
        
        Blank()
        
        Button('保存')
          .fontSize(16)
          .backgroundColor('transparent')
          .fontColor('#007DFF')
          .onClick(() => {
            this.saveSettings();
          })
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#FFFFFF')
      
      Scroll() {
        Column() {
          // 服务器设置
          Column() {
            Text('服务器设置')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .width('100%')
              .margin({ bottom: 16 })
            
            TextInput({ text: this.serverAddress, placeholder: '服务器地址' })
              .onChange((value: string) => {
                this.serverAddress = value;
              })
              .margin({ bottom: 12 })
            
            TextInput({ text: this.serverPort.toString(), placeholder: '端口' })
              .type(InputType.Number)
              .onChange((value: string) => {
                const port = parseInt(value);
                if (!isNaN(port)) {
                  this.serverPort = port;
                }
              })
              .margin({ bottom: 16 })
            
            Row() {
              Text('直连模式')
                .fontSize(16)
              
              Blank()
              
              Toggle({ type: ToggleType.Switch, isOn: this.enableDirectAccess })
                .onChange((isOn: boolean) => {
                  this.enableDirectAccess = isOn;
                })
            }
            .width('100%')
          }
          .width('100%')
          .padding(20)
          .backgroundColor('#FFFFFF')
          .margin({ bottom: 12 })
          
          // 其他设置
          Column() {
            Text('通用设置')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .width('100%')
              .margin({ bottom: 16 })
            
            Row() {
              Text('开机自启')
                .fontSize(16)
              
              Blank()
              
              Toggle({ type: ToggleType.Switch, isOn: this.autoStart })
                .onChange((isOn: boolean) => {
                  this.autoStart = isOn;
                })
            }
            .width('100%')
            .margin({ bottom: 16 })
            
            Row() {
              Text('语言')
                .fontSize(16)
              
              Blank()
              
              Text('中文')
                .fontSize(16)
                .fontColor('#666666')
            }
            .width('100%')
            .margin({ bottom: 16 })
            
            Row() {
              Text('关于')
                .fontSize(16)
              
              Blank()
              
              Text('RustDesk v1.4.6')
                .fontSize(16)
                .fontColor('#666666')
            }
            .width('100%')
          }
          .width('100%')
          .padding(20)
          .backgroundColor('#FFFFFF')
          .margin({ bottom: 12 })
        }
        .width('100%')
        .padding(12)
      }
      .layoutWeight(1)
      .backgroundColor('#F5F5F5')
    }
    .width('100%')
    .height('100%')
  }
  
  saveSettings() {
    try {
      const rustCore = requireNapi('rustdesk_core');
      rustCore.setServerConfig(this.serverAddress, this.serverPort, this.enableDirectAccess);
      
      promptAction.showToast({
        message: '设置已保存',
        duration: 2000
      });
    } catch (e) {
      console.error('Failed to save settings: ' + e);
    }
  }
}
