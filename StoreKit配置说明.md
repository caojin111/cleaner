# StoreKit 订阅配置说明

## 概述
已成功配置了三个订阅产品的ID和价格获取功能，使用StoreKit 2框架实现。

## 产品ID配置

### 订阅产品
1. **年订阅**: `yearly_29.99` - $29.99/年
2. **月订阅**: `monthly_9.99` - $9.99/月  
3. **周订阅**: `weekly_2.99` - $2.99/周

## 文件结构

### 1. StoreKitManager.swift
- 位置: `CleanUpAi/Services/StoreKitManager.swift`
- 功能: 管理StoreKit产品加载、价格获取和购买流程
- 主要方法:
  - `loadProducts()`: 加载产品信息
  - `getFormattedPrice(for:)`: 获取格式化价格
  - `purchase(_:)`: 执行购买

### 2. 更新的文件
- **MediaItem.swift**: 更新SubscriptionPlan模型，使用StoreKitManager获取价格
- **PaywallView.swift**: 集成StoreKitManager，实现动态价格显示和真实购买
- **Localizable.json**: 添加多语言支持的单位文本

### 3. StoreKit配置文件
- **Configuration.storekit**: 用于Xcode测试的StoreKit配置文件

## 主要功能

### 价格获取
```swift
// 获取年订阅价格
let yearlyPrice = StoreKitManager.shared.yearlyPrice

// 获取月订阅价格  
let monthlyPrice = StoreKitManager.shared.monthlyPrice

// 获取周订阅价格
let weeklyPrice = StoreKitManager.shared.weeklyPrice
```

### 产品加载
- 应用启动时自动加载产品信息
- 支持加载状态显示和错误处理
- 实时更新价格显示

### 购买流程
- 集成真实的StoreKit购买流程
- 支持交易验证和完成
- 错误处理和用户取消处理

## 使用方法

### 1. 在PaywallView中
- 自动显示从App Store获取的真实价格
- 支持加载状态和错误重试
- 集成真实的购买流程

### 2. 价格显示
- 价格会根据用户所在地区自动本地化
- 支持不同货币格式
- 实时从App Store获取最新价格

### 3. 测试
- 使用Configuration.storekit文件在Xcode中进行测试
- 支持模拟购买和交易验证
- 可以在不同地区测试价格显示

## 注意事项

1. **App Store Connect配置**: 确保在App Store Connect中正确配置了这三个产品ID
2. **沙盒测试**: 使用测试账号在沙盒环境中测试购买流程
3. **价格更新**: 价格变更需要等待App Store审核通过
4. **地区支持**: 确保在目标地区都配置了相应的价格

## 下一步

1. 在App Store Connect中创建对应的订阅产品
2. 配置不同地区的价格
3. 设置订阅组和介绍优惠
4. 测试购买流程
5. 提交审核

## 调试信息

StoreKitManager会输出详细的调试日志，包括：
- 产品加载状态
- 价格获取结果
- 购买流程状态
- 错误信息

可以通过Xcode控制台查看这些日志信息。 