//
//  TripPlannerExtensionView.swift
//  OTPKit
//
//  Created by Hilmy Veradin on 12/08/24.
//

import MapKit
import SwiftUI

/// Main Extension View that take Map as it's content
/// This simplify all the process of making the Trip Planner UI
public struct TripPlannerExtensionView<MapContent: View>: View {
    @Environment(OriginDestinationSheetEnvironment.self) private var sheetEnvironment
    @Environment(TripPlannerService.self) private var tripPlanner

    @State private var directionSheetDetent: PresentationDetent = .fraction(0.2)


    // MARK: - ViewModel
    private var viewModel: TripPlannerExtensionViewModel {
        TripPlannerExtensionViewModel(
            tripPlannerService: tripPlanner,
            sheetEnvironment: sheetEnvironment
        )
    }

    private let mapContent: () -> MapContent

    public init(@ViewBuilder mapContent: @escaping () -> MapContent) {
        self.mapContent = mapContent
    }

    public var body: some View {
        ZStack {
            MapReader { proxy in
                mapContent()
                    .onTapGesture { tappedLocation in
                        viewModel.handleMapTap(proxy: proxy, tappedLocation: tappedLocation)
                    }
            }
            .sheet(isPresented: viewModel.isOriginDestinationSheetPresented) {
                OriginDestinationSheetView()
            }
            .sheet(isPresented: viewModel.isTripPlannerSheetPresented) {
                TripPlannerSheetView()
                    .presentationDetents([.medium, .large])
                    .interactiveDismissDisabled()
            }
            .sheet(
                isPresented: viewModel.isStepsViewSheetPresented,
                onDismiss: {
                    viewModel.handleStepsViewDismissal()
                }
            ) {
                DirectionSheetView(sheetDetent: $directionSheetDetent)
                    .presentationDetents([.fraction(0.2), .medium, .large], selection: $directionSheetDetent)
                    .interactiveDismissDisabled()
                    .presentationBackgroundInteraction(.enabled(upThrough: .fraction(0.2)))
            }

            overlayContent
        }
        .onAppear {
            viewModel.onViewAppear()
        }
        .alert(
            viewModel.currentError?.title ?? "Error",
            isPresented: Binding(
                get: { viewModel.showErrorAlert },
                set: { _ in viewModel.clearError() }
            )
        ) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            Text(viewModel.currentError?.errorDescription ?? "")
        }
    }

    // MARK: - Overlay Content

    @ViewBuilder
    private var overlayContent: some View {
        switch viewModel.overlayContentType {
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.regularMaterial)

        case .mapMarking:
            MapMarkingView()

        case .tripPlanner:
            VStack {
                Spacer()
                TripPlannerView(text: viewModel.getItinerarySummary())
            }

        case .originDestination:
            VStack {
                Spacer()
                OriginDestinationView()
            }

        case .none:
            EmptyView()
        }
    }
}
