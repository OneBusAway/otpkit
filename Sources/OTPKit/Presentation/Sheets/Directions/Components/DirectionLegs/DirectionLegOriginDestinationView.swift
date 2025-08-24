import SwiftUI

struct DirectionLegOriginDestinationView: View {
    let title: String
    let description: String
    
    @Environment(\.otpTheme) private var theme

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(theme.primaryColor)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 12)
    }
}

#Preview {
    DirectionLegOriginDestinationView(
        title: "Origin",
        description: "123 Main St"
    )
} 