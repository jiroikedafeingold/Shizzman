import SwiftUI

struct ConfettiView: View {
    private struct Particle {
        let startX:   CGFloat       // normalised 0–1
        let delay:    Double        // seconds before appearing
        let speed:    CGFloat       // pts / second downward
        let drift:    CGFloat       // pts / second sideways
        let spinRate: Double        // degrees / second
        let size:     CGFloat
        let color:    Color
        let symbol:   String?       // nil → small rectangle
    }

    private let particles: [Particle]
    private let startDate: Date = .now

    init() {
        let colors: [Color] = [
            Theme.valid, Theme.reset, Theme.burn, Theme.low, Theme.hint,
            .white.opacity(0.85), Theme.valid.opacity(0.6), Theme.reset.opacity(0.7)
        ]
        let suits = ["♠", "♥", "♦", "♣"]
        particles = (0..<80).map { _ in
            // ~40 % are suit symbols, rest are rectangles
            let useSymbol = CGFloat.random(in: 0...1) < 0.4
            return Particle(
                startX:   CGFloat.random(in: 0...1),
                delay:    Double.random(in: 0...2.0),
                speed:    CGFloat.random(in: 180...380),
                drift:    CGFloat.random(in: -50...50),
                spinRate: Double.random(in: -300...300),
                size:     CGFloat.random(in: 7...15),
                color:    colors.randomElement()!,
                symbol:   useSymbol ? suits.randomElement()! : nil
            )
        }
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
            Canvas { ctx, size in
                let elapsed = timeline.date.timeIntervalSince(startDate)
                for p in particles {
                    let t = CGFloat(max(0, elapsed - p.delay))
                    guard t > 0 else { continue }

                    // Loop vertically: particle wraps from bottom back to top
                    let rawY  = t * p.speed
                    let y     = rawY.truncatingRemainder(dividingBy: size.height + 40) - 20
                    let x     = (p.startX * size.width + p.drift * t)
                                    .truncatingRemainder(dividingBy: size.width)
                    let angle = Angle.degrees(p.spinRate * Double(t))

                    var copy  = ctx
                    copy.transform = CGAffineTransform(translationX: x, y: y)
                        .rotated(by: CGFloat(angle.radians))

                    if let sym = p.symbol {
                        let resolved = copy.resolve(
                            Text(sym)
                                .font(.system(size: p.size))
                                .foregroundStyle(p.color)
                        )
                        copy.draw(resolved, at: .zero, anchor: .center)
                    } else {
                        let rect = Path(CGRect(
                            x: -p.size / 2, y: -p.size * 0.3,
                            width: p.size, height: p.size * 0.55
                        ))
                        copy.fill(rect, with: .color(p.color))
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}
