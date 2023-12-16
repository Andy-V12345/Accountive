//
//  GroupsView.swift
//  Training Reminder
//
//  Created by Andy Vu on 12/15/23.
//

import SwiftUI

class FriendGroup: Hashable {
    var id: String
    var name: String
    var friends: [Friend]
    
    init(id: String?, name: String, friends: [Friend]) {
        self.id = id ?? ""
        self.name = name
        self.friends = friends
    }
    
    static func == (lhs: FriendGroup, rhs: FriendGroup) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct GroupsView: View {
    
    @EnvironmentObject var authState: AuthState
    
    @State var friendGroups: [FriendGroup] = []
    
    @State var isAddingGroup = false
    
    @State var isDeleting: String? = nil
    @State var isDeleted: String?
    @State var changeHeight: String?
    @State var deleteIndex: Int?
    
    @State var isLoading = false
    
    let firebaseService = FirebaseService()
    
    var body: some View {
        GeometryReader { screen in
            ZStack {
                Color.white.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    
                    Button(action: {
                        isAddingGroup = true
                    }, label: {
                        HStack(spacing: 10) {
                            Text("Create a Group")
                                .font(.title3)
                                .foregroundColor(.white)
                            Image(systemName: "plus")
                                .font(.title3)
                                .foregroundColor(.white)
                        }
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 25)
                        .padding(.horizontal, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(LinearGradient(colors: [Color(hex: "b597f6"), Color(hex: "96c6ea")], startPoint: .bottomLeading, endPoint: .topTrailing))
                        )
                        
                    })
                    
                    
                    GeometryReader { scrollGeo in
                        ScrollView(.vertical) {
                            if isLoading {
                                VStack {
                                    Spacer()
                                    ProgressView()
                                        .tint(Color(hex: "A6AEF0"))
                                        .frame(width: 300)
                                        .controlSize(.regular)
                                    Spacer()
                                }
                                .frame(width: scrollGeo.size.width)
                                .frame(minHeight: scrollGeo.size.height - 100)
                            }
                            else {
                                if friendGroups.isEmpty {
                                    VStack {
                                        Text("Add a group!")
                                            .gradientForeground(colors: [Color(hex: "b597f6"), Color(hex: "96c6ea")], startPoint: .bottomLeading, endPoint: .topTrailing)
                                            .italic()
                                    }
                                    .frame(width: scrollGeo.size.width)
                                    .frame(minHeight: scrollGeo.size.height - 100)
                                }
                                else {
                                    VStack(spacing: 10) {
                                        ForEach(Array(friendGroups.enumerated()), id:\.element) { offset, friendGroup in
                                            ZStack {
                                                
                                                FriendGroupPanel(friendGroup: friendGroup, isDeleting: $isDeleting)
                                                    .opacity(isDeleting == friendGroup.id ? 0 : 1)
                                                
                                                // MARK: DELETE FRIEND GROUP
                                                
                                                HStack(spacing: 15) {
                                                    if isDeleting == friendGroup.id {
                                                        
                                                        Image(systemName: "chevron.right")
                                                            .foregroundColor(.white)
                                                            .onTapGesture {
                                                                withAnimation(.spring()) {
                                                                    isDeleting = nil
                                                                }
                                                                
                                                                deleteIndex = nil
                                                            }
                                                        
                                                        Text("Delete this group?")
                                                            .foregroundColor(.white)
                                                            .bold()
                                                        
                                                        Spacer()
                                                        
                                                        
                                                        Spacer()
                                                        
                                                        HStack(spacing: 30) {
                                                            Image(systemName: "checkmark")
                                                                .foregroundColor(.white)
                                                                .onTapGesture {
                                                                    Task {
                                                                        
                                                                        withAnimation(.linear(duration: 0.3)) {
                                                                            isDeleted = friendGroup.id
                                                                        }
                                                                        
                                                                        deleteIndex = offset
                                                                        
                                                                        withAnimation(.spring(dampingFraction: 0.55).delay(0.3)) {
                                                                            changeHeight = friendGroup.id
                                                                        }
                                                                        
                                                                        do {
                                                                            
                                                                            
                                                                            try await Task.sleep(nanoseconds: UInt64(1.5) * 1_000_000_000)
                                                                            
                                                                            
                                                                            isDeleting = nil
                                                                            
                                                                            friendGroups.removeAll { value in
                                                                                value.id == friendGroup.id
                                                                            }
                                                                            
                                                                            isDeleted = nil
                                                                            changeHeight = nil
                                                                            deleteIndex = nil
                                                                            
                                                                        }
                                                                        catch {
                                                                            //                                                                        errorMsg = "Error deleting activity"
                                                                            //                                                                        isError = true
                                                                        }
                                                                        
                                                                    }
                                                                }
                                                            
                                                            Image(systemName: "xmark")
                                                                .foregroundColor(.white)
                                                                .onTapGesture {
                                                                    withAnimation(.spring()) {
                                                                        isDeleting = nil
                                                                    }
                                                                    
                                                                    deleteIndex = nil
                                                                }
                                                        }
                                                        
                                                    }
                                                }
                                                .padding(.horizontal, 20)
                                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                                .background(LinearGradient(colors: [Color(hex: "f83d5c"), Color(hex: "fd4b2f")], startPoint: .bottomLeading, endPoint: .topTrailing))
                                                .cornerRadius(15)
                                                .offset(x: isDeleting == friendGroup.id ? 0 : 500)
                                                .opacity(isDeleting == friendGroup.id ? 1 : 0)
                                                
                                            } //: ZStack
                                            .offset(x: isDeleted == friendGroup.id ? 500 : 0)
                                            .offset(y: changeHeight != nil && changeHeight! != friendGroup.id && (deleteIndex != nil && deleteIndex! < offset) ? -10 : 0)
                                            .frame(maxHeight: changeHeight == friendGroup.id ? 0 : .infinity)
                                            
                                        }
                                        
                                    } //: VStack
                                }
                            }
                        }
                    }
                    
                    Spacer()
                    
                    
                } //: VStack
                .ignoresSafeArea(.keyboard)
            } //: ZStack
            .onAppear {
                Task {
                    do {
                        isLoading = true
                        friendGroups = try await firebaseService.getFriendGroups(uid: authState.user!.uid)
                        isLoading = false
                    }
                    catch {
                        
                    }
                }
            }
            .onTapGesture {
                hideKeyboard()
            }
            .fullScreenCover(isPresented: $isAddingGroup, content: {
                AddingGroupView()
                    .environmentObject(authState)
            })
        } //: GeometryReader
       
    }
}

//#Preview {
//    VStack(spacing: 15) {
//        HStack {
//            Image(systemName: "arrow.right")
//                .hidden()
//            Spacer()
//
//            Text("ACCOUNTIVE")
//                .frame(maxWidth: .infinity, alignment: .center)
//                .gradientForeground(colors: [Color(hex: "b597f6"), Color(hex: "96c6ea")], startPoint: .bottomLeading, endPoint: .topTrailing)
//                .font(.system(size: 30))
//                .fontWidth(.condensed)
//                .bold()
//
//            Spacer()
//
//            Button(action: {
//                AppState.shared.showSocial = false
//            }, label: {
//                Image(systemName: "xmark")
//                    .font(.title3)
//                    .foregroundColor(.black)
//            })
//        } //: Header HStack
//        GroupsView()
//    }
//    .padding(.horizontal, 20)
//    .padding(.top, 10)
//}
