//
//  SheetPresenter.swift
//  OTPKit
//
//  Created by Manu on 2025-07-11.
//

import Foundation

// Protocol for any view model that wants to control presenting/dismissing sheets
protocol SheetPresenter: ObservableObject {
    // Holds the currently active sheet (if any)
    var activeSheet: Sheet? { get set }
}

// Default helper methods so conforming types don’t have to re-implement
extension SheetPresenter {
    // Show a new sheet by assigning it
    func present(_ sheet: Sheet) {
        activeSheet = sheet
    }

    // Close any currently shown sheet
    func dismiss() {
        activeSheet = nil
    }
}
