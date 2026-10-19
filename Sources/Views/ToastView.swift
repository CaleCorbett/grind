import SwiftUI

public struct ToastView: View {
    @ObservedObject var manager = UndoToastManager.shared
    
    public init() {}
    
    public var body: some View {
        if let message = manager.currentToastMessage {
            HStack(spacing: 12) {
                Text(message)
                    .font(.geist(.medium, size: 13))
                    .foregroundColor(GrindColors.primaryInverted)
                
                if manager.canUndo {
                    Button(action: {
                        manager.undo()
                    }) {
                        HStack(spacing: 4) {
                            Text("Undo")
                                .font(.geist(.bold, size: 13))
                            Text("⌘Z")
                                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                .opacity(0.8)
                        }
                        .foregroundColor(GrindColors.primaryInverted)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(GrindColors.primaryInverted.opacity(0.2))
                        .cornerRadius(5)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(GrindColors.primary)
                    .shadow(color: Color.black.opacity(0.25), radius: 12, x: 0, y: 6)
            )
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .padding(.bottom, 24)
        }
    }
}
