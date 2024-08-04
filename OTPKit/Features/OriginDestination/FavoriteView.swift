//
//  FavoriteView.swift
//  OTPKit
//
//  Created by Aaron Brethorst on 7/31/24.
//

import SwiftUI

/// A button that wraps a circle with an icon above a line of text.
struct FavoriteView: View {
    private let title: String
    private let imageName: String
    private let action: VoidBlock?

    init(title: String, imageName: String, action: VoidBlock? = nil) {
        self.title = title
        self.imageName = imageName
        self.action = action
    }

    var body: some View {
        Button(action: {
            action?()
        }, label: {
            VStack(alignment: .center) {
                Image(systemName: imageName)
                    .frame(width: 48, height: 48)
                    .background(Color.gray.opacity(0.5))
                    .clipShape(Circle())

                Text(title)
                    .font(.caption)
                    .frame(width: 64)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .padding(.all, 4)
            .foregroundStyle(.foreground)
        })
    }
}

#Preview {
    FavoriteView(title: "Hello, world!", imageName: "mappin")
}
