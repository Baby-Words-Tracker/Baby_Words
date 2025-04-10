// The Cloud Functions for Firebase SDK to create Cloud Functions and triggers.
const { logger } = require("firebase-functions");

// The Firebase Admin SDK to access Firestore.
const admin = require("firebase-admin");
const { getAuth } = require("firebase-admin/auth");

const { Storage } = require("@google-cloud/storage");

// Import our auth module
const { Role } = require("./auth/roles");
const { giveClaim, removeClaim } = require("./auth/claims");
// eslint-disable-next-line max-len
const { checkIsAtLeast } = require("./auth/auth.js");

// functions
// v1 functions
const auth = require("firebase-functions/v1/auth");

// v2 functions
const https = require("firebase-functions/v2/https");

admin.initializeApp();

const db = admin.firestore();
const storage = new Storage();

// TODO: make these functions more generic/concise

/**
 * Adds the Parent claim to the user when they are created
 * @param {auth.UserRecord} user the user object
 */
exports.addDefaultClaim = auth.user().onCreate(async (user) => {
  try {
    // Set the custom claim 'parent' to true
    await getAuth().setCustomUserClaims(user.uid, { parent: true });

    logger.log(`Custom claim set for user ${user.uid}`);
  } catch (error) {
    logger.error(`Error setting custom claim: ${error}`);
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
 * @param {https.CallableResponse<unknown>} data the data object
 * @param {https.CallableResponse<unknown>} context the context object
 * @return {Promise<{message: string}>} the success message
 * @throws {https.HttpsError} if the target UID is not provided,
 * if the user is not authenticated,
 * or if the user does not have the minimum role
 */
exports.giveResearcherClaim = https.onCall(async (req, context) => {
  const targetUid = req.data.targetUid;
  checkEmpty(targetUid, "targetUid");

  // Assign the 'researcher' role to the target user
  try {
    giveClaim(Role.researcher, Role.admin, targetUid, req);
  } catch (error) {
    logger.error(`Failed to assign researcher role: ${error}`);
    return {
      message: `Failed to assign the ${Role.researcher.value.description}` +
        ` role to user with error: ${error}`,
    };
  }

  return {
    message: `User ${targetUid} has been assigned the` +
      ` ${Role.researcher.value.description} role.`,
  };
});

/**
 * Removes the 'researcher' role from the target user
 * @param {https.CallableResponse<unknown>} data the data object
 * @param {https.CallableResponse<unknown>} context the context object
 * @return {Promise<{message: string}>} the success message
 * @throws {https.HttpsError} if the target UID is not provided,
 * if the user is not authenticated,
 * or if the user does not have the minimum role
 */
exports.removeResearcherClaim = https.onCall(async (req, context) => {
  const targetUid = req.data.targetUid;
  checkEmpty(targetUid, "targetUid");

  try {
    removeClaim(Role.researcher, Role.admin, targetUid, req);
  } catch (error) {
    logger.error(`Failed to remove researcher role: ${error}`);
    return {
      message: `Failed to remove the ${Role.researcher.value.description}` +
        ` role from user with error: ${error}`,
    };
  }

  return {
    message: `User ${targetUid} has been removed from the` +
      ` ${Role.researcher.value.description} role.`,
  };
});

/**
 * Assigns the 'parent' role to the target user
 * @param {https.CallableResponse<unknown>} data the data object
 * @param {https.CallableResponse<unknown>} context the context object
 * @return {Promise<{message: string}>} the success message
 * @throws {https.HttpsError} if the target UID is not provided,
 * if the user is not authenticated,
 * or if the user does not have the minimum role
 */
exports.giveParentClaim = https.onCall(async (req, context) => {
  const targetUid = req.data.targetUid;
  checkEmpty(targetUid, "targetUid");

  try {
    giveClaim(Role.parent, Role.researcher, targetUid, req);
  } catch (error) {
    logger.error(`Failed to assign parent role: ${error}`);
    return {
      message: `Failed to assign the ${Role.parent.value.description}` +
        ` role to user with error: ${error}`,
    };
  }

  return {
    message: `User ${targetUid} has been assigned the` +
      ` ${Role.parent.value.description} role.`,
  };
});

/**
 * Removes the 'parent' role from the target user
 * @param {https.CallableResponse<unknown>} data the data object
 * @param {https.CallableResponse<unknown>} context the context object
 * @return {Promise<{message: string}>} the success message
 * @throws {https.HttpsError} if the target UID is not provided,
 * if the user is not authenticated,
 * or if the user does not have the minimum role
 */
exports.removeParentClaim = https.onCall(async (req, context) => {
  const targetUid = req.data.targetUid;
  checkEmpty(targetUid, "targetUid");

  try {
    removeClaim(Role.parent, Role.admin, targetUid, req);
  } catch (error) {
    logger.error(`Failed to remove parent role: ${error}`);
    return {
      message: `Failed to remove the ${Role.parent.value.description}` +
        ` role from user with error: ${error}`,
    };
  }

  return {
    message: `User ${targetUid} has been removed from the` +
      ` ${Role.parent.value.description} role.`,
  };
});

/**
 * Assigns the 'admin' role to the target user
 * @param {https.CallableResponse<unknown>} data the data object
 * @param {https.CallableResponse<unknown>} context the context object
 * @return {Promise<{message: string}>} the success message
 * @throws {https.HttpsError} if the target UID is not provided,
 * if the user is not authenticated,
 * or if the user does not have the minimum role
 */
exports.giveAdminClaim = https.onCall(async (req, context) => {
  const targetUid = req.data.targetUid;
  checkEmpty(targetUid, "targetUid");

  try {
    giveClaim(Role.admin, Role.admin, targetUid, req);
  } catch (error) {
    logger.error(`Failed to assign admin role: ${error}`);
    return {
      message: `Failed to assign the ${Role.admin.value.description}` +
        ` role to user with error: ${error}`,
    };
  }

  return {
    message: `User ${targetUid} has been assigned the` +
      ` ${Role.admin.value.description} role.`,
  };
});

/**
 * Removes the 'admin' role from the target user
 * @param {https.CallableResponse<unknown>} data the data object
 * @param {https.CallableResponse<unknown>} context the context object
 * @return {Promise<{message: string}>} the success message
 * @throws {https.HttpsError} if the target UID is not provided,
 * if the user is not authenticated,
 * or if the user does not have the minimum role
 */
exports.removeAdminClaim = https.onCall(async (req, context) => {
  const targetUid = req.data.targetUid;
  checkEmpty(targetUid, "targetUid");

  try {
    removeClaim(Role.admin, Role.admin, targetUid, req);
  } catch (error) {
    logger.error(`Failed to remove admin role: ${error}`);
    return {
      message: `Failed to remove the ${Role.admin.value.description}` +
        ` role from user with error: ${error}`,
    };
  }

  return {
    message: `User ${targetUid} has been removed from the` +
      ` ${Role.admin.value.description} role.`,
  };
});


// TODO: this is extremely insecure.
//       we need to check if the user is a parent of the child
// TODO: test if a parent can add a child they don't own to someone else
/**
 * Assigns a child to another parent
 * @param {https.CallableResponse<unknown>} data the data object
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

  try {
    checkIsAtLeast(req, Role.parent);

    const parentCollection = db.collection("Parent");

    // const parentQuerySnapshot = await parentCollection
    //     .where("email", "==", targetEmail)
    //     .get();

    let targetUid;
    try {
      const userRecord = await getAuth().getUserByEmail(targetEmail);
      targetUid = userRecord.uid;
    } catch (error) {
      throw new https.HttpsError("not-found", `Parent was not found: ${error}`);
    }


    await db.runTransaction(async (transaction) => {
      const userRef = parentCollection.doc(req.auth.uid);
      const userSnaphot = await transaction.get(userRef);

      if (!userSnaphot.exists ||
        !userSnaphot.data().childIDs.includes(childUid)) {
        throw new https.HttpsError(
          "permission-denied",
          // eslint-disable-next-line max-len
          "You do must be a parent of the child to assign them to another parent",
        );
      }

      const parentRef = parentCollection.doc(targetUid);
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
        childIDs: admin.firestore.FieldValue.arrayUnion(childUid),
      });

      transaction.update(childRef, {
        parentIDs: admin.firestore.FieldValue.arrayUnion(parentUID),
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


exports.getUserCustomClaims = https.onCall(async (req, context) => {
  const targetUid = req.data.targetUid;

  checkEmpty(targetUid, "targetUid");

  try {
    checkIsAtLeast(req, Role.admin);

    // Fetch the custom claims of the selected user
    const selectedUser = await admin.auth().getUser(targetUid);

    // Return the user's custom claims
    return selectedUser.customClaims != null ? selectedUser.customClaims : {};
  } catch (error) {
    console.error("Error fetching user custom claims:", error);
    return {
      message: `Failed to fetch user custom claims error: ${error}`,
    };
  }
});

// get signed url - idk if this will even come close to working
exports.generateSignedUrl = https.onCall(async (req, res) => {
  try {
    logger.log(`Current filename passed: ${req.data.fileName}`);
    // Proceed with signed URL generation
    const bucketName = "baby-words-tracker-media";
    const fileName = req.data.fileName;
    const options = {
      version: "v4",
      action: "write",
      expires: Date.now() + 5 * 60 * 1000, // 5 minutes
    };

    const fireFile = storage.bucket(bucketName).file(fileName);
    await fireFile.save(Buffer.from(""), { contentType: "video/mp4" });

    const [url] = await fireFile.getSignedUrl(options);

    // res.status(200).send({url});
    return { url };
  } catch (error) {
    throw new https.HttpsError(
      "not-found",
      // eslint-disable-next-line max-len
      `Error generating signed url: ${error}, filename : ${req.data.fileName}`,
    );
  }
});

const listAllUsers = (nextPageToken) => {
  const users = [];

  // List batch of users, 1000 at a time.
  getAuth()
    .listUsers(1000, nextPageToken)
    .then((listUsersResult) => {
      listUsersResult.users.forEach((userRecord) => {
        console.log("user", userRecord.toJSON());
        users.push(userRecord.toJSON());
      });
      if (listUsersResult.pageToken) {
        // List next batch of users.
        listAllUsers(listUsersResult.pageToken);
      }
    })
    .catch((error) => {
      console.log("Error listing users:", error);
    });
  return users;
};

exports.getEmailUIDTable = https.onCall(async (req, context) => {
  try {
    checkIsAtLeast(req, Role.admin);
    // Start listing users from the beginning, 1000 at a time.
    const users = listAllUsers();

    return {
      users: users,
    };
  } catch (error) {
    console.message(`Error listing users: ${error}`);
    throw new https.HttpsError(
      "not-found",
      // eslint-disable-next-line max-len
      `Error generating signed url: ${error}, filename : ${req.data.fileName}`,
    );
  }
});
