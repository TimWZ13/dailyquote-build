import SwiftUI
import AppKit

/// 首次启动欢迎页 — 动画开场序列
/// 设计：黑色幕布拉开 → 文字浮现 → 流光溢彩 → 开始按钮
/// 原始 HTML 设计 ©️Trigin 深源，SwiftUI 原生实现 ©️Trigin
/// v1.2.0 新增
struct WelcomeView: View {
    @Environment(\.dismiss) private var dismiss

    // MARK: - 动画状态

    @State private var maskScaleY: CGFloat = 1.0
    @State private var topTextOpacity: Double = 0
    @State private var topTextOffset: CGFloat = 20
    @State private var centerTextOpacity: Double = 0
    @State private var centerTextOffset: CGFloat = 20
    @State private var auroraOpacity: Double = 0
    @State private var stripeOpacity: Double = 0
    @State private var warmOpacity: Double = 0
    @State private var blackWhiteOpacity: Double = 1
    @State private var textAuroraOn = false
    @State private var buttonOpacity: Double = 0
    @State private var buttonOffset: CGFloat = 20
    @State private var buttonHover = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // 纯黑底色
                Color.black

                // 1. 流光溢彩背景
                auroraBackground
                    .opacity(auroraOpacity)
                    .allowsHitTesting(false)

                // 2. 横向流动条纹
                stripeLayer
                    .opacity(stripeOpacity)
                    .blendMode(.screen)
                    .allowsHitTesting(false)

                // 3. 米黄色暖调
                Color(red: 1.0, green: 0.96, blue: 0.86)
                    .opacity(warmOpacity * 0.18)
                    .allowsHitTesting(false)

                // 4. 白色中段（30% 高度）
                Rectangle()
                    .fill(Color.white)
                    .frame(width: geo.size.width, height: geo.size.height * 0.30)
                    .position(x: geo.size.width / 2, y: geo.size.height * 0.50)
                    .opacity(blackWhiteOpacity)
                    .allowsHitTesting(false)

                // 5. 黑色上段（35%）
                Rectangle()
                    .fill(Color.black)
                    .frame(width: geo.size.width, height: geo.size.height * 0.35)
                    .position(x: geo.size.width / 2, y: geo.size.height * 0.175)
                    .opacity(blackWhiteOpacity)
                    .allowsHitTesting(false)

                // 6. 黑色下段（35%）
                Rectangle()
                    .fill(Color.black)
                    .frame(width: geo.size.width, height: geo.size.height * 0.35)
                    .position(x: geo.size.width / 2, y: geo.size.height * 0.825)
                    .opacity(blackWhiteOpacity)
                    .allowsHitTesting(false)

                // 7. 顶部文字
                Text("欢迎使用Trigin6Quote")
                    .font(.system(size: clampedFont(geo, 3.5, max: 48), weight: .light))
                    .foregroundColor(.white)
                    .shadow(
                        color: textAuroraOn ? .white.opacity(0.5) : .clear,
                        radius: textAuroraOn ? 30 : 0
                    )
                    .tracking(clampedFont(geo, 3.5, max: 48) * 0.15)
                    .opacity(topTextOpacity)
                    .offset(y: topTextOffset)
                    .position(x: geo.size.width / 2, y: geo.size.height * 0.175)
                    .allowsHitTesting(false)

                // 8. 中心文字
                Text("©️Trigin 深源")
                    .font(.system(size: clampedFont(geo, 3.0, max: 42), weight: .regular))
                    .foregroundColor(textAuroraOn ? .white : .black)
                    .shadow(
                        color: textAuroraOn ? .white.opacity(0.5) : .clear,
                        radius: textAuroraOn ? 30 : 0
                    )
                    .tracking(clampedFont(geo, 3.0, max: 42) * 0.2)
                    .opacity(centerTextOpacity)
                    .offset(y: centerTextOffset)
                    .position(x: geo.size.width / 2, y: geo.size.height * 0.50)
                    .allowsHitTesting(false)

