//
//  OriginDestinationView.swift
//  OTPKitDemo
//
//  Created by Hilmy Veradin on 25/06/24.
//

import SwiftUI

struct OriginDestinationView: View {
    var body: some View {
        List {
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
        }
    }
}

#Preview {
    OriginDestinationView()
}
