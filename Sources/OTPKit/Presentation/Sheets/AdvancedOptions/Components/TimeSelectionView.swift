//
//  TimeSelectionView.swift
//  OTPKit
//
//  Created by Manu on 2025-08-21.
//

import SwiftUI

/// A reusable view for selecting date and time in advanced options
struct TimeSelectionView: View {
    @Binding var selectedDate: Date
    @Binding var selectedTime: Date

    var body: some View {
        VStack(spacing: 12) {
            DatePicker(OTPLoc("time_selection.date", comment: "Date picker label"), selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(.compact)
                .accessibilityLabel(OTPLoc("time_selection.select_date_accessibility", comment: "Accessibility label for date picker"))

            DatePicker(OTPLoc("time_selection.time", comment: "Time picker label"), selection: $selectedTime, displayedComponents: .hourAndMinute)
                .datePickerStyle(.compact)
                .accessibilityLabel(OTPLoc("time_selection.select_time_accessibility", comment: "Accessibility label for time picker"))
        }
        .padding(.top, 8)
    }
}

#Preview {
    @Previewable @State var date = Date()
    @Previewable @State var time = Date()

    return Form {
        Section(OTPLoc("time_selection.title", comment: "Section title for time selection")) {
            TimeSelectionView(selectedDate: $date, selectedTime: $time)
        }
    }
}
