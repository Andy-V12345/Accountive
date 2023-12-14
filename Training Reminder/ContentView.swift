//
//  ContentView.swift
//  Training Reminder
//
//  Created by Andy Vu on 9/4/23.
//

import SwiftUI


struct ContentView: View {
    
    @StateObject private var authState = AuthState()
    @ObservedObject private var appState = AppState.shared
    @State private var isSocialScreen = false
    
    @StateObject private var network = Network()
    
    var body: some View {
        Group {
            if network.connected {
                if authState.value == .undefined {
                    ProgressView()
                        .tint(Color(hex: "A6AEF0"))
                        .frame(width: 300)
                        .controlSize(.regular)
                }
                else if authState.value == .notAuthorized {
                    SignInView()
                        .environmentObject(authState)
                }
                else {
                    if authState.doneAuth == nil || authState.doneAuth! {
                        HomeView()
                            .environmentObject(authState)
                    }
                    else {
                        ProgressView()
                            .tint(Color(hex: "A6AEF0"))
                            .frame(width: 300)
                            .controlSize(.regular)
                    }
                }
            }
            else {
                ZStack {
                    Color.white.ignoresSafeArea()
                    
                    VStack(spacing: 15) {
                        Image(systemName: "wifi.slash")
                            .gradientForeground(colors: [Color(hex: "b597f6"), Color(hex: "96c6ea")], startPoint: .bottomLeading, endPoint: .topTrailing)
                            .font(.title)
                        Text("No connection!")
                            .gradientForeground(colors: [Color(hex: "b597f6"), Color(hex: "96c6ea")], startPoint: .bottomLeading, endPoint: .topTrailing)
                            .font(.subheadline)
                        
                    }
                    .padding(.horizontal, 30)
                    
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
            }
        }
        
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
