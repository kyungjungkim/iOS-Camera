//
//  ContentView.swift
//  B Camera
//
//  Created by Kyungjung Kim on 9/19/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var model = FrameHandler()
    
    var body: some View {
        FrameView(image: model.frame)
            .ignoresSafeArea()
    }
}

#Preview {
    ContentView()
}
