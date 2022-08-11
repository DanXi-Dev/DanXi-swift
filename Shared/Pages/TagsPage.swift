//
//  TagPage.swift
//  DanXi-native
//
//  Created by Singularity on 2022/8/11.
//

import SwiftUI

struct TagsPage: View {
    @State var tags: [THTag] = []
    @State private var isUpdating = false
    @State private var errorInfo: String? = nil
    @State private var searchText = ""
    
    func update() async {
        isUpdating = true
        errorInfo = nil
        defer { isUpdating = false }
        do {
            tags = try await networks.getTags()
        } catch {
            errorInfo = error.localizedDescription
        }
    }
    
    private var filteredTags: [THTag] {
        if searchText.isEmpty { return tags }
        return tags.filter { $0.name.contains(searchText) }
    }
    
    var body: some View {
        List {
            if isUpdating {
                ProgressView()
            }
            
            if let errorInfo = errorInfo {
                Button(errorInfo) {
                    Task.init { await update() }
                }
                .foregroundColor(.red)
            } else {
                ForEach(filteredTags) { tag in
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
        }
        .task {
            await update()
        }
        .searchable(text: $searchText)
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("tags")
    }
}

struct TagPage_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TagsPage(tags: PreviewDecode.decodeObj(name: "tags")!)
            TagsPage(tags: PreviewDecode.decodeObj(name: "tags")!)
                .preferredColorScheme(.dark)
        }
    }
}
