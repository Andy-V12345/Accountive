//
//  FirebaseService.swift
//  Training Reminder
//
//  Created by Andy Vu on 9/4/23.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseFunctions


class Activity: Codable, Identifiable, Hashable {
    
    var id: String
    var name: String
    var description: String
    var isDone = false
    var day: String
    var groupPath: String
    
    init(id: String?, name: String, description: String, isDone: Bool?, day: String, groupPath: String) {
        self.id = id ?? ""
        self.name = name
        self.description = description
        self.isDone = isDone ?? false
        self.day = day
        self.groupPath = groupPath
    }
    
    static func == (lhs: Activity, rhs: Activity) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    func groupRef() -> DocumentReference? {
        if self.groupPath == "" {
            return nil
        }
        else {
            return Firestore.firestore().document(groupPath)
        }
    }

}

struct Friend {
    var uid: String = ""
    var name: String
    var username: String
    var status: String
}

class FirebaseService {
    
    let db = Firestore.firestore()
    lazy var functions = Functions.functions()
    

    // MARK: NOTIFY FRIENDS OF COMPLETED TASK
    func notifyFriends(uid: String, username: String, task: String) async throws {
        do {
            let friends = try await self.getFriends(uid: uid)
            var fcmTokens: [String] = []
            
            
            for friend in friends {
                let token = try await self.getFcmTokenOfFriend(friendUid: friend.uid)
                if token != "" {
                    fcmTokens.append(token)
                }
            }
            
            if !fcmTokens.isEmpty {
                print(fcmTokens)
                let res = try await functions.httpsCallable("notifyFriends").call(["fcmTokens": fcmTokens, "body": "\(username) completed task \"\(task)\"!"])
                print(res.data)
            }
        }
        catch {
            throw error
        }
    }
    
    
    
    
    // MARK: GET FCMTOKEN OF FRIEND
    func getFcmTokenOfFriend(friendUid: String) async throws -> String {
        do {
            let doc = try await self.db.collection("uids").document(friendUid).getDocument()
            if doc.exists {
                return doc.data()!["fcmToken"] as? String ?? ""
            }
            return ""
        }
        catch {
            throw error
        }
    }
    
    // MARK: REMOVE FRIEND
    func removeFriend(uid: String, friendToRemove: Friend) {
        let curRef = self.db.collection("requests").document(uid)
        let friendRef = self.db.collection("requests").document(friendToRemove.uid)
        
        curRef.setData([
            "friends": [
                friendToRemove.uid: FieldValue.delete()
            ]
        ], merge: true)
        
        
        friendRef.setData([
            "friends": [
                uid: FieldValue.delete()
            ]
        ], merge: true)
        
        // TODO: REMOVE FRIEND FROM NOTIF GROUP
    }
    
    // MARK: GET FRIENDS
    func getFriends(uid: String) async throws -> [Friend] {
        let ref = self.db.collection("requests").document(uid)
        var ret: [Friend] = []
        
        do {
            let doc = try await ref.getDocument()
            if doc.exists {
                let friendsData = doc.data()!["friends"] as? [String: [String: String]] ?? [:]
                
                if friendsData.isEmpty {
                    return ret
                }
                else {
                    for (uid, data) in friendsData {
                        ret.append(Friend(uid: uid, name: data["name"]!, username: data["username"]!, status: "FRIEND"))
                    }
                    return ret
                }
            }
            else {
                return ret
            }
        }
        catch {
            throw error
        }
    }
    
    // MARK: GET FRIEND REQUESTS
    func getFriendReq(uid: String) async throws -> [String: Any] {
        let ref = self.db.collection("requests").document(uid)
                
        do {
            let doc = try await ref.getDocument()
            if doc.exists {
                return doc.data()!["friendRequests"] as? [String: Any] ?? [:]
            }
            return [:]
        }
        catch {
            throw error
        }
    }
    
    // MARK: GET PENDING REQUESTS
    func getPendingReq(uid: String) async throws -> [String: Any] {
        let ref = self.db.collection("requests").document(uid)
        
        do {
            let doc = try await ref.getDocument()
            if doc.exists {
                return doc.data()!["ownRequests"] as? [String: Any] ?? [:]
            }
            return [:]
        }
        catch {
            throw error
        }
    }
    
