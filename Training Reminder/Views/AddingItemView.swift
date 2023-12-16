//
//  AddingItemView.swift
//  Training Reminder
//
//  Created by Andy Vu on 9/7/23.
//

import SwiftUI
import AlertToast
import UIKit
import FirebaseMessaging

func hideKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
}

struct AddingItemView: View {
    
    // MARK: PROPERTIES
    
    let days = [
        "Sunday",
        "Monday",
        "Tuesday",
        "Wednesday",
        "Thursday",
        "Friday",
        "Saturday"
    ]
    
    @State var buttonsSelected = Array(repeating: false, count: 7)
    
    @State var dayIndex: Int = Calendar.current.component(.weekday, from: Date())
    
    @Environment(\.dismiss) var dismiss
    
    @State var activityName = ""
    @State var activityDescription = ""
    
    @State var activities: [Activity] = []
    
    @State var isLoading = false
    
    @EnvironmentObject var authState: AuthState
    
    @State var errorMsg = ""
    @State var isError = false
    
    @State var selectedIndex: Int?
    
    @State var isEditing = false
    
    @State var isDeleting: String?
    @State var isDeleted: String?
    @State var changeHeight: String?
    @State var deleteIndex: Int?
    
    @State var preSelectedDaysForEditing: [String] = []
    
    @State var refresh = false
    
    @State var isAddEnabled = false
    
    @State var isAdding = false

    
    let firebaseService = FirebaseService()
    
    
    func getActivities() {
        isLoading = true

        Task {
            activities = await firebaseService.getAllActivities(uid: authState.user!.uid)
            isDeleting = nil
            isDeleted = nil
            changeHeight = nil
            deleteIndex = nil
            preSelectedDaysForEditing = []
            isLoading = false
        }
    }
    
    
    // MARK: BODY
    
    var body: some View {
        GeometryReader { screen in
            ZStack {
                Color.white.ignoresSafeArea()


                VStack(spacing: 10) {
                    HStack {
                        Spacer()
                        Button(action: {
                            dismiss()
                        }, label: {
                            Image(systemName: "xmark")
                                .font(.title3)
                                .foregroundStyle(.black)
                        })
                    }

                    VStack(spacing: screen.size.height < 700 ? 5 : 10) {
                        //  MARK: HORIZONTAL SCROLLER
                        ScrollViewReader { index in
                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHStack(alignment: .center, spacing: 30) {
                                    Spacer()
                                    ForEach(0...6, id:\.self) { i in
                                        Text(days[i].prefix(3))
                                            .foregroundColor(.black)
                                            .bold()
                                            .font(screen.size.height < 736 ? .title2 : .title)
                                            .frame(width: screen.size.height < 736 ? 80 : 100, height: screen.size.height < 736 ? 80 : 120)
                                            .background(i+1 == dayIndex ? .gray.opacity(0.06) : .clear)
                                            .cornerRadius(10)
                                            .id(i+1)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .strokeBorder(LinearGradient(colors: [Color(hex: "b597f6"), Color(hex: "96c6ea")], startPoint: .bottomLeading, endPoint: .topTrailing), lineWidth: i+1 == dayIndex ? 5 : 0)
                                            )
                                            .onTapGesture {
                                                buttonsSelected = Array(repeating: false, count: 7)
                                                dayIndex = i+1
                                                buttonsSelected[dayIndex-1] = true
                                                withAnimation(.spring()) {
                                                    index.scrollTo(dayIndex, anchor: .center)
                                                }
                                                
                                                getActivities()
                                                refresh.toggle()

                                            }

                                        if i < 6 {
                                            Divider()
                                                .padding(0)
                                        }

                                    }
                                    Spacer()
                                }
                                //: HStack
                                .padding(.horizontal, (screen.size.width - (screen.size.height < 736 ? 195 : 220)) / 2)
                                .frame(height: screen.size.height < 736 ? 90 : 150)
                            }
                            .onAppear { // MARK: ON APPEAR
                                withAnimation(.spring()) {
                                    index.scrollTo(dayIndex, anchor: .center)
                                }
                                buttonsSelected[dayIndex-1] = true

                                getActivities()

                            }
                            //: ScrollView
                        }
                        //: ScrollViewReader

                        // MARK: INPUT FIELDS VSTACK

                        VStack(spacing: screen.size.height < 700 ? 20 : 30) {
                            // Title textfield
                            VStack(spacing: 20) {
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
                            }
                            //: VStack

                            // Repeat options

                            VStack(spacing: screen.size.height < 700 ? 5 : 10) {
                                Text("Add to other days?")
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 20) {
                                        ForEach(0...6, id:\.self) { i in
                                            if i != dayIndex - 1 {
                                                Button(action: {
                                                    buttonsSelected[i].toggle()
                                                }, label: {
                                                    Text(days[i].prefix(3))
                                                        .foregroundColor(.black)
                                                        .padding(.horizontal, 20)
                                                        .padding(.vertical, 10)
                                                        .background(Color(hex: "F8F9FA"))
                                                        .cornerRadius(10)
                                                        .opacity(buttonsSelected[i] ? 0.3 : 1)
                                                })
                                            }
                                        }
                                    }
                                }
                            }

                            //MARK: Add activity button

                            Button(action: {
                                
                                isAddEnabled = false
                                hideKeyboard()
                                
                                var selectedDays = [days[dayIndex-1]]

                                for i in 0..<buttonsSelected.count {
                                    if buttonsSelected[i] && i != dayIndex-1 {
                                        selectedDays.append(days[i])
                                    }
                                }
                                
                                let tmpName = activityName
                                let tmpDes = activityDescription
                                
                                activityName = ""
                                activityDescription = ""
                                
                                buttonsSelected = Array(repeating: false, count: 7)
                                
                                isAdding = true

                                Task {
                                    do {
                                        
                                        let retVal = try await firebaseService.addActivity(activity: Activity(id: nil, name: tmpName, description: tmpDes, isDone: false, day: days[dayIndex-1], groupPath: ""), days: selectedDays, uid: authState.user!.uid)
                                        
                                        withAnimation(.spring()) {
                                            activities.append(contentsOf: retVal)
                                        }

                                        firebaseService.addSubscriptions(days: selectedDays, uid: authState.user!.uid)

                                        try await firebaseService.subscribeToTopic(fcmToken: UserDefaults.standard.string(forKey: "fcmKey")!, days: selectedDays)
                                        
                                        isAdding = false
                                    }
                                    catch {
                                        errorMsg = "Error adding activity"
                                        isError = true
                                        isAdding = false
                                    }
                                }

                            }, label: {
                                Image(systemName: "plus")
                                    .foregroundColor(.white)
                                    .font(screen.size.height < 736 ? .title2 : .title)
                                    .padding(.vertical, 20)
                                    .frame(maxWidth: .infinity)
                                    .background(LinearGradient(colors: [Color(hex: "b597f6"), Color(hex: "96c6ea")], startPoint: .bottomLeading, endPoint: .topTrailing))
                                    .cornerRadius(10)
                            })
                            .opacity(!isAddEnabled ? 0.5 : 1)
                            .disabled(!isAddEnabled)

                        }
                        .padding(.horizontal, 10)
                        .onChange(of: activityName) { value in
                            if value.trimmingCharacters(in: .whitespacesAndNewlines).count == 0 {
                                isAddEnabled = false
                            }
                            else {
                                isAddEnabled = true
                            }
                        }

                        Spacer()

                        // MARK: ACTIVITIES DISPLAY

                        if isLoading {
                            VStack {
                                Spacer()
                                ProgressView()
                                    .tint(Color(hex: "A6AEF0"))
                                    .frame(width: 300)
                                    .controlSize(ControlSize.regular)
                                Spacer()
                            }
                        }
                        else if activities.filter({ value in value.day == days[dayIndex-1] }).isEmpty {
                            VStack {
                                Spacer()
                                Text("No activities added")
                                    .italic()
                                    .foregroundColor(.gray)
                                Spacer()
                            }
                        }
                        else if !activities.isEmpty && !isLoading {
                            ScrollView(.vertical) {
                                VStack(spacing: 15) {
                                    ForEach(Array(activities.enumerated()), id:\.element) { offset, activity in
                                        if activity.day == days[dayIndex-1] {
                                            ZStack {
                                                HStack(spacing: 20) {
                                                    DisclosureGroup(content: {
                                                        Divider()
                                                            .overlay(
                                                                LinearGradient(colors: [Color(hex: "b597f6"), Color(hex: "96c6ea")], startPoint: .leading, endPoint: .trailing)
                                                            )
                                                        
                                                        VStack(alignment: .leading, spacing: 5) {
                                                            Text("Description:")
                                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                                .bold()
                                                            Text(activity.description == "" ? "None" : activity.description)
                                                                .font(.headline)
                                                                .fontWeight(.regular)
                                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                                .multilineTextAlignment(.leading)
                                                        }
                                                        .frame(maxWidth: .infinity)
                                                        
                                                    }, label: {
                                                        HStack(spacing: 20) {
                                                            Text(activity.name)
                                                                .bold()
                                                                .font(screen.size.height < 844 ? .body : .title3)
                                                                .multilineTextAlignment(.leading)
                                                                .foregroundColor(.black)
                                                            
                                                            // MARK: EDIT ACTIVITIES
                                                            
                                                            Button(action: {
                                                                Task {
                                                                    do {
                                                                        let tmpActs = activities
                                                                        
                                                                        selectedIndex = activities.firstIndex { value in
                                                                            value.id == activity.id
                                                                        }
                                                                        
                                                                        
                                                                        let idsInGroup = try await firebaseService.getActivitiesInGroup(groupRef: tmpActs[selectedIndex!].groupRef())
                                                                        
                                                                        let filtered = activities.filter { value in
                                                                            idsInGroup.contains(value.id) && value.id != activity.id
                                                                        }
                                                                        
                                                                        preSelectedDaysForEditing = filtered.map{$0.day}
                                                                        preSelectedDaysForEditing.append(activity.day)
                                                                        
                                                                        isEditing = true
                                                                    }
                                                                    catch {
                                                                        errorMsg = "Error editing activity"
                                                                        isError = true
                                                                    }
                                                                }
                                                                
                                                            }, label: {
                                                                Image(systemName: "pencil")
                                                                    .gradientForeground(colors: [Color(hex: "b597f6"), Color(hex: "96c6ea")], startPoint: .leading, endPoint: .trailing)
                                                                    .bold()
                                                                    .frame(maxHeight: .infinity)
                                                            })
                                                        }
                                                        
                                                    })
                                                    .foregroundColor(.black)
                                                    .accentColor(.black)
                                                    
                                                    Spacer()
                                                    
                                                    // MARK: DELETING ACTIVITY
                                                    
                                                    Button(action: {
                                                        withAnimation(.spring(bounce: 0.15)) {
                                                            isDeleting = activity.id
                                                        }
                                                        deleteIndex = offset
                                                    }, label: {
                                                        Image(systemName: "trash")
                                                            .resizable()
                                                            .aspectRatio(contentMode: .fit)
                                                            .frame(width: screen.size.height < 844 ? 15 : 20, height: 25)
                                                            .gradientForeground(colors: [Color(hex: "f83d5c"), Color(hex: "fd4b2f")], startPoint: .bottomLeading, endPoint: .topTrailing)
                                                    })
                                                    
                                                } //: HStack
                                                .padding(.vertical, 20)
                                                .padding(.horizontal, 20)
                                                .background(
                                                    Color.gray.opacity(0.05)
                                                )
                                                .cornerRadius(15)
                                                .opacity(isDeleting == activity.id ? 0 : 1)
                                                .animation(.easeInOut, value: isDeleting == activity.id)
                                                
                                                HStack(spacing: 15) {
                                                    if isDeleting == activity.id {
                                                        
                                                        Image(systemName: "chevron.right")
                                                            .foregroundColor(.white)
                                                            .onTapGesture {
                                                                withAnimation(.spring()) {
                                                                    isDeleting = nil
                                                                }
                                                                
                                                                deleteIndex = nil
                                                            }
                                                        
                                                        Text("Delete all occurences?")
                                                            .font(screen.size.height < 844 ? .subheadline : .body)
                                                            .foregroundColor(.white)
                                                            .bold()
                                                        
                                                        Spacer()
                                                        
                                                        Image(systemName: "xmark")
                                                            .foregroundColor(.white)
                                                            .onTapGesture {
                                                                
                                                                // Delete task from current day
                                                                
                                                                Task {
                                                                    var unsubscribeDays: [String] = []
                                                                    
                                                                    withAnimation(.linear(duration: 0.3)) {
                                                                        isDeleted = activity.id
                                                                    }
                                                                    
                                                                    withAnimation(.spring(dampingFraction: 0.55).delay(0.3)) {
                                                                        changeHeight = activity.id
                                                                    }
                                                                    
                                                                    
                                                                    do {
                                                                        try await Task.sleep(nanoseconds: UInt64(1.15) * 1_000_000_000)
                                                                        
                                                                        let _ = try await firebaseService.deleteActivity(uid: authState.user!.uid, activityId: activity.id, groupPath: activity.groupPath, all: false)
                                                                        
                                                                        
                                                                        isDeleting = nil
                                                                        
                                                                        activities.removeAll { value in
                                                                            value.id == activity.id
                                                                        }
                                                                        
                                                                        
                                                                        isDeleted = nil
                                                                        deleteIndex = nil
                                                                        changeHeight = nil
                                                                        
                                                                        let filtered = activities.filter { value in
                                                                            value.day == days[dayIndex - 1]
                                                                        }
                                                                        
                                                                        if filtered.count == 0 {
                                                                            unsubscribeDays.append(days[dayIndex-1])
                                                                        }
                                                                        
                                                                        
                                                                        firebaseService.removeSubscriptions(days: unsubscribeDays, uid: authState.user!.uid)
                                                                        
                                                                        try await firebaseService.unsubscribeFromTopic(fcmToken: UserDefaults.standard.string(forKey: "fcmKey")!, days: unsubscribeDays)
                                                                        
                                                                    }
                                                                    catch {
                                                                        errorMsg = "Error deleting activity"
                                                                        isError = true
                                                                    }
                                                                }
                                                            }
                                                        
                                                        Spacer()
                                                        
                                                        Image(systemName: "checkmark")
                                                            .foregroundColor(.white)
                                                            .onTapGesture {
                                                                Task {
                                                                    
                                                                    withAnimation(.linear(duration: 0.3)) {
                                                                        isDeleted = activity.id
                                                                    }
                                                                    
                                                                    withAnimation(.spring(dampingFraction: 0.55).delay(0.3)) {
                                                                        changeHeight = activity.id
                                                                    }
                                                                    
                                                                    do {
                                                                        
                                                                        try await Task.sleep(nanoseconds: UInt64(1.15) * 1_000_000_000)
                                                                        
                                                                        let deletedIds = try await firebaseService.deleteActivity(uid: authState.user!.uid, activityId: activity.id, groupPath: activity.groupPath, all: true)
                                                                        
                                                                        isDeleting = nil
                                                                        
                                                                        for id in deletedIds {
                                                                            activities.removeAll { value in
                                                                                value.id == id
                                                                            }
                                                                        }
                                                                        
                                                                        
                                                                        isDeleted = nil
                                                                        deleteIndex = nil
                                                                        changeHeight = nil
                                                                        
                                                                        var unsubscribeDays: [String] = []
                                                                        
                                                                        for day in days {
                                                                            let filtered = activities.filter { value in
                                                                                value.day == day
                                                                            }
                                                                            if filtered.count == 0 {
                                                                                unsubscribeDays.append(day)
                                                                            }
                                                                        }
                                                                                                                                        
                                                                        firebaseService.removeSubscriptions(days: unsubscribeDays, uid: authState.user!.uid)
                                                                        
                                                                        try await firebaseService.unsubscribeFromTopic(fcmToken: UserDefaults.standard.string(forKey: "fcmKey")!, days: unsubscribeDays)
                                                                        
                                                                    }
                                                                    catch {
                                                                        errorMsg = "Error deleting activity"
                                                                        isError = true
                                                                    }
                                                                }
                                                            }
                                                        
                                                    }
                                                }
                                                .padding(.horizontal, 20)
                                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                                .background(LinearGradient(colors: [Color(hex: "f83d5c"), Color(hex: "fd4b2f")], startPoint: .bottomLeading, endPoint: .topTrailing))
                                                .cornerRadius(15)
                                                .offset(x: isDeleting == activity.id ? 0 : 500)
                                                .opacity(isDeleting == activity.id ? 1 : 0)
                                                
                                                
                                                
                                            } //: ZStack
                                            .offset(x: isDeleted == activity.id ? 500 : 0)
                                            .offset(y: changeHeight != nil && changeHeight! != activity.id && (deleteIndex != nil && deleteIndex! < offset) ? -15 : 0)
                                            .frame(maxHeight: changeHeight == activity.id ? 0 : .infinity)
                                            .opacity(refresh ? 1 : 1)
                                        }

                                    }

                                }
                            } //: ScrollView
                            .opacity(isAdding ? 0.2 : 1)
                            .overlay(
                                isAdding ?
                                    ProgressView()
                                        .tint(Color(hex: "A6AEF0"))
                                        .frame(width: 300)
                                        .controlSize(ControlSize.regular)
                                :
                                    nil
                                
                                , alignment: .center)
                            
                        }

                        Spacer()
                    }

                }
                .padding(.vertical, 10)
                .padding(.horizontal, 20)
                .ignoresSafeArea(.keyboard)
                //: VStack
            }
            .onTapGesture {
                hideKeyboard()
            }
            .toast(isPresenting: $isError, duration: 2, alert: {
                AlertToast(displayMode: .hud, type: .error(Color(hex: "ff5858")), subTitle: errorMsg)
            })
            .sheet(isPresented: $isEditing, content: {
                EditingActivityView(activity: activities[selectedIndex ?? 0], activityName: activities[selectedIndex ?? 0].name, activityDescription: activities[selectedIndex ?? 0].description, preSelectedDays: preSelectedDaysForEditing)
                    .environmentObject(authState)
            })
            .onChange(of: isEditing) { newValue in
                if newValue == false {
                    getActivities()
                }
            }
            .onChange(of: AppState.shared.showSocial) { value in
                if value {
                    dismiss()
                }
            }
        }
        .ignoresSafeArea(.keyboard)
    }
    
   
}

