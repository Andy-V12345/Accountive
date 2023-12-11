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
    @EnvironmentObject var authState: AuthState
    
    let firebaseService = FirebaseService()
    
    @State var doesHaveFriendReq = false
    
    @Namespace var namespace
    
    @State var errorMsg = ""
    @State var isError = false
    
    var body: some View {
        ZStack() {
            if isFriendsView {
                FriendsView()
                    .frame(maxHeight: .infinity)
                    .environmentObject(authState)
            }
            else {
                RequestsView(doesHaveFriendReq: $doesHaveFriendReq)
                    .environmentObject(authState)
            }
            
            VStack {
                Spacer()
                HStack(spacing: 20) {
                    Text("Friends")
                        .foregroundStyle(isFriendsView ? .black : .white)
                        .bold()
                        .padding(.horizontal, 20)
                        .padding(.vertical, 6)
                        .background(isFriendsView ? .white : .clear)
                        .clipShape(Capsule())
                        .onTapGesture {
                            withAnimation(.spring()) {
                                isFriendsView = true
                            }
                        }
                    
                    Text("Requests")
                        .foregroundStyle(isFriendsView ? .white : .black)
                        .bold()
                        .padding(.horizontal, 20)
                        .padding(.vertical, 6)
                        .background(isFriendsView ? .clear : .white)
                        .clipShape(Capsule())
                        .onTapGesture {
                            withAnimation(.spring()) {
                                isFriendsView = false
                            }
                        }
                        .overlay(alignment: .topTrailing, content: {
                            if doesHaveFriendReq {
                                Circle()
                                    .fill(.red)
                                    .frame(width: 8)
                                    .offset(x: -12, y: 7)
                            }
                        })
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
            Task {
                do {
                    doesHaveFriendReq = !(try await firebaseService.getFriendReq(uid: authState.user!.uid).isEmpty)
                }
                catch {
                    errorMsg = "Error loading friends"
                    isError = true
                }
            }
        }
        .toast(isPresenting: $isError, duration: 3, alert: {
            AlertToast(displayMode: .hud, type: .error(Color(hex: "ff5858")), subTitle: errorMsg)
        })
        .onTapGesture {
            hideKeyboard()
        }
        
    }
}

struct SocialContainerPreview: PreviewProvider {
    static var previews: some View {
        SocialContainerView(isFriendsView: true)
    }
}