    // MARK: SEND FRIEND REQUEST
    func sendFriendReq(fromFriend: Friend, toFriend: Friend) {
        let fromRef = self.db.collection("requests").document(fromFriend.uid)
        let toRef = self.db.collection("requests").document(toFriend.uid)
        
        let fromData: [String: Any] = [
            "ownRequests": [
                toFriend.uid: [
                    "name": toFriend.name,
                    "username": toFriend.username,
                    "status": "PENDING"
                ]
            ]
        ]
        
        let toData: [String: Any] = [
            "friendRequests": [
                fromFriend.uid: [
                    "name": fromFriend.name,
                    "username": fromFriend.username,
                    "status": "PENDING"
                ]
            ]
        ]
        
        fromRef.setData(fromData, merge: true)
        toRef.setData(toData, merge: true)
    }
    
    // MARK: GET USER FCMTOKEN
    func getUserFcmToken(uid: String) async throws -> String {
        let uidRef = self.db.collection("uids").document(uid)
        
        do {
            let uidDoc = try await uidRef.getDocument()
            return uidDoc.data()!["fcmToken"] as? String ?? ""
        }
        catch {
            throw error
        }
    }
    
    // MARK: ADDING FRIENDS
    func addFriend(username: String, name: String, uid: String, friendToAdd: Friend) {
        let curRef = self.db.collection("requests").document(uid)
        let friendRef = self.db.collection("requests").document(friendToAdd.uid)
        
        curRef.setData([
            "friendRequests": [
                friendToAdd.uid: FieldValue.delete()
            ]
        ], merge: true)
        
        
        friendRef.setData([
            "ownRequests": [
                uid: FieldValue.delete()
            ]
        ], merge: true)
        
        curRef.setData([
            "friends": [
                friendToAdd.uid: [
                    "name": friendToAdd.name,
                    "username": friendToAdd.username,
                    "status": "FRIEND"
                ]
            ]
        ], merge: true)
        
        friendRef.setData([
            "friends": [
                uid: [
                    "name": name,
                    "username": username,
                    "status": "FRIEND"
                ]
            ]
        ], merge: true)
        
        Task {
            do {
                try await self.notifyIndividual(targetFcmKey: friendToAdd.uid, body: "\(friendToAdd.username) accepted your friend request!")
            }
            catch {
                throw error
            }
        }
        
    }
    
    // MARK: REMOVE FRIEND REQUEST
    func removeFriendRequest(uid: String, friendToRemove: Friend) {
        let curRef = self.db.collection("requests").document(uid)
        let friendRef = self.db.collection("requests").document(friendToRemove.uid)
        
        curRef.setData([
            "friendRequests": [
                friendToRemove.uid: FieldValue.delete()
            ]
        ], merge: true)
        
        
        friendRef.setData([
            "ownRequests": [
                uid: FieldValue.delete()
            ]
        ], merge: true)
    }
    
    // MARK: REMOVE PENDING REQUEST
    func removePendingRequest(uid: String, friendToRemove: Friend) {
        let curRef = self.db.collection("requests").document(uid)
        let friendRef = self.db.collection("requests").document(friendToRemove.uid)
        
        curRef.setData([
            "ownRequests": [
                friendToRemove.uid: FieldValue.delete()
            ]
        ], merge: true)
        
        
        friendRef.setData([
            "friendRequests": [
                uid: FieldValue.delete()
            ]
        ], merge: true)
    }
    
    // MARK: FILTERING USERNAMES
    func filterUsernames(uid: String, query: String, currentUsername: String) async throws -> [Friend] {
        let uidCollectionRef = self.db.collection("uids")
        var ret: [Friend] = []
        
        if query == "" {
            return ret
        }
        
        do {
            
            let friendReq = try await getFriendReq(uid: uid) as? [String: [String:String]]
            let pendingReq = try await getPendingReq(uid: uid) as? [String: [String:String]]
            let friends = try await getFriends(uid: uid)
            
            let querySnapshot = try await uidCollectionRef.whereField("username", isGreaterThanOrEqualTo: query).whereField("username", isLessThanOrEqualTo: query + "~").whereField("username", isNotEqualTo: currentUsername).getDocuments()
            
            if querySnapshot.documents.isEmpty {
                return ret
            }
            else {
                for doc in querySnapshot.documents {
                    if !friends.contains(where: {friend in friend.uid == doc.documentID}) {
                        if friendReq != nil && !friendReq!.keys.contains(doc.documentID) {
                            if pendingReq != nil && pendingReq!.keys.contains(doc.documentID) {
                                ret.append(Friend(uid: doc.documentID, name: doc.data()["name"] as! String, username: doc.data()["username"] as! String, status: pendingReq![doc.documentID]!["status"]!))
                            }
                            else {
                                ret.append(Friend(uid: doc.documentID, name: doc.data()["name"] as! String, username: doc.data()["username"] as! String, status: ""))
                            }
                        }
                    }
                }
                return ret
            }
            
        }
        catch {
            throw error
        }
        
    }
    
    // MARK: NUM ACTIVITIES
    
