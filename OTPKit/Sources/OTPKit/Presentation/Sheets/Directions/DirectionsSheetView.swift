//
//  DirectionsSheetView.swift
//  OTPKit
//
//  Created by Hilmy Veradin on 08/08/24.
//

import SwiftUI
import MapKit

/// The in-trip panel: a progress rail over the whole trip at the medium and
/// large detents, and a glanceable one-instruction bar at the tip detent.
///
/// At the expanded detents the anatomy is fixed: grabber → destination header →
/// scrolling rail → optional pinned footer. The header never scrolls and the
/// progress bar never resets — those two continuities make six trip moments
/// feel like one trip.
struct DirectionsSheetView: View {
    @EnvironmentObject private var tripPlannerVM: TripPlannerViewModel
    @EnvironmentObject private var mapCoordinator: MapCoordinator
    @Environment(\.otpTheme) private var theme
    @State private var showEndConfirmation = false

    let trip: Trip
    @Binding var sheetDetent: PresentationDetent

    /// The `focusedLeg` cursor: what the rider is looking at, as opposed to
    /// where they are. Nil means tethered to now. Shared across detents so
    /// expanding the sheet carries focus over.
    @State private var focusedLegIndex: Int?

    /// True once the rider tapped Start Trip. Before the first leg's start
    /// time the clock alone can't distinguish "reviewing the plan" from
    /// "guidance underway", so the button press is what flips the sheet from
    /// its overview footer to live guidance.
    @State private var tripStarted = false

    /// The compact tip detent: the current instruction is one line, so the map
    /// keeps most of the screen.
    static let tipDetent: PresentationDetent = .height(160)

    public init(trip: Trip, sheetDetent: Binding<PresentationDetent>) {
        self.trip = trip
        _sheetDetent = sheetDetent
    }

    public var body: some View {
        TimelineView(.periodic(from: .now, by: 10)) { context in
            content(now: context.date)
        }
        .presentationDragIndicator(.visible)
        .presentationDetents(
            [DirectionsSheetView.tipDetent, .medium, .large], selection: $sheetDetent
        )
        .interactiveDismissDisabled()
        .presentationBackgroundInteraction(.enabled(upThrough: .large))
        .confirmationDialog(
            OTPLoc("directions.end_trip_confirm_title", comment: "Title of the end-trip confirmation dialog"),
            isPresented: $showEndConfirmation,
            titleVisibility: .visible
        ) {
            Button(OTPLoc("directions.end_trip", comment: "Confirms ending the active trip"), role: .destructive) {
                tripPlannerVM.resetTripPlanner()
            }
            Button(OTPLoc("directions.end_trip_cancel", comment: "Declines ending the active trip"), role: .cancel) {}
        } message: {
            Text(OTPLoc("directions.end_trip_confirm_message", comment: "Body of the end-trip confirmation dialog"))
        }
        .onChange(of: sheetDetent) { _, _ in
            updateMap(now: Date())
        }
        .onChange(of: focusedLegIndex) { _, _ in
            // The one place browsing drives the map: frame the focused leg,
            // or fall back to following the rider when focus clears.
            updateMap(now: Date())
        }
        .onAppear {
            // Pre-trip, open at the overview height so the rider sees the whole
            // plan and the Start Trip button; the tip detent hides both.
            let progress = TripProgress(itinerary: trip.itinerary, now: Date())
            if !hasStarted(progress) {
                sheetDetent = .medium
            }
            updateMap(now: Date())
        }
    }

    @ViewBuilder
    private func content(now: Date) -> some View {
        let progress = TripProgress(itinerary: trip.itinerary, now: now)

        VStack(spacing: 0) {
            if sheetDetent == DirectionsSheetView.tipDetent {
                TipContentView(
                    trip: trip,
                    progress: progress,
                    focusedLegIndex: $focusedLegIndex
                )
            } else {
                TripHeaderView(trip: trip, progress: progress)

                Divider()

                InTripRailView(
                    progress: progress,
                    focusedLegIndex: $focusedLegIndex
                )

                footer(progress)
            }
        }
        .onChange(of: progress.phase) { _, _ in
            handlePhaseChange(progress)
        }
    }

    // MARK: - Footer

    /// Whether guidance is underway: either the rider tapped Start Trip, or
    /// the clock says the trip has already begun.
    private func hasStarted(_ progress: TripProgress) -> Bool {
        tripStarted || progress.phase != .notStarted
    }

