//
//  FriendRequestPanel.swift
//  Training Reminder
//
//  Created by Andy Vu on 9/22/23.
//

import SwiftUI

struct FriendRequestPanel: View {
    
    @Binding var friend: Friend
    @Binding var deleteIndex: String
    
    @EnvironmentObject var authState: AuthState
    
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
            
            HStack(spacing: 25) {
                Button(action: {
                    // TODO: ACCEPT REQUEST
                    firebaseService.addFriend(username: authState.getUsername(), name: authState.user!.displayName!, uid: authState.user!.uid, friendToAdd: friend)
                    deleteIndex = friend.uid
                }, label: {
                    Text("ACCEPT")
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .foregroundStyle(Color.white)
                        .font(.footnote)
                        .bold()
                        .background(LinearGradient(colors: [Color(hex: "b597f6"), Color(hex: "96c6ea")], startPoint: .bottomLeading, endPoint: .topTrailing))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                })
                
                Button(action: {
                    // TODO: REMOVE REQUEST
                    firebaseService.removeFriendRequest(uid: authState.user!.uid, friendToRemove: friend)
                    deleteIndex = friend.uid
                }, label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(.red)
                })
            }
        }
        .padding(.vertical, 10)
    }
}

