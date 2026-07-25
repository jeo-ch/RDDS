import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { logger } from '@ohos.hilog';
import { rustDeskCore, ServerConfig } from '../utils/RustDeskCore';

const TAG: string = '[RustDesk.Settings]';

// Option key 常量（与 libs/hbb_common/src/config.rs 中 keys 模块保持一致）
const OPT_VERIFICATION_METHOD: string = 'verification-method';
const OPT_APPROVE_MODE: string = 'approve-mode';
const OPT_TEMPORARY_PASSWORD_LENGTH: string = 'temporary-password-length';

@Entry
@Component
struct Settings {
  // ===== 服务器设置 =====
  @State rendezvousServer: string = '';
  @State apiServer: string = '';
  @State relayServer: string = '';
  @State key: string = '';

  // ===== 密码策略 =====
  @State verificationMethod: string = 'use-both-passwords';
  @State approveMode: string = 'password-click';
  @State temporaryPasswordLength: string = '6';
  @State permanentPassword: string = '';

  // ===== Socks5 代理 =====
  @State socksProxy: string = '';
  @State socksUsername: string = '';
  @State socksPassword: string = '';

  // ===== 通用 =====
  @State saving: boolean = false;

  async aboutToAppear() {
    await this.loadSettings();
  }

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

        Button(this.saving ? '保存中...' : '保存')
          .fontSize(16)
          .backgroundColor('transparent')
          .fontColor('#007DFF')
          .enabled(!this.saving)
          .onClick(() => {
            this.saveAll();
          })
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#FFFFFF')

