//
//  OnboardingViewController.swift
//  OTPKitDemo
//
//  Created by Aaron Brethorst on 10/30/25.
//

import Foundation
import UIKit
import CoreLocation

class OnboardingViewController: UIViewController {

    var onboardingCompleteHandler: ((URL, OTPRegionInfo) -> Void)?

    private var regionPicker: UIPickerView!
    private var continueButton: UIButton!

    private let regions = [
        OTPRegionInfo(
            name: "San Diego",
            description: "San Diego",
            icon: "building.2.fill",
            url: URL(string: "https://realtime.sdmts.com:9091/otp/")!,
            center: CLLocationCoordinate2D(latitude: 32.8850078, longitude: -117.2393175)
        ),
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
