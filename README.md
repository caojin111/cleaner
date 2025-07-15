# CleanUp AI - 老年人友好的手机清理应用

## 项目简介

CleanUp AI 是一款专为老年人设计的iOS手机清理应用，采用Swift + SwiftUI开发，提供智能的重复文件检测和简单易用的滑动清理操作。

## 🎯 项目特色

### 老年人友好设计
- **大字体设计**: 专门适配老年人视力需求
- **简化交互**: 左滑删除，右滑保留的直观操作
- **高对比度**: 清晰的视觉效果
- **语音反馈**: 触觉反馈增强操作确认

### 智能清理功能
- **AI算法**: 基于哈希算法检测重复文件
- **安全删除**: 回收站机制防止误删
- **批量处理**: 高效处理大量文件
- **空间统计**: 实时显示可节省的存储空间

## 📱 应用架构

### 页面流程
```
启动页面 → 引导页面(4页) → 订阅页面 → 主界面(5个Tab)
```

### 核心功能模块
1. **照片清理** - 主要功能，滑动卡片式交互
2. **视频清理** - 待开发
3. **音频清理** - 待开发  
4. **文件清理** - 待开发
5. **回收站** - 安全删除和恢复

### 技术架构
```
├── Views/ (界面层)
│   ├── Splash/ (启动页)
│   ├── Onboarding/ (引导页)
│   ├── Paywall/ (订阅页)
│   ├── Main/ (主界面)
│   └── RecycleBin/ (回收站)
├── Models/ (数据模型)
├── Services/ (业务服务)
├── Utils/ (工具类)
└── Info.plist (权限配置)
```

## 🔧 技术实现

### 开发环境
- **平台**: iOS 16.0+
- **语言**: Swift 5.0+
- **框架**: SwiftUI
- **工具**: Xcode

### 核心技术
- **Photos Framework**: 照片库访问
- **DocumentPicker**: 文件选择
- **OSLog**: 日志记录
- **UserNotifications**: 通知推送
- **CoreData**: 数据持久化

### 权限管理
```xml
<!-- 必需权限 -->
<key>NSPhotoLibraryUsageDescription</key>
<string>需要访问照片库来分析和清理重复图片</string>

<key>NSCameraUsageDescription</key>
<string>需要访问相机来管理照片</string>

<!-- 不需要的权限 -->
<!-- NSMicrophoneUsageDescription (不录制音频) -->
<!-- NSAppleMusicUsageDescription (不访问音乐库) -->
```

## 🎨 界面设计

### 老年人UI规范
```swift
// 字体大小
.seniorLargeTitle = 32pt
.seniorTitle = 24pt  
.seniorBody = 20pt
.seniorCaption = 16pt

// 颜色方案
.seniorPrimary = 蓝色主题色
.seniorBackground = 浅灰背景
.seniorText = 深色文字
.seniorSuccess = 绿色
.seniorDanger = 红色
```

### 交互设计
- **滑动阈值**: 100pt
- **动画时长**: 0.3s
- **按钮大小**: 最小50pt高度
- **间距规范**: 16pt基础间距

## ⚡ 主要功能实现

### 1. 启动流程
- **Splash页面**: Logo展示 + 开发者信息
- **权限申请**: 照片库 + 通知权限
- **照片分析**: 后台智能分析重复项
- **统计展示**: 实时显示分析结果

### 2. 核心清理功能
```swift
// 滑动卡片交互
SwipeablePhotoCard(
    item: mediaItem,
    onSwipeLeft: { item in handleDelete(item) },    // 左滑删除
    onSwipeRight: { item in handleKeep(item) }      // 右滑保留
)
```

### 3. 安全删除机制
- **两阶段删除**: 先移至回收站，再永久删除
- **恢复功能**: 支持从回收站恢复文件
- **批量操作**: 支持批量删除和恢复

### 4. 订阅系统
- **三档价格**: 年度/月度/周度订阅
- **免费试用**: 7天免费试用
- **功能对比**: Pro功能清晰展示

## 📊 开发进度

### ✅ 已完成
- [x] 项目架构搭建
- [x] 数据模型定义  
- [x] 核心服务实现
- [x] 启动页面
- [x] 引导页面(4页)
- [x] 订阅页面
- [x] 照片清理主界面
- [x] 回收站功能
- [x] 权限配置

### 🔄 进行中
- [ ] 真实照片显示
- [ ] 哈希算法优化
- [ ] 性能测试

### 📋 待开发
- [ ] 视频清理功能
- [ ] 音频清理功能
- [ ] 文件清理功能
- [ ] 应用内购买集成
- [ ] 云端备份功能

## 🚀 部署说明

### 编译要求
1. macOS系统
2. Xcode 14.0+
3. iOS 16.0+ 模拟器或真机

### 运行步骤
1. 打开 `CleanUpAi.xcodeproj`
2. 选择目标设备
3. 点击 Run 按钮

### 注意事项
- 需要在真机上测试权限功能
- 照片库权限需要用户授权
- 订阅功能需要配置App Store Connect

## 📄 许可证

本项目为演示项目，遵循MIT许可证。

## 👥 开发团队

Made with LazyCat

---

## 🔍 代码亮点

### 1. 老年人友好设计
```swift
extension Font {
    static let seniorLargeTitle = Font.system(size: 32, weight: .bold)
    static let seniorTitle = Font.system(size: 24, weight: .semibold)
    // ... 专门为老年人优化的字体系统
}
```

### 2. 智能滑动交互
```swift
private func handleSwipeEnd(_ value: DragGesture.Value) {
    if value.translation.x < -Constants.swipeThreshold {
        // 左滑删除 - 精确的手势识别
        onSwipeLeft(item)
    } else if value.translation.x > Constants.swipeThreshold {
        // 右滑保留 - 防误操作设计
        onSwipeRight(item)
    }
}
```

### 3. 完整的日志系统
```swift
extension Logger {
    static func logPageNavigation(from: String, to: String) {
        ui.info("📱 页面导航: \(from) → \(to)")
    }
    // ... 全面的日志记录，便于问题追踪
}
```

这个项目充分体现了对老年人用户群体的关怀，在技术实现上兼顾了易用性、安全性和性能优化。
 