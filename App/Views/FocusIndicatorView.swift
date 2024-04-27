//
//  FocusIndicatorView.swift
//  3DScanner
//
//  Created by Alexander Onishchenko on 27.04.2024.
//

import SwiftUI

struct FocusIndicatorView: View {
    var center: CGPoint
    var isVisible: Bool

    var body: some View {
        Rectangle()
            .stroke(lineWidth: 2)
            .foregroundColor(.yellow)
            .frame(width: isVisible ? 80 : 0, height: isVisible ? 80 : 0) // Начинаем с 0 размера
            .background(Rectangle().fill(Color.clear))
            .position(center)
            .opacity(isVisible ? 1 : 0)
            .animation(.easeInOut(duration: 0.3), value: isVisible)
    }
}

