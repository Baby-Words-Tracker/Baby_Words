// The Cloud Functions for Firebase SDK to create Cloud Functions and triggers.
const {logger} = require("firebase-functions");

// The Firebase Admin SDK to access Firestore.
const admin = require("firebase-admin");
const {getAuth} = require("firebase-admin/auth");

const {Storage} = require("@google-cloud/storage");

// Import our auth module
const {Role} = require("./auth/roles");
const {giveClaim, removeClaim} = require("./auth/claims");
// eslint-disable-next-line max-len
const {checkAuthentication, checkIsAtLeast, isAuthenticated} = require("./auth/auth.js");

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
    await getAuth().setCustomUserClaims(user.uid, {parent: true});

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
exports.giveResearcherClaim = https.onCall(async (data, context) => {
  const targetUid = data.data.targetUid;
  checkEmpty(targetUid, "targetUid");

  // Assign the 'researcher' role to the target user
  try {
    giveClaim(Role.researcher, Role.admin, targetUid, data);
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
exports.removeResearcherClaim = https.onCall(async (data, context) => {
  const targetUid = data.data.targetUid;
  checkEmpty(targetUid, "targetUid");

  try {
    removeClaim(Role.researcher, Role.admin, targetUid, data);
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
exports.giveParentClaim = https.onCall(async (data, context) => {
  const targetUid = data.data.targetUid;
  checkEmpty(targetUid, "targetUid");

  try {
    giveClaim(Role.parent, Role.researcher, targetUid, data);
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
exports.removeParentClaim = https.onCall(async (data, context) => {
  const targetUid = data.data.targetUid;
  checkEmpty(targetUid, "targetUid");

  try {
    removeClaim(Role.parent, Role.admin, targetUid, data);
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
exports.giveAdminClaim = https.onCall(async (data, context) => {
  const targetUid = data.data.targetUid;
  checkEmpty(targetUid, "targetUid");

  try {
    giveClaim(Role.admin, Role.admin, targetUid, data);
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
exports.removeAdminClaim = https.onCall(async (data, context) => {
  const targetUid = data.data.targetUid;
  checkEmpty(targetUid, "targetUid");

  try {
    removeClaim(Role.admin, Role.admin, targetUid, data);
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
exports.addChildToOtherParent = https.onCall(async (data, context) => {
  const targetEmail = data.data.targetEmail;
  const childUid = data.data.childUid;

  checkEmpty(targetEmail, "targetEmail");
  checkEmpty(childUid, "childUid");

  try {
    checkAuthentication(data);

    // TODO: is this necessary?
    checkIsAtLeast(data, Role.parent);

    const parentCollection = db.collection("Parent");

    const parentQuerySnapshot = await parentCollection
        .where("email", "==", targetEmail)
        .get();

    if (parentQuerySnapshot.empty) {
      throw new https.HttpsError("not-found", "Parent with email not found");
    }

    await db.runTransaction(async (transaction) => {
      const userRef = parentCollection.doc(data.auth.uid);
      const userSnaphot = await transaction.get(userRef);

      if (!userSnaphot.exists ||
          !userSnaphot.data().childIDs.includes(childUid)) {
        throw new https.HttpsError(
            "permission-denied",
            // eslint-disable-next-line max-len
            "You do must be a parent of the child to assign them to another parent",
        );
      }

      const parentRef = parentQuerySnapshot.docs[0].ref;
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


exports.getUserCustomClaims = https.onCall(async (data, context) => {
  const targetUid = data.data.targetUid;

  checkEmpty(targetUid, "targetUid");

  try {
    checkAuthentication(data);

    checkIsAtLeast(data, Role.admin);

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
exports.generateSignedUrl = https.onRequest(async (req, res) => {
  // const authToken = req.headers.authorization?.split('Bearer ')[1];

  // if (!authToken) {
  //   return res.status(401).send({ error: 'Unauthorized: Missing token' });
  // }

  isAuthenticated(req);

  try {
    // Verify the token
    // TODO: is this right? i dont think so
    await admin.auth().verifyIdToken(req.auth);

    // Proceed with signed URL generation
    const bucketName = "baby-words-tracker-media";
    const fileName = req.body.fileName;
    const options = {
      version: "v4",
      action: "write",
      expires: Date.now() + 5 * 60 * 1000, // 5 minutes
    };

    const [url] = await storage
        .bucket(bucketName)
        .file(fileName)
        .getSignedUrl(options);

    res.status(200).send({url});
  } catch (error) {
    res.status(401).send({error: "Unauthorized: Invalid token"});
  }
});
