//
//  SwiftUIView.swift
//  OTPKit
//
//  Created by Mohamed Sliem on 21/03/2025.
//

import SwiftUI

struct AddFavoriteCell: View {

    private let title: String
    private let subtitle: String
    private let action: VoidBlock

    init(title: String, subtitle: String, action: @escaping VoidBlock) {
        self.title = title
        self.subtitle = subtitle
        self.action = action
    }

    var body: some View {
        Button(action: {
            action()
        }, label: {
            HStack {
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.headline)
                    Text(subtitle)
                }.foregroundStyle(.foreground)

                Spacer()

                Image(systemName: "plus")
            }

        })

    }
}
