//
//  HomeView.swift
//  Training Reminder
//
//  Created by Andy Vu on 9/6/23.
//

import SwiftUI
import SPConfetti
import AlertToast
import PopupView
import FirebaseFirestore

// TODO: WORK ON ADDING ACTIVITIES

struct HomeView: View {
    
    // MARK: Properties
    @State var isLoading = true
    @State var dayIndex: Int = Calendar.current.component(.weekday, from: Date())
    @State var doneCount: Int?
    @State var allDone = false
    @State var totalCount: Int?
    @State var activities: [Activity]?
    
    @State var isAddingItem = false
    @State var isLoggingOut = false
    
    @State var errorMsg = ""
    @State var isError = false
    
    @State var isDeleting: String?
    @State var isDeleted: String?
    @State var changeHeight: String?
    @State var deleteIndex: Int?
    
    @State var isSignOutLoading = false
    
    @State var isShowingFriendsView = AppState.shared.showSocial
    
    @State var updatingLabels = 0
    
    @State var isDeleteAlert = false
    
    @State var passwordText = ""
    @State var isDeletingError = false
    
    @State var hasShownInstructions = false
    @State var showInstructions = false
    
    @Environment(\.scenePhase) var scenePhase
    
    let firebaseService = FirebaseService()
    
    @EnvironmentObject private var authState: AuthState
    
    let days = [
        "Sunday",
        "Monday",
        "Tuesday",
        "Wednesday",
        "Thursday",
        "Friday",
        "Saturday"
    ]
    
    func loadData(showLoading: Bool) async {
        do {
            if showLoading {
                withAnimation(.spring()) {
                    isLoading = true
                }
            }
            
            dayIndex = Calendar.current.component(.weekday, from: Date())
            isDeleting = nil
            isDeleted = nil
            changeHeight = nil
            deleteIndex = nil
            activities = await firebaseService.getActivitiesByDay(day: days[dayIndex-1], uid: authState.user!.uid)
            doneCount = try await firebaseService.getDoneCount(day: days[dayIndex-1], uid: authState.user!.uid)
            totalCount = activities?.count
            
            firebaseService.updateTotalCount(uid: authState.user!.uid, totalCount: totalCount ?? 0)
            
            if authState.getUsername() == "" {
                authState.setUsername(username: try await firebaseService.getUsername(uid: authState.user!.uid))
            }
                        
            hasShownInstructions = try await firebaseService.getHasShownInstructions(uid: authState.user!.uid)
                        
            withAnimation(.spring()) {
                isLoading = false
            }
        }
        catch {
            errorMsg = "Error loading data"
            isError = true
        }
    }
    
    // MARK: Body
    
