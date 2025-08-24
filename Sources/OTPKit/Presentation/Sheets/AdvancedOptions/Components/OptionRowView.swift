//
//  OptionRowView.swift
//  OTPKit
//
//  Created by Manu on 2025-08-21.
//

import SwiftUI

/// A reusable row view for selectable options in advanced settings
struct OptionRowView: View {
    let iconName: String
    let title: String
    let description: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: iconName)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .foregroundColor(.primary)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundColor(.blue)
                    .fontWeight(.semibold)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            action()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title): \(description)")
        .accessibilityHint(isSelected ? OTPLoc("option_row.selected_hint", comment: "Accessibility hint for selected option") : OTPLoc("option_row.tap_to_select_hint", comment: "Accessibility hint for unselected option"))
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

#Preview {
    Form {
        Section(OTPLoc("option_row.preview_section", comment: "Preview section title")) {
            OptionRowView(
                iconName: "timer",
                title: OTPLoc("option_row.fastest_trip_title", comment: "Fastest trip option title"),
                description: OTPLoc("option_row.fastest_trip_desc", comment: "Fastest trip option description"),
                isSelected: true
            ) {
                // Preview action
            }
            
            OptionRowView(
                iconName: "arrow.triangle.swap",
                title: OTPLoc("option_row.fewest_transfers_title", comment: "Fewest transfers option title"),
                description: OTPLoc("option_row.fewest_transfers_desc", comment: "Fewest transfers option description"),
                isSelected: false
            ) {
                // Preview action
            }
        }
    }
}
