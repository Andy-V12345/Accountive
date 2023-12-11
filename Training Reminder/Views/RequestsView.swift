//
//  RequestsView.swift
//  Training Reminder
//
//  Created by Andy Vu on 9/21/23.
//

import SwiftUI
import AlertToast

struct RequestsView: View {
    
    var isTesting = false
    
    @Environment(\.dismiss) var dismiss
    
    @Binding var doesHaveFriendReq: Bool
    
    @State var friendReq: [Friend] = []
    @State var pendingReq: [Friend] = []
    
    let firebaseService = FirebaseService()
    
    @State var isLoading = true
    
    @EnvironmentObject var authState: AuthState
    
    @State var deleteUid: String = ""
    
    @State var errorMsg = ""
    @State var isError = false
    
    var body: some View {
        GeometryReader { screen in
            ZStack {
                Color.white.ignoresSafeArea()
                VStack(spacing: 15) {
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
                    
                    if isLoading {
                        VStack {
                            Spacer()
                            ProgressView()
                                .tint(Color(hex: "A6AEF0"))
                                .frame(width: 300)
                                .controlSize(.large)
                            Spacer()
                        }
                        .padding(.bottom, 70)
                    }
                    else {
                        if friendReq.isEmpty && pendingReq.isEmpty {
                            VStack {
                                Spacer()
                                Text("Wow, it's empty in here!")
                                    .gradientForeground(colors: [Color(hex: "b597f6"), Color(hex: "96c6ea")], startPoint: .bottomLeading, endPoint: .topTrailing)
                                    .italic()
                                Spacer()
                            }
                            .padding(.bottom, 70)
                        }
                        else {
                            ScrollView() {
                                VStack(spacing: 0) {
                                    if !friendReq.isEmpty {
                                        Text("FRIEND REQUESTS")
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .gradientForeground(colors: [Color(hex: "b597f6"), Color(hex: "96c6ea")], startPoint: .bottomLeading, endPoint: .topTrailing)
                                            .bold()
                                        LazyVStack(spacing: 0) {
                                            ForEach(0..<friendReq.count, id:\.self) { i in
                                                FriendRequestPanel(friend: $friendReq[i], deleteIndex: $deleteUid)
                                                    .environmentObject(authState)
                                            }
                                        }
                                    }
                                    if !pendingReq.isEmpty {
                                        Text("YOUR REQUESTS")
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .gradientForeground(colors: [Color(hex: "b597f6"), Color(hex: "96c6ea")], startPoint: .bottomLeading, endPoint: .topTrailing)
                                            .bold()
                                        LazyVStack(spacing: 0) {
                                            ForEach(0..<pendingReq.count, id:\.self) { i in
                                                RequestPanel(friend: pendingReq[i], reqStatus: $pendingReq[i].status, deleteIndex: $deleteUid)
                                            }
                                        }
                                    }
                                }
                                .padding(.bottom, 70)
                                .onChange(of: deleteUid) { value in
                                    if value != "" {
                                        friendReq.removeAll { friend in
                                            friend.uid == value
                                        }
                                        
                                        pendingReq.removeAll { friend in
                                            friend.uid == value
                                        }
                                        
                                        doesHaveFriendReq = !friendReq.isEmpty && !pendingReq.isEmpty
                                        
                                    }
                                }
                            } //: ScrollView
                            .scrollIndicators(.hidden)
                        }
                    }
                    
                    Spacer()
                }
            } //: Parent ZStack
            .padding(.top, 10)
            .padding(.horizontal, 20)
            .toast(isPresenting: $isError, duration: 3, alert: {
                AlertToast(displayMode: .hud, type: .error(Color(hex: "ff5858")), subTitle: errorMsg)
            })
            .onAppear {
                Task {
                    do {
                        withAnimation(.spring()) {
                            isLoading = true
                        }
                        
                        let friendReqRes = try await firebaseService.getFriendReq(uid: authState.user!.uid) as? [String: [String: String]] ?? [:]
                        let pendingReqRes = try await firebaseService.getPendingReq(uid: authState.user!.uid) as? [String: [String: String]] ?? [:]
                        
                        if friendReqRes != [:] {
                            
                            for (uid, data) in friendReqRes {
                                friendReq.append(Friend(uid: uid, name: data["name"]!, username: data["username"]!, status: data["status"]!))
                            }
                        }
                        
                        if pendingReqRes != [:] {
                            
                            for (uid, data) in pendingReqRes {
                                pendingReq.append(Friend(uid: uid, name: data["name"]!, username: data["username"]!, status: data["status"]!))
                            }
                        }
                        
                        withAnimation(.spring()) {
                            isLoading = false
                        }
                        
                    }
                    catch {
                        errorMsg = "Error loading friend requests"
                        isError = true
                    }
                }
                
            }
            .ignoresSafeArea(edges: [.bottom, .leading, .trailing])
        }
    }
    
}

