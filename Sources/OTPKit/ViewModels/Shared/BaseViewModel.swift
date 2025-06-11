//
//  BaseViewModel.swift
//  OTPKit
//
//  Created by Manu on 2025-06-06.
//

import Foundation
import SwiftUI

/// Base class for all ViewModels in OTPKit
/// Provides common functionality like error handling, loading states, and lifecycle management
@Observable
open class BaseViewModel {

    // MARK: - Common State Properties

    /// Indicates if the ViewModel is currently performing an async operation
    public var isLoading: Bool = false

    /// Current error state, if any
    public var currentError: OTPKitError?

    /// Indicates if an error alert should be shown
    public var showErrorAlert: Bool = false

    // MARK: - Initialization

    public init() {}

    // MARK: - Common Methods

    /// Sets the loading state
    /// - Parameter loading: Whether loading is active
    public func setLoading(_ loading: Bool) {
        isLoading = loading
    }

    /// Handles errors in a consistent way across all ViewModels
    /// - Parameter error: The error to handle
    public func handleError(_ error: Error) {
        if let otpError = error as? OTPKitError {
            currentError = otpError
        } else {
            // Convert generic errors to OTPKitError
            currentError = .apiError(error.localizedDescription)
        }
        showErrorAlert = true
        isLoading = false
    }

    /// Clears the current error state
    public func clearError() {
        currentError = nil
        showErrorAlert = false
    }

    /// Executes an async task with automatic loading state management
    /// - Parameter task: The async task to execute
    public func executeTask(_ task: @escaping () async throws -> Void) {
        Task {
            await MainActor.run {
                setLoading(true)
                clearError()
            }

            do {
                try await task()
            } catch {
                await MainActor.run {
                    handleError(error)
                }
            }

            await MainActor.run {
                setLoading(false)
            }
        }
    }
}
