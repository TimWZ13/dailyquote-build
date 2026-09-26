import SwiftUI
import AppKit

/// 应用元信息 — 集中管理版本号与版权，便于全局维护与防篡改
/// 版本编号规则：第1位=界面大更新，第2位=功能更新，第3位=修复问题
/// ©️Trigin
enum AppInfo {
    static let version = "1.2.3"
    static let copyright = "©️Trigin 2026"
    static let appName = "Trigin6Quote"

    /// 是否已作为正规 .app bundle 运行（有 Info.plist 和 bundle identifier）
    /// swift run / swift build 产出的裸可执行文件为 false，无法使用 SMAppService
    static var isProperlyBundled: Bool {
        Bundle.main.bundleIdentifier != nil && Bundle.main.bundlePath.hasSuffix(".app")
    }
}

/// 主窗口打开器 — 在菜单栏（常驻视图）中捕获 SwiftUI 的 openWindow 动作，
/// 供菜单栏按钮、菜单命令、Dock 重新打开使用，解决主窗口关闭后无法再打开的问题。
/// ©️Trigin
final class WindowOpener: ObservableObject {
    static var shared: WindowOpener?
    var openMain: (() -> Void)?
    init() { Self.shared = self }
}

@main
struct Trigin6QuoteApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = QuoteStore()
    @StateObject private var windowOpener = WindowOpener()
    // 外观模式：0=跟随系统 1=浅色 2=深色
    @AppStorage("appearanceMode") private var appearanceMode: Int = 0
    // 首次启动欢迎页 — v1.2.3 新增 ©️Trigin
    @AppStorage("hasLaunchedBefore") private var hasLaunchedBefore: Bool = false
    @State private var showWelcome = false

    // 根据设置计算实际配色方案
    private var preferredScheme: ColorScheme? {
        switch appearanceMode {
        case 1: return .light
        case 2: return .dark
        default: return nil
        }
    }

    var body: some Scene {
        WindowGroup("Trigin6Quote", id: "main") {
            ContentView()
                .environmentObject(store)
                .environmentObject(windowOpener)
                .frame(minWidth: 900, minHeight: 640)
                .preferredColorScheme(preferredScheme)
                // v1.2.3 首次启动欢迎页 ©️Trigin
                .sheet(isPresented: $showWelcome) {
                    WelcomeView()
                        .environmentObject(store)
                        .frame(minWidth: 900, minHeight: 600)
                }
                .onAppear {
                    if !hasLaunchedBefore {
                        showWelcome = true
                        hasLaunchedBefore = true
                    }
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 1100, height: 720)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("关于 Trigin6Quote") {
                    NSApp.orderFrontStandardAboutPanel(nil)
                }
            }
            CommandGroup(after: .appSettings) {
                Button("显示主窗口") {
                    windowOpener.openMain?()
                }
                .keyboardShortcut("0", modifiers: .command)
            }
            CommandMenu("语录") {
                Button("下一条") {
                    store.nextQuote()
                }
                .keyboardShortcut("r", modifiers: .command)

                Button("上一条") {
                    store.previousQuote()
                }
                .keyboardShortcut("l", modifiers: .command)

                Button("收藏当前语录") {
                    store.toggleFavorite(store.currentQuote)
                }
                .keyboardShortcut("f", modifiers: .command)

                Button("复制当前语录") {
                    store.copyQuote(store.currentQuote)
                }
                .keyboardShortcut("c", modifiers: [.command, .shift])
            }
        }

        MenuBarExtra {
            MenuBarView()
                .environmentObject(store)
                .environmentObject(windowOpener)
                .preferredColorScheme(preferredScheme)
        } label: {
            Image(systemName: "6.circle.fill")
                .foregroundStyle(AppTheme.accent)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environmentObject(store)
                .preferredColorScheme(preferredScheme)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // 只前置主窗口，避免把 MenuBarExtra 的 panel 也意外弹出
            for window in NSApp.windows where window.title == AppInfo.appName {
                window.makeKeyAndOrderFront(nil)
            }
        }
        setupAppIcon()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            // 主窗口已关闭时，通过 SwiftUI 的 openWindow 重新打开
            if let openMain = WindowOpener.shared?.openMain {
                openMain()
            } else {
                for window in NSApp.windows where window.title == "Trigin6Quote" {
                    window.makeKeyAndOrderFront(nil)
                    break
                }
            }
        }
        return true
    }

    private func setupAppIcon() {
        // SwiftPM 资源通过 Bundle.module 访问，尝试多种路径组合
        let candidates: [URL?] = [
            Bundle.module.url(forResource: "AppIcon", withExtension: "png", subdirectory: "Images"),
            Bundle.module.url(forResource: "AppIcon", withExtension: "png"),
            Bundle.module.url(forResource: "AppIcon_512", withExtension: "png", subdirectory: "Images"),
            Bundle.module.url(forResource: "AppIcon_512", withExtension: "png"),
            Bundle.module.url(forResource: "icon_512x512", withExtension: "png", subdirectory: "Images/AppIcon.iconset"),
            Bundle.module.url(forResource: "icon_512x512", withExtension: "png", subdirectory: "AppIcon.iconset"),
        ]

        var iconImage: NSImage?
        for url in candidates.compactMap({ $0 }) {
            if let img = NSImage(contentsOf: url) {
                iconImage = img
                break
            }
        }

        // 回退到文件系统搜索
        if iconImage == nil {
            let fm = FileManager.default
            let bundlePath = Bundle.main.bundlePath
            let paths = [
                bundlePath + "/Resources/Images/AppIcon.png",
                bundlePath + "/../Resources/Images/AppIcon.png",
                bundlePath + "/../../Resources/Images/AppIcon.png",
                bundlePath + "/Trigin6Quote_Trigin6Quote.resources/AppIcon.png",
                bundlePath + "/../Trigin6Quote_Trigin6Quote.resources/AppIcon.png",
            ]
            for path in paths {
                if fm.fileExists(atPath: path), let img = NSImage(contentsOfFile: path) {
                    iconImage = img
                    break
                }
            }
        }

        if let image = iconImage {
            NSApp.applicationIconImage = image
        } else {
            generateFallbackIcon()
        }
    }

    private func generateFallbackIcon() {
        let iconSize: CGFloat = 512
        let rect = NSRect(x: 0, y: 0, width: iconSize, height: iconSize)
        let image = NSImage(size: rect.size)
        image.lockFocus()

        // 深灰背景渐变
        let bgGradient = NSGradient(colors: [
            NSColor(red: 0.14, green: 0.14, blue: 0.15, alpha: 1.0),
            NSColor(red: 0.08, green: 0.08, blue: 0.09, alpha: 1.0)
        ])
        bgGradient?.draw(in: rect, angle: -90)

        // 圆角裁切
        let radius = iconSize * 0.22
        let inset = iconSize * 0.03
        let clipPath = NSBezierPath(roundedRect: rect.insetBy(dx: inset, dy: inset),
                                    xRadius: radius, yRadius: radius)
        clipPath.addClip()
        bgGradient?.draw(in: rect, angle: -90)

        // 绘制 "T6" 文字
        let text = "T6" as NSString
        let font = NSFont.systemFont(ofSize: iconSize * 0.42, weight: .bold)
        let textSize = text.size(withAttributes: [.font: font])
        let textRect = NSRect(
            x: (iconSize - textSize.width) / 2,
            y: (iconSize - textSize.height) / 2 - iconSize * 0.02,
            width: textSize.width,
            height: textSize.height
        )
        let beigeColor = NSColor(red: 0.96, green: 0.87, blue: 0.70, alpha: 1.0)
        text.draw(in: textRect, withAttributes: [
            .font: font,
            .foregroundColor: beigeColor
        ])

        // 底部装饰线
        let lineWidth = iconSize * 0.18
        let lineHeight = max(1, iconSize * 0.008)
        let lineRect = NSRect(
            x: (iconSize - lineWidth) / 2,
            y: iconSize * 0.72,
            width: lineWidth,
            height: lineHeight
        )
        beigeColor.setFill()
        NSBezierPath(roundedRect: lineRect, xRadius: lineHeight / 2, yRadius: lineHeight / 2).fill()

        //  subtle inner border
        let borderPath = NSBezierPath(roundedRect: rect.insetBy(dx: inset, dy: inset),
                                      xRadius: radius, yRadius: radius)
        NSColor(red: 0.96, green: 0.87, blue: 0.70, alpha: 0.15).setStroke()
        borderPath.lineWidth = max(1, iconSize * 0.004)
        borderPath.stroke()

        image.unlockFocus()
        NSApp.applicationIconImage = image
    }
}
