//
//  CustomTextField.swift
//  Training Reminder
//
//  Created by Andy Vu on 9/7/23.
//

import SwiftUI

struct CustomTextField: View {
    var placeholder: Text
    @Binding var text: String
    var editingChange: (Bool) -> () = { _ in}
    var commit: () -> () = {}
    var isSecure: Bool
        
    var body: some View {
        ZStack(alignment: .leading) {
            if text.isEmpty { placeholder }
            if isSecure {
                SecureField("", text: $text, onCommit: commit)
                    .foregroundColor(.black)
                    .submitLabel(.done)
            }
            else {
                TextField("", text: $text, onEditingChanged: editingChange, onCommit: commit)
                    .foregroundColor(.black)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
            }
        }
    }
    
}

