//
//  EditingActivityView.swift
//  Training Reminder
//
//  Created by Andy Vu on 9/11/23.
//

import SwiftUI
import AlertToast

struct EditingActivityView: View {
    
    @Environment(\.dismiss) var dismiss
    
    let days = [
        "Sunday",
        "Monday",
        "Tuesday",
        "Wednesday",
        "Thursday",
        "Friday",
        "Saturday"
    ]
    
    @State var activity: Activity
    
    @State var activityName: String
    @State var activityDescription: String
    
    @State var isLoading = false
    
    var preSelectedDays: [String]
    
    @State var buttonsSelected = Array(repeating: false, count: 7)
    
    @State var isSuccess = false
    
    @EnvironmentObject var authState: AuthState
    
    @State var friendGroups: [FriendGroup] = []
    @State var selectedGroupId: String? = nil
    
    let firebaseService = FirebaseService()
    
    var body: some View {
        
        GeometryReader { screen in
            ZStack {
                Color.white.ignoresSafeArea()
                
                
                VStack(spacing: 60) {
                    VStack(spacing: 25) {
                        
                        Text("Edit Activity")
                            .foregroundColor(.black)
                            .font(.largeTitle)
                            .bold()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    
                        HStack(spacing: 20) {
                            Image(systemName: "pencil")
                                .foregroundColor(.gray)
                                .bold()
                            CustomTextField(placeholder: Text("Enter activity title").foregroundColor(.gray), text: $activityName, isSecure: false)
                                .frame(height: 50)
                            
                        }
                        .overlay(
                            Divider()
                                .padding(.vertical, 0)
                                .frame(maxWidth: .infinity, maxHeight:1)
                                .background(LinearGradient(colors: [Color(hex: "b597f6"), Color(hex: "96c6ea")], startPoint: .leading, endPoint: .trailing)), alignment: .bottom)
                        
                        // Details textfield
                        
                        HStack(spacing: 20) {
                            Image(systemName: "info.circle")
                                .foregroundColor(.gray)
                                .bold()
                            CustomTextField(placeholder: Text("Enter details (optional)").foregroundColor(.gray), text: $activityDescription, isSecure: false)
                                .frame(height: 50)
                            
                        }
                        .overlay(
                            Divider()
                                .padding(.vertical, 0)
                                .frame(maxWidth: .infinity, maxHeight:1)
                                .background(LinearGradient(colors: [Color(hex: "b597f6"), Color(hex: "96c6ea")], startPoint: .leading, endPoint: .trailing)), alignment: .bottom)
                        
                        VStack(spacing: screen.size.height < 700 ? 5 : 10) {
                            Text("Change days?")
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 20) {
                                    ForEach(0...6, id:\.self) { i in
                                        Button(action: {
                                            buttonsSelected[i].toggle()
                                        }, label: {
                                            Text(days[i].prefix(3))
                                                .foregroundColor(buttonsSelected[i] ? .white : .black)
                                                .padding(.horizontal, 20)
                                                .padding(.vertical, 10)
                                                .background(
                                                    buttonsSelected[i] ?
                                                        Color(hex: "A6AEF0")
                                                    :
                                                        Color(hex: "F8F9FA")
                                                )
                                                .animation(.easeInOut, value: buttonsSelected[i])
                                                .cornerRadius(10)
                                        })
                                    
                                    }
                                }
                            }
                        }
                        
                        VStack(spacing: screen.size.height < 700 ? 5 : 10) {
                            Text("Select a group?")
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            if friendGroups.count > 0 {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 20) {
                                        ForEach(friendGroups, id:\.self) { friendGroup in
                                            Button(action: {
                                                if selectedGroupId == nil || selectedGroupId! != friendGroup.id {
                                                    selectedGroupId = friendGroup.id
                                                }
                                                else if selectedGroupId! == friendGroup.id {
                                                    selectedGroupId = nil
                                                }
                                            }, label: {
                                                Text(friendGroup.name)
                                                    .foregroundColor((selectedGroupId != nil && selectedGroupId! == friendGroup.id) ? .white : .black)
                                                    .padding(.horizontal, 20)
                                                    .padding(.vertical, 8)
                                                    .background(
                                                        (selectedGroupId != nil && selectedGroupId! == friendGroup.id) ?
                                                            Color(hex: "A6AEF0")
                                                        :
                                                            Color(hex: "F8F9FA")
                                                    )
                                                    .cornerRadius(10)
                                            })
                                        }
                                        
                                    }
                                }
                            }
                            else {
                                Text("You have no friend groups")
                                    .font(.footnote)
                                    .foregroundStyle(.gray)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .italic()
                            }
                        }
                    } //: VStack
                    
