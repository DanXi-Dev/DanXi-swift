//
//  TagPage.swift
//  DanXi-native
//
//  Created by Singularity on 2022/8/11.
//

import SwiftUI

struct TagPage: View {
    @State var tags: [THTag] = []
    @State private var isUpdating = false
    
    var body: some View {
        List {
            if isUpdating {
                ProgressView()
            }
            
            ForEach(tags) { tag in
                NavigationLink(destination: SearchTagPage(tagname: tag.name, divisionId: nil)) {
                    HStack {
                        Text(tag.name)
                            .tagStyle(color: tag.color)
                        Label(String(tag.temperature), systemImage: "flame")
                    }
                        .foregroundColor(tag.color)
                }
            }
        }
        .task {
            isUpdating = true
            defer { isUpdating = false }
            do {
                tags = try await networks.getTags()
            } catch {
                print("Failed to get tags \(error)")
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("tags")
    }
}

struct TagPage_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TagPage(tags: PreviewDecode.decodeObj(name: "tags")!)
            TagPage(tags: PreviewDecode.decodeObj(name: "tags")!)
                .preferredColorScheme(.dark)
        }
    }
}
