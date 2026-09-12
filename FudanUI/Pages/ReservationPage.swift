import FudanKit
import Foundation
import SwiftUI
import ViewUtils

struct ReservationPage: View {
    var body: some View {
        AsyncContentView {
            async let topic = SportsReservationStore.shared.getTopic()
            async let venues = SportsReservationStore.shared.getVenues()
            let (loadedTopic, loadedVenues) = try await (topic, venues)
            return SportsReservationHomeData(topic: loadedTopic, venues: loadedVenues)
        } refreshAction: {
            async let topic = SportsReservationStore.shared.getTopic(forceRefresh: true)
            async let venues = SportsReservationStore.shared.getVenues(forceRefresh: true)
            let (loadedTopic, loadedVenues) = try await (topic, venues)
            return SportsReservationHomeData(topic: loadedTopic, venues: loadedVenues)
        } content: { data in
            SportsVenueList(data: data)
        }
        .navigationTitle(String(localized: "Playground Reservation", bundle: .module))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    SportsAppointmentsPage()
                } label: {
                    Label(bookingLocalized("My Reservations"), systemImage: "calendar.badge.clock")
                }
            }
        }
    }
}

private struct SportsReservationHomeData: Sendable {
    let topic: BookingTopic
    let venues: [BookingVenue]
}

private struct SportsVenueList: View {
    let data: SportsReservationHomeData
    @State private var searchText = ""
    @State private var selectedCampus = "全部"
    @State private var selectedType = "全部"
    @State private var selectedEnvironment = "全部"

    private let campuses = ["全部", "邯郸", "江湾", "枫林", "张江"]
    private let venueTypes = ["全部", "篮球", "排球", "羽毛球", "网球", "足球", "舞蹈房", "乒乓球"]
    private let environments = ["全部", "室内", "室外"]

    private var filteredVenues: [BookingVenue] {
        data.venues.filter { venue in
            (searchText.isEmpty || venue.name.localizedCaseInsensitiveContains(searchText))
                && (selectedCampus == "全部" || venue.name.contains(selectedCampus))
                && (selectedType == "全部" || venue.name.contains(selectedType))
                && (selectedEnvironment == "全部" || environment(for: venue) == selectedEnvironment)
        }
    }

    var body: some View {
        List {
            Section {
                HStack(spacing: 24) {
                    ReservationStatistic(
                        title: bookingLocalized("Reservations"),
                        value: data.topic.appointmentCount,
                        systemImage: "checkmark.circle.fill"
                    )
                    ReservationStatistic(
                        title: bookingLocalized("Visits"),
                        value: data.topic.visitCount,
                        systemImage: "eye.fill"
                    )
                }
                .padding(.vertical, 6)

                if !data.topic.description.plainText.isEmpty {
                    NavigationLink {
                        BookingTextPage(title: bookingLocalized("Reservation Instructions"), text: data.topic.description.plainText)
                    } label: {
                        Label(bookingLocalized("Reservation Instructions"), systemImage: "doc.text")
                    }
                }
            } header: {
                Text(data.topic.name)
            }

            Section {
                Picker(bookingLocalized("Campus"), selection: $selectedCampus) {
                    ForEach(campuses, id: \.self) { campus in
                        Text(verbatim: campus).tag(campus)
                    }
                }
                Picker(bookingLocalized("Venue Type"), selection: $selectedType) {
                    ForEach(venueTypes, id: \.self) { type in
                        Text(verbatim: type).tag(type)
                    }
                }
                Picker(bookingLocalized("Indoor/Outdoor"), selection: $selectedEnvironment) {
                    ForEach(environments, id: \.self) { environment in
                        Text(verbatim: environment).tag(environment)
                    }
                }
            } header: {
                Text("Filters", bundle: .module)
            }

            Section {
                if filteredVenues.isEmpty {
                    Text("No matching sports venues", bundle: .module)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(filteredVenues) { venue in
                        NavigationLink {
                            SportsVenuePage(venue: venue)
                        } label: {
                            SportsVenueRow(venue: venue)
                        }
                    }
                }
            } header: {
                Text("Sports Venues", bundle: .module)
            }
        }
        .searchable(text: $searchText, prompt: Text("Search Venues", bundle: .module))
    }

