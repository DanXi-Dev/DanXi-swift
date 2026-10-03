import FudanKit
import SwiftUI
import ViewUtils

private enum LibraryAccountText {
    static func date(_ value: String?) -> String? {
        guard let value, !value.isEmpty else { return nil }
        return String(value.prefix(10))
    }
}

struct LibraryLoansPage: View {
    private enum Range: String, CaseIterable {
        case current, history
    }

    private let pageSize = 20

    @State private var range: Range = .current
    @State private var refreshID = 0
    @State private var pendingRenewal: LibraryCurrentLoan?
    @State private var renewingID: String?
    @State private var operationError: String?

    var body: some View {
        VStack(spacing: 0) {
            Picker(String(localized: "Loan Period", bundle: .module), selection: $range) {
                Text("Current", bundle: .module).tag(Range.current)
                Text("History", bundle: .module).tag(Range.history)
            }
            .pickerStyle(.segmented)
            .padding()

            List {
                if range == .current {
                    AsyncCollection { (loans: [LibraryCurrentLoan]) in
                        if !loans.isEmpty && !loans.count.isMultiple(of: pageSize) { return [] }
                        let page = loans.count / pageSize + 1
                        let result = try await LibraryAccountAPI.getCurrentLoans(page: page, pageSize: pageSize)
                        return result.items
                    } content: { loan in
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(loan.title)
                                    .font(.headline)
                                if let dueDate = LibraryAccountText.date(loan.dueDate) {
                                    Text(String(format: String(localized: "Due %@", bundle: .module), dueDate))
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                Text(String(format: String(localized: "Renewed %lld times", bundle: .module), loan.renewalCount))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            if renewingID == loan.id {
                                ProgressView()
                            } else {
                                Button(String(localized: "Renew", bundle: .module)) {
                                    pendingRenewal = loan
                                }
                                .buttonStyle(.borderedProminent)
                                .buttonBorderShape(.capsule)
                                .disabled(renewingID != nil || (loan.renewalLimit.map { loan.renewalCount >= $0 } ?? false))
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .id(refreshID)
                } else {
                    AsyncCollection { (loans: [LibraryLoanHistoryItem]) in
                        if !loans.isEmpty && !loans.count.isMultiple(of: pageSize) { return [] }
                        let page = loans.count / pageSize + 1
                        let result = try await LibraryAccountAPI.getLoanHistory(page: page, pageSize: pageSize)
                        return result.items
                    } content: { loan in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(loan.title).font(.headline)
                            if let author = loan.author, !author.isEmpty {
                                Text(author).font(.subheadline).foregroundStyle(.secondary)
                            }
                            if let loanDate = LibraryAccountText.date(loan.loanDate) {
                                Text(String(format: String(localized: "Borrowed %@", bundle: .module), loanDate))
                                    .font(.subheadline).foregroundStyle(.secondary)
                            }
                            if let returnDate = LibraryAccountText.date(loan.returnDate) {
                                Text(String(format: String(localized: "Returned %@", bundle: .module), returnDate))
                                    .font(.subheadline).foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            #if !os(watchOS)
            .listStyle(.insetGrouped)
            #endif
        }
        .navigationTitle(String(localized: "My Loans", bundle: .module))
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            String(localized: "Renew this loan?", bundle: .module),
            isPresented: Binding(
                get: { pendingRenewal != nil },
                set: { if !$0 { pendingRenewal = nil } }
            )
        ) {
            Button(String(localized: "Renew", bundle: .module)) {
                guard let loan = pendingRenewal else { return }
                pendingRenewal = nil
                Task { await renew(loan) }
            }
        } message: {
            Text(pendingRenewal?.title ?? "")
        }
        .alert(String(localized: "Library Action Failed", bundle: .module), isPresented: Binding(
            get: { operationError != nil },
            set: { if !$0 { operationError = nil } }
        )) {
            Button(String(localized: "OK", bundle: .module)) { operationError = nil }
        } message: {
            Text(operationError ?? "")
        }
    }

    private func renew(_ loan: LibraryCurrentLoan) async {
        renewingID = loan.id
        defer { renewingID = nil }
        do {
            try await LibraryAccountAPI.renewLoan(loan)
            refreshID += 1
        } catch {
            operationError = error.localizedDescription
        }
    }
}

struct LibraryRequestsPage: View {
    private let pageSize = 20

    @State private var range: LibraryRequestRange = .current
    @State private var refreshID = 0
    @State private var pendingCancellation: LibraryBookRequest?
    @State private var cancellingID: Int?
    @State private var operationError: String?

    var body: some View {
        VStack(spacing: 0) {
            Picker(String(localized: "Request Period", bundle: .module), selection: $range) {
                Text("Current", bundle: .module).tag(LibraryRequestRange.current)
                Text("History", bundle: .module).tag(LibraryRequestRange.history)
            }
            .pickerStyle(.segmented)
            .padding()

            List {
                AsyncCollection { (requests: [LibraryBookRequest]) in
                    if !requests.isEmpty && !requests.count.isMultiple(of: pageSize) { return [] }
                    let page = requests.count / pageSize + 1
                    let result = try await LibraryAccountAPI.getRequests(
                        range: range,
                        page: page,
                        pageSize: pageSize
                    )
                    return result.items
                } content: { request in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(request.title).font(.headline)
                            Spacer()
                            if cancellingID == request.id {
                                ProgressView()
                            }
                            Text(request.status).font(.subheadline).foregroundStyle(.secondary)
                        }
                        if let pickup = request.pickupName, !pickup.isEmpty {
                            Label(pickup, systemImage: "mappin")
                                .font(.subheadline).foregroundStyle(.secondary)
                        }
                        if range == .current, let position = request.queuePosition, position > 0 {
                            Text(String(format: String(localized: "Queue position %lld", bundle: .module), position))
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        if range == .current {
                            Button(String(localized: "Cancel Request", bundle: .module), role: .destructive) {
                                pendingCancellation = request
                            }
                            .disabled(cancellingID != nil)
                        }
                    }
                }
                .id("\(range.rawValue)-\(refreshID)")
            }
            #if !os(watchOS)
            .listStyle(.insetGrouped)
            #endif
        }
        .navigationTitle(String(localized: "My Requests", bundle: .module))
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            String(localized: "Cancel this request?", bundle: .module),
            isPresented: Binding(
                get: { pendingCancellation != nil },
                set: { if !$0 { pendingCancellation = nil } }
            )
        ) {
            Button(String(localized: "Cancel Request", bundle: .module), role: .destructive) {
                guard let request = pendingCancellation else { return }
                pendingCancellation = nil
                Task { await cancel(request) }
            }
        } message: {
            Text(pendingCancellation?.title ?? "")
        }
        .alert(String(localized: "Library Action Failed", bundle: .module), isPresented: Binding(
            get: { operationError != nil },
            set: { if !$0 { operationError = nil } }
        )) {
            Button(String(localized: "OK", bundle: .module)) { operationError = nil }
        } message: {
            Text(operationError ?? "")
        }
    }

    private func cancel(_ request: LibraryBookRequest) async {
        cancellingID = request.id
        defer { cancellingID = nil }
        do {
            try await LibraryAccountAPI.cancelRequest(id: request.id)
            refreshID += 1
        } catch {
            operationError = error.localizedDescription
        }
    }
}
