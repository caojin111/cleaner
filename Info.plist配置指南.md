# Info.plist配置指南

## 问题解答

### 为什么Info.plist文件是空的？

您的项目设置了`GENERATE_INFOPLIST_FILE = YES`，这意味着Xcode会自动生成Info.plist文件。但是，为了确保所有必要的配置都正确，我们手动创建了一个完整的Info.plist文件。

## 配置方法

### 方法1：使用手动创建的Info.plist文件（推荐）

我已经为您创建了一个完整的Info.plist文件，包含了应用所需的所有配置。这个文件包括：

#### 基本信息
- **CFBundleDisplayName**: "CleanUp AI" - 应用显示名称
- **CFBundleIdentifier**: "CleanUpAi.CleanUpAi" - 应用标识符
- **CFBundleVersion**: "1.0.0" - 构建版本
- **CFBundleShortVersionString**: "1.0.0" - 营销版本

#### 权限描述（App Store审核必需）
- **NSPhotoLibraryUsageDescription**: 照片库访问权限描述
- **NSPhotoLibraryAddUsageDescription**: 照片库写入权限描述
- **NSUserNotificationsUsageDescription**: 通知权限描述

#### 应用配置
- **UIApplicationSceneManifest**: SwiftUI应用场景配置
- **UISupportedInterfaceOrientations**: 支持的设备方向
- **CFBundleIcons**: 应用图标配置
- **UILaunchScreen**: 启动屏幕配置

#### 网络和安全
- **NSAppTransportSecurity**: 网络安全配置
- **UIBackgroundModes**: 后台模式配置

#### 本地化
- **CFBundleLocalizations**: 支持的语言
- **CFBundleDevelopmentRegion**: 开发区域

### 方法2：在Xcode项目设置中配置

如果您更喜欢在Xcode中配置，可以：

1. **打开Xcode项目**
2. **选择项目** → **选择目标** → **Info标签**
3. **在"Custom iOS Target Properties"中添加以下键值对**：

#### 基本信息
```
Bundle display name: CleanUp AI
Bundle identifier: CleanUpAi.CleanUpAi
Bundle version: 1.0.0
Bundle version string (short): 1.0.0
```

#### 权限描述
```
Privacy - Photo Library Usage Description: CleanUp AI needs access to your photo library to analyze and clean duplicate photos. This helps you free up storage space and organize your photos better.

Privacy - Photo Library Additions Usage Description: CleanUp AI needs access to save cleaned photos back to your library.

Privacy - User Notifications Usage Description: CleanUp AI sends notifications to remind you to clean your photos regularly and keep your device storage optimized.
```

#### 应用配置
```
Application Scene Manifest: Dictionary
  - Enable Multiple Windows: NO
  - Scene Configuration: Dictionary
    - Application Session Role: Dictionary
      - Item 0: Dictionary
        - Configuration Name: Default Configuration
        - Delegate Class Name: $(PRODUCT_MODULE_NAME).SceneDelegate

Supported interface orientations: Array
  - Item 0: UIInterfaceOrientationPortrait

Supported interface orientations (iPad): Array
  - Item 0: UIInterfaceOrientationPortrait
  - Item 1: UIInterfaceOrientationPortraitUpsideDown
  - Item 2: UIInterfaceOrientationLandscapeLeft
  - Item 3: UIInterfaceOrientationLandscapeRight
```

## 重要配置说明

### 1. 权限描述的重要性

App Store审核时，如果应用请求权限但没有提供清晰的描述，会被拒绝。我们的描述：

- **照片库访问**: 明确说明用于分析和清理重复照片
- **照片库写入**: 说明用于保存清理后的照片
- **通知权限**: 说明用于发送清理提醒

### 2. Bundle Identifier

确保Bundle Identifier与您在App Store Connect中创建的应用ID一致：
- 当前配置: `CleanUpAi.CleanUpAi`
- 如果不同，请更新为您的实际Bundle ID

### 3. 版本号

- **CFBundleVersion**: 构建版本，每次构建递增
- **CFBundleShortVersionString**: 营销版本，用户看到的版本号

### 4. 网络安全配置

配置了Firebase的网络访问权限，确保应用可以正常连接Firebase服务。

## 验证配置

### 1. 编译测试
- 清理项目 (Cmd+Shift+K)
- 重新构建 (Cmd+B)
- 确保没有编译错误

### 2. 功能测试
- 测试权限请求是否正常
- 测试通知功能
- 测试照片访问功能

### 3. 真机测试
- 在真机上安装应用
- 测试所有功能是否正常
- 检查权限描述是否正确显示

## 常见问题

### Q: 权限描述不显示怎么办？
A: 确保权限描述键名正确，并且描述文本不为空。

### Q: Bundle Identifier不匹配怎么办？
A: 在Xcode项目设置中更新Bundle Identifier，确保与App Store Connect中的一致。

### Q: 版本号如何管理？
A: 每次发布新版本时，更新CFBundleShortVersionString；每次构建时，可以更新CFBundleVersion。

## 下一步

1. **验证配置**: 确保Info.plist配置正确
2. **测试功能**: 在真机上测试所有功能
3. **更新版本**: 准备发布时更新版本号
4. **提交审核**: 确保所有配置都正确后提交App Store审核

现在您的Info.plist文件已经配置完整，包含了App Store审核所需的所有信息！ 