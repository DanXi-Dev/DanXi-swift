import SwiftUI
import Combine

struct DXQuestionSheet: View {
    var body: some View {
        AsyncContentView {
            return try await DXRequests.retrieveQuestions()
        } content: { questions in
            QuestionPage(questions)
        }
    }
}

fileprivate struct QuestionPage: View {
    @StateObject private var model: QuestionModel
    @State private var showSubmitAlert = false
    @State private var showIncorrectAlert = false
    @Environment(\.dismiss) var dismiss
    
    init(_ questions: DXQuestions) {
        let model = QuestionModel(questions)
        self._model = StateObject(wrappedValue: model)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                FormTitle(title: "DanXi Qualification",
                          description: "DanXi Question Prompt")
                                
                ForEach(model.questions) { question in
                    switch question.type {
                    case .singleSelection, .trueOrFalse:
                        QuestionPicker(question: question)
                    case .multipleSelection:
                        MultiQuestionSelectior(question: question)
                    }
                }
                
                submitButton
            }
            .alert("Unanswered Questions", isPresented: $showSubmitAlert, actions: { }, message: {
                Text("Answer all questions before submit")
            })
            .alert("Answer incorrect, please review and re-submit", isPresented: $showIncorrectAlert, actions: { })
            .headerProminence(.increased)
            .environmentObject(model)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                    }
                }
            }
        }
    }
    
    private var submitButton: some View {
        AsyncButton {
            if model.allAnswered {
                let correct = try await model.submit()
                if correct {
                    dismiss()
                } else {
                    showIncorrectAlert = true
                }
            } else {
                showSubmitAlert = true
            }
        } label: {
            HStack {
                Spacer()
                Text("Submit")
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
    let question: DXQuestion
    let incorrect: Bool
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Group {
                    switch question.type {
                    case .trueOrFalse: Text("True or False")
                    case .singleSelection: Text("Single Selection")
                    case .multipleSelection: Text("Multiple Selection")
                    }
                    
                    switch question.group {
                    case .required: Text("Question.Required")
                    case .optional: Text("Question.Optional")
                    }
                }
                .padding(EdgeInsets(top: 3, leading: 10, bottom: 3, trailing: 10))
                .background(.accentColor.opacity(colorScheme == .light ? 0.1 : 0.2))
                .cornerRadius(5)
                .foregroundColor(.accentColor)
            }
            .font(.footnote)
            
            Text(question.question)
                .foregroundColor(incorrect ? .red : .primary)
        }
    }
}

fileprivate struct QuestionPicker: View {
    @EnvironmentObject private var model: QuestionModel
    @State private var answer = ""
    @State private var incorrect = false
    let question: DXQuestion
    
    var body: some View {
        Picker(selection: $answer, label: QuestionLabel(question: question, incorrect: incorrect)) {
            ForEach(Array(question.option.enumerated()), id: \.offset) { _, option in
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

fileprivate struct MultiQuestionSelectior: View {
    @EnvironmentObject private var model: QuestionModel
    @State private var answer: [String : Bool]
    @State private var incorrect = false
    let question: DXQuestion
    
    init(question: DXQuestion) {
        var answer: [String : Bool] = [:]
        for option in question.option {
            answer[option] = false
        }
        self._answer = State(initialValue: answer)
        self.question = question
    }
    
    var body: some View {
        Section {
            ForEach(Array(question.option.enumerated()), id: \.offset) { _, option in
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
fileprivate class QuestionModel: ObservableObject {
    let version: Int
    @Published var questions: [DXQuestion]
    @Published var answers: [Int : [String]]
    let wrongQuestionPublisher = PassthroughSubject<[Int], Never>()
    
    init(_ questions: DXQuestions) {
        self.version = questions.version
        self.questions = questions.questions
        var answers: [Int : [String]] = [:]
        for question in questions.questions {
            answers[question.id] = []
        }
        self.answers = answers
    }
    
    var allAnswered: Bool {
        for (_, answer) in answers {
            if answer.isEmpty {
                return false
            }
        }
        return true
    }
    
    func submit() async throws -> Bool {
        let (correct, token, wrongIds) = try await DXRequests.submitQuestions(answers: answers, version: version)
        if correct {
            DXModel.shared.token = token // reset token
            do {
                // user info reload must be performed after the token update, since backend may retrieve this info from token, not DB
                _ = try await DXModel.shared.loadUser()
            } catch {
                DXModel.shared.user?.answered = true // update user info when load fails, since questions can be only submitted once
            }
        } else {
            wrongQuestionPublisher.send(wrongIds)
        }
        return correct
    }
}
