// The Cloud Functions for Firebase SDK to create Cloud Functions and triggers.
const {logger} = require("firebase-functions");

// The Firebase Admin SDK to access Firestore.
const admin = require("firebase-admin");
const {getAuth} = require("firebase-admin/auth");

const {Storage} = require("@google-cloud/storage");

// Import our auth module
// eslint-disable-next-line max-len
const {Role, isDemoRole, getRoleFromToken, getRoleFromString} = require("./auth/roles");
const {giveClaimByEmail, removeClaimByEmail} = require("./auth/claims");
// eslint-disable-next-line max-len
const {checkIsAtLeast, checkAuthentication} = require("./auth/auth.js");

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
    const userRole = getRoleFromToken(req.auth.token);

    if (isDemoRole(userRole)) {
      logger.info(`User is a demo user, assigning demo_parent role`);
      // eslint-disable-next-line max-len
      await giveClaimByEmail(Role.demo_parent, Role.demo_admin, targetEmail, req);
    } else {
      await giveClaimByEmail(Role.parent, Role.admin, targetEmail, req);
    }
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
    const userRole = getRoleFromToken(req.auth.token);

    if (isDemoRole(userRole)) {
      logger.info(`User is a demo user, removing demo_parent role`);
      // eslint-disable-next-line max-len
      await removeClaimByEmail(Role.demo_parent, Role.demo_admin, targetEmail, req);
    } else {
      await removeClaimByEmail(Role.parent, Role.admin, targetEmail, req);
    }
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
    const userRole = getRoleFromToken(req.auth.token);

    if (isDemoRole(userRole)) {
      logger.info(`User is a demo user, giving demo_researcher role`);
      // eslint-disable-next-line max-len
      await giveClaimByEmail(Role.demo_researcher, Role.demo_admin, targetEmail, req);
    } else {
      await giveClaimByEmail(Role.researcher, Role.admin, targetEmail, req);
    }
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
    const userRole = getRoleFromToken(req.auth.token);

    if (isDemoRole(userRole)) {
      logger.info(`User is a demo user, removing demo_researcher role`);
      // eslint-disable-next-line max-len
      await removeClaimByEmail(Role.demo_researcher, Role.demo_admin, targetEmail, req);
    } else {
      await removeClaimByEmail(Role.researcher, Role.admin, targetEmail, req);
    }
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
    const userRole = getRoleFromToken(req.auth.token);

    if (isDemoRole(userRole)) {
      logger.info(`User is a demo user, giving demo_admin role`);
      // eslint-disable-next-line max-len
      await giveClaimByEmail(Role.demo_admin, Role.demo_admin, targetEmail, req);
    } else {
      await giveClaimByEmail(Role.admin, Role.admin, targetEmail, req);
    }
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
    const userRole = getRoleFromToken(req.auth.token);

    if (isDemoRole(userRole)) {
      logger.info(`User is a demo user, removing demo_admin role`);
      // eslint-disable-next-line max-len
      await removeClaimByEmail(Role.demo_admin, Role.demo_admin, targetEmail, req);
    } else {
      await removeClaimByEmail(Role.admin, Role.admin, targetEmail, req);
    }
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

exports.giveDemoParentClaim = https.onCall(async (req, context) => {
  const targetEmail = req.data.targetEmail;
  checkEmpty(targetEmail, "targetEmail");

  try {
    checkAuthentication(req.data);
    giveClaimByEmail(Role.demo_parent, Role.admin, targetEmail, req);
  } catch (error) {
    logger.error(`Failed to assign demo parent role: ${error}`);
    return {
      message: `Failed to assign the ${Role.demo_parent.value.description}` +
        ` role to user with error: ${error}`,
    };
  }

  return {
    message: `User ${targetEmail} has been assigned the` +
      ` ${Role.demo_parent.value.description} role.`,
  };
});

exports.removeDemoParentClaim = https.onCall(async (req, context) => {
  const targetEmail = req.data.targetEmail;
  checkEmpty(targetEmail, "targetEmail");

  try {
    checkAuthentication(req.data);
    removeClaimByEmail(Role.demo_parent, Role.admin, targetEmail, req);
  } catch (error) {
    logger.error(`Failed to remove demo parent role: ${error}`);
    return {
      message: `Failed to remove the ${Role.demo_parent.value.description}` +
        ` role from user with error: ${error}`,
    };
  }
  return {
    message: `User ${targetEmail} has been removed from the` +
      ` ${Role.demo_parent.value.description} role.`,
  };
});

exports.giveDemoResearcherClaim = https.onCall(async (req, context) => {
  const targetEmail = req.data.targetEmail;
  checkEmpty(targetEmail, "targetEmail");

  try {
    checkAuthentication(req.data);
    giveClaimByEmail(Role.demo_researcher, Role.admin, targetEmail, req);
  } catch (error) {
    logger.error(`Failed to assign demo researcher role: ${error}`);
    return {
      // eslint-disable-next-line max-len
      message: `Failed to assign the ${Role.demo_researcher.value.description}` +
        ` role to user with error: ${error}`,
    };
  }

  return {
    message: `User ${targetEmail} has been assigned the` +
      ` ${Role.demo_researcher.value.description} role.`,
  };
});

