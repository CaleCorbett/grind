import SwiftUI

public struct StatusToggleView: View {
    let status: TaskStatus
    let action: () -> Void
    
    public init(status: TaskStatus, action: @escaping () -> Void) {
        self.status = status
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            ZStack {
                // Outer rounded square border
                RoundedRectangle(cornerRadius: GrindTheme.checkboxRadius, style: .continuous)
                    .strokeBorder(
                        status == .incomplete ? GrindColors.primary.opacity(0.24) : GrindColors.primary,
                        lineWidth: 1.5
                    )
                    .frame(width: GrindTheme.checkboxSize, height: GrindTheme.checkboxSize)
                
                // In-Progress: 180-degree pie slice
                if status == .inProgress {
                    PieSlice(sweep: 180)
                        .fill(GrindColors.primary)
                        .frame(width: 13, height: 13)
                        .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                        .transition(.scale.combined(with: .opacity))
                }
                
                // Completed: checkmark
                if status == .completed {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(GrindColors.primary)
                        .transition(.scale(scale: 0.6).combined(with: .opacity))
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(GrindTheme.snapSpring, value: status)
    }
}

// Custom shape for 180° sweep pie
struct PieSlice: Shape {
    var sweep: Double // in degrees
    
    var animatableData: Double {
        get { sweep }
        set { sweep = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        path.move(to: center)
        path.addArc(
            center: center,
            radius: radius,
            startAngle: .degrees(-90),
            endAngle: .degrees(-90 + sweep),
            clockwise: false
        )
        path.closeSubpath()
        return path
    }
}
