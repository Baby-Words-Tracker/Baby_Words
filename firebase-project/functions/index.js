// The Cloud Functions for Firebase SDK to create Cloud Functions and triggers.
const {logger} = require("firebase-functions");

// The Firebase Admin SDK to access Firestore.
const admin = require("firebase-admin");
const {getAuth} = require("firebase-admin/auth");

const {Storage} = require("@google-cloud/storage");

// Import our auth module
// eslint-disable-next-line max-len
const {Role} = require("./auth/roles.js");
const {isDemoRoleFromToken} = require("./auth/demo_role.js");
const {Type, getTypeFromString} = require("./auth/types");
// eslint-disable-next-line max-len
const {giveClaimByEmail, removeClaimByEmail, setTypeClaimByEmail} = require("./auth/claims");
// eslint-disable-next-line max-len
const {checkIsAtLeast, checkAuthentication, checkDemoStatusesMatch} = require("./auth/auth.js");

// functions
// v1 functions
const auth = require("firebase-functions/v1/auth");

// v2 functions
const https = require("firebase-functions/v2/https");

// path
const path = require("path");

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
    await getAuth().setCustomUserClaims(user.uid, {parent: true,
      parent_type: true});

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
    checkAuthentication(req.data);
    await giveClaimByEmail(Role.parent, Role.admin, targetEmail, req);
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
    checkAuthentication(req.data);
    await removeClaimByEmail(Role.parent, Role.admin, targetEmail, req);
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
    checkAuthentication(req.data);
    await giveClaimByEmail(Role.researcher, Role.admin, targetEmail, req);
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
 * @param {https.CallableResponse<unknown>} req the request object
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
    checkAuthentication(req.data);
    await removeClaimByEmail(Role.researcher, Role.admin, targetEmail, req);
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
    checkAuthentication(req.data);
    await giveClaimByEmail(Role.admin, Role.admin, targetEmail, req);
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
    checkAuthentication(req.data);
    await removeClaimByEmail(Role.admin, Role.admin, targetEmail, req);
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

exports.giveDemoClaim = https.onCall(async (req, context) => {
  const targetEmail = req.data.targetEmail;
  checkEmpty(targetEmail, "targetEmail");

  try {
    checkAuthentication(req.data);
    const isDemo = isDemoRoleFromToken(req.auth.token);
    if (isDemo) {
      logger.info(`Demo user ${req.auth.uid} attempted to assign demo role`);
      return {
        message: `Demo users cannot assign or remove the demo role.`,
      };
    } else {
      giveClaimByEmail(Role.demo, Role.admin, targetEmail, req);
    }
  } catch (error) {
    logger.error(`Failed to set role by email: ${error}`);
    return {
      message: `Failed to set the role by email; Error: ${error}`,
    };
  }

  logger.info(`User ${targetEmail} has been set to the role` +
   ` ${Role.demo.value.description}.`);
  return {
    message: `User ${targetEmail} has been set to the role` +
     ` ${Role.demo.value.description}.`,
  };
});

exports.removeDemoClaim = https.onCall(async (req, context) => {
  const targetEmail = req.data.targetEmail;
  checkEmpty(targetEmail, "targetEmail");

  try {
    checkAuthentication(req.data);
    const isDemo = isDemoRoleFromToken(req.auth.token);
    if (isDemo) {
      logger.info(`Demo user ${req.auth.uid} attempted to remove demo role`);
      return {
        message: `Demo users cannot assign or remove the demo role.`,
      };
    } else {
      removeClaimByEmail(Role.demo, Role.admin, targetEmail, req);
    }
  } catch (error) {
    logger.error(`Failed to remove role by email: ${error}`);
    return {
      message: `Failed to remove the role by email; Error: ${error}`,
    };
  }
  logger.info(`User ${targetEmail} has been removed from the role` +
   ` ${Role.demo.value.description}.`);
  return {
    message: `User ${targetEmail} has been removed from the role` +
     ` ${Role.demo.value.description}.`,
  };
});

exports.setTypeClaim = https.onCall(async (req, context) => {
  const targetEmail = req.data.targetEmail;
  const newTypeString = req.data.newType;
  checkEmpty(targetEmail, "targetEmail");
  checkEmpty(newTypeString, "newType");

  const newType = getTypeFromString(newTypeString);
  if (newType === Type.unauthenticated) {
    throw new https.HttpsError(
        "invalid-argument",
        "Cannot set type to unauthenticated",
    );
  }

  try {
    checkAuthentication(req.data);
    setTypeClaimByEmail(newType, Role.admin, targetEmail, req);
  } catch (error) {
    logger.error(`Failed to set type by email: ${error}`);
    return {
      message: `Failed to set the type by email; Error: ${error}`,
    };
  }

  return {
    message: `User ${targetEmail} has been set to the type` +
     ` ${newType.value.description}.`,
  };
});