      Scroll() {
        Column() {
          // ===== 服务器设置 =====
          this.buildServerSection()

          // ===== 密码策略 =====
          this.buildPasswordSection()

          // ===== Socks5 代理 =====
          this.buildSocksSection()

          // ===== 关于 =====
          this.buildAboutSection()
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

  @Builder
  buildServerSection() {
    Column() {
      Text('服务器设置')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ bottom: 16 })

      Column({ space: 12 }) {
        Text('ID 服务器 (rendezvous)')
          .fontSize(14)
          .fontColor('#666666')
          .width('100%')
        TextInput({ text: this.rendezvousServer, placeholder: 'host[:port]，端口缺省 21116' })
          .onChange((value: string) => { this.rendezvousServer = value; })
          .width('100%')

        Text('API 服务器')
          .fontSize(14)
          .fontColor('#666666')
          .width('100%')
        TextInput({ text: this.apiServer, placeholder: 'https://api.example.com' })
          .onChange((value: string) => { this.apiServer = value; })
          .width('100%')

        Text('中继服务器 (relay)')
          .fontSize(14)
          .fontColor('#666666')
          .width('100%')
        TextInput({ text: this.relayServer, placeholder: 'host[:port]，端口缺省 21117' })
          .onChange((value: string) => { this.relayServer = value; })
          .width('100%')

        Text('Key')
          .fontSize(14)
          .fontColor('#666666')
          .width('100%')
        TextInput({ text: this.key, placeholder: '服务器公钥 (base64)' })
          .onChange((value: string) => { this.key = value; })
          .width('100%')
      }
      .width('100%')
    }
    .width('100%')
    .padding(20)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ bottom: 12 })
  }

  @Builder
  buildPasswordSection() {
    Column() {
      Text('安全设置')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ bottom: 16 })

      Column({ space: 12 }) {
        Row() {
          Text('验证方式')
            .fontSize(14)
          Blank()
          Select([
            { value: '仅临时密码' },
            { value: '仅固定密码' },
            { value: '两者皆可' }
          ])
            .selected(this.verificationMethodIndex())
            .value(this.verificationMethodLabel())
            .onSelect((index: number) => {
              this.verificationMethod = this.verificationMethodFromIndex(index);
            })
        }
        .width('100%')

        Row() {
          Text('批准方式')
            .fontSize(14)
          Blank()
          Select([
            { value: '密码' },
            { value: '点击' },
            { value: '密码或点击' }
          ])
            .selected(this.approveModeIndex())
            .value(this.approveModeLabel())
            .onSelect((index: number) => {
              this.approveMode = this.approveModeFromIndex(index);
            })
        }
        .width('100%')

        Row() {
          Text('临时密码长度')
            .fontSize(14)
          Blank()
          Select([
            { value: '6 位' },
            { value: '8 位' },
            { value: '10 位' }
          ])
            .selected(this.tempPwdLenIndex())
            .value(this.tempPwdLenLabel())
            .onSelect((index: number) => {
              this.temporaryPasswordLength = ['6', '8', '10'][index];
            })
        }
        .width('100%')

        Text('固定密码')
          .fontSize(14)
          .fontColor('#666666')
          .width('100%')
        TextInput({ text: this.permanentPassword, placeholder: '设置固定密码（留空则清除）' })
          .type(InputType.Password)
          .onChange((value: string) => { this.permanentPassword = value; })
          .width('100%')
      }
      .width('100%')
    }
    .width('100%')
    .padding(20)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ bottom: 12 })
  }

  @Builder
  buildSocksSection() {
    Column() {
      Text('Socks5 代理')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ bottom: 16 })

      Column({ space: 12 }) {
        Text('代理地址')
          .fontSize(14)
          .fontColor('#666666')
          .width('100%')
        TextInput({ text: this.socksProxy, placeholder: 'socks5://host:port（留空则清除代理）' })
          .onChange((value: string) => { this.socksProxy = value; })
          .width('100%')

        Text('用户名')
          .fontSize(14)
          .fontColor('#666666')
          .width('100%')
        TextInput({ text: this.socksUsername, placeholder: '可选' })
          .onChange((value: string) => { this.socksUsername = value; })
          .width('100%')

        Text('密码')
          .fontSize(14)
          .fontColor('#666666')
          .width('100%')
        TextInput({ text: this.socksPassword, placeholder: '可选' })
          .type(InputType.Password)
          .onChange((value: string) => { this.socksPassword = value; })
          .width('100%')
      }
      .width('100%')
    }
    .width('100%')
    .padding(20)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ bottom: 12 })
  }

  @Builder
  buildAboutSection() {
    Column() {
      Text('关于')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ bottom: 16 })

      Row() {
        Text('版本')
          .fontSize(14)
        Blank()
        Text('RustDesk v1.4.6-harmony')
          .fontSize(14)
          .fontColor('#666666')
      }
      .width('100%')
    }
    .width('100%')
    .padding(20)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ bottom: 12 })
  }

  // ===== Select 索引与 option 字符串的转换 =====
  private verificationMethodIndex(): number {
    switch (this.verificationMethod) {
      case 'use-temporary-password': return 0;
      case 'use-permanent-password': return 1;
      default: return 2;
    }
  }
  private verificationMethodLabel(): string {
    switch (this.verificationMethod) {
      case 'use-temporary-password': return '仅临时密码';
      case 'use-permanent-password': return '仅固定密码';
      default: return '两者皆可';
    }
  }
  private verificationMethodFromIndex(index: number): string {
    return ['use-temporary-password', 'use-permanent-password', 'use-both-passwords'][index];
  }

  private approveModeIndex(): number {
    switch (this.approveMode) {
      case 'password': return 0;
      case 'click': return 1;
      default: return 2;
    }
  }
  private approveModeLabel(): string {
    switch (this.approveMode) {
      case 'password': return '密码';
      case 'click': return '点击';
      default: return '密码或点击';
    }
  }
  private approveModeFromIndex(index: number): string {
    return ['password', 'click', 'password-click'][index];
  }

  private tempPwdLenIndex(): number {
    return ['6', '8', '10'].indexOf(this.temporaryPasswordLength);
  }
  private tempPwdLenLabel(): string {
    const idx = this.tempPwdLenIndex();
    return idx >= 0 ? `${['6', '8', '10'][idx]} 位` : '6 位';
  }

  // ===== 加载与保存 =====
  private async loadSettings() {
    try {
      this.rendezvousServer = await rustDeskCore.getOption('custom-rendezvous-server');
      this.apiServer = await rustDeskCore.getOption('api-server');
      this.relayServer = await rustDeskCore.getOption('relay-server');
      this.key = await rustDeskCore.getOption('key');

      const vMethod = await rustDeskCore.getOption(OPT_VERIFICATION_METHOD);
      if (vMethod) this.verificationMethod = vMethod;
      const aMode = await rustDeskCore.getOption(OPT_APPROVE_MODE);
      if (aMode) this.approveMode = aMode;
      const tLen = await rustDeskCore.getOption(OPT_TEMPORARY_PASSWORD_LENGTH);
      if (tLen) this.temporaryPasswordLength = tLen;

      logger.info(TAG, 'Settings loaded');
    } catch (e) {
      logger.error(TAG, 'Failed to load settings: ' + JSON.stringify(e));
    }
  }

  private async saveAll() {
    this.saving = true;
    try {
      // 1. 服务器配置（一次性写入 4 项）
      const cfg: ServerConfig = {
        rendezvousServer: this.rendezvousServer.trim(),
        apiServer: this.apiServer.trim(),
        relayServer: this.relayServer.trim(),
        key: this.key.trim()
      };
      await rustDeskCore.setServerConfig(cfg);

      // 2. 密码策略
      await rustDeskCore.setOption(OPT_VERIFICATION_METHOD, this.verificationMethod);
      await rustDeskCore.setOption(OPT_APPROVE_MODE, this.approveMode);
      await rustDeskCore.setOption(OPT_TEMPORARY_PASSWORD_LENGTH, this.temporaryPasswordLength);

      // 3. 固定密码（只在用户填了时设置；留空表示不清除）
      const pwd = this.permanentPassword;
      if (pwd.length > 0) {
        const ok = await rustDeskCore.setPermanentPassword(pwd);
        if (!ok) {
          promptAction.showToast({ message: '固定密码设置被拒绝', duration: 2000 });
        } else {
          this.permanentPassword = '';
        }
      }

      // 4. Socks5 代理
      await rustDeskCore.setSocks(
        this.socksProxy.trim(),
        this.socksUsername,
        this.socksPassword
      );

      promptAction.showToast({ message: '设置已保存', duration: 2000 });
      logger.info(TAG, 'Settings saved successfully');
    } catch (e) {
      logger.error(TAG, 'Failed to save settings: ' + JSON.stringify(e));
      promptAction.showToast({ message: '保存失败', duration: 2000 });
    } finally {
      this.saving = false;
    }
  }
}
