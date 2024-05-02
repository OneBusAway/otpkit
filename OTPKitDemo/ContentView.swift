//
//  ContentView.swift
//  OTPKitDemo
//
//  Created by Aaron Brethorst on 5/2/24.
//

import SwiftUI
import OTPKit

struct ContentView: View {
    let restApi = RestAPI()
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text(restApi.hello())
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
