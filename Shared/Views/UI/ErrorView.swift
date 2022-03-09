//
//  ErrorView.swift
//  DanXi-native
//
//  Created by Kavin Zhao on 2021/7/13.
//

import SwiftUI

struct ErrorView: View {
    var error: Error
    
    var body: some View {
        VStack {
            Image(systemName: "xmark.octagon")
                .foregroundColor(.accentColor)
                .imageScale(.large)
            Text(NSLocalizedString("error", comment: "") + "\n\(error.localizedDescription)")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
}

struct ErrorView_Previews: PreviewProvider {
    static var previews: some View {
        ErrorView(error: TreeHoleError.notInitialized)
    }
}
