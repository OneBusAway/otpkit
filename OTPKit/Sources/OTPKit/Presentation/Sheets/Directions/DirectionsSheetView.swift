//
//  DirectionsSheetView.swift
//  OTPKit
//
//  Created by Hilmy Veradin on 08/08/24.
//

import SwiftUI
import MapKit

/// A sheet view that displays step-by-step directions to the destination
struct DirectionsSheetView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var tripPlannerVM: TripPlannerViewModel
    @EnvironmentObject private var mapCoordinator: MapCoordinator

    @Environment(\.otpTheme) private var theme

    @Binding var sheetDetent: PresentationDetent
    @State private var scrollToItem: String?

    public init(sheetDetent: Binding<PresentationDetent>) {
        _sheetDetent = sheetDetent
    }

    public var body: some View {
        ScrollViewReader { proxy in
            List {
                Section {
                    PageHeaderView(
                        text: tripPlannerVM.selectedDestination?.title ?? "Destination"
                    ) {
                        tripPlannerVM.resetTripPlanner()
                        dismiss()
                    }
                    .frame(height: 50)
                    .listRowInsets(EdgeInsets())
                }
                .listRowBackground(Color.clear)

                if let itinerary = tripPlannerVM.selectedItinerary {
                    Section {
                        createOriginView(itinerary: itinerary)
                        ItineraryLegsView(itinerary: itinerary) { leg, index in
                            print("Leg tapped: \(leg) - index: \(index)")
                            let coordinate = CLLocationCoordinate2D(latitude: leg.to.lat, longitude: leg.to.lon)
                            handleTap(coordinate: coordinate, itemId: index)
                        }
                        createDestinationView(itinerary: itinerary)
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 16)
            .listStyle(PlainListStyle())
            .scrollIndicators(.hidden)
            .onChange(of: scrollToItem) {
                if let scrollToItem {
                    withAnimation {
                        proxy.scrollTo(scrollToItem, anchor: .top)
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.scrollToItem = nil
                    }
                }
            }
        }
    }

    private func handleTap(coordinate: CLLocationCoordinate2D, itemId: String) {
        mapCoordinator.centerOn(coordinate: coordinate)
        scrollToItem = itemId
        sheetDetent = .fraction(0.2)
    }

    private func createOriginView(itinerary _: Itinerary) -> some View {
        DirectionLegOriginDestinationView(
            title: "Start",
            description: tripPlannerVM.selectedOrigin?.title ?? "Unknown"
        )
        .id("start")
        .onTapGesture {
            if let originCoordinate = tripPlannerVM.selectedOrigin?.coordinate {
                handleTap(coordinate: originCoordinate, itemId: "start")
            }
        }
    }

    private func createDestinationView(itinerary: Itinerary) -> some View {
        DirectionLegOriginDestinationView(
            title: "Destination",
            description: tripPlannerVM.selectedDestination?.title ?? "Unknown"
        )
        .id("destination")
        .onTapGesture {
            if let destinationCoordinate = tripPlannerVM.selectedDestination?.coordinate {
                handleTap(coordinate: destinationCoordinate, itemId: "destination")
            }
        }
    }
}

#Preview {
    DirectionsSheetView(
        sheetDetent: .constant(.fraction(0.2))
    )
    .environmentObject(PreviewHelpers.mockTripPlannerViewModel())
}