    var body: some View {
        GeometryReader { screen in
            ZStack {
                Color.white.ignoresSafeArea()
                
                if isLoading {
                    ProgressView()
                        .tint(Color(hex: "A6AEF0"))
                        .frame(width: 300)
                        .controlSize(.large)
                    VStack {
                        Text("ACCOUNTIVE")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .gradientForeground(colors: [Color(hex: "b597f6"), Color(hex: "96c6ea")], startPoint: .bottomLeading, endPoint: .topTrailing)
                            .font(.system(size: 30))
                            .fontWidth(.condensed)
                            .bold()
                        Spacer()
                    }
                    .padding(.top, 10)
                }
                else {
                    // MARK: PARENT VSTACK
                    VStack {
                        // MARK: HEADER HSTACK
                        HStack {
                            
                            Button(action: {
                                withAnimation(.spring()) {
                                    isShowingFriendsView.toggle()
                                }
                            }, label: {
                                Image(systemName: "person.2.fill")
                                    .font(screen.size.width < 390 ? .body : .title3)
                                    .bold()
                                    .foregroundColor(.black)
                            })
                            
                            Spacer()
                            
                            Text("ACCOUNTIVE")
                                .frame(maxWidth: .infinity, alignment: .center)
                                .gradientForeground(colors: [Color(hex: "b597f6"), Color(hex: "96c6ea")], startPoint: .bottomLeading, endPoint: .topTrailing)
                                .font(.system(size: 30))
                                .fontWidth(.condensed)
                                .bold()
                            
                            Spacer()
                            
                            
                            Button(action: {
                                isLoggingOut = true
                            }, label: {
                                Image(systemName: "figure.walk.departure")
                                    .font(screen.size.width < 390 ? .body : .title3)
                                    .foregroundColor(.black)
                            })
                        }
                        .padding(.horizontal, screen.size.width < 390 ? 0 : 10)
                        
                        //: HStack
                        
                        Spacer()
                        
                        ZStack {
                            VStack {
                                
                                if activities != nil && activities!.count > 0 {
                                    
                                    if updatingLabels == 0 {
                                        
                                        Spacer()
                                        
                                        // MARK: CIRCLE PROGRESS BAR
                                        CircleProgressBar(count: doneCount!, total: totalCount!, progress: CGFloat(doneCount!) / CGFloat(totalCount!), font1: (screen.size.height < 736 ? Font.system(size: 45, weight: .bold) : nil), font2: (screen.size.height < 736 ? Font.system(size: 20, weight: .bold) : nil), lineWidth: (screen.size.height < 736 ? 12 : nil))
                                            .frame(width: screen.size.width * (screen.size.height < 700 ? 0.4 : 0.45))
                                        
                                        Spacer()
                                        
                                        VStack(spacing: 5) {
                                            
                                            Text(days[dayIndex-1])
                                                .font((screen.size.height < 736 ? Font.system(size: 30, weight: .bold) : .largeTitle))
                                                .fontWeight(Font.Weight.semibold)
                                                .foregroundColor(.black)
                                            
                                            
                                            Button(action: {
                                                isAddingItem = true
                                            }, label: {
                                                HStack(spacing: 10) {
                                                    Text("Activities")
                                                        .font(.title3)
                                                        .foregroundColor(.white)
                                                    Image(systemName: "line.3.horizontal")
                                                        .font(.title3)
                                                        .foregroundColor(.white)
                                                }
                                                .gradientForeground(colors: [Color(hex: "b597f6"), Color(hex: "96c6ea")], startPoint: .bottomLeading, endPoint: .topTrailing)
                                                .padding(.vertical, 10)
                                                .padding(.horizontal, 20)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 10)
                                                        .strokeBorder(LinearGradient(colors: [Color(hex: "b597f6"), Color(hex: "96c6ea")], startPoint: .bottomLeading, endPoint: .topTrailing), lineWidth: 3)
                                                )
                                            })
                                        }
                                    }
                                        
                                    Spacer()
                                    
                                    
                                    // MARK: ITEM LIST
                                    
                                    ScrollView(.vertical) {
                                        VStack(spacing: 15) {
                                            ForEach(Array(activities!.enumerated()), id:\.element) { offset, activity in
                                                ZStack {
                                                    ActivityLabel(activity: activities![offset], doneCount: $doneCount, allDone: $allDone, totalCount: totalCount!, isDeleting: $isDeleting, isDeleted: $isDeleted, changeHeight: $changeHeight, deleteIndex: $deleteIndex, updatingViews: $updatingLabels)
                                                        .environmentObject(authState)
                                                        .opacity(isDeleting == activity.id ? 0 : 1)
                                                    
                                                    // MARK: DELETE ACTIVITY FOR CURRENT DAY
                                                    
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
                                                            
                                                            Text("Delete this task?")
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
                                                                                isDeleted = activity.id
                                                                            }
                                                                            
                                                                            deleteIndex = offset
                                                                            
                                                                            withAnimation(.spring(dampingFraction: 0.55).delay(0.3)) {
                                                                                changeHeight = activity.id
                                                                            }
                                                                            
                                                                            do {
                                                                                
                                                                                
                                                                                try await Task.sleep(nanoseconds: UInt64(0.9) * 1_000_000_000)
                                                                                
                                                                                
                                                                                
                                                                                let _ = try await firebaseService.deleteActivity(uid: authState.user!.uid, activityId: activity.id, groupPath: activity.groupPath, all: false)
                                                                                
                                                                                isDeleting = nil
                                                                                
                                                                                activities!.removeAll { value in
                                                                                    value.id == activity.id
                                                                                }
                                                                                
                                                                                isDeleted = nil
                                                                                changeHeight = nil
                                                                                deleteIndex = nil
                                                                                
                                                                                if activity.isDone {
                                                                                    doneCount! -= 1
                                                                                }
                                                                                
                                                                                
                                                                                totalCount = activities!.count
                                                                                firebaseService.updateTotalCount(uid: authState.user!.uid, totalCount: totalCount ?? 0)
                                                                                
                                                                                
                                                                                if activities!.count == 0 {
                                                                                    firebaseService.removeSubscriptions(days: [days[dayIndex-1]], uid: authState.user!.uid)
                                                                                    try await firebaseService.unsubscribeFromTopic(fcmToken: UserDefaults.standard.string(forKey: "fcmKey")!, days: [days[dayIndex-1]])
                                                                                }
                                                                                
                                                                            }
                                                                            catch {
                                                                                errorMsg = "Error deleting activity"
                                                                                isError = true
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
                                                    .offset(x: isDeleting == activity.id ? 0 : 500)
                                                    .opacity(isDeleting == activity.id ? 1 : 0)
                                                    
                                                } //: ZStack
                                                .offset(x: isDeleted == activity.id ? 500 : 0)
                                                .offset(y: changeHeight != nil && changeHeight! != activity.id && (deleteIndex != nil && deleteIndex! < offset) ? -15 : 0)
                                                .frame(maxHeight: changeHeight == activity.id ? 0 : .infinity)
                                                
                                                
                                            }
                                            
                                            
                                            
                                        } //: VStack
                                    } //: ScrollView
                                    .frame(maxHeight: updatingLabels > 0 ? .infinity : screen.size.height * (screen.size.height < 736 ? 0.4 : 0.45))
                                }
                                
                            } //: VStack
                            .opacity(activities != nil && activities!.count > 0 ? 1 : 0)
                            .animation(.linear(duration: 0.25), value:activities)
                            
                            // MARK: No activities display
                            
                            VStack(spacing: 15) {
                                Spacer()
                                Text("Nothing to do today")
                                    .italic()
                                    .gradientForeground(colors: [Color(hex: "b597f6"), Color(hex: "96c6ea")], startPoint: .bottomLeading, endPoint: .topTrailing)
                                
                                Button(action: {
                                    isAddingItem = true
                                }, label: {
                                    HStack(spacing: 10) {
                                        Text("Add Something")
                                            .font(.title3)
                                            .foregroundColor(.white)
                                        Image(systemName: "plus")
                                            .font(.title3)
                                            .foregroundColor(.white)
                                    }
                                    .gradientForeground(colors: [Color(hex: "b597f6"), Color(hex: "96c6ea")], startPoint: .bottomLeading, endPoint: .topTrailing)
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 20)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .strokeBorder(LinearGradient(colors: [Color(hex: "b597f6"), Color(hex: "96c6ea")], startPoint: .bottomLeading, endPoint: .topTrailing), lineWidth: 3)
                                    )
                                })
                                Spacer()
                            }
                            .opacity(activities != nil && activities!.count > 0 ? 0 : 1)
                            .animation(.linear(duration: 0.25), value:activities)
                            
                        }
                        
                    } //: Parent VStack
                    .padding(.top, 10)
                    .padding(.horizontal, 15)
                    .padding(.bottom, 15)
                    .confetti(isPresented: $allDone, animation: .fullWidthToDown, particles: [.triangle, .arc], duration: 2.0)
                    
                }
                
                
            } //: Parent ZStack
            .onChange(of: isAddingItem) { newValue in
                if newValue == false {
                    Task {
                        activities = nil
                        await loadData(showLoading: true)
                        
                        if activities!.count > 0 && hasShownInstructions == false {
                            print("bruh")
                            showInstructions = true
                        }
                    }
                    
                }
            }
            .onChange(of: doneCount) { count in
                firebaseService.updateDoneCount(uid: authState.user!.uid, doneCount: doneCount ?? 0)
            }
            .onChange(of: scenePhase) { phase in
                switch phase {
                case .active:
                    if !isShowingFriendsView {
                        withAnimation(.spring()) {
                            isShowingFriendsView = AppState.shared.showSocial
                        }
                    }
                    Task {
                        await loadData(showLoading: true)
                    }
                case .background: print("ScenePhase: background")
                case .inactive: print("ScenePhase: inactive")
                @unknown default: print("ScenePhase: unexpected state")
                }
            }
            .onAppear {
                withAnimation(.spring()) {
                    isShowingFriendsView = AppState.shared.showSocial
                }
                Task {
                    await loadData(showLoading: true)
                }
            }
            .onChange(of: AppState.shared.showSocial) { value in
                withAnimation(.spring()) {
                    isShowingFriendsView = AppState.shared.showSocial
                }
                if value {
                    isLoggingOut = false
                }
            }
            
            .onTapGesture {
                hideKeyboard()
            }
            .toast(isPresenting: $isError, duration: 2, alert: {
                AlertToast(displayMode: .hud, type: .error(Color(hex: "ff5858")), subTitle: errorMsg)
            })
            .alert("Quick Tip!", isPresented: $showInstructions) {
                Button(role: .cancel) {
                    hasShownInstructions = firebaseService.updateHasShownInstructions(hasShownInstructions: true, uid: authState.user!.uid)
                } label: {
                    Text("Got it!")
                }
            } message: {
                Text("You've added your first daily goal! When you've completed it, click the box next to your goal to mark it as done and to notify your friends.")
            }
            .popup(isPresented: $isLoggingOut) {
                VStack(spacing: 0) {
                    
                    Spacer()
                                        
                    Text("Sign Out?")
                        .foregroundColor(.black)
                        .font(.largeTitle)
                        .bold()
                        .padding(.bottom, 25)
                    
                    VStack(spacing: 12) {
                        Button(action: {
                            Task {
                                withAnimation(.spring()) {
                                    isSignOutLoading = true
                                }
                                do {
                                    firebaseService.updateFcmToken(uid: authState.user!.uid, newFcmToken: "")
                                    try await firebaseService.unsubscribeFromTopic(fcmToken: UserDefaults.standard.string(forKey: "fcmKey")!, days: days)
                                    try authState.logout()
                                    withAnimation(.spring()) {
                                        isSignOutLoading = false
                                    }
                                }
                                catch {
                                    errorMsg = "Error logging out"
                                    isError = true
                                }
                            }
                            
                        }, label: {
                            Text("Yes")
                                .font(.title2)
                                .foregroundColor(.white)
                                .bold()
                                .frame(width: screen.size.width * 0.85, height: 65)
                                .background(
                                    LinearGradient(colors: [Color(hex: "b597f6"), Color(hex: "96c6ea")], startPoint: .bottomLeading, endPoint: .topTrailing)
                                )
                                .cornerRadius(15)
                        })
                        
                        Text("or")
                            .foregroundColor(.black)
                        
                        Text("Cancel")
                            .gradientForeground(colors: [Color(hex: "b597f6"), Color(hex: "96c6ea")], startPoint: .bottomLeading, endPoint: .topTrailing)
                            .italic()
                            .onTapGesture {
                                isLoggingOut = false
                            }
                        
                        
                        Divider()
                            .padding(.vertical, 25)
                            .padding(.horizontal, 30)
                        
                        
                        Text("Delete Account")
                            .foregroundStyle(.red)
                            .onTapGesture {
                                isDeleteAlert = true
                            }
                        
                    }
                    
                    Spacer()
                }
                .alert("Error", isPresented: $isDeletingError) {
                    Button(role: .cancel) {
                        
                    } label: {
                        Text("Cancel")
                    }
                    
                    Button(role: .destructive) {
                        isDeleteAlert = true
                    } label: {
                        Text("Try Again")
                    }
                    
                } message: {
                    Text("Something went wrong when deleting your account! Maybe your password was incorrect.")
                }
                .alert("Are You Sure?", isPresented: $isDeleteAlert) {
                    Button(role: .destructive) {
                        // TODO: DELETE ACCOUNT
                        isSignOutLoading = true
                        Task {
                            if passwordText.trimmingCharacters(in: .whitespacesAndNewlines) != "" {
                                do {
                                    print("deleting")
                                    try await authState.deleteAccount(password: passwordText)
                                }
                                catch {
                                    print("error")
                                    isDeletingError = true
                                }
                            }
                            isSignOutLoading = false
                            passwordText = ""
                        }
                    } label: {
                        Text("Delete")
                    }
                    
                    Button(role: .cancel) {
                        
                    } label: {
                        Text("Cancel")
                    }
                    
                    SecureField("Password", text: $passwordText)
                        .font(.subheadline)
                    
                } message: {
                    Text("This will permanently delete your account and all of your data! Please enter your password to delete your account.")
                }
                .opacity(isSignOutLoading ? 0.1 : 1)
                .frame(maxWidth: .infinity)
                .frame(height: 380)
                .background(.white)
                .cornerRadius(20)
                .overlay(isSignOutLoading ? ProgressView()
                    .tint(Color(hex: "A6AEF0"))
                    .frame(width: 300)
                    .controlSize(.regular) : nil, alignment: .center)
                
                
            } customize: {
                $0
                    .closeOnTapOutside(true)
                    .position(.bottom)
                    .backgroundColor(.black.opacity(0.25))
                    .closeOnTap(false)
            }
        } //: GeometryReader
        .transition(.move(edge: .trailing))
        .ignoresSafeArea(.keyboard)
        .fullScreenCover(isPresented: $isAddingItem, content: {
            AddingItemView(dayIndex: dayIndex)
                .environmentObject(authState)
        })
        .fullScreenCover(isPresented: $isShowingFriendsView, content: {
            SocialContainerView(isFriendsView: !(AppState.shared.showSocial))
                .environmentObject(authState)
        })
    }
    
}

//struct HomeView_Previews: PreviewProvider {
//    static var previews: some View {
//        HomeView()
//    }
//}
