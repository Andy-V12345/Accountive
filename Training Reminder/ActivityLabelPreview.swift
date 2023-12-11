//
//  ActivityLabelPreview.swift
//  Training Reminder
//
//  Created by Andy Vu on 9/18/23.
//

//import SwiftUI
//
//struct ActivityLabelPreview: View {
//    
//    @State var activity = Activity(id: "4r134", name: "Run", description: "Run 10 miles", isDone: false, day: "Monday", groupPath: "")
//    @State var doneCount: Int? = 2
//    @State var allDone = false
//    @State var totalCount = 5
//    @State var isDeleting: String? = ""
//    @State var isDeleted: String? = ""
//    @State var changeHeight: String? = ""
//    @State var deleteIndex: Int? = 0
//    @State var index = 0
//    
//    var body: some View {
//        VStack {
//            ActivityLabel(activity: activity, doneCount: $doneCount, allDone: $allDone, totalCount: totalCount, isDeleting: $isDeleting, isDeleted: $isDeleted, changeHeight: $changeHeight, deleteIndex: $deleteIndex)
//        }
//        .padding(.horizontal, 20)
//    }
//}
//
//struct ActivityLabelPreview_Previews: PreviewProvider {
//    static var previews: some View {
//        ActivityLabelPreview()
//    }
//}
