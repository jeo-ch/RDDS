import { logger } from '@ohos.hilog';

const TAG: string = '[RustDesk.Native]';

// 权限状态
export enum ConnectionState {
  Disconnected = 0,
  Connecting = 1,
  Connected = 2,
  Error = 3
}

/**
 * 远程桌面会话
 */
export interface RemoteSession {
  id: string;
  peerId: string;
  state: ConnectionState;
  connectedAt: number;
}

/**
 * RustDesk 服务器配置（对应主项目 options）。
 * 写入后会自动持久化到 RustDesk2.toml，
 * RendezvousMediator 启动连接时会自动读取应用。
 */
export interface ServerConfig {
  /** 自定义 rendezvous server，host[:port]，端口缺省 21116 */
  rendezvousServer: string;
  /** API 服务器 URL，如 https://api.example.com */
  apiServer: string;
  /** 自定义 relay server，host[:port]，端口缺省 21117 */
  relayServer: string;
  /** rendezvous server 的公钥（base64），用于 secure_tcp 握手 */
  key: string;
}

/**
 * RustDesk Core Interface
 */
export interface IRustDeskCore {
  initialize(appDir: string): Promise<boolean>;
  getLocalId(): Promise<string>;
  connectToPeer(peerId: string, password: string): Promise<boolean>;
  disconnect(): Promise<void>;
  disconnectPeer(peerId: string): Promise<void>;
  getConnectionState(peerId: string): Promise<string>;
  /** 一次性写入四项服务器配置 */
  setServerConfig(config: ServerConfig): Promise<void>;
  /** 通用 option 写入（verification-method / approve-mode / temporary-password-length 等） */
  setOption(key: string, value: string): Promise<void>;
  /** 通用 option 读取 */
  getOption(key: string): Promise<string>;
  /** 设置固定密码，返回 false 表示被锁定或新旧值相同 */
  setPermanentPassword(password: string): Promise<boolean>;
  /** 设置 Socks5 代理，proxy 为空表示清除 */
  setSocks(proxy: string, username: string, password: string): Promise<void>;
  injectMouseMove(x: number, y: number): Promise<void>;
  injectMouseClick(x: number, y: number, button: number, down: boolean): Promise<void>;
  injectKey(keyCode: number, down: boolean): Promise<void>;
  captureScreenFrame(): Promise<Uint8Array | null>;
  getVersion(): Promise<string>;
  isNativeAvailable(): boolean;
}

/**
 * RustDesk Core Implementation
 *
 * 优先尝试加载 native NAPI 模块 `rustdesk_napi`；若加载失败，
 * 自动降级到 mock 实现，保证 UI 仍可在模拟器或未编译 native 时运行。
 */
export class RustDeskCore implements IRustDeskCore {
  private static instance: RustDeskCore;
  private isInitialized: boolean = false;
  private nativeModule: any = null;
  private nativeAvailable: boolean = false;

  public static getInstance(): RustDeskCore {
    if (!RustDeskCore.instance) {
      RustDeskCore.instance = new RustDeskCore();
    }
    return RustDeskCore.instance;
  }

  private constructor() {
    this.tryLoadNative();
  }

  /**
   * 尝试加载 native NAPI 模块，失败时降级到 mock。
   */
  private tryLoadNative(): void {
    try {
      // 鸿蒙 NAPI 模块名必须与 CMakeLists.txt 中 nm_modname 一致
      this.nativeModule = requireNapi('rustdesk_napi');
      if (this.nativeModule && typeof this.nativeModule === 'object') {
        this.nativeAvailable = true;
        logger.info(TAG, 'Native NAPI module loaded successfully');
      } else {
        this.nativeModule = null;
        this.nativeAvailable = false;
        logger.warn(TAG, 'NAPI module returned empty, using mock implementation');
      }
    } catch (e) {
      this.nativeModule = null;
      this.nativeAvailable = false;
      logger.warn(TAG, 'Failed to load NAPI module, using mock implementation: ' + JSON.stringify(e));
    }
  }

  isNativeAvailable(): boolean {
    return this.nativeAvailable;
  }

  async initialize(appDir: string): Promise<boolean> {
    if (this.isInitialized) {
      return true;
    }

    try {
      logger.info(TAG, 'Initializing RustDesk core at: ' + appDir);

      if (this.nativeModule && this.nativeModule.initialize) {
        const result = await this.nativeModule.initialize(appDir);
        this.isInitialized = !!result;
        return this.isInitialized;
      } else {
        // Mock 初始化
        this.isInitialized = true;
        return true;
      }
    } catch (e) {
      logger.error(TAG, 'Failed to initialize core: ' + JSON.stringify(e));
      return false;
    }
  }

  async getLocalId(): Promise<string> {
    if (!this.isInitialized) {
      return 'NOT_INITIALIZED';
    }

    try {
      if (this.nativeModule && this.nativeModule.getLocalId) {
        return await this.nativeModule.getLocalId();
      } else {
        // Mock ID
        return 'TEST' + Math.floor(Math.random() * 1000000);
      }
    } catch (e) {
      logger.error(TAG, 'Failed to get local ID: ' + JSON.stringify(e));
      return 'ERROR';
    }
  }

  async connectToPeer(peerId: string, password: string): Promise<boolean> {
    if (!this.isInitialized) {
      logger.warn(TAG, 'Core not initialized');
      return false;
    }

    try {
      if (this.nativeModule && this.nativeModule.connectToPeer) {
        return await this.nativeModule.connectToPeer(peerId, password);
      } else {
        // Mock 连接
        await new Promise(resolve => setTimeout(resolve, 1500));
        return true;
      }
    } catch (e) {
      logger.error(TAG, 'Failed to connect: ' + JSON.stringify(e));
      return false;
    }
  }

