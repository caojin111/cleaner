//
//  RatingView.swift
//  CleanUpAi
//
//  Created by CleanU AI Team
//

import SwiftUI
import MessageUI
import OSLog

struct RatingView: View {
    @Binding var isPresented: Bool
    @StateObject private var userSettings = UserSettingsManager.shared
    @State private var selectedRating: Int = 0
    @State private var showingFeedback = false
    @State private var feedbackText = ""
    @State private var showingMailComposer = false
    @State private var mailResult: Result<MFMailComposeResult, Error>?
    @State private var showingMailAlert = false
    @State private var mailResultTrigger = false
    @State private var isVisible = false
    @State private var showStarAnimation = false
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        ZStack {
            Color.black.opacity(isVisible ? 0.4 : 0)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                if selectedRating == 0 {
                    // 初始评分界面
                    initialRatingView
                } else if selectedRating <= 3 {
                    // 1-3星：反馈界面
                    feedbackView
                } else {
                    // 4-5星：跳转App Store（隐藏界面，直接跳转）
                    Color.clear
                        .frame(height: 0)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
            )
            .padding(.horizontal, 40)
            .scaleEffect(isVisible ? 1.0 : 0.8)
            .opacity(isVisible ? 1.0 : 0)
        }
        .animation(.easeInOut(duration: 0.3), value: selectedRating)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isVisible)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                isVisible = true
            }
        }
        .sheet(isPresented: $showingMailComposer) {
            if MFMailComposeViewController.canSendMail() {
                MailComposerView(
                    isShowing: $showingMailComposer,
                    result: $mailResult,
                    resultTrigger: $mailResultTrigger,
                    subject: "CleanUp AI - 用户反馈 (\(selectedRating)星)",
                    recipients: ["dxycj250@gmail.com"],
                    messageBody: feedbackText
                )
            }
        }
        .alert("rate_us.mail.result_title".localized, isPresented: $showingMailAlert) {
            Button("common.ok".localized) {
                dismissRating()
            }
        } message: {
            Text(getMailResultMessage())
        }
        .onChange(of: mailResultTrigger) { _ in
            if mailResult != nil {
                showingMailAlert = true
            }
        }
    }
    
    // MARK: - 初始评分界面
    
    private var initialRatingView: some View {
        ZStack {
            // 主要内容区域
            VStack(spacing: 20) {
                // 图标
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)
                
                // 标题和副标题
                VStack(spacing: 8) {
                    Text("rate_us.title".localized)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.seniorText)
                    
                    Text("rate_us.subtitle".localized)
                        .font(.body)
                        .foregroundColor(.seniorSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(minHeight: 60)
                }
                .padding(.horizontal, 20)
                
                // 星级评分
                HStack(spacing: 12) {
                    ForEach(1...5, id: \.self) { star in
                        Button(action: {
                            selectedRating = star
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showStarAnimation = true
                            }
                            handleRatingSelection(star)
                        }) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 32))
                                .foregroundColor(star <= selectedRating ? .orange : .gray.opacity(0.3))
                                .scaleEffect(star <= selectedRating && showStarAnimation ? 1.2 : 1.0)
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer(minLength: 20)
            }
            .padding(.top, 40) // 为关闭按钮留出空间
            
            // 关闭按钮 - 独立定位
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        dismissRating()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                Spacer()
            }
        }
        .frame(maxHeight: 300)
    }
    
    // MARK: - 反馈界面（1-3星）
    
    private var feedbackView: some View {
        VStack(spacing: 16) {
            // 关闭按钮
            HStack {
                Button(action: {
                    selectedRating = 0
                    showStarAnimation = false
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.seniorPrimary)
                }
                Spacer()
                Button(action: {
                    dismissRating()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            // 反馈图标
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 50))
                .foregroundColor(.blue)
            
            // 反馈标题
            VStack(spacing: 8) {
                Text("rate_us.feedback.title".localized)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.seniorText)
                
                Text("rate_us.feedback.subtitle".localized)
                    .font(.body)
                    .foregroundColor(.seniorSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(minHeight: 60)
            }
            .padding(.horizontal, 20)
            
            // 反馈输入框
            TextEditor(text: $feedbackText)
                .frame(height: 100)
                .padding(12)
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .padding(.horizontal, 20)
                .colorScheme(.light)
                .focused($isTextFieldFocused)
                .onTapGesture {
                    isTextFieldFocused = true
                }
            
            // 发送按钮
            VStack(spacing: 12) {
                Button("Submit") {
                    sendFeedback()
                }
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.seniorPrimary)
                )
                .disabled(feedbackText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            
        }
        .frame(maxHeight: 450)
    }
    

    
    // MARK: - Actions
    
    private func handleRatingSelection(_ rating: Int) {
        Logger.ui.info("用户选择评分: \(rating)星")
        
        if rating >= 4 {
            // 4-5星：延迟后直接跳转到App Store
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                showStarAnimation = false
                goToAppStore()
            }
        } else {
            // 1-3星：延迟显示反馈界面
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showStarAnimation = false
                // 界面会自动切换到feedbackView
            }
        }
    }
    
    private func sendFeedback() {
        Logger.ui.info("用户发送反馈: \(selectedRating)星")
        
        if MFMailComposeViewController.canSendMail() {
            showingMailComposer = true
        } else {
            // 如果设备不支持发送邮件，使用mailto链接
            let emailBody = feedbackText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let subject = "CleanUp AI - 用户反馈 (\(selectedRating)星)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            
            if let url = URL(string: "mailto:dxycj250@gmail.com?subject=\(subject)&body=\(emailBody)") {
                UIApplication.shared.open(url)
            }
            dismissRating()
        }
    }
    
    private func goToAppStore() {
        Logger.ui.info("用户前往App Store评分")
        
        // 标记需要显示感谢弹窗
        userSettings.markShouldShowThankYou()
        
        if let url = URL(string: "https://apps.apple.com/app/id6748984268?action=write-review") {
            UIApplication.shared.open(url)
        }
        dismissRating()
    }
    
    private func dismissRating() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isVisible = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            userSettings.markRatingShown()
            isPresented = false
            Logger.ui.info("评分弹窗已关闭")
        }
    }
    
    private func getMailResultMessage() -> String {
        guard let result = mailResult else { return "" }
        
        switch result {
        case .success(let mailResult):
            switch mailResult {
            case .sent:
                return "rate_us.mail.sent".localized
            case .saved:
                return "rate_us.mail.saved".localized
            case .cancelled:
                return "rate_us.mail.cancelled".localized
            case .failed:
                return "rate_us.mail.failed".localized
            @unknown default:
                return "rate_us.mail.unknown".localized
            }
        case .failure(let error):
            return "rate_us.mail.error".localized(error.localizedDescription)
        }
    }
}

// MARK: - Mail Composer

struct MailComposerView: UIViewControllerRepresentable {
    @Binding var isShowing: Bool
    @Binding var result: Result<MFMailComposeResult, Error>?
    @Binding var resultTrigger: Bool
    
    let subject: String
    let recipients: [String]
    let messageBody: String
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        @Binding var isShowing: Bool
        @Binding var result: Result<MFMailComposeResult, Error>?
        @Binding var resultTrigger: Bool
        
        init(isShowing: Binding<Bool>, result: Binding<Result<MFMailComposeResult, Error>?>, resultTrigger: Binding<Bool>) {
            _isShowing = isShowing
            _result = result
            _resultTrigger = resultTrigger
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            defer {
                isShowing = false
            }
            
            DispatchQueue.main.async {
                if let error = error {
                    Logger.ui.error("邮件发送失败: \(error.localizedDescription)")
                    self.result = .failure(error)
                } else {
                    Logger.ui.info("邮件操作完成，结果: \(result.rawValue)")
                    self.result = .success(result)
                }
                // 触发UI更新
                self.resultTrigger.toggle()
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(isShowing: $isShowing, result: $result, resultTrigger: $resultTrigger)
    }
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<MailComposerView>) -> MFMailComposeViewController {
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = context.coordinator
        composer.setSubject(subject)
        composer.setToRecipients(recipients)
        composer.setMessageBody(messageBody, isHTML: false)
        return composer
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: UIViewControllerRepresentableContext<MailComposerView>) {
        // No updates needed
    }
}

#Preview {
    RatingView(isPresented: .constant(true))
} 