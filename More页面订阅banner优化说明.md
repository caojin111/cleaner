# More页面订阅banner优化说明

## 需求描述

用户要求优化More页面的订阅banner：
- 如果是已订阅状态，在"Get Now"按钮处，不应该再展示"Get Now"
- 而是展示当前plan的种类，比如：yearly plan/monthly plan/weekly plan
- 并且无法被点击

## 实现方案

### 1. 修改MoreView的proCardSection

**修改前**:
```swift
Button(action: { showingPaywall = true }) {
    Text("more.pro_card.button".localized)
    // ...
}
```

**修改后**:
```swift
if userSettings.isSubscribed {
    // 已订阅状态：显示当前plan类型
    Text(getCurrentPlanType())
        .font(.system(size: 17, weight: .semibold))
        .foregroundColor(Color.white)
        .padding(.horizontal, 18)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color.green)
        )
} else {
    // 未订阅状态：显示Get Now按钮
    Button(action: { showingPaywall = true }) {
        Text("more.pro_card.button".localized)
        // ...
    }
}
```

### 2. 添加StoreKitManager方法

在`StoreKitManager`中添加获取当前订阅plan类型的方法：

```swift
/// 获取当前订阅的plan类型
func getCurrentSubscriptionPlan() async -> String? {
    for await result in Transaction.currentEntitlements {
        do {
            let transaction = try checkVerified(result)
            logger.info("找到当前订阅: \(transaction.productID)")
            
            // 根据产品ID返回对应的plan类型
            switch transaction.productID {
            case "yearly_29.99":
                return "yearly"
            case "monthly_9.99":
                return "monthly"
            case "weekly_2.99":
                return "weekly"
            default:
                return nil
            }
        } catch {
            logger.error("验证订阅失败: \(error.localizedDescription)")
        }
    }
    return nil
}
```

### 3. 添加MoreView状态管理

**新增状态变量**:
```swift
@State private var currentPlanType: String = "Pro Plan"
```

**添加获取plan类型的方法**:
```swift
private func getCurrentPlanType() -> String {
    return currentPlanType
}

private func loadCurrentPlanType() {
    Task {
        if let planType = await storeManager.getCurrentSubscriptionPlan() {
            await MainActor.run {
                switch planType {
                case "yearly":
                    currentPlanType = "more.pro_card.yearly_plan".localized
                case "monthly":
                    currentPlanType = "more.pro_card.monthly_plan".localized
                case "weekly":
                    currentPlanType = "more.pro_card.weekly_plan".localized
                default:
                    currentPlanType = "more.pro_card.pro_plan".localized
                }
            }
        }
    }
}
```

**在页面加载时获取plan类型**:
```swift
.onAppear {
    Logger.ui.debug("MoreView: 初始化更多视图")
    if userSettings.isSubscribed {
        loadCurrentPlanType()
    }
}
```

### 4. 添加多语言配置

**英文配置**:
```json
"pro_card": {
  "title": "Premium",
  "subtitle": "Enjoy pro feature",
  "button": "Get Now",
  "yearly_plan": "Yearly Plan",
  "monthly_plan": "Monthly Plan",
  "weekly_plan": "Weekly Plan",
  "pro_plan": "Pro Plan"
}
```

**中文配置**:
```json
"pro_card": {
  "title": "PRO 优惠",
  "subtitle": "高级功能",
  "button": "立即获取",
  "yearly_plan": "年度订阅",
  "monthly_plan": "月度订阅",
  "weekly_plan": "周度订阅",
  "pro_plan": "Pro订阅"
}
```

## 功能特点

### 1. 状态区分
- **未订阅状态**: 显示蓝色的"Get Now"按钮，可点击跳转到Paywall
- **已订阅状态**: 显示绿色的plan类型文本，不可点击

### 2. 动态显示
- 根据实际的订阅类型显示对应的plan名称
- 支持年度、月度、周度三种订阅类型
- 如果无法获取具体类型，显示默认的"Pro Plan"

### 3. 视觉区分
- 未订阅：蓝色按钮背景
- 已订阅：绿色文本背景
- 清晰的状态区分

### 4. 多语言支持
- 完整的中英文支持
- 根据用户设备语言自动切换

## 技术实现细节

### 1. 异步数据获取
- 使用`async/await`从StoreKit获取当前订阅信息
- 在主线程更新UI状态
- 错误处理和日志记录

### 2. 状态管理
- 使用`@State`管理当前plan类型
- 在页面加载时自动获取订阅信息
- 只在已订阅状态下获取plan类型

### 3. UI条件渲染
- 根据`userSettings.isSubscribed`状态条件渲染不同UI
- 已订阅状态显示静态文本
- 未订阅状态显示可点击按钮

### 4. 本地化支持
- 所有文本都支持多语言
- 使用`String.localized`扩展
- 统一的本地化键名管理

## 测试验证

### 测试场景
1. ✅ 未订阅状态显示"Get Now"按钮
2. ✅ 已订阅状态显示plan类型文本
3. ✅ 不同订阅类型正确显示
4. ✅ 按钮不可点击（已订阅状态）
5. ✅ 多语言环境下的显示
6. ✅ 异步数据加载

### 验证方法
- 在模拟器中测试不同订阅状态
- 检查UI显示和交互行为
- 验证多语言环境下的文本显示
- 测试异步数据加载的稳定性

## 影响范围

### 修改的文件
- `CleanUpAi/Views/Main/MoreView.swift` - 订阅banner逻辑修改
- `CleanUpAi/Services/StoreKitManager.swift` - 添加获取订阅类型方法
- `CleanUpAi/Resources/Localizable.json` - 添加多语言配置

### 新增功能
- 订阅状态动态显示
- 当前plan类型获取
- 条件UI渲染
- 多语言plan类型显示

## 注意事项

1. **异步处理**: 订阅信息获取是异步的，需要正确处理UI更新
2. **错误处理**: 如果无法获取订阅信息，显示默认文本
3. **性能优化**: 只在已订阅状态下获取plan类型
4. **用户体验**: 提供清晰的状态区分和视觉反馈
5. **向后兼容**: 所有修改都保持向后兼容性

## 总结

本次优化完全满足了用户的需求：

- ✅ **状态区分**: 已订阅和未订阅状态显示不同的UI
- ✅ **Plan类型显示**: 已订阅用户看到具体的plan类型（年度/月度/周度）
- ✅ **不可点击**: 已订阅状态的plan类型文本不可点击
- ✅ **多语言支持**: 完整的中英文支持
- ✅ **动态获取**: 从StoreKit动态获取当前订阅信息

**优化效果**:
- 未订阅用户看到"Get Now"按钮，可点击跳转到Paywall
- 已订阅用户看到当前plan类型（如"年度订阅"），不可点击
- 提供清晰的状态区分和更好的用户体验
- 支持完整的多语言环境

现在More页面的订阅banner能够根据用户的订阅状态智能显示相应的内容，提供更好的用户体验。 