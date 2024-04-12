//
//  TextFieldExtension.swift
//  DanXi
//
//  Created by Kavin Zhao on 2024-03-28.
//

import SwiftUI

/// This TextField is specifically designed for [THTagEditor]
struct BackspaceDetectingTextField: UIViewRepresentable {
    let placeholder: String
    @Binding var text: String
    let onBackPressed: (Bool) -> Void
    let onSubmit: () -> Void
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(text: $text, onBackPressed: onBackPressed, onSubmit: onSubmit)
    }
    
    func makeUIView(context: Context) -> CustomTextField {
        let textField = CustomTextField()
        textField.delegate = context.coordinator
        textField.onBackPressed = onBackPressed
        textField.placeholder = placeholder
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.spellCheckingType = .no
        textField.returnKeyType = .done
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textChange(textField:)), for: .editingChanged)
        return textField
    }
    
    func updateUIView(_ uiView: CustomTextField, context: Context) {
        uiView.text = text
        uiView.placeholder = placeholder
    }
    
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: CustomTextField, context: Context) -> CGSize? {
        guard
            let width = proposal.width,
            let height = proposal.height
        else { return nil }
        
        return CGSize(width: width, height: height)
    }
    
    class Coordinator: NSObject, UITextFieldDelegate {
        @Binding var text: String
        let onBackPressed: (Bool) -> Void
        let onSubmit: () -> Void
        
        init(text: Binding<String>, onBackPressed: @escaping (Bool) -> Void, onSubmit: @escaping () -> Void) {
            self._text = text
            self.onBackPressed = onBackPressed
            self.onSubmit = onSubmit
        }
        
        @objc func textChange(textField: UITextField) {
            DispatchQueue.main.async { @MainActor [weak self] in
                self?.text = textField.text ?? ""
            }
        }
        
        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            onSubmit()
            return false
        }
    }
    
    class CustomTextField: UITextField {
        open var onBackPressed: ((Bool) -> Void)?
        
        override func deleteBackward() {
            onBackPressed?(text?.isEmpty == true)
            super.deleteBackward()
        }
    }
}

/// This TextField is specifically designed as a Text Editor for Tree Hole
struct THTextEditor: View {
    @Binding var text: String
    let placeholder: String?
    let minHeight: CGFloat
    @State private var height: CGFloat?

    var body: some View {
        THTextEditorUIView(placeholder: placeholder ?? "", textDidChange: self.textDidChange, text: $text)
            .frame(height: height ?? minHeight)
    }

    private func textDidChange(_ textView: UITextView) {
        self.height = max(textView.contentSize.height, minHeight)
    }
}

struct THTextEditorUIView: UIViewRepresentable {
    typealias UIViewType = UITextView
    
    let placeholder: String
    let textDidChange: (UITextView) -> Void
    @Binding var text: String
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(text: $text, placeholder: placeholder, textDidChange: textDidChange)
    }
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = true
        textView.delegate = context.coordinator
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.backgroundColor = .clear
        return textView
    }
    
    func updateUIView(_ textView: UITextView, context: Context) {
        if text.isEmpty && !textView.isFirstResponder {
            textView.text = placeholder
            textView.textColor = .placeholderText
        } else {
            textView.text = text
            textView.textColor = .label
        }
        DispatchQueue.main.async {
            self.textDidChange(textView)
        }
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        @Binding var text: String
        let placeholder: String
        let textDidChange: (UITextView) -> Void
        
        init(text: Binding<String>, placeholder: String, textDidChange: @escaping (UITextView) -> Void) {
            self._text = text
            self.placeholder = placeholder
            self.textDidChange = textDidChange
        }
        
        func textViewDidChange(_ textView: UITextView) {
            DispatchQueue.main.async { @MainActor [weak self] in
                self?.text = textView.text
                self?.textDidChange(textView)
            }
        }

        func textViewDidBeginEditing(_ textView: UITextView) {
            // Remove placeholder text when the user starts editing
            if textView.textColor == .placeholderText {
                textView.text = nil
                textView.textColor = .label
            }
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            // Add placeholder text if the user ends editing with an empty field
            if textView.text.isEmpty {
                textView.text = placeholder
                textView.textColor = .placeholderText
            }
        }
    }
}
