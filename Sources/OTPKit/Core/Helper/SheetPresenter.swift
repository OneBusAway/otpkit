//
//  SheetPresenter.swift
//  OTPKit
//
//  Created by Manu on 2025-07-11.
//

import Foundation

protocol SheetPresenter: ObservableObject {
    var activeSheet: Sheet? { get set }
}

extension SheetPresenter {
    func present(_ sheet: Sheet) {
        activeSheet = sheet
    }

    func dismiss() {
        activeSheet = nil
    }
}
