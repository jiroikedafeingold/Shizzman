import SwiftUI

/// Full-bleed textured background for the game table.
/// Renders the felt colour with an optional Canvas-drawn pattern overlay.
struct FeltBackground: View {
    let theme: FeltColor

    var body: some View {
        theme.felt
            .overlay(
                Canvas { ctx, size in
                    drawTexture(ctx: ctx, size: size)
                }
                .opacity(theme.textureOpacity)
                .allowsHitTesting(false)
            )
    }

    // MARK: - Texture dispatch

    private func drawTexture(ctx: GraphicsContext, size: CGSize) {
        switch theme.texture {
        case .plain:      break
        case .grain:      drawGrain(ctx: ctx, size: size)
        case .crosshatch: drawCrosshatch(ctx: ctx, size: size)
        case .diagonal:   drawDiagonal(ctx: ctx, size: size)
        case .grid:       drawGrid(ctx: ctx, size: size)
        case .horizontal: drawHorizontal(ctx: ctx, size: size)
        }
    }

    // MARK: - Pattern implementations

    /// Staggered dot grid — simulates the fine weave of casino felt.
    private func drawGrain(ctx: GraphicsContext, size: CGSize) {
        let spacing: CGFloat = 3.0
        let r: CGFloat = 0.5
        var row = 0
        var y: CGFloat = 0
        while y <= size.height + spacing {
            let xOff: CGFloat = (row % 2 == 0) ? 0 : spacing / 2
            var x: CGFloat = xOff
            while x <= size.width + spacing {
                ctx.fill(
                    Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)),
                    with: .color(.white)
                )
                x += spacing
            }
            y += spacing
            row += 1
        }
    }

    /// 45° crosshatch lines — classic linen / canvas texture.
    private func drawCrosshatch(ctx: GraphicsContext, size: CGSize) {
        let spacing: CGFloat = 5.0
        var path = Path()
        let h = size.height

        // Lines going down-right
        var x: CGFloat = -h
        while x <= size.width + spacing {
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x + h, y: h))
            x += spacing
        }
        // Lines going down-left
        x = 0
        while x <= size.width + h {
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x - h, y: h))
            x += spacing
        }
        ctx.stroke(path, with: .color(.white), lineWidth: 0.4)
    }

    /// Parallel diagonal lines (one direction) — traditional casino baize.
    private func drawDiagonal(ctx: GraphicsContext, size: CGSize) {
        let spacing: CGFloat = 5.0
        var path = Path()
        let h = size.height

        var x: CGFloat = -h
        while x <= size.width + spacing {
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x + h, y: h))
            x += spacing
        }
        ctx.stroke(path, with: .color(.white), lineWidth: 0.5)
    }

    /// Even horizontal + vertical grid — tight woven fabric.
    private func drawGrid(ctx: GraphicsContext, size: CGSize) {
        let spacing: CGFloat = 7.0
        var path = Path()
        var y: CGFloat = 0
        while y <= size.height {
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: size.width, y: y))
            y += spacing
        }
        var x: CGFloat = 0
        while x <= size.width {
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: size.height))
            x += spacing
        }
        ctx.stroke(path, with: .color(.white), lineWidth: 0.3)
    }

    /// Varied-spacing horizontal lines — suggests wood grain.
    private func drawHorizontal(ctx: GraphicsContext, size: CGSize) {
        let base: CGFloat = 5.0
        var path = Path()
        var y: CGFloat = 0
        var row = 0
        while y <= size.height {
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: size.width, y: y))
            y += (row % 3 == 2) ? base * 1.6 : base
            row += 1
        }
        ctx.stroke(path, with: .color(.white), lineWidth: 0.4)
    }
}
