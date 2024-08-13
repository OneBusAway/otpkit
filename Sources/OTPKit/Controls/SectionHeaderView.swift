//
//  SectionHeaderView.swift
//  OTPKit
//
//  Created by Aaron Brethorst on 7/31/24.
//

import SwiftUI

/// The view that appears above a section on the `OriginDestinationSheetView`.
/// For instance, the header for the Recents and Favorites sections.
struct SectionHeaderView: View {
    private let text: String
    private let action: VoidBlock?

    init(text: String, action: VoidBlock? = nil) {
        self.text = text
        self.action = action
    }

    var body: some View {
        HStack {
            Text(text)
                .textCase(.none)
            Spacer()
            Button(action: {
                action?()
            }, label: {
                Text("More")
                    .textCase(.none)
                    .font(.subheadline)
            })
        }
    }
}

#Preview {
    SectionHeaderView(text: "Hello, world!")
}
