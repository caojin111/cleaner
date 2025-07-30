# Onboarding第二页权限多语言修复说明

## 问题描述

在Onboarding第二页中，存在以下多语言问题：

1. **权限状态显示问题**：在拒绝给图库权限后，图库权限状态文本区域应该展示多语言"not_set"这一条
2. **权限设置弹窗硬编码问题**：在都拒绝提供权限的情况下，再次点击granted弹出的弹窗内：
   - "权限设置"硬编码应该展示"title"的多语言
   - "去设置"的硬编码应该展示"gotosetting"的多语言
   - "取消"应该展示"cancel"的多语言

## 问题分析

### 1. 权限状态文本问题
**原因**：在`PermissionManager.swift`的`getPermissionStatusText`方法中，照片库权限被拒绝时返回的是`"onboarding.page2.partial_authorized"`，而不是`"onboarding.page2.not_set"`。

### 2. 弹窗多语言硬编码问题
**原因**：在`OnboardingPage2View.swift`中，权限设置弹窗的标题和按钮文本都是硬编码的中文，没有使用多语言系统。

## 解决方案

### 1. 添加缺失的多语言键

在`Localizable.json`中添加了以下多语言键：

#### 英文版本：
```json
"onboarding": {
  "page2": {
    "title": "Permission Settings",
    "gotosetting": "Go to Settings",
    "cancel": "Cancel"
  }
}
```

#### 中文版本：
```json
"onboarding": {
  "page2": {
    "title": "权限设置",
    "gotosetting": "去设置",
    "cancel": "取消"
  }
}
```

### 2. 修复权限状态文本逻辑

修改`PermissionManager.swift`中的`getPermissionStatusText`方法：

```swift
func getPermissionStatusText(for permission: String) -> String {
    switch permission {
    case "photos":
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .authorized, .limited:
            return "onboarding.page2.authorized".localized
        case .denied, .restricted:
            return "onboarding.page2.not_set".localized  // 修复：拒绝权限时显示"not_set"
        case .notDetermined:
            return "onboarding.page2.not_set".localized
        @unknown default:
            return "onboarding.page2.not_set".localized
        }
    case "notifications":
        // ... 通知权限逻辑保持不变
    case "files":
        return "onboarding.page2.not_set".localized  // 修复：文件权限也显示"not_set"
    default:
        return "onboarding.page2.not_set".localized  // 修复：默认情况也显示"not_set"
    }
}
```

### 3. 修复弹窗多语言硬编码

修改`OnboardingPage2View.swift`中的弹窗代码：

```swift
// 修复前：
.alert("权限设置", isPresented: $showPermissionAlert) {
    Button("去设置") {
        permissionManager.openAppSettings()
    }
    Button("取消", role: .cancel) { }
} message: {
    Text("onboarding.page2.permission_required".localized)
}

// 修复后：
.alert("onboarding.page2.title".localized, isPresented: $showPermissionAlert) {
    Button("onboarding.page2.gotosetting".localized) {
        permissionManager.openAppSettings()
    }
    Button("onboarding.page2.cancel".localized, role: .cancel) { }
} message: {
    Text("onboarding.page2.permission_required".localized)
}
```

## 修复效果

### 修复前的问题：
- ❌ 拒绝照片库权限后显示"partial_authorized"而不是"not_set"
- ❌ 权限设置弹窗标题硬编码为"权限设置"
- ❌ 弹窗按钮"去设置"和"取消"都是硬编码中文

### 修复后的效果：
- ✅ 拒绝照片库权限后正确显示"not_set"多语言文本
- ✅ 权限设置弹窗标题使用多语言"title"键
- ✅ 弹窗按钮"去设置"使用多语言"gotosetting"键
- ✅ 弹窗按钮"取消"使用多语言"cancel"键

## 多语言支持

### 英文界面：
- 弹窗标题：Permission Settings
- 去设置按钮：Go to Settings
- 取消按钮：Cancel
- 权限状态：Not Set

### 中文界面：
- 弹窗标题：权限设置
- 去设置按钮：去设置
- 取消按钮：取消
- 权限状态：Not Set

## 技术要点

### 1. 权限状态一致性
确保所有权限状态（照片库、通知、文件）在未授权时都显示统一的"not_set"文本，提供一致的用户体验。

### 2. 多语言完整性
所有用户可见的文本都通过多语言系统管理，支持中英文切换，提升国际化体验。

### 3. 代码维护性
通过使用多语言键而不是硬编码文本，提高了代码的可维护性和扩展性。

## 测试建议

### 测试场景：
1. **权限拒绝场景**：拒绝照片库权限，检查状态文本是否正确显示"not_set"
2. **弹窗多语言**：在不同语言环境下测试权限设置弹窗的文本显示
3. **权限状态一致性**：测试各种权限状态下的文本显示是否一致

### 验证要点：
- 权限状态文本是否正确显示
- 弹窗标题和按钮是否使用多语言
- 中英文切换是否正常工作

## 总结

通过这次修复，Onboarding第二页的权限相关功能现在完全支持多语言，并且权限状态显示逻辑更加一致和准确。这提升了应用的国际化和用户体验质量。 