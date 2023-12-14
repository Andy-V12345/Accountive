//
//  CircleProgressBar.swift
//  Training Reminder
//
//  Created by Andy Vu on 9/7/23.
//

import SwiftUI

struct CircleProgressBar: View {
    
    var count: Int
    var total: Int
    var progress: CGFloat
    var font1: Font?
    var font2: Font?
    var lineWidth: CGFloat?
    var includeTotal: Bool?
    
    let animation = Animation
            .easeInOut(duration: 1)
            .repeatForever(autoreverses: false)
    
    var body: some View {
        ZStack {
            Circle()
                    .stroke(style: StrokeStyle(lineWidth: lineWidth ?? 14))
                    .foregroundColor(.gray.opacity(0.1))
                    .overlay {
                        // Foreground ring
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(LinearGradient(colors: [Color(hex: "b597f6"), Color(hex: "96c6ea")], startPoint: .bottomLeading, endPoint: .topTrailing),
                                    style: StrokeStyle(lineWidth: lineWidth ?? 14, lineCap: .round))
                            .animation(.linear, value: progress)
                    }
                .rotationEffect(.degrees(-90))
            
            VStack {
                Text(String(count))
                    .font(font1 ?? Font.system(size: 50, weight: .bold))
                    .foregroundColor(.black)
                
                if includeTotal ?? true {
                    Text("/ \(total)")
                        .font(font2 ?? Font.system(size: 25, weight: .bold))
                        .foregroundColor(.gray)
                }
            }
        }
//        .animation(animation, value: progress)
    }
}

//struct CircleProgressBar_Previews: PreviewProvider {
//    static var previews: some View {
//        CircleProgressBar(count: 5, total: 10, progress: 0.6)
//    }
//}
