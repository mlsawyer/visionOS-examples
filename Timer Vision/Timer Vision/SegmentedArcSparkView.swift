//
//  SegmentedArcSparkView.swift
//  Timer Vision
//

import SwiftUI

struct SegmentedArcSparkView: View {
    @ObservedObject var viewModel: TimerViewModel

    private let CUSTOM_FONT = "Audiowide-Regular"
    private let segmentCount: Int = 60
    private let gapFraction: Double = 0.18

    var body: some View {
        TimelineView(.animation(paused: viewModel.timerState != .running)) { _ in
            Canvas { ctx, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let radius: CGFloat = size.width / 2 - 14
                let segAngle = 2 * Double.pi / Double(segmentCount)
                let arcSpan = segAngle * (1.0 - gapFraction)
                let progress = viewModel.progress
                let activeCount = Int((progress * Double(segmentCount)).rounded(.down))

                // Draw segments
                for i in 0..<segmentCount {
                    let startAngle = Double(i) * segAngle - Double.pi / 2
                    let isActive = i < activeCount
                    var segPath = Path()
                    segPath.addArc(
                        center: center,
                        radius: radius,
                        startAngle: Angle(radians: startAngle),
                        endAngle: Angle(radians: startAngle + arcSpan),
                        clockwise: false
                    )
                    ctx.stroke(
                        segPath,
                        with: .color(isActive ? .cyan.opacity(0.9) : .gray.opacity(0.25)),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                }

                guard !viewModel.hasFinished && progress > 0 else { return }

                // Spark position at leading edge of progress
                let sparkAngle = progress * 2 * Double.pi - Double.pi / 2
                let sparkX = center.x + radius * cos(sparkAngle)
                let sparkY = center.y + radius * sin(sparkAngle)

                // Comet tail dots
                let tailOffsets: [Double] = [0.04, 0.08, 0.13]
                let tailOpacities: [Double] = [0.55, 0.30, 0.12]
                let tailSizes: [CGFloat] = [5, 4, 3]

                for (i, offset) in tailOffsets.enumerated() {
                    let tailProgress = max(0, progress - offset)
                    let tailAngle = tailProgress * 2 * Double.pi - Double.pi / 2
                    let tx = center.x + radius * cos(tailAngle)
                    let ty = center.y + radius * sin(tailAngle)
                    let ts = tailSizes[i]
                    let tailRect = CGRect(x: tx - ts/2, y: ty - ts/2, width: ts, height: ts)
                    ctx.fill(Path(ellipseIn: tailRect), with: .color(.cyan.opacity(tailOpacities[i])))
                }

                // Glow halo behind spark
                let glowRect = CGRect(x: sparkX - 10, y: sparkY - 10, width: 20, height: 20)
                ctx.fill(Path(ellipseIn: glowRect), with: .color(.white.opacity(0.25)))

                // Main spark dot
                let sparkRect = CGRect(x: sparkX - 6, y: sparkY - 6, width: 12, height: 12)
                ctx.fill(Path(ellipseIn: sparkRect), with: .color(.white))
            }
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
