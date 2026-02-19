//
//  ContentView.swift
//  Timer Vision
//
//  Created by IVAN CAMPOS
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    @StateObject private var timerViewModel = TimerViewModel()
    @State private var inputSeconds: String = ""
    
    let CUSTOM_FONT = "Audiowide-Regular"
    
    var body: some View {
        ZStack {
            Color.white.opacity(0.0).edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                if timerViewModel.timerState == .stopped {
                    TextField("Second", text: $inputSeconds)
                        .padding()
                        .foregroundColor(Color.blue)
                        .background(Color.white)
                        .cornerRadius(5)
                        .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.gray, lineWidth: 1))
                        .keyboardType(.numberPad)
                        .font(.custom(CUSTOM_FONT, size: 36))
                        .multilineTextAlignment(.center)
                        .frame(width: 200)
                        .padding()
                    
                    Button("Start Timer") {
                        if let seconds = Int(inputSeconds) {
                            timerViewModel.startTimer(duration: seconds)
                        }
                    }
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .clipShape(Capsule())
                } else {
                    HStack(alignment: .top, spacing: 24) {
                        VStack(spacing: 8) {
                            PulsingGlowRingView(viewModel: timerViewModel)
                            Text("Glow Ring")
                                .font(.custom(CUSTOM_FONT, size: 12))
                                .foregroundColor(.secondary)
                        }

                        VStack(spacing: 8) {
                            SegmentedArcSparkView(viewModel: timerViewModel)
                            Text("Arc Spark")
                                .font(.custom(CUSTOM_FONT, size: 12))
                                .foregroundColor(.secondary)
                        }

                        VStack(spacing: 8) {
                            MorphingShapeView(viewModel: timerViewModel)
                            Text("Morph")
                                .font(.custom(CUSTOM_FONT, size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                
                if timerViewModel.timerState == .running || timerViewModel.timerState == .paused {
                    HStack(spacing: 16) {
                        Button(timerViewModel.timerState == .running ? "Pause" : "Resume") {
                            if timerViewModel.timerState == .running {
                                timerViewModel.pauseTimer()
                            } else {
                                timerViewModel.resumeTimer()
                            }
                        }
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.orange)
                        .clipShape(Capsule())

                        Button("Cancel") {
                            timerViewModel.cancelTimer()
                        }
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.red)
                        .clipShape(Capsule())
                    }
                }

                if timerViewModel.hasFinished {
                    Button("Stop Sound") {
                        timerViewModel.stopSound()
                    }
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.red)
                    .clipShape(Capsule())
                }
            }
        }
        .font(.custom(CUSTOM_FONT, size: 0.3))
    }
}
