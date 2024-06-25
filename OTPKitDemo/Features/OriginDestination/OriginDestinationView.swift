//
//  OriginDestinationView.swift
//  OTPKitDemo
//
//  Created by Hilmy Veradin on 25/06/24.
//

import SwiftUI

struct OriginDestinationView: View {
    @StateObject private var viewModel = OriginDestinationViewModel()
    
    @StateObject private var originDestinationEnvironment = OriginDestinationSheetEnvironment()
    
    @State private var isSheetOpened = false
    
    var body: some View {
        List {
            Button(action: {
                isSheetOpened.toggle()
                originDestinationEnvironment.sheetState = .origin
            }, label: {
                HStack(spacing: 16) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.white)
                        .background(
                            Circle()
                                .fill(Color.green)
                                .frame(width: 30, height: 30)
                        )
                    Text("Origin UI")
                }
            })
            
            Button(action: {
                isSheetOpened.toggle()
                originDestinationEnvironment.sheetState = .destination
            }, label: {
                HStack(spacing: 16) {
                    Image(systemName: "mappin")
                        .foregroundColor(.white)
                        .background(
                            Circle()
                                .fill(Color.green)
                                .frame(width: 30, height: 30)
                        )
                    Text("Destination UI")
                }
            })


        }
        .sheet(isPresented: $isSheetOpened) {
            OriginDestinationSheetView()
                .environmentObject(originDestinationEnvironment)
                .presentationDetents([.medium])
        }

    }
}

#Preview {
    OriginDestinationView()
}
