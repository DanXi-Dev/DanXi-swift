import SwiftUI
import Combine
import ViewUtils
import DanXiKit

public struct QuestionSheet: View {
    public init() { }
    
    public var body: some View {
        AsyncContentView {
            try await GeneralAPI.getQuestions()
        } content: { questions in
            QuestionPage(questions)
        }
    }
}

private struct QuestionPage: View {
    @StateObject private var model: QuestionModel
    @State private var showSubmitAlert = false
    @State private var showIncorrectAlert = false
    @State private var scrollTarget: Question.ID?
    @Environment(\.dismiss) var dismiss
    
    init(_ questions: Questions) {
        let model = QuestionModel(questions)
        self._model = StateObject(wrappedValue: model)
    }
    
    var body: some View {
        NavigationStack {
            ScrollViewReader { scrollView in
                Form {
                    FormTitle(title: String(localized: "DanXi Qualification", bundle: .module),
                              description: AttributedString(localized: "DanXi Question Prompt", bundle: .module))
                        .useSafariController()
                    
                    ForEach(model.questions) { question in
                        Group {
                            switch question.type {
                            case .singleSelection, .trueOrFalse:
                                QuestionPicker(question: question)
                            case .multipleSelection:
                                MultiQuestionSelectior(question: question)
                            }
                        }
                        .id(question.id)
                    }
                    
                    submitButton
                }
                .onChange(of: scrollTarget) { target in
                    if let target {
                        withAnimation {
                            scrollView.scrollTo(target, anchor: .center)
                        }
                    }
                    scrollTarget = nil
                }
            }
            .alert(String(localized: "Unanswered Questions", bundle: .module), isPresented: $showSubmitAlert, actions: { }, message: {
                Text("Answer all questions before submit", bundle: .module)
            })
            .alert(String(localized: "Answer incorrect, please review and re-submit", bundle: .module), isPresented: $showIncorrectAlert, actions: { })
            .environmentObject(model)
            .navigationTitle(String(""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel", bundle: .module)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    AsyncButton {
                        try await submit()
                    } label: {
                        Text("Submit", bundle: .module)
                    }
                }
            }
        }
    }
    
    func submit() async throws {
        // Check answered
        if let firstUnanswered = model.allAnswered {
            scrollTarget = firstUnanswered
            try? await Task.sleep(for: .seconds(0.5))
            showSubmitAlert = true
            return
        }
        
        // All question has been answered
        let (correct, firstWrongId) = try await model.submit()
        if correct {
            dismiss()
        } else {
            if let firstWrongId {
                scrollTarget = firstWrongId
                try? await Task.sleep(for: .seconds(0.5))
            }
            showIncorrectAlert = true
        }
    }
    
    private var submitButton: some View {
        AsyncButton {
            try await submit()
        } label: {
            HStack {
                Spacer()
                Text("Submit", bundle: .module)
                    .bold()
                    .foregroundStyle(.white)
                Spacer()
            }
        }
        .listRowBackground(Color.accentColor)
    }
}

fileprivate struct QuestionLabel: View {
    @Environment(\.colorScheme) private var colorScheme
    let question: Question
    let incorrect: Bool
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Group {
                    switch question.type {
                    case .trueOrFalse: Text("True or False", bundle: .module)
                    case .singleSelection: Text("Single Selection", bundle: .module)
                    case .multipleSelection: Text("Multiple Selection", bundle: .module)
                    }
                }
                .padding(EdgeInsets(top: 3, leading: 10, bottom: 3, trailing: 10))
                .background(.accentColor.opacity(colorScheme == .light ? 0.1 : 0.2))
                .cornerRadius(5)
                .foregroundColor(.accentColor)
            }
            .font(.footnote)
            
            Text(question.question)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundColor(incorrect ? .red : .primary)
                .font(.headline)
                .bold()
                .textCase(.none)
        }
    }
}

private struct QuestionPicker: View {
    @EnvironmentObject private var model: QuestionModel
    @State private var answer = ""
    @State private var incorrect = false
    let question: Question
    
    var body: some View {
        Picker(selection: $answer, label: QuestionLabel(question: question, incorrect: incorrect)) {
            ForEach(Array(question.options.enumerated()), id: \.offset) { _, option in
                Text(option).tag(option)
            }
        }
        .pickerStyle(.inline)
        // sync change to model
        .onChange(of: answer) { answer in
            incorrect = false // reset when edit
            model.answers[question.id] = [answer]
        }
        // set label title to red when receive wrongIds
        .onReceive(model.wrongQuestionPublisher) { wrongIds in
            incorrect = wrongIds.contains(where: { $0 == question.id })
        }
    }
}

private struct MultiQuestionSelectior: View {
    @EnvironmentObject private var model: QuestionModel
    @State private var answer: [String : Bool]
    @State private var incorrect = false
    let question: Question
    
    init(question: Question) {
        var answer: [String : Bool] = [:]
        for option in question.options {
            answer[option] = false
        }
        self._answer = State(initialValue: answer)
        self.question = question
    }
    
    var body: some View {
        Section {
            ForEach(Array(question.options.enumerated()), id: \.offset) { _, option in
                Button {
                    answer[option] = !(answer[option]!) // force unwrap and inverse
                } label: {
                    HStack {
                        Text(option)
                            .foregroundColor(.primary)
                        Spacer()
                        // the map in set in initializer, and the question is constant, so force unwrap can't crash
                        if answer[option]! {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
        } header: {
            QuestionLabel(question: question, incorrect: incorrect)
        }
        // sync change to model
        .onChange(of: answer) { answer in
            incorrect = false // reset on edit
            
            var answerList: [String] = []
            for (option, selected) in answer {
                if selected {
                    answerList.append(option)
                }
            }
            model.answers[question.id] = answerList
        }
        // set label title to red when receive wrongIds
        .onReceive(model.wrongQuestionPublisher) { wrongIds in
            incorrect = wrongIds.contains(where: { $0 == question.id })
        }
    }
}


@MainActor
private class QuestionModel: ObservableObject {
    let version: Int
    @Published var questions: [Question]
    @Published var answers: [Int : [String]]
    let wrongQuestionPublisher = PassthroughSubject<[Int], Never>()
    
    init(_ questions: Questions) {
        self.version = questions.version
        self.questions = questions.questions
        var answers: [Int : [String]] = [:]
        for question in questions.questions {
            answers[question.id] = []
        }
        self.answers = answers
    }
    
    /// Returns nil on success, first unanswered question id on fail.
    var allAnswered: Int? {
        for q in questions {
            if answers[q.id]?.isEmpty == true {
                return q.id
            }
        }
        return nil
    }
    
    func submit() async throws -> (Bool, Int?) {
        let response = try await GeneralAPI.submitQuestions(answers: answers, version: version)
        switch response {
        case .success(let token):
            await CommunityModel.shared.setToken(token: token)
            try await ProfileStore.shared.refreshProfile()
            return (true, nil)
        case .fail(let wrongIds):
            wrongQuestionPublisher.send(wrongIds)
            return (false, wrongIds.first)
        }
    }
}

#Preview {
    let questions: Questions = decodePreviewData(filename: "questions")
    
    QuestionPage(questions)
}