    func getNumActivities(day: String, uid: String) async -> Int {
        let activitiesForDay = await self.getActivitiesByDay(day: day, uid: uid)
        return activitiesForDay.count
    }

    
    // MARK: ACTIVITIES
    
    func addActivity(activity: Activity, days: [String], uid: String) async throws -> [Activity] {
        let activitiesRef = self.db.collection("/uids/\(uid)/activities")
        let groupsRef = self.db.collection("/uids/\(uid)/linkedActivities")
        
        if days.count == 1 {
            let activityDoc = activitiesRef.document()
            do {
                try await activityDoc.setData([
                    "title": activity.name,
                    "description": activity.description,
                    "isDone": false,
                    "day": days[0],
                    "groupPath": ""
                ])
                return [Activity(id: activityDoc.documentID, name: activity.name, description: activity.description, isDone: false, day: days[0], groupPath: "")]
            }
            catch {
                throw error
            }
        }
        else {
            let groupDoc = groupsRef.document()
            
            var activities: [Activity] = []
            var activityIds: [String] = []
            
            do {
                for day in days {
                    let activityDoc = activitiesRef.document()
                    try await activityDoc.setData([
                        "title": activity.name,
                        "description": activity.description,
                        "isDone": false,
                        "day": day,
                        "groupPath": groupDoc.path
                    ])
                    activities.append(Activity(id: activityDoc.documentID, name: activity.name, description: activity.description, isDone: false, day: day, groupPath: groupDoc.path))
                    activityIds.append(activityDoc.documentID)
                }
                
                try await groupDoc.setData([
                    "activityIds": activityIds
                ])
                
                return activities
            }
            catch {
                throw error
            }
        }
        
    }
    
    func updateActivityByDay(newActivity: Activity, uid: String) {
        let oldActivityDoc = self.db.collection("/uids/\(uid)/activities").document(newActivity.id)
        
        oldActivityDoc.updateData([
            "title": newActivity.name,
            "description": newActivity.description
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            }
        }
        
        
    }
    
    func updateActivity(activity: Activity, days: [String], uid: String) async throws -> [Activity] {
        do {
            let _ = try await self.deleteActivity(uid: uid, activityId: activity.id, groupPath: activity.groupPath, all: true)
            return try await self.addActivity(activity: activity, days: days, uid: uid)
        }
        catch {
            throw error
        }
        
    }
    
    func markActivity(activityId: String, uid: String) {
        let activityDoc = self.db.collection("/uids/\(uid)/activities").document(activityId)
        
        activityDoc.updateData([
            "isDone": true
        ])
    }
    
    func getActivitiesInGroup(groupRef: DocumentReference?) async throws -> [String] {
        do {
            if groupRef == nil {
                return []
            }
            else {
                let groupDoc = try await groupRef!.getDocument()
                return groupDoc.data()!["activityIds"] as? [String] ?? []
            }
        }
        catch {
            throw error
        }
    }
    
    func deleteActivity(uid: String, activityId: String, groupPath: String, all: Bool) async throws -> [String] {
        if all && groupPath != "" {
            do {
                let groupRef = db.document(groupPath)
                let activityIds = try await self.getActivitiesInGroup(groupRef: groupRef)
                for actId in activityIds {
                    try await self.db.collection("/uids/\(uid)/activities").document(actId).delete()
                }
                try await groupRef.delete()
                return activityIds
            }
            catch {
                throw error
            }
        }
        else {
            do {
                if groupPath != "" {
                    let groupRef = db.document(groupPath)
                    try await groupRef.updateData([
                        "activityIds": FieldValue.arrayRemove([activityId])
                    ])
                }
                try await self.db.collection("/uids/\(uid)/activities").document(activityId).delete()
                return [activityId]
            }
            catch {
                throw error
            }
        }
    }
    
    func getActivitiesByDay(day: String, uid: String) async -> [Activity] {
        let collectionRef = self.db.collection("/uids/\(uid)/activities")
                
        do {
            let query = try await collectionRef.whereField("day", isEqualTo: day).getDocuments()
            if query.documents.isEmpty {
                return []
            }
            else {
                var activities: [Activity] = []
                for i in 0..<query.documents.count {
                    let doc = query.documents[i].data()
                    activities.append(Activity(id: query.documents[i].documentID, name: doc["title"] as! String, description: doc["description"] as? String ?? "", isDone: doc["isDone"] as? Bool, day: doc["day"] as! String, groupPath: doc["groupPath"] as? String ?? ""))
                }

                return activities
            }
        }
        catch {
            return []
        }
    }
    
