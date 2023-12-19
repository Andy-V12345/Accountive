//
//  ActivityLabel.swift
//  Training Reminder
//
//  Created by Andy Vu on 9/4/23.
//

import SwiftUI

struct ActivityLabel: View {
    
    // MARK: PROPERTY
    
    @State var activity: Activity
    
    @Binding var doneCount: Int?
    @Binding var allDone: Bool
    @State var totalCount: Int
    
    @Binding var isDeleting: String?
    @Binding var changeHeight: String?
    @Binding var deleteIndex: Int?
    
    
    @Binding var updatingViews: Int

    
    @State var isUpdating = false
    
    @State var showAlert = false
    
    @EnvironmentObject var authState: AuthState
    
    @Namespace var namespace
    
    @FocusState var isNameFocused
    @FocusState var isDescriptionFocused
    
    @State var newName = ""
    @State var newDescription = ""
    
    @State var friendGroups: [FriendGroup] = []
    @State var selectedGroupId = ""
    
    @State var listener: Any? = nil
    
    let firebaseService = FirebaseService()
    
    let days = [
        "Sunday",
        "Monday",
        "Tuesday",
        "Wednesday",
        "Thursday",
        "Friday",
        "Saturday"
    ]
    
    @State var dayIndex = Calendar.current.component(.weekday, from: Date())
    
    
    func getFriendGroupName(groupId: String) -> String? {
        let group = friendGroups.first(where: {$0.id == groupId})
        
        return group?.name
    }
        
