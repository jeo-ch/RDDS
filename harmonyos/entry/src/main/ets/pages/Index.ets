import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { rustDeskCore } from '../utils/RustDeskCore';
import { logger } from '@ohos.hilog';

const TAG: string = '[RustDesk.Index]';

@Entry
@Component
struct Index {
  @State localId: string = 'LOADING...';
  @State remoteId: string = '';
  @State password: string = '';
  @State isConnecting: boolean = false;
  @State connectionStatus: string = '';

  async aboutToAppear() {
    logger.info(TAG, 'Index page appearing');
    
    try {
      // 初始化核心
      const appFilesPath = this.context.filesDir;
      const initSuccess = await rustDeskCore.initialize(appFilesPath);
      
      if (initSuccess) {
        // 加载本地ID
        this.localId = await rustDeskCore.getLocalId();
        logger.info(TAG, 'Local ID loaded: ' + this.localId);
      } else {
        this.localId = 'INIT_FAILED';
        promptAction.showToast({
          message: '初始化失败',
          duration: 2000
        });
      }
    } catch (error) {
      logger.error(TAG, 'Failed to initialize: ' + JSON.stringify(error));
      this.localId = 'ERROR';
    }
  }

  build() {
    Column() {
      // 标题
      Text('RustDesk')
        .fontSize(32)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 40, bottom: 20 })

      // 本地ID展示区
      Column() {
        Text('您的ID')
          .fontSize(16)
          .fontColor('#666666')
          .margin({ bottom: 8 })
          .width('100%')
        
        Text(this.localId)
          .fontSize(28)
          .fontWeight(FontWeight.Medium)
          .margin({ bottom: 16 })
          .copyOption({ copyOption: CopyOptions.Inside })
        
        Row() {
          Button('复制ID')
            .fontSize(14)
            .onClick(() => {
              // 复制到剪贴板
              promptAction.showToast({
                message: 'ID已复制',
                duration: 1500
              });
            })
        }
      }
      .width('90%')
      .padding(20)
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .margin({ bottom: 20 })

      // 连接区
      Column() {
        Text('远程ID')
          .fontSize(16)
          .fontColor('#666666')
          .width('100%')
          .margin({ bottom: 8 })
        
        TextInput({ placeholder: '输入远程设备ID', text: this.remoteId })
          .onChange((value: string) => {
            this.remoteId = value;
          })
          .margin({ bottom: 12 })
        
        Text('密码(可选)')
          .fontSize(16)
          .fontColor('#666666')
          .width('100%')
          .margin({ bottom: 8 })
        
        TextInput({ placeholder: '输入密码', text: this.password })
          .type(InputType.Password)
          .onChange((value: string) => {
            this.password = value;
          })
          .margin({ bottom: 20 })
        
        Button(this.isConnecting ? '连接中...' : '连接')
          .width('100%')
          .height(48)
          .enabled(!this.isConnecting)
          .backgroundColor('#007DFF')
          .onClick(() => {
            this.connectToPeer();
          })
        
        if (this.connectionStatus) {
          Text(this.connectionStatus)
            .fontSize(14)
            .fontColor(this.connectionStatus.includes('失败') || this.connectionStatus.includes('错误') ? '#FF4444' : '#00AA00')
            .margin({ top: 12 })
        }
      }
      .width('90%')
      .padding(20)
      .backgroundColor('#FFFFFF')
      .borderRadius(12)

      Blank()

      // 底部控制栏
      Row() {
        Button('设置')
          .fontSize(14)
          .backgroundColor('transparent')
          .fontColor('#666666')
          .onClick(() => {
            router.pushUrl({ url: 'pages/Settings' });
          })
        
        Blank()
        
        Text('版本: 1.0.0-harmony')
          .fontSize(12)
          .fontColor('#999999')
      }
      .width('90%')
      .height(50)
      .margin({ bottom: 20 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  async connectToPeer() {
    if (!this.remoteId.trim()) {
      promptAction.showToast({
        message: '请输入远程ID',
        duration: 2000
      });
      return;
    }

    this.isConnecting = true;
    this.connectionStatus = '正在连接到 ' + this.remoteId + '...';

    try {
      const success = await rustDeskCore.connectToPeer(this.remoteId, this.password);
      
      if (success) {
        this.connectionStatus = '连接成功!';
        
        // 延迟跳转，让用户看到成功提示
        setTimeout(() => {
          router.pushUrl({
            url: 'pages/RemoteDesktop',
            params: { peerId: this.remoteId }
          });
          this.connectionStatus = '';
          this.isConnecting = false;
        }, 1000);
      } else {
        this.connectionStatus = '连接失败，请检查网络';
        this.isConnecting = false;
      }
    } catch (error) {
      this.connectionStatus = '连接错误: ' + JSON.stringify(error);
      logger.error(TAG, 'Connection error: ' + JSON.stringify(error));
      this.isConnecting = false;
    }
  }
}
