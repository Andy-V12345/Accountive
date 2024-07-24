
const logger = require("firebase-functions/logger");

const {onRequest} = require("firebase-functions/v2/https");
const functions = require("firebase-functions")
const {getFirestore} = require("firebase-admin/firestore")
const firebase = require("firebase-admin")
const messaging = require("firebase-admin/messaging")

const {onCall, HttpsError} = require("firebase-functions/v2/https");

firebase.initializeApp()

exports.deleteUserActivities = onCall((request) => {
    if (!request.auth) {
        throw new HttpsError(16, "unauthorized", "must be authenticated")
    }
})

exports.notifyFriends = onCall((request) => {
    if (!request.auth) {
        throw new HttpsError(16, "unauthorized", "must be authenticated")
    }

    const fcmKeys = request.data.fcmTokens
    const body = request.data.body

    const message = {
        tokens: fcmKeys,
        notification: {
            title: "Accountive",
            body: body
        },
        data: {
            type: "friends"
        }
    }

    messaging.getMessaging().sendEachForMulticast(message).then((res) => {
        return {message: "notified friends!"}
    })
    .catch((error) => {
        throw new HttpsError(2, "error", `${error}`)
    })

})

exports.notifyIndividual = onCall((request) => {
    if (!request.auth) {
        throw new HttpsError(16, "unauthorized", "must be authenticated")
    }

    const fcmKey = request.data.fcmKey
    const body = request.data.body

    const message = {
        token: fcmKey,
        notification: {
            title: "Accountive",
            body: body
        },
        data: {
            type: "individual"
        }
    }

    messaging.getMessaging().send(message).then((res) => {
        return {message: "user notified"}
    })
    .catch((error) => {
        throw new HttpsError(2, "error", `${error}`)
    })

})

exports.subscribeToDays = onCall((request) => {

    if (!request.auth) {
        throw new HttpsError(16, "unauthorized", "must be authenticated")
    }

    const daysToSubscribe = request.data.days
    const fcmKey = request.data.fcmKey

    for (var i = 0; i < daysToSubscribe.length; i++) {
        messaging.getMessaging().subscribeToTopic([fcmKey], daysToSubscribe[i]).then((res) => {
            return {message: "subscribed!"}
        })
        .catch((error) => {
            throw new HttpsError(2, "error", `${error}`)
        })
    }
})

exports.unsubscribeFromDays = onCall((request) => {
    if (!request.auth) {
        throw new HttpsError(16, "unauthorized", "must be authenticated")
    }

    const daysToUnsub = request.data.days
    const fcmKey = request.data.fcmKey

    for (var i = 0; i < daysToUnsub.length; i++) {
        messaging.getMessaging().unsubscribeFromTopic([fcmKey], daysToUnsub[i]).then((res) => {
            return {message: "unsubscribed!"}
        })
        .catch((error) => {
            throw new HttpsError(2, "error", `${error}`)
        })
    }
})

exports.sendReminders2 = functions.pubsub
    .schedule("0 17 * * *")
    .onRun(async (context) => {
        const days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        const dayIndex = new Date().getDay()

        const message = {
            notification: {
                title: "Accountive",
                body: "Reminder to complete today's activities!"
            },
            topic: days[dayIndex]
        }

        messaging.getMessaging().send(message).then((response) => {
            logger.log("Reminder sent!", response)
        })
        .catch((error) => {
            logger.log("Error sending reminder: ", error)
        })
    })

exports.sendReminders = functions.pubsub
    .schedule("0 11 * * *")
    .onRun(async (context) => {
        const days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        const dayIndex = new Date().getDay()

        const message = {
            notification: {
                title: "Accountive",
                body: "Reminder to complete today's activities!"
            },
            topic: days[dayIndex]
        }

        messaging.getMessaging().send(message).then((response) => {
            logger.log("Reminder sent!", response)
        })
        .catch((error) => {
            logger.log("Error sending reminder: ", error)
        })
    })

exports.sendRemindersTest = onRequest((req, res) => {
    const days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        const dayIndex = new Date().getDay()

        const message = {
            notification: {
                title: "Accountive",
                body: "Reminder to complete today's activities!"
            },
            topic: days[dayIndex]
        }

        messaging.getMessaging().send(message).then((response) => {
            res.status(200).send("Reminders sent!")
        })
        .catch((error) => {
            res.json({"error": `${error}`})
        })
})

exports.resetActivities = functions.pubsub.schedule("0 22 * * *").onRun(async (context) => {
    const activitiesRef = getFirestore().collectionGroup("activities")
    const activities = await activitiesRef.where('isDone', '==', true).get()

    activities.forEach(async activityDoc => {
        activityDoc.ref.update({
            isDone: false
        })
    })

    const uidsRef = getFirestore().collectionGroup("uids")
    const uids = await uidsRef.where('doneCount', '>', 0).get()

    functions.logger.log("hello: ----->", uids)

    uids.forEach(async uidDoc => {
        uidDoc.ref.update({
            doneCount: 0
        })
    })
})