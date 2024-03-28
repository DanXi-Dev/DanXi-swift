//
//  TextFieldExtension.swift
//  DanXi
//
//  Created by Kavin Zhao on 2024-03-28.
//

import SwiftUI

/// This TextField is specifically designed for [THTagEditor]
public struct BackspaceDetectingTextField: UIViewRepresentable {
    let placeholder: String
    @Binding var text: String
    let onBackspace: (Bool) -> Void
    let onSubmit: () -> Void
    
    public func makeCoordinator() -> BackspaceDetectingTextFieldCoordinator {
        BackspaceDetectingTextFieldCoordinator(textBinding: $text, onSubmit: onSubmit)
    }
    
    public func makeUIView(context: Context) -> BackspaceDetectingUITextField {
        let view = BackspaceDetectingUITextField()
        view.placeholder = placeholder
        view.delegate = context.coordinator
        view.autocorrectionType = .no
        view.autocapitalizationType = .none
        view.spellCheckingType = .no
        view.returnKeyType = .done
        view.onBackspace = onBackspace
        return view
    }
    
    public func updateUIView(_ uiView: BackspaceDetectingUITextField, context: Context) {
        uiView.text = text
    }
    
    public class BackspaceDetectingUITextField: UITextField {
        var onBackspace: ((Bool) -> Void)?
        
        override init(frame: CGRect) {
            onBackspace = nil
            super.init(frame: frame)
        }
        
        required init?(coder: NSCoder) {
            print("Unsupported method called in BackspaceDetectingTextField")
            fatalError()
        }
        
        override public func deleteBackward() {
            onBackspace?(text?.isEmpty == true)
            super.deleteBackward()
        }
    }
}

public class BackspaceDetectingTextFieldCoordinator: NSObject {
    let textBinding: Binding<String>
    let onSubmit: () -> Void
    
    init(textBinding: Binding<String>, onSubmit: @escaping () -> Void) {
        self.textBinding = textBinding
        self.onSubmit = onSubmit
    }
}

extension BackspaceDetectingTextFieldCoordinator: UITextFieldDelegate {
    public func textField(_ textField: UITextField,
                          shouldChangeCharactersIn range: NSRange,
                          replacementString string: String) -> Bool {
        let currentText = textField.text ?? ""
        let replacementText = (currentText as NSString).replacingCharacters(in: range, with: string)
        DispatchQueue.main.async {
            self.textBinding.wrappedValue = replacementText
        }
        return true
    }
    
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
//        textField.resignFirstResponder()
        DispatchQueue.main.async {
            self.onSubmit()
        }
        return true
    }
}
