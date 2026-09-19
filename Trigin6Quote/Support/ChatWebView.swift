import SwiftUI
import WebKit
import AppKit

/// Chatango 聊天 WebView 组件
/// 直接内嵌 Chatango 嵌入脚本，不跳转外部网页
/// handle: trigin6quate
/// ©️Trigin
@MainActor
final class ChatWebViewModel: NSObject, ObservableObject, WKNavigationDelegate {

    @Published var isLoading: Bool = true
    @Published var loadError: String? = nil

    private var webView: WKWebView?
    private var lastLoadedIsDark: Bool? = nil
    private var loadingTimer: DispatchWorkItem?

    /// 构建包含 Chatango 嵌入脚本的完整 HTML
    /// 脚本内容必须包含完整的 JSON 配置（handle、arch、styles）
    func buildHTML(isDark: Bool) -> String {
        // 配色适配：浅色用米黄主题，深色用深灰主题
        let bgColor = isDark ? "#1a1a1b" : "#f5f4f1"

        // Chatango 完整配置 JSON — 包含 handle 和 arch
        let chatangoConfig = isDark
            ? #"{"handle":"trigin6quate","arch":"js","styles":{"a":"1a1a1b","b":70,"c":"f0ede8","d":"c8c5c0","f":70,"i":70,"k":"ffcc00","l":"ffcc00","m":"ffcc00","o":70,"p":"14","q":"ffcc00","r":70,"t":0,"ab":false,"usricon":0,"fwtickm":1}}"#
            : #"{"handle":"trigin6quate","arch":"js","styles":{"a":"f5f4f1","b":100,"c":"1a1918","d":"3d3b36","f":100,"i":70,"k":"cc8800","l":"cc8800","m":"cc8800","o":100,"p":14,"q":"cc8800","r":70,"t":0,"ab":false,"usricon":0,"fwtickm":1}}"#

        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                * { margin: 0; padding: 0; box-sizing: border-box; }
                html, body {
                    width: 100%;
                    height: 100%;
                    background: \(bgColor);
                    overflow: hidden;
                }
                /* Chatango 创建的 iframe 需要撑满容器 */
                iframe {
                    width: 100% !important;
                    height: 100% !important;
                    border: none !important;
                }
            </style>
        </head>
        <body>
            <!-- Chatango 嵌入脚本 — 完整配置含 handle 和 arch -->
            <script id="cid0020000446552691512" data-cfasync="false" async src="https://st.chatango.com/js/gz/emb.js" style="width: 100%;height: 100%;">\(chatangoConfig)</script>

            <!-- iframe 加载检测 — 通知 Swift 端隐藏加载指示器 -->
            <script>
                (function() {
                    function notifyLoaded() {
                        try {
                            window.webkit.messageHandlers.chatObserver.postMessage('loaded');
                        } catch(e) {}
                    }

                    // 监测 Chatango iframe 创建
                    var observer = new MutationObserver(function(mutations) {
                        mutations.forEach(function(mutation) {
                            mutation.addedNodes.forEach(function(node) {
                                if (node.tagName === 'IFRAME') {
                                    // iframe load 事件
                                    node.addEventListener('load', function() {
                                        setTimeout(notifyLoaded, 300);
                                    });
                                    // iframe 可能已加载完成
                                    if (node.contentWindow) {
                                        setTimeout(notifyLoaded, 1000);
                                    }
                                }
                            });
                        });
                    });
                    observer.observe(document.body, {childList: true, subtree: true});

                    // 超时兜底：5秒后强制通知
                    setTimeout(notifyLoaded, 5000);
                })();
            </script>
        </body>
        </html>
        """
    }

    /// 创建 WKWebView 配置 — 注册 JS 消息处理器
    func makeWebViewConfiguration() -> WKWebViewConfiguration {
        let config = WKWebViewConfiguration()
        let contentController = WKUserContentController()
        // 使用弱引用代理，避免循环引用
        let handler = ChatMessageHandler()
        handler.viewModel = self
        contentController.add(handler, name: "chatObserver")
        config.userContentController = contentController
        // 使用公共 API isInspectable（在 loadHTML 中设置）启用 Web 检查器，
        // 不再使用私有 KVC "developerExtrasEnabled"，避免 App Store 拒审风险
        config.preferences.javaScriptCanOpenWindowsAutomatically = true
        return config
    }

    /// 处理来自 JavaScript 的消息 — iframe 加载完成时调用
    func handleScriptMessage(_ message: WKScriptMessage) {
        if message.name == "chatObserver", let body = message.body as? String, body == "loaded" {
            isLoading = false
            loadError = nil
            loadingTimer?.cancel()
            loadingTimer = nil
        }
    }

    /// 加载 HTML 到 WebView
    func loadHTML(in webView: WKWebView, isDark: Bool) {
        self.webView = webView
        webView.navigationDelegate = self
        webView.isInspectable = true

        let html = buildHTML(isDark: isDark)
        webView.loadHTMLString(html, baseURL: URL(string: "about:blank")!)
        lastLoadedIsDark = isDark
        isLoading = true
        loadError = nil

        // 定时器兜底：3秒后如果仍在加载，强制隐藏加载指示器
        loadingTimer?.cancel()
        let timer = DispatchWorkItem { [weak self] in
            self?.isLoading = false
        }
        loadingTimer = timer
        DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: timer)
    }

    /// 主题变更时重新加载
    func reloadIfThemeChanged(in webView: WKWebView, isDark: Bool) {
        if lastLoadedIsDark != isDark {
            loadHTML(in: webView, isDark: isDark)
        }
    }

    /// 重新加载页面
    func reload() {
        guard let webView = webView else { return }
        isLoading = true
        loadError = nil
        webView.reload()

        // 重新加载也启动定时器兜底
        loadingTimer?.cancel()
        let timer = DispatchWorkItem { [weak self] in
            self?.isLoading = false
        }
        loadingTimer = timer
        DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: timer)
    }

    // MARK: - WKNavigationDelegate

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.main.async {
            self.isLoading = false
            self.loadError = nil
            self.loadingTimer?.cancel()
            self.loadingTimer = nil
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        DispatchQueue.main.async {
            self.isLoading = false
            self.loadError = error.localizedDescription
            self.loadingTimer?.cancel()
        }
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        DispatchQueue.main.async {
            self.isLoading = false
            self.loadError = error.localizedDescription
            self.loadingTimer?.cancel()
        }
    }
}

// MARK: - 弱引用消息处理器（避免 WKUserContentController 循环引用）

private final class ChatMessageHandler: NSObject, WKScriptMessageHandler {
    weak var viewModel: ChatWebViewModel?

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        viewModel?.handleScriptMessage(message)
    }
}

// MARK: - SwiftUI 包装视图

struct ChatWebView: NSViewRepresentable {
    @ObservedObject var viewModel: ChatWebViewModel
    let isDark: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> WKWebView {
        let config = viewModel.makeWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.setValue(false, forKey: "drawsBackground")
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        // 根据主题更新 WebView 背景色
        webView.setValue(isDark ? NSColor(red: 0.10, green: 0.10, blue: 0.11, alpha: 1.0) : NSColor(red: 0.96, green: 0.95, blue: 0.92, alpha: 1.0), forKey: "underPageBackgroundColor")

        // 使用 coordinator 标记追踪是否已加载，避免重复加载
        if !context.coordinator.hasLoaded {
            context.coordinator.hasLoaded = true
            viewModel.loadHTML(in: webView, isDark: isDark)
        } else {
            viewModel.reloadIfThemeChanged(in: webView, isDark: isDark)
        }
    }

    static func dismantleNSView(_ webView: WKWebView, coordinator: Coordinator) {
        webView.stopLoading()
        coordinator.hasLoaded = false
    }

    final class Coordinator {
        var hasLoaded = false
    }
}

// MARK: - 预览

#Preview {
    ChatWebView(viewModel: ChatWebViewModel(), isDark: false)
        .frame(width: 420, height: 520)
}
