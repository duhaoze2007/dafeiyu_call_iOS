import Combine
import Foundation
import SwiftUI

struct FatFishView: View {
    let isSpeaking: Bool
    let isListening: Bool

    @State private var bob = false
    @State private var blink = false

    private let blinkTimer = Timer.publish(every: 4.3, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height

            ZStack {
                Ellipse()
                    .fill(FishTheme.sky.opacity(0.16))
                    .frame(width: width * 0.78, height: height * 0.48)
                    .blur(radius: 30)

                FishTailShape()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#3FB5E8"), Color(hex: "#155E8C")],
                            startPoint: .topTrailing,
                            endPoint: .bottomLeading
                        )
                    )
                    .frame(width: width * 0.30, height: height * 0.31)
                    .rotationEffect(.degrees(-6))
                    .offset(x: -width * 0.36, y: height * 0.02)

                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#63D2FF"), Color(hex: "#1E7DBE")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: width * 0.76, height: height * 0.55)
                    .overlay(
                        Ellipse()
                            .stroke(.white.opacity(0.18), lineWidth: 1)
                    )
                    .shadow(color: FishTheme.sky.opacity(0.38), radius: 26, y: 12)
                    .offset(x: width * 0.02, y: height * 0.02)

                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [
                                FishTheme.cream.opacity(0.88),
                                FishTheme.cream.opacity(0.18)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: width * 0.56, height: height * 0.29)
                    .offset(x: width * 0.03, y: height * 0.15)

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#43B8E8"), Color(hex: "#1A6F9E")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: width * 0.18, height: height * 0.12)
                    .rotationEffect(.degrees(-22))
                    .offset(x: width * 0.02, y: -height * 0.28)

                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#39A9DE"), Color(hex: "#1E76A8")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: width * 0.17, height: height * 0.075)
                    .rotationEffect(.degrees(32))
                    .offset(x: -width * 0.29, y: -height * 0.005)

                Ellipse()
                    .fill(.white.opacity(0.13))
                    .frame(width: width * 0.28, height: height * 0.07)
                    .rotationEffect(.degrees(-14))
                    .blur(radius: 4)
                    .offset(x: -width * 0.15, y: -height * 0.15)

                eye(width: width * 0.050, height: height * 0.074)
                    .offset(x: width * 0.055, y: -height * 0.065)
                eye(width: width * 0.050, height: height * 0.074)
                    .offset(x: width * 0.205, y: -height * 0.065)

                Ellipse()
                    .fill(FishTheme.coral.opacity(0.36))
                    .frame(width: width * 0.068, height: height * 0.033)
                    .blur(radius: 1.5)
                    .offset(x: -width * 0.045, y: height * 0.075)

                Ellipse()
                    .fill(FishTheme.coral.opacity(0.36))
                    .frame(width: width * 0.068, height: height * 0.033)
                    .blur(radius: 1.5)
                    .offset(x: width * 0.29, y: height * 0.075)

                FishMouth(
                    width: width * 0.075,
                    height: height * 0.040,
                    isSpeaking: isSpeaking
                )
                .offset(x: width * 0.13, y: height * 0.09)

                if isListening {
                    Image(systemName: "sparkle")
                        .font(.system(size: width * 0.045, weight: .semibold))
                        .foregroundStyle(FishTheme.mint.opacity(0.85))
                        .offset(x: width * 0.40, y: -height * 0.24)
                    Image(systemName: "sparkle")
                        .font(.system(size: width * 0.030, weight: .semibold))
                        .foregroundStyle(FishTheme.mint.opacity(0.55))
                        .offset(x: width * 0.46, y: -height * 0.11)
                }
            }
            .frame(width: width, height: height)
            .offset(y: bob ? -7 : 7)
            .rotationEffect(.degrees(bob ? 1.4 : -1.4))
            .animation(.easeInOut(duration: 2.9).repeatForever(autoreverses: true), value: bob)
            .onAppear { bob = true }
            .onReceive(blinkTimer) { _ in
                withAnimation(.easeInOut(duration: 0.07)) { blink = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
                    withAnimation(.easeInOut(duration: 0.09)) { blink = false }
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("大肥鱼，圆滚滚的蓝色小鲸鱼")
        .accessibilityHint(isSpeaking ? "轻点可以打断它" : "轻点可以开始说话")
    }

    private func eye(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            Ellipse()
                .fill(FishTheme.ink)
                .frame(width: width, height: height)
            Circle()
                .fill(.white.opacity(0.95))
                .frame(width: width * 0.39)
                .offset(x: -width * 0.12, y: -height * 0.22)
            Circle()
                .fill(.white.opacity(0.50))
                .frame(width: width * 0.16)
                .offset(x: width * 0.18, y: height * 0.20)
        }
        .scaleEffect(x: 1, y: blink ? 0.10 : 1)
    }
}

private struct FishMouth: View {
    let width: CGFloat
    let height: CGFloat
    let isSpeaking: Bool

    var body: some View {
        if isSpeaking {
            TimelineView(.animation(minimumInterval: 1.0 / 15.0)) { timeline in
                let phase = sin(timeline.date.timeIntervalSinceReferenceDate * 13.0)
                let openness = 0.55 + 0.45 * (phase * 0.5 + 0.5)

                ZStack(alignment: .bottom) {
                    Ellipse()
                        .fill(FishTheme.ink.opacity(0.86))
                        .frame(width: width, height: height * CGFloat(openness))
                    Ellipse()
                        .fill(FishTheme.coral.opacity(0.78))
                        .frame(width: width * 0.52, height: height * 0.30)
                        .offset(y: -height * 0.05)
                }
                .frame(width: width, height: height, alignment: .center)
            }
        } else {
            SmileShape()
                .stroke(
                    FishTheme.ink.opacity(0.78),
                    style: StrokeStyle(lineWidth: 2.2, lineCap: .round)
                )
                .frame(width: width, height: height * 0.7)
        }
    }
}

private struct SmileShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.midY),
            control: CGPoint(x: rect.midX, y: rect.maxY)
        )
        return path
    }
}

private struct FishTailShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addCurve(
            to: CGPoint(x: rect.minX, y: rect.minY),
            control1: CGPoint(x: rect.midX, y: rect.midY),
            control2: CGPoint(x: rect.minX + rect.width * 0.18, y: rect.minY + rect.height * 0.18)
        )
        path.addCurve(
            to: CGPoint(x: rect.minX, y: rect.maxY),
            control1: CGPoint(x: rect.minX + rect.width * 0.20, y: rect.midY),
            control2: CGPoint(x: rect.midX, y: rect.maxY)
        )
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: rect.midY),
            control1: CGPoint(x: rect.midX, y: rect.maxY),
            control2: CGPoint(x: rect.midX, y: rect.midY)
        )
        path.closeSubpath()
        return path
    }
}

struct PulseRings: View {
    let active: Bool
    var color: Color = FishTheme.mint

    @State private var animate = false

    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .stroke(color.opacity(active ? 0.28 : 0), lineWidth: 1)
                    .scaleEffect(animate ? 1.18 : 0.72)
                    .opacity(animate ? 0 : 0.5)
                    .animation(
                        .easeOut(duration: 2.8)
                            .repeatForever(autoreverses: false)
                            .delay(Double(index) * 0.85),
                        value: animate
                    )
            }
        }
        .onAppear { animate = true }
        .allowsHitTesting(false)
    }
}
