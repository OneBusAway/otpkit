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
    private let tapAction: VoidBlock?
    private let longTapAction: VoidBlock?

    init(title: String, imageName: String, tapAction: VoidBlock? = nil, longTapAction: VoidBlock? = nil) {
        self.title = title
        self.imageName = imageName
        self.tapAction = tapAction
        self.longTapAction = longTapAction
    }

    var body: some View {
        Button(action: {}, label: {
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
        .simultaneousGesture(LongPressGesture().onEnded { _ in
            longTapAction?()
        })
        .simultaneousGesture(TapGesture().onEnded {
            tapAction?()
        })
    }
}

#Preview {
    FavoriteView(title: "Hello, world!", imageName: "mappin")
}
