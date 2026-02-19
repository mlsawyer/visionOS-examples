//
//  MorphingShapeView.swift
//  Timer Vision
//
//  3D Morphing RealityKit Polyhedron — a real 3D ModelEntity (rounded box) that
//  steps through 5 shape stages as time elapses, spinning continuously on Y axis,
//  and shifting color blue → teal → green → orange → red → gray (finished).
//
//  MorphingTimerShape is retained below as a 2D Shape fallback (unused by the view).
//

import SwiftUI
import RealityKit

// MARK: - Morph Stage

private enum MorphStage: Equatable {
    case spherelike
    case roundedHeavy
    case roundedMedium
    case roundedLight
    case cubelike
    case finished

    static func from(progress: Double, hasFinished: Bool) -> MorphStage {
        if hasFinished { return .finished }
        switch progress {
        case 0.8...1.01: return .spherelike
        case 0.6..<0.8:  return .roundedHeavy
        case 0.4..<0.6:  return .roundedMedium
        case 0.2..<0.4:  return .roundedLight
        default:         return .cubelike
        }
    }

    // size = 0.076 m, half = 0.038 m. All cornerRadius < 0.038 ✓
    var cornerRadius: Float {
        let h: Float = 0.038
        switch self {
        case .spherelike:    return h * 0.92    // 0.03496 — near sphere
        case .roundedHeavy:  return h * 0.65    // 0.02470
        case .roundedMedium: return h * 0.40    // 0.01520
        case .roundedLight:  return h * 0.18    // 0.00684
        case .cubelike:      return h * 0.04    // 0.00152
        case .finished:      return h * 0.04
        }
    }

    var uiColor: UIColor {
        switch self {
        case .spherelike:    return UIColor(red: 0.20, green: 0.55, blue: 1.00, alpha: 1)  // blue
        case .roundedHeavy:  return UIColor(red: 0.10, green: 0.80, blue: 0.70, alpha: 1)  // teal
        case .roundedMedium: return UIColor(red: 0.35, green: 0.80, blue: 0.30, alpha: 1)  // green
        case .roundedLight:  return UIColor(red: 1.00, green: 0.55, blue: 0.10, alpha: 1)  // orange
        case .cubelike:      return UIColor(red: 1.00, green: 0.18, blue: 0.10, alpha: 1)  // red
        case .finished:      return UIColor(red: 0.50, green: 0.50, blue: 0.50, alpha: 1)  // gray
        }
    }
}

// MARK: - MorphingShapeView

struct MorphingShapeView: View {
    @ObservedObject var viewModel: TimerViewModel

    private let CUSTOM_FONT = "Audiowide-Regular"
    private let boxSize: Float = 0.076                 // metres
    private let spinSpeedNormal: Double = 0.5          // rad/sec
    private let spinSpeedUrgent: Double = 1.5

    @State private var entity: ModelEntity? = nil
    @State private var lastStage: MorphStage? = nil
    @State private var spinAngle: Double = 0

    private var isUrgent: Bool { viewModel.progress < 0.2 }
    private var currentStage: MorphStage {
        MorphStage.from(progress: viewModel.progress, hasFinished: viewModel.hasFinished)
    }

    var body: some View {
        ZStack {
            // ── RealityKit 3D entity ───────────────────────────────────────
            TimelineView(.animation(paused: viewModel.timerState != .running)) { timeline in
                let speed = isUrgent ? spinSpeedUrgent : spinSpeedNormal
                let angle = timeline.date.timeIntervalSinceReferenceDate * speed

                RealityView { content in
                    let e = ModelEntity()
                    e.name = "morphBox"
                    applyStage(currentStage, to: e)
                    content.add(e)
                    Task { @MainActor in entity = e }
                } update: { _ in
                    guard let e = entity else { return }

                    // Update mesh only on stage change
                    let stage = currentStage
                    if stage != lastStage {
                        applyStage(stage, to: e)
                        Task { @MainActor in lastStage = stage }
                    }

                    // Continuous Y-rotation driven by wall-clock angle
                    e.orientation = simd_quatf(angle: Float(angle), axis: [0, 1, 0])

                    // Scale: shrink slightly when paused / finished
                    let targetScale: Float = viewModel.hasFinished ? 0.82
                        : (viewModel.timerState == .paused ? 0.90 : 1.0)
                    e.scale = SIMD3<Float>(repeating: targetScale)
                }
                .frame(width: 150, height: 150)
            }

            // ── Time label overlay ────────────────────────────────────────
            Text(viewModel.timeFormatted)
                .font(.custom(CUSTOM_FONT, size: 22))
                .fontWeight(.bold)
                .foregroundColor(viewModel.hasFinished ? .gray : .white)
                // Push label below entity centre so it doesn't overlap
                .offset(y: 52)
        }
        .frame(width: 150, height: 150)
    }

    // MARK: - Helpers

