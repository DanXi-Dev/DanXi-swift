import FudanKit
import SwiftUI
import ViewUtils

private struct LibraryRequestOptions: Sendable {
    let policy: LibraryRequestPolicy
    let locations: [LibraryPickupLocation]
}

struct LibraryRequestSheet: View {
    let holding: BookHolding

    @State private var options: LibraryRequestOptions?
    @State private var pickupCode = ""
    @State private var expectedDate = Date.now
    @State private var allowReplace = true

    private var startDate: Date { Calendar.current.startOfDay(for: .now) }

    private func endDate(for policy: LibraryRequestPolicy) -> Date {
        Calendar.current.date(
            byAdding: .day,
            value: max(0, policy.requestDateRange),
            to: startDate
        ) ?? startDate
    }

    private var selectedLocation: LibraryPickupLocation? {
        options?.locations.first { $0.code == pickupCode }
    }

    var body: some View {
        Sheet(String(localized: "Request Book", bundle: .module)) {
            guard let barcode = holding.barcode, let selectedLocation else {
                throw CampusError.customError(message: String(localized: "This copy cannot be requested", bundle: .module))
            }
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.calendar = Calendar(identifier: .gregorian)
            formatter.dateFormat = "yyyy-MM-dd"
            _ = try await LibraryAccountAPI.addRequest(
                itemBarcode: barcode,
                expectDate: formatter.string(from: expectedDate),
                pickupLocation: selectedLocation,
                allowReplace: allowReplace
            )
        } content: {
            Section(String(localized: "Requested Copy", bundle: .module)) {
                LabeledContent(String(localized: "Library", bundle: .module), value: holding.library)
                LabeledContent(String(localized: "Holding Location", bundle: .module), value: holding.location)
                if let callNumber = holding.callNumber {
                    LabeledContent(String(localized: "Call Number", bundle: .module), value: callNumber)
                }
            }

            AsyncContentView(style: .widget) {
                guard let barcode = holding.barcode,
                      let libraryCode = holding.libraryCode,
                      let locationCode = holding.locationCode else {
                    throw CampusError.customError(message: String(localized: "This copy cannot be requested", bundle: .module))
                }
                let policy = try await LibraryAccountAPI.getRequestPolicy(itemBarcode: barcode)
                let locations = try await LibraryAccountAPI.getPickupLocations(
                    libraryCode: libraryCode,
                    locationCode: locationCode
                )
                return LibraryRequestOptions(policy: policy, locations: locations.available)
            } content: { loaded in
                Section(String(localized: "Pickup Details", bundle: .module)) {
                    if loaded.locations.isEmpty {
                        Text("No pickup locations available", bundle: .module)
                            .foregroundStyle(.secondary)
                    } else {
                        Picker(String(localized: "Pickup Location", bundle: .module), selection: $pickupCode) {
                            ForEach(loaded.locations) { location in
                                Text(location.name).tag(location.code)
                            }
                        }
                    }
                    DatePicker(
                        String(localized: "Expected Pickup Date", bundle: .module),
                        selection: $expectedDate,
                        in: startDate...endDate(for: loaded.policy),
                        displayedComponents: .date
                    )
                    Toggle(String(localized: "Allow Another Copy", bundle: .module), isOn: $allowReplace)
                }
                .onAppear {
                    guard options == nil else { return }
                    options = loaded
                    pickupCode = loaded.locations.first?.code ?? ""
                    expectedDate = endDate(for: loaded.policy)
                }
            }
        }
        .submitText(String(localized: "Submit Request", bundle: .module))
        .completed(selectedLocation != nil)
    }
}
