import FudanKit
import SwiftUI
import ViewUtils
#if canImport(EventKitUI)
import EventKit
#endif

struct ExamPage: View {
    @State var selectedExam: Exam? = nil
    @State private var showExportSheet = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        AsyncContentView {
            try await UndergraduateCourseAPI.getExams()
        } content: { exams in
            List {
                ForEach(exams) { exam in
                    Button {
                        selectedExam = exam
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(exam.course)
                                    .fontWeight(.bold)
                                    .foregroundColor(exam.isFinished ? .secondary : .primary)
                                Text(verbatim: "\(exam.date)  \(exam.time)")
                                    .foregroundColor(.secondary)
                                    .font(.footnote)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                    if !exam.type.contains("无") {
                                        Text(exam.type)
                                            .fontWeight(.bold)
                                            .foregroundColor(exam.isFinished ? .secondary : .primary)
                                            .font(.footnote)
                                    }
                                    if !exam.location.contains("无") || !exam.method.contains("无") {
                                        let locationText = exam.location
                                        let methodText = exam.method
                                        let combinedText = !methodText.contains("无") ? "\(locationText)(\(methodText))" : locationText
                                        Text(combinedText)
                                            .foregroundColor(.secondary)
                                            .font(.footnote)
                                    }
                                }
                        }
                    }
                    .tint(.primary)
                }
            }
            .navigationTitle(String(localized: "Exams", bundle: .module))
            .sheet(item: $selectedExam) { exam in
                ExamDetailSheet(exam: exam)
                    .presentationDetents([.medium])
            }
#if canImport(EventKitUI)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showExportSheet = true
                        } label: {
                            Label {
                                Text("Export to Calendar", bundle: .module)
                            } icon: {
                                Image(systemName: "square.and.arrow.up")
                            }
                        }
                        .disabled(!exams.contains { $0.calendarInterval != nil })
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showExportSheet) {
                ExamExportSheet(exams: exams.filter { $0.calendarInterval != nil })
            }
#endif
        }
        .navigationTitle(String(localized: "Exams", bundle: .module))
        .navigationBarTitleDisplayMode(.inline)
    }
}

#if canImport(EventKitUI)
private extension Exam {
    var calendarTitle: String {
        [course, type].filter { !$0.isEmpty && $0 != "无" }.joined(separator: " ")
    }

    var calendarInterval: DateInterval? {
        let times = time.components(separatedBy: "~")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        guard (1...2).contains(times.count), let first = times.first, let last = times.last else { return nil }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(identifier: "Asia/Shanghai")
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        guard let start = formatter.date(from: "\(date) \(first)"),
              let end = formatter.date(from: "\(date) \(last)"),
              formatter.string(from: start) == "\(date) \(first)",
              formatter.string(from: end) == "\(date) \(last)", end >= start else { return nil }
        return DateInterval(start: start, end: end)
    }
}

private struct ExamExportSheet: View {
    @Environment(\.dismiss) private var dismiss
    let exams: [Exam]
    @State private var eventStore = EKEventStore()
    @State private var selectedIDs = Set<Exam.ID>()
    @State private var selectedCalendar: EKCalendar?
    @State private var showCalendarChooser = false
    @State private var showPermissionDeniedAlert = false
    @State private var showExportError = false
    @State private var exportError: Error?

    private func presentCalendarChooser() async {
        do {
            selectedCalendar = nil
            let granted: Bool
            if #available(iOS 17, *) {
                granted = try await eventStore.requestWriteOnlyAccessToEvents()
            } else {
                granted = try await eventStore.requestAccess(to: .event)
            }
            showCalendarChooser = granted
            showPermissionDeniedAlert = !granted
        } catch {
            exportError = error
            showExportError = true
        }
    }

    private func exportToCalendar(_ calendar: EKCalendar) {
        do {
            for exam in exams where selectedIDs.contains(exam.id) {
                guard let interval = exam.calendarInterval else { continue }
                let event = EKEvent(eventStore: eventStore)
                event.title = exam.calendarTitle
                event.location = exam.location
                event.startDate = interval.start
                event.endDate = interval.end
                event.timeZone = TimeZone(identifier: "Asia/Shanghai")
                event.calendar = calendar
                try eventStore.save(event, span: .thisEvent, commit: false)
            }
            try eventStore.commit()
            dismiss()
        } catch {
            eventStore.reset()
            exportError = error
            showExportError = true
        }
    }

    var body: some View {
        NavigationStack {
            List(exams, selection: $selectedIDs) { exam in
                VStack(alignment: .leading) {
                    Text(exam.calendarTitle)
                    Text(verbatim: "\(exam.date)  \(exam.time)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .tag(exam.id)
            }
            .environment(\.editMode, .constant(.active))
            .navigationTitle(String(localized: "Export to Calendar", bundle: .module))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if selectedIDs.count == exams.count {
                        Button {
                            selectedIDs = []
                        } label: {
                            Text("Unselect All", bundle: .module)
                        }
                    } else {
                        Button {
                            selectedIDs = Set(exams.map(\.id))
                        } label: {
                            Text("Select All", bundle: .module)
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if selectedIDs.isEmpty {
                        Button {
                            dismiss()
                        } label: {
                            Text("Cancel", bundle: .module)
                        }
                    } else {
                        Button {
                            Task(priority: .userInitiated) {
                                await presentCalendarChooser()
                            }
                        } label: {
                            Text("Export", bundle: .module)
                        }
                    }
                }
            }
            .alert(String(localized: "Calendar Access not Granted", bundle: .module), isPresented: $showPermissionDeniedAlert) { }
            .alert(String(localized: "Error", bundle: .module), isPresented: $showExportError) { } message: {
                Text(verbatim: exportError?.localizedDescription ?? "")
            }
            .sheet(isPresented: $showCalendarChooser, onDismiss: {
                if let selectedCalendar {
                    exportToCalendar(selectedCalendar)
                    self.selectedCalendar = nil
                }
            }) {
                CalendarChooserSheet(selectedCalendar: $selectedCalendar, eventStore: eventStore)
                    .ignoresSafeArea()
            }
        }
    }
}
#endif

fileprivate struct ExamDetailSheet: View {
    @Environment(\.dismiss) private var dismiss

    let exam: Exam

    var body: some View {
        NavigationStack {
            List {
                HStack {
                    Text(exam.course)
                        .lineLimit(1)
                        .fontWeight(.bold)
                        .foregroundColor(exam.isFinished ? .secondary : .primary)
                    Spacer()
                    Text(exam.type)
                        .fontWeight(.bold)
                        .foregroundColor(exam.isFinished ? .secondary : .primary)
                }
                HStack {
                    Text("Exam Type", bundle: .module)
                    Spacer()
                    Text(exam.method)
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("Exam Date", bundle: .module)
                    Spacer()
                    Text(exam.date)
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("Exam Time", bundle: .module)
                    Spacer()
                    Text(exam.time)
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("Exam Location", bundle: .module)
                    Spacer()
                    Text(exam.location)
                        .foregroundColor(.secondary)
                }
            }
            .labelStyle(.titleOnly)
            #if !os(watchOS)
            .listStyle(.insetGrouped)
            #endif
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Done", bundle: .module)
                    }
                }
            }
            .navigationTitle(String(localized: "Exam Detail", bundle: .module))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
