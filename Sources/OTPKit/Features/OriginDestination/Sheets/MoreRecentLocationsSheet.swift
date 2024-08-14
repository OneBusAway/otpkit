//
//  MoreRecentLocationsSheet.swift
//  OTPKitDemo
//
//  Created by Hilmy Veradin on 03/07/24.
//

import SwiftUI

/// Show all the lists of all recent locations
public struct MoreRecentLocationsSheet: View {
    @Environment(\.dismiss) var dismiss

    @EnvironmentObject private var sheetEnvironment: OriginDestinationSheetEnvironment

    public var body: some View {
        VStack {
            PageHeaderView(text: "Recents") {
                dismiss()
            }
            .padding()

            List {
                ForEach(sheetEnvironment.recentLocations) { location in
                    VStack(alignment: .leading) {
                        Text(location.title)
                            .font(.headline)
                        Text(location.subTitle)
                    }
                }
            }
        }
    }
}

#Preview {
    MoreRecentLocationsSheet()
}
