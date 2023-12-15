//
//  SocialContainerView.swift
//  Training Reminder
//
//  Created by Andy Vu on 9/21/23.
//

import SwiftUI
import AlertToast

struct SocialContainerView: View {
    
    @State var isFriendsView: Bool = !(AppState.shared.showSocial)
    @State var isRequestsView = AppState.shared.showSocial
    @State var isGroupsView = false
    
    @EnvironmentObject var authState: AuthState
    
    let firebaseService = FirebaseService()
    
    @State var doesHaveFriendReq = false
    @State var friendReqRes: [String: [String: String]] = [:]
    
    @Namespace var namespace
    
    @State var errorMsg = ""
    @State var isError = false
    
    let isTesting = false
    
    @Environment(\.dismiss) var dismiss
    
    func realtimeFriendReq(uid: String) {
        
        var reqData: [String: [String: String]] = [:]
        let _ = firebaseService.db.collection("requests").document(uid)
            .addSnapshotListener(includeMetadataChanges: true, listener: { docSnapshot, error in
                guard let doc = docSnapshot else {
                    errorMsg = "Error loading friends"
                    isError = true
                    return
                }
                guard let data = doc.data() else {
                    return
                }
                                
                reqData = data["friendRequests"] as? [String: [String: String]] ?? [:]
                
                friendReqRes = reqData
                doesHaveFriendReq = !(reqData == [:])
                
            })
        
    }
    
    var body: some View {
        ZStack() {
            
            VStack(spacing: 15) {
                
                // MARK: HEADER HSTACK
                HStack {
                    Image(systemName: "arrow.right")
                        .hidden()
                    Spacer()

                    Text("ACCOUNTIVE")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .gradientForeground(colors: [Color(hex: "b597f6"), Color(hex: "96c6ea")], startPoint: .bottomLeading, endPoint: .topTrailing)
                        .font(.system(size: 30))
                        .fontWidth(.condensed)
                        .bold()

                    Spacer()

                    Button(action: {
                        AppState.shared.showSocial = false
                        dismiss()
                    }, label: {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .foregroundColor(.black)
                    })
                } //: Header HStack
                
                if !isGroupsView {
                    
                    // MARK: ACCOUNT PANEL
                    HStack {
                        VStack {
                            Text("Share your username")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .bold()
                                .font(.body)
                                .foregroundColor(.white)
                            Text(isTesting ? "Andy Vu" : authState.user?.displayName ?? "")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .bold()
                                .font(.title)
                                .foregroundColor(.white)
                            Text(isTesting ? "Andy.V" : authState.getUsername())
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .font(.subheadline)
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        ShareLink("", item: "Add me on Accountive (https://apps.apple.com/app/accountive/id6468552927)! My username: \(authState.getUsername())")
                            .foregroundColor(.white)
                            .font(.title3)
                        
                    }
                    .padding()
                    .background(LinearGradient(colors: [Color(hex: "b597f6"), Color(hex: "96c6ea")], startPoint: .bottomLeading, endPoint: .topTrailing))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                
                if isFriendsView {
                    FriendsView()
                        .frame(maxHeight: .infinity)
                        .environmentObject(authState)
                }
                else if isRequestsView {
                    RequestsView(doesHaveFriendReq: $doesHaveFriendReq, friendReqRes: $friendReqRes)
                        .environmentObject(authState)
                }
                else if isGroupsView {
                    GroupsView()
                        .environmentObject(authState)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            
            VStack {
                Spacer()
                HStack(spacing: 10) {
                    Text("Friends")
                        .foregroundStyle(isFriendsView ? .black : .white)
                        .font(.subheadline)
                        .bold()
                        .padding(.horizontal, 15)
                        .padding(.vertical, 6)
                        .background(isFriendsView ? .white : .clear)
                        .clipShape(Capsule())
                        .onTapGesture {
                            withAnimation(.spring()) {
                                isFriendsView = true
                                isGroupsView = false
                                isRequestsView = false
                            }
                        }
                    
                    Text("Requests")
                        .foregroundStyle(isRequestsView ? .black : .white)
                        .font(.subheadline)
                        .bold()
                        .padding(.horizontal, 15)
                        .padding(.vertical, 6)
                        .background(isRequestsView ? .white : .clear)
                        .clipShape(Capsule())
                        .onTapGesture {
                            withAnimation(.spring()) {
                                isRequestsView = true
                                isGroupsView = false
                                isFriendsView = false
                            }
                        }
                        .overlay(alignment: .topTrailing, content: {
                            if doesHaveFriendReq {
                                Circle()
                                    .fill(.red)
                                    .frame(width: 6)
                                    .offset(x: -9, y: 8)
                            }
                        })
                    
                    Text("Groups")
                        .foregroundStyle(isGroupsView ? .black : .white)
                        .font(.subheadline)
                        .bold()
                        .padding(.horizontal, 15)
                        .padding(.vertical, 6)
                        .background(isGroupsView ? .white : .clear)
                        .clipShape(Capsule())
                        .onTapGesture {
                            withAnimation(.spring()) {
                                isGroupsView = true
                                isFriendsView = false
                                isRequestsView = false
                            }
                        }
                    
                } //: HStack
                .padding(.vertical, 10)
                .padding(.horizontal, 10)
                .background(LinearGradient(colors: [Color(hex: "b597f6"), Color(hex: "96c6ea")], startPoint: .bottomLeading, endPoint: .topTrailing))
                .clipShape(Capsule())
            } //: VStack
            .padding(.bottom, 10)

        } //: ZStack
        .padding(.bottom, 20)
        .ignoresSafeArea(edges: [.bottom, .leading, .trailing])
        .onAppear {
            realtimeFriendReq(uid: authState.user!.uid)
        }
        .toast(isPresenting: $isError, duration: 3, alert: {
            AlertToast(displayMode: .hud, type: .error(Color(hex: "ff5858")), subTitle: errorMsg)
        })
        .onTapGesture {
            hideKeyboard()
        }
        
    }
}
