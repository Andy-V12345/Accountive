//
//  FriendGroupPanel.swift
//  Training Reminder
//
//  Created by Andy Vu on 12/15/23.
//

import SwiftUI

struct FriendGroupPanel: View {
    
    @State var friendGroup: FriendGroup
    
    @Binding var isDeleting: String?
    
    @EnvironmentObject var authState: AuthState
    
    @Namespace var namespace
    
    @State var isUpdating = false
    @Binding var updatingViews: Int
    @FocusState var isNameFocused
    
    @State var newName = ""
    @State var friendSelections: [FriendGroupSelection] = []
    @State var selectedFriends: [Friend] = []
    
    @State var searchQuery = ""
    @State var queryRes = true
    @State var showingCancel = false
    
    @State var isLoadingFriends = false
    @State var isRefreshing = false
    
    let firebaseService = FirebaseService()
    
    
    let amountBeforeRefreshing: CGFloat = 100
    
    func loadQuery() {
        queryRes = friendSelections.contains { friendSelection in
            friendSelection.friend.username.hasPrefix(searchQuery)
        }
    }
    
    func loadFriends() async {
        do {
            
            isLoadingFriends = true
            
            for friend in selectedFriends {
                let res = friendSelections.contains { value in
                    value.friend.uid == friend.uid
                }
                
                if !res {
                    friendSelections.append(FriendGroupSelection(friend: friend, isSelected: true))
                }
            }
            
            let friends = try await firebaseService.getFriends(uid: authState.user!.uid)
            
            for friend in friends {
                
                let isSelected = selectedFriends.contains { value in
                    value.uid == friend.uid
                }
                
                let res = friendSelections.contains { value in
                    value.friend.uid == friend.uid
                }
                
                if !res {
                    friendSelections.append(FriendGroupSelection(friend: friend, isSelected: isSelected))
                }
            }
            
            isLoadingFriends = false
        }
        catch {
            print("error loading friends")
        }
    }
    
    var body: some View {
        ZStack {
            if !isUpdating {
                HStack(spacing: 20) {
                    
                    DisclosureGroup(content: {
                        
                        Divider()
                            .overlay(
                                LinearGradient(colors: [Color(hex: "b597f6"), Color(hex: "96c6ea")], startPoint: .leading, endPoint: .trailing)
                            )
                            .matchedGeometryEffect(id: "divider", in: namespace)
                        
                        VStack(spacing: 3) {
                            Text("Friends")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .multilineTextAlignment(.leading)
                                .padding(.top, 5)
                                .matchedGeometryEffect(id: "friendsLabel", in: namespace)
                            
                            ForEach(0..<friendGroup.friends.count, id:\.self) { i in
                                Text(friendGroup.friends[i].username)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            
                        }
                    },
                                    label: {
                        Text("\(friendGroup.name)")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .multilineTextAlignment(.leading)
                            .matchedGeometryEffect(id: "name", in: namespace)
                    })
                    .foregroundColor(.black)
                    .accentColor(.black)
                    
                    Button(action: {
                        withAnimation(.spring(duration: 0.4, bounce: 0.3)) {
                            updatingViews += 1
                        }
                        
                        withAnimation(.spring(duration: 0.4)) {
                            isUpdating.toggle()
                            isNameFocused = true
                        }
                    }, label: {
                        Image(systemName: "pencil")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 18, height: 25)
                            .gradientForeground(colors: [Color(hex: "b597f6"), Color(hex: "96c6ea")], startPoint: .leading, endPoint: .trailing)
                            .bold()
                        
                    })
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.spring(bounce: 0.15)) {
                            isDeleting = friendGroup.id
                        }
                    }, label: {
                        Image(systemName: "trash")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 18, height: 25)
                            .gradientForeground(colors: [Color(hex: "f83d5c"), Color(hex: "fd4b2f")], startPoint: .bottomLeading, endPoint: .topTrailing)
                    })
                    
                }
                .frame(maxWidth: .infinity)
                .padding(20)
                .background(Color.gray.opacity(0.05).matchedGeometryEffect(id: "background", in: namespace))
                .cornerRadius(15)
            }
            else {
                VStack(spacing: 25) {
                    VStack {
                        TextField(newName, text: $newName)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fontWeight(.semibold)
                            .font(.title3)
                            .foregroundColor(.black)
                            .multilineTextAlignment(.leading)
                            .matchedGeometryEffect(id: "name", in: namespace)
                            .submitLabel(.done)
                            .focused($isNameFocused)
                        
                        
                        Divider()
                            .overlay(
                                LinearGradient(colors: [Color(hex: "b597f6"), Color(hex: "96c6ea")], startPoint: .leading, endPoint: .trailing)
                            )
                            .matchedGeometryEffect(id: "divider", in: namespace)
                        
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Friends")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .foregroundColor(.black)
                                .bold()
                                .matchedGeometryEffect(id: "friendsLabel", in: namespace)
                            
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
                                        .font(.callout)
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                })
                                .frame(width: showingCancel ? 75 : 0)
                            }
                            
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
                                }
                                else {
                                    if queryRes {
                                        VStack(spacing: 15) {
                                            ForEach(0..<friendSelections.count, id:\.self) { i in
                                                if friendSelections[i].friend.username.hasPrefix(searchQuery) {
                                                    HStack {
                                                        VStack(alignment: .leading) {
                                                            Text(friendSelections[i].friend.name)
                                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                                .font(.headline)
                                                                .bold()
                                                            Text(friendSelections[i].friend.username)
                                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                                .font(.subheadline)
                                                            
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
                                                                .frame(width: 20, height: 20)
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
                        .frame(maxWidth: .infinity)
                    }
                                        
                    HStack {
                        Button(action: {
                            
                            withAnimation(.spring(duration: 0.3, bounce: 0.3)) {
                                updatingViews -= 1
                            }
                            
                            withAnimation(.spring(duration: 0.3)) {
                                hideKeyboard()
                                isUpdating.toggle()
                                isNameFocused = false
                            }
                        }, label: {
                            Image(systemName: "xmark")
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .center)
                        })
                        
                        Spacer()
                        
                        Button(action: {
                            // TODO: UPDATE ACTIVITY
                            
                            hideKeyboard()
                            //                                activity.name = newName
                            //                                activity.description = newDescription
                            //                                firebaseService.updateActivityByDay(newActivity: activity, uid: authState.user!.uid)
                            //
                            withAnimation(.spring(duration: 0.3, bounce: 0.3)) {
                                updatingViews -= 1
                            }
                            
                            withAnimation(.spring(duration: 0.3)) {
                                isUpdating = false
                            }
                            
                        }, label: {
                            Image(systemName: "checkmark")
                                .foregroundColor(.green)
                                .frame(maxWidth: .infinity, alignment: .center)
                        })
                        
                    } //: HStack
                }
                .frame(height: 400)
                .padding(20)
                .background(Color.gray.opacity(0.05).matchedGeometryEffect(id: "background", in: namespace))
                .cornerRadius(15)
                .onAppear {
                    searchQuery = ""
                    showingCancel = false
                    Task {
                        await loadFriends()
                    }
                }
            }
        } //: ZStack
        .onAppear {
            newName = friendGroup.name
            selectedFriends = friendGroup.friends
        }
        .onChange(of: searchQuery) { _ in
            loadQuery()
        }
    }
}

//#Preview {
//    FriendGroupPanel(friendGroup: FriendGroup(id: "1", name: "real ones", friends: [Friend(name: "Nam", username: "nammy", status: "FRIEND"), Friend(name: "Andy", username: "andy.v", status: "FRIEND")]))
//}
