import SwiftUI
import OTPKit
import MapKit

/// View to select region for demo purposes
struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @Binding var otpConfiguration: OTPConfiguration?
    @State private var selectedRegion: String = "Puget Sound"

    private struct RegionInfo {
        let name: String
        let description: String
        let icon: String
        let url: URL
        let center: CLLocationCoordinate2D
    }

    private let regions: [RegionInfo] = [
        RegionInfo(
            name: "Puget Sound",
            description: "Seattle & surrounding areas",
            icon: "building.2.fill",
            url: URL(string: "https://otp.prod.sound.obaweb.org/otp/routers/default/")!,
            center: CLLocationCoordinate2D(latitude: 47.64585, longitude: -122.2963)
        ),
        RegionInfo(
            name: "San Diego",
            description: "Southern California transit",
            icon: "sun.max.fill",
            url: URL(string: "https://realtime.sdmts.com:9091/otp/routers/default/")!,
            center: CLLocationCoordinate2D(latitude: 32.731591, longitude: -117.1896335)
        ),
        RegionInfo(
            name: "Tampa",
            description: "Tampa Bay area transit",
            icon: "water.waves",
            url: URL(string: "https://otp.prod.obahart.org/otp/routers/default/")!,
            center: CLLocationCoordinate2D(latitude: 27.9769105, longitude: -82.445851)
        )
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                headerSection
                regionSelectionSection
                getStartedButton
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 40)
        }
        .background(
            LinearGradient(
                colors: [Color(.systemBackground), Color(.secondarySystemBackground)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    // MARK: - View Components

    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "location.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.blue.gradient)

            VStack(spacing: 8) {
                Text("Welcome to OTPKitDemo!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text("Choose your region to start planning trips")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var regionSelectionSection: some View {
        VStack(spacing: 16) {
            Text("Available Regions")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 12) {
                ForEach(regions, id: \.name) { region in
                    regionCard(for: region)
                }
            }
        }
    }

    private func regionCard(for region: RegionInfo) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedRegion = region.name
            }
        } label: {
            HStack(spacing: 16) {
                Image(systemName: region.icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 4) {
                    Text(region.name)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(region.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if selectedRegion == region.name {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(selectedRegion == region.name ? Color.blue.opacity(0.1) : Color(.tertiarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(selectedRegion == region.name ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var getStartedButton: some View {
        Button {
            guard let selectedRegionInfo = regions.first(where: { $0.name == selectedRegion }) else { return }

            otpConfiguration = OTPConfiguration(
                otpServerURL: selectedRegionInfo.url,
                region: .region(MKCoordinateRegion(
                    center: selectedRegionInfo.center,
                    latitudinalMeters: 50000,
                    longitudinalMeters: 50000
                ))
            )

            hasCompletedOnboarding = true
        } label: {
            HStack {
                Image(systemName: "arrow.right.circle.fill")
                Text("Get Started")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.blue.gradient)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    let config = OTPConfiguration(
        otpServerURL: URL(string: "https://otp.prod.sound.obaweb.org/otp/routers/default/")!,
        region: .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 47.64585, longitude: -122.2963),
            latitudinalMeters: 50000,
            longitudinalMeters: 50000
        ))
    )

    return OnboardingView(
        hasCompletedOnboarding: .constant(false),
        otpConfiguration: .constant(config)
    )
}
