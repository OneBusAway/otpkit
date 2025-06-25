import MapKit
import SwiftUI

public struct DirectionSheetView: View {
    @Environment(TripPlannerService.self) private var tripPlanner
    @Environment(\.dismiss) private var dismiss
    @Binding var sheetDetent: PresentationDetent
    @State private var scrollToItem: String?

    // MARK: - ViewModel
    private var viewModel: DirectionSheetViewModel {
        DirectionSheetViewModel(tripPlannerService: tripPlanner)
    }

    // MARK: - Initialization
    public init(sheetDetent: Binding<PresentationDetent>) {
        _sheetDetent = sheetDetent
    }

    // MARK: - Body
    public var body: some View {
        ScrollViewReader { proxy in
            List {
                headerSection()

                if let itinerary = viewModel.selectedItinerary {
                    directionsSection(itinerary: itinerary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 16)
            .listStyle(PlainListStyle())
            .onChange(of: scrollToItem) {
                handleScrollToItem(proxy: proxy)
            }
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
        .overlay {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.regularMaterial)
            }
        }
    }

    // MARK: - View Sections

    private func headerSection() -> some View {
        Section {
            PageHeaderView(text: viewModel.pageTitle) {
                viewModel.resetTripPlanner()
                dismiss()
            }
            .frame(height: 50)
            .listRowInsets(EdgeInsets())
        }
    }

    private func directionsSection(itinerary: Itinerary) -> some View {
        Section {
            originView()
            legsView(itinerary: itinerary)
            destinationView(itinerary: itinerary)
        }
    }

    private func originView() -> some View {
        DirectionLegOriginDestinationView(
            title: "Origin",
            description: viewModel.originName
        )
        .id(viewModel.originItemId)
        .onTapGesture {
            handleTap(itemId: viewModel.originItemId) {
                viewModel.handleOriginTap()
            }
        }
    }

    private func legsView(itinerary: Itinerary) -> some View {
        ForEach(Array(itinerary.legs.enumerated()), id: \.offset) { index, leg in
            legView(for: leg)
                .id(viewModel.generateItemId(for: index + 1))
                .onTapGesture {
                    let itemId = viewModel.generateItemId(for: index + 1)
                    handleTap(itemId: itemId) {
                        viewModel.handleLegTap(leg)
                    }
                }
        }
    }

    @ViewBuilder
    private func legView(for leg: Leg) -> some View {
        switch viewModel.getLegViewType(for: leg) {
        case .vehicle:
            DirectionLegVehicleView(leg: leg)
        case .walk:
            DirectionLegWalkView(leg: leg)
        case .unknown:
            DirectionLegUnknownView(leg: leg)
        }
    }

    private func destinationView(itinerary: Itinerary) -> some View {
        DirectionLegOriginDestinationView(
            title: "Destination",
            description: viewModel.destinationName
        )
        .id(viewModel.destinationItemId(for: itinerary))
        .onTapGesture {
            handleTap(itemId: viewModel.destinationItemId(for: itinerary)) {
                viewModel.handleDestinationTap()
            }
        }
    }

    // MARK: - Actions

    private func handleTap(itemId: String, action: () -> Void) {
        action()
        scrollToItem = itemId
        sheetDetent = .fraction(0.2)
    }

    private func handleScrollToItem(proxy: ScrollViewProxy) {
        guard let itemId = scrollToItem else { return }

        withAnimation {
            proxy.scrollTo(itemId, anchor: .top)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            scrollToItem = nil
        }
    }
}

#Preview {
    DirectionSheetView(sheetDetent: .constant(.fraction(0.2)))
}
