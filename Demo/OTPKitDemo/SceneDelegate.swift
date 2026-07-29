//
//  SceneDelegate.swift
//  OTPKitDemo
//
//  Created by Aaron Brethorst on 7/28/26.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        window.backgroundColor = .systemBackground

        // Check if onboarding has been completed
        let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")

        if hasCompletedOnboarding,
           let serverURL = UserDefaults.standard.url(forKey: "otpServerURL"),
           let regionData = UserDefaults.standard.data(forKey: "selectedRegion"),
           let region = try? JSONDecoder().decode(OTPRegionInfo.self, from: regionData) {
            // Show main OTP view controller
            window.rootViewController = makeMainViewController(serverURL: serverURL, regionInfo: region)
        } else {
            // Show onboarding
            let onboardingViewController = OnboardingViewController()
            onboardingViewController.onboardingCompleteHandler = { [weak self] serverURL, regionInfo in
                self?.showMainViewController(serverURL: serverURL, regionInfo: regionInfo)
            }
            window.rootViewController = onboardingViewController
        }

        window.makeKeyAndVisible()
        self.window = window
    }

    private func makeMainViewController(serverURL: URL, regionInfo: OTPRegionInfo) -> UIViewController {
        UINavigationController(rootViewController: OTPDemoViewController(serverURL: serverURL, regionInfo: regionInfo))
    }

    private func showMainViewController(serverURL: URL, regionInfo: OTPRegionInfo) {
        guard let window else { return }

        let mainViewController = makeMainViewController(serverURL: serverURL, regionInfo: regionInfo)
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve) {
            window.rootViewController = mainViewController
        }
    }
}