    private func applyStage(_ stage: MorphStage, to entity: ModelEntity) {
        guard let mesh = try? MeshResource.generateBox(
            size: boxSize,
            cornerRadius: stage.cornerRadius
        ) else { return }

        var mat = SimpleMaterial()
        mat.color = .init(tint: stage.uiColor)
        mat.roughness = MaterialScalarParameter(floatLiteral: 0.28)
        mat.metallic  = MaterialScalarParameter(floatLiteral: 0.65)
        entity.model = ModelComponent(mesh: mesh, materials: [mat])
    }
}

// MARK: - MorphingTimerShape (2D fallback, retained for reference)

private let k: CGFloat = 0.5522847498

struct MorphingTimerShape: Shape {
    var morphFactor: Double

    var animatableData: Double {
        get { morphFactor }
        set { morphFactor = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let cx = rect.midX, cy = rect.midY
        let r = min(rect.width, rect.height) / 2
        let cr = r * 0.28
        let f = CGFloat(morphFactor)

        func pt(_ c: CGPoint, _ s: CGPoint) -> CGPoint {
            CGPoint(x: c.x + (s.x - c.x) * f, y: c.y + (s.y - c.y) * f)
        }

        let kc = k * cr
        let trC = CGPoint(x: cx + r - cr, y: cy - r + cr)
        let brC = CGPoint(x: cx + r - cr, y: cy + r - cr)
        let blC = CGPoint(x: cx - r + cr, y: cy + r - cr)
        let tlC = CGPoint(x: cx - r + cr, y: cy - r + cr)

        let cTop   = CGPoint(x: cx,     y: cy - r)
        let cRight = CGPoint(x: cx + r, y: cy)
        let cBot   = CGPoint(x: cx,     y: cy + r)
        let cLeft  = CGPoint(x: cx - r, y: cy)

        let sTRts = CGPoint(x: cx + r - cr, y: cy - r)
        let sBRre = CGPoint(x: cx + r,      y: cy + r - cr)
        let sBLbe = CGPoint(x: cx - r + cr, y: cy + r)
        let sTLle = CGPoint(x: cx - r,      y: cy - r + cr)

        var p = Path()
        p.move(to: pt(cTop, CGPoint(x: cx, y: cy - r)))

        p.addCurve(
            to: pt(CGPoint(x: cx + r * 0.707, y: cy - r * 0.707), sTRts),
            control1: pt(CGPoint(x: cx + k*r*0.5, y: cy - r), CGPoint(x: cx, y: cy - r)),
            control2: pt(CGPoint(x: cx + r, y: cy - k*r*0.5), sTRts)
        )
        p.addCurve(
            to: pt(cRight, CGPoint(x: cx + r, y: cy)),
            control1: pt(CGPoint(x: cx + r, y: cy - k*r*0.5), CGPoint(x: trC.x + cr, y: trC.y - kc)),
            control2: pt(CGPoint(x: cx + k*r*0.5, y: cy), CGPoint(x: trC.x + kc, y: trC.y - cr))
        )
        p.addCurve(
            to: pt(CGPoint(x: cx + r*0.707, y: cy + r*0.707), sBRre),
            control1: pt(CGPoint(x: cx + r, y: cy + k*r*0.5), CGPoint(x: cx + r, y: cy)),
            control2: pt(CGPoint(x: cx + r*0.5, y: cy + r), sBRre)
        )
        p.addCurve(
            to: pt(cBot, CGPoint(x: cx, y: cy + r)),
            control1: pt(CGPoint(x: cx + r*0.5, y: cy + r), CGPoint(x: brC.x + cr, y: brC.y + kc)),
            control2: pt(CGPoint(x: cx + k*r*0.5, y: cy + r), CGPoint(x: brC.x + kc, y: brC.y + cr))
        )
        p.addCurve(
            to: pt(CGPoint(x: cx - r*0.707, y: cy + r*0.707), sBLbe),
            control1: pt(CGPoint(x: cx - k*r*0.5, y: cy + r), CGPoint(x: cx, y: cy + r)),
            control2: pt(CGPoint(x: cx - r, y: cy + k*r*0.5), sBLbe)
        )
        p.addCurve(
            to: pt(cLeft, CGPoint(x: cx - r, y: cy)),
            control1: pt(CGPoint(x: cx - r, y: cy + k*r*0.5), CGPoint(x: blC.x - kc, y: blC.y + cr)),
            control2: pt(CGPoint(x: cx - r, y: cy - k*r*0.5), CGPoint(x: blC.x - cr, y: blC.y + kc))
        )
        p.addCurve(
            to: pt(CGPoint(x: cx - r*0.707, y: cy - r*0.707), sTLle),
            control1: pt(CGPoint(x: cx - r, y: cy - k*r*0.5), CGPoint(x: cx - r, y: cy)),
            control2: pt(CGPoint(x: cx - r*0.5, y: cy - r), sTLle)
        )
        p.addCurve(
            to: pt(cTop, CGPoint(x: cx, y: cy - r)),
            control1: pt(CGPoint(x: cx - r*0.5, y: cy - r), CGPoint(x: tlC.x - kc, y: tlC.y - cr)),
            control2: pt(CGPoint(x: cx - k*r*0.5, y: cy - r), CGPoint(x: tlC.x - cr, y: tlC.y - kc))
        )
        p.closeSubpath()
        return p
    }
}
