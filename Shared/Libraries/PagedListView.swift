//
//  PagedListView.swift
//  DanXi-native
//
//  Created by Kavin Zhao on 2022/3/8.
//

import SwiftUI

struct PagedListView<T: Identifiable>: View {
    let headBuilder: () -> AnyView
    let viewBuilder:  (T) -> AnyView
    let initialData: [T]
    let dataLoader: (Int, [T]) async throws -> [T]
    @State private var dataList: [T]
    @State private var endReached = false
    @State private var encounteredError: Error? = nil
    @State private var isLoading = true
    @State private var currentPage = 1
    
    init(headBuilder: @escaping () -> AnyView,
         viewBuilder:  @escaping (T) -> AnyView,
         initialData: [T] = [],
         dataLoader: @escaping (Int, [T]) async throws -> [T]) {
        self.headBuilder = headBuilder
        self.viewBuilder = viewBuilder
        self.initialData = initialData
        self.dataLoader = dataLoader
        
        self.dataList = initialData
    }
    
    func refresh() async {
        encounteredError = nil
        isLoading = true
        defer { isLoading = false }
        currentPage = 1
        do {
            dataList = try await dataLoader(currentPage, dataList)
        }
        catch {
            encounteredError = error
        }
    }
    
    func loadNextPage() async {
        encounteredError = nil
        isLoading = true
        defer { isLoading = false }
        currentPage += 1
        do {
            let newData = try await dataLoader(currentPage, dataList)
            guard !newData.isEmpty else {
                endReached = true
                return
            }
            dataList.append(contentsOf: newData)
        }
        catch {
            encounteredError = error
        }
    }
    
    var body: some View {
        if let hasEncounteredError = encounteredError {
            ErrorView(error: hasEncounteredError)
                .onTapGesture {
                    Task.init{
                        await refresh()
                    }
                }
        } else {
            List {
                headBuilder()
                ForEach(dataList) { data in
                    viewBuilder(data)
                }
                if(!endReached) {
                    ProgressView()
                        .onAppear {
                            Task.init{
                                await loadNextPage()
                            }
                        }
                }
                else {
                    Text("end_reached")
                }
            }
            /*.refreshable {
                await refresh()
            }*/
        }
    }
}

struct PagedListView_Previews: PreviewProvider {
    static var previews: some View {
        EmptyView()
        //PagedListView()
    }
}