  async disconnect(): Promise<void> {
    try {
      if (this.nativeModule && this.nativeModule.disconnect) {
        await this.nativeModule.disconnect();
      }
    } catch (e) {
      logger.error(TAG, 'Failed to disconnect: ' + JSON.stringify(e));
    }
  }

  async disconnectPeer(peerId: string): Promise<void> {
    try {
      if (this.nativeModule && this.nativeModule.disconnectPeer) {
        await this.nativeModule.disconnectPeer(peerId);
      } else {
        // Mock 断开
        await this.disconnect();
      }
    } catch (e) {
      logger.error(TAG, 'Failed to disconnect peer: ' + JSON.stringify(e));
    }
  }

  async getConnectionState(peerId: string): Promise<string> {
    try {
      if (this.nativeModule && this.nativeModule.getConnectionState) {
        return await this.nativeModule.getConnectionState(peerId);
      } else {
        return 'Disconnected';
      }
    } catch (e) {
      logger.error(TAG, 'Failed to get connection state: ' + JSON.stringify(e));
      return 'Error';
    }
  }

  async setServerConfig(config: ServerConfig): Promise<void> {
    try {
      if (this.nativeModule && this.nativeModule.setServerConfig) {
        await this.nativeModule.setServerConfig(
          config.rendezvousServer,
          config.apiServer,
          config.relayServer,
          config.key
        );
      } else {
        // Mock 保存配置
        logger.info(TAG, `Server config updated: rendezvous=${config.rendezvousServer}, api=${config.apiServer}, relay=${config.relayServer}, key_len=${config.key.length}`);
      }
    } catch (e) {
      logger.error(TAG, 'Failed to set server config: ' + JSON.stringify(e));
    }
  }

  async setOption(key: string, value: string): Promise<void> {
    try {
      if (this.nativeModule && this.nativeModule.setOption) {
        await this.nativeModule.setOption(key, value);
      } else {
        logger.info(TAG, `setOption mock: ${key}=${value}`);
      }
    } catch (e) {
      logger.error(TAG, `Failed to set option ${key}: ` + JSON.stringify(e));
    }
  }

  async getOption(key: string): Promise<string> {
    try {
      if (this.nativeModule && this.nativeModule.getOption) {
        return await this.nativeModule.getOption(key);
      } else {
        return '';
      }
    } catch (e) {
      logger.error(TAG, `Failed to get option ${key}: ` + JSON.stringify(e));
      return '';
    }
  }

  async setPermanentPassword(password: string): Promise<boolean> {
    try {
      if (this.nativeModule && this.nativeModule.setPermanentPassword) {
        return await this.nativeModule.setPermanentPassword(password);
      } else {
        logger.info(TAG, `setPermanentPassword mock: password_len=${password.length}`);
        return true;
      }
    } catch (e) {
      logger.error(TAG, 'Failed to set permanent password: ' + JSON.stringify(e));
      return false;
    }
  }

  async setSocks(proxy: string, username: string, password: string): Promise<void> {
    try {
      if (this.nativeModule && this.nativeModule.setSocks) {
        await this.nativeModule.setSocks(proxy, username, password);
      } else {
        logger.info(TAG, `setSocks mock: proxy_set=${proxy.length > 0}`);
      }
    } catch (e) {
      logger.error(TAG, 'Failed to set socks: ' + JSON.stringify(e));
    }
  }

  async injectMouseMove(x: number, y: number): Promise<void> {
    try {
      if (this.nativeModule && this.nativeModule.injectMouseMove) {
        await this.nativeModule.injectMouseMove(x, y);
      }
    } catch (e) {
      logger.error(TAG, 'Failed to inject mouse move: ' + JSON.stringify(e));
    }
  }

  async injectMouseClick(x: number, y: number, button: number, down: boolean): Promise<void> {
    try {
      if (this.nativeModule && this.nativeModule.injectMouseClick) {
        await this.nativeModule.injectMouseClick(x, y, button, down);
      }
    } catch (e) {
      logger.error(TAG, 'Failed to inject mouse click: ' + JSON.stringify(e));
    }
  }

  async injectKey(keyCode: number, down: boolean): Promise<void> {
    try {
      if (this.nativeModule && this.nativeModule.injectKey) {
        await this.nativeModule.injectKey(keyCode, down);
      }
    } catch (e) {
      logger.error(TAG, 'Failed to inject key: ' + JSON.stringify(e));
    }
  }

  async captureScreenFrame(): Promise<Uint8Array | null> {
    try {
      if (this.nativeModule && this.nativeModule.captureScreenFrame) {
        return await this.nativeModule.captureScreenFrame();
      } else {
        // Mock 屏幕捕获：返回一个 1x1 黑色像素以避免 UI 显示异常
        const data = new Uint8Array(4);
        data[0] = 0; data[1] = 0; data[2] = 0; data[3] = 255;
        return data;
      }
    } catch (e) {
      logger.error(TAG, 'Failed to capture frame: ' + JSON.stringify(e));
      return null;
    }
  }

  async getVersion(): Promise<string> {
    try {
      if (this.nativeModule && this.nativeModule.getVersion) {
        return await this.nativeModule.getVersion();
      } else {
        return '1.4.6-harmony-mock';
      }
    } catch (e) {
      logger.error(TAG, 'Failed to get version: ' + JSON.stringify(e));
      return 'unknown';
    }
  }
}

// 导出单例
export const rustDeskCore = RustDeskCore.getInstance();
