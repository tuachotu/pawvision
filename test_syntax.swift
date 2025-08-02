import SwiftUI

struct DesignSystem {
    static let cornerRadius: CGFloat = 16
    static let smallCornerRadius: CGFloat = 12
    static let cardPadding: CGFloat = 20
    static let spacing: CGFloat = 16
    static let smallSpacing: CGFloat = 8
    
    struct Colors {
        static let primary = Color.blue
        static let secondary = Color.indigo
        static let accent = Color.orange
        static let background = Color(.systemBackground)
        static let cardBackground = Color(.secondarySystemBackground)
        static let textPrimary = Color.primary
        static let textSecondary = Color.secondary
        static let overlay = Color.black.opacity(0.3)
    }
    
    struct Typography {
        static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
        static let title = Font.system(size: 28, weight: .semibold, design: .rounded)
        static let headline = Font.system(size: 17, weight: .semibold)
        static let body = Font.system(size: 17, weight: .regular)
        static let caption = Font.system(size: 12, weight: .medium)
    }
    
    struct Shadows {
        static let card = Color.black.opacity(0.1)
        static let button = Color.black.opacity(0.15)
    }
}

struct TestView: View {
    var body: some View {
        Text("Hello")
    }
}