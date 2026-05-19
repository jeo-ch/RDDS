import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { rustDeskCore } from '../utils/RustDeskCore';
import { logger } from '@ohos.hilog';

const TAG: string = '[RustDesk.Settings]';

@Entry
@Component
struct Settings {
  @State serverAddress: string = 'rustdesk.com';
  @State serverPort: number = 21116;
  @State enableDirectConnection: boolean = true;
  @State enableAudio: boolean = true;
  @State qualityLevel: number = 2; // 0=低,1=中,2=高

  async aboutToAppear() {
    logger.info(TAG, 'Settings page appearing');
    // 可以在这里加载保存的配置
  }

  build() {
    Column() {
      // 顶部栏
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
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF')

      Scroll() {
        Column() {
          // 服务器设置
          Column() {
            Text('中继服务器')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .width('100%')
              .margin({ bottom: 16 })
            
            Text('服务器地址')
              .fontSize(14)
              .fontColor('#666666')
              .width('100%')
              .margin({ bottom: 8 })
            
            TextInput({ placeholder: '服务器地址', text: this.serverAddress })
              .onChange((value: string) => {
                this.serverAddress = value;
              })
              .margin({ bottom: 16 })
            
            Text('服务器端口')
              .fontSize(14)
              .fontColor('#666666')
              .width('100%')
              .margin({ bottom: 8 })
            
            TextInput({ placeholder: '端口', text: this.serverPort.toString() })
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
              
              Toggle({ type: ToggleType.Switch, isOn: this.enableDirectConnection })
                .selectedColor('#007DFF')
                .onChange((isOn: boolean) => {
                  this.enableDirectConnection = isOn;
                })
            }
            .width('100%')
          }
          .width('100%')
          .padding(20)
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
          .margin({ bottom: 12 })

          // 视频和音频设置
          Column() {
            Text('视频和音频')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .width('100%')
              .margin({ bottom: 16 })
            
            Text('画面质量')
              .fontSize(14)
              .fontColor('#666666')
              .width('100%')
              .margin({ bottom: 8 })
            
            Row() {
              Button('低')
                .fontSize(12)
                .backgroundColor(this.qualityLevel === 0 ? '#007DFF' : '#EEEEEE')
                .fontColor(this.qualityLevel === 0 ? '#FFFFFF' : '#333333')
                .onClick(() => {
                  this.qualityLevel = 0;
                })
              
              Button('中')
                .fontSize(12)
                .margin({ left: 8, right: 8 })
                .backgroundColor(this.qualityLevel === 1 ? '#007DFF' : '#EEEEEE')
                .fontColor(this.qualityLevel === 1 ? '#FFFFFF' : '#333333')
                .onClick(() => {
                  this.qualityLevel = 1;
                })
              
              Button('高')
                .fontSize(12)
                .backgroundColor(this.qualityLevel === 2 ? '#007DFF' : '#EEEEEE')
                .fontColor(this.qualityLevel === 2 ? '#FFFFFF' : '#333333')
                .onClick(() => {
                  this.qualityLevel = 2;
                })
            }
            .width('100%')
            .margin({ bottom: 16 })
            
            Row() {
              Text('传输音频')
                .fontSize(16)
              
              Blank()
              
              Toggle({ type: ToggleType.Switch, isOn: this.enableAudio })
                .selectedColor('#007DFF')
                .onChange((isOn: boolean) => {
                  this.enableAudio = isOn;
                })
            }
            .width('100%')
          }
          .width('100%')
          .padding(20)
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
          .margin({ bottom: 12 })

          // 其他设置
          Column() {
            Text('关于')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .width('100%')
              .margin({ bottom: 16 })
            
            Row() {
              Text('版本')
                .fontSize(16)
              
              Blank()
              
              Text('1.0.0-harmony')
                .fontSize(14)
                .fontColor('#999999')
            }
            .width('100%')
            .margin({ bottom: 8 })
            
            Row() {
              Text('查看帮助')
                .fontSize(16)
                .fontColor('#007DFF')
            }
            .width('100%')
          }
          .width('100%')
          .padding(20)
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
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

  async saveSettings() {
    try {
      await rustDeskCore.setServerConfig(
        this.serverAddress, 
        this.serverPort, 
        this.enableDirectConnection
      );
      
      promptAction.showToast({
        message: '设置已保存',
        duration: 2000
      });
      
      logger.info(TAG, 'Settings saved');
    } catch (e) {
      logger.error(TAG, 'Failed to save settings: ' + JSON.stringify(e));
      promptAction.showToast({
        message: '保存失败',
        duration: 2000
      });
    }
  }
}
