//
//  OriginDestinationSheetView.swift
//  OTPKitDemo
//
//  Created by Hilmy Veradin on 25/06/24.
//

import SwiftUI

struct OriginDestinationSheetView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var sheetEnvironment: OriginDestinationSheetEnvironment
    
    var body: some View {
        Text("Hello!")
    }
}

#Preview {
    OriginDestinationSheetView()
}