    func getAllActivities(uid: String) async -> [Activity] {
        let collectionRef = self.db.collection("/uids/\(uid)/activities")
        
        do {
            let snapshot = try await collectionRef.getDocuments()
            if snapshot.documents.isEmpty {
                return []
            }
            else {
                var activities: [Activity] = []
                
                for i in 0..<snapshot.documents.count {
                    let doc = snapshot.documents[i].data()
                    activities.append(Activity(id: snapshot.documents[i].documentID, name: doc["title"] as! String, description: doc["description"] as? String ?? "", isDone: doc["isDone"] as? Bool, day: doc["day"] as! String, groupPath: doc["groupPath"] as? String ?? ""))
                }
                return activities
            }
        }
        catch {
            return []
        }
    }
    
    
    // MARK: DONE COUNT
    func getDoneCount(day: String, uid: String) async throws -> Int {
        let collectionRef = self.db.collection("/uids/\(uid)/activities")
        do {
            let query = try await collectionRef.whereField("day", isEqualTo: day).whereField("isDone", isEqualTo: true).getDocuments()
            return query.documents.count
        }
        catch {
            throw error
        }
    }
    
    
    // MARK: SEND INDIVIDUAL NOTIF
    func notifyIndividual(targetFcmKey: String, body: String) async throws {
        do {
            let _ = try await functions.httpsCallable("notifyIndividual").call(["fcmKey": targetFcmKey, "body": body])
        }
        catch {
            throw error
        }
    }
    
    // MARK: SUBSCRIBE TO TOPIC
    func subscribeToTopic(fcmToken: String, days: [String]) async throws {
        
        do {
            let _ = try await functions.httpsCallable("subscribeToDays").call(["days": days, "fcmKey": fcmToken])
        }
        catch {
            throw error
        }
        
    }
    
    func addSubscriptions(days: [String], uid: String) {
        let uidRef = db.collection("uids").document(uid)
        
        uidRef.updateData([
            "daysSubscribed": FieldValue.arrayUnion(days)
        ])
    }
    
    func removeSubscriptions(days: [String], uid: String) {
        let uidRef = db.collection("uids").document(uid)
        uidRef.updateData([
            "daysSubscribed": FieldValue.arrayRemove(days)
        ])
    }
    
    func getSubscriptions(uid: String) async throws -> [String] {
        let uidRef = db.collection("uids").document(uid)
        
        do {
            let uidDoc = try await uidRef.getDocument()
            if uidDoc.exists {
                return uidDoc.data()!["daysSubscribed"] as? [String] ?? []
            }
            return []
        }
        catch {
            throw error
        }
        
    }
    
    func unsubscribeFromTopic(fcmToken: String, days: [String]) async throws {
        
        do {
            let _ = try await functions.httpsCallable("unsubscribeFromDays").call(["days": days, "fcmKey": fcmToken])
        }
        catch {
            throw error
        }
    }
    
    func updateFcmToken(uid: String, newFcmToken: String) {
        let userRef = db.collection("uids").document(uid)
        
        userRef.updateData([
            "fcmToken": newFcmToken
        ])
    }
    
    
    func addUser(email: String, username: String, uid: String, fcmToken: String, name: String) {
        let uidsRef = db.collection("uids")
        let uidDoc = uidsRef.document(uid)
        
        uidDoc.setData([
            "email": email,
            "username": username,
            "fcmToken": fcmToken,
            "name": name,
            "daysSubscribed": [],
            "hasShownInstructions": false
        ], merge: true)
    }
    
    func getHasShownInstructions(uid: String) async throws -> Bool {
        let uidRef = db.collection("uids").document(uid)
        do {
            let uidDoc = try await uidRef.getDocument()
            let docData = uidDoc.data()!
            if (docData.keys.contains("hasShownInstructions")) {
                return docData["hasShownInstructions"] as! Bool
            }
            else {
                return self.updateHasShownInstructions(hasShownInstructions: false, uid: uid)
            }
        }
        catch {
            throw error
        }
    }
    
    func updateHasShownInstructions(hasShownInstructions: Bool, uid: String) -> Bool {
        let uidRef = db.collection("uids").document(uid)
        uidRef.updateData([
            "hasShownInstructions": hasShownInstructions
        ])
        
        return hasShownInstructions
    }
    
    func getUsername(uid: String) async throws -> String {
        let uidRef = db.collection("uids").document(uid)
        do {
            let uidDoc = try await uidRef.getDocument()
            return uidDoc.data()!["username"] as! String
        }
        catch {
            throw error
        }
    }
    
    func deleteUid(uid: String) async throws {
        do {
            try await self.db.collection("uids").document(uid).delete()
            try await self.db.collection("requests").document(uid).delete()
        }
        catch {
            throw error
        }
    }
    
}

