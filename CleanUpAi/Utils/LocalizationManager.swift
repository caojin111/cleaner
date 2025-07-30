//
//  LocalizationManager.swift
//  CleanUpAi
//
//  Created by CleanU AI Team
//

import Foundation
import OSLog

class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    @Published var currentLanguage: String = "en"
    
    private var localizationData: [String: Any] = [:]
    private let logger = Logger(subsystem: "com.cleanupai.app", category: "Localization")
    
    private init() {
        loadLocalizationData()
        detectDeviceLanguage()
    }
    
    // MARK: - Language Detection
    
    private func detectDeviceLanguage() {
        let preferredLanguage = Locale.preferredLanguages.first ?? "en"
        let languageCode = String(preferredLanguage.prefix(2))
        
        // 系统默认为英语，只有检测到中文时才使用中文
        if languageCode == "zh" {
            self.currentLanguage = "zh"
            logger.info("检测到中文设备语言，切换到中文")
        } else {
            self.currentLanguage = "en"
            logger.info("使用默认英语语言")
        }
        
        // 调试：打印当前语言和可用的本地化数据
        logger.info("当前语言: \(self.currentLanguage)")
        if let languageData = localizationData[self.currentLanguage] as? [String: Any] {
            logger.info("语言数据加载成功，包含 \(languageData.keys.count) 个顶级键")
        } else {
            logger.error("无法加载语言数据: \(self.currentLanguage)")
        }
    }
    
    // MARK: - Data Loading
    
    private func loadLocalizationData() {
        guard let url = Bundle.main.url(forResource: "Localizable", withExtension: "json") else {
            logger.error("无法找到Localizable.json文件")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            
            if let dict = json as? [String: Any] {
                localizationData = dict
                logger.info("成功加载本地化数据")
            }
        } catch {
            logger.error("加载本地化数据失败: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Text Retrieval
    
    /// 获取本地化文本
    /// - Parameter key: 文本键，使用点号分隔，如 "photos.title"
    /// - Returns: 本地化文本，如果找不到则返回键名
    func localizedString(_ key: String) -> String {
        let result = getLocalizedValue(for: key) as? String ?? key
        logger.debug("本地化键 '\(key)' -> '\(result)'")
        return result
    }
    
    /// 获取带参数的本地化文本
    /// - Parameters:
    ///   - key: 文本键
    ///   - arguments: 参数数组
    /// - Returns: 格式化后的本地化文本
    func localizedString(_ key: String, arguments: [CVarArg]) -> String {
        let format = localizedString(key)
        return String(format: format, arguments: arguments)
    }
    
    /// 获取带单个参数的本地化文本
    /// - Parameters:
    ///   - key: 文本键
    ///   - argument: 单个参数
    /// - Returns: 格式化后的本地化文本
    func localizedString(_ key: String, argument: CVarArg) -> String {
        return localizedString(key, arguments: [argument])
    }
    
    // MARK: - Private Helper Methods
    
    private func getLocalizedValue(for key: String) -> Any? {
        let keys = key.components(separatedBy: ".")
        
        guard let languageData = localizationData[self.currentLanguage] as? [String: Any] else {
            logger.error("无法获取语言数据: \(self.currentLanguage)")
            return nil
        }
        
        var current: Any = languageData
        
        for keyComponent in keys {
            if let dict = current as? [String: Any] {
                guard let value = dict[keyComponent] else {
                    logger.error("找不到键: \(key)")
                    return nil
                }
                current = value
            } else {
                logger.error("键路径无效: \(key)")
                return nil
            }
        }
        
        return current
    }
    
    // MARK: - Language Switching
    
    /// 切换语言
    /// - Parameter language: 语言代码 ("en" 或 "zh")
    func switchLanguage(to language: String) {
        guard ["en", "zh"].contains(language) else {
            logger.error("不支持的语言: \(language)")
            return
        }
        
        self.currentLanguage = language
        logger.info("切换到语言: \(language)")
    }
    
    // MARK: - Debug Methods
    
    /// 获取当前语言
    var currentLanguageCode: String {
        return self.currentLanguage
    }
    
    /// 检查是否支持指定语言
    func isLanguageSupported(_ language: String) -> Bool {
        return ["en", "zh"].contains(language)
    }
    
    /// 获取所有支持的语言
    var supportedLanguages: [String] {
        return ["en", "zh"]
    }
    

}

// MARK: - String Extension for Easy Access

extension String {
    /// 本地化字符串
    var localized: String {
        return LocalizationManager.shared.localizedString(self)
    }
    
    /// 本地化字符串（带参数）
    func localized(_ arguments: CVarArg...) -> String {
        return LocalizationManager.shared.localizedString(self, arguments: arguments)
    }
} 