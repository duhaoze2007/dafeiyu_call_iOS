import Foundation
import SwiftUI

extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)

        let red: UInt64
        let green: UInt64
        let blue: UInt64
        let alpha: UInt64

        switch cleaned.count {
        case 8:
            red = (value >> 24) & 0xFF
            green = (value >> 16) & 0xFF
            blue = (value >> 8) & 0xFF
            alpha = value & 0xFF
        default:
            red = (value >> 16) & 0xFF
            green = (value >> 8) & 0xFF
            blue = value & 0xFF
            alpha = 0xFF
        }

        self.init(
            .sRGB,
            red: Double(red) / 255.0,
            green: Double(green) / 255.0,
            blue: Double(blue) / 255.0,
            opacity: Double(alpha) / 255.0
        )
    }
}

enum FishTheme {
    static let deep = Color(hex: "#02101C")
    static let ocean = Color(hex: "#07344C")
    static let night = Color(hex: "#041B2B")
    static let mint = Color(hex: "#5FE3C0")
    static let sky = Color(hex: "#6FD3FF")
    static let coral = Color(hex: "#FF91A6")
    static let cream = Color(hex: "#DAF8FF")
    static let ink = Color(hex: "#062033")
    static let panel = Color.white.opacity(0.065)
    static let stroke = Color.white.opacity(0.10)
}

struct OceanBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [FishTheme.deep, FishTheme.ocean, FishTheme.night],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [FishTheme.sky.opacity(0.20), .clear],
                center: .topLeading,
                startRadius: 10,
                endRadius: 420
            )

            RadialGradient(
                colors: [FishTheme.mint.opacity(0.12), .clear],
                center: .bottomTrailing,
                startRadius: 10,
                endRadius: 380
            )

            LightRays()
            BubbleField()
        }
        .ignoresSafeArea()
    }
}

private struct LightRays: View {
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(0..<3, id: \.self) { index in
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.10), .white.opacity(0.0)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 64, height: proxy.size.height * 0.9)
                        .rotationEffect(.degrees(Double(index) * 10 - 10))
                        .offset(
                            x: CGFloat(index - 1) * 145,
                            y: -proxy.size.height * 0.38
                        )
                        .blur(radius: 26)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct BubbleField: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 15.0)) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                let width = Double(max(size.width, 1))
                let height = Double(max(size.height, 1))

                for index in 0..<16 {
                    let seed = Double(index)
                    let diameter = 3.0 + (seed * 7.3).truncatingRemainder(dividingBy: 13.0)
                    let speed = 8.0 + (seed * 5.1).truncatingRemainder(dividingBy: 16.0)
                    let baseX = (seed * 97.0 + 31.0).truncatingRemainder(dividingBy: width)
                    let x = baseX + sin(time * 0.35 + seed) * 10.0
                    let travel = height + 120.0
                    let y = height + 60.0 - ((time * speed + seed * 73.0).truncatingRemainder(dividingBy: travel))
                    let rect = CGRect(
                        x: CGFloat(x),
                        y: CGFloat(y),
                        width: CGFloat(diameter),
                        height: CGFloat(diameter)
                    )
                    let path = Path(ellipseIn: rect)

                    context.fill(path, with: .color(Color.white.opacity(0.07)))
                    context.stroke(path, with: .color(Color.white.opacity(0.15)), lineWidth: 0.7)
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
