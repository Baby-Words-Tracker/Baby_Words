// The Cloud Functions for Firebase SDK to create Cloud Functions and triggers.
const {logger} = require("firebase-functions");

// The Firebase Admin SDK to access Firestore.
const admin = require("firebase-admin");
const {getAuth} = require("firebase-admin/auth");
const {FieldValue} = require("firebase-admin/firestore");

require("@google-cloud/storage");

// Import our auth module
const {Role} = require("./auth/roles");
const {giveClaimByEmail, removeClaimByEmail} = require("./auth/claims");
// eslint-disable-next-line max-len
const {checkIsAtLeast} = require("./auth/auth.js");

// Import migration functions
const {migrateToUserProfile} = require("./migration");

// functions
// v1 functions
const auth = require("firebase-functions/v1/auth");

// v2 functions
const https = require("firebase-functions/v2/https");
const {onSchedule} = require("firebase-functions/v2/scheduler");


admin.initializeApp();

const db = admin.firestore();

// Export migration function
exports.migrateToUserProfile = migrateToUserProfile;

// TODO: make these functions more generic/concise

/**
 * Creates UserProfile and sets default claims when a new user is created
 * @param {auth.UserRecord} user the user object
 */
exports.addDefaultClaim = auth.user().onCreate(async (user) => {
  try {
    // Set the custom claim 'parent' to true (default role)
    await getAuth().setCustomUserClaims(user.uid, {parent: true});
    logger.log(`Custom claim set for user ${user.uid}`);

    const displayName = user.displayName || null;
    let firstName = null;
    let lastName = null;
    if (displayName) {
      const parts = displayName.trim().split(/\s+/);
      if (parts.length > 0) {
        firstName = parts.shift();
        if (parts.length > 0) {
          lastName = parts.join(" ");
        }
      }
    }

    // Create UserProfile document in Firestore
    await db.collection("UserProfile").doc(user.uid).set({
      role: "parent", // Default role
      status: "active",
      email: user.email || null,
      name: user.displayName || null,
      firstName,
      lastName,
      emailVerified: user.emailVerified || false,
      twoFactorEnabled: false,
      acceptedPrivacyPolicy: false,
      surveyCompleted: false,
      childIDs: [],
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
    logger.log(`UserProfile created for user ${user.uid}`);
  } catch (error) {
    logger.error(`Error setting up new user ${user.uid}: ${error}`);
  }
});

/**
 * Checks if the uid value is set and thows an exception if not
 * @param {string} variable The UID of the user to assign the role to
 * @param {string} variableName The name to display if the variable is empty
 */
function checkEmpty(variable, variableName) {
  if (!variable) {
    throw new https.HttpsError(
        "invalid-argument", `Target user ${variableName} is required`);
  }
}

/**
 * Assigns the 'researcher' role to the target user
 * @param {https.CallableResponse<unknown>} req the data object
 * @param {https.CallableResponse<unknown>} context the context object
 * @return {Promise<{message: string}>} the success message
 * @throws {https.HttpsError} if the target UID is not provided,
 * if the user is not authenticated,
 * or if the user does not have the minimum role
 */
exports.giveResearcherClaim = https.onCall(async (req, context) => {
  const targetEmail = req.data.targetEmail;
  checkEmpty(targetEmail, "targetEmail");

  // Assign the 'researcher' role to the target user
  try {
    giveClaimByEmail(Role.researcher, Role.admin, targetEmail, req);
  } catch (error) {
    logger.error(`Failed to assign researcher role: ${error}`);
    return {
      message: `Failed to assign the ${Role.researcher.value.description}` +
        ` role to user with error: ${error}`,
    };
  }

  return {
    message: `User ${targetEmail} has been assigned the` +
      ` ${Role.researcher.value.description} role.`,
  };
});

/**
 * Removes the 'researcher' role from the target user
 * @param {https.CallableResponse<unknown>} req the data object
 * @param {https.CallableResponse<unknown>} context the context object
 * @return {Promise<{message: string}>} the success message
 * @throws {https.HttpsError} if the target UID is not provided,
 * if the user is not authenticated,
 * or if the user does not have the minimum role
 */
exports.removeResearcherClaim = https.onCall(async (req, context) => {
  const targetEmail = req.data.targetEmail;
  checkEmpty(targetEmail, "targetEmail");

  try {
    removeClaimByEmail(Role.researcher, Role.admin, targetEmail, req);
  } catch (error) {
    logger.error(`Failed to remove researcher role: ${error}`);
    return {
      message: `Failed to remove the ${Role.researcher.value.description}` +
        ` role from user with error: ${error}`,
    };
  }

  return {
    message: `User ${targetEmail} has been removed from the` +
      ` ${Role.researcher.value.description} role.`,
  };
});

/**
 * Assigns the 'parent' role to the target user
 * @param {https.CallableResponse<unknown>} req the data object
 * @param {https.CallableResponse<unknown>} context the context object
 * @return {Promise<{message: string}>} the success message
 * @throws {https.HttpsError} if the target UID is not provided,
 * if the user is not authenticated,
 * or if the user does not have the minimum role
 */
exports.giveParentClaim = https.onCall(async (req, context) => {
  const targetEmail = req.data.targetEmail;
  checkEmpty(targetEmail, "targetEmail");

  try {
    giveClaimByEmail(Role.parent, Role.admin, targetEmail, req);
  } catch (error) {
    logger.error(`Failed to assign parent role: ${error}`);
    return {
      message: `Failed to assign the ${Role.parent.value.description}` +
        ` role to user with error: ${error}`,
    };
  }

  return {
    message: `User ${targetEmail} has been assigned the` +
      ` ${Role.parent.value.description} role.`,
  };
});

/**
 * Removes the 'parent' role from the target user
 * @param {https.CallableResponse<unknown>} req the data object
 * @param {https.CallableResponse<unknown>} context the context object
 * @return {Promise<{message: string}>} the success message
 * @throws {https.HttpsError} if the target UID is not provided,
 * if the user is not authenticated,
 * or if the user does not have the minimum role
 */
exports.removeParentClaim = https.onCall(async (req, context) => {
  const targetEmail = req.data.targetEmail;
  checkEmpty(targetEmail, "targetEmail");

  try {
    removeClaimByEmail(Role.parent, Role.admin, targetEmail, req);
  } catch (error) {
    logger.error(`Failed to remove parent role: ${error}`);
    return {
      message: `Failed to remove the ${Role.parent.value.description}` +
        ` role from user with error: ${error}`,
    };
  }

  return {
    message: `User ${targetEmail} has been removed from the` +
      ` ${Role.parent.value.description} role.`,
  };
});

/**
 * Assigns the 'admin' role to the target user
 * @param {https.CallableResponse<unknown>} req the data object
 * @param {https.CallableResponse<unknown>} context the context object
 * @return {Promise<{message: string}>} the success message
 * @throws {https.HttpsError} if the target UID is not provided,
 * if the user is not authenticated,
 * or if the user does not have the minimum role
 */
exports.giveAdminClaim = https.onCall(async (req, context) => {
  const targetEmail = req.data.targetEmail;
  checkEmpty(targetEmail, "targetEmail");

  try {
    giveClaimByEmail(Role.admin, Role.admin, targetEmail, req);
  } catch (error) {
    logger.error(`Failed to assign admin role: ${error}`);
    return {
      message: `Failed to assign the ${Role.admin.value.description}` +
        ` role to user with error: ${error}`,
    };
  }

  return {
    message: `User ${targetEmail} has been assigned the` +
      ` ${Role.admin.value.description} role.`,
  };
});

/**
 * Removes the 'admin' role from the target user
 * @param {https.CallableResponse<unknown>} req the data object
 * @param {https.CallableResponse<unknown>} context the context object
 * @return {Promise<{message: string}>} the success message
 * @throws {https.HttpsError} if the target UID is not provided,
 * if the user is not authenticated,
 * or if the user does not have the minimum role
 */
exports.removeAdminClaim = https.onCall(async (req, context) => {
  const targetEmail = req.data.targetEmail;
  checkEmpty(targetEmail, "targetEmail");

  try {
    removeClaimByEmail(Role.admin, Role.admin, targetEmail, req);
  } catch (error) {
    logger.error(`Failed to remove admin role: ${error}`);
    return {
      message: `Failed to remove the ${Role.admin.value.description}` +
        ` role from user with error: ${error}`,
    };
  }

  return {
    message: `User ${targetEmail} has been removed from the` +
      ` ${Role.admin.value.description} role.`,
  };
});


// TODO: this is extremely insecure.
//       we need to check if the user is a parent of the child
// TODO: test if a parent can add a child they don't own to someone else
/**
 * Assigns a child to another parent
 * @param {https.CallableResponse<unknown>} req the data object
 * @param {https.CallableResponse<unknown>} context the context object
 * @return {Promise<{message: string}>} the success message
 * @throws {https.HttpsError} if the target email or child UID is not provided,
 * if the user is not authenticated,
 * if the is not already a parent of the child,
 * or if the user does not have the minimum role
 */
exports.addChildToOtherParent = https.onCall(async (req, context) => {
  const targetEmail = req.data.targetEmail;
  const childUid = req.data.childUid;

  checkEmpty(targetEmail, "targetEmail");
  checkEmpty(childUid, "childUid");

  if (targetEmail.length > 100) {
    throw new https.HttpsError(
        "invalid-argument",
        "Target email is too long",
    );
  }

  try {
    checkIsAtLeast(req, Role.parent);

    const userProfileCollection = db.collection("UserProfile");

    let targetUid;
    try {
      const userRecord = await getAuth().getUserByEmail(targetEmail);
      targetUid = userRecord.uid;
    } catch (error) {
      throw new https.HttpsError("not-found", `Parent was not found: ${error}`);
    }


    await db.runTransaction(async (transaction) => {
      const userRef = userProfileCollection.doc(req.auth.uid);
      const userSnaphot = await transaction.get(userRef);

      if (!userSnaphot.exists ||
        !userSnaphot.data().childIDs.includes(childUid)) {
        throw new https.HttpsError(
            "permission-denied",
            // eslint-disable-next-line max-len
            "You do must be a parent of the child to assign them to another parent",
        );
      }

      const parentRef = userProfileCollection.doc(targetUid);
      const parentUID = parentRef.id;

      const childCollection = db.collection("Child");
      const childRef = childCollection.doc(childUid);
      const childSnapshot = await transaction.get(childRef);

      if (!childSnapshot.exists) {
        throw new https.HttpsError(
            "not-found",
            "Child document not found",
        );
      }

      transaction.update(parentRef, {
        pendingChildIDs: admin.firestore.FieldValue.arrayUnion(childUid),
      });
    });
  } catch (error) {
    logger.error(`Failed to assign child to other parent: ${error}`);
    return {
      message: `Failed to assign child` +
        ` to parent with email: ${targetEmail} because of error: ${error}`,
    };
  }

  return {
    message: `User ${targetEmail} has been given the child.`,
  };
});

/**
 * Accepts a pending child share request
 */
exports.acceptChildShare = https.onCall(async (req) => {
  const childUid = req.data.childUid;
  checkEmpty(childUid, "childUid");

  try {
    checkIsAtLeast(req, Role.parent);
    const callerUid = req.auth.uid;
    const userProfileCollection = db.collection("UserProfile");

    await db.runTransaction(async (transaction) => {
      const userRef = userProfileCollection.doc(callerUid);
      const userSnapshot = await transaction.get(userRef);

      if (!userSnapshot.exists ||
          !(userSnapshot.data().pendingChildIDs || []).includes(childUid)) {
        throw new https.HttpsError(
            "not-found",
            "No pending share found for this child",
        );
      }

      const childRef = db.collection("Child").doc(childUid);

      transaction.update(userRef, {
        pendingChildIDs: admin.firestore.FieldValue.arrayRemove(childUid),
        childIDs: admin.firestore.FieldValue.arrayUnion(childUid),
      });
      transaction.update(childRef, {
        parentIDs: admin.firestore.FieldValue.arrayUnion(callerUid),
      });
    });
  } catch (error) {
    logger.error(`Failed to accept child share: ${error}`);
    return {message: `Failed to accept child share: ${error}`};
  }

  return {message: "Child share accepted successfully."};
});

/**
 * Declines a pending child share request
 */
exports.declineChildShare = https.onCall(async (req) => {
  const childUid = req.data.childUid;
  checkEmpty(childUid, "childUid");

  try {
    checkIsAtLeast(req, Role.parent);
    const callerUid = req.auth.uid;

    await db.collection("UserProfile").doc(callerUid).update({
      pendingChildIDs: admin.firestore.FieldValue.arrayRemove(childUid),
    });
  } catch (error) {
    logger.error(`Failed to decline child share: ${error}`);
    return {message: `Failed to decline child share: ${error}`};
  }

  return {message: "Child share declined."};
});

exports.getUserIdByEmail = https.onCall(async (req, context) => {
  const targetEmail = req.data.targetEmail;
  checkEmpty(targetEmail, "targetEmail");
  try {
    checkIsAtLeast(req, Role.admin);
    // Fetch the user record by email
    const userRecord = await getAuth().getUserByEmail(targetEmail);
    // Return the user's UID
    return {userId: userRecord.uid};
  } catch (error) {
    logger.error("Error fetching user UID by email:", error);
    throw new https.HttpsError(
        "not-found",
        `Failed to fetch user UID by email: ${error}`,
    );
  }
});


exports.getUserCustomClaims = https.onCall(async (req, context) => {
  const targetEmail = req.data.targetEmail;

  checkEmpty(targetEmail, "targetEmail");

  try {
    checkIsAtLeast(req, Role.admin);

    // Fetch the custom claims of the selected user
    const selectedUser = await admin.auth().getUserByEmail(targetEmail);

    // Return the user's custom claims
    return selectedUser.customClaims != null ? selectedUser.customClaims : {};
  } catch (error) {
    logger.error("Error fetching user custom claims:", error);
    throw new https.HttpsError(
        "not-found",
        `Failed to fetch user custom claims error: ${error}`);
  }
});


// !!! note: this function should only be called by admin users.
// Make sure to call checkIsAtLeast(req, Role.admin); before using it
const listAllUsers = async (nextPageToken) => {
  const users = [];
  logger.info("Listing all users...");

  try {
    // List batch of users, 1000 at a time.
    const listUsersResult = await getAuth()
        .listUsers(1000, nextPageToken);

    listUsersResult.users.forEach((userRecord) => {
      const user = userRecord.toJSON();
      // Remove sensitive information.
      // !!Don't include this unless you are migrating the
      //    authentication database.
      //    These hashes compromise password security fo all users if leaked!
      delete user.passwordHash;
      delete user.passwordSalt;

      // This data is unecessary for now, but not sensetive to my knowledge.
      delete user.tokensValidAfterTime;
      delete user.providerData;
      delete user.emailVerified;
      delete user.metadata;
      delete user.displayName;
      delete user.photoURL;
      delete user.phoneNumber;
      delete user.tenantId;

      // logger.info("user", user);

      // At this point, the user object should have the follwoing fields:
      // uid, email, disabled, and customClaims
      // email is the email of the user
      // uid is the unique id of the user
      // disabled is a boolean that indicates if the user account is disabled
      // customClaims is an object that contains the custom claims of the user
      users.push(user);
    });

    if (listUsersResult.pageToken) {
      // List next batch of users.
      const nextUsers = await listAllUsers(listUsersResult.pageToken);
      users.push(...nextUsers);
    }
  } catch (error) {
    logger.error("Error listing users:", error);
    throw new https.HttpsError(
        "internal",
        `Error listing users: ${error}`,
    );
  }

  logger.info("Finished listing users: ", users);

  return users;
};

exports.getEmailUIDTable = https.onCall(async (req, context) => {
  logger.info(`getEmailUIDTable called from account ID: ${req.auth.uid}`);
  try {
    checkIsAtLeast(req, Role.admin);
    // Start listing users from the beginning, 1000 at a time.
    const users = await listAllUsers();

    return {
      users: users,
    };
  } catch (error) {
    logger.error(`Error listing users: ${error}`);
    throw new https.HttpsError(
        "internal",
        `Error getting user list: ${error}`,
    );
  }
});

/**
 * Nightly Notification Job
 * Runs every day at 8:00 PM (America/Chicago)
 * Checks for users with 'nightlyNotificationsEnabled' and sends a prompt.
 */
exports.sendNightlyNotifications = onSchedule({
  schedule: "every day 20:00",
  timeZone: "America/Chicago",
}, async (event) => {
  logger.log("Starting nightly notification job...");

  try {
    const snapshot = await db.collection("UserProfile")
        .where("notificationsEnabled", "==", true)
        .where("nightlyNotificationsEnabled", "==", true)
        .get();

    if (snapshot.empty) {
      logger.log("No users found for nightly notifications.");
      return;
    }

    logger.log(`Found ${snapshot.size} users for nightly notifications.`);

    const messages = [];
    snapshot.docs.forEach((doc) => {
      const user = doc.data();
      if (user.fcmToken) {
        messages.push({
          token: user.fcmToken,
          notification: {
            title: "Nightly Word Check",
            body: "Time to log your little one's words for today!",
          },
        });
      }
    });

    if (messages.length > 0) {
      const response = await admin.messaging().sendEach(messages);
      logger.log(`Nightly: Sent ${response.successCount} messages, ` +
          `${response.failureCount} failed.`);
    }
  } catch (error) {
    logger.error("Error in nightly notification job:", error);
  }
});

/**
 * Weekly Notification Job
 * Runs every Monday at 9:00 AM (America/Chicago)
 * Checks for users with 'weeklyNotificationsEnabled' and sends a summary.
 */
exports.sendWeeklyNotifications = onSchedule({
  schedule: "every monday 9:00",
  timeZone: "America/Chicago",
}, async (event) => {
  logger.log("Starting weekly notification job...");

  try {
    const snapshot = await db.collection("UserProfile")
        .where("notificationsEnabled", "==", true)
        .where("weeklyNotificationsEnabled", "==", true)
        .get();

    if (snapshot.empty) {
      logger.log("No users found for weekly notifications.");
      return;
    }

    logger.log(`Found ${snapshot.size} users for weekly notifications.`);

    const messages = [];
    snapshot.docs.forEach((doc) => {
      const user = doc.data();
      if (user.fcmToken) {
        messages.push({
          token: user.fcmToken,
          notification: {
            title: "Weekly Summary",
            body: "Check out your child's progress from last week!",
          },
        });
      }
    });

    if (messages.length > 0) {
      const response = await admin.messaging().sendEach(messages);
      logger.log(`Weekly: Sent ${response.successCount} messages, ` +
          `${response.failureCount} failed.`);
    }
  } catch (error) {
    logger.error("Error in weekly notification job:", error);
  }
});

/**
 * Debug Notification Job
 * Runs every 5 minutes
 * Checks for users with 'notificationsEnabled' and logs them.
 */

// uncomment then firebase deploy to test

// exports.sendDebugNotifications = onSchedule({
//   schedule: "every 5 minutes",
// }, async (event) => {
//   logger.log("Starting debug notification job...");

//   try {
//     const snapshot = await db.collection("UserProfile")
//         .where("notificationsEnabled", "==", true)
//         .get();

//     if (snapshot.empty) {
//       logger.log("No users found for debug notifications.");
//       return;
//     }

//     logger.log(`Found ${snapshot.size} users for debug notifications.`);

//     const messages = [];
//     snapshot.docs.forEach((doc) => {
//       const user = doc.data();
//       if (user.fcmToken) {
//         messages.push({
//           token: user.fcmToken,
//           notification: {
//             title: "Debug Notification",
//             body: "This is a test notification sent every 5 minutes.",
//           },
//         });
//       }
//     });

//     if (messages.length > 0) {
//       const response = await admin.messaging().sendEach(messages);
//       logger.log(`Debug: Sent ${response.successCount} messages, ` +
//           `${response.failureCount} failed.`);
//     }
//   } catch (error) {
//     logger.error("Error in debug notification job:", error);
//   }
// });
