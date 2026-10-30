import SwiftUI

public struct StatusToggleView: View {
    let status: TaskStatus
    let action: () -> Void
    
    @State private var isHovered: Bool = false
    
    public init(status: TaskStatus, action: @escaping () -> Void) {
        self.status = status
        self.action = action
    }
    
    private var sweepDegrees: Double {
        switch status {
        case .incomplete: return 0
        case .inProgress: return 180
        case .completed: return 360
        }
    }
    
    public var body: some View {
        Button(action: action) {
            ZStack {
                // Subtle hover fill for incomplete state
                RoundedRectangle(cornerRadius: GrindTheme.checkboxRadius, style: .continuous)
                    .fill(status == .incomplete && isHovered ? GrindColors.hair : Color.clear)
                    .frame(width: GrindTheme.checkboxSize, height: GrindTheme.checkboxSize)
                
                // Outer rounded square border
                RoundedRectangle(cornerRadius: GrindTheme.checkboxRadius, style: .continuous)
                    .strokeBorder(
                        status == .incomplete
                            ? (isHovered ? GrindColors.primary.opacity(0.55) : GrindColors.primary.opacity(0.28))
                            : GrindColors.primary,
                        lineWidth: 1.5
                    )
                    .frame(width: GrindTheme.checkboxSize, height: GrindTheme.checkboxSize)
                
                // Continuous 0° -> 180° -> 360° conic sweep fill
                PieSlice(sweep: sweepDegrees)
                    .fill(GrindColors.primary)
                    .frame(
                        width: status == .completed ? GrindTheme.checkboxSize : 14,
                        height: status == .completed ? GrindTheme.checkboxSize : 14
                    )
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: status == .completed ? GrindTheme.checkboxRadius : 4.5,
                            style: .continuous
                        )
                    )
                    .opacity(status == .incomplete ? 0 : 1)
                
                // Animated vector checkmark on completion (Things 3 style)
                CheckmarkShape()
                    .trim(from: 0, to: status == .completed ? 1.0 : 0.0)
                    .stroke(
                        GrindColors.primaryInverted,
                        style: StrokeStyle(lineWidth: 2.0, lineCap: .round, lineJoin: .round)
                    )
                    .frame(width: 10, height: 8)
                    .offset(y: 0.5)
            }
            .scaleEffect(isHovered ? 1.07 : 1.0)
            .contentShape(Rectangle())
        }
        .buttonStyle(TactileCheckboxButtonStyle())
        .onHover { hovering in
            withAnimation(GrindTheme.snapSpring) {
                isHovered = hovering
            }
        }
        .animation(GrindTheme.snapSpring, value: status)
    }
}

private struct TactileCheckboxButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.86 : 1.0)
            .animation(GrindTheme.snapSpring, value: configuration.isPressed)
    }
}

// Custom shape for 0° -> 180° -> 360° sweep pie
struct PieSlice: Shape {
    var sweep: Double // in degrees
    
    var animatableData: Double {
        get { sweep }
        set { sweep = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard sweep > 0.1 else { return path }
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = max(rect.width, rect.height)
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

// Vector checkmark path for trim animation
struct CheckmarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.08, y: rect.midY + rect.height * 0.05))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.38, y: rect.maxY - rect.height * 0.10))
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.06, y: rect.minY + rect.height * 0.10))
        return path
    }
}
