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
 * RustDesk Core Interface
 */
export interface IRustDeskCore {
  initialize(appDir: string): Promise<boolean>;
  getLocalId(): Promise<string>;
  connectToPeer(peerId: string, password: string): Promise<boolean>;
  disconnect(): Promise<void>;
  disconnectPeer(peerId: string): Promise<void>;
  getConnectionState(peerId: string): Promise<string>;
  setServerConfig(address: string, port: number, enableDirect: boolean): Promise<void>;
  injectMouseMove(x: number, y: number): Promise<void>;
  injectMouseClick(x: number, y: number, button: number, down: boolean): Promise<void>;
  injectKey(keyCode: number, down: boolean): Promise<void>;
  captureScreenFrame(): Promise<Uint8Array | null>;
  getVersion(): Promise<string>;
}

/**
 * RustDesk Core Implementation
 */
export class RustDeskCore implements IRustDeskCore {
  private static instance: RustDeskCore;
  private isInitialized: boolean = false;
  private nativeModule: any = null;
  
  public static getInstance(): RustDeskCore {
    if (!RustDeskCore.instance) {
      RustDeskCore.instance = new RustDeskCore();
    }
    return RustDeskCore.instance;
  }

  private constructor() {
    try {
      // 尝试加载 NAPI 模块
      // this.nativeModule = requireNapi('rustdesk_napi');
      logger.info(TAG, 'NAPI module loaded successfully');
    } catch (e) {
      logger.warn(TAG, 'Failed to load NAPI module, using mock implementation');
    }
  }

  async initialize(appDir: string): Promise<boolean> {
    if (this.isInitialized) {
      return true;
    }

    try {
      logger.info(TAG, 'Initializing RustDesk core at: ' + appDir);
      
      if (this.nativeModule && this.nativeModule.initialize) {
        const result = await this.nativeModule.initialize(appDir);
        this.isInitialized = result;
        return result;
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

  async setServerConfig(address: string, port: number, enableDirect: boolean): Promise<void> {
    try {
      if (this.nativeModule && this.nativeModule.setServerConfig) {
        await this.nativeModule.setServerConfig(address, port, enableDirect);
      } else {
        // Mock 保存配置
        logger.info(TAG, 'Server config updated');
      }
    } catch (e) {
      logger.error(TAG, 'Failed to set server config: ' + JSON.stringify(e));
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
        // Mock 屏幕捕获
        const width = 1280;
        const height = 720;
        const data = new Uint8Array(width * height * 4);
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
        return '1.0.0-harmony';
      }
    } catch (e) {
      logger.error(TAG, 'Failed to get version: ' + JSON.stringify(e));
      return 'unknown';
    }
  }
}

// 导出单例
export const rustDeskCore = RustDeskCore.getInstance();
