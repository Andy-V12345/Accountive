//
//  RequestPanel.swift
//  Training Reminder
//
//  Created by Andy Vu on 9/21/23.
//

import SwiftUI

struct RequestPanel: View {
    let friend: Friend
    @Binding var reqStatus: String
    
    @EnvironmentObject var authState: AuthState
    
    let firebaseService = FirebaseService()
    
    @Binding var deleteIndex: String
    
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
            
            HStack(spacing: 15) {
                
                Text(reqStatus)
                    .bold()
                    .font(.footnote)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                
                Button(action: {
                    // TODO: CANCEL FRIEND REQUEST
                    firebaseService.removePendingRequest(uid: authState.user!.uid, friendToRemove: friend)
                    deleteIndex = friend.uid
                    reqStatus = ""
                }, label: {
                    Image(systemName: "xmark")
                        .font(.footnote)
                    
                })
            }
        }
        .padding(.vertical, 10)
    }
}

