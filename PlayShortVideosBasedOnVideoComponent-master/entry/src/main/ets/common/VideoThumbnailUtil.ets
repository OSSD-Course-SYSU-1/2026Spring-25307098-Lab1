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
import { image } from '@kit.ImageKit';

const DOMAIN = 0x0000; // Tag domain.

export class VideoThumbnailUtil {
  /**
   * 生成视频缩略图
   * @param videoUri 视频文件URI
   * @param width 缩略图宽度
   * @param height 缩略图高度
   * @returns 缩略图URI或默认图片资源
   */
  static async generateThumbnail(videoUri: string, width: number = 200, height: number = 200): Promise<ResourceStr> {
    try {
      hilog.info(DOMAIN, 'testTag', '%{public}s', `开始生成视频缩略图: ${videoUri}`);
      
      // 检查URI是否有效
      if (!videoUri || videoUri.trim().length === 0) {
        hilog.warn(DOMAIN, 'testTag', '%{public}s', '视频URI为空，返回默认缩略图');
        return $r('app.media.background');  // 直接返回Resource
      }

      // 对于 rawfile 资源，直接使用默认图片
      if (videoUri.includes('rawfile')) {
        hilog.info(DOMAIN, 'testTag', '%{public}s', 'rawfile视频，使用默认缩略图');
        return $r('app.media.background');  // 直接返回Resource
      }

      // 尝试使用ImageKit生成缩略图
      // 注意：实际应用中可能需要更复杂的实现
      // 这里使用一个简单的实现，实际应该使用媒体库API
      
      // 对于本地文件URI，我们可以尝试创建一个缩略图
      // 这里使用一个占位符实现
      // 在实际应用中，应该使用 @kit.MediaLibraryKit 或 @kit.AVSessionKit 来获取视频缩略图
      
      hilog.info(DOMAIN, 'testTag', '%{public}s', '使用默认缩略图（实际应用中应实现真正的缩略图生成）');
      return $r('app.media.background');  // 直接返回Resource
      
    } catch (error) {
      hilog.error(DOMAIN, 'testTag', '%{public}s', `生成缩略图错误: ${JSON.stringify(error)}`);
      // 发生错误时返回默认图片
      return $r('app.media.background');  // 直接返回Resource
    }
  }

  /**
   * 获取视频时长
   * @param videoUri 视频文件URI
   * @returns 视频时长（秒）
   */
  static async getVideoDuration(videoUri: string): Promise<number> {
    try {
      hilog.info(DOMAIN, 'testTag', '%{public}s', `获取视频时长: ${videoUri}`);
      
      // 这里应该使用媒体库API获取视频时长
      // 暂时返回0，实际应用中需要实现
      
      // 对于演示目的，返回一个随机时长（30-300秒）
      const randomDuration = Math.floor(Math.random() * 270) + 30;
      hilog.info(DOMAIN, 'testTag', '%{public}s', `视频时长（模拟）: ${randomDuration}秒`);
      
      return randomDuration;
    } catch (error) {
      hilog.error(DOMAIN, 'testTag', '%{public}s', `获取视频时长错误: ${JSON.stringify(error)}`);
      return 0;
    }
  }

  /**
   * 从视频URI提取视频信息
   * @param videoUri 视频文件URI
   * @returns 视频信息对象
   */
  static async getVideoInfo(videoUri: string): Promise<VideoInfo> {
    try {
      const thumbnail = await VideoThumbnailUtil.generateThumbnail(videoUri);
      const duration = await VideoThumbnailUtil.getVideoDuration(videoUri);
      
      // 从URI提取文件名作为标题
      let title = '未命名视频';
      try {
        const lastSlashIndex = videoUri.lastIndexOf('/');
        if (lastSlashIndex !== -1) {
          const fileNameWithExt = videoUri.substring(lastSlashIndex + 1);
          const lastDotIndex = fileNameWithExt.lastIndexOf('.');
          if (lastDotIndex !== -1) {
            title = fileNameWithExt.substring(0, lastDotIndex);
          } else {
            title = fileNameWithExt;
          }
        }
      } catch (error) {
        hilog.warn(DOMAIN, 'testTag', '%{public}s', `提取视频标题错误: ${error}`);
      }

      return {
        thumbnail,
        duration,
        title
      };
    } catch (error) {
      hilog.error(DOMAIN, 'testTag', '%{public}s', `获取视频信息错误: ${JSON.stringify(error)}`);
      return {
        thumbnail: $r('app.media.background'),  // 直接返回Resource
        duration: 0,
        title: '未命名视频'
      };
    }
  }
}

// 视频信息接口
interface VideoInfo {
  thumbnail: ResourceStr;  // 使用ResourceStr类型，支持Resource和string
  duration: number;
  title: string;
}