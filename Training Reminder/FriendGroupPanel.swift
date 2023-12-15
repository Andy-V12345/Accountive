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
    
    var body: some View {
        HStack(spacing: 20) {
            
            DisclosureGroup(content: {
                
                Divider()
                    .overlay(
                        LinearGradient(colors: [Color(hex: "b597f6"), Color(hex: "96c6ea")], startPoint: .leading, endPoint: .trailing)
                    )
                
                VStack(spacing: 3) {
                    Text("Friends")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                        .padding(.top, 5)
                    
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
            })
            .foregroundColor(.black)
            .accentColor(.black)
            
            Button(action: {
                // TODO: UPDATE FRIEND GROUP
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
                // TODO: DELETE FRIEND GROUP
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
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.gray.opacity(0.05))
        )
    }
}

//#Preview {
//    FriendGroupPanel(friendGroup: FriendGroup(id: "1", name: "real ones", friends: [Friend(name: "Nam", username: "nammy", status: "FRIEND"), Friend(name: "Andy", username: "andy.v", status: "FRIEND")]))
//}
