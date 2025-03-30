//
//  DateTimeSelector.swift
//  OTPKit
//
//  Created by Manu on 2025-03-30.
//

import SwiftUI

struct DateTimeSelector: View {
    @Environment(TripPlannerService.self) private var tripPlanner
    @Binding var selectedDate: Date
    @Binding var selectedTime: Date
    @Binding var isDatePickerVisible: Bool
    @Binding var isTimePickerVisible: Bool

    init(
        selectedDate: Binding<Date>,
        selectedTime: Binding<Date>,
        isDatePickerVisible: Binding<Bool>,
        isTimePickerVisible: Binding<Bool>
    ) {
        self._selectedDate = selectedDate
        self._selectedTime = selectedTime
        self._isDatePickerVisible = isDatePickerVisible
        self._isTimePickerVisible = isTimePickerVisible
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("When:")
                    .fontWeight(.medium)
                Spacer()
                dateButton
                Spacer().frame(width: 8)
                timeButton
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            if isDatePickerVisible {
                Divider()
                DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                    .padding()
                    .transition(.opacity)
                    .onChange(of: selectedDate) { _, newDate in
                        tripPlanner.selectedDate = newDate
                    }
            }

            if isTimePickerVisible {
                Divider()
                DatePicker("Select Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .padding()
                    .frame(maxHeight: 200)
                    .transition(.opacity)
                    .onChange(of: selectedTime) { _, newTime in
                        tripPlanner.selectedTime = newTime
                    }
            }
        }
    }

    private var dateButton: some View {
        Button(action: {
            withAnimation {
                isDatePickerVisible.toggle()
                isTimePickerVisible = false
            }
        }) {
            HStack(spacing: 4) {
                Image(systemName: "calendar")
                    .foregroundColor(.blue)
                    .font(.system(size: 14))
                Text(selectedDate.formattedTripDate)
                    .foregroundColor(.primary)
                    .font(.system(size: 14))
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(Color(.systemGray6))
            .cornerRadius(6)
        }
    }

    private var timeButton: some View {
        Button(action: {
            withAnimation {
                isTimePickerVisible.toggle()
                isDatePickerVisible = false
            }
        }) {
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .foregroundColor(.blue)
                    .font(.system(size: 14))
                Text(selectedTime.formattedTripDate)
                    .foregroundColor(.primary)
                    .font(.system(size: 14))
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(Color(.systemGray6))
            .cornerRadius(6)
        }
    }
}
