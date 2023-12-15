//
//  AddingGroupView.swift
//  Training Reminder
//
//  Created by Andy Vu on 12/15/23.
//

import SwiftUI
import AlertToast

struct FriendGroupSelection {
    var friend: Friend
    var isSelected: Bool = false
}

// MARK: PREFERENCE KEY FOR PULL TO REFRESH
struct FriendGroupKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value += nextValue()
    }
}


struct AddingGroupView: View {
    
    @EnvironmentObject var authState: AuthState
    
    @Environment(\.dismiss) var dismiss
    
    @State var groupName = ""
    
    @State var friendSelections: [FriendGroupSelection] = []
    
    @State var searchQuery = ""
    @State var showingCancel = false
    @State var queryRes = true
    
    @State var selectedFriends: [Friend] = []
    
    @State var isError = false
    @State var errorMsg = ""
    
    @State var isLoadingFriends = false
    
    @Environment(\.refresh) private var refresh
    @State private var isRefreshing = false
    let amountBeforeRefreshing: CGFloat = 125
    
    let firebaseService = FirebaseService()
    
    func loadQuery() {
        queryRes = friendSelections.contains { friendSelection in
            friendSelection.friend.username.hasPrefix(searchQuery)
        }
    }
    
    func loadFriends() async {
        do {
            
            isLoadingFriends = true
            
            let friends = try await firebaseService.getFriends(uid: authState.user!.uid)
            
            friendSelections.removeAll()
            
            for friend in friends {
                friendSelections.append(FriendGroupSelection(friend: friend))
            }
            
            isLoadingFriends = false
        }
        catch {
            errorMsg = "Error loading friend groups"
            isError = true
        }
    }
    