// TODO: test if a parent can add a child they don't own to someone else
/**
 * Assigns a child to another parent
 * @param {https.CallableResponse<unknown>} req the data object
 * @param {https.CallableResponse<unknown>} context the context object
 * @return {Promise<{message: string}>} the success message
 * @throws {https.HttpsError} if the target email or child UID is not provided,
 *  if the user is not authenticated,
 *  if the user is not already a parent of the child,
 *  or if the user does not have the minimum role
 */
exports.addChildToOtherParent = https.onCall(async (req, context) => {
  const targetEmail = req.data.targetEmail;
  const childUid = req.data.childUid;

  const uid = req.auth.uid;
  checkEmpty(uid, "uid");

  checkEmpty(targetEmail, "targetEmail");
  checkEmpty(childUid, "childUid");

  if (targetEmail.length > 100) {
    throw new https.HttpsError(
        "invalid-argument",
        "Target email is too long",
    );
  }
  // TODO: add regex to check if the email is valid.
  //  I don't think this is a security issue, but we should still validate it
  // const emailRegex = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;

  try {
    checkAuthentication(req.data);
    checkIsAtLeast(req, Role.parent);

    const isDemoUser = isDemoRoleFromToken(req.auth.token);
    let parentCollection;
    let childCollection;

    if (isDemoUser) {
      parentCollection = db.collection("Demo_Parent");
      childCollection = db.collection("Demo_Child");
    } else {
      parentCollection = db.collection("Parent");
      childCollection = db.collection("Child");
    }

    let targetUserRecord;
    let targetUid;
    try {
      targetUserRecord = await getAuth().getUserByEmail(targetEmail);
      targetUid = targetUserRecord.uid;
    } catch (error) {
      throw new https.HttpsError(
          "not-found",
          `Target parent does not exist: ${error}`,
      );
    }

    if (isDemoUser) {
      const targetIsDemoUser = isDemoRoleFromToken(targetUserRecord.token);
      if (!targetIsDemoUser) {
        logger.info(`Demo user ${req.auth.uid} ` +
          `attempted to assign child to non-demo user`);
        throw new https.HttpsError(
            "permission-denied",
            "Demo users can only interact with other demo users.",
        );
      }
    }

    await db.runTransaction(async (transaction) => {
      const userRef = parentCollection.doc(req.auth.uid);
      const userSnapshot = await transaction.get(userRef);

      if (!userSnapshot.exists) {
        throw new https.HttpsError(
            "not-found",
            "User document not found",
        );
      }

      if (!userSnapshot.data().childIDs.includes(childUid)) {
        throw new https.HttpsError(
            "permission-denied",
            // eslint-disable-next-line max-len
            "You do must be a parent of the child to assign them to another parent. (1)",
        );
      }

      const parentRef = parentCollection.doc(targetUid);
      const parentUID = parentRef.id;
      const parentSnapshot = await transaction.get(parentRef);

      if (!parentSnapshot.exists) {
        throw new https.HttpsError(
            "not-found",
            "Target parent document not found",
        );
      }

      const childRef = childCollection.doc(childUid);
      const childSnapshot = await transaction.get(childRef);

      if (!childSnapshot.exists) {
        throw new https.HttpsError(
            "not-found",
            "Child document not found",
        );
      }

      if (!childSnapshot.data().parentIDs.includes(uid)) {
        throw new https.HttpsError(
            "permission-denied",
            // eslint-disable-next-line max-len
            "You do must be a parent of the child to assign them to another parent. (2)",
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

exports.getUserIdByEmail = https.onCall(async (req, context) => {
  const targetEmail = req.data.targetEmail;
  checkEmpty(targetEmail, "targetEmail");
  try {
    checkIsAtLeast(req, Role.admin);
    // Fetch the user record by email
    const userRecord = await getAuth().getUserByEmail(targetEmail);
    checkDemoStatusesMatch(req, userRecord);
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

// TODO: decide if this needs to be demo accessible at all
exports.getUserCustomClaims = https.onCall(async (req, context) => {
  const targetEmail = req.data.targetEmail;

  checkEmpty(targetEmail, "targetEmail");

  try {
    checkAuthentication(req.data);
    checkIsAtLeast(req, Role.admin);

    // Fetch the custom claims of the selected user
    const selectedUserRecord = await admin.auth().getUserByEmail(targetEmail);

    checkDemoStatusesMatch(req, selectedUserRecord);

    // Return the user's custom claims
    return selectedUserRecord.customClaims != null ?
           selectedUserRecord.customClaims :
           {};
  } catch (error) {
    logger.error("Error fetching user custom claims:", error);
    throw new https.HttpsError(
        "not-found",
        `Failed to fetch user custom claims error: ${error}`);
  }
});

exports.generateSignedUploadUrl = https.onCall(async (req, context) => {
  logger.log(`Current filename passed: ${req.data.fileName}`);

  try {
    checkAuthentication(req.data);
    checkIsAtLeast(req, Role.parent);
  } catch (error) {
    logger.error(`User does not have permission to upload: ${error}`);
    throw new https.HttpsError(
        "permission-denied",
        `User does not have permission to upload: ${error}`,
    );
  }

  // code to validate the file name
  const rawFileName = req.data.fileName;

  // Reject obviously bad characters
  if (
    typeof rawFileName !== "string" ||
      rawFileName.includes("/") ||
      rawFileName.includes("..")
  ) {
    // eslint-disable-next-line max-len
    logger.info(`User ${req.auth.uid} attempted illegal file name: ${rawFileName}`);
    throw new https.HttpsError(
        "invalid-argument",
        "Filename cannot be an address",
    );
  }

  // Ensure the file name contains only valid characters
  if (!/^[a-zA-Z0-9._-]+$/.test(rawFileName)) {
    throw new https.HttpsError(
        "invalid-argument",
        "Invalid characters in file name",
    );
  }

  // TODO: this might cause issues on an IOS device
  //    if videos are stored in a different format
  // Ensure the file name ends with .mp4
  if (!rawFileName.toLowerCase().endsWith(".mp4")) {
    throw new https.HttpsError(
        "invalid-argument",
        "File extension must be .mp4",
    );
  }

  // Ensure normalized path is within user directory
  const userId = req.auth.uid;
  const filePath = path.posix.normalize(`${userId}/${rawFileName}`);
  if (!filePath.startsWith(`${userId}/`)) {
    throw new https.HttpsError(
        "permission-denied",
        "Illegal file path traversal attempt",
    );
  }

  try {
    // Proceed with signed URL generation
    const bucketName = "baby-words-tracker-media";

    const options = {
      version: "v4",
      action: "write",
      expires: Date.now() + 5 * 60 * 1000, // 5 minutes
      contentType: "video/mp4", // Ensures Cloud Storage knows the format
    };

    const fireFile = storage.bucket(bucketName).file(filePath);
    await fireFile.save(Buffer.from(""), {
      contentType: "video/mp4",
    });

    const [url] = await fireFile.getSignedUrl(options);

    // res.status(200).send({url});
    return {url};
  } catch (error) {
    throw new https.HttpsError(
        "not-found",
        // eslint-disable-next-line max-len
        `Error generating signed url: ${error}, filename : ${req.data.fileName}`,
    );
  }
});

// TODO: verify that this function is secure
exports.generateSignedDownloadUrl = https.onCall(async (req, context) => {
  logger.log(`Current filename passed: ${req.data.fileName}`);

  try {
    checkAuthentication(req.data);
    checkIsAtLeast(req, Role.parent);
  } catch (error) {
    logger.error(`User does not have permission to upload: ${error}`);
    throw new https.HttpsError(
        "permission-denied",
        `User does not have permission to upload: ${error}`,
    );
  }

  // Proceed with signed URL generation
  const bucketName = "baby-words-tracker-media";

  // code to validate the file name
  const rawFileName = req.data.fileName;

  // Reject obviously bad characters
  if (
    typeof rawFileName !== "string" ||
      rawFileName.includes("/") ||
      rawFileName.includes("..")
  ) {
    throw new https.HttpsError("invalid-argument", "Invalid file name");
  }

  // Ensure normalized path is within user directory
  const userId = req.auth.uid;
  const filePath = path.posix.normalize(`${userId}/${rawFileName}`);
  if (!filePath.startsWith(`${userId}/`)) {
    // eslint-disable-next-line max-len
    logger.info(`User ${userId} attempted illegal file path traversal: ${filePath}`);
    throw new https.HttpsError(
        "permission-denied",
        "Illegal file path traversal attempt",
    );
  }

  try {
    const options = {
      version: "v4",
      action: "read",
      expires: Date.now() + 5 * 60 * 1000, // 5 minutes
      // contentType: "video/mp4", // Ensures Cloud Storage knows the format
    };

    const fireFile = storage.bucket(bucketName).file(filePath);

    const [url] = await fireFile.getSignedUrl(options);

    // res.status(200).send({url});
    return {url};
  } catch (error) {
    throw new https.HttpsError(
        "not-found",
        // eslint-disable-next-line max-len
        `Error generating signed url: ${error}, filename : ${req.data.fileName}`,
    );
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
    checkIsAtLeast(req, Role.admin, true);

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
