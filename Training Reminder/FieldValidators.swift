//
//  FieldValidators.swift
//  Training Reminder
//
//  Created by Andy Vu on 9/7/23.
//

import Foundation
import Valid

struct PasswordValidator: Validator {
    var rules: ValidationRules<String> {
        
        DenyIfContainsInvalidCharacters(allowedCharacters: .letters.union(.decimalDigits).union(.punctuationCharacters))
            .message("Password can only have letters, numbers, and punctuation.")
        
        Property(\String.count) {
            DenyIfTooSmall(minimum: 8)
                .message("Password must be at least 8 characters long.")
            
            DenyIfTooBig(maximum: 16)
                .message("Password must be less than 16 characters long.")
        }
        
        DenyIfContainsTooFewCharactersFromSet(.decimalDigits, minimum: 1)
            .message("Password must have a number.")
        
        AlwaysAllow<String>()
    }
}

struct UsernameValidator: Validator {
    var rules: ValidationRules<String> {
        DenyIfContainsInvalidCharacters(allowedCharacters: .letters.union(.decimalDigits).union(.punctuationCharacters))
            .message("Username can only have letters, numbers, and punctuation.")
        
        Property(\String.count) {
            DenyIfTooSmall(minimum: 4)
                .message("Username must be at least 4 characters long.")
            
            DenyIfTooBig(maximum: 16)
                .message("Username must be less than 16 characters long.")
        }
        
        DenyIfContainsTooFewCharactersFromSet(.letters, minimum: 1)
            .message("Username must have a letter.")
        
        AlwaysAllow<String>()
    }
}

struct NameValidator: Validator {
    var rules: ValidationRules<String> {
        DenyIfContainsInvalidCharacters(allowedCharacters: .letters.union(.whitespaces))
            .message("Names can only have letters.")
        
        AlwaysAllow<String>()
    }
}



