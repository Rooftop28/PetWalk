//
//  WebViewPreloader.swift
//  PetWalk
//
//  Created by Cursor AI on 2026/1/28.
//

import Foundation
import WebKit
import SwiftUI

/// WebView 预热器 - 后台预加载 Ready Player Me 页面
@MainActor
class WebViewPreloader: ObservableObject {
    // MARK: - 单例
    static let shared = WebViewPreloader()
    
    // MARK: - 发布的状态
    @Published var isPreloaded = false
    @Published var isPreloading = false
    
    // MARK: - 预热的 WebView
    private var preloadedWebView: WKWebView?
    private var preloadCoordinator: PreloadCoordinator?
    
    // MARK: - 配置
    private let preloadTimeout: TimeInterval = 10.0  // 预热超时时间（秒）
    
    private init() {}
    
    // MARK: - 预热 Avatar Creator
    
    /// 开始预热 Ready Player Me 头像编辑器
    func preloadAvatarCreator() async {
        guard !isPreloaded && !isPreloading else { return }
        
        isPreloading = true
        
        // 创建 WebView 配置
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        
        // 创建协调器
        let coordinator = PreloadCoordinator()
        self.preloadCoordinator = coordinator
        
        // 创建隐藏的 WebView
        let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 1, height: 1), configuration: configuration)
        webView.navigationDelegate = coordinator
        
        // 加载 Ready Player Me URL
        let url = AvatarManager.shared.avatarCreatorURL
        let request = URLRequest(url: url)
        webView.load(request)
        
        // 等待加载完成或超时
        let loadResult = await withTaskGroup(of: Bool.self) { group in
            // 任务1: 等待加载完成
            group.addTask {
                await coordinator.waitForLoad()
                return true
            }
            
            // 任务2: 超时
            group.addTask {
                try? await Task.sleep(nanoseconds: UInt64(self.preloadTimeout * 1_000_000_000))
                return false
            }
            
            // 返回第一个完成的结果
            if let result = await group.next() {
                group.cancelAll()
                return result
            }
            return false
        }
        
        if loadResult {
            preloadedWebView = webView
            isPreloaded = true
            print("WebViewPreloader: Ready Player Me 预热成功")
        } else {
            print("WebViewPreloader: Ready Player Me 预热超时或失败")
        }
        
        isPreloading = false
    }
    
    /// 获取预热的 WebView（如果可用）
    /// 调用后会清除预热的 WebView，需要重新预热
    func getPreloadedWebView() -> WKWebView? {
        guard isPreloaded, let webView = preloadedWebView else {
            return nil
        }
        
        // 清除引用，表示已被使用
        preloadedWebView = nil
        isPreloaded = false
        
        // 在后台开始新的预热
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 延迟2秒后开始重新预热
            await preloadAvatarCreator()
        }
        
        return webView
    }
    
    /// 重新预热（在头像编辑器关闭后调用）
    func refreshPreload() {
        guard !isPreloading else { return }
        
        Task {
            await preloadAvatarCreator()
        }
    }
    
    /// 清除预热的 WebView
    func clearPreload() {
        preloadedWebView = nil
        isPreloaded = false
        preloadCoordinator = nil
    }
}

// MARK: - 预热协调器

private class PreloadCoordinator: NSObject, WKNavigationDelegate {
    private var continuation: CheckedContinuation<Void, Never>?
    private var isLoaded = false
    
    func waitForLoad() async {
        if isLoaded { return }
        
        await withCheckedContinuation { continuation in
            self.continuation = continuation
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        isLoaded = true
        continuation?.resume()
        continuation = nil
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        isLoaded = true
        continuation?.resume()
        continuation = nil
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        isLoaded = true
        continuation?.resume()
        continuation = nil
    }
}
