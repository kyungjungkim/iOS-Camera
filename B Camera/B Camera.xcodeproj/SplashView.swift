//
//  SplashView.swift
//  B Camera
//
//  Created by Kyungjung Kim on 9/19/25.
//

import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 12) {
                // 로고가 있으면 아래 라인을 사용하세요: Image("AppLogo").resizable().scaledToFit().frame(width: 120, height: 120)
                Text("B Camera")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(.white)
                Text("Starting…")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("B Camera Starting")
    }
}

#Preview {
    SplashView()
}
