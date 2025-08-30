//
//  LocalizedText.swift
//  OTPKit
//
//  Created by Manu on 2025-08-08.
//

import SwiftUI

/// A SwiftUI view that shows a localized string from the package's bundle.
public struct LocalizedText: View {
    private let text: String

    /// Localized text for a simple key.
    public init(_ key: String) {
        self.text = Localization.string(key)
    }

    /// Localized text with format arguments.
    public init(_ key: String, _ args: CVarArg...) {
        self.text = Localization.string(key, args: args)
    }

    public var body: some View {
        Text(text)
    }
}
