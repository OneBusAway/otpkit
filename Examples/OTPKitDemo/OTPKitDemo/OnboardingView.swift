import SwiftUI
import OTPKit
import MapKit

/// View to select region for demo purposes
struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @Binding var selectedRegionURL: URL?
    @Binding var tripPlannerService: TripPlannerService?
    @State private var selectedRegion: String = "Puget Sound"

    private let regions = [
        "Puget Sound": [
            "url": URL(string: "https://otp.prod.sound.obaweb.org/otp/routers/default/")!,
            "center": CLLocationCoordinate2D(latitude: 47.64585, longitude: -122.2963)
        ],
        "San Diego": [
            "url": URL(string: "https://realtime.sdmts.com:9091/otp/routers/default/")!,
            "center": CLLocationCoordinate2D(latitude: 32.731591, longitude: -117.1896335)
        ],
        "Tampa": [
            "url": URL(string: "https://otp.prod.obahart.org/otp/routers/default/")!,
            "center": CLLocationCoordinate2D(latitude: 27.9769105, longitude: -82.445851)
        ]
    ]

    var body: some View {
        VStack {
            Spacer(minLength: 20)
            Text("Welcome to OTPKitDemo!")
                .bold()
                .font(.title)

            Text("Please choose your region.")

            List(Array(regions.keys.sorted()), id: \.self) { key in
                Button {
                    selectedRegion = key
                } label: {
                    HStack {
                        Text(key)
                        Spacer()
                        if selectedRegion == key {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
                .foregroundColor(.primary)
            }

            Button {
                let selection = regions[selectedRegion]!

                // swiftlint:disable force_cast
                let url = selection["url"] as! URL
                let center = selection["center"] as! CLLocationCoordinate2D
                // swiftlint:enable force_cast

                selectedRegionURL = url

                tripPlannerService = TripPlannerService(
                    apiClient: RestAPI(baseURL: url),
                    locationManager: CLLocationManager(),
                    searchCompleter: MKLocalSearchCompleter()
                )

                tripPlannerService?.changeMapCamera(to: center)
                hasCompletedOnboarding = true

            } label: {
                Text("OK")
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(BorderedProminentButtonStyle())
            .padding()
        }
        .background(Color(UIColor.systemGroupedBackground))
    }
}

#Preview {
    let planner = TripPlannerService(
        apiClient: RestAPI(baseURL: URL(string: "https://otp.prod.sound.obaweb.org/otp/routers/default/")!),
        locationManager: CLLocationManager(),
        searchCompleter: MKLocalSearchCompleter()
    )

    return OnboardingView(
        hasCompletedOnboarding: .constant(true),
        selectedRegionURL: .constant(nil),
        tripPlannerService: .constant(planner)
    )
}
