import MapKit
import SwiftUI

public struct DirectionSheetView: View {
    @EnvironmentObject private var locationManagerService: TripPlannerService
    @Environment(\.dismiss) private var dismiss
    @Binding var sheetDetent: PresentationDetent
    @State private var scrollToItem: String?

    public init(sheetDetent: Binding<PresentationDetent>) {
        _sheetDetent = sheetDetent
    }

    private func generateLegView(leg: Leg) -> some View {
        Group {
            switch leg.mode {
            case "BUS", "TRAM":
                DirectionLegVehicleView(leg: leg)
            case "WALK":
                DirectionLegWalkView(leg: leg)
            default:
                DirectionLegUnknownView(leg: leg)
            }
        }
    }

    private func handleTap(coordinate: CLLocationCoordinate2D, itemId: String) {
        let placemark = MKPlacemark(coordinate: coordinate)
        let item = MKMapItem(placemark: placemark)
        locationManagerService.changeMapCamera(item)
        scrollToItem = itemId
        sheetDetent = .fraction(0.2)
    }

    public var body: some View {
        ScrollViewReader { proxy in
            List {
                Section {
                    PageHeaderView(text: "\(locationManagerService.destinationName)") {
                        locationManagerService.resetTripPlanner()
                        dismiss()
                    }
                    .frame(height: 50)
                    .listRowInsets(EdgeInsets())
                }

                if let itinerary = locationManagerService.selectedItinerary {
                    Section {
                        createOriginView(itinerary: itinerary)
                        createLegsView(itinerary: itinerary)
                        createDestinationView(itinerary: itinerary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 16)
            .listStyle(PlainListStyle())
            .onChange(of: scrollToItem) {
                if let itemId = scrollToItem {
                    withAnimation {
                        proxy.scrollTo(itemId, anchor: .top)
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        scrollToItem = nil
                    }
                }
            }
        }
    }

    private func createOriginView(itinerary _: Itinerary) -> some View {
        DirectionLegOriginDestinationView(
            title: "Origin",
            description: locationManagerService.originName
        )
        .id("item-0")
        .onTapGesture {
            if let originCoordinate = locationManagerService.originCoordinate {
                handleTap(coordinate: originCoordinate, itemId: "item-0")
            }
        }
    }

    private func createLegsView(itinerary: Itinerary) -> some View {
        ForEach(Array(itinerary.legs.enumerated()), id: \.offset) { index, leg in
            generateLegView(leg: leg)
                .id("item-\(index + 1)")
                .onTapGesture {
                    let coordinate = CLLocationCoordinate2D(latitude: leg.to.lat, longitude: leg.to.lon)
                    handleTap(coordinate: coordinate, itemId: "item-\(index + 1)")
                }
        }
    }

    private func createDestinationView(itinerary: Itinerary) -> some View {
        DirectionLegOriginDestinationView(
            title: "Destination",
            description: locationManagerService.destinationName
        )
        .id("item-\(itinerary.legs.count + 1)")
        .onTapGesture {
            if let destinationCoordinate = locationManagerService.destinationCoordinate {
                handleTap(coordinate: destinationCoordinate, itemId: "item-\(itinerary.legs.count + 1)")
            }
        }
    }
}

#Preview {
    DirectionSheetView(sheetDetent: .constant(.fraction(0.2)))
        .environmentObject(PreviewHelpers.buildTripPlannerService())
}