    /// Start Trip is the only primary button in the whole flow; Hide and End
    /// Trip split the two intents the old close button conflated.
    @ViewBuilder
    private func footer(_ progress: TripProgress) -> some View {
        if !hasStarted(progress) {
            preTripFooter
        } else if sheetDetent != DirectionsSheetView.tipDetent {
            VStack(spacing: 0) {
                Divider()
                HStack(spacing: 12) {
                    Button {
                        sheetDetent = DirectionsSheetView.tipDetent
                    } label: {
                        Text(OTPLoc("rail.hide", comment: "Collapses the trip sheet without ending the trip"))
                            .font(.body.weight(.semibold))
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 12))
                            .foregroundStyle(.primary)
                    }

                    Button {
                        showEndConfirmation = true
                    } label: {
                        Text(OTPLoc("directions.end_trip", comment: "Confirms ending the active trip"))
                            .font(.body.weight(.semibold))
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.red.opacity(0.35), lineWidth: 1)
                            )
                            .foregroundStyle(.red)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
        }
    }

    private var preTripFooter: some View {
        VStack(spacing: 0) {
            Divider()
            Button {
                startTrip()
            } label: {
                Text(OTPLoc("rail.start_trip", comment: "Begins turn-by-turn guidance for the trip"))
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(theme.primaryColor, in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)

            // A planned trip must be abandonable without starting it.
            Button {
                showEndConfirmation = true
            } label: {
                Text(OTPLoc("directions.end_trip", comment: "Confirms ending the active trip"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, minHeight: 36)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
        }
    }

    /// Begin guidance: collapse to the tip so the map does the wayfinding,
    /// frame the first step, and confirm with a haptic.
    private func startTrip() {
        tripStarted = true
        HapticManager.shared.success()
        sheetDetent = DirectionsSheetView.tipDetent
        updateMap(now: Date())
    }

    // MARK: - Map Coordination

    /// Approximate sheet height for map bottom padding at the current detent.
    private var currentSheetHeight: CGFloat {
        let screenHeight = UIScreen.main.bounds.height
        switch sheetDetent {
        case DirectionsSheetView.tipDetent:
            return 160
        case .medium:
            return screenHeight * 0.5
        default:
            return screenHeight * 0.9
        }
    }

    /// What the map does at each detent: tip and medium frame the leg under the
    /// active cursor; large frames the whole itinerary and the rail is the interface.
    private func updateMap(now: Date) {
        if sheetDetent == .large {
            mapCoordinator.showItinerary(trip.itinerary)
            return
        }

        let progress = TripProgress(itinerary: trip.itinerary, now: now)
        // Pre-trip the first leg is what matters; after arrival, the last —
        // panning back to the origin at the destination helps no one.
        let fallback = progress.phase == .arrived ? progress.legs.count - 1 : 0
        let legIndex = focusedLegIndex ?? progress.phase.legIndex ?? fallback
        guard progress.legs.indices.contains(legIndex) else { return }
        mapCoordinator.focusOnLeg(progress.legs[legIndex], bottomPadding: currentSheetHeight)
    }

    /// Auto-advance is announced, not silent: a rider staring at a stop sign
    /// isn't watching the screen.
    private func handlePhaseChange(_ progress: TripProgress) {
        guard progress.phase != .notStarted else { return }
        HapticManager.shared.success()

        let announcement = progress.localizedActivityName
            ?? OTPLoc("rail.arrived", comment: "The rider has reached the destination")
        AccessibilityNotification.Announcement(announcement).post()

        // Tethered focus follows the rider; untethered, the rail stays put.
        if focusedLegIndex == nil {
            updateMap(now: progress.now)
        }
    }
}

#Preview {
    @Previewable @State var sheetVisible = true
    @Previewable @State var directionSheetDetent = DirectionsSheetView.tipDetent
    let trip = Trip(origin: PreviewHelpers.createOrigin(), destination: PreviewHelpers.createDestination(), itinerary: PreviewHelpers.buildItin(legsCount: 2))

    Color(.systemGray5)
        .ignoresSafeArea()
        .sheet(isPresented: $sheetVisible) {
        DirectionsSheetView(
            trip: trip, sheetDetent: $directionSheetDetent
        )
        .environmentObject(PreviewHelpers.mockTripPlannerViewModel())
    }
}

#Preview {
    @Previewable @State var directionSheetDetent = DirectionsSheetView.tipDetent
    let trip = Trip(origin: PreviewHelpers.createOrigin(), destination: PreviewHelpers.createDestination(), itinerary: PreviewHelpers.buildItin(legsCount: 2))
    DirectionsSheetView(
        trip: trip, sheetDetent: $directionSheetDetent
    )
}