    private func environment(for venue: BookingVenue) -> String {
        let location = venue.name.components(separatedBy: "-").first ?? venue.name
        if location.contains("体育馆") || location.contains("活动中心") || location.contains("舞蹈房") {
            return "室内"
        }
        return "室外"
    }
}

private struct ReservationStatistic: View {
    let title: String
    let value: Int
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: systemImage)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value, format: .number)
                .font(.title3.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct SportsVenueRow: View {
    let venue: BookingVenue

    var body: some View {
        HStack(spacing: 12) {
            #if !os(watchOS)
            AsyncImage(url: venue.imageURL) { phase in
                switch phase {
                case let .success(image):
                    image
                        .resizable()
                        .scaledToFill()
                default:
                    ZStack {
                        Color.secondary.opacity(0.12)
                        Image(systemName: venueSystemImage(venue.name))
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(width: 96, height: 64)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            #endif

            VStack(alignment: .leading, spacing: 5) {
                Text(venue.name)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                if venue.introduction?.isEnabled == true,
                   let introduction = venue.introduction,
                   !introduction.plainText.isEmpty {
                    Text(introduction.plainText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(.vertical, 3)
    }
}

private struct SportsVenuePage: View {
    let venue: BookingVenue

    var body: some View {
        AsyncContentView {
            try await SportsReservationStore.shared.getVenueDetail(id: venue.id)
        } content: { detail in
            SportsVenueContent(venue: venue, detail: detail)
        }
        .navigationTitle(venue.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct SportsVenueContent: View {
    let venue: BookingVenue
    let detail: BookingVenueDetail
    @State private var date = Date.now
    @State private var presentedSheet: VenueSheet?
    @State private var reservationSucceeded = false
    @State private var calendarVersion = UUID()

    var body: some View {
        List {
            #if !os(watchOS)
            if let imageURL = venue.imageURL {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case let .success(image):
                        image.resizable().scaledToFill()
                    default:
                        Rectangle()
                            .fill(.secondary.opacity(0.12))
                            .overlay {
                                Image(systemName: venueSystemImage(venue.name))
                                    .font(.largeTitle)
                                    .foregroundStyle(.secondary)
                            }
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
            #endif

            if let introduction = detail.introduction,
               introduction.isEnabled,
               !introduction.plainText.isEmpty {
                Section(bookingLocalized("Venue Introduction")) {
                    Text(introduction.plainText)
                }
            }

            if let description = detail.bookingDescription,
               description.isEnabled,
               !description.plainText.isEmpty {
                Section {
                    NavigationLink {
                        BookingTextPage(title: bookingLocalized("Reservation Rules"), text: description.plainText)
                    } label: {
                        Label(bookingLocalized("View Reservation Rules"), systemImage: "info.circle")
                    }
                }
            }

            Section(bookingLocalized("Reservation Date")) {
                if detail.usable {
                    DatePicker(bookingLocalized("Date"), selection: $date, in: allowedDates, displayedComponents: .date)
                } else {
                    Label(systemImage: "exclamationmark.circle") {
                        Text(detail.limitInfo.isEmpty ? bookingLocalized("This venue is currently unavailable") : detail.limitInfo)
                    }
                    .foregroundStyle(.secondary)
                }
            }

            if detail.usable {
                Section(bookingLocalized("Time Slots")) {
                    AsyncContentView(style: .widget) {
                        let range = calendarRange(containing: date)
                        return try await SportsReservationStore.shared.getCalendar(
                            venueID: venue.id,
                            from: range.start,
                            through: range.end
                        )
                    } content: { calendar in
                        if calendar.periods.isEmpty {
                            Text("No time slots are open on this date", bundle: .module)
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(calendar.periods) { period in
                                BookingPeriodRow(
                                    period: period,
                                    calendar: calendar,
                                    date: date,
                                    onReserve: {
                                        presentedSheet = .reserve(period, calendar)
                                    },
                                    onShowReservations: {
                                        presentedSheet = .reservationInfo(period, calendar)
                                    }
                                )
                            }
                        }
                    }
                    .id(bookingDateString(date) + calendarVersion.uuidString)
                }
            }
        }
        .sheet(item: $presentedSheet) { sheet in
            switch sheet {
            case let .reserve(period, calendar):
                BookingFormSheet(
                    venue: venue,
                    detail: detail,
                    calendar: calendar,
                    date: date,
                    period: period
                ) {
                    calendarVersion = UUID()
                    reservationSucceeded = true
                }
            case let .reservationInfo(period, calendar):
                ReservationInfoSheet(
                    venue: venue,
                    calendar: calendar,
                    date: date,
                    period: period
                )
            }
        }
        .alert(bookingLocalized("Reservation Successful"), isPresented: $reservationSucceeded) {
            Button(bookingLocalized("OK"), role: .cancel) {}
        } message: {
            Text("The venue is reserved. View the assigned court in My Reservations.", bundle: .module)
        }
    }

    private var allowedDates: ClosedRange<Date> {
        let calendar = bookingCalendar
        let today = calendar.startOfDay(for: .now)
        let end = calendar.date(byAdding: .day, value: 3, to: today) ?? today
        return today ... end
    }
}

private struct BookingPeriodRow: View {
    let period: BookingPeriod
    let calendar: BookingCalendar
    let date: Date
    let onReserve: () -> Void
    let onShowReservations: () -> Void

    private var availableCount: Int {
        calendar.availableCourts(on: bookingDateString(date), periodID: period.id).count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(period.displayTime)
                    .font(.body.monospacedDigit().weight(.medium))
                Spacer()
                Group {
                    if availableCount > 0 {
                        Text("Available: \(availableCount)", bundle: .module)
                    } else {
                        Text("Full", bundle: .module)
                    }
                }
                .font(.caption)
                .foregroundStyle(availableCount > 0 ? Color.green : Color.secondary)
            }

            HStack {
                if availableCount < calendar.courts.count {
                    Button(bookingLocalized("Reservation Info"), action: onShowReservations)
                        .buttonStyle(.borderless)
                }
                Spacer()
                if availableCount > 0 {
                    Button(bookingLocalized("Reserve"), action: onReserve)
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                }
            }
        }
        .padding(.vertical, 3)
    }
}

private enum VenueSheet: Identifiable {
    case reserve(BookingPeriod, BookingCalendar)
    case reservationInfo(BookingPeriod, BookingCalendar)

    var id: String {
        switch self {
        case let .reserve(period, _): "reserve-\(period.id)"
        case let .reservationInfo(period, _): "info-\(period.id)"
        }
    }
}

private struct BookingFormSheet: View {
    @Environment(\.dismiss) private var dismiss
    let venue: BookingVenue
    let detail: BookingVenueDetail
    let calendar: BookingCalendar
    let date: Date
    let period: BookingPeriod
    let onSuccess: () -> Void

    @State private var values: [String: String] = [:]
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section(bookingLocalized("Reservation Details")) {
                    LabeledContent(bookingLocalized("Venue"), value: venue.name)
                    LabeledContent(bookingLocalized("Date"), value: bookingDateString(date))
                    LabeledContent(bookingLocalized("Time Slot"), value: period.displayTime)
                    LabeledContent(bookingLocalized("Court"), value: bookingLocalized("Assigned automatically"))
                }

                if !detail.requiredFields.isEmpty {
                    Section(bookingLocalized("Contact Information")) {
                        ForEach(detail.requiredFields, id: \.self) { field in
                            TextField(field.name, text: valueBinding(for: field))
                                #if os(iOS)
                                .keyboardType(field.type == "mobile" ? .phonePad : .default)
                                #endif
                        }
                    }
                }

                if detail.requiresCaptcha {
                    Section {
                        Label(bookingLocalized("This venue requires CAPTCHA, which is not supported yet."), systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.orange)
                        Link(destination: SportsReservationAPI.webReservationURL(venueID: venue.id)) {
                            Label(bookingLocalized("Open Web Reservation"), systemImage: "safari")
                        }
                    }
                }
            }
            .navigationTitle(bookingLocalized("Confirm Reservation"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(bookingLocalized("Cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(bookingLocalized("Submit")) {
                        submit()
                    }
                    .disabled(isSubmitting || detail.requiresCaptcha)
                }
            }
            .task {
                await fillContactInformation()
            }
            .alert(bookingLocalized("Reservation Failed"), isPresented: errorPresented) {
                Button(bookingLocalized("OK"), role: .cancel) {}
            } message: {
                Text(errorMessage ?? bookingLocalized("Unknown Error"))
            }
            .overlay {
                if isSubmitting {
                    ProgressView()
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    private var errorPresented: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )
    }

    private func valueBinding(for field: BookingFormField) -> Binding<String> {
        Binding(
            get: { values[field.name, default: ""] },
            set: { values[field.name] = $0 }
        )
    }

    private func fillContactInformation() async {
        guard let contact = try? await SportsReservationStore.shared.getContact() else { return }
        for field in detail.requiredFields where field.type == "mobile" && values[field.name, default: ""].isEmpty {
            values[field.name] = contact.mobile
        }
    }

    private func submit() {
        let missingField = detail.requiredFields.first {
            $0.isRequired && values[$0.name, default: ""].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        guard missingField == nil else {
            errorMessage = String(
                format: bookingLocalized("Please fill in %@"),
                missingField?.name ?? bookingLocalized("required information")
            )
            return
        }

        isSubmitting = true
        Task {
            do {
                let fields = detail.requiredFields.map {
                    BookingCollectedField(name: $0.name, value: values[$0.name, default: ""], type: $0.type)
                }
                let request = BookingLaunchRequest(
                    groupID: venue.id,
                    resourceIDs: calendar.courts.map(\.id),
                    date: date,
                    periodID: period.id,
                    collectedFields: fields
                )
                _ = try await SportsReservationStore.shared.launch(request)
                isSubmitting = false
                dismiss()
                onSuccess()
            } catch {
                isSubmitting = false
                errorMessage = error.localizedDescription
            }
        }
    }
}

private struct ReservationInfoSheet: View {
    @Environment(\.dismiss) private var dismiss
    let venue: BookingVenue
    let calendar: BookingCalendar
    let date: Date
    let period: BookingPeriod

    var body: some View {
        NavigationStack {
            AsyncContentView {
                try await SportsReservationStore.shared.getReservationInfo(
                    venueID: venue.id,
                    resourceIDs: calendar.courts.map(\.id),
                    date: date,
                    period: period
                )
            } content: { page in
                List {
                    if page.reservations.isEmpty {
                        Text("No public reservation information for this time slot", bundle: .module)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(page.reservations) { reservation in
                            VStack(alignment: .leading, spacing: 5) {
                                Text(reservation.name)
                                    .font(.body.weight(.medium))
                                if let department = reservation.departmentName, !department.isEmpty {
                                    Text(department)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                if let number = reservation.number, !number.isEmpty {
                                    Text(number)
                                        .font(.caption.monospaced())
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(period.displayTime)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(bookingLocalized("Done")) { dismiss() }
                }
            }
        }
    }
}

private struct SportsAppointmentsPage: View {
    @State private var version = UUID()

    var body: some View {
        AsyncContentView {
            try await SportsReservationStore.shared.getAppointments(pageSize: 50)
        } refreshAction: {
            try await SportsReservationStore.shared.getAppointments(pageSize: 50)
        } content: { page in
            SportsAppointmentList(appointments: page.appointments) {
                version = UUID()
            }
        }
        .id(version)
        .navigationTitle(bookingLocalized("My Reservations"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct SportsAppointmentList: View {
    let appointments: [BookingAppointment]
    let onChanged: () -> Void
    @State private var cancelTarget: BookingAppointment?
    @State private var isCancelling = false
    @State private var errorMessage: String?

    var body: some View {
        List {
            if appointments.isEmpty {
                Text("No sports venue reservations", bundle: .module)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(appointments) { appointment in
                    Section {
                        ForEach(appointment.details) { detail in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(detail.date)
                                    .font(.body.weight(.medium))
                                Text(detail.displayTime)
                                    .font(.subheadline.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                        }

                        if appointment.canCancel {
                            Button(bookingLocalized("Cancel Reservation"), role: .destructive) {
                                cancelTarget = appointment
                            }
                            .disabled(isCancelling)
                        }
                    } header: {
                        Text(appointment.resourceName)
                    } footer: {
                        Text(appointment.statusName)
                    }
                }
            }
        }
        .confirmationDialog(
            bookingLocalized("Cancel this reservation?"),
            isPresented: cancelConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button(bookingLocalized("Cancel Reservation"), role: .destructive) {
                cancelAppointment()
            }
            Button(bookingLocalized("Keep Reservation"), role: .cancel) {
                cancelTarget = nil
            }
        }
        .alert(bookingLocalized("Cancellation Failed"), isPresented: errorPresented) {
            Button(bookingLocalized("OK"), role: .cancel) {}
        } message: {
            Text(errorMessage ?? bookingLocalized("Unknown Error"))
        }
    }

    private var cancelConfirmationPresented: Binding<Bool> {
        Binding(
            get: { cancelTarget != nil },
            set: { if !$0 { cancelTarget = nil } }
        )
    }

    private var errorPresented: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )
    }

    private func cancelAppointment() {
        guard let appointment = cancelTarget else { return }
        cancelTarget = nil
        isCancelling = true
        Task {
            do {
                let detailIDs = appointment.details.filter(\.canCancel).map(\.id)
                try await SportsReservationStore.shared.cancel(
                    appointmentID: appointment.id,
                    detailIDs: detailIDs
                )
                isCancelling = false
                onChanged()
            } catch {
                isCancelling = false
                errorMessage = error.localizedDescription
            }
        }
    }
}

private struct BookingTextPage: View {
    let title: String
    let text: String

    var body: some View {
        ScrollView {
            Text(text)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private var bookingCalendar: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Asia/Shanghai")!
    return calendar
}

private func bookingDateString(_ date: Date) -> String {
    let components = bookingCalendar.dateComponents([.year, .month, .day], from: date)
    return String(
        format: "%04d-%02d-%02d",
        components.year ?? 0,
        components.month ?? 0,
        components.day ?? 0
    )
}

private func calendarRange(containing date: Date) -> (start: Date, end: Date) {
    let calendar = bookingCalendar
    let day = calendar.startOfDay(for: date)
    let weekday = calendar.component(.weekday, from: day)
    let daysSinceMonday = (weekday + 5) % 7
    let start = calendar.date(byAdding: .day, value: -daysSinceMonday, to: day) ?? day
    let end = calendar.date(byAdding: .day, value: 6, to: start) ?? day
    return (start, end)
}

private func venueSystemImage(_ name: String) -> String {
    let symbols = [
        "篮球": "basketball.fill",
        "排球": "volleyball.fill",
        "羽毛球": "figure.badminton",
        "足球": "soccerball",
        "网球": "tennis.racket",
        "舞蹈": "figure.dance",
        "乒乓球": "figure.table.tennis"
    ]
    return symbols.first(where: { name.contains($0.key) })?.value ?? "sportscourt"
}

private func bookingLocalized(_ key: String.LocalizationValue) -> String {
    String(localized: key, bundle: .module)
}
