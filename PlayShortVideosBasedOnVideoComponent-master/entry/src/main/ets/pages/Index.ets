/*
* Copyright (C) 2026 Huawei Device Co., Ltd.
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
* http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

import { hilog } from '@kit.PerformanceAnalysisKit';
import { display } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { WindowUtil } from '../common/WindowUtil';
import { VideoLibrary } from '../view/VideoLibrary';
import { VideoPlayer } from '../view/VideoPlayer';
import { VideoData } from '../common/VideoData';
import CommonConstants from '../constants/CommonConstants';
import { MyDataSource, VideoDataModel, VideoInfoDataModel } from '../common/VideoDataModel';
import { FilePickerUtil } from '../common/FilePickerUtil';
import { VideoStorageUtil } from '../common/VideoStorageUtil';
import prompt from '@ohos.promptAction';
import { TabBar } from '../components/TabBar';
import { MyPage } from './MyPage';

const DOMAIN = 0x0000; // Tag domain.

@Entry
@Component
struct Index {
  private swiperController: SwiperController = new SwiperController();
  private windowUtil: WindowUtil = WindowUtil.getInstance(); // Window-related utility class
  @State videoInfoList: Array<VideoDataModel> = []; // Video resource list
  @State isFullLandscapeScreen: boolean = false;
  @State isStart: boolean = true; // Playing or pause
  @State currentIndex: number = 0; // Index of the currently playing video
  @State screenWidth: number = 0; // Screen width
  @State showVideoLibrary: boolean = true; // 显示视频库还是播放器
  @State selectedVideoIndex: number = 0; // 选中的视频索引
  @State currentTab: number = 0; // 当前选中的标签页：0-视频，1-我的

  aboutToAppear() {
    // 不再加载内置视频，改为从本地加载用户添加的视频
    AppStorage.setOrCreate('swiperController', this.swiperController);
    // Get screenWidth
    this.getScreenWidth();
    // Monitor window size changes
    this.windowUtil.registerOnWindowSizeChange((size) => {
      hilog.info(DOMAIN, 'testTag', '%{public}s',
        'registerOnWindowSizeChange:' + ' width:' + size.width + ',height:' + size.height);
      if (size.width > size.height) {
        this.isFullLandscapeScreen = true;
      } else {
        this.isFullLandscapeScreen = false;
      }
      // Update screenWidth
      this.getScreenWidth();
    });
    // 加载持久化的视频列表
    this.loadSavedVideos();
  }

  // 加载保存的视频列表
  private async loadSavedVideos(): Promise<void> {
    try {
      const context = getContext(this) as common.UIAbilityContext;
      
      // 加载本地视频
      const savedVideosJson = await VideoStorageUtil.loadVideoList(context);
      if (savedVideosJson && savedVideosJson.length > 0) {
        const savedVideos = JSON.parse(savedVideosJson) as VideoInfoDataModel[];
        if (savedVideos && savedVideos.length > 0) {
          // 将本地视频加载到列表中
          const savedVideoModels = savedVideos.map(v => new VideoDataModel(v));
          this.videoInfoList = [...savedVideoModels];
          hilog.info(DOMAIN, 'testTag', '%{public}s', `加载了 ${savedVideoModels.length} 个本地视频`);
        }
      }
    } catch (error) {
      hilog.error(DOMAIN, 'testTag', '%{public}s', `加载保存的视频失败: ${JSON.stringify(error)}`);
    }
  }

  // 保存视频列表到本地
  private async saveVideoList(): Promise<void> {
    try {
      // 只保存本地视频（所有视频都是本地文件）
      const localVideosData: VideoInfoDataModel[] = this.videoInfoList
        .filter(v => v.isLocalFile)
        .map(v => {
          const data: VideoInfoDataModel = {
            uri: v.uri,
            title: v.title,
            thumbnail: v.thumbnail,
            duration: v.duration,
            filePath: v.filePath,
            isLocalFile: v.isLocalFile,
            addTime: v.addTime  // 保存添加时间
          };
          return data;
        });
      
      const context = getContext(this) as common.UIAbilityContext;
      
      // 保存本地视频
      if (localVideosData.length > 0) {
        const localJson = JSON.stringify(localVideosData);
        await VideoStorageUtil.saveVideoList(context, localJson);
        hilog.info(DOMAIN, 'testTag', '%{public}s', `保存了 ${localVideosData.length} 个本地视频`);
      }
    } catch (error) {
      hilog.error(DOMAIN, 'testTag', '%{public}s', `保存视频列表失败: ${JSON.stringify(error)}`);
    }
  }

  getScreenWidth() {
    display.getAllDisplays((err: BusinessError, data: Array<display.Display>) => {
      const errCode: number = err.code;
      if (errCode) {
        hilog.error(DOMAIN, 'testTag', '%{public}s',
          `Failed to obtain all the display objects. Code: ${err.code}, message: ${err.message}`);
        return;
      }
      this.screenWidth = this.getUIContext().px2vp(data[0].width);
      hilog.info(DOMAIN, 'testTag', '%{public}s', 'this.screenWidth:' + this.screenWidth);
    });
  }

  build() {
    Column() {
      // 根据当前标签页显示不同内容
      if (this.currentTab === 0) {
        // 视频标签页
        if (this.showVideoLibrary) {
          // 显示视频库
          VideoLibrary({
            videoList: $videoInfoList,
            selectedVideoIndex: $selectedVideoIndex,
            onVideoSelected: (index: number) => {
              hilog.info(DOMAIN, 'testTag', '%{public}s', `视频被选中: ${index}, 当前视频列表长度: ${this.videoInfoList.length}`);
              // 确保索引在有效范围内
              if (index >= 0 && index < this.videoInfoList.length) {
                this.selectedVideoIndex = index;
                this.showVideoLibrary = false;
                // 使用swiperController跳转到指定索引
                setTimeout(() => {
                  this.swiperController.changeIndex(index, false);
                  hilog.info(DOMAIN, 'testTag', '%{public}s', `Swiper跳转到索引: ${index}`);
                }, 100);
              } else {
                hilog.error(DOMAIN, 'testTag', '%{public}s', `无效的视频索引: ${index}`);
              }
            },
            onVideosAdded: (newVideos: Array<VideoDataModel>) => {
              hilog.info(DOMAIN, 'testTag', '%{public}s', `添加了 ${newVideos.length} 个新视频`);
              this.videoInfoList = [...this.videoInfoList, ...newVideos];
              prompt.showToast({
                message: `已添加 ${newVideos.length} 个视频到库中`,
                duration: 2000
              });
              // 保存视频列表到本地
              this.saveVideoList();
            },
            onVideoNameChanged: (index: number, newName: string) => {
              hilog.info(DOMAIN, 'testTag', '%{public}s', `修改视频名称: 索引=${index}, 新名称=${newName}`);
              // 确保索引在有效范围内
              if (index >= 0 && index < this.videoInfoList.length) {
                // 创建新的视频对象（深拷贝）
                const oldVideo = this.videoInfoList[index];
                const updatedVideo = new VideoDataModel({
                  uri: oldVideo.uri,
                  title: newName,
                  thumbnail: oldVideo.thumbnail,
                  duration: oldVideo.duration,
                  filePath: oldVideo.filePath,
                  isLocalFile: oldVideo.isLocalFile,
                  addTime: oldVideo.addTime  // 保留添加时间
                });
                
                // 替换数组中的对应元素
                const updatedList = [...this.videoInfoList];
                updatedList[index] = updatedVideo;
                this.videoInfoList = updatedList;
                
                hilog.info(DOMAIN, 'testTag', '%{public}s', `视频名称已更新: ${this.videoInfoList[index].title}`);
                
                // 保存视频列表到本地
                this.saveVideoList();
              }
            }
          })
        } else {
          // 显示视频播放器
          Stack() {
            Column() {
              // [Start cachedCount]
              Swiper(this.swiperController) {
                LazyForEach(new MyDataSource(this.videoInfoList), (item: VideoDataModel, index: number) => {
                  VideoPlayer({
                    isFullLandscapeScreen: this.isFullLandscapeScreen, // fullLandscapeScreen state
                    videoIndex: index, // Video index
                    activeIndex: this.selectedVideoIndex, // Index of the currently playing video
                    screenWidth: this.screenWidth, // Screen width
                    videoList: this.videoInfoList // Video list from parent
                  })
                }, (item: VideoDataModel) => item.uri.toString())
              }
              // [StartExclude onAnimationStart]
              .cachedCount(CommonConstants.CACHED_COUNT)
              // [End cachedCount]
              .vertical(true)
              .loop(true)
              .curve(Curve.Linear)
              .duration(CommonConstants.SWIPER_DURATION)
              .indicator(false)
              // [EndExclude onAnimationStart]
              .onAnimationStart((index: number, targetIndex: number) => {
                hilog.info(DOMAIN, 'testTag', '%{public}s',
                  `onAnimationStart index:${index} , targetIndex: ${targetIndex}`);
                this.selectedVideoIndex = targetIndex; // Update current video index.
              })
            }
            .backgroundColor(Color.Black)
            .height('100%')

            // 返回按钮（竖屏时显示）
            if (!this.isFullLandscapeScreen) {
              Row() {
                Button({ type: ButtonType.Circle }) {
                  Image($r('sys.media.ohos_ic_public_arrow_left'))
                    .fillColor(Color.White)
                    .width(24)
                    .height(24)
                }
                .width(48)
                .height(48)
                .backgroundColor('rgba(0, 0, 0, 0.5)')
                .onClick(() => {
                  this.showVideoLibrary = true;
                })
                
                Text(this.videoInfoList[this.selectedVideoIndex]?.title || '视频播放')
                  .fontSize(18)
                  .fontColor(Color.White)
                  .margin({ left: 16 })
                
                Blank()
              }
              .width('100%')
              .height(60)
              .padding({ left: 16, right: 16 })
              .justifyContent(FlexAlign.Start)
              .backgroundColor('rgba(0, 0, 0, 0.3)')
              .position({ x: 0, y: 48 }) // 距离顶部48vp，避免与状态栏冲突
              .zIndex(10)
            }
          }
        }
      } else {
        // 我的标签页
        MyPage()
      }
      
      // 底部导航栏（仅在视频库或我的页面时显示，播放视频时隐藏）
      if (this.currentTab === 0 && !this.showVideoLibrary) {
        // 播放视频时不显示底部导航栏
      } else {
        TabBar({ currentTab: $currentTab })
      }
    }
    .width('100%')
    .height('100%')
  }
}