exports.removeDemoResearcherClaim = https.onCall(async (req, context) => {
  const targetEmail = req.data.targetEmail;
  checkEmpty(targetEmail, "targetEmail");

  try {
    checkAuthentication(req.data);
    removeClaimByEmail(Role.demo_researcher, Role.admin, targetEmail, req);
  } catch (error) {
    logger.error(`Failed to remove demo researcher role: ${error}`);
    return {
      // eslint-disable-next-line max-len
      message: `Failed to remove the ${Role.demo_researcher.value.description}` +
        ` role from user with error: ${error}`,
    };
  }

  return {
    message: `User ${targetEmail} has been removed from the` +
      ` ${Role.demo_researcher.value.description} role.`,
  };
});

exports.giveDemoAdminClaim = https.onCall(async (req, context) => {
  const targetEmail = req.data.targetEmail;
  checkEmpty(targetEmail, "targetEmail");

  try {
    checkAuthentication(req.data);
    giveClaimByEmail(Role.demo_admin, Role.admin, targetEmail, req);
  } catch (error) {
    logger.error(`Failed to assign demo admin role: ${error}`);
    return {
      message: `Failed to assign the ${Role.demo_admin.value.description}` +
        ` role to user with error: ${error}`,
    };
  }

  return {
    message: `User ${targetEmail} has been assigned the` +
      ` ${Role.demo_admin.value.description} role.`,
  };
});

exports.removeDemoAdminClaim = https.onCall(async (req, context) => {
  const targetEmail = req.data.targetEmail;
  checkEmpty(targetEmail, "targetEmail");

  try {
    checkAuthentication(req.data);
    removeClaimByEmail(Role.demo_admin, Role.admin, targetEmail, req);
  } catch (error) {
    logger.error(`Failed to remove demo admin role: ${error}`);
    return {
      message: `Failed to remove the ${Role.demo_admin.value.description}` +
        ` role from user with error: ${error}`,
    };
  }

  return {
    message: `User ${targetEmail} has been removed from the` +
      ` ${Role.demo_admin.value.description} role.`,
  };
});

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

    const userRole = getRoleFromToken(req.auth.token);
    const isDemo = isDemoRole(userRole);
    let parentCollection;
    let childCollection;

    if (isDemo) {
      checkIsAtLeast(req, Role.demo_parent);
      parentCollection = db.collection("Demo_Parent");
      childCollection = db.collection("Demo_Child");
    } else {
      checkIsAtLeast(req, Role.parent);
      parentCollection = db.collection("Parent");
      childCollection = db.collection("Child");
    }

    let targetUid;
    try {
      const userRecord = await getAuth().getUserByEmail(targetEmail);
      targetUid = userRecord.uid;
    } catch (error) {
      throw new https.HttpsError(
          "not-found",
          `Target parent does not exist: ${error}`,
      );
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

    const userRole = getRoleFromToken(req.auth.token);
    const isNotDemo = !isDemoRole(userRole);

    if (isNotDemo) {
      checkIsAtLeast(req, Role.admin);

      // Fetch the custom claims of the selected user
      const selectedUser = await admin.auth().getUserByEmail(targetEmail);

      // Return the user's custom claims
      return selectedUser.customClaims != null ? selectedUser.customClaims : {};
    } else {
      checkIsAtLeast(req, Role.demo_admin);

      // Fetch the custom claims of the selected user
      const selectedUser = await admin.auth().getUserByEmail(targetEmail);

      // filter the user's custom claims to only include demo roles
      // and unauthenticated
      const demoRoles = Object.fromEntries(
          Object.entries(selectedUser.customClaims || {}).filter(
              ([key, value]) =>
                isDemoRole(getRoleFromString(key)),
          ),
      );

      // Return the user's demo custom claims
      return selectedUser.customClaims != null ? demoRoles : {};
    }
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

    const userRole = getRoleFromToken(req.auth.token);
    const isDemo = isDemoRole(userRole);

    if (isDemo) {
      checkIsAtLeast(req, Role.demo_parent);
    } else {
      checkIsAtLeast(req, Role.parent);
    }
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

exports.generateSignedDownloadUrl = https.onCall(async (req, context) => {
  logger.log(`Current filename passed: ${req.data.fileName}`);

  try {
    checkAuthentication(req.data);

    const userRole = getRoleFromToken(req.auth.token);
    const isDemo = isDemoRole(userRole);

    if (isDemo) {
      checkIsAtLeast(req, Role.demo_parent);
    } else {
      checkIsAtLeast(req, Role.parent);
    }
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
