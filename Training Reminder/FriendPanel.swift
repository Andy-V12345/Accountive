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
        HStack(spacing: 30) {
            VStack(alignment: .leading) {
                Text(friend.name)
                    .frame(alignment: .leading)
                    .font(.title3)
                    .bold()
                Text(friend.username)
                    .frame(alignment: .leading)
            }
            
            Spacer()
            
            CircleProgressBar(count: friend.doneCount, total: friend.totalCount, progress: friend.totalCount == 0 ? 0 : CGFloat(friend.doneCount) / CGFloat(friend.totalCount), font1: .body.weight(.medium), lineWidth: 4, includeTotal: false)
                .frame(height: 40)
            
            
            
            if !isFriend {
                Button(action: {
                    // TODO: SEND FRIEND REQUEST
                    firebaseService.sendFriendReq(fromFriend: Friend(uid: authState.user!.uid, name: authState.user!.displayName!, username: authState.getUsername(), status: ""), toFriend: friend)
                    friend.status = "PENDING"
                    Task {
                        do {
                            let toFcmToken = try await firebaseService.getFcmTokenOfFriend(friendUid: friend.uid)
                            if toFcmToken != "" {
                                try await firebaseService.notifyIndividual(targetFcmKey: toFcmToken, body:
                                "\(authState.getUsername()) sent you a friend request!")
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

//struct FriendPanelPreview: View {
//    
//    @State var friend = Friend(name: "Nam", username: "Nammy", status: "FRIEND", doneCount: 2, totalCount: 3)
//    @State var friend2 = Friend(name: "Andy", username: "Andy.v123", status: "FRIEND", doneCount: 1, totalCount: 2)
//    @State var deleteIndex = "fasd"
//    @State var isDeleting = false
//    @State var deleteFriend: Friend? = nil
//    
//    var body: some View {
//        VStack {
//            FriendPanel(friend: $friend, isFriend: true, deleteIndex: $deleteIndex, isConfirmingDelete: $isDeleting, friendBeingDeleted: $deleteFriend)
//            
//            FriendPanel(friend: $friend2, isFriend: true, deleteIndex: $deleteIndex, isConfirmingDelete: $isDeleting, friendBeingDeleted: $deleteFriend)
//        }
//        .padding(.horizontal, 20)
//    }
//}
//
//#Preview {
//    FriendPanelPreview()
//}
