import SwiftUI

struct FDPlaygroundPage: View {
    var body: some View {
        AsyncContentView {
            return try await FDPlaygroundModel.load()
        } content: { model in
            FDPlaygroundContent(model)
        }
    }
}

fileprivate struct FDPlaygroundContent: View {
    @StateObject var model: FDPlaygroundModel
    
    init(_ model: FDPlaygroundModel) {
        self._model = StateObject(wrappedValue: model)
    }
    
    var body: some View {
        List {
            Section {
                Picker(selection: $model.campus, label: Text("Campus")) {
                    ForEach(model.campusList, id: \.self) { campus in
                        Text(campus).tag(campus)
                    }
                    Text("All").tag("")
                }
                Picker(selection: $model.type, label: Text("Playground Type")) {
                    ForEach(model.typesList, id: \.self) { type in
                        Text(type).tag(type)
                    }
                    Text("All").tag("")
                }
            }
            
            Section("Playground List") {
                ForEach(model.filteredPlaygrounds) { playground in
                    NavigationLink(value: playground) {
                        Label(playground.name, systemImage: model.categoryIcon(playground.type))
                    }
                }
            }
        }
        .navigationTitle("Playground Reservation")
        .navigationDestination(for: FDPlayground.self) { playground in
            FDPlaygroundReservePage(playground)
        }
    }
}

fileprivate struct FDPlaygroundReservePage: View {
    @StateObject var model: FDReservationModel
    
    init(_ playground: FDPlayground) {
        self._model = StateObject(wrappedValue: FDReservationModel(playground))
    }
    
    var body: some View {
        List {
            Section {
                DatePicker("Select Reservation Date", selection: $model.date, displayedComponents: [.date])
                Toggle("Available Time Slots Only", isOn: $model.showAvailable)
            }
            
            Section {
                ForEach(model.filteredTimeSlots) { timeSlot in
                    FDReservationTimeSlotView(timeSlot: timeSlot)
                }
            } header: {
                Text("Reservation Time Slots")
            } footer: {
                if model.timeSlots.isEmpty {
                    LoadingFooter(loading: $model.loading,
                                  errorDescription: model.loadingError?.localizedDescription ?? "",
                                  action: model.loadTimeSlots)
                }
            }
            .task {
                await model.loadTimeSlots()
            }
        }
        .navigationTitle(model.playground.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

fileprivate struct FDReservationTimeSlotView: View {
    let timeSlot: FDPlaygroundTimeSlot
    
    var body: some View {
        HStack {
            Text("\(timeSlot.beginTime) - \(timeSlot.endTime)")
            Spacer()
            Text("\(timeSlot.reserved) / \(timeSlot.total)")
            Spacer()
            if let url = timeSlot.registerURL {
                Link("Reserve", destination: url)
            } else if timeSlot.reserved == timeSlot.total {
                Text("Reserved")
                    .foregroundColor(.secondary)
            } else {
                Text("Cannot Reserve")
                    .foregroundColor(.secondary)
            }
        }
    }
}
