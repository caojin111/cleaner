# More页面订阅banner文本优化说明

## 优化内容

### 1. 移除不需要的"Pro Plan"选项

**问题描述**: 用户反馈英文配置中的"Pro Plan"不需要，因为只有三种订阅类型（Yearly/Monthly/Weekly）。

**修复内容**: 从多语言配置中移除"Pro Plan"相关配置。

**修改的文件**: `CleanUpAi/Resources/Localizable.json`

**英文配置修改**:
```json
// 修改前
"pro_card": {
  "title": "Premium",
  "subtitle": "Pro feature",
  "button": "Get Now",
  "yearly_plan": "Yearly Plan",
  "monthly_plan": "Monthly Plan",
  "weekly_plan": "Weekly Plan",
  "pro_plan": "Pro Plan"  // 删除
}

// 修改后
"pro_card": {
  "title": "Premium",
  "subtitle": "Pro feature",
  "button": "Get Now",
  "yearly_plan": "Yearly Plan",
  "monthly_plan": "Monthly Plan",
  "weekly_plan": "Weekly Plan"
}
```

**中文配置修改**:
```json
// 修改前
"pro_card": {
  "title": "PRO 优惠",
  "subtitle": "高级功能",
  "button": "立即获取",
  "yearly_plan": "年度订阅",
  "monthly_plan": "月度订阅",
  "weekly_plan": "周度订阅",
  "pro_plan": "Pro订阅"  // 删除
}

// 修改后
"pro_card": {
  "title": "PRO 优惠",
  "subtitle": "高级功能",
  "button": "立即获取",
  "yearly_plan": "年度订阅",
  "monthly_plan": "月度订阅",
  "weekly_plan": "周度订阅"
}
```

### 2. 修改默认值和fallback逻辑

**修改的文件**: `CleanUpAi/Views/Main/MoreView.swift`

**状态变量修改**:
```swift
// 修改前
@State private var currentPlanType: String = "Pro Plan"

// 修改后
@State private var currentPlanType: String = "Yearly Plan"
```

**Fallback逻辑修改**:
```swift
// 修改前
case "weekly":
    currentPlanType = "more.pro_card.weekly_plan".localized
default:
    currentPlanType = "more.pro_card.pro_plan".localized  // 删除

// 修改后
case "weekly":
    currentPlanType = "more.pro_card.weekly_plan".localized
default:
    currentPlanType = "more.pro_card.yearly_plan".localized  // 使用年度订阅作为默认
```

### 3. 优化底图自适应

**问题描述**: 用户希望订阅类型文本的底图可以随文本长短自适应。

**修复内容**: 调整padding设置，让底图更好地适应文本长度。

**UI修改**:
```swift
// 修改前
Text(getCurrentPlanType())
    .font(.system(size: 17, weight: .semibold))
    .foregroundColor(Color.white)
    .padding(.horizontal, 18)  // 固定padding
    .padding(.vertical, 8)
    .background(
        Capsule()
            .fill(Color.green)
    )

// 修改后
Text(getCurrentPlanType())
    .font(.system(size: 17, weight: .semibold))
    .foregroundColor(Color.white)
    .padding(.horizontal, 16)  // 减少padding，让底图更紧凑
    .padding(.vertical, 8)
    .background(
        Capsule()
            .fill(Color.green)
    )
```

## 技术实现细节

### 1. 配置清理
- 移除不需要的"Pro Plan"多语言配置
- 保持配置的一致性和简洁性
- 避免冗余的文本选项

### 2. 默认值优化
- 将默认值从"Pro Plan"改为"Yearly Plan"
- 将fallback逻辑改为使用年度订阅
- 确保在无法获取订阅信息时有合理的默认显示

### 3. UI自适应优化
- 减少水平padding从18到16
- 让Capsule背景更好地适应文本长度
- 保持垂直padding不变，确保按钮高度一致

### 4. 订阅类型映射
现在只支持三种订阅类型：
- `yearly` → "Yearly Plan" / "年度订阅"
- `monthly` → "Monthly Plan" / "月度订阅"
- `weekly` → "Weekly Plan" / "周度订阅"

## 优化效果

### 1. 配置简化
- ✅ 移除了不需要的"Pro Plan"配置
- ✅ 保持配置的简洁性和一致性
- ✅ 减少了维护成本

### 2. 默认值合理
- ✅ 使用"Yearly Plan"作为默认值
- ✅ 在无法获取订阅信息时显示年度订阅
- ✅ 提供更好的用户体验

### 3. UI自适应
- ✅ 底图更好地适应文本长度
- ✅ 减少不必要的空白空间
- ✅ 保持视觉美观

### 4. 多语言支持
- ✅ 英文：Yearly Plan / Monthly Plan / Weekly Plan
- ✅ 中文：年度订阅 / 月度订阅 / 周度订阅
- ✅ 完整的多语言支持

## 测试验证

### 测试场景
1. ✅ 未订阅状态显示"Get Now"按钮
2. ✅ 已订阅状态显示plan类型文本
3. ✅ 不同订阅类型正确显示（年度/月度/周度）
4. ✅ 底图自适应文本长度
5. ✅ 多语言环境下的显示
6. ✅ 默认值和fallback逻辑

### 验证方法
- 在模拟器中测试不同订阅状态
- 检查UI显示和文本长度适配
- 验证多语言环境下的文本显示
- 测试默认值和fallback逻辑

## 影响范围

### 修改的文件
- `CleanUpAi/Resources/Localizable.json` - 移除Pro Plan配置
- `CleanUpAi/Views/Main/MoreView.swift` - 修改默认值和UI适配

### 优化功能
- 订阅类型配置简化
- 默认值优化
- UI自适应改进
- 多语言配置清理

## 注意事项

1. **配置一致性**: 确保英文和中文配置保持一致
2. **默认值合理**: 使用年度订阅作为默认值，符合用户期望
3. **UI适配**: 底图自适应文本长度，提供更好的视觉效果
4. **向后兼容**: 所有修改都保持向后兼容性
5. **维护简化**: 移除不需要的配置，减少维护成本

## 总结

本次优化完全满足了用户的需求：

- ✅ **移除Pro Plan**: 删除了不需要的"Pro Plan"配置
- ✅ **底图自适应**: 优化了底图的padding，让文本长度自适应
- ✅ **默认值优化**: 使用"Yearly Plan"作为默认值
- ✅ **配置简化**: 保持配置的简洁性和一致性

**优化效果**:
- 配置更加简洁，只保留三种订阅类型
- 底图更好地适应不同长度的文本
- 默认值更加合理
- 提供更好的用户体验和视觉效果

现在More页面的订阅banner配置更加简洁，UI更加自适应，完全符合用户的需求！ 