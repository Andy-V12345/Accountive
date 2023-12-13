//
//  SignInView.swift
//  Training Reminder
//
//  Created by Andy Vu on 9/6/23.
//

import SwiftUI
import Valid
import PopupView
import AlertToast
import FirebaseAuth
import FirebaseFirestore
import Combine

class TextInputVM: ObservableObject {
    @Published var text: String = ""
}


// MARK: SIGN IN CONTAINER

struct SignInView: View {
    
    // MARK: PROPERTIES
    
    @State var email = ""
    @State var password = ""
    @State var username = ""
    @State var isError = false
    @State var errorMsg = ""
    @State var isLogIn = true
    @State var isForgetPassword = false
    
    @State var signUpStage = 0
    
    @State var isLoading = false
    
    
    @StateObject var emailObject = TextInputVM()
    @State var emailError = false
    @State var isEmailLoading = false
    @State var emailErrorMsg = ""
    @State var isEmailValid = false
    @FocusState var isEmailFocused
    
    @StateObject var usernameObject = TextInputVM()
    @State var usernameError = false
    @State var isUsernameLoading = false
    @State var usernameErrorMsg = ""
    @State var isUsernameValid = false
    @FocusState var isUsernameFocused
    
    @StateObject var passwordObject = TextInputVM()
    @State var passwordError = false
    @State var isPasswordLoading = false
    @State var passwordErrorMsg = ""
    @State var isPasswordValid = false
    @FocusState var isPasswordFocused
    
    @StateObject var nameObject = TextInputVM()
    @State var nameError = false
    @State var isNameLoading = false
    @State var nameErrorMsg = ""
    @State var isNameValid = false
    @FocusState var isNameFocused
    
    @State var isSmallScreen = false
    
    
    
    @EnvironmentObject private var authState: AuthState
    
    @Namespace var namespace
    
    let firebaseService = FirebaseService()
    let db = Firestore.firestore()
    
    // MARK: VALIDATE NAME
    func validateName(name: String) async -> String {
        let nameValidator = NameValidator()
        let validation = await nameValidator.validate(input: name)
        
        let errors = validation.all.errors
        
        
        if errors.isEmpty && name.trimmingCharacters(in: .whitespacesAndNewlines) != "" {
            return ""
        }
        else {
            return errors[0].message
        }
    }
    
    // MARK: VALIDATE EMAIL
    
