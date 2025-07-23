# 如何在Xcode中添加HTML文件

## 当前状态
✅ HTML文件已移动到 `CleanUpAi/Privacy Policy.html`
❌ 文件尚未添加到Xcode项目中

## 在Xcode中添加HTML文件的步骤

### 方法一：通过Xcode界面添加
1. **打开Xcode项目**
   - 双击 `CleanUpAi.xcodeproj` 文件

2. **在项目导航器中右键点击CleanUpAi文件夹**
   - 选择 "Add Files to 'CleanUpAi'"

3. **选择HTML文件**
   - 导航到 `CleanUpAi/Privacy Policy.html`
   - 确保选中 "Add to target: CleanUpAi"
   - 点击 "Add"

### 方法二：拖拽添加
1. **打开Finder**
   - 导航到项目目录：`/Users/apple/Desktop/CleanUpAi/CleanUpAi/`

2. **拖拽文件到Xcode**
   - 将 `Privacy Policy.html` 文件拖拽到Xcode的项目导航器中
   - 确保拖拽到CleanUpAi文件夹下

## 验证添加成功
添加成功后，您应该能在Xcode中看到：
- 项目导航器中显示 `Privacy Policy.html` 文件
- 文件图标显示为HTML文件图标
- 点击文件可以在编辑器中查看内容

## 在应用中使用HTML文件

### 1. 在WebView中显示
```swift
import SwiftUI
import WebKit

struct PrivacyPolicyView: View {
    var body: some View {
        WebView(url: Bundle.main.url(forResource: "Privacy Policy", withExtension: "html")!)
    }
}

struct WebView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
    }
}
```

### 2. 在设置页面中添加链接
```swift
// 在MoreView.swift中添加
Button("隐私政策") {
    // 打开隐私政策页面
}
```

## 注意事项
- 确保文件名中的空格不会影响引用
- 如果遇到问题，可以重命名为 `PrivacyPolicy.html`（去掉空格）
- 添加后记得提交到版本控制系统

## 文件位置
当前文件位置：`CleanUpAi/Privacy Policy.html`
目标位置：Xcode项目中的CleanUpAi文件夹 