//
//  TagPage.swift
//  DanXi-native
//
//  Created by Singularity on 2022/8/11.
//

import SwiftUI

struct TagRowView: View {
    let tag: THTag
    
    var body: some View {
        HStack {
            Text(tag.name)
                .tagStyle(color: tag.color)
            Label(String(tag.temperature), systemImage: "flame")
        }
        .foregroundColor(tag.color)
    }
}

struct TagsPage: View {
    @ObservedObject private var model = TreeholeDataModel.shared
    @State private var errorInfo: String? = nil
    @State private var searchText = ""
    
    func update() async {
        errorInfo = nil
        do {
            model.tags = try await NetworkRequests.shared.loadTags()
        } catch {
            errorInfo = error.localizedDescription
        }
    }
    
    private var filteredTags: [THTag] {
        if searchText.isEmpty { return model.tags }
        return model.tags.filter { $0.name.contains(searchText) }
    }
    
    var body: some View {
        List {
            if model.tags.isEmpty { // FIXME: This isn't a very good way to determine whether tags are being loaded
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
                        TagRowView(tag: tag)
                    }
                }
            }
        }
        .refreshable {
            await update()
        }
        .searchable(text: $searchText)
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Tags")
    }
}

struct TagPage_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TagsPage()
            TagsPage()
                .preferredColorScheme(.dark)
        }
    }
}