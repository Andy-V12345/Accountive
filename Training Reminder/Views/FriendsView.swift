//
//  FriendsView.swift
//  Training Reminder
//
//  Created by Andy Vu on 9/19/23.
//

import SwiftUI
import AlertToast

// MARK: SEARCHBAR STRUCT
struct SearchBar: View {
    
    @StateObject var searchObject = TextInputVM()
    
    @Binding var text: String
    @State var placeholder: String
    @Binding var showingCancel: Bool

    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .font(.footnote)
            
            CustomTextField(placeholder: Text("Search or add friends").foregroundColor(.gray), text: $searchObject.text, isSecure: false)
                .onReceive(searchObject.$text.debounce(for: .seconds(0.4), scheduler: DispatchQueue.main))
            {
                guard $0 != "" else {
                    text = ""
                    return
                }
                
                text = searchObject.text
                
            }
            .onTapGesture {
                withAnimation(.linear(duration: 0.2)) {
                    showingCancel = true
                }
            }
            
            if searchObject.text != "" {
                Button(action: {
                    searchObject.text = ""
                }, label: {
                    Image(systemName: "xmark.circle")
                        .font(.footnote)
                })
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 10)
        .background(.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

// MARK: PREFERENCE KEY FOR PULL TO REFRESH
struct FriendsViewKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value += nextValue()
    }
}

// MARK: FRIENDSVIEW

struct FriendsView: View {
    
    @State var searchQuery = ""
    
    @State var showingCancel = false
    
    @EnvironmentObject var authState: AuthState
    
    @State var friends: [Friend] = []
    
    @State var queryRes: [Friend] = []
    
    @State var isLoading = false
    
    var isTesting = false
    
    let firebaseService = FirebaseService()
    
    @Environment(\.dismiss) var dismiss
    
    @State var deleteUid = ""
    
    @State var isConfirmingDelete = false
    
    @State var doesHaveFriends = false
    
    @State var friendBeingRemoved: Friend? = nil
    
    @State var errorMsg = ""
    @State var isError = false
    
    @Environment(\.refresh) private var refresh
    @State private var isRefreshing = false
    let amountBeforeRefreshing: CGFloat = 150
    @State private var offset: CGFloat? = nil
    
    // MARK: LOADFRIENDS()
    
