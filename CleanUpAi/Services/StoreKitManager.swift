//
//  StoreKitManager.swift
//  CleanUpAi
//
//  Created by CleanU AI Team
//

import Foundation
import StoreKit
import OSLog

@MainActor
class StoreKitManager: ObservableObject {
    static let shared = StoreKitManager()
    
    private let logger = Logger(subsystem: "com.cleanupai.app", category: "StoreKit")
    
    // 产品ID配置
    private let productIdentifiers = [
        "yearly_29.99",   // 年订阅
        "monthly_9.99",   // 月订阅
        "weekly_2.99"     // 周订阅
    ]
    
    @Published var products: [Product] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private init() {
        // 初始化时不立即加载，等待外部调用
        logger.info("StoreKitManager 初始化完成")
    }
    
    // MARK: - Product Loading
    
    /// 预加载产品信息（应用启动时调用）
    func preloadProducts() {
        logger.info("开始预加载产品信息")
        Task {
            await loadProducts()
        }
    }
    
    /// 加载产品信息
    func loadProducts() async {
        logger.info("开始加载产品信息...")
        isLoading = true
        errorMessage = nil
        
        do {
            let storeProducts = try await Product.products(for: productIdentifiers)
            
            await MainActor.run {
                self.products = storeProducts
                self.isLoading = false
                self.logger.info("成功加载 \(storeProducts.count) 个产品")
                
                // 打印产品信息用于调试
                for product in storeProducts {
                    self.logger.info("产品: \(product.id), 价格: \(product.displayPrice), 标题: \(product.displayName)")
                }
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
                self.logger.error("加载产品失败: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Product Retrieval
    
    /// 根据产品ID获取产品
    func getProduct(identifier: String) -> Product? {
        return products.first { $0.id == identifier }
    }
    
    /// 获取年订阅产品
    var yearlyProduct: Product? {
        return getProduct(identifier: "yearly_29.99")
    }
    
    /// 获取月订阅产品
    var monthlyProduct: Product? {
        return getProduct(identifier: "monthly_9.99")
    }
    
    /// 获取周订阅产品
    var weeklyProduct: Product? {
        return getProduct(identifier: "weekly_2.99")
    }
    
    // MARK: - Price Formatting
    
    /// 获取格式化的价格字符串
    func getFormattedPrice(for identifier: String) -> String {
        guard let product = getProduct(identifier: identifier) else {
            logger.warning("未找到产品: \(identifier)")
            // 如果正在加载，显示加载状态
            if isLoading {
                return "价格加载中..."
            }
            // 如果加载失败，显示默认价格
            switch identifier {
            case "yearly_29.99":
                return "$29.99"
            case "monthly_9.99":
                return "$9.99"
            case "weekly_2.99":
                return "$2.99"
            default:
                return "价格加载中..."
            }
        }
        return product.displayPrice
    }
    
    /// 获取年订阅价格
    var yearlyPrice: String {
        return getFormattedPrice(for: "yearly_29.99")
    }
    
    /// 获取月订阅价格
    var monthlyPrice: String {
        return getFormattedPrice(for: "monthly_9.99")
    }
    
    /// 获取周订阅价格
    var weeklyPrice: String {
        return getFormattedPrice(for: "weekly_2.99")
    }
    
    // MARK: - Purchase Handling
    
    /// 购买产品
    func purchase(_ product: Product) async throws -> Transaction? {
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                logger.info("购买成功: \(product.id)")
                return transaction
            case .userCancelled:
                logger.info("用户取消购买: \(product.id)")
                return nil
            case .pending:
                logger.info("购买待处理: \(product.id)")
                return nil
            @unknown default:
                logger.error("未知购买结果: \(product.id)")
                return nil
            }
        } catch {
            logger.error("购买失败: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// 验证交易
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }
    
    // MARK: - Restore Purchases
    
    /// 恢复购买
    func restorePurchases() async throws -> Bool {
        logger.info("开始恢复购买...")
        
        do {
            // 尝试恢复购买
            try await AppStore.sync()
            logger.info("AppStore.sync() 完成")
            
            // 检查是否有有效的订阅
            var hasValidSubscription = false
            
            for await result in Transaction.currentEntitlements {
                do {
                    let transaction = try checkVerified(result)
                    logger.info("找到有效订阅: \(transaction.productID)")
                    hasValidSubscription = true
                } catch {
                    logger.error("验证订阅失败: \(error.localizedDescription)")
                }
            }
            
            logger.info("恢复购买完成，是否有有效订阅: \(hasValidSubscription)")
            return hasValidSubscription
            
        } catch {
            logger.error("恢复购买失败: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Subscription Status
    
    /// 检查订阅状态
    func checkSubscriptionStatus() async {
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                logger.info("当前订阅: \(transaction.productID)")
            } catch {
                logger.error("验证订阅失败: \(error.localizedDescription)")
            }
        }
    }
    
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
}

// MARK: - Store Errors

enum StoreError: Error, LocalizedError {
    case verificationFailed
    
    var errorDescription: String? {
        switch self {
        case .verificationFailed:
            return "交易验证失败"
        }
    }
} 