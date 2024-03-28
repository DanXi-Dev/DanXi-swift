//
//  WatermarkView.swift
//  DanXi
//
//  Created by Serenii on 2024/3/28.
//

import SwiftUI

struct StructuredWatermarkView: View {
    var content: String
    var rowCount: Int
    var columnCount: Int
    var opacity: Double
    
    var body: some View {
        GeometryReader { geometry in
            let cellWidth = geometry.size.width / CGFloat(columnCount)
            let cellHeight = geometry.size.height / CGFloat(rowCount)
            
            ForEach(0..<rowCount * columnCount, id: \.self) { index in
                let row = index / columnCount
                let column = index % columnCount
                
                Text(content)
                    .font(.system(size: 36))
                    .foregroundColor(.gray.opacity(opacity))
                    .rotationEffect(.degrees(20))
                    .frame(width: cellWidth, height: cellHeight, alignment: .center)
                    .position(x: CGFloat(column) * cellWidth + cellWidth / 2,
                              y: CGFloat(row) * cellHeight + cellHeight / 2)
            }
        }
        .background(Color.clear)
    }
}

struct WatermarkModifier: ViewModifier {
    var watermarkContent: String
    var opacity: Double
    
    func body(content: Content) -> some View {
        content
            .overlay(
                StructuredWatermarkView(content: watermarkContent, rowCount: 8, columnCount: 4, opacity: opacity)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            )
    }
}

extension View {
    func watermark(content: String, opacity: Double = 0.1) -> some View {
        self.modifier(WatermarkModifier(watermarkContent: content, opacity: opacity))
    }
}
