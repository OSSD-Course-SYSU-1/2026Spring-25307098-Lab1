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
import { picker } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { VideoInfoDataModel, VideoDataModel } from './VideoDataModel';
import { VideoThumbnailUtil } from './VideoThumbnailUtil';

const DOMAIN = 0x0000; // Tag domain.

export class FilePickerUtil {
  /**
   * 打开文件选择器选择视频文件
   * @param context UIAbility上下文
   * @returns 选择的视频文件信息数组
   */
  static async pickVideoFiles(context: common.UIAbilityContext): Promise<Array<VideoDataModel>> {
    try {
      hilog.info(DOMAIN, 'testTag', '%{public}s', '开始选择视频文件');

      // 创建文件选择器选项
      const photoSelectOptions = new picker.PhotoSelectOptions();
      photoSelectOptions.MIMEType = picker.PhotoViewMIMETypes.VIDEO_TYPE; // 只选择视频文件
      photoSelectOptions.maxSelectNumber = 10; // 最多选择10个文件

      // 创建文件选择器
      const photoPicker = new picker.PhotoViewPicker();

      // 打开文件选择器
      const photoSelectResult = await photoPicker.select(photoSelectOptions);

      if (!photoSelectResult || photoSelectResult.photoUris.length === 0) {
        hilog.info(DOMAIN, 'testTag', '%{public}s', '用户取消了文件选择或未选择任何文件');
        return [];
      }

      hilog.info(DOMAIN, 'testTag', '%{public}s', `选择了 ${photoSelectResult.photoUris.length} 个文件`);

      // 转换选中的文件为视频数据模型
      const videoFiles: Array<VideoDataModel> = [];
      for (let i = 0; i < photoSelectResult.photoUris.length; i++) {
        const uri = photoSelectResult.photoUris[i];
        const fileName = FilePickerUtil.getFileNameFromUri(uri);
        
        // 获取视频信息（缩略图和时长）
        const videoInfo = await VideoThumbnailUtil.getVideoInfo(uri);
        
        const videoData: VideoInfoDataModel = {
          uri: uri,
          title: videoInfo.title || fileName || `视频 ${i + 1}`,
          thumbnail: videoInfo.thumbnail,
          duration: videoInfo.duration,
          filePath: uri,
          isLocalFile: true
        };
        
        videoFiles.push(new VideoDataModel(videoData));

        hilog.info(DOMAIN, 'testTag', '%{public}s', `选择的文件: ${fileName}, URI: ${uri}, 时长: ${videoInfo.duration}秒`);
      }

      return videoFiles;
    } catch (error) {
      hilog.error(DOMAIN, 'testTag', '%{public}s', `文件选择器错误: ${JSON.stringify(error)}`);
      throw new Error(`文件选择器错误: ${error}`);
    }
  }

  /**
   * 从URI中提取文件名
   * @param uri 文件URI
   * @returns 文件名
   */
  private static getFileNameFromUri(uri: string): string {
    try {
      // 从URI中提取文件名
      const lastSlashIndex = uri.lastIndexOf('/');
      if (lastSlashIndex !== -1) {
        const fileNameWithExt = uri.substring(lastSlashIndex + 1);
        // 移除文件扩展名
        const lastDotIndex = fileNameWithExt.lastIndexOf('.');
        if (lastDotIndex !== -1) {
          return fileNameWithExt.substring(0, lastDotIndex);
        }
        return fileNameWithExt;
      }
      return '未知文件';
    } catch (error) {
      hilog.error(DOMAIN, 'testTag', '%{public}s', `提取文件名错误: ${error}`);
      return '未知文件';
    }
  }

  /**
   * 检查是否有文件访问权限
   * @returns 是否有权限
   */
  static async checkPermissions(): Promise<boolean> {
    try {
      // 这里可以添加权限检查逻辑
      // 目前返回true，实际应用中需要根据具体权限配置进行检查
      return true;
    } catch (error) {
      hilog.error(DOMAIN, 'testTag', '%{public}s', `权限检查错误: ${error}`);
      return false;
    }
  }
}