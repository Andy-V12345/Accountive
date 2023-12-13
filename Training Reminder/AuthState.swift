//
//  AuthState.swift
//  Training Reminder
//
//  Created by Andy Vu on 9/6/23.
//

import Foundation
import FirebaseAuth

enum AuthenticationState {
    case undefined, notAuthorized, authorized
}


class AuthState: ObservableObject {
    @Published var value: AuthenticationState = .undefined
    @Published var user: User? = nil
    @Published var doneAuth: Bool? = nil
    
    private var username = ""
    
    init() {
        Auth.auth().addStateDidChangeListener { auth, user in
            self.value = user != nil ? .authorized : .notAuthorized
            self.user = user != nil ? user : nil
        }
    }
    
    @MainActor
    func isEmailTaken(email: String) async throws -> Bool {
        do {
            let res = try await Auth.auth().fetchSignInMethods(forEmail: email)
            return res.count > 0
        }
        catch {
            throw error
        }
    }
    
    @MainActor
    func signUp(email: String, password: String, name: String) async throws {
        try await Auth.auth().createUser(withEmail: email, password: password)
        let changeReq = Auth.auth().currentUser?.createProfileChangeRequest()
        changeReq?.displayName = name
        do {
            try await changeReq?.commitChanges()
        }
        catch {
            throw error
        }
    }
    
    @MainActor
    func setUsername(username: String) {
        self.username = username
    }
    
    @MainActor
    func getUsername() -> String {
        return self.username
    }
    
    @MainActor
    @discardableResult
    func logIn(email: String, password: String) async throws -> AuthDataResult {
        try await Auth.auth().signIn(withEmail: email, password: password)
    }
    
    @MainActor
    func deleteAccount(password: String) async throws {
        let firebaseService = FirebaseService()
        
        let uid = self.user!.uid
        
        let creds = EmailAuthProvider.credential(withEmail: self.user!.email ?? "", password: password)
        
        do {
            
            let _ = try await self.user?.reauthenticate(with: creds)
            
            let friends = try await firebaseService.getFriends(uid: uid)
            let friendReqs = try await firebaseService.getFriendReq(uid: uid) as? [String: [String: String]] ?? [:]
            let pendingReqs = try await firebaseService.getPendingReq(uid: uid) as? [String: [String: String]] ?? [:]
            
            for friend in friends {
                firebaseService.removeFriend(uid: uid, friendToRemove: friend)
            }
            
            for (friendUid, data) in friendReqs {
                let friend = Friend(uid: friendUid, name: data["name"] ?? "", username: data["username"] ?? "", status: data["status"] ?? "")
                firebaseService.removeFriendRequest(uid: uid, friendToRemove: friend)
            }
            
            for (friendUid, data) in pendingReqs {
                let friend = Friend(uid: friendUid, name: data["name"] ?? "", username: data["username"] ?? "", status: data["status"] ?? "")
                firebaseService.removePendingRequest(uid: uid, friendToRemove: friend)
            }
            
            try await firebaseService.deleteUid(uid: uid)
            
            try await self.user?.delete()
            
        }
        catch {
            throw error
        }
    
    }
        
    
    @MainActor
    func logout() throws {
        self.doneAuth = nil
        try Auth.auth().signOut()
    }
    
}