    private func loadFriends() async {
        isLoading = true
        do {
            friends = try await firebaseService.getFriends(uid: authState.user!.uid)
            isLoading = false
        }
        catch {
            errorMsg = "Error loading friends"
            isError = true
            isLoading = false
        }
    }
    
    
    var body: some View {
        GeometryReader { screen in
            ZStack {
                Color.white.ignoresSafeArea()
                    
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
                    
                    
                    // MARK: SEARCHBAR
                    HStack(spacing: showingCancel ? 5 : 0) {
                        SearchBar(text: $searchQuery, placeholder: "Search or add friends", showingCancel: $showingCancel)
                            .frame(maxWidth: .infinity)
                        
                        Button(action: {
                            // TODO: CANCEL SEARCH
                            withAnimation(.linear(duration: 0.2)) {
                                showingCancel.toggle()
                                hideKeyboard()
                            }
                        }, label: {
                            Text("Cancel")
                                .lineLimit(1)
                                .truncationMode(.tail)
                        })
                        .frame(width: showingCancel ? 75 : 0)
                        
                    }
                    
                    // MARK: FRIENDS DISPLAY
                    
                    GeometryReader { scrollgeo in
                        ScrollView() {
                            if isLoading && !isRefreshing {
                                VStack {
                                    Spacer()
                                    ProgressView()
                                        .tint(Color(hex: "A6AEF0"))
                                        .frame(width: 300)
                                        .controlSize(.regular)
                                    Spacer()
                                }
                                .frame(width: scrollgeo.size.width)
                                .frame(minHeight: scrollgeo.size.height - 100)
                            }
                            else if queryRes.isEmpty && friends.isEmpty && searchQuery == "" {
                                VStack {
                                    Text("Add some friends!")
                                        .gradientForeground(colors: [Color(hex: "b597f6"), Color(hex: "96c6ea")], startPoint: .bottomLeading, endPoint: .topTrailing)
                                        .italic()
                                }
                                .frame(width: scrollgeo.size.width)
                                .frame(minHeight: scrollgeo.size.height - 100)
                                .overlay(GeometryReader { geo in
                                    let currentScrollViewPosition = -geo.frame(in: .named("scrollview")).origin.y
                                    
                                    if currentScrollViewPosition < -amountBeforeRefreshing && !isRefreshing {
                                        Color.clear.preference(key: FriendsViewKey.self, value: -geo.frame(in: .global).origin.y)
                                    }
                                })
                                .opacity(isRefreshing ? 0.3 : 1)
                                
                            }
                            else if !doesHaveFriends && queryRes.isEmpty && searchQuery != "" {
                                VStack {
                                    Spacer()
                                    
                                    Text("No user found!")
                                        .gradientForeground(colors: [Color(hex: "b597f6"), Color(hex: "96c6ea")], startPoint: .bottomLeading, endPoint: .topTrailing)
                                        .italic()
                                    
                                    Spacer()
                                }
                                .frame(width: scrollgeo.size.width)
                                .frame(minHeight: scrollgeo.size.height - 100)
                                .overlay(GeometryReader { geo in
                                    let currentScrollViewPosition = -geo.frame(in: .named("scrollview")).origin.y
                                    
                                    if currentScrollViewPosition < -amountBeforeRefreshing && !isRefreshing {
                                        Color.clear.preference(key: FriendsViewKey.self, value: -geo.frame(in: .global).origin.y)
                                    }
                                })
                                .opacity(isRefreshing ? 0.3 : 1)
                            }
                            else {
                                VStack(spacing: 0) {
                                    if !friends.isEmpty {
                                        if doesHaveFriends {
                                            Text("YOUR FRIENDS")
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .gradientForeground(colors: [Color(hex: "b597f6"), Color(hex: "96c6ea")], startPoint: .bottomLeading, endPoint: .topTrailing)
                                                .bold()
                                            LazyVStack(spacing: 0) {
                                                ForEach(0..<friends.count, id:\.self) { i in
                                                    if searchQuery == "" {
                                                        FriendPanel(friend: $friends[i], isFriend: true, deleteIndex: $deleteUid, isConfirmingDelete: $isConfirmingDelete, friendBeingDeleted: $friendBeingRemoved)
                                                            .environmentObject(authState)
                                                    }
                                                    else if searchQuery != "" && friends[i].username.hasPrefix(searchQuery) {
                                                        FriendPanel(friend: $friends[i], isFriend: true, deleteIndex: $deleteUid, isConfirmingDelete: $isConfirmingDelete, friendBeingDeleted: $friendBeingRemoved)
                                                            .environmentObject(authState)
                                                    }
                                                    
                                                }
                                            }
                                        }
                                    }
                                    
                                    if !queryRes.isEmpty {
                                        Text("RESULTS")
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .gradientForeground(colors: [Color(hex: "b597f6"), Color(hex: "96c6ea")], startPoint: .bottomLeading, endPoint: .topTrailing)
                                            .bold()
                                        LazyVStack(spacing: 0) {
                                            ForEach(0..<queryRes.count, id:\.self) { i in
                                                if queryRes[i].status == "PENDING" {
                                                    RequestPanel(friend: queryRes[i], reqStatus: $queryRes[i].status, deleteIndex: $deleteUid)
                                                }
                                                else {
                                                    FriendPanel(friend: $queryRes[i], isFriend: false, deleteIndex: $deleteUid, isConfirmingDelete: $isConfirmingDelete, friendBeingDeleted: $friendBeingRemoved)
                                                        .environmentObject(authState)
                                                }
                                            }
                                        }
                                    }
                                } //: VStack
                                .padding(.bottom, 70)
                                .overlay(GeometryReader { geo in
                                    let currentScrollViewPosition = -geo.frame(in: .named("scrollview")).origin.y
                                    
                                    if currentScrollViewPosition < -amountBeforeRefreshing && !isRefreshing {
                                        Color.clear.preference(key: FriendsViewKey.self, value: -geo.frame(in: .global).origin.y)
                                    }
                                })
                                .opacity(isRefreshing ? 0.4 : 1)
                            }
                            
                        } //: ScrollView
                        .scrollIndicators(.hidden)
                        .coordinateSpace(name: "scrollview")
                        .onPreferenceChange(FriendsViewKey.self) { scrollPosition in
                            if scrollPosition < -amountBeforeRefreshing && !isRefreshing {
                                isRefreshing = true
                                Task {
                                    await loadFriends()
                                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                                    await MainActor.run {
                                        isRefreshing = false
                                    }
                                }
                            }
                        }
                        .overlay(
                            isRefreshing ?
                            ProgressView()
                                .tint(Color(hex: "A6AEF0"))
                                .frame(width: 300)
                                .controlSize(.regular)
                                .offset(y: -50)
                            :
                                nil
                            , alignment: .center)
                    }
                    
                    Spacer()
                } //: VStack
                .padding(.top, 10)
                .padding(.horizontal, 20)
            } //: Parent ZStack
            .toast(isPresenting: $isError, duration: 3, alert: {
                AlertToast(displayMode: .hud, type: .error(Color(hex: "ff5858")), subTitle: errorMsg)
            })
            .onChange(of: searchQuery) { _ in
                Task {
                    isLoading = true
                    do {
                        queryRes = try await firebaseService.filterUsernames(uid: authState.user!.uid, query: searchQuery, currentUsername: authState.getUsername())
                        
                        let filtered = friends.first(where: { friend in
                            friend.username.hasPrefix(searchQuery)
                        })
                                                
                        doesHaveFriends = filtered != nil
                        isLoading = false
                    }
                    catch {
                        errorMsg = "Error loading results"
                        isError = true
                    }
                }
            }
            .onAppear {
                Task {
                    await loadFriends()
                    doesHaveFriends = friends.count > 0
                }
            }
            .ignoresSafeArea(edges: [.bottom, .leading, .trailing])
            .alert("Are You Sure?", isPresented: $isConfirmingDelete, presenting: "Are you sure you want to unfriend \(friendBeingRemoved?.username ?? "")? You won't be notified when they've completed a task.") { details in
                Button(role: .destructive) {
                    // TODO: REMOVE FRIEND
                    firebaseService.removeFriend(uid: authState.user!.uid, friendToRemove: friendBeingRemoved!)
                    friends.removeAll(where: { friend in
                        friend.uid == friendBeingRemoved!.uid
                    })
                } label: {
                    Text("Remove")
                }
            } message: { details in
                Text("Are you sure you want to unfriend \(friendBeingRemoved?.username ?? "")? You won't be notified when they've completed a task.")
            }
        } //: GeometryReader
        .ignoresSafeArea(.keyboard)

    }
}

struct FriendsView_Previews: PreviewProvider {
    static var previews: some View {
        FriendsView()
    }
}


