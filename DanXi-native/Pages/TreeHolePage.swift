//
//  TreeHole.swift
//  DanXi-native
//
//  Created by Kavin Zhao on 2021/6/26.
//

import SwiftUI

struct TreeHolePage: View {
    @State private var discussions = [THDiscussion]()
    @State private var currentPage = 1
    @State private var endReached = false
    @State private var errorReason: String? = nil
    
    // Scroll Position Indicator
    @State private var isLoading = true
    
    @Sendable
    func refreshDiscussions() async {
        currentPage = 1
        
        do {
            errorReason = nil
            isLoading = true
            discussions = try await loadDiscussions(page: currentPage, sortOrder: SortOrder.last_updated)
            isLoading = false
        }
        catch {
            isLoading = false
            errorReason = error.localizedDescription
        }
        
    }
    
    @Sendable
    func loadNextPage() async {
        currentPage += 1
        do {
            errorReason = nil
            isLoading = true
            discussions.append(contentsOf: try await loadDiscussions(page: currentPage, sortOrder: SortOrder.last_updated) as [THDiscussion])
            isLoading = false
        }
        catch {
            isLoading = false
            errorReason = error.localizedDescription
        }
        
    }
    
    var body: some View {
        if (errorReason == nil) {
            if (discussions.isEmpty) {
                List {
                    ProgressView()
                }
                .navigationTitle("treehole")
                .onAppear {
                    Task.init(operation: refreshDiscussions)
                }
            }
            else {
                List {
                    ForEach(discussions) { discussion in
                        NavigationLink(destination: TreeHoleDetailsPage(replies: discussion.posts)) {
                            THPostView(discussion: discussion)
                        }
                    }
                    if(!endReached) {
                        ProgressView()
                            .onAppear{
                                Task.init(operation: loadNextPage)
                            }
                    }
                    else {
                        Text("end_reached")
                    }
                }
                .listStyle(.inset)
                .refreshable(action: refreshDiscussions)
                .navigationTitle("treehole")
            }
        }
        else {
            ErrorView(errorInfo: errorReason ?? "Unknown Error")
                .onTapGesture {
                    Task.init(operation: refreshDiscussions)
                }
        }
    }
}

struct TreeHole_Previews: PreviewProvider {
    static var previews: some View {
        TreeHolePage()
    }
}
