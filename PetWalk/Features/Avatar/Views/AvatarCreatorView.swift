//
//  AvatarCreatorView.swift
//  PetWalk
//
//  Created by Cursor AI on 2026/1/28.
//

import SwiftUI
import WebKit

/// Ready Player Me 头像创建器视图
struct AvatarCreatorView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var avatarManager = AvatarManager.shared
    @ObservedObject var webViewPreloader = WebViewPreloader.shared
    
    // 回调：头像创建完成
    var onAvatarCreated: ((String) -> Void)?
    
    @State private var isLoading = true
    @State private var showError = false
    @State private var errorMessage = ""
    
    // 检查是否有预热的 WebView 可用
    private var hasPreloadedWebView: Bool {
        webViewPreloader.isPreloaded
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // WebView - 优先使用预热的版本
                ReadyPlayerMeWebView(
                    url: avatarManager.avatarCreatorURL,
                    isLoading: $isLoading,
                    usePreloadedIfAvailable: true,
                    onAvatarExported: { avatarURL in
                        handleAvatarExported(avatarURL)
                    },
                    onError: { error in
                        errorMessage = error
                        showError = true
                    }
                )
                .ignoresSafeArea(edges: .bottom)
                
                // 加载指示器
                if isLoading {
                    VStack(spacing: 15) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text(hasPreloadedWebView ? "正在准备..." : "正在加载头像编辑器...")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(30)
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(15)
                    .shadow(radius: 10)
                }
            }
            .navigationTitle("创建头像")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        // 触发重新预热
                        WebViewPreloader.shared.refreshPreload()
                        dismiss()
                    }
                }
            }
            .alert("加载失败", isPresented: $showError) {
                Button("重试") {
                    // 重新加载 WebView
                }
                Button("取消", role: .cancel) {
                    dismiss()
                }
            } message: {
                Text(errorMessage)
            }
        }
        .onDisappear {
            // 视图消失时触发重新预热
            WebViewPreloader.shared.refreshPreload()
        }
    }
    
    private func handleAvatarExported(_ avatarURL: String) {
        // 保存头像
        avatarManager.saveAvatarURL(avatarURL)
        
        // 回调
        onAvatarCreated?(avatarURL)
        
        // 关闭视图
        dismiss()
    }
}

// MARK: - Ready Player Me WebView 封装
struct ReadyPlayerMeWebView: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool
    var usePreloadedIfAvailable: Bool = false
    var onAvatarExported: ((String) -> Void)?
    var onError: ((String) -> Void)?
    
    func makeUIView(context: Context) -> WKWebView {
        // 尝试使用预热的 WebView
        if usePreloadedIfAvailable, let preloadedWebView = WebViewPreloader.shared.getPreloadedWebView() {
            print("AvatarCreatorView: 使用预热的 WebView")
            
            // 添加消息处理器到预热的 WebView
            preloadedWebView.configuration.userContentController.add(context.coordinator, name: "readyPlayerMe")
            preloadedWebView.navigationDelegate = context.coordinator
            
            // 注入 JavaScript（因为预热时没有注入）
            injectJavaScript(into: preloadedWebView)
            
            // 预热的 WebView 已经加载完成
            DispatchQueue.main.async {
                self.isLoading = false
            }
            
            return preloadedWebView
        }
        
        // 没有预热的 WebView，创建新的
        print("AvatarCreatorView: 创建新的 WebView")
        
        let configuration = WKWebViewConfiguration()
        
        // 启用 JavaScript
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        
        // 添加消息处理器
        configuration.userContentController.add(context.coordinator, name: "readyPlayerMe")
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = true
        webView.allowsBackForwardNavigationGestures = true
        
        // 加载 Ready Player Me
        let request = URLRequest(url: url)
        webView.load(request)
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        // 无需更新
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // MARK: - JavaScript 注入
    
    private func injectJavaScript(into webView: WKWebView) {
        let js = """
        window.addEventListener('message', function(event) {
            // 检查是否来自 Ready Player Me
            if (event.data && typeof event.data === 'string') {
                try {
                    const json = JSON.parse(event.data);
                    if (json.source === 'readyplayerme') {
                        // 发送消息给 Swift
                        window.webkit.messageHandlers.readyPlayerMe.postMessage(event.data);
                    }
                } catch (e) {
                    // 不是 JSON，可能是普通字符串
                    if (event.data.includes('.glb')) {
                        window.webkit.messageHandlers.readyPlayerMe.postMessage(JSON.stringify({
                            source: 'readyplayerme',
                            eventName: 'v1.avatar.exported',
                            data: { url: event.data }
                        }));
                    }
                }
            } else if (event.data && event.data.source === 'readyplayerme') {
                window.webkit.messageHandlers.readyPlayerMe.postMessage(JSON.stringify(event.data));
            }
        });
        
        // 通知 Ready Player Me 我们已准备好接收消息
        if (window.postMessage) {
            window.postMessage(JSON.stringify({
                target: 'readyplayerme',
                type: 'subscribe',
                eventName: 'v1.**'
            }), '*');
        }
        """
        
        webView.evaluateJavaScript(js) { _, error in
            if let error = error {
                print("AvatarCreatorView: JavaScript 注入失败 - \(error)")
            }
        }
    }
    
    // MARK: - Coordinator
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: ReadyPlayerMeWebView
        
        init(_ parent: ReadyPlayerMeWebView) {
            self.parent = parent
        }
        
        // MARK: - WKNavigationDelegate
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = true
            }
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
            }
            
            // 注入 JavaScript 来监听 Ready Player Me 的消息
            parent.injectJavaScript(into: webView)
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
                self.parent.onError?(error.localizedDescription)
            }
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
                self.parent.onError?(error.localizedDescription)
            }
        }
        
        // MARK: - WKScriptMessageHandler
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "readyPlayerMe",
                  let messageBody = message.body as? String,
                  let data = messageBody.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return
            }
            
            print("AvatarCreatorView: 收到消息 - \(json)")
            
            // 检查事件类型
            if let eventName = json["eventName"] as? String {
                switch eventName {
                case "v1.avatar.exported":
                    // 头像导出完成
                    if let eventData = json["data"] as? [String: Any],
                       let avatarURL = eventData["url"] as? String {
                        DispatchQueue.main.async {
                            self.parent.onAvatarExported?(avatarURL)
                        }
                    }
                    
                case "v1.user.set":
                    // 用户已登录
                    print("AvatarCreatorView: 用户已登录")
                    
                case "v1.frame.ready":
                    // Frame 已准备好
                    print("AvatarCreatorView: Frame 已准备好")
                    
                default:
                    print("AvatarCreatorView: 未知事件 - \(eventName)")
                }
            }
        }
    }
}

#Preview {
    AvatarCreatorView()
}