                // 9. 开始按钮
                Button(action: { dismiss() }) {
                    Text("开始使用")
                        .font(.system(size: 20, weight: .light))
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.horizontal, 56)
                        .padding(.vertical, 14)
                        .background(
                            Capsule()
                                .fill(.ultraThinMaterial)
                        )
                        .overlay(
                            Capsule()
                                .strokeBorder(
                                    .white.opacity(buttonHover ? 0.55 : 0.35),
                                    lineWidth: 1
                                )
                        )
                        .shadow(
                            color: buttonHover ? .white.opacity(0.15) : .clear,
                            radius: buttonHover ? 30 : 0
                        )
                        .scaleEffect(buttonHover ? 1.02 : 1.0)
                }
                .buttonStyle(.plain)
                .opacity(buttonOpacity)
                .offset(y: buttonOffset)
                .position(x: geo.size.width / 2, y: geo.size.height * 0.88)
                .onHover { buttonHover = $0 }
                .animation(.easeOut(duration: 0.4), value: buttonHover)

                // 10. 幕布遮罩（上 50%）
                Rectangle()
                    .fill(Color.black)
                    .frame(width: geo.size.width, height: geo.size.height * 0.5)
                    .position(x: geo.size.width / 2, y: geo.size.height * 0.25)
                    .scaleEffect(y: maskScaleY, anchor: .top)
                    .allowsHitTesting(false)

                // 11. 幕布遮罩（下 50%）
                Rectangle()
                    .fill(Color.black)
                    .frame(width: geo.size.width, height: geo.size.height * 0.5)
                    .position(x: geo.size.width / 2, y: geo.size.height * 0.75)
                    .scaleEffect(y: maskScaleY, anchor: .bottom)
                    .allowsHitTesting(false)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .onAppear {
            startAnimationSequence()
        }
    }

    // MARK: - 动画时间线
    // ©️Trigin — 还原 HTML 动画序列

    private func startAnimationSequence() {
        // 0.5s：幕布拉开（2s，cubic-bezier(0.22, 1, 0.36, 1)）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.timingCurve(0.22, 1, 0.36, 1, duration: 2)) {
                maskScaleY = 0
            }
        }

        // 2.2s：顶部文字淡入（1s）
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation(.easeOut(duration: 1)) {
                topTextOpacity = 1
                topTextOffset = 0
            }
        }

        // 2.5s：中心文字淡入（1s）
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeOut(duration: 1)) {
                centerTextOpacity = 1
                centerTextOffset = 0
            }
        }

        // 4.5s：流光淡入 + 黑白层淡出（2.5s）
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
            withAnimation(.easeIn(duration: 2.5)) {
                auroraOpacity = 1
                warmOpacity = 1
                blackWhiteOpacity = 0
            }
        }

        // 4.5s：文字变色 + 光晕（2s）
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
            withAnimation(.easeIn(duration: 2)) {
                textAuroraOn = true
            }
        }

        // 4.8s：条纹淡入（2.5s）
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.8) {
            withAnimation(.easeIn(duration: 2.5)) {
                stripeOpacity = 1
            }
        }

        // 7.5s：按钮淡入（0.8s）
        DispatchQueue.main.asyncAfter(deadline: .now() + 7.5) {
            withAnimation(.easeOut(duration: 0.8)) {
                buttonOpacity = 1
                buttonOffset = 0
            }
        }
    }

    // MARK: - 流光溢彩背景（Canvas + TimelineView）

    private var auroraBackground: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let t = timeline.date.timeIntervalSinceReferenceDate
                let w = size.width
                let h = size.height

                // 深色渐变底
                let baseGradient = Gradient(colors: [
                    Color(red: 0.03, green: 0.03, blue: 0.09),
                    Color(red: 0.09, green: 0.04, blue: 0.16),
                    Color(red: 0.04, green: 0.11, blue: 0.16),
                    Color(red: 0.09, green: 0.04, blue: 0.10),
                    Color(red: 0.03, green: 0.03, blue: 0.09)
                ])
                context.fill(
                    Path(CGRect(origin: .zero, size: size)),
                    with: .linearGradient(baseGradient, startPoint: .zero, endPoint: CGPoint(x: w, y: h))
                )

                // 流光色块定义
                struct Blob {
                    let bx: CGFloat; let by: CGFloat
                    let color: Color; let r: CGFloat
                    let speed: Double; let phase: Double
                }

                let blobs: [Blob] = [
                    Blob(bx: 0.20, by: 0.30, color: Color(red: 0.55, green: 0.31, blue: 0.94, opacity: 0.60), r: 0.50, speed: 0.30, phase: 0),
                    Blob(bx: 0.80, by: 0.20, color: Color(red: 1.00, green: 0.39, blue: 0.55, opacity: 0.50), r: 0.45, speed: 0.35, phase: 1),
                    Blob(bx: 0.50, by: 0.80, color: Color(red: 0.31, green: 0.78, blue: 1.00, opacity: 0.50), r: 0.50, speed: 0.25, phase: 2),
                    Blob(bx: 0.10, by: 0.70, color: Color(red: 1.00, green: 0.78, blue: 0.31, opacity: 0.40), r: 0.40, speed: 0.28, phase: 3),
                    Blob(bx: 0.90, by: 0.60, color: Color(red: 0.39, green: 1.00, blue: 0.78, opacity: 0.40), r: 0.45, speed: 0.32, phase: 4),
                ]

                for b in blobs {
                    let dx = CGFloat(sin(t * b.speed + b.phase)) * 0.05
                    let dy = CGFloat(cos(t * b.speed * 0.8 + b.phase)) * 0.05
                    let cx = (b.bx + dx) * w
                    let cy = (b.by + dy) * h
                    let radius = w * b.r

                    let ellipseRect = CGRect(x: cx - radius, y: cy - radius, width: radius * 2, height: radius * 2)
                    let radialGradient = Gradient(colors: [b.color, b.color.opacity(0)])
                    context.fill(
                        Path(ellipseIn: ellipseRect),
                        with: .radialGradient(radialGradient, center: CGPoint(x: cx, y: cy), startRadius: 0, endRadius: radius)
                    )
                }
            }
        }
    }

    // MARK: - 横向流动条纹

    private var stripeLayer: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let t = timeline.date.timeIntervalSinceReferenceDate
                let phase = CGFloat(t.truncatingRemainder(dividingBy: 8) / 8)
                let w = size.width
                let h = size.height

                let stripeWidth = w * 3
                let offset = phase * stripeWidth - stripeWidth / 3

                let stripeGradient = Gradient(colors: [
                    .clear,
                    Color(red: 1.0, green: 0.47, blue: 0.62, opacity: 0.15),
                    Color(red: 0.47, green: 0.82, blue: 1.0, opacity: 0.15),
                    Color(red: 0.62, green: 1.0, blue: 0.47, opacity: 0.15),
                    Color(red: 1.0, green: 0.82, blue: 0.39, opacity: 0.15),
                    .clear
                ])

                let rect = CGRect(x: offset, y: 0, width: stripeWidth, height: h)
                context.fill(
                    Path(rect),
                    with: .linearGradient(
                        stripeGradient,
                        startPoint: CGPoint(x: offset, y: 0),
                        endPoint: CGPoint(x: offset + stripeWidth, y: 0)
                    )
                )
            }
        }
    }

    // MARK: - 字号计算

    private func clampedFont(_ geo: GeometryProxy, _ pct: CGFloat, max: CGFloat) -> CGFloat {
        Swift.min(geo.size.width * pct / 100, max)
    }
}
