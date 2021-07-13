//
//  ErrorView.swift
//  DanXi-native
//
//  Created by Kavin Zhao on 2021/7/13.
//

import SwiftUI

struct ErrorView: View {
    var errorInfo: String
    
    var body: some View {
        VStack {
            Image(systemName: "xmark.octagon")
                .foregroundColor(.accentColor)
                .imageScale(.large)
            Text(NSLocalizedString("error", comment: "") + "\n\(errorInfo)")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
}

struct ErrorView_Previews: PreviewProvider {
    static var previews: some View {
        ErrorView(errorInfo: "Example Error")
    }
}
