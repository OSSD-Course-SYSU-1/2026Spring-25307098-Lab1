/*
 * Copyright (c) 2026 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import { hilog } from '@kit.PerformanceAnalysisKit';
import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';

const DOMAIN = 0x0000; // Tag domain.
const STORE_NAME = 'video_library_store';
const KEY_VIDEO_LIST = 'video_list';
const KEY_BUILT_IN_VIDEOS = 'built_in_videos';

/**
 * 视频存储工具类
 * 用于持久化保存视频列表
 */
export class VideoStorageUtil {
  /**
   * 保存视频列表到本地存储
   * @param context UIAbility上下文
   * @param videoListJson 视频列表JSON字符串
   */
  static async saveVideoList(context: common.UIAbilityContext, videoListJson: string): Promise<void> {
    try {
      hilog.info(DOMAIN, 'testTag', '%{public}s', '开始保存视频列表');
      
      const dataStore = await preferences.getPreferences(context, STORE_NAME);
      await dataStore.put(KEY_VIDEO_LIST, videoListJson);
      await dataStore.flush();
      
      hilog.info(DOMAIN, 'testTag', '%{public}s', '视频列表保存成功');
    } catch (error) {
      hilog.error(DOMAIN, 'testTag', '%{public}s', `保存视频列表失败: ${JSON.stringify(error)}`);
    }
  }

  /**
   * 从本地存储加载视频列表
   * @param context UIAbility上下文
   * @returns 视频列表JSON字符串
   */
  static async loadVideoList(context: common.UIAbilityContext): Promise<string> {
    try {
      hilog.info(DOMAIN, 'testTag', '%{public}s', '开始加载视频列表');
      
      const dataStore = await preferences.getPreferences(context, STORE_NAME);
      const videoListJson = await dataStore.get(KEY_VIDEO_LIST, '');
      
      if (videoListJson && typeof videoListJson === 'string') {
        hilog.info(DOMAIN, 'testTag', '%{public}s', '视频列表加载成功');
        return videoListJson;
      }
      
      hilog.info(DOMAIN, 'testTag', '%{public}s', '没有保存的视频列表');
      return '';
    } catch (error) {
      hilog.error(DOMAIN, 'testTag', '%{public}s', `加载视频列表失败: ${JSON.stringify(error)}`);
      return '';
    }
  }

  /**
   * 清除保存的视频列表
   * @param context UIAbility上下文
   */
  static async clearVideoList(context: common.UIAbilityContext): Promise<void> {
    try {
      const dataStore = await preferences.getPreferences(context, STORE_NAME);
      await dataStore.delete(KEY_VIDEO_LIST);
      await dataStore.flush();
      
      hilog.info(DOMAIN, 'testTag', '%{public}s', '视频列表已清除');
    } catch (error) {
      hilog.error(DOMAIN, 'testTag', '%{public}s', `清除视频列表失败: ${JSON.stringify(error)}`);
    }
  }

  /**
   * 保存内置视频信息（包括名称修改）
   * @param context UIAbility上下文
   * @param builtInVideosJson 内置视频信息JSON字符串
   */
  static async saveBuiltInVideos(context: common.UIAbilityContext, builtInVideosJson: string): Promise<void> {
    try {
      hilog.info(DOMAIN, 'testTag', '%{public}s', '开始保存内置视频信息');
      
      const dataStore = await preferences.getPreferences(context, STORE_NAME);
      await dataStore.put(KEY_BUILT_IN_VIDEOS, builtInVideosJson);
      await dataStore.flush();
      
      hilog.info(DOMAIN, 'testTag', '%{public}s', '内置视频信息保存成功');
    } catch (error) {
      hilog.error(DOMAIN, 'testTag', '%{public}s', `保存内置视频信息失败: ${JSON.stringify(error)}`);
    }
  }

  /**
   * 加载内置视频信息
   * @param context UIAbility上下文
   * @returns 内置视频信息JSON字符串
   */
  static async loadBuiltInVideos(context: common.UIAbilityContext): Promise<string> {
    try {
      hilog.info(DOMAIN, 'testTag', '%{public}s', '开始加载内置视频信息');
      
      const dataStore = await preferences.getPreferences(context, STORE_NAME);
      const builtInVideosJson = await dataStore.get(KEY_BUILT_IN_VIDEOS, '');
      
      if (builtInVideosJson && typeof builtInVideosJson === 'string') {
        hilog.info(DOMAIN, 'testTag', '%{public}s', '内置视频信息加载成功');
        return builtInVideosJson;
      }
      
      hilog.info(DOMAIN, 'testTag', '%{public}s', '没有保存的内置视频信息');
      return '';
    } catch (error) {
      hilog.error(DOMAIN, 'testTag', '%{public}s', `加载内置视频信息失败: ${JSON.stringify(error)}`);
      return '';
    }
  }
}
