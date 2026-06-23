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

export interface VideoInfoDataModel {
  uri: ResourceStr;
  title?: string;
  thumbnail?: ResourceStr;
  duration?: number;
  filePath?: string; // 本地文件路径
  isLocalFile?: boolean; // 是否为本地文件
  addTime?: number; // 添加时间戳
}

export class VideoDataModel {
  public uri: ResourceStr;
  public title: string;
  public thumbnail: ResourceStr;
  public duration: number;
  public filePath: string;
  public isLocalFile: boolean;
  public addTime: number; // 添加时间戳

  constructor(item: VideoInfoDataModel) {
    this.uri = item.uri;
    this.title = item.title || '未命名视频';
    this.thumbnail = item.thumbnail || $r('app.media.background');
    this.duration = item.duration || 0;
    this.filePath = item.filePath || '';
    this.isLocalFile = item.isLocalFile || false;
    this.addTime = item.addTime || Date.now(); // 默认使用当前时间
  }
}

// LazyForEach model.
class BasicDataSource implements IDataSource {
  private listeners: DataChangeListener[] = [];

  public totalCount(): number {
    return this.listeners.length;
  }

  public getData(index: number): VideoDataModel | DataChangeListener {
    return this.listeners[index];
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    if (this.listeners.indexOf(listener) < 0) {
      this.listeners.push(listener);
    }
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    const pos = this.listeners.indexOf(listener);
    if (pos >= 0) {
      this.listeners.splice(pos, 1);
    }
  }

  notifyDataReload(): void {
    this.listeners.forEach(listener => {
      listener.onDataReloaded();
    })
  }

  notifyDataAdd(index: number): void {
    this.listeners.forEach(listener => {
      listener.onDataAdd(index);
    })
  }

  notifyDataChange(index: number): void {
    this.listeners.forEach(listener => {
      listener.onDataChange(index);
    })
  }
}

export class MyDataSource extends BasicDataSource {
  public dataArray: VideoDataModel[] = [];

  constructor(ele: VideoDataModel[]) {
    super();
    this.dataArray = ele;
  }

  public totalCount(): number {
    return this.dataArray.length;
  }

  public getData(index: number): VideoDataModel {
    return this.dataArray[index];
  }

  public addData(index: number, data: VideoDataModel): void {
    this.dataArray.splice(index, 0, data);
    this.notifyDataAdd(index);
  }
}