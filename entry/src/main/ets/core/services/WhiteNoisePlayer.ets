import { media } from '@kit.MediaKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';

export enum PlayerState {
  IDLE,       
  LOADING,    
  PLAYING,    
  PAUSED,     
  ERROR       
}

@ObservedV2
export class WhiteNoisePlayer {
  @Trace state: PlayerState = PlayerState.IDLE;
  @Trace currentTrackName: string = '';
  @Trace volume: number = 1; 
  @Trace selectedTrack: string = 'rain.mp3';

  private avPlayer: media.AVPlayer | null = null;

  constructor() {
    this.initPlayer();
  }

  private async initPlayer(): Promise<void> {
    try {
      this.avPlayer = await media.createAVPlayer();
      this.setListeners();
      console.info('[WhiteNoisePlayer] AVPlayer 初始化成功');
    } catch (error) {
      console.error(`[WhiteNoisePlayer] AVPlayer 创建失败: ${(error as BusinessError).message}`);
      this.state = PlayerState.ERROR;
    }
  }

  private setListeners(): void {
    if (!this.avPlayer) return;

    this.avPlayer.on('stateChange', async (state: string, reason: media.StateChangeReason) => {
      console.info(`[WhiteNoisePlayer] 状态流转: ${state}`);
      switch (state) {
        case 'initialized':
          this.state = PlayerState.LOADING;
          this.avPlayer?.prepare();
          break;
        case 'prepared':
          if (this.avPlayer) {
            this.avPlayer.loop = true;
            this.avPlayer.setVolume(this.volume);
            this.avPlayer.play();
          }
          break;
        case 'playing':
          this.state = PlayerState.PLAYING;
          break;
        case 'paused':
          this.state = PlayerState.PAUSED;
          break;
        case 'stopped':
        case 'idle':
          this.state = PlayerState.IDLE;
          break;
        case 'error':
          this.state = PlayerState.ERROR;
          break;
      }
    });

    this.avPlayer.on('error', (error: BusinessError) => {
      console.error(`[WhiteNoisePlayer] 播放错误: ${error.message}`);
      this.state = PlayerState.ERROR;
    });
  }

  /**
   * 播放 rawfile/white_noise/ 目录下的白噪音
   * @param context UIAbilityContext
   * @param fileName 文件名
   */
  public async playWhiteNoise(context: common.UIAbilityContext, fileName: string): Promise<void> {
    if (!this.avPlayer) await this.initPlayer();
    if (!this.avPlayer) return;

    try {
      if (this.state !== PlayerState.IDLE) {
        await this.avPlayer.reset(); 
      }

      this.currentTrackName = fileName;
      this.state = PlayerState.LOADING;
      const rawFilePath = `white_noise/${fileName}`;
      const fileDescriptor = await context.resourceManager.getRawFd(rawFilePath);
      
      this.avPlayer.fdSrc = fileDescriptor; 
    } catch (error) {
      console.error(`[WhiteNoisePlayer] 加载音频失败: ${(error as BusinessError).message}`);
      this.state = PlayerState.ERROR;
    }
  }

  public pause(): void {
    if (this.state === PlayerState.PLAYING) {
      this.avPlayer?.pause();
    }
  }

  public resume(): void {
    if (this.state === PlayerState.PAUSED) {
      this.avPlayer?.play();
    }
  }

  public async stop(): Promise<void> {
    if (this.state !== PlayerState.IDLE && this.avPlayer) {
      await this.avPlayer.stop();
      this.currentTrackName = '';
    }
  }

  public setVolume(vol: number): void {
    this.volume = Math.max(0, Math.min(1, vol));
    if (this.state === PlayerState.PLAYING || this.state === PlayerState.PAUSED) {
      this.avPlayer?.setVolume(this.volume);
    }
  }

  public async release(): Promise<void> {
    if (this.avPlayer) {
      await this.avPlayer.release();
      this.avPlayer = null;
      this.state = PlayerState.IDLE;
    }
  }
}