//
//  PulsingGlowRingView.swift
//  Timer Vision
//
//  Gyroscope Orbital Rings — three concentric rings each tilted on a different
//  axis and driven by wall-clock time through TimelineView, creating an orrery /
//  gyroscope illusion. Urgency triples spin speed and shifts ring colors.
//

import SwiftUI

struct PulsingGlowRingView: View {
    @ObservedObject var viewModel: TimerViewModel

    private let CUSTOM_FONT = "Audiowide-Regular"

    private var isUrgent: Bool { viewModel.progress < 0.2 }
    private var speedMult: Double { isUrgent ? 3.0 : 1.0 }

    private var progressColor: Color {
        if viewModel.hasFinished { return .gray }
        return isUrgent ? .red : .green
    }

    private var accentColor: Color {
        if viewModel.hasFinished { return .gray }
        return isUrgent ? .orange : .cyan
    }

    var body: some View {
        TimelineView(.animation(paused: viewModel.timerState != .running)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let sm = speedMult

            ZStack {
                // ── Outer track ring ───────────────────────────────────────
                // Thin full ring, static x-tilt, slow Y-spin
                Circle()
                    .stroke(lineWidth: 3)
                    .foregroundColor(progressColor.opacity(0.28))
                    .frame(width: 140, height: 140)
                    // Static structural tilt
                    .rotation3DEffect(.degrees(15), axis: (x: 1, y: 0, z: 0))
                    // Time-driven Y spin
                    .rotation3DEffect(
                        .degrees(t * 6.0 * sm),
                        axis: (x: 0, y: 1, z: 0),
                        perspective: 0.35
                    )

                // ── Second decorative ring ─────────────────────────────────
                // Slightly inset, opposite axis tilt, Z-spin
                Circle()
                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [6, 8]))
                    .foregroundColor(accentColor.opacity(0.35))
                    .frame(width: 130, height: 130)
                    .rotation3DEffect(.degrees(-20), axis: (x: 0, y: 1, z: 0))
                    .rotation3DEffect(
                        .degrees(t * 5.0 * sm),
                        axis: (x: 0, y: 0, z: 1),
                        perspective: 0.4
                    )

                // ── Middle progress ring ───────────────────────────────────
                // Carries the .trim countdown arc + glow. Static x-tilt, X-spin.
                ZStack {
                    // Track
                    Circle()
                        .stroke(lineWidth: 12)
                        .foregroundColor(.gray.opacity(0.18))
                        .frame(width: 116, height: 116)

                    // Progress arc
                    Circle()
                        .trim(from: 0, to: viewModel.hasFinished ? 0 : CGFloat(viewModel.progress))
                        .stroke(style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .foregroundColor(progressColor)
                        .rotationEffect(.degrees(-90))
                        .shadow(
                            color: viewModel.hasFinished ? .clear : progressColor.opacity(0.9),
                            radius: 14
                        )
                        .frame(width: 116, height: 116)
                        .animation(.linear(duration: 1), value: viewModel.progress)
                }
                .rotation3DEffect(.degrees(-10), axis: (x: 1, y: 0, z: 0))
                .rotation3DEffect(
                    .degrees(-(t * 4.0 * sm)),   // spins in opposite direction
                    axis: (x: 1, y: 0, z: 0),
                    perspective: 0.4
                )

                // ── Inner accent ring ──────────────────────────────────────
                // Glowing small ring, z-tilt, Y-spin opposite direction
                Circle()
                    .stroke(lineWidth: 5)
                    .foregroundColor(accentColor.opacity(0.75))
                    .frame(width: 92, height: 92)
                    .shadow(color: accentColor.opacity(0.65), radius: 8)
                    .rotation3DEffect(.degrees(5), axis: (x: 0, y: 0, z: 1))
                    .rotation3DEffect(
                        .degrees(-(t * 8.0 * sm)),
                        axis: (x: 0, y: 1, z: 0),
                        perspective: 0.45
                    )

                // ── Innermost decorative ring ──────────────────────────────
                Circle()
                    .stroke(lineWidth: 1.5)
                    .foregroundColor(progressColor.opacity(0.4))
                    .frame(width: 68, height: 68)
                    .rotation3DEffect(.degrees(30), axis: (x: 1, y: 1, z: 0))
                    .rotation3DEffect(
                        .degrees(t * 10.0 * sm),
                        axis: (x: 1, y: 0, z: 0),
                        perspective: 0.5
                    )

                // ── Time label ────────────────────────────────────────────
                Text(viewModel.timeFormatted)
                    .font(.custom(CUSTOM_FONT, size: 22))
                    .fontWeight(.bold)
                    .foregroundColor(viewModel.hasFinished ? .gray : .white)
            }
            .opacity(viewModel.timerState == .paused ? 0.6 : 1.0)
        }
        .frame(width: 150, height: 150)
    }
}
