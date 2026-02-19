//
//  MorphingShapeView.swift
//  Timer Vision
//

import SwiftUI

// Bezier circle approximation constant: 4*(sqrt(2)-1)/3
private let k: CGFloat = 0.5522847498

struct MorphingTimerShape: Shape {
    var morphFactor: Double  // 0.0 = circle, 1.0 = rounded square

    var animatableData: Double {
        get { morphFactor }
        set { morphFactor = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        let cx = rect.midX
        let cy = rect.midY
        let r = min(w, h) / 2           // circle radius
        let cr = r * 0.28               // corner radius for rounded-square
        let f = CGFloat(morphFactor)

        // Helper: lerp between circle point and square point
        func pt(_ circle: CGPoint, _ square: CGPoint) -> CGPoint {
            CGPoint(
                x: circle.x + (square.x - circle.x) * f,
                y: circle.y + (square.y - circle.y) * f
            )
        }

        // Circle key points (4 cardinal anchors, k*r for control points)
        // Square key points (edges at ±r, corners rounded by cr)
        //
        // We model the path as 4 cubic bezier segments (one per quadrant).
        // Each segment goes from a cardinal point clockwise to the next.
        // Starting from the top (12 o'clock), going clockwise.

        // Anchor points on circle
        let cTop    = CGPoint(x: cx,     y: cy - r)
        let cRight  = CGPoint(x: cx + r, y: cy)
        let cBottom = CGPoint(x: cx,     y: cy + r)
        let cLeft   = CGPoint(x: cx - r, y: cy)

        // Anchor points on rounded-square
        // Top edge: from (-r+cr, -r) to (r-cr, -r)
        // Right edge: from (r, -r+cr) to (r, r-cr)
        // etc.
        // We split each side at the midpoint to match the circle's cardinal anchor
        let sTop    = CGPoint(x: cx,     y: cy - r)         // top center
        let sRight  = CGPoint(x: cx + r, y: cy)             // right center
        let sBottom = CGPoint(x: cx,     y: cy + r)         // bottom center
        let sLeft   = CGPoint(x: cx - r, y: cy)             // left center

        // Corner points (where arcs meet straight edges) on rounded-square
        let sTR_topStart    = CGPoint(x: cx + r - cr, y: cy - r)        // top-right: top edge end
        let sTR_rightStart  = CGPoint(x: cx + r,      y: cy - r + cr)   // top-right: right edge start
        let sBR_rightEnd    = CGPoint(x: cx + r,      y: cy + r - cr)   // bottom-right: right edge end
        let sBR_bottomStart = CGPoint(x: cx + r - cr, y: cy + r)        // bottom-right: bottom edge start
        let sBL_bottomEnd   = CGPoint(x: cx - r + cr, y: cy + r)        // bottom-left: bottom edge end
        let sBL_leftStart   = CGPoint(x: cx - r,      y: cy + r - cr)   // bottom-left: left edge start
        let sTL_leftEnd     = CGPoint(x: cx - r,      y: cy - r + cr)   // top-left: left edge end
        let sTL_topStart    = CGPoint(x: cx - r + cr, y: cy - r)        // top-left: top edge start

        // Control points for circle (tangent handles)
        // Top → Right segment
        let cCP1_TR = CGPoint(x: cx + k*r, y: cy - r)
        let cCP2_TR = CGPoint(x: cx + r,   y: cy - k*r)
        // Right → Bottom segment
        let cCP1_RB = CGPoint(x: cx + r,   y: cy + k*r)
        let cCP2_RB = CGPoint(x: cx + k*r, y: cy + r)
        // Bottom → Left segment
        let cCP1_BL = CGPoint(x: cx - k*r, y: cy + r)
        let cCP2_BL = CGPoint(x: cx - r,   y: cy + k*r)
        // Left → Top segment
        let cCP1_LT = CGPoint(x: cx - r,   y: cy - k*r)
        let cCP2_LT = CGPoint(x: cx - k*r, y: cy - r)

        // Control points for rounded-square corners (Bezier arc approx, radius=cr)
        // Top-right corner: from sTR_topStart to sTR_rightStart
        let sCP1_TR = CGPoint(x: cx + r,       y: cy - r)
        let sCP2_TR = CGPoint(x: cx + r,       y: cy - r)
        // We need control points at the corner tangent
        // For a 90° bezier arc of radius cr centered at (cx+r-cr, cy-r+cr):
        let trCenter = CGPoint(x: cx + r - cr, y: cy - r + cr)
        let sCP1_TRarc = CGPoint(x: trCenter.x + cr,       y: trCenter.y - cr)        // = (cx+r, cy-r)... simplified
        let sCP2_TRarc = CGPoint(x: trCenter.x + cr,       y: trCenter.y - cr)

        // For cleaner code, compute rounded rect as two halves per quadrant:
        // Half 1 (straight to corner start): straight line → use same point for both CPs
        // Half 2 (corner arc): use the k*cr tangent offset

        let kc = k * cr

        // Top-right corner center
        let trC = CGPoint(x: cx + r - cr, y: cy - r + cr)
        // Bottom-right corner center
        let brC = CGPoint(x: cx + r - cr, y: cy + r - cr)
        // Bottom-left corner center
        let blC = CGPoint(x: cx - r + cr, y: cy + r - cr)
        // Top-left corner center
        let tlC = CGPoint(x: cx - r + cr, y: cy - r + cr)

        var path = Path()

        // Start at top center
        path.move(to: pt(cTop, sTop))

        // Segment 1: Top → Right (top-right quadrant)
        // Circle: single cubic from cTop to cRight
        // Square: straight from sTop to sTR_topStart, then bezier corner to sTR_rightStart, straight to sRight
        // We approximate as two cubics blended together:
        //   Sub-seg A: top-center → top-right corner start
        //   Sub-seg B: top-right corner arc → right-center

        // Sub-seg A: sTop → sTR_topStart (straight on square, arc on circle)
        path.addCurve(
            to: pt(
                CGPoint(x: cx + r * 0.707, y: cy - r * 0.707),  // circle: 45° point
                sTR_topStart
            ),
            control1: pt(
                CGPoint(x: cx + k*r * 0.5, y: cy - r),          // circle CP1
                sTop                                              // square: stay on top edge
            ),
            control2: pt(
                CGPoint(x: cx + r, y: cy - k*r * 0.5),          // circle CP2
                sTR_topStart                                      // square: arrive at corner
            )
        )

        // Sub-seg B: corner arc → right-center
        path.addCurve(
            to: pt(cRight, sRight),
            control1: pt(
                CGPoint(x: cx + r,   y: cy - k*r * 0.5),
                CGPoint(x: trC.x + cr, y: trC.y - kc)           // square: corner arc CP1
            ),
            control2: pt(
                CGPoint(x: cx + k*r * 0.5, y: cy),
                CGPoint(x: trC.x + kc, y: trC.y - cr)           // square: corner arc CP2
            )
        )

        // Segment 2: Right → Bottom (bottom-right quadrant)
        path.addCurve(
            to: pt(
                CGPoint(x: cx + r * 0.707, y: cy + r * 0.707),
                sBR_rightEnd
            ),
            control1: pt(
                CGPoint(x: cx + r, y: cy + k*r * 0.5),
                sRight
            ),
            control2: pt(
                CGPoint(x: cx + r * 0.5, y: cy + r),
                sBR_rightEnd
            )
        )

        path.addCurve(
            to: pt(cBottom, sBottom),
            control1: pt(
                CGPoint(x: cx + r * 0.5, y: cy + r),
                CGPoint(x: brC.x + cr, y: brC.y + kc)
            ),
            control2: pt(
                CGPoint(x: cx + k*r * 0.5, y: cy + r),
                CGPoint(x: brC.x + kc, y: brC.y + cr)
            )
        )

        // Segment 3: Bottom → Left (bottom-left quadrant)
        path.addCurve(
            to: pt(
                CGPoint(x: cx - r * 0.707, y: cy + r * 0.707),
                sBL_bottomEnd
            ),
            control1: pt(
                CGPoint(x: cx - k*r * 0.5, y: cy + r),
                sBottom
            ),
            control2: pt(
                CGPoint(x: cx - r, y: cy + k*r * 0.5),
                sBL_bottomEnd
            )
        )

        path.addCurve(
            to: pt(cLeft, sLeft),
            control1: pt(
                CGPoint(x: cx - r, y: cy + k*r * 0.5),
                CGPoint(x: blC.x - kc, y: blC.y + cr)
            ),
            control2: pt(
                CGPoint(x: cx - r, y: cy - k*r * 0.5),
                CGPoint(x: blC.x - cr, y: blC.y + kc)
            )
        )

        // Segment 4: Left → Top (top-left quadrant)
        path.addCurve(
            to: pt(
                CGPoint(x: cx - r * 0.707, y: cy - r * 0.707),
                sTL_leftEnd
            ),
            control1: pt(
                CGPoint(x: cx - r, y: cy - k*r * 0.5),
                sLeft
            ),
            control2: pt(
                CGPoint(x: cx - r * 0.5, y: cy - r),
                sTL_leftEnd
            )
        )

        path.addCurve(
            to: pt(cTop, sTop),
            control1: pt(
                CGPoint(x: cx - r * 0.5, y: cy - r),
                CGPoint(x: tlC.x - kc, y: tlC.y - cr)
            ),
            control2: pt(
                CGPoint(x: cx - k*r * 0.5, y: cy - r),
                CGPoint(x: tlC.x - cr, y: tlC.y - kc)
            )
        )

        path.closeSubpath()
        return path
    }
}

struct MorphingShapeView: View {
    @ObservedObject var viewModel: TimerViewModel

    private let CUSTOM_FONT = "Audiowide-Regular"

    private var morphFactor: Double {
        viewModel.hasFinished ? 1.0 : (1.0 - viewModel.progress)
    }

    private var shapeColor: Color {
        viewModel.hasFinished ? .gray : .purple
    }

    var body: some View {
        ZStack {
            MorphingTimerShape(morphFactor: morphFactor)
                .fill(shapeColor.opacity(0.15))
                .animation(.linear, value: viewModel.progress)

            MorphingTimerShape(morphFactor: morphFactor)
                .stroke(
                    shapeColor,
                    style: StrokeStyle(lineWidth: 14, lineCap: .round, lineJoin: .round)
                )
                .animation(.linear, value: viewModel.progress)

            Text(viewModel.timeFormatted)
                .font(.custom(CUSTOM_FONT, size: 22))
                .fontWeight(.bold)
                .foregroundColor(viewModel.hasFinished ? .gray : .white)
                .scaleEffect(1.0 - (1.0 - viewModel.progress) * 0.15)
                .animation(.linear, value: viewModel.progress)
        }
        .frame(width: 150, height: 150)
    }
}
