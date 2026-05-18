import { testNapi } from 'libentry.so'
import promptAction from '@ohos.promptAction'
import { logger } from '@ohos.hilog'

const TAG: string = '[RustDesk.Native]'

// RustDesk 原生核心接口
export class RustDeskCore {
  private static instance: RustDeskCore
  private isInitialized: boolean = false

  static getInstance(): RustDeskCore {
    if (!RustDeskCore.instance) {
      RustDeskCore.instance = new RustDeskCore()
    }
    return RustDeskCore.instance
  }

  // 初始化核心
  async initialize(appDir: string): Promise<boolean> {
    if (this.isInitialized) {
      return true
    }

    try {
      logger.info(TAG, `Initializing RustDesk core at: ${appDir}`)
      
      // 调用 NAPI 函数初始化
      // testNapi.initialize(appDir)  // 实际使用时启用
      
      // 模拟初始化
      this.isInitialized = true
      
      logger.info(TAG, 'RustDesk core initialized successfully')
      return true
    } catch (e) {
      logger.error(TAG, `Failed to initialize RustDesk core: ${JSON.stringify(e)}`)
      return false
    }
  }

  // 获取本地 ID
  async getLocalId(): Promise<string> {
    if (!this.isInitialized) {
      logger.warn(TAG, 'Core not initialized, returning test ID')
      return 'TEST123456'
    }

    try {
      // return testNapi.getLocalId()  // 实际使用时启用
      return 'TEST123456' // 模拟数据
    } catch (e) {
      logger.error(TAG, `Failed to get local ID: ${JSON.stringify(e)}`)
      return 'ERROR'
    }
  }

  // 连接到对等端
  async connectToPeer(peerId: string, password: string): Promise<boolean> {
    if (!this.isInitialized) {
      logger.warn(TAG, 'Core not initialized')
      return false
    }

    try {
      logger.info(TAG, `Connecting to peer: ${peerId}`)
      
      // 模拟连接过程
      await new Promise(resolve => setTimeout(resolve, 1500))
      
      // return testNapi.connectToPeer(peerId, password)  // 实际使用时启用
      return true // 模拟成功
    } catch (e) {
      logger.error(TAG, `Failed to connect to peer: ${JSON.stringify(e)}`)
      return false
    }
  }

  // 断开连接
  async disconnect(): Promise<void> {
    if (!this.isInitialized) {
      return
    }

    try {
      logger.info(TAG, 'Disconnecting')
      
      // testNapi.disconnect()  // 实际使用时启用
    } catch (e) {
      logger.error(TAG, `Failed to disconnect: ${JSON.stringify(e)}`)
    }
  }

  // 获取连接状态
  async getConnectionState(peerId: string): Promise<string> {
    if (!this.isInitialized) {
      return 'Disconnected'
    }

    try {
      // return testNapi.getConnectionState(peerId)  // 实际使用时启用
      return 'Connected' // 模拟数据
    } catch (e) {
      logger.error(TAG, `Failed to get connection state: ${JSON.stringify(e)}`)
      return 'Error'
    }
  }

  // 设置服务器配置
  async setServerConfig(address: string, port: number, enableDirect: boolean): Promise<void> {
    if (!this.isInitialized) {
      return
    }

    try {
      logger.info(TAG, `Setting server config: ${address}:${port}, direct: ${enableDirect}`)
      
      // testNapi.setServerConfig(address, port, enableDirect)  // 实际使用时启用
    } catch (e) {
      logger.error(TAG, `Failed to set server config: ${JSON.stringify(e)}`)
    }
  }

  // 注入鼠标移动
  async injectMouseMove(x: number, y: number): Promise<void> {
    if (!this.isInitialized) {
      return
    }

    try {
      // testNapi.injectMouseMove(x, y)  // 实际使用时启用
    } catch (e) {
      logger.error(TAG, `Failed to inject mouse move: ${JSON.stringify(e)}`)
    }
  }

  // 注入鼠标点击
  async injectMouseClick(x: number, y: number, button: number, down: boolean): Promise<void> {
    if (!this.isInitialized) {
      return
    }

    try {
      // testNapi.injectMouseClick(x, y, button, down)  // 实际使用时启用
    } catch (e) {
      logger.error(TAG, `Failed to inject mouse click: ${JSON.stringify(e)}`)
    }
  }

  // 注入键盘按键
  async injectKey(keyCode: number, down: boolean): Promise<void> {
    if (!this.isInitialized) {
      return
    }

    try {
      // testNapi.injectKey(keyCode, down)  // 实际使用时启用
    } catch (e) {
      logger.error(TAG, `Failed to inject key: ${JSON.stringify(e)}`)
    }
  }

  // 捕获屏幕帧
  async captureScreenFrame(): Promise<Uint8Array | null> {
    if (!this.isInitialized) {
      return null
    }

    try {
      // return testNapi.captureScreenFrame()  // 实际使用时启用
      
      // 模拟帧数据
      const width = 1280
      const height = 720
      const frameData = new Uint8Array(width * height * 4)
      
      for (let y = 0; y < height; y++) {
        for (let x = 0; x < width; x++) {
          const idx = (y * width + x) * 4
          frameData[idx] = (x & 0xFF) as u8      // R
          frameData[idx + 1] = (y & 0xFF) as u8  // G
          frameData[idx + 2] = 128 as u8         // B
          frameData[idx + 3] = 255 as u8         // A
        }
      }
      
      return frameData
    } catch (e) {
      logger.error(TAG, `Failed to capture screen frame: ${JSON.stringify(e)}`)
      return null
    }
  }

  // 获取版本信息
  async getVersion(): Promise<string> {
    try {
      // return testNapi.getVersion()  // 实际使用时启用
      return '1.4.6-harmony'
    } catch (e) {
      logger.error(TAG, `Failed to get version: ${JSON.stringify(e)}`)
      return 'unknown'
    }
  }
}

// 全局核心实例
export const rustDeskCore = RustDeskCore.getInstance()
