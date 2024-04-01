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
            return true
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