    var body: some View {
        GeometryReader { screen in
            ZStack {
                Color.white.ignoresSafeArea()
                
                VStack(spacing: 30) {
                    HStack(alignment: .center) {
                        Text("Create a group")
                            .font(.title)
                            .bold()
                        
                        Spacer()
                        
                        Button(action: {
                            dismiss()
                        }, label: {
                            Image(systemName: "xmark")
                                .font(.title3)
                                .foregroundStyle(.black)
                        })
                    }
                    
                    // MARK: GROUP NAME TEXT FIELD
                    VStack(spacing: 0) {
                        Text("GROUP NAME")
                            .bold()
                            .gradientForeground(colors: [Color(hex: "b597f6"), Color(hex: "96c6ea")], startPoint: .leading, endPoint: .trailing)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        HStack(spacing: 20) {
                            Image(systemName: "pencil")
                                .foregroundColor(.gray)
                                .bold()
                            CustomTextField(placeholder: Text("Enter group name").foregroundColor(.gray), text: $groupName, isSecure: false)
                                .frame(height: 50)
                            
                        } //: HStack
                        .overlay(
                            Divider()
                                .padding(.vertical, 0)
                                .frame(maxWidth: .infinity, maxHeight:1)
                                .background(LinearGradient(colors: [Color(hex: "b597f6"), Color(hex: "96c6ea")], startPoint: .leading, endPoint: .trailing)), alignment: .bottom)
                    }
                    
                    // MARK: FRIEND SELECTION
                    VStack(spacing: 10) {
                        Text("SELECT FRIENDS")
                            .bold()
                            .gradientForeground(colors: [Color(hex: "b597f6"), Color(hex: "96c6ea")], startPoint: .leading, endPoint: .trailing)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // MARK: SEARCHBAR
                        HStack(spacing: showingCancel ? 5 : 0) {
                            SearchBar(text: $searchQuery, placeholder: "Search your friends", showingCancel: $showingCancel)
                                .frame(maxWidth: .infinity)
                            
                            Button(action: {
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
                        
                        GeometryReader { scrollGeo in
                            ScrollView(.vertical) {
                                if isLoadingFriends && !isRefreshing {
                                    VStack {
                                        Spacer()
                                        ProgressView()
                                            .tint(Color(hex: "A6AEF0"))
                                            .frame(width: 300)
                                            .controlSize(.regular)
                                        Spacer()
                                    }
                                    .frame(width: scrollGeo.size.width)
                                    .frame(minHeight: scrollGeo.size.height)
                                }
                                else {
                                    if queryRes {
                                        VStack(spacing: 20) {
                                            ForEach(0..<friendSelections.count, id:\.self) { i in
                                                if friendSelections[i].friend.username.hasPrefix(searchQuery) {
                                                    HStack {
                                                        VStack(alignment: .leading) {
                                                            Text(friendSelections[i].friend.name)
                                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                                .font(.title3)
                                                                .bold()
                                                            Text(friendSelections[i].friend.username)
                                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                            
                                                        }
                                                        
                                                        Spacer()
                                                        
                                                        Button(action: {
                                                            if friendSelections[i].isSelected {
                                                                selectedFriends.removeAll { friend in
                                                                    friend.username == friendSelections[i].friend.username
                                                                }
                                                            }
                                                            else {
                                                                selectedFriends.append(friendSelections[i].friend)
                                                            }
                                                            
                                                            withAnimation(.spring(duration: 0.4, bounce: 0.3)) {
                                                                friendSelections[i].isSelected.toggle()
                                                            }
                                                            
                                                        }) {
                                                            Image(systemName: friendSelections[i].isSelected ? "checkmark.circle" : "circle")
                                                                .resizable()
                                                                .aspectRatio(contentMode: .fit)
                                                                .frame(width: 23, height: 25)
                                                                .gradientForeground(colors: [Color(hex: "b597f6"), Color(hex: "96c6ea")], startPoint: .bottomLeading, endPoint: .topTrailing)
                                                        }
                                                        .foregroundColor(Color.black)
                                                    }
                                                    .onTapGesture {
                                                        
                                                        if friendSelections[i].isSelected {
                                                            selectedFriends.removeAll { friend in
                                                                friend.username == friendSelections[i].friend.username
                                                            }
                                                        }
                                                        else {
                                                            selectedFriends.append(friendSelections[i].friend)
                                                        }
                                                        
                                                        withAnimation(.spring(duration: 0.4, bounce: 0.3)) {
                                                            friendSelections[i].isSelected.toggle()
                                                        }
                                                    }
                                                }
                                                
                                            }
                                        } //: VStack
                                        .overlay(GeometryReader { geo in
                                            let currentScrollViewPosition = -geo.frame(in: .named("scrollview")).origin.y
                                            
                                            if currentScrollViewPosition < -amountBeforeRefreshing && !isRefreshing {
                                                Color.clear.preference(key: FriendGroupKey.self, value: -geo.frame(in: .global).origin.y)
                                            }
                                        })
                                        .opacity(isRefreshing ? 0.4 : 1)
                                    }
                                    else {
                                        VStack {
                                            Spacer()
                                            Text("No friends found!")
                                                .gradientForeground(colors: [Color(hex: "b597f6"), Color(hex: "96c6ea")], startPoint: .bottomLeading, endPoint: .topTrailing)
                                                .italic()
                                            Spacer()
                                        }
                                        .frame(width: scrollGeo.size.width)
                                        .frame(minHeight: scrollGeo.size.height)
                                        .overlay(GeometryReader { geo in
                                            let currentScrollViewPosition = -geo.frame(in: .named("scrollview")).origin.y
                                            
                                            if currentScrollViewPosition < -amountBeforeRefreshing && !isRefreshing {
                                                Color.clear.preference(key: FriendGroupKey.self, value: -geo.frame(in: .global).origin.y)
                                            }
                                        })
                                        .opacity(isRefreshing ? 0.4 : 1)
                                    }
                                }
                            } //: ScrollView
                            .scrollIndicators(.hidden)
                            .coordinateSpace(name: "scrollview")
                            .onPreferenceChange(FriendGroupKey.self) { scrollPosition in
                                if scrollPosition < -amountBeforeRefreshing && !isRefreshing {
                                    isRefreshing = true
                                    Task {
                                        try? await Task.sleep(nanoseconds: 500_000_000)
                                        
                                        await loadFriends()
                                        loadQuery()
                                        
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
                                :
                                    nil
                                , alignment: .center)
                            
                        }
                    }
                    
                    Button(action: {
                        // TODO: CREATE GROUP
                    }, label: {
                        Text("Create Group")
                            .frame(maxWidth: .infinity)
                            .padding(20)
                            .font(.title2)
                            .bold()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(LinearGradient(colors: [Color(hex: "b597f6"), Color(hex: "96c6ea")], startPoint: .leading, endPoint: .trailing))
                            )
                            .foregroundStyle(.white)
                            .disabled(selectedFriends.isEmpty)
                            .opacity(selectedFriends.isEmpty ? 0.5 : 1)
                    })
                    
                    Spacer()
                    
                }
                .padding(.top, 10)
                .padding(.horizontal, 25)
                .ignoresSafeArea(.keyboard)
            } //: ZStack
            .onAppear {
                Task {
                    await loadFriends()
                }
            }
            .onChange(of: searchQuery) { _ in
                loadQuery()
            }
            .toast(isPresenting: $isError, duration: 3, alert: {
                AlertToast(displayMode: .hud, type: .error(Color(hex: "ff5858")), subTitle: errorMsg)
            })
        }
    }
}

//#Preview {
//    AddingGroupView()
//}
