/**
 * 模块功能简介：
 * - 华为实况窗 (Live View) 管理服务类。
 * - 颜色暂时是硬编码的。
 * - todo：实况胶囊有时不显示，排查原因
 */
import { liveViewManager } from '@kit.LiveViewKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { wantAgent } from '@kit.AbilityKit';
import { FocusState } from './FocusTimerEngine';

export class FocusLiveViewManager {
  private static currentLiveViewId: number = 0; 
  private static readonly ENTRY_BUNDLE_NAME: string = 'com.nis3366.ZhixingActhub';
  private static readonly ENTRY_ABILITY_NAME: string = 'EntryAbility';
  
  private static currentView: liveViewManager.LiveView | undefined = undefined;
  private static isShowing: boolean = false; 
  private static globalSequence: number = 0; 

  public static async isLiveViewEnabled(): Promise<boolean> {
    try {
      return await liveViewManager.isLiveViewEnabled();
    } catch (e) {
      return false;
    }
  }

  public static async syncState(
    state: FocusState,
    remainingSeconds: number,
    expectedEndTime: number,
    todoTitle: string 
  ): Promise<void> {
    if (!await FocusLiveViewManager.isLiveViewEnabled()) {
      return;
    }

    if (state !== FocusState.WORKING && state !== FocusState.RESTING && state !== FocusState.PAUSED) {
      await FocusLiveViewManager.stop();
      return;
    }

    const isWorking = state === FocusState.WORKING;
    const isPaused = state === FocusState.PAUSED;
    const date = new Date(expectedEndTime);
    const timeStr = `${date.getHours().toString().padStart(2, '0')}:${date.getMinutes().toString().padStart(2, '0')}`;
    
    const stageTitle = isWorking ? '专注中' : (isPaused ? '已暂停' : '休息中');
    const nextStageText = isWorking ? `预计 ${timeStr} 开始休息` : `预计 ${timeStr} 继续专注`;

    if (!FocusLiveViewManager.isShowing) {
      FocusLiveViewManager.currentLiveViewId = Math.floor(Date.now() % 1000000); 
    }

    const finalDisplayTitle = todoTitle.trim().length > 0 ? todoTitle.trim() : stageTitle;

    FocusLiveViewManager.currentView = await FocusLiveViewManager.buildLiveView(
      stageTitle, 
      nextStageText, 
      remainingSeconds, 
      isPaused, 
      finalDisplayTitle
    );
    
    if (!FocusLiveViewManager.currentView) return;

    try {
      FocusLiveViewManager.globalSequence += 1;
      FocusLiveViewManager.currentView.sequence = FocusLiveViewManager.globalSequence;

      if (FocusLiveViewManager.isShowing) {
        try {
          await liveViewManager.updateLiveView(FocusLiveViewManager.currentView);
        } catch (updateError) {
          FocusLiveViewManager.currentLiveViewId = Math.floor(Date.now() % 1000000);
          FocusLiveViewManager.currentView.id = FocusLiveViewManager.currentLiveViewId;
          FocusLiveViewManager.globalSequence = 1;
          FocusLiveViewManager.currentView.sequence = 1;
          await liveViewManager.startLiveView(FocusLiveViewManager.currentView);
          FocusLiveViewManager.isShowing = true;
        }
      } else {
        await liveViewManager.startLiveView(FocusLiveViewManager.currentView);
        FocusLiveViewManager.isShowing = true; 
      }
    } catch (e) {
      const err = e as BusinessError;
      console.error(`[FocusLiveView] 同步失败: ${err.code} - ${err.message}`);
    }
  }

  public static async stop(): Promise<void> {
    if (!await FocusLiveViewManager.isLiveViewEnabled() || !FocusLiveViewManager.isShowing || !FocusLiveViewManager.currentView) {
      return;
    }

    try {
      FocusLiveViewManager.currentView.timer = { time: 0, isPaused: true, isCountdown: false };
      FocusLiveViewManager.currentView.liveViewData.primary.title = '专注已完成';
      FocusLiveViewManager.currentView.liveViewData.primary.content = [{ text: '本次专注记录已保存' }];
      
      FocusLiveViewManager.currentView.liveViewData.primary.layoutData = {
        layoutType: liveViewManager.LayoutType.LAYOUT_TYPE_PICKUP,
        title: '已完成',
        content: '00:00', 
        descPic: 'app_icon.png'
      };

      FocusLiveViewManager.currentView.liveViewData.capsule = {
        type: liveViewManager.CapsuleType.CAPSULE_TYPE_TEXT, 
        status: 1,
        title: '已结束',
        backgroundColor: '#FF000000',
        icon: 'app_icon.png'
      };
      
      FocusLiveViewManager.globalSequence += 1;
      FocusLiveViewManager.currentView.sequence = FocusLiveViewManager.globalSequence;

      await liveViewManager.stopLiveView(FocusLiveViewManager.currentView);
    } catch (e) {
      console.warn(`[FocusLiveView] 销毁遇到非致命错误: ${(e as BusinessError).message}`);
    } finally {
      FocusLiveViewManager.currentView = undefined;
      FocusLiveViewManager.isShowing = false; 
      FocusLiveViewManager.globalSequence = 0; 
    }
  }

  private static async buildLiveView(
    stageTitle: string, 
    desc: string, 
    remainingSeconds: number, 
    isPaused: boolean,
    displayTitle: string 
  ): Promise<liveViewManager.LiveView> {
    
    const clickAction = await FocusLiveViewManager.getWantAgent();

    return {
      id: FocusLiveViewManager.currentLiveViewId, 
      event: "TIMER",
      sequence: 1, 
      isMute: true,
      timer: {
        time: remainingSeconds * 1000,
        isCountdown: true,
        isPaused: isPaused
      },
      liveViewData: {
        primary: {
          title: stageTitle, 
          content: [{ text: desc }],
          clickAction: clickAction,
          keepTime: 15,
          layoutData: {
            layoutType: liveViewManager.LayoutType.LAYOUT_TYPE_PICKUP, 
            title: displayTitle, 
            content: '${placeholder.timer}', 
            descPic: 'app_icon.png' 
          }
        },
        capsule: {
          type: liveViewManager.CapsuleType.CAPSULE_TYPE_TIMER,
          status: 1,
          icon: 'app_icon.png', 
          backgroundColor: '#FF000000',
          time: remainingSeconds * 1000,
          isCountdown: true,
          isPaused: isPaused,
        }
      }
    };
  }

  private static async getWantAgent(): Promise<Object> {
    const wantAgentInfo: wantAgent.WantAgentInfo = {
      wants: [{
        bundleName: FocusLiveViewManager.ENTRY_BUNDLE_NAME,
        abilityName: FocusLiveViewManager.ENTRY_ABILITY_NAME,
      }],
      operationType: wantAgent.OperationType.START_ABILITY, 
      requestCode: 0,
      wantAgentFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG]
    };
    return await wantAgent.getWantAgent(wantAgentInfo);
  }
}