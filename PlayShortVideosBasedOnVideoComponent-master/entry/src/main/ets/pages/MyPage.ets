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
 * "我的"页面
 * 包含播放设置和管理设置等功能
 */
@Component
export struct MyPage {
  build() {
    Column() {
      // 顶部标题栏
      Row() {
        Text('我的')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.Black)
          .margin({ left: 16 })
      }
      .width('100%')
      .height(60)
      .backgroundColor(Color.White)
      
      // 设置列表
      Column() {
        // 播放设置
        this.SettingItem(
          $r('sys.media.ohos_ic_public_video'),
          '播放设置',
          () => {
            // 播放设置点击事件（暂不处理）
          }
        )
        
        // 分隔线
        Divider()
          .width('100%')
          .height(1)
          .color('#E5E5E5')
          .margin({ left: 56 })
        
        // 管理设置
        this.SettingItem(
          $r('sys.media.ohos_ic_public_add'),
          '管理设置',
          () => {
            // 管理设置点击事件（暂不处理）
          }
        )
      }
      .width('100%')
      .backgroundColor(Color.White)
      .margin({ top: 16 })
      .borderRadius(8)
      
      // 底部占位
      Blank()
    }
    .width('100%')
    .layoutWeight(1)
    .backgroundColor('#F5F5F5')
  }
  
  // 设置项组件
  @Builder
  SettingItem(icon: Resource, title: string, onClick: () => void) {
    Row() {
      // 图标
      Image(icon)
        .width(24)
        .height(24)
        .fillColor('#333333')
        .margin({ left: 16 })
      
      // 标题
      Text(title)
        .fontSize(16)
        .fontColor(Color.Black)
        .margin({ left: 16 })
      
      Blank()
      
      // 右箭头
      Image($r('sys.media.ohos_ic_public_arrow_right'))
        .width(20)
        .height(20)
        .fillColor('#999999')
        .margin({ right: 16 })
    }
    .width('100%')
    .height(56)
    .backgroundColor(Color.White)
    .onClick(onClick)
  }
}
