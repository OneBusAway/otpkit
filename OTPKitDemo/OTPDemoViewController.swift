/*
 * Copyright (C) Open Transit Software Foundation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import UIKit
import CoreLocation
import MapKit
import SwiftUI
import OTPKit

// MARK: - Main View Controller

class OTPDemoViewController: UIViewController {

    // MARK: - Properties

    private let serverURL: URL
    private let regionInfo: OTPRegionInfo
    private var mapView: MKMapView!
    private var mapProvider: OTPMapProvider?
    private var apiService: RestAPIService!
    private var tripPlanner: TripPlanner?
    private var hostingController: UIViewController?

    // MARK: - Initialization

    init(serverURL: URL, regionInfo: OTPRegionInfo) {
        self.serverURL = serverURL
        self.regionInfo = regionInfo
        super.init(nibName: nil, bundle: nil)

        subscribeToTripPlannerNotifications()
    }

    deinit {
        unsubscribeFromTripPlannerNotifications()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupMapView()
        setupAPIService()
        setupUI()

        // Request location permission
        LocationManager.shared.requestLocationPermission()
    }

    // MARK: - Setup

    private func setupMapView() {
        mapView = MKMapView()
        mapView.mapType = .mutedStandard
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.showsUserLocation = true
        mapView.showsCompass = true
        mapView.showsScale = true

        // Set initial region
        let region = MKCoordinateRegion(
            center: regionInfo.center,
            latitudinalMeters: 50000,
            longitudinalMeters: 50000
        )
        mapView.setRegion(region, animated: false)

        view.addSubview(mapView)

        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // Create the map adapter for OTPKit
        mapProvider = MKMapViewAdapter(mapView: mapView)
    }

    private func setupUI() {
        title = "OTPKit Demo"

        // Add navigation bar buttons
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Trip Planner",
            style: .plain,
            target: self,
            action: #selector(showTripPlannerTapped)
        )

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Clear",
            style: .plain,
            target: self,
            action: #selector(clearTripTapped)
        )
    }

    private func setupAPIService() {
        // Create API service
        apiService = RestAPIService(baseURL: serverURL)
    }

    // MARK: - Actions

    @objc private func showTripPlannerTapped() {
        presentTripPlanner()
    }

    @objc private func clearTripTapped() {
        // Clear map annotations and routes
        mapProvider?.clearAllRoutes()
        mapProvider?.clearAllAnnotations()
    }

    private func presentTripPlanner() {
        guard
            tripPlanner == nil,
            let provider = mapProvider
        else {
            showAlert(title: "Trip planner already exists", message: "")
            return
        }

        // Create bottom sheet and present it
        let tripPlanner = TripPlanner(
            otpConfig: OTPConfiguration(otpServerURL: serverURL),
            apiService: apiService,
            mapProvider: provider,
            notificationCenter: NotificationCenter.default
        )

        let view = tripPlanner.createTripPlannerView { [weak self] in
            guard let self else { return }
            self.removeTripPlanner()
        }
        let hostingController = PanelHostingController(rootView: view)

        present(hostingController, animated: true)

        self.hostingController = hostingController
        self.tripPlanner = tripPlanner
    }

    private func removeTripPlanner() {
        hostingController?.dismiss(animated: true)
        self.hostingController = nil
        self.tripPlanner = nil
    }

    // MARK: - Notifications

    private func subscribeToTripPlannerNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(itinerariesUpdated), name: Notifications.itinerariesUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(itineraryPreviewStarted), name: Notifications.itineraryPreviewStarted, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(itineraryPreviewEnded), name: Notifications.itineraryPreviewEnded, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(tripStarted), name: Notifications.tripStarted, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(tripEnded), name: Notifications.tripEnded, object: nil)
    }

    private func unsubscribeFromTripPlannerNotifications() {
        NotificationCenter.default.removeObserver(self, name: Notifications.itinerariesUpdated, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notifications.itineraryPreviewStarted, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notifications.itineraryPreviewEnded, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notifications.tripStarted, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notifications.tripEnded, object: nil)
    }

    @objc private func itinerariesUpdated(_ note: NSNotification) {
        print(#function)
        hostingController?.animateToDetentIdentifier(.large)
    }

    @objc private func itineraryPreviewStarted(_ note: NSNotification) {
        print(#function)
        // nop
    }

    // TODO: wire this up! the notification doesn't get triggered yet.
    @objc private func itineraryPreviewEnded(_ note: NSNotification) {
        print(#function)
    }

    @objc private func tripStarted(_ note: NSNotification) {
        print(#function)
        hostingController?.animateToDetentIdentifier(.tip)
    }

    // TODO: wire this up! the notification doesn't get triggered yet.
    @objc private func tripEnded(_ note: NSNotification) {
        print(#function)
    }

    // MARK: - Helper Methods

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
