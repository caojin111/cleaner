//
//  FirebaseManager.swift
//  CleanUpAi
//
//  Created by Firebase Manager on 2025/1/14.
//

import Foundation
import FirebaseAnalytics
import FirebaseCore
import FirebaseRemoteConfig
import FirebaseDatabase

class FirebaseManager {
    static let shared = FirebaseManager()

    private let remoteConfig: RemoteConfig
    private let databaseRef: DatabaseReference

    private init() {
        // 初始化Remote Config
        remoteConfig = RemoteConfig.remoteConfig()
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 0 // 开发模式下设置为0，生产环境建议设置为3600（1小时）
        remoteConfig.configSettings = settings

        // 初始化Database
        databaseRef = Database.database().reference()

        setupRemoteConfigDefaults()
    }

    // MARK: - Analytics Methods

    /// 记录应用启动事件
    func logAppOpen() {
        Analytics.logEvent(AnalyticsEventAppOpen, parameters: nil)
        print("Firebase: 记录应用启动事件 - Firebase Analytics已启用")
    }

    /// 记录用户操作事件
    func logUserAction(action: String, parameters: [String: Any]? = nil) {
        Analytics.logEvent(action, parameters: parameters)
        print("Firebase: 记录用户操作 - \(action)")
    }

    /// 记录屏幕浏览事件
    func logScreenView(screenName: String, screenClass: String? = nil) {
        Analytics.logEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: screenName,
            AnalyticsParameterScreenClass: screenClass ?? screenName
        ])
        print("Firebase: 记录屏幕浏览 - \(screenName)")
    }

    /// 设置用户属性
    func setUserProperty(value: String?, forName name: String) {
        Analytics.setUserProperty(value, forName: name)
        print("Firebase: 设置用户属性 - \(name): \(value ?? "nil")")
    }

    /// 记录自定义事件
    func logCustomEvent(name: String, parameters: [String: Any]? = nil) {
        Analytics.logEvent(name, parameters: parameters)
        print("Firebase: 记录自定义事件 - \(name)")
    }

    // MARK: - Remote Config Methods

    /// 获取远程配置值
    func getRemoteConfigValue(forKey key: String) -> RemoteConfigValue {
        return remoteConfig[key]
    }

    /// 获取远程配置字符串值
    func getRemoteConfigString(forKey key: String) -> String {
        return remoteConfig[key].stringValue
    }

    /// 获取远程配置布尔值
    func getRemoteConfigBool(forKey key: String) -> Bool {
        return remoteConfig[key].boolValue
    }

    /// 获取远程配置数字值
    func getRemoteConfigNumber(forKey key: String) -> NSNumber {
        return remoteConfig[key].numberValue
    }

    /// 异步获取远程配置
    func fetchRemoteConfig(completion: @escaping (Bool) -> Void) {
        remoteConfig.fetch { [weak self] status, error in
            if let error = error {
                print("Firebase: 远程配置获取失败 - \(error.localizedDescription)")
                completion(false)
                return
            }

            self?.remoteConfig.activate { changed, error in
                if let error = error {
                    print("Firebase: 远程配置激活失败 - \(error.localizedDescription)")
                    completion(false)
                } else {
                    print("Firebase: 远程配置激活成功")
                    completion(true)
                }
            }
        }
    }

    // MARK: - Database Methods

    /// 保存用户数据到Firebase Database
    func saveUserData(userId: String, data: [String: Any], completion: @escaping (Bool, Error?) -> Void) {
        databaseRef.child("users").child(userId).setValue(data) { error, _ in
            if let error = error {
                print("Firebase: 保存用户数据失败 - \(error.localizedDescription)")
                completion(false, error)
            } else {
                print("Firebase: 保存用户数据成功")
                completion(true, nil)
            }
        }
    }

    /// 获取用户数据
    func getUserData(userId: String, completion: @escaping ([String: Any]?, Error?) -> Void) {
        databaseRef.child("users").child(userId).observeSingleEvent(of: .value) { snapshot in
            if let value = snapshot.value as? [String: Any] {
                print("Firebase: 获取用户数据成功")
                completion(value, nil)
            } else {
                print("Firebase: 用户数据不存在")
                completion(nil, nil)
            }
        } withCancel: { error in
            print("Firebase: 获取用户数据失败 - \(error.localizedDescription)")
            completion(nil, error)
        }
    }

    /// 记录应用事件到Database
    func logEventToDatabase(eventName: String, parameters: [String: Any]? = nil) {
        let eventData: [String: Any] = [
            "event_name": eventName,
            "timestamp": ServerValue.timestamp(),
            "parameters": parameters ?? [:]
        ]

        let eventId = UUID().uuidString
        databaseRef.child("events").child(eventId).setValue(eventData) { error, _ in
            if let error = error {
                print("Firebase: 记录事件到数据库失败 - \(error.localizedDescription)")
            } else {
                print("Firebase: 记录事件到数据库成功 - \(eventName)")
            }
        }
    }

    // MARK: - Private Methods

    private func setupRemoteConfigDefaults() {
        let defaults: [String: NSObject] = [
            "welcome_message": "欢迎使用CleanUp AI" as NSObject,
            "max_free_scans": 5 as NSObject,
            "show_premium_features": false as NSObject,
            "app_version_check_enabled": true as NSObject
        ]
        remoteConfig.setDefaults(defaults)
        print("Firebase: 远程配置默认值已设置")
    }

}
