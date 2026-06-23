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
import { VideoDataModel } from '../common/VideoDataModel';
import { FilePickerUtil } from '../common/FilePickerUtil';
import { common } from '@kit.AbilityKit';
import prompt from '@ohos.promptAction';

const DOMAIN = 0x0000; // Tag domain.

// 分类类型枚举
enum SortType {
  NONE = 0,        // 默认（无排序）
  FORMAT = 1,      // 按格式分类
  NAME = 2,        // 按名称分类
  ADD_TIME = 3     // 按添加时间分类
}

@Component
export struct VideoLibrary {
  @Link videoList: Array<VideoDataModel>;
  @Link selectedVideoIndex: number;
  private onVideoSelected?: (index: number) => void;
  private onVideosAdded?: (videos: Array<VideoDataModel>) => void;
  private onVideoNameChanged?: (index: number, newName: string) => void;
  private context = getContext(this) as common.UIAbilityContext;
  
  // 弹窗相关状态
  @State showRenameDialog: boolean = false;
  @State editingVideoIndex: number = -1;
  @State newVideoName: string = '';
  
  // 分类相关状态
  @State showSortDialog: boolean = false;
  @State currentSortType: SortType = SortType.NONE;
  @State originalVideoList: Array<VideoDataModel> = []; // 原始视频列表

  build() {
    Column() {
      // 顶部标题栏
      Row() {
        Text('视频库')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.Black)
          .margin({ left: 16 })
        
        Blank()
        
        // 分类按钮
        Button({ type: ButtonType.Circle }) {
          Image($r('sys.media.ohos_ic_public_more'))
            .width(24)
            .height(24)
        }
        .width(48)
        .height(48)
        .margin({ right: 8 })
        .onClick(() => {
          // 保存原始列表（如果还没有保存）
          if (this.originalVideoList.length === 0) {
            this.originalVideoList = [...this.videoList];
          }
          this.showSortDialog = true;
        })
        
        // 添加视频按钮
        Button({ type: ButtonType.Circle }) {
          Image($r('sys.media.ohos_ic_public_add'))
            .width(24)
            .height(24)
        }
        .width(48)
        .height(48)
        .margin({ right: 16 })
        .onClick(() => {
          // 触发文件选择器
          this.openFilePicker();
        })
      }
      .width('100%')
      .height(60)
      .backgroundColor(Color.White)
      .justifyContent(FlexAlign.SpaceBetween)

      // 视频网格列表
      Scroll() {
        Grid() {
          ForEach(this.videoList, (item: VideoDataModel, index: number) => {
            GridItem() {
              Column() {
                // 视频缩略图
                Stack() {
                  Image(item.thumbnail)
                    .width('100%')
                    .height(200)
                    .objectFit(ImageFit.Cover)
                    .borderRadius(8)
                  
                  // 视频时长
                  if (item.duration > 0) {
                    Text(this.formatDuration(item.duration))
                      .fontSize(12)
                      .fontColor(Color.White)
                      .backgroundColor('rgba(0, 0, 0, 0.6)')
                      .padding({ left: 4, right: 4, top: 2, bottom: 2 })
                      .borderRadius(4)
                      .position({ x: 8, y: 8 })
                  }
                  
                  // 播放按钮
                  Image($r('app.media.play'))
                    .width(40)
                    .height(40)
                    .fillColor(Color.White)
                    .opacity(0.8)
                    .position({ x: '50%', y: '50%' })
                    .translate({ x: -20, y: -20 })
                }
                .width('100%')
                .height(200)
                .priorityGesture(
                  LongPressGesture({ repeat: false, duration: 500 })
                    .onAction(() => {
                      hilog.info(DOMAIN, 'testTag', '%{public}s', `长按视频: ${index}, 标题: ${item.title}`);
                      this.editingVideoIndex = index;
                      this.newVideoName = item.title;
                      this.showRenameDialog = true;
                      hilog.info(DOMAIN, 'testTag', '%{public}s', `弹窗状态: ${this.showRenameDialog}`);
                    })
                )
                .gesture(
                  TapGesture({ count: 1 })
                    .onAction(() => {
                      hilog.info(DOMAIN, 'testTag', '%{public}s', `点击视频: ${index}, 标题: ${item.title}`);
                      this.selectedVideoIndex = index;
                      if (this.onVideoSelected) {
                        this.onVideoSelected(index);
                      }
                    })
                )

                // 视频标题
                Text(item.title)
                  .fontSize(14)
                  .fontColor(Color.Black)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .margin({ top: 8 })
                  .width('100%')
                
                // 文件类型标签
                Row() {
                  if (item.isLocalFile) {
                    Text('本地文件')
                      .fontSize(10)
                      .fontColor(Color.White)
                      .backgroundColor(Color.Blue)
                      .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                      .borderRadius(10)
                  } else {
                    Text('内置视频')
                      .fontSize(10)
                      .fontColor(Color.White)
                      .backgroundColor(Color.Green)
                      .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                      .borderRadius(10)
                  }
                }
                .justifyContent(FlexAlign.Start)
                .width('100%')
                .margin({ top: 4 })
              }
              .width('100%')
              .padding(8)
              .backgroundColor(Color.White)
              .borderRadius(12)
              .shadow({ radius: 8, color: Color.Gray, offsetX: 2, offsetY: 2 })
            }
            .width('100%')
            .height(280)
          }, (item: VideoDataModel) => item.uri.toString())
        }
        .columnsTemplate('1fr 1fr')
        .columnsGap(12)
        .rowsGap(12)
        .width('100%')
        .padding(16)
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .layoutWeight(1)
    .backgroundColor('#F5F5F5')
    .bindSheet($$this.showRenameDialog, this.RenameDialogBuilder(), {
      height: 280,
      backgroundColor: Color.White,
      dragBar: false
    })
    .bindSheet($$this.showSortDialog, this.SortDialogBuilder(), {
      height: 380,
      backgroundColor: Color.White,
      dragBar: false
    })
  }
  
  // 重命名弹窗
  @Builder
  RenameDialogBuilder() {
    Column() {
      // 标题
      Text('修改视频名称')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.Black)
        .margin({ top: 20, bottom: 20 })
      
      // 输入框
      TextInput({ text: $$this.newVideoName, placeholder: '请输入视频名称' })
        .width('80%')
        .height(48)
        .fontSize(16)
        .backgroundColor('#F5F5F5')
        .borderRadius(8)
        .margin({ bottom: 20 })
      
      // 按钮行
      Row() {
        Button('取消')
          .width('35%')
          .height(40)
          .fontSize(16)
          .fontColor('#666666')
          .backgroundColor('#F5F5F5')
          .borderRadius(8)
          .onClick(() => {
            this.showRenameDialog = false;
          })
        
        Button('确定')
          .width('35%')
          .height(40)
          .fontSize(16)
          .fontColor(Color.White)
          .backgroundColor('#007DFF')
          .borderRadius(8)
          .onClick(() => {
            if (this.newVideoName.trim().length > 0) {
              hilog.info(DOMAIN, 'testTag', '%{public}s', 
                `修改视频名称: 索引=${this.editingVideoIndex}, 新名称=${this.newVideoName}`);
              
              if (this.onVideoNameChanged) {
                this.onVideoNameChanged(this.editingVideoIndex, this.newVideoName.trim());
              }
              
              prompt.showToast({
                message: '视频名称已修改',
                duration: 2000
              });
            } else {
              prompt.showToast({
                message: '视频名称不能为空',
                duration: 2000
              });
            }
            this.showRenameDialog = false;
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceEvenly)
      .margin({ bottom: 20 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Start)
  }
  
  // 分类弹窗
  @Builder
  SortDialogBuilder() {
    Column() {
      // 标题
      Text('视频分类')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.Black)
        .margin({ top: 20, bottom: 20 })
      
      // 分类选项
      Column({ space: 12 }) {
        // 默认
        this.SortOptionItem('默认顺序', SortType.NONE)
        
        // 按格式
        this.SortOptionItem('按格式分类', SortType.FORMAT)
        
        // 按名称
        this.SortOptionItem('按名称分类', SortType.NAME)
        
        // 按时间
        this.SortOptionItem('按添加时间', SortType.ADD_TIME)
      }
      .width('100%')
      .padding({ left: 16, right: 16 })
      
      // 取消按钮
      Button('取消')
        .width('90%')
        .height(44)
        .backgroundColor('#f0f0f0')
        .fontColor('#333333')
        .margin({ top: 20 })
        .onClick(() => {
          this.showSortDialog = false;
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Start)
  }
  
  // 分类选项组件
  @Builder
  SortOptionItem(text: string, sortType: SortType) {
    Row() {
      Text(text)
        .fontSize(16)
        .fontColor(this.currentSortType === sortType ? '#007AFF' : '#333333')
        .layoutWeight(1)
      
      if (this.currentSortType === sortType) {
        Image($r('sys.media.ohos_ic_public_ok'))
          .width(20)
          .height(20)
          .fillColor('#007AFF')
      }
    }
    .width('100%')
    .height(48)
    .padding({ left: 16, right: 16 })
    .borderRadius(8)
    .backgroundColor(this.currentSortType === sortType ? '#E3F2FD' : '#f5f5f5')
    .onClick(() => {
      this.performSort(sortType);
    })
  }

  // 格式化视频时长（秒转换为 MM:SS）
  private formatDuration(seconds: number): string {
    const minutes = Math.floor(seconds / 60);
    const remainingSeconds = Math.floor(seconds % 60);
    return `${minutes.toString().padStart(2, '0')}:${remainingSeconds.toString().padStart(2, '0')}`;
  }
  
  // 获取视频格式
  private getVideoFormat(uri: string): string {
    const uriStr = uri.toString();
    const lastDot = uriStr.lastIndexOf('.');
    if (lastDot !== -1) {
      return uriStr.substring(lastDot + 1).toLowerCase();
    }
    return '未知';
  }
  
  // 按格式分类
  private sortByFormat(): void {
    const sorted = [...this.videoList].sort((a, b) => {
      const formatA = this.getVideoFormat(a.uri.toString());
      const formatB = this.getVideoFormat(b.uri.toString());
      return formatA.localeCompare(formatB);
    });
    this.videoList = sorted;
    hilog.info(DOMAIN, 'testTag', '%{public}s', '按格式分类完成');
  }
  
  // 按名称分类
  private sortByName(): void {
    const sorted = [...this.videoList].sort((a, b) => {
      return a.title.localeCompare(b.title);
    });
    this.videoList = sorted;
    hilog.info(DOMAIN, 'testTag', '%{public}s', '按名称分类完成');
  }
  
  // 按添加时间分类
  private sortByAddTime(): void {
    const sorted = [...this.videoList].sort((a, b) => {
      return b.addTime - a.addTime; // 降序，最新的在前
    });
    this.videoList = sorted;
    hilog.info(DOMAIN, 'testTag', '%{public}s', '按添加时间分类完成');
  }
  
  // 执行分类
  private performSort(sortType: SortType): void {
    this.currentSortType = sortType;
    
    switch (sortType) {
      case SortType.NONE:
        // 恢复原始顺序
        if (this.originalVideoList.length > 0) {
          this.videoList = [...this.originalVideoList];
        }
        hilog.info(DOMAIN, 'testTag', '%{public}s', '恢复原始顺序');
        break;
      case SortType.FORMAT:
        this.sortByFormat();
        break;
      case SortType.NAME:
        this.sortByName();
        break;
      case SortType.ADD_TIME:
        this.sortByAddTime();
        break;
    }
    
    this.showSortDialog = false;
    
    // 显示提示
    const sortNames = ['默认', '按格式', '按名称', '按时间'];
    prompt.showToast({
      message: `已切换为: ${sortNames[sortType]}`,
      duration: 1500
    });
  }

  // 打开文件选择器
  private async openFilePicker(): Promise<void> {
    hilog.info(DOMAIN, 'testTag', '%{public}s', '打开文件选择器');
    try {
      // 检查权限
      const hasPermission = await FilePickerUtil.checkPermissions();
      if (!hasPermission) {
        prompt.showToast({
          message: '请授予文件访问权限',
          duration: 2000
        });
        return;
      }

      // 打开文件选择器
      const selectedVideos = await FilePickerUtil.pickVideoFiles(this.context);
      
      if (selectedVideos.length > 0) {
        hilog.info(DOMAIN, 'testTag', '%{public}s', `成功选择了 ${selectedVideos.length} 个视频文件`);
        prompt.showToast({
          message: `成功导入 ${selectedVideos.length} 个视频`,
          duration: 2000
        });
        
        // 将选择的视频添加到视频列表中
        if (this.onVideosAdded) {
          this.onVideosAdded(selectedVideos);
        }
      } else {
        hilog.info(DOMAIN, 'testTag', '%{public}s', '用户取消了文件选择或未选择任何文件');
      }
    } catch (error) {
      hilog.error(DOMAIN, 'testTag', '%{public}s', `文件选择器错误: ${JSON.stringify(error)}`);
      prompt.showToast({
        message: '文件选择失败，请重试',
        duration: 2000
      });
    }
  }
}