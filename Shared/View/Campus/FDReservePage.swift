import SwiftUI

struct FDReservePage: View {
    let playground: FDPlayground
    @State var date = Date.now
    @State var timeSlots: [FDPlaygroundTimeSlot] = []
    @State var showAvailable = true
    
    var filteredTimeSlots: [FDPlaygroundTimeSlot] {
        timeSlots.filter { $0.reserveId != nil || !showAvailable }
    }
    
    @State var loading = false
    @State var errorDescription = ""
    
    func loadTimeSlots() async {
        do {
            Task { @MainActor in
                self.timeSlots = []
            }
            loading = true
            defer { loading = false }
            let timeSlots = try await FDPlaygroundAPI.getTimeSlotList(playground: playground, date: date)
            Task { @MainActor in
                self.timeSlots = timeSlots
            }
        } catch {
            errorDescription = error.localizedDescription
        }
    }
    
    var body: some View {
        List {
            Section {
                DatePicker("Select Reservation Date", selection: $date, displayedComponents: [.date])
                Toggle("Available Time Slots Only", isOn: $showAvailable)
            }
            
            Section {
                ForEach(filteredTimeSlots) { timeSlot in
                    FDReservationTimeSlotView(timeSlot: timeSlot)
                }
            } header: {
                Text("Reservation Time Slots")
            } footer: {
                if timeSlots.isEmpty {
                    LoadingFooter(loading: $loading, errorDescription: errorDescription, action: loadTimeSlots)
                        .task {
                            await loadTimeSlots()
                        }
                }
            }
        }
        .navigationTitle(playground.name)
        .onChange(of: date) { _ in
            Task {
                await loadTimeSlots()
            }
        }
    }
}

struct FDReservationTimeSlotView: View {
    let timeSlot: FDPlaygroundTimeSlot
    
    var body: some View {
        HStack {
            Text("\(timeSlot.beginTime) - \(timeSlot.endTime)")
            Spacer()
            Text("\(timeSlot.reserved) / \(timeSlot.total)")
            Spacer()
            if let url = timeSlot.registerURL {
                Link("Reserve", destination: url)
            } else {
                Text("Reserved")
                    .foregroundColor(.secondary)
            }
        }
    }
}
