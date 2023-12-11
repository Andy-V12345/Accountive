//
//  FriendPanel.swift
//  Training Reminder
//
//  Created by Andy Vu on 9/20/23.
//

import SwiftUI

struct FriendPanel: View {
    
    @Binding var friend: Friend
    let isFriend: Bool
    
    @EnvironmentObject var authState: AuthState
    
    @Binding var deleteIndex: String
    
    @Binding var isConfirmingDelete: Bool
    @Binding var friendBeingDeleted: Friend?
    
    let firebaseService = FirebaseService()
    
    var body: some View {
        HStack {
            VStack {
                Text(friend.name)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.title3)
                    .bold()
                Text(friend.username)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Spacer()
            
            if !isFriend {
                Button(action: {
                    // TODO: SEND FRIEND REQUEST
                    firebaseService.sendFriendReq(fromFriend: Friend(uid: authState.user!.uid, name: authState.user!.displayName!, username: authState.getUsername(), status: ""), toFriend: friend)
                    friend.status = "PENDING"
                    Task {
                        do {
                            let toFcmToken = try await firebaseService.getFcmTokenOfFriend(friendUid: friend.uid)
                            if toFcmToken != "" {
                                try await firebaseService.notifyIndividual(username: authState.getUsername(), targetFcmKey: toFcmToken)
                            }
                        }
                        catch {
                            print(error)
                        }
                    }
                }, label: {
                    Text("ADD")
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .foregroundStyle(Color.white)
                        .font(.footnote)
                        .bold()
                        .background(LinearGradient(colors: [Color(hex: "b597f6"), Color(hex: "96c6ea")], startPoint: .bottomLeading, endPoint: .topTrailing))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                })
            }
            else {
                Button(action: {
                    // TODO: REMOVE FRIEND
                    isConfirmingDelete = true
                    friendBeingDeleted = friend
                }, label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(.red)
                })
            }
        }
        .padding(.vertical, 10)
    }
}

//#Preview {
//    FriendPanel(friend: Friend(name: "Nam", username: "namv123", status: ""), isFriend: false, isRequest: false)
//}