                    VStack(spacing: 12) {
                        
                        Button(action: {
                            // MARK: UPDATE ACTIVITY
                            Task {
                                
                                do {
                                    
                                    isLoading = true
                                    
                                    var selectedDays: [String] = []
                                    var unsubscribeDays: [String] = []
                                                                    
                                    hideKeyboard()
                                    
                                    for i in 0..<buttonsSelected.count {
                                        if buttonsSelected[i] {
                                            selectedDays.append(days[i])
                                        }
                                    }
                                    
                                    let _ = try await firebaseService.updateActivity(activity: Activity(id: activity.id, name: activityName, description: activityDescription, isDone: false, day: activity.day, groupPath: activity.groupPath, friendGroupId: selectedGroupId), days: selectedDays, uid: authState.user!.uid)
                                    
                                    for day in days {
                                        if await firebaseService.getNumActivities(day: day, uid: authState.user!.uid) == 0 {
                                            unsubscribeDays.append(day)
                                        }
                                    }
                                    
                                    try await firebaseService.subscribeToTopic(fcmToken: UserDefaults.standard.string(forKey: "fcmKey")!, days: selectedDays)
                                    firebaseService.addSubscriptions(days: selectedDays, uid: authState.user!.uid)
                                    
                                    try await firebaseService.unsubscribeFromTopic(fcmToken: UserDefaults.standard.string(forKey: "fcmKey")!, days: unsubscribeDays)
                                    firebaseService.removeSubscriptions(days: unsubscribeDays, uid: authState.user!.uid)
                                    
                                    isLoading = false
                                    
                                    isSuccess = true
                                    
                                }
                                
                            }
                        
                        
                        }, label: {
                            Image(systemName: "checkmark")
                                .foregroundColor(.white)
                                .font(screen.size.height < 736 ? .title2 : .title)
                                .padding(.vertical, 20)
                                .frame(maxWidth: .infinity)
                                .background(LinearGradient(colors: [Color(hex: "b597f6"), Color(hex: "96c6ea")], startPoint: .bottomLeading, endPoint: .topTrailing))
                                .cornerRadius(10)
                        })
                        .opacity(activity.name.trimmingCharacters(in: .whitespacesAndNewlines).count == 0 || buttonsSelected == Array(repeating: false, count: 7) ? 0.5 : 1)
                        .disabled(activity.name.trimmingCharacters(in: .whitespacesAndNewlines).count == 0 || buttonsSelected == Array(repeating: false, count: 7))
                        
                        Text("or")
                            .foregroundColor(.black)
                        
                        Text("Cancel")
                            .gradientForeground(colors: [Color(hex: "b597f6"), Color(hex: "96c6ea")], startPoint: .bottomLeading, endPoint: .topTrailing)
                            .italic()
                            .onTapGesture {
                                dismiss()
                            }
                    }
                    
                    Spacer()
                } //: VStack
                .padding(.horizontal, 25)
                .padding(.top, 40)
                .onAppear {
                    for day in preSelectedDays {
                        buttonsSelected[days.firstIndex(of: day)!] = true
                    }
                    
                    selectedGroupId = activity.friendGroupId
                }
                .opacity(isLoading ? 0.15 : 1)
                .animation(.linear(duration: 0.5), value: isLoading)
                
                if isLoading {
                    VStack {
                        Spacer()
                        ProgressView()
                            .tint(Color(hex: "A6AEF0"))
                            .frame(width: 300)
                            .controlSize(ControlSize.large)
                        Spacer()
                    }
                }
                
            } //: ZStack
            .toast(isPresenting: $isSuccess, duration: 1.5, alert: {
                AlertToast(displayMode: .alert, type: .complete(.green), title: "Updated")
            })
            .onChange(of: isSuccess) { newValue in
                if isSuccess == false {
                    dismiss()
                }
            }
            .onTapGesture {
                hideKeyboard()
            }
        }
        .ignoresSafeArea(.keyboard)
    }
}

//struct EditingPreview: PreviewProvider {
//    static var previews: some View {
//        EditingActivityView(activity: Activity(id: "", name: "bruh", description: "", isDone: false, day: "Monday", groupPath: ""), activityName: "Run", activityDescription: "", preSelectedDays: ["Monday"])
//    }
//}

