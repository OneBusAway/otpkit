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
            "url": "https://otp.prod.sound.obaweb.org/otp/routers/default/",
            "lat": 47.64585,
            "lon": -122.2963
        ],
        "San Diego": [
            "url": "https://realtime.sdmts.com:9091/otp/routers/default/",
            "lat": 32.731591,
            "lon": -117.1896335
        ],
        "Tampa": [
            "url": "https://otp.prod.obahart.org/otp/routers/default/",
            "lat": 27.9769105,
            "lon": -82.445851
        ]
    ]

    var body: some View {
        VStack(spacing: 20) {
            Text("Hello! Welcome to OTPKitDemo!")
                .font(.title)
            
            Text("Please choose your initial region.")
                .font(.subheadline)
            
            List(Array(regions.keys), id: \.self) { key in
                Button(action: {
                    selectedRegion = key
                }) {
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
            .frame(height: 200)
            
            Button(action: {
                if let urlString = regions[selectedRegion]?["url"] as? String,
                   let url = URL(string: urlString),
                   let latitude = regions[selectedRegion]?["lat"] as? Double,
                   let longitude = regions[selectedRegion]?["lon"] as? Double {
                    
                    selectedRegionURL = url
                    
                    print(urlString)
                    tripPlannerService = TripPlannerService(
                        apiClient: RestAPI(baseURL: url),
                        locationManager: CLLocationManager(),
                        searchCompleter: MKLocalSearchCompleter()
                    )
                    
                    let locationCoordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                    tripPlannerService?.changeMapCamera(to: locationCoordinate)
                    hasCompletedOnboarding = true
                }
            }) {
                Text("Submit")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
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
