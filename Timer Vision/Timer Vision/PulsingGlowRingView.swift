//
//  PulsingGlowRingView.swift
//  Timer Vision
//

import SwiftUI

struct PulsingGlowRingView: View {
    @ObservedObject var viewModel: TimerViewModel
    @State private var pulsing: Bool = false
    @State private var wasUrgent: Bool = false

    private let CUSTOM_FONT = "Audiowide-Regular"

    private var isUrgent: Bool { viewModel.progress < 0.2 }
    private var ringColor: Color { isUrgent ? .red : .green }
    private var pulseAnimation: Animation {
        isUrgent
            ? .easeInOut(duration: 0.4).repeatForever(autoreverses: true)
            : .easeInOut(duration: 1.8).repeatForever(autoreverses: true)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 16)
                .foregroundColor(.gray.opacity(0.3))

            Circle()
                .trim(from: 0, to: viewModel.hasFinished ? 0 : CGFloat(viewModel.progress))
                .stroke(style: StrokeStyle(lineWidth: 16, lineCap: .round))
                .foregroundColor(viewModel.hasFinished ? .gray : ringColor)
                .rotationEffect(.degrees(-90))
                .shadow(color: viewModel.hasFinished ? .clear : ringColor.opacity(0.8), radius: 12)
                .animation(.linear, value: viewModel.progress)

            Text(viewModel.timeFormatted)
                .font(.custom(CUSTOM_FONT, size: 24))
                .fontWeight(.bold)
                .foregroundColor(viewModel.hasFinished ? .gray : .white)
        }
        .scaleEffect(pulsing ? 1.04 : 0.96)
        .opacity(viewModel.timerState == .paused ? 0.6 : (pulsing ? 1.0 : 0.75))
        .animation(
            viewModel.timerState == .paused || viewModel.hasFinished ? .default : pulseAnimation,
            value: pulsing
        )
        .frame(width: 150, height: 150)
        .onAppear {
            if viewModel.timerState == .running {
                pulsing = true
            }
        }
        .onChange(of: viewModel.timerState) { _, newState in
            switch newState {
            case .running:
                restartPulse()
            case .paused, .stopped, .finished:
                pulsing = false
            }
        }
        .onChange(of: viewModel.progress) { _, _ in
            let urgent = isUrgent
            if urgent != wasUrgent {
                wasUrgent = urgent
                pulsing = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    if viewModel.timerState == .running {
                        pulsing = true
                    }
                }
            }
        }
    }

    private func restartPulse() {
        pulsing = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            pulsing = true
        }
    }
}
