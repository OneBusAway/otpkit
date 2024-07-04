//
//  FavoriteLocationDetailSheet.swift
//  OTPKitDemo
//
//  Created by Hilmy Veradin on 04/07/24.
//

import SwiftUI

/// This responsible for showing the details of favorite locations
/// Users can see the details and delete the location sheet
struct FavoriteLocationDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var sheetEnvironment: OriginDestinationSheetEnvironment

    @State private var isShowErrorAlert = false
    @State private var errorMessage = ""

    private func headerView() -> some View {
        HStack {
            Text("Favorite location detail")
                .font(.title2)
                .fontWeight(.bold)
            Spacer()
            Button(action: {
                sheetEnvironment.selectedDetailFavoriteLocation = nil
                dismiss()
            }, label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.gray)
            })
        }
    }

    var body: some View {
        VStack {
            headerView()
                .padding(.vertical)

            Text("\(sheetEnvironment.selectedDetailFavoriteLocation?.title ?? "")")
                .font(.headline)
            Text("\(sheetEnvironment.selectedDetailFavoriteLocation?.subTitle ?? "")")

            Button(action: {
                guard let uid = sheetEnvironment.selectedDetailFavoriteLocation?.id else {
                    return
                }
                switch UserDefaultsServices.shared.deleteFavoriteLocationData(with: uid) {
                case .success:
                    sheetEnvironment.selectedDetailFavoriteLocation = nil
                    sheetEnvironment.refreshFavoriteLocations()
                    dismiss()
                case let .failure(failure):
                    errorMessage = failure.localizedDescription
                    isShowErrorAlert.toggle()
                }
            }, label: {
                Text("Delete Location")
            })
            .padding()

            Spacer()
        }
        .padding()
        .alert(isPresented: $isShowErrorAlert) {
            Alert(title: Text("Error Delete Favorite Location"),
                  message: Text(errorMessage),
                  dismissButton: .cancel(Text("Ok")))
        }
    }
}

#Preview {
    FavoriteLocationDetailSheet()
}
