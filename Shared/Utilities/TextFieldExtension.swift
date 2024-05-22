//
//  TextFieldExtension.swift
//  DanXi
//
//  Created by Kavin Zhao on 2024-03-28.
//

import PhotosUI
import SwiftUI
import ViewUtils

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
struct THTextEditor<Toolbar: View>: View {
    @Binding var text: String
    @Binding var selection: Range<String.Index>?
    let placeholder: String?
    let minHeight: CGFloat
    let uploadImageAction: (Data?) async throws -> Void
    @ViewBuilder let toolbar: () -> Toolbar
    @State private var height: CGFloat?
    
    var body: some View {
        THTextEditorUIView(textDidChange: textDidChange,
                           uploadImageAction: uploadImageAction,
                           text: $text,
                           selection: $selection,
                           toolbar: toolbar)
        .frame(height: height ?? minHeight)
        .overlay(alignment: .topLeading) {
            if let placeholder, text.isEmpty {
                Group {
                    if #available(iOS 17, *) {
                        Text(placeholder)
                            .foregroundStyle(.placeholder)
                    } else {
                        Text(placeholder)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 9)
                .padding(.leading, 6)
                .allowsHitTesting(false)
            }
        }
    }
    
    private func textDidChange(_ textView: UITextView) {
        height = max(textView.contentSize.height, minHeight)
        DispatchQueue.main.async { IQKeyboardManager.shared.reloadLayoutIfNeeded() }
    }
}

struct THTextEditorUIView<Toolbar: View>: UIViewRepresentable {
    typealias UIViewType = UITextView
    
    let textDidChange: (UITextView) -> Void
    let uploadImageAction: (Data?) async throws -> Void
    @Binding var text: String
    @Binding var selection: Range<String.Index>?
    @ViewBuilder let toolbar: () -> Toolbar
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(text: $text, selection: $selection, textDidChange: textDidChange)
    }
    
    class TextViewWithImagePasting: UITextView {
        let uploadImageAction: (Data?) async throws -> Void
        
        init(uploadImageAction: @escaping (Data?) async throws -> Void) {
            self.uploadImageAction = uploadImageAction
            super.init(frame: .zero, textContainer: nil)
        }
        
        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
            if action == #selector(paste(_:)) {
                return true
            }
            return super.canPerformAction(action, withSender: sender)
        }
        
        override func paste(_ sender: Any?) {
            if UIPasteboard.general.hasImages && !UIPasteboard.general.hasStrings && !UIPasteboard.general.hasURLs {
                if let image = UIPasteboard.general.image {
                    Task {
                        try await uploadImageAction(image.pngData())
                    }
                }
            } else {
                super.paste(sender)
            }
        }
    }
    
    func makeUIView(context: Context) -> UITextView {
        let textView = TextViewWithImagePasting(uploadImageAction: uploadImageAction)
        textView.isEditable = true
        textView.delegate = context.coordinator
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.backgroundColor = .clear
        textView.allowsEditingTextAttributes = false
        
        let toolbarHostingVC = UIHostingController(rootView: toolbar())
        toolbarHostingVC.sizingOptions = [.intrinsicContentSize]
        toolbarHostingVC.view.translatesAutoresizingMaskIntoConstraints = false
        toolbarHostingVC.view.backgroundColor = .tertiarySystemBackground
        textView.inputAccessoryView = toolbarHostingVC.view
        
        return textView
    }
    
    func updateUIView(_ textView: UITextView, context: Context) {
        textView.text = text
        if let selection,
           selection.lowerBound >= text.startIndex,
           selection.upperBound <= text.endIndex {
            textView.selectedRange = NSRange(selection, in: textView.text)
        }
        DispatchQueue.main.async {
            self.textDidChange(textView)
        }
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        @Binding var text: String
        @Binding var selection: Range<String.Index>?
        let textDidChange: (UITextView) -> Void
        
        init(text: Binding<String>, selection: Binding<Range<String.Index>?>, textDidChange: @escaping (UITextView) -> Void) {
            self._text = text
            self._selection = selection
            self.textDidChange = textDidChange
        }
        
        func textViewDidChange(_ textView: UITextView) {
            DispatchQueue.main.async { @MainActor [weak self] in
                self?.text = textView.text
                self?.textDidChange(textView)
            }
        }
        
        // customize the menu of textfield
        func textView(
            _ textView: UITextView,
            editMenuForTextIn range: NSRange,
            suggestedActions: [UIMenuElement]
        ) -> UIMenu? {
            return nil
            
            // todo I'll do this later
            
            //            guard range.length > 0 else { return nil }
            //
            //            var customActions: [UIMenuElement] = []
            //
            //            if range.length > 0, let textRange = Range(range, in: textView.text) {
            //                let boldAction = UIAction(title: "Bold") { _ in
            //                    let selectedText = textView.text[textRange]
            //                    let boldedText = "**\(selectedText)**"
            //
            //                    let replacedText = textView.text.replacingCharacters(in: textRange, with: boldedText)
            //
            //                    textView.text = replacedText
            //                    self.parent.text = replacedText
            //
            //                    let newCursorPosition = textView.position(from: textView.beginningOfDocument, offset: range.location + boldedText.count)
            //                    if let newCursorPosition = newCursorPosition {
            //                        textView.selectedTextRange = textView.textRange(from: newCursorPosition, to: newCursorPosition)
            //                    }
            //                }
            //
            //                let italicAction = UIAction(title: "Italic") { _ in
            //                    let selectedText = textView.text[textRange]
            //                    let italicText = "*\(selectedText)*"
            //
            //                    let replacedText = textView.text.replacingCharacters(in: textRange, with: italicText)
            //
            //                    textView.text = replacedText
            //                    self.parent.text = replacedText
            //
            //                    let newCursorPosition = textView.position(from: textView.beginningOfDocument, offset: range.location + italicText.count)
            //                    if let newCursorPosition = newCursorPosition {
            //                        textView.selectedTextRange = textView.textRange(from: newCursorPosition, to: newCursorPosition)
            //                    }
            //                }
            //
            //                customActions.append(boldAction)
            //                customActions.append(italicAction)
            //            }
            //
            //            return UIMenu(children: customActions + suggestedActions)
        }
        
        func textViewDidChangeSelection(_ textView: UITextView) {
            DispatchQueue.main.async { @MainActor [weak self] in
                self?.selection = Range(textView.selectedRange, in: textView.text)
            }
        }
    }
}
