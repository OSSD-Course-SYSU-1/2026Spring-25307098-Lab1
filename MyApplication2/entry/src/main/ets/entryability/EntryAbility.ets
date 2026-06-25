import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { GameManager } from '../common/GameManager';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');

    // 处理跨端流转冷启动：目标设备上应用未运行，通过 onCreate 恢复
    if (launchParam.launchReason === AbilityConstant.LaunchReason.CONTINUATION) {
      hilog.info(DOMAIN, 'testTag', 'Launched by continuation (cold start)');
      this.handleContinuation(want);
    }
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    // 如果是流转冷启动，用 restoreWindowStage 替代 loadContent
    if (this.isContinuationRestore) {
      this.restoreWindowStageForContinuation(windowStage);
      return;
    }

    windowStage.loadContent('pages/MainMenu', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');

    // 每次回到前台时，根据 GameManager 中保存的开关状态设置流转能力
    try {
      const isAuto = GameManager.isAutoContinuation();
      this.context.setMissionContinueState(
        isAuto ? AbilityConstant.ContinueState.ACTIVE : AbilityConstant.ContinueState.INACTIVE,
        (result) => {
          hilog.info(DOMAIN, 'testTag', 'onForeground setMissionContinueState: %{public}s', JSON.stringify(result));
        }
      );
      hilog.info(DOMAIN, 'testTag', 'onForeground: autoContinuation=%{public}s', isAuto ? 'true' : 'false');
    } catch (error) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set mission continue state: %{public}s', JSON.stringify(error));
    }
  }

  onBackground(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }

  // ===== 自由流转：迁移源端 =====

  /**
   * 源端：用户发起流转迁移时调用，保存游戏状态
   */
  onContinue(wantParam: Record<string, Object>): AbilityConstant.OnContinueResult {
    hilog.info(DOMAIN, 'testTag', 'onContinue: preparing game state for migration');

    try {
      const gameManager = GameManager.getInstance();
      const stateJson = gameManager.serializeState();

      // 将游戏状态存入 wantParam，系统会自动传递到目标端
      wantParam['gameState'] = stateJson;

      hilog.info(DOMAIN, 'testTag', 'onContinue: game state saved, agreeing to continue');
      return AbilityConstant.OnContinueResult.AGREE;
    } catch (error) {
      hilog.error(DOMAIN, 'testTag', 'onContinue failed: %{public}s', JSON.stringify(error));
      return AbilityConstant.OnContinueResult.REJECT;
    }
  }

  // ===== 自由流转：目标端恢复 =====

  // 标记是否是流转恢复
  private isContinuationRestore: boolean = false;

  /**
   * 从 want.parameters 中提取流转数据并存入 GameManager
   */
  private handleContinuation(want: Want): void {
    if (!want.parameters) {
      hilog.warn(DOMAIN, 'testTag', 'handleContinuation: no parameters in want');
      return;
    }

    const stateJson = want.parameters['gameState'] as string;
    if (!stateJson || typeof stateJson !== 'string') {
      hilog.warn(DOMAIN, 'testTag', 'handleContinuation: no valid gameState found');
      return;
    }

    GameManager.setContinuationData(stateJson);
    this.isContinuationRestore = true;
    hilog.info(DOMAIN, 'testTag', 'handleContinuation: game state saved for restoration');
  }

  /**
   * 使用 restoreWindowStage 恢复流转的窗口和页面状态
   */
  private restoreWindowStageForContinuation(windowStage: window.WindowStage): void {
    try {
      // 恢复窗口阶段 - 页面栈会自动重建为源端的页面
      windowStage.loadContent('pages/MainMenu', (err) => {
        if (err.code) {
          hilog.error(DOMAIN, 'testTag', 'Failed to restore content. Cause: %{public}s', JSON.stringify(err));
        }
        hilog.info(DOMAIN, 'testTag', 'Restored content for continuation');
      });
    } catch (error) {
      hilog.error(DOMAIN, 'testTag', 'restoreWindowStageForContinuation failed: %{public}s', JSON.stringify(error));
      // 降级：正常加载首页
      windowStage.loadContent('pages/MainMenu', (err) => {
        hilog.error(DOMAIN, 'testTag', 'Fallback loadContent: %{public}s', JSON.stringify(err));
      });
    }
  }

  /**
   * 目标端热启动时调用：应用已在后台运行，流转数据通过此回调传入
   */
  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, 'testTag', 'onNewWant called');

    if (launchParam.launchReason === AbilityConstant.LaunchReason.CONTINUATION) {
      hilog.info(DOMAIN, 'testTag', 'onNewWant: continuation (hot restart)');
      this.handleContinuation(want);
    }
  }
}
