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

/**
 * 底部导航栏组件
 * 包含"视频"和"我的"两个标签页
 */
@Component
export struct TabBar {
  @Link currentTab: number; // 当前选中的标签索引：0-视频，1-我的
  
  build() {
    Row() {
      // 视频标签
      Column() {
        Image(this.currentTab === 0 ? $r('sys.media.ohos_ic_public_video') : $r('sys.media.ohos_ic_public_video'))
          .width(24)
          .height(24)
          .fillColor(this.currentTab === 0 ? '#007DFF' : '#999999')
        
        Text('视频')
          .fontSize(12)
          .fontColor(this.currentTab === 0 ? '#007DFF' : '#999999')
          .margin({ top: 4 })
      }
      .width('50%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .onClick(() => {
        this.currentTab = 0;
      })
      
      // 我的标签
      Column() {
        Image($r('app.media.menu_icon_user_avatar'))
          .width(24)
          .height(24)
          .objectFit(ImageFit.Cover)
        
        Text('我的')
          .fontSize(12)
          .fontColor(this.currentTab === 1 ? '#007DFF' : '#999999')
          .margin({ top: 4 })
      }
      .width('50%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .onClick(() => {
        this.currentTab = 1;
      })
    }
    .width('100%')
    .height(56)
    .backgroundColor(Color.White)
    .border({ width: { top: 1 }, color: { top: '#E5E5E5' } })
  }
}