    func validateEmail(email: String) -> Bool {
        if email.count > 100 {
            return false
        }
        let emailFormat = "(?:[\\p{L}0-9!#$%\\&'*+/=?\\^_`{|}~-]+(?:\\.[\\p{L}0-9!#$%\\&'*+/=?\\^_`{|}" + "~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\" + "x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[\\p{L}0-9](?:[a-" + "z0-9-]*[\\p{L}0-9])?\\.)+[\\p{L}0-9](?:[\\p{L}0-9-]*[\\p{L}0-9])?|\\[(?:(?:25[0-5" + "]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-" + "9][0-9]?|[\\p{L}0-9-]*[\\p{L}0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21" + "-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])"
        //        let emailFormat = ""
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailFormat)
        return emailPredicate.evaluate(with: email)
    }
    
    // MARK: VALIDATES PASSWORD
    
    func validatePassword(password: String) async -> String {
        let passwordValidator = PasswordValidator()
        
        let validation = await passwordValidator.validate(input: password)
        
        let errors = validation.all.errors
        
        if errors.isEmpty {
            return ""
        }
        else {
            return errors[0].message
        }
    }
    
    // MARK: VALIDATES USERNAME
    
    func validateUsername(username: String) async -> String {
        let usernameValidator = UsernameValidator()
        
        let validation = await usernameValidator.validate(input: username)
        
        let errors = validation.all.errors
        
        if errors.isEmpty {
            return ""
        }
        else {
            return errors[0].message
        }
    }
    
    
    
    // MARK: CHECK IF USERNAME IS TAKEN
    
    private func isUsernameTaken(input: String) async -> Bool {
        let usernameRef = db.collection("usernames")
        
        do {
            let querySnapshot = try await usernameRef.whereField("username", isEqualTo: input).getDocuments()
            if querySnapshot.documents.count > 0 {
                return true
            }
            else {
                return false
            }
        }
        catch {
            return true
        }
        
    }
    
    // MARK: LOG IN FUNCTION
    
    func logIn() async {
        do {
            isLoading = true
            try await authState.logIn(email: email, password: password)
            firebaseService.updateFcmToken(uid: authState.user!.uid, newFcmToken: UserDefaults.standard.string(forKey: "fcmKey")!)
            let daysToSubscribe = try await firebaseService.getSubscriptions(uid: authState.user!.uid)
            try await firebaseService.subscribeToTopic(fcmToken: UserDefaults.standard.string(forKey: "fcmKey")!, days: daysToSubscribe)
            authState.setUsername(username: try await firebaseService.getUsername(uid: authState.user!.uid))
            isLoading = false
        }
        catch {
            isLoading = false
            errorMsg = "Invalid email/password"
            isError = true
        }
    }
    
    func signUp() async {
        do {
            isLoading = true
            authState.doneAuth = false
            authState.setUsername(username: usernameObject.text)
            try await authState.signUp(email: emailObject.text, password: passwordObject.text, name: nameObject.text.trimmingCharacters(in: .whitespacesAndNewlines))
            firebaseService.addUser(email: emailObject.text, username: usernameObject.text, uid: authState.user!.uid, fcmToken: UserDefaults.standard.string(forKey: "fcmKey")!, name: nameObject.text)
            authState.doneAuth = true
            isLoading = false
        }
        catch {
            errorMsg = "Error saving account"
            isError = true
        }
    }
    
    // MARK: BODY FOR SIGN IN CONTAINER
    
    var body: some View {
        GeometryReader { screen in
            ZStack {
                Color.white.ignoresSafeArea()
                
                if isLoading {
                    VStack {
                        Spacer()
                        ProgressView()
                            .tint(Color(hex: "A6AEF0"))
                            .frame(width: 300)
                            .controlSize(.large)
                        Spacer()
                    }
                }
                
                VStack(spacing: 20) {
                    
                    if isLogIn {
                        Spacer()
                    }
                    
                    
                    Text("ACCOUNTIVE")
                        .gradientForeground(colors: [Color(hex: "b597f6"), Color(hex: "96c6ea")], startPoint: .bottomLeading, endPoint: .topTrailing)
                        .font(.system(size: 40))
                        .fontWidth(.condensed)
                        .bold()
                    
                    ZStack {
                        if isLogIn {
                            LogIn
                        }
                        else {
                            SignUp
                        }
                    }
                    
                    Spacer()
                    
                    if isLogIn {
                        Image("med")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    }
                    
                }
                .padding(.top, isLogIn ? 0 : 50)
                .toast(isPresenting: $isError, duration: 3, alert: {
                    AlertToast(displayMode: .hud, type: .error(Color(hex: "ff5858")), subTitle: errorMsg)
                })
                .sheet(isPresented: $isForgetPassword, content: {
                    ForgotPasswordView()
                })
                .opacity(isLoading ? 0.3 : 1)
                .disabled(isLoading)
                .animation(.linear(duration: 0.2), value: isLoading)
                
            }
            .onTapGesture {
                hideKeyboard()
            }
            .edgesIgnoringSafeArea([.bottom, .leading, .trailing])
            .onAppear {
                if screen.size.height < 844 {
                    isSmallScreen = true
                }
            }
        }
        .ignoresSafeArea(.keyboard)
    }
    
    // MARK: SIGNUP SCREEN
    
    var SignUp: some View {
        VStack(spacing: isSmallScreen ? 35 : 60) {
            VStack(spacing: isSmallScreen ? 15 : 20) {
                
                // Name textfield
                VStack {
                    HStack(spacing: 20) {
                        Image(systemName: "signature")
                            .foregroundColor(.gray)
                        CustomTextField(placeholder: Text("Your name").foregroundColor(.gray).font(isSmallScreen ? .subheadline : .body), text: $nameObject.text, isSecure: false)
                            .onReceive(nameObject.$text.debounce(for: .seconds(0.8), scheduler: DispatchQueue.main))
                        {
                            guard $0 != "" else { return }
                            
                            if signUpStage == 0 {
                                Task {
                                    isNameLoading = true
                                    
                                    let res = await validateName(name: nameObject.text)
                                    
                                    if res != "" {
                                        withAnimation(.spring(dampingFraction: 0.95)) {
                                            nameErrorMsg = res
                                            nameError = true
                                            isNameValid = false
                                        }
                                    }
                                    else {
                                        withAnimation(.spring(dampingFraction: 0.95)) {
                                            nameError = false
                                            nameErrorMsg = ""
                                            isNameValid = true
                                        }
                                    }
                                    isNameLoading = false
                                }
                                
                            }
                            
                        }
                        .onSubmit {
                            if isNameValid {
                                if signUpStage < 3 {
                                    
                                    if signUpStage == 0 {
                                        isNameFocused = false
                                    }
                                    else if signUpStage == 1 {
                                        isEmailFocused = false
                                    }
                                    else if signUpStage == 2 {
                                        isUsernameFocused = false
                                    }
                                    else {
                                        isNameFocused = false
                                        isEmailFocused = false
                                        isUsernameFocused = false
                                        isPasswordFocused = false
                                    }
                                    
                                    withAnimation(.spring(dampingFraction: 0.95)) {
                                        signUpStage += 1
                                    }
                                    
                                }
                                else {
                                    // TODO: NEW SIGNUP
                                    
                                    Task {
                                        await signUp()
                                        signUpStage = 0
                                    }
                                    
                                }
                            }
                        }
                        .frame(height: isSmallScreen ? 35 : 50)
                        .font(isSmallScreen ? .subheadline : .body)
                        .onTapGesture {
                            withAnimation(.spring(dampingFraction: 0.95)) {
                                signUpStage = 0
                                
                                emailError = false
                                emailErrorMsg = ""
                                
                                usernameError = false
                                usernameErrorMsg = ""
                                
                                passwordError = false
                                passwordErrorMsg = ""
                            }
                            isNameFocused = true
                        }
                        .focused($isNameFocused)
                        
                        if !isNameLoading {
                            if isNameValid {
                                Image(systemName: "checkmark.circle")
                                    .foregroundColor(.green)
                                    .font(isSmallScreen ? .subheadline : .body)
                            }
                            else {
                                Image(systemName: "xmark.circle")
                                    .foregroundColor(nameError == true ? .red : .gray.opacity(0.4))
                                    .font(isSmallScreen ? .subheadline : .body)
                            }
                        }
                        else {
                            ProgressView()
                                .controlSize(.small)
                                .tint(Color(hex: "A6AEF0"))
                        }
                        
                    }
                    .overlay(
                        Divider()
                            .padding(.vertical, 0)
                            .frame(maxWidth: .infinity, maxHeight:1)
                            .background(LinearGradient(colors: [Color(hex: "b597f6"), Color(hex: "96c6ea")], startPoint: .leading, endPoint: .trailing)), alignment: .bottom)
                    
                    Text(nameErrorMsg)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.caption2)
                        .foregroundColor(.red)
                        .opacity(nameError ? 1 : 0)
                    
                }
                
                if signUpStage > 0 {
                    
                    // Email textfield
                    VStack {
                        
                        HStack(spacing: 20) {
                            Image(systemName: "envelope")
                                .foregroundColor(.gray)
                            CustomTextField(placeholder: Text("Email").foregroundColor(.gray).font(isSmallScreen ? .subheadline : .body), text: $emailObject.text, isSecure: false)
                                .onDisappear {
                                    isEmailFocused = false
                                }
                                .onAppear {
                                    isEmailFocused = true
                                }
                                .onSubmit {
                                    if isEmailValid {
                                        if signUpStage < 3 {
                                            
                                            if signUpStage == 0 {
                                                isNameFocused = false
                                            }
                                            else if signUpStage == 1 {
                                                isEmailFocused = false
                                            }
                                            else if signUpStage == 2 {
                                                isUsernameFocused = false
                                            }
                                            else {
                                                isNameFocused = false
                                                isEmailFocused = false
                                                isUsernameFocused = false
                                                isPasswordFocused = false
                                            }
                                            
                                            withAnimation(.spring(dampingFraction: 0.95)) {
                                                signUpStage += 1
                                            }
                                            
                                        }
                                        else {
                                            // TODO: NEW SIGNUP
                                            
                                            Task {
                                                await signUp()
                                                signUpStage = 0
                                            }
                                            
                                        }
                                    }
                                }
                                .onReceive(emailObject.$text.debounce(for: .seconds(0.8), scheduler: DispatchQueue.main))
                            {
                                guard $0 != "" else { return }
                                
                                if signUpStage == 1 {
                                    Task {
                                        if validateEmail(email: emailObject.text) {
                                            isEmailLoading = true
                                            do {
                                                if try await authState.isEmailTaken(email: emailObject.text) {
                                                    withAnimation(.spring(dampingFraction: 0.95)) {
                                                        emailErrorMsg = "Email is taken."
                                                        emailError = true
                                                        isEmailValid = false
                                                    }
                                                }
                                                else {
                                                    withAnimation(.spring(dampingFraction: 0.95)) {
                                                        emailError = false
                                                        emailErrorMsg = ""
                                                        isEmailValid = true
                                                    }
                                                }
                                                isEmailLoading = false
                                            }
                                        }
                                        else {
                                            withAnimation(.spring(dampingFraction: 0.95)) {
                                                emailErrorMsg = "Invalid email."
                                                emailError = true
                                                isEmailValid = false
                                            }
                                        }
                                    }
                                    
                                }
                                
                            }
                            .disabled(signUpStage < 1)
                            .font(isSmallScreen ? .subheadline : .body)
                            .frame(height: isSmallScreen ? 35 : 50)
                            .onTapGesture {
                                withAnimation(.spring(dampingFraction: 0.95)) {
                                    signUpStage = 1
                                    
                                    usernameError = false
                                    usernameErrorMsg = ""
                                    
                                    passwordError = false
                                    passwordErrorMsg = ""
                                }
                                isEmailFocused = true
                            }
                            .focused($isEmailFocused)
                            
                            if !isEmailLoading {
                                if isEmailValid {
                                    Image(systemName: "checkmark.circle")
                                        .foregroundColor(.green)
                                        .font(isSmallScreen ? .subheadline : .body)
                                }
                                else {
                                    Image(systemName: "xmark.circle")
                                        .foregroundColor(emailError == true ? .red : .gray.opacity(0.4))
                                        .font(isSmallScreen ? .subheadline : .body)
                                }
                            }
                            else {
                                ProgressView()
                                    .controlSize(.small)
                                    .tint(Color(hex: "A6AEF0"))
                            }
                            
                        }
                        .overlay(
                            Divider()
                                .padding(.vertical, 0)
                                .frame(maxWidth: .infinity, maxHeight:1)
                                .background(LinearGradient(colors: [Color(hex: "b597f6"), Color(hex: "96c6ea")], startPoint: .leading, endPoint: .trailing)), alignment: .bottom)
                        
                        Text(emailErrorMsg)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .font(.caption2)
                            .foregroundColor(.red)
                            .opacity(emailError ? 1 : 0)
                        
                    }
                }
                
                // Username textfield
                
                if signUpStage > 1 {
                    
                    VStack {
                        HStack(spacing: 20) {
                            Image(systemName: "person")
                                .foregroundColor(.gray)
                            CustomTextField(placeholder: Text("Username").foregroundColor(.gray).font(isSmallScreen ? .subheadline : .body), text: $usernameObject.text, isSecure: false)
                                .frame(height: isSmallScreen ? 35 : 50)
                                .disabled(signUpStage < 2)
                                .focused($isUsernameFocused)
                                .font(isSmallScreen ? .subheadline : .body)
                                .onSubmit {
                                    if isUsernameValid {
                                        if signUpStage < 3 {
                                            
                                            if signUpStage == 0 {
                                                isNameFocused = false
                                            }
                                            else if signUpStage == 1 {
                                                isEmailFocused = false
                                            }
                                            else if signUpStage == 2 {
                                                isUsernameFocused = false
                                            }
                                            else {
                                                isNameFocused = false
                                                isEmailFocused = false
                                                isUsernameFocused = false
                                                isPasswordFocused = false
                                            }
                                            
                                            withAnimation(.spring(dampingFraction: 0.95)) {
                                                signUpStage += 1
                                            }
                                            
                                        }
                                        else {
                                            // TODO: NEW SIGNUP
                                            
                                            Task {
                                                await signUp()
                                                signUpStage = 0
                                            }
                                            
                                        }
                                    }
                                }
                            
                            if !isUsernameLoading {
                                if isUsernameValid {
                                    Image(systemName: "checkmark.circle")
                                        .foregroundColor(.green)
                                        .font(isSmallScreen ? .subheadline : .body)
                                }
                                else {
                                    Image(systemName: "xmark.circle")
                                        .foregroundColor(usernameError == true ? .red : .gray.opacity(0.4))
                                        .font(isSmallScreen ? .subheadline : .body)
                                }
                            }
                            else {
                                ProgressView()
                                    .controlSize(.small)
                                    .tint(Color(hex: "A6AEF0"))
                            }
                            
                        }
                        .overlay(
                            Divider()
                                .padding(.vertical, 0)
                                .frame(maxWidth: .infinity, maxHeight:1)
                                .background(LinearGradient(colors: [Color(hex: "b597f6"), Color(hex: "96c6ea")], startPoint: .leading, endPoint: .trailing)), alignment: .bottom)
                        .onReceive(usernameObject.$text.debounce(for: .seconds(0.8), scheduler: DispatchQueue.main))
                        {
                            guard $0 != "" else { return }
                            
                            if signUpStage == 2 {
                                Task {
                                    isUsernameLoading = true
                                    let usernameValidation = await validateUsername(username: usernameObject.text)
                                    if usernameValidation == "" {
                                        let isUsernameTaken = await isUsernameTaken(input: usernameObject.text)
                                        if isUsernameTaken {
                                            withAnimation(.spring(dampingFraction: 0.95)) {
                                                usernameErrorMsg = "Username is taken."
                                                usernameError = true
                                                isUsernameValid = false
                                            }
                                        }
                                        else {
                                            withAnimation(.spring(dampingFraction: 0.95)) {
                                                usernameErrorMsg = ""
                                                usernameError = false
                                                isUsernameValid = true
                                            }
                                        }
                                        isUsernameLoading = false
                                        
                                    }
                                    else {
                                        withAnimation(.spring(dampingFraction: 0.95)) {
                                            usernameErrorMsg = usernameValidation
                                            usernameError = true
                                            isUsernameLoading = false
                                            isUsernameValid = false
                                        }
                                    }
                                }
                            }
                            
                        }
                        .onTapGesture {
                            withAnimation(.spring(dampingFraction: 0.95)) {
                                isUsernameFocused = true
                                signUpStage = 2
                                passwordError = false
                                passwordErrorMsg = ""
                            }
                        }
                        .opacity(signUpStage > 1 ? 1 : 0)
                        
                        Text(usernameErrorMsg)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .font(.caption2)
                            .foregroundColor(.red)
                            .opacity(usernameError ? 1 : 0)
                        
                    }
                    .onAppear {
                        isUsernameFocused = true
                    }
                    .onDisappear {
                        isUsernameFocused = false
                    }
                }
                
                // Password textfield
                
                if signUpStage > 2 {
                    
                    VStack {
                        HStack(spacing: 20) {
                            Image(systemName: "lock")
                                .foregroundColor(.gray)
                            
                            CustomTextField(placeholder: Text("Password").foregroundColor(.gray).font(isSmallScreen ? .subheadline : .body), text: $passwordObject.text, isSecure: true)
                                .onReceive(passwordObject.$text.debounce(for: .seconds(0.8), scheduler: DispatchQueue.main))
                            {
                                guard $0 != "" else { return }
                                
                                if signUpStage == 3 {
                                    Task {
                                        isPasswordLoading = true
                                        
                                        let res = await validatePassword(password: passwordObject.text)
                                        
                                        if res == "" {
                                            withAnimation(.spring(dampingFraction: 0.95)) {
                                                passwordErrorMsg = ""
                                                passwordError = false
                                                isPasswordValid = true
                                            }
                                        }
                                        else {
                                            withAnimation(.spring(dampingFraction: 0.95)) {
                                                passwordErrorMsg = res
                                                passwordError = true
                                                isPasswordValid = false
                                            }
                                        }
                                        isPasswordLoading = false
                                    }
                                }
                            }
                            .onSubmit {
                                if isPasswordValid {
                                    if signUpStage < 3 {
                                        
                                        if signUpStage == 0 {
                                            isNameFocused = false
                                        }
                                        else if signUpStage == 1 {
                                            isEmailFocused = false
                                        }
                                        else if signUpStage == 2 {
                                            isUsernameFocused = false
                                        }
                                        else {
                                            isNameFocused = false
                                            isEmailFocused = false
                                            isUsernameFocused = false
                                            isPasswordFocused = false
                                        }
                                        
                                        withAnimation(.spring(dampingFraction: 0.95)) {
                                            signUpStage += 1
                                        }
                                        
                                    }
                                    else {
                                        // TODO: NEW SIGNUP
                                        
                                        Task {
                                            await signUp()
                                            signUpStage = 0
                                        }
                                        
                                    }
                                }
                            }
                            .focused($isPasswordFocused)
                            .frame(height: isSmallScreen ? 35 : 50)
                            .disabled(signUpStage < 3)
                            .font(isSmallScreen ? .subheadline : .body)
                            .onAppear {
                                isPasswordFocused = true
                            }
                            .onDisappear {
                                isPasswordFocused = false
                            }
                            
                            if !isPasswordLoading {
                                if isPasswordValid {
                                    Image(systemName: "checkmark.circle")
                                        .foregroundColor(.green)
                                        .font(isSmallScreen ? .subheadline : .body)
                                }
                                else {
                                    Image(systemName: "xmark.circle")
                                        .foregroundColor(passwordError == true ? .red : .gray.opacity(0.4))
                                        .font(isSmallScreen ? .subheadline : .body)
                                }
                            }
                            else {
                                ProgressView()
                                    .controlSize(.small)
                                    .tint(Color(hex: "A6AEF0"))
                            }
                            
                        }
                        .overlay(
                            Divider()
                                .padding(.vertical, 0)
                                .frame(maxWidth: .infinity, maxHeight:1)
                                .background(LinearGradient(colors: [Color(hex: "b597f6"), Color(hex: "96c6ea")], startPoint: .leading, endPoint: .trailing)), alignment: .bottom)
                        
                        Text(passwordErrorMsg)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .font(.caption2)
                            .foregroundColor(.red)
                            .opacity(passwordError ? 1 : 0)
                        
                    }
                }
            }
            
            VStack(spacing: 9) {
                Button(action: {
                    if signUpStage < 3 {
                        
                        if signUpStage == 0 {
                            isNameFocused = false
                        }
                        else if signUpStage == 1 {
                            isEmailFocused = false
                        }
                        else if signUpStage == 2 {
                            isUsernameFocused = false
                        }
                        else {
                            isNameFocused = false
                            isEmailFocused = false
                            isUsernameFocused = false
                            isPasswordFocused = false
                        }
                        
                        withAnimation(.spring(dampingFraction: 0.95)) {
                            signUpStage += 1
                        }
                        
                    }
                    else {
                        // TODO: NEW SIGNUP
                        
                        Task {
                            await signUp()
                            signUpStage = 0
                        }
                        
                    }
                    
                }, label: {
                    Text(signUpStage < 3 ? "Next" : "Sign Up")
                        .foregroundColor(.white)
                        .font(.title2)
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(LinearGradient(colors: [Color(hex: "b597f6"), Color(hex: "96c6ea")], startPoint: .leading, endPoint: .trailing))
                        .cornerRadius(10)
                })
                .disabled((signUpStage == 0 && !isNameValid) || (signUpStage == 1 && !isEmailValid) || (signUpStage == 2 && !isUsernameValid) || (signUpStage == 3 && !isPasswordValid))
                .opacity((signUpStage == 0 && !isNameValid) || (signUpStage == 1 && !isEmailValid) || (signUpStage == 2 && !isUsernameValid) || (signUpStage == 3 && !isPasswordValid) ? 0.5 : 1)
                
                HStack {
                    Text("Have an account?")
                        .italic()
                    Button(action: {
                        email = ""
                        password = ""
                        username = ""
                        hideKeyboard()
                        withAnimation(.spring(dampingFraction: 0.7)) {
                            isLogIn = true
                        }
                    }, label: {
                        Text("Log in")
                            .gradientForeground(colors: [Color(hex: "b597f6"), Color(hex: "96c6ea")], startPoint: .bottomLeading, endPoint: .topTrailing)
                            .italic()
                    })
                    
                    Spacer()
                }
                .foregroundColor(.black)
                .font(.subheadline)
                
            }
            
        }
        .padding(.horizontal, 40)
        .ignoresSafeArea(.keyboard)
    }
    
    // MARK: LOG IN SCREEN
    
    var LogIn: some View {
        VStack(spacing: 60) {
            VStack(spacing: 20) {
                
                // Email textfield
                
                HStack(spacing: 20) {
                    Image(systemName: "envelope")
                        .foregroundColor(.gray)
                    CustomTextField(placeholder: Text("Email").foregroundColor(.gray), text: $email, isSecure: false)
                        .frame(height: 50)
                }
                .overlay(
                    Divider()
                        .padding(.vertical, 0)
                        .frame(maxWidth: .infinity, maxHeight:1)
                        .background(LinearGradient(colors: [Color(hex: "b597f6"), Color(hex: "96c6ea")], startPoint: .leading, endPoint: .trailing)), alignment: .bottom)
                
                // Password textfield
                
                HStack(spacing: 20) {
                    Image(systemName: "lock")
                        .foregroundColor(.gray)
                    CustomTextField(placeholder: Text("Password").foregroundColor(.gray), text: $password, isSecure: true)
                        .frame(height: 50)
                    
                }
                .overlay(
                    Divider()
                        .padding(.vertical, 0)
                        .frame(maxWidth: .infinity, maxHeight:1)
                        .background(LinearGradient(colors: [Color(hex: "b597f6"), Color(hex: "96c6ea")], startPoint: .leading, endPoint: .trailing)), alignment: .bottom)
            }
            
            
            VStack(spacing: 9) {
                Button(action: {
                    Task {
                        await logIn()
                    }
                }, label: {
                    Text("Log In")
                        .foregroundColor(.white)
                        .font(.title2)
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(LinearGradient(colors: [Color(hex: "b597f6"), Color(hex: "96c6ea")], startPoint: .topTrailing, endPoint: .bottomLeading).matchedGeometryEffect(id: "buttonBackground", in: namespace))
                        .cornerRadius(10)
                })
                .matchedGeometryEffect(id: "button", in: namespace)
                
                
                HStack {
                    Text("Don't have an account?")
                        .italic()
                    Button(action: {
                        email = ""
                        password = ""
                        username = ""
                        hideKeyboard()
                        withAnimation(.spring(dampingFraction: 0.7)) {
                            isLogIn = false
                        }
                    }, label: {
                        Text("Create one")
                            .gradientForeground(colors: [Color(hex: "b597f6"), Color(hex: "96c6ea")], startPoint: .bottomLeading, endPoint: .topTrailing)
                            .italic()
                    })
                    
                    Spacer()
                }
                .foregroundColor(.black)
                .font(.subheadline)
                
                HStack {
                    Button(action: {
                        isForgetPassword = true
                    }, label: {
                        Text("Forgot password?")
                            .gradientForeground(colors: [Color(hex: "b597f6"), Color(hex: "96c6ea")], startPoint: .bottomLeading, endPoint: .topTrailing)
                            .italic()
                            .font(.subheadline)
                        
                    })
                    
                    Spacer()
                }
            }
        }
        .padding(.horizontal, 40)
    }
    
}

struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        SignInView()
    }
}
