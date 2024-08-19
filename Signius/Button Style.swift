import SwiftUI

struct ButtonStyleModifier: ViewModifier {
    var color: Color
    
    func body(content: Content) -> some View {
        content
            .foregroundStyle(.white)
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity, maxHeight: 50)
            .background(color.gradient, in: RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)
    }
}

extension View {
    func buttonStyle(_ color: Color) -> some View {
        self.modifier(ButtonStyleModifier(color: color))
    }
}