    // MARK: BODY
    var body: some View {
        ZStack {
            if !isUpdating {
                
                // MARK: NORMAL ACTIVITY LABEL
                
                HStack(alignment: .center, spacing: 20) {
                    Button(action: {
                        if activity.isDone == false {
                            if !UserDefaults.standard.bool(forKey: "isAlerted") {
                                showAlert = true
                            }
                            else {
                                markActivity()
                            }
                        }
                        
                    }) {
                        Image(systemName: activity.isDone ? "checkmark.square" : "square")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 25)
                            .gradientForeground(colors: [Color(hex: "b597f6"), Color(hex: "96c6ea")], startPoint: .bottomLeading, endPoint: .topTrailing)
                    }
                    .foregroundColor(Color.black)
                    .disabled(activity.isDone)
                    
                    DisclosureGroup(content: {
                        Divider()
                            .overlay(
                                LinearGradient(colors: [Color(hex: "b597f6"), Color(hex: "96c6ea")], startPoint: .leading, endPoint: .trailing)
                            )
                            .matchedGeometryEffect(id: "divider", in: namespace)
                        
                        VStack(alignment: .leading, spacing: 3) {
                            
                            Text(.init("**Group:** \(getFriendGroupName(groupId: activity.friendGroupId ?? "") ?? "None")"))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .font(.headline)
                                .fontWeight(.regular)
                                .matchedGeometryEffect(id: "groupLabel", in: namespace)
                            
                            Text("Description:")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .bold()
                                .matchedGeometryEffect(id: "descriptionLabel", in: namespace)
                            
                            Text(activity.description == "" ? "None" : activity.description)
                                .font(.body)
                                .fontWeight(.regular)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .multilineTextAlignment(.leading)
                                .matchedGeometryEffect(id: "description", in: namespace)
                        }
                        .frame(maxWidth: .infinity)
                        
                    }, label: {
                        Text(activity.name)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fontWeight(.semibold)
                            .font(.title3)
                            .foregroundColor(.black)
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
                            .gradientForeground(colors: [Color(hex: "b597f6"), Color(hex: "96c6ea")], startPoint: .leading, endPoint: .trailing)
                            .bold()
                            .frame(maxHeight: .infinity)
                        
                    })
                    Spacer()
                    
                    Button(action: {
                        // MARK: DELETE ACTIVITY
                        withAnimation(.spring(bounce: 0.15)) {
                            isDeleting = activity.id
                        }
                    }, label: {
                        Image(systemName: "trash")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 25)
                            .gradientForeground(colors: [Color(hex: "f83d5c"), Color(hex: "fd4b2f")], startPoint: .bottomLeading, endPoint: .topTrailing)
                    })
                    
                }
                .alert("FYI", isPresented: $showAlert) {
                    Button(role: .cancel) {
                        // TODO: MARK ACTIVITY AS DONE
                        UserDefaults.standard.set(true, forKey: "isAlerted")
                        markActivity()
                    } label: {
                        Text("Ok")
                    }
                    
                    Button(role: .destructive) {
                        UserDefaults.standard.set(true, forKey: "isAlerted")
                    } label: {
                        Text("Cancel")
                    }
                    
                } message: {
                    Text("Once you mark an activity, you can't unmark it for the rest of the day!")
                }
                .padding(.vertical, 20)
                .padding(.horizontal, 20)
                .background(Color.gray.opacity(0.05).matchedGeometryEffect(id: "background", in: namespace))
                .cornerRadius(15)
            }
            else {
                
                // MARK: UPDATING LABEL
                
                VStack(spacing: 25) {
                    VStack(spacing: 8) {
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
                            
                            VStack(spacing: 5) {
                                Text("Select a group?")
                                    .bold()
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .matchedGeometryEffect(id: "groupLabel", in: namespace)
                                if friendGroups.count > 0 {
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 20) {
                                            ForEach(friendGroups, id:\.self) { friendGroup in
                                                Button(action: {
                                                    if selectedGroupId == "" || selectedGroupId != friendGroup.id {
                                                        selectedGroupId = friendGroup.id
                                                    }
                                                    else if selectedGroupId == friendGroup.id {
                                                        selectedGroupId = ""
                                                    }
                                                }, label: {
                                                    Text(friendGroup.name)
                                                        .font(.callout)
                                                        .foregroundColor(.white)
                                                        .padding(.horizontal, 20)
                                                        .padding(.vertical, 8)
                                                        .background(Color(hex: "A8AABD"))
                                                        .cornerRadius(10)
                                                        .opacity(selectedGroupId != "" && selectedGroupId == friendGroup.id ? 0.3 : 1)
                                                })
                                            }
                                            
                                        }
                                    }
                                }
                                else {
                                    Text("You have no friend groups")
                                        .font(.callout)
                                        .foregroundStyle(.gray)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .italic()
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Description:")
                                    .font(.body)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .foregroundColor(.black)
                                    .bold()
                                    .matchedGeometryEffect(id: "descriptionLabel", in: namespace)
                                
                                CustomTextField(placeholder: Text("No description").italic().foregroundColor(.gray), text: $newDescription, isSecure: false)
                                    .font(.callout)
                                    .fontWeight(.regular)
                                    .matchedGeometryEffect(id: "description", in: namespace)
                                
                            }
                            .frame(maxWidth: .infinity)
                        }
                    
                        HStack {
                            Button(action: {
                                
                                withAnimation(.spring(duration: 0.4, bounce: 0.3)) {
                                    updatingViews -= 1
                                }
                                
                                withAnimation(.spring(duration: 0.4)) {
                                    hideKeyboard()
                                    isUpdating.toggle()
                                    isNameFocused = false
                                    isDescriptionFocused = false
                                }
                            }, label: {
                                Image(systemName: "xmark")
                                    .foregroundColor(.red)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            })
                            
                            Spacer()
                            
                            Button(action: {
                                // MARK: UPDATE ACTIVITY
                                hideKeyboard()
                                activity.name = newName
                                activity.description = newDescription
                                activity.friendGroupId = selectedGroupId
                                firebaseService.updateActivityByDay(newActivity: activity, uid: authState.user!.uid)
                                
                                withAnimation(.spring(duration: 0.4, bounce: 0.3)) {
                                    updatingViews -= 1
                                }
                                
                                withAnimation(.spring(duration: 0.4)) {
                                    isUpdating = false
                                }
                                
                            }, label: {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.green)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            })
                            .opacity(newName.trimmingCharacters(in: .whitespacesAndNewlines).count == 0 ? 0.4 : 1)
                            .disabled(newName.trimmingCharacters(in: .whitespacesAndNewlines).count == 0)

                        }
                    }
                    .padding(20)
                    .background(Color.gray.opacity(0.05).matchedGeometryEffect(id: "background", in: namespace))
                    .cornerRadius(15)
            }
        }
        .onAppear {
            newName = activity.name
            newDescription = activity.description
            selectedGroupId = activity.friendGroupId ?? ""
            
            activity.printActivity()
        }
        .onDisappear { // MARK: LEAVE HERE TO FORCE ACTIVITY LABEL TO REFRESH FRIEND GROUP
        }
        
    }
    
    func markActivity() {
        doneCount! += 1
        activity.isDone = true
        if doneCount == totalCount {
            allDone = true
        }
        firebaseService.markActivity(activityId: activity.id, uid: authState.user!.uid)
        Task {
            do {
                if activity.friendGroupId == nil || activity.friendGroupId == "" {
                    try await firebaseService.notifyFriends(uid: authState.user!.uid, username: authState.getUsername(), task: activity.name)
                }
                else {
                    try await firebaseService.notifyFriendGroup(groupId: activity.friendGroupId!, username: authState.getUsername(), task: activity.name)
                }
            }
            catch {
                
            }
        }
    }
}

//struct ActivityLabel_Preview: PreviewProvider {
//    static var previews: some View {
//        ActivityLabelPreview()
//    }
//}

