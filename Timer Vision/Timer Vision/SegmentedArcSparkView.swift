//
//  SegmentedArcSparkView.swift
//  Timer Vision
//
//  3D Helix Particle Ring — 60 segments arranged on a rotating 3D helix,
//  projected with perspective division. Painter's algorithm depth sorting
//  gives correct front/back occlusion. Spark + comet trail follow the helix.
//

import SwiftUI

struct SegmentedArcSparkView: View {
    @ObservedObject var viewModel: TimerViewModel

    private let CUSTOM_FONT = "Audiowide-Regular"
    private let segmentCount: Int = 60
    private let helixTurns: Double = 1.5
    private let helixRadius: CGFloat = 52.0
    private let helixPitch: CGFloat = 44.0
    private let focalLength: CGFloat = 200.0
    private let rotSpeedNormal: Double = 0.8   // radians/sec
    private let rotSpeedUrgent: Double = 2.5

    private var isUrgent: Bool { viewModel.progress < 0.2 }

    // Project a helix segment index to 2D screen coordinates + scale factor
    private func project(index: Int, rotAngle: Double, size: CGSize)
        -> (x: CGFloat, y: CGFloat, scale: CGFloat, z: CGFloat)
    {
        let cx = size.width / 2
        let cy = size.height / 2
        let t = Double(index) / Double(segmentCount) * helixTurns * 2 * .pi
        let x3 = helixRadius * CGFloat(cos(t + rotAngle))
        let y3 = helixPitch * CGFloat(t / (helixTurns * 2 * .pi)) - helixPitch / 2
        let z3 = helixRadius * CGFloat(sin(t + rotAngle))
        let scale = focalLength / (z3 + focalLength)
        return (cx + x3 * scale, cy + y3 * scale, scale, z3)
    }

    // Sorted segment indices back-to-front for painter's algorithm
    private func sortedIndices(rotAngle: Double) -> [Int] {
        (0..<segmentCount).sorted { a, b in
            let ta: Double = Double(a) / Double(segmentCount) * helixTurns * 2 * .pi
            let tb: Double = Double(b) / Double(segmentCount) * helixTurns * 2 * .pi
            let za: CGFloat = helixRadius * CGFloat(sin(ta + rotAngle))
            let zb: CGFloat = helixRadius * CGFloat(sin(tb + rotAngle))
            return za < zb
        }
    }

    private func drawHelix(ctx: GraphicsContext, size: CGSize,
                           rotAngle: Double, activeCount: Int) {
        let sorted: [Int] = sortedIndices(rotAngle: rotAngle)

        for i in sorted {
            let p = project(index: i, rotAngle: rotAngle, size: size)
            let isActive: Bool = i < activeCount
            let isBack: Bool = p.z < -10

            let baseOpacity: Double = isActive ? 0.9 : 0.22
            let depthOpacity: Double = isBack ? 0.4 : 1.0
            let opacity: Double = baseOpacity * depthOpacity
            let dotR: CGFloat = max(1.5, 5.0 * p.scale)
            let color: Color = isActive ? .cyan : .gray

            if isActive && !isBack {
                let glowR: CGFloat = dotR * 2.2
                ctx.fill(
                    Path(ellipseIn: CGRect(x: p.x - glowR, y: p.y - glowR,
                                           width: glowR * 2, height: glowR * 2)),
                    with: .color(Color.cyan.opacity(opacity * 0.25))
                )
            }

            ctx.fill(
                Path(ellipseIn: CGRect(x: p.x - dotR, y: p.y - dotR,
                                       width: dotR * 2, height: dotR * 2)),
                with: .color(color.opacity(opacity))
            )
        }
    }

    private func drawSpark(ctx: GraphicsContext, size: CGSize,
                           rotAngle: Double, activeCount: Int, progress: Double) {
        guard !viewModel.hasFinished && progress > 0 else { return }

        let sparkIdx: Int = min(activeCount, segmentCount - 1)
        let sp = project(index: sparkIdx, rotAngle: rotAngle, size: size)
        let sparkR: CGFloat = max(4.0, 10.0 * sp.scale)
        let glowR: CGFloat = sparkR * 1.8

        ctx.fill(
            Path(ellipseIn: CGRect(x: sp.x - glowR, y: sp.y - glowR,
                                   width: glowR * 2, height: glowR * 2)),
            with: .color(Color.white.opacity(0.22))
        )
        ctx.fill(
            Path(ellipseIn: CGRect(x: sp.x - sparkR, y: sp.y - sparkR,
                                   width: sparkR * 2, height: sparkR * 2)),
            with: .color(.white)
        )

        let tailOffsets: [Int] = [1, 2, 3]
        let tailOpacities: [Double] = [0.55, 0.30, 0.12]
        for (j, offset) in tailOffsets.enumerated() {
            let tailIdx: Int = max(0, sparkIdx - offset)
            let tp = project(index: tailIdx, rotAngle: rotAngle, size: size)
            let tailR: CGFloat = max(2.0, 5.0 * tp.scale)
            ctx.fill(
                Path(ellipseIn: CGRect(x: tp.x - tailR, y: tp.y - tailR,
                                       width: tailR * 2, height: tailR * 2)),
                with: .color(Color.cyan.opacity(tailOpacities[j]))
            )
        }
    }

    var body: some View {
        TimelineView(.animation(paused: viewModel.timerState != .running)) { timeline in
            let elapsed: Double = timeline.date.timeIntervalSinceReferenceDate
            let rotAngle: Double = elapsed * (isUrgent ? rotSpeedUrgent : rotSpeedNormal)
            let progress: Double = viewModel.progress
            let activeCount: Int = Int((progress * Double(segmentCount)).rounded(.down))

            Canvas { ctx, size in
                drawHelix(ctx: ctx, size: size, rotAngle: rotAngle, activeCount: activeCount)
                drawSpark(ctx: ctx, size: size, rotAngle: rotAngle, activeCount: activeCount, progress: progress)
            }
            .accessibilityHidden(true)
            .overlay(alignment: .center) {
                Text(viewModel.timeFormatted)
                    .font(.custom(CUSTOM_FONT, size: 22))
                    .fontWeight(.bold)
                    .foregroundColor(viewModel.hasFinished ? .gray : .white)
            }
        }
        .frame(width: 150, height: 150)
        .opacity(viewModel.hasFinished ? 0.4 : 1.0)
    }
}
