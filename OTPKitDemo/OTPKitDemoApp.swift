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

// MARK: - OTPRegionInfo

struct OTPRegionInfo: Codable {
    let name: String
    let description: String
    let icon: String
    let url: URL
    let center: CLLocationCoordinate2D

    enum CodingKeys: String, CodingKey {
        case name, description, icon, url
        case latitude, longitude
    }

    init(name: String, description: String, icon: String, url: URL, center: CLLocationCoordinate2D) {
        self.name = name
        self.description = description
        self.icon = icon
        self.url = url
        self.center = center
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        icon = try container.decode(String.self, forKey: .icon)
        url = try container.decode(URL.self, forKey: .url)
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encode(icon, forKey: .icon)
        try container.encode(url, forKey: .url)
        try container.encode(center.latitude, forKey: .latitude)
        try container.encode(center.longitude, forKey: .longitude)
    }
}

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.backgroundColor = .systemBackground

        // Check if onboarding has been completed
        let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")

        print("SceneDelegate - Setting up window")
        print("Has completed onboarding: \(hasCompletedOnboarding)")

        if hasCompletedOnboarding,
           let serverURL = UserDefaults.standard.url(forKey: "otpServerURL"),
           let regionData = UserDefaults.standard.data(forKey: "selectedRegion"),
           let region = try? JSONDecoder().decode(OTPRegionInfo.self, from: regionData) {
            // Show main OTP view controller
            let mainViewController = OTPDemoViewController(serverURL: serverURL, regionInfo: region)
            let navigationController = UINavigationController(rootViewController: mainViewController)
            window?.rootViewController = navigationController
        } else {
            // Show onboarding
            print("Showing onboarding screen")
            let onboardingVC = OnboardingViewController()
            onboardingVC.onboardingCompleteHandler = { [weak self] serverURL, regionInfo in
                self?.showMainViewController(serverURL: serverURL, regionInfo: regionInfo)
            }
            window?.rootViewController = onboardingVC
        }

        window?.makeKeyAndVisible()
        print("Window is key and visible")

        return true
    }

    private func showMainViewController(serverURL: URL, regionInfo: OTPRegionInfo) {
        let mainViewController = OTPDemoViewController(serverURL: serverURL, regionInfo: regionInfo)
        let navigationController = UINavigationController(rootViewController: mainViewController)

        if let window = window {
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {
                window.rootViewController = navigationController
            })
        }
    }
}

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

        let view = tripPlanner.createTripPlannerView() { [weak self] in
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

// MARK: - Onboarding View Controller

class OnboardingViewController: UIViewController {

    var onboardingCompleteHandler: ((URL, OTPRegionInfo) -> Void)?

    private var regionPicker: UIPickerView!
    private var continueButton: UIButton!

    private let regions = [
        OTPRegionInfo(
            name: "Seattle",
            description: "Puget Sound region",
            icon: "building.2.fill",
            url: URL(string: "https://otp.prod.sound.obaweb.org/otp/routers/default/")!,
            center: CLLocationCoordinate2D(latitude: 47.6062, longitude: -122.3321)
        )
    ]

    private var selectedRegion: OTPRegionInfo?

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        setupUI()

        selectedRegion = regions.first
    }

    private func setupUI() {
        let titleLabel = UILabel()
        titleLabel.text = "OTPKit Demo Setup"
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let regionLabel = UILabel()
        regionLabel.text = "Select Region:"
        regionLabel.font = .systemFont(ofSize: 16)
        regionLabel.translatesAutoresizingMaskIntoConstraints = false

        regionPicker = UIPickerView()
        regionPicker.delegate = self
        regionPicker.dataSource = self
        regionPicker.translatesAutoresizingMaskIntoConstraints = false

        continueButton = UIButton(type: .system)
        continueButton.setTitle("Continue", for: .normal)
        continueButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        continueButton.backgroundColor = .systemBlue
        continueButton.setTitleColor(.white, for: .normal)
        continueButton.layer.cornerRadius = 8
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        continueButton.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)

        view.addSubview(titleLabel)
        view.addSubview(regionLabel)
        view.addSubview(regionPicker)
        view.addSubview(continueButton)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            regionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 30),
            regionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

            regionPicker.topAnchor.constraint(equalTo: regionLabel.bottomAnchor, constant: 10),
            regionPicker.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            regionPicker.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            regionPicker.heightAnchor.constraint(equalToConstant: 150),

            continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            continueButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            continueButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            continueButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    @objc private func continueTapped() {
        guard let region = selectedRegion else {
            let alert = UIAlertController(title: "Invalid Input", message: "Please select a region", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        // Save to UserDefaults
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        UserDefaults.standard.set(region.url, forKey: "otpServerURL")

        if let regionData = try? JSONEncoder().encode(region) {
            UserDefaults.standard.set(regionData, forKey: "selectedRegion")
        }

        onboardingCompleteHandler?(region.url, region)
    }
}

// MARK: - UIPickerViewDataSource & UIPickerViewDelegate

extension OnboardingViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return regions.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return regions[row].name
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedRegion = regions[row]
    }
}
