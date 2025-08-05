// The Cloud Functions for Firebase SDK to create Cloud Functions and triggers.
const {logger} = require("firebase-functions");

// The Firebase Admin SDK to access Firestore.
const admin = require("firebase-admin");
// eslint-disable-next-line no-unused-vars
const {getAuth, UserRecord} = require("firebase-admin/auth");

const {Storage} = require("@google-cloud/storage");

// Import our auth module
// eslint-disable-next-line max-len
const {Role} = require("./auth/roles.js");
const {isDemoRoleFromClaimsList} = require("./auth/demo_role.js");
// eslint-disable-next-line max-len
const {Type, getTypeFromString} = require("./auth/types");
// eslint-disable-next-line max-len
const {giveClaimByEmail, removeClaimByEmail, setTypeClaimByEmail} = require("./auth/claims");
// eslint-disable-next-line max-len
const {checkIsAtLeast, checkAuthentication, checkDemoStatusesMatch} = require("./auth/auth.js");

// functions
// v1 functions
const auth = require("firebase-functions/v1/auth");

// v2 functions
const {
  onCall,
  HttpsError,
  // eslint-disable-next-line no-unused-vars
  CallableResponse,
  // eslint-disable-next-line no-unused-vars
  CallableRequest,
} = require("firebase-functions/v2/https");

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
    throw new HttpsError(
        "invalid-argument", `Target user ${variableName} is required`);
  }
}

/**
 * Assigns the 'parent' role to the target user
 * @param {CallableRequest} req the data object
 * @param {CallableResponse} context the context object
 * @return {Promise<{message: string}>} the success message
 * @throws {HttpsError} if the target UID is not provided,
 * if the user is not authenticated,
 * or if the user does not have the minimum role
 */
exports.giveParentClaim = onCall(async (request, context) => {
  const targetEmail = request.data.targetEmail;
  checkEmpty(targetEmail, "targetEmail");

  try {
    // TODO: fix check authentication. It blocks all requests
    checkAuthentication(request);
    await giveClaimByEmail(Role.parent, Role.admin, targetEmail, request);
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
 * @param {CallableResponse<unknown>} req the data object
 * @param {CallableResponse<unknown>} context the context object
 * @return {Promise<{message: string}>} the success message
 * @throws {HttpsError} if the target UID is not provided,
 * if the user is not authenticated,
 * or if the user does not have the minimum role
 */
exports.removeParentClaim = onCall(async (request, context) => {
  const targetEmail = request.data.targetEmail;
  checkEmpty(targetEmail, "targetEmail");

  try {
    checkAuthentication(request);
    await removeClaimByEmail(Role.parent, Role.admin, targetEmail, request);
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
 * @param {CallableResponse<unknown>} req the data object
 * @param {CallableResponse<unknown>} context the context object
 * @return {Promise<{message: string}>} the success message
 * @throws {HttpsError} if the target UID is not provided,
 * if the user is not authenticated,
 * or if the user does not have the minimum role
 */
exports.giveResearcherClaim = onCall(async (request, context) => {
  const targetEmail = request.data.targetEmail;
  checkEmpty(targetEmail, "targetEmail");

  // Assign the 'researcher' role to the target user
  try {
    checkAuthentication(request);
    await giveClaimByEmail(Role.researcher, Role.admin, targetEmail, request);
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
 * @param {CallableResponse<unknown>} req the request object
 * @param {CallableResponse<unknown>} context the context object
 * @return {Promise<{message: string}>} the success message
 * @throws {HttpsError} if the target UID is not provided,
 * if the user is not authenticated,
 * or if the user does not have the minimum role
 */
exports.removeResearcherClaim = onCall(async (request, context) => {
  const targetEmail = request.data.targetEmail;
  checkEmpty(targetEmail, "targetEmail");

  try {
    checkAuthentication(request);
    await removeClaimByEmail(Role.researcher, Role.admin, targetEmail, request);
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
 * @param {CallableResponse<unknown>} req the data object
 * @param {CallableResponse<unknown>} context the context object
 * @return {Promise<{message: string}>} the success message
 * @throws {HttpsError} if the target UID is not provided,
 * if the user is not authenticated,
 * or if the user does not have the minimum role
 */
exports.giveAdminClaim = onCall(async (request, context) => {
  const targetEmail = request.data.targetEmail;
  checkEmpty(targetEmail, "targetEmail");

  try {
    checkAuthentication(request);
    await giveClaimByEmail(Role.admin, Role.admin, targetEmail, request);
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
 * @param {CallableResponse<unknown>} req the data object
 * @param {CallableResponse<unknown>} context the context object
 * @return {Promise<{message: string}>} the success message
 * @throws {HttpsError} if the target UID is not provided,
 * if the user is not authenticated,
 * or if the user does not have the minimum role
 */
exports.removeAdminClaim = onCall(async (request, context) => {
  const targetEmail = request.data.targetEmail;
  checkEmpty(targetEmail, "targetEmail");

  try {
    checkAuthentication(request);
    await removeClaimByEmail(Role.admin, Role.admin, targetEmail, request);
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

exports.giveDemoClaim = onCall(async (request, context) => {
  const targetEmail = request.data.targetEmail;
  checkEmpty(targetEmail, "targetEmail");

  try {
    checkAuthentication(request);
    const isDemo = isDemoRoleFromClaimsList(request.auth.token);
    if (isDemo) {
      // eslint-disable-next-line max-len
      logger.info(`Demo user ${request.auth.uid} attempted to assign demo role`);
      return {
        message: `Demo users cannot assign or remove the demo role.`,
      };
    } else {
      giveClaimByEmail(Role.demo, Role.admin, targetEmail, request);
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

exports.removeDemoClaim = onCall(async (request, context) => {
  const targetEmail = request.data.targetEmail;
  checkEmpty(targetEmail, "targetEmail");

  try {
    checkAuthentication(request);
    const isDemo = isDemoRoleFromClaimsList(request.auth.token);
    if (isDemo) {
      // eslint-disable-next-line max-len
      logger.info(`Demo user ${request.auth.uid} attempted to remove demo role`);
      return {
        message: `Demo users cannot assign or remove the demo role.`,
      };
    } else {
      removeClaimByEmail(Role.demo, Role.admin, targetEmail, request);
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

exports.setTypeClaim = onCall(async (request, context) => {
  const targetEmail = request.data.targetEmail;
  const newTypeString = request.data.newType;
  checkEmpty(targetEmail, "targetEmail");
  checkEmpty(newTypeString, "newType");

  const newType = getTypeFromString(newTypeString);
  if (newType === Type.unauthenticated) {
    throw new HttpsError(
        "invalid-argument",
        "Cannot set type to unauthenticated",
    );
  }

  try {
    checkAuthentication(request);
    setTypeClaimByEmail(newType, Role.admin, targetEmail, request);
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
 * @param {CallableResponse<unknown>} req the data object
 * @param {CallableResponse<unknown>} context the context object
 * @return {Promise<{message: string}>} the success message
 * @throws {HttpsError} if the target email or child UID is not provided,
 *  if the user is not authenticated,
 *  if the user is not already a parent of the child,
 *  or if the user does not have the minimum role
 */
exports.addChildToOtherParent = onCall(async (request, context) => {
  const targetEmail = request.data.targetEmail;
  const childUid = request.data.childUid;

  const uid = request.auth.uid;
  checkEmpty(uid, "uid");

  checkEmpty(targetEmail, "targetEmail");
  checkEmpty(childUid, "childUid");

  if (targetEmail.length > 100) {
    throw new HttpsError(
        "invalid-argument",
        "Target email is too long",
    );
  }
  // TODO: add regex to check if the email is valid.
  //  I don't think this is a security issue, but we should still validate it
  // const emailRegex = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;

  try {
    checkAuthentication(request);
    checkIsAtLeast(request, Role.parent);

    const isDemoUser = isDemoRoleFromClaimsList(request.auth.token);
    let parentCollection;
    let childCollection;

    if (isDemoUser) {
      parentCollection = db.collection("demo_Parent");
      childCollection = db.collection("demo_Child");
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
      throw new HttpsError(
          "not-found",
          `Target parent does not exist: ${error}`,
      );
    }

    if (isDemoUser) {
      const targetIsDemoUser = isDemoRoleFromClaimsList(targetUserRecord.token);
      if (!targetIsDemoUser) {
        logger.info(`Demo user ${request.auth.uid} ` +
          `attempted to assign child to non-demo user`);
        throw new HttpsError(
            "permission-denied",
            "Demo users can only interact with other demo users.",
        );
      }
    }

    await db.runTransaction(async (transaction) => {
      const userRef = parentCollection.doc(request.auth.uid);
      const userSnapshot = await transaction.get(userRef);

      if (!userSnapshot.exists) {
        throw new HttpsError(
            "not-found",
            "User document not found",
        );
      }

      if (!userSnapshot.data().childIDs.includes(childUid)) {
        throw new HttpsError(
            "permission-denied",
            // eslint-disable-next-line max-len
            "You do must be a parent of the child to assign them to another parent. (1)",
        );
      }

      const parentRef = parentCollection.doc(targetUid);
      const parentUID = parentRef.id;
      const parentSnapshot = await transaction.get(parentRef);

      if (!parentSnapshot.exists) {
        throw new HttpsError(
            "not-found",
            "Target parent document not found",
        );
      }

      const childRef = childCollection.doc(childUid);
      const childSnapshot = await transaction.get(childRef);

      if (!childSnapshot.exists) {
        throw new HttpsError(
            "not-found",
            "Child document not found",
        );
      }

      if (!childSnapshot.data().parentIDs.includes(uid)) {
        throw new HttpsError(
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

exports.getUserIdByEmail = onCall(async (request, context) => {
  const targetEmail = request.data.targetEmail;
  checkEmpty(targetEmail, "targetEmail");
  try {
    checkIsAtLeast(request, Role.admin);
    // Fetch the user record by email
    const userRecord = await getAuth().getUserByEmail(targetEmail);
    checkDemoStatusesMatch(request, userRecord);
    // Return the user's UID
    return {userId: userRecord.uid};
  } catch (error) {
    logger.error("Error fetching user UID by email:", error);
    throw new HttpsError(
        "not-found",
        `Failed to fetch user UID by email: ${error}`,
    );
  }
});

// TODO: decide if this needs to be demo accessible at all
exports.getUserCustomClaims = onCall(async (request, context) => {
  const targetEmail = request.data.targetEmail;

  checkEmpty(targetEmail, "targetEmail");

  try {
    checkAuthentication(request);
    checkIsAtLeast(request, Role.admin);

    // Fetch the custom claims of the selected user
    const selectedUserRecord = await admin.auth().getUserByEmail(targetEmail);

    checkDemoStatusesMatch(request, selectedUserRecord);

    // Return the user's custom claims
    return selectedUserRecord.customClaims != null ?
           selectedUserRecord.customClaims :
           {};
  } catch (error) {
    logger.error("Error fetching user custom claims:", error);
    throw new HttpsError(
        "not-found",
        `Failed to fetch user custom claims error: ${error}`);
  }
});

exports.generateSignedUploadUrl = onCall(async (request) => {
  logger.log(`Current filename passed: ${request.data.fileName}`);

  try {
    checkAuthentication(request);
    checkIsAtLeast(request, Role.parent);
  } catch (error) {
    logger.error(`User does not have permission to upload: ${error}`);
    throw new HttpsError(
        "permission-denied",
        `User does not have permission to upload: ${error}`,
    );
  }

  // code to validate the file name
  const rawFileName = request.data.fileName;

  // Reject obviously bad characters
  if (
    typeof rawFileName !== "string" ||
      rawFileName.includes("/") ||
      rawFileName.includes("..")
  ) {
    // eslint-disable-next-line max-len
    logger.info(`User ${request.auth.uid} attempted illegal file name: ${rawFileName}`);
    throw new HttpsError(
        "invalid-argument",
        "Filename cannot be an address",
    );
  }

  // Ensure the file name contains only valid characters
  if (!/^[a-zA-Z0-9._-]+$/.test(rawFileName)) {
    throw new HttpsError(
        "invalid-argument",
        "Invalid characters in file name",
    );
  }

  // TODO: this might cause issues on an IOS device
  //    if videos are stored in a different format
  // Ensure the file name ends with .mp4
  if (!rawFileName.toLowerCase().endsWith(".mp4")) {
    throw new HttpsError(
        "invalid-argument",
        "File extension must be .mp4",
    );
  }

  // Ensure normalized path is within user directory
  const userId = request.auth.uid;
  const filePath = path.posix.normalize(`${userId}/${rawFileName}`);
  if (!filePath.startsWith(`${userId}/`)) {
    throw new HttpsError(
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
    throw new HttpsError(
        "not-found",
        // eslint-disable-next-line max-len
        `Error generating signed url: ${error}, filename : ${request.data.fileName}`,
    );
  }
});

// TODO: verify that this function is secure
exports.generateSignedDownloadUrl = onCall(async (request, context) => {
  logger.log(`Current filename passed: ${request.data.fileName}`);

  try {
    checkAuthentication(request);
    checkIsAtLeast(context, Role.parent);
  } catch (error) {
    logger.error(`User does not have permission to upload: ${error}`);
    throw new HttpsError(
        "permission-denied",
        `User does not have permission to upload: ${error}`,
    );
  }

  // Proceed with signed URL generation
  const bucketName = "baby-words-tracker-media";

  // code to validate the file name
  const rawFileName = request.data.fileName;

  // Reject obviously bad characters
  if (
    typeof rawFileName !== "string" ||
      rawFileName.includes("/") ||
      rawFileName.includes("..")
  ) {
    throw new HttpsError("invalid-argument", "Invalid file name");
  }

  // Ensure normalized path is within user directory
  const userId = request.auth.uid;
  const filePath = path.posix.normalize(`${userId}/${rawFileName}`);
  if (!filePath.startsWith(`${userId}/`)) {
    // eslint-disable-next-line max-len
    logger.info(`User ${userId} attempted illegal file path traversal: ${filePath}`);
    throw new HttpsError(
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
    throw new HttpsError(
        "not-found",
        // eslint-disable-next-line max-len
        `Error generating signed url: ${error}, filename : ${request.data.fileName}`,
    );
  }
});

//

/**
 * Lists all users in the Firebase Authentication system.
 * !!! note: this function should only be called by admin users.
 * !!! This function accesses all the hashes of every user.
 *  It's output must be sanitized before being returned.
 * @param {CallableRequest} request The request object containing the auth token
 * @param {string} nextPageToken The page token from the previous listUsers call
 *   Should be empty for the first call.
 *   This is used to paginate through the list of users.
 *   If not provided, it will start from the beginning.
 * @return {Promise<UserRecord[]>} A promise that resolves
 *  to an array of UserRecord objects
 */
const listAllUsers = async (request, nextPageToken) => {
  const userList = [];
  logger.info("Listing all users...");

  try {
    checkAuthentication(request);
    checkIsAtLeast(request, Role.admin);
  } catch (error) {
    logger.warn(`User ${request.auth.uid} attempted to list` +
      ` all users with incorrect permissions: ${error}`);
    throw new HttpsError(
        "permission-denied",
        `User ${request.auth.uid} does not have` +
        ` permission to list users: ${error}`,
    );
  }

  try {
    const isDemoUser = isDemoRoleFromClaimsList(request.auth.token);
    // List batch of users, 1000 at a time.
    const listUsersResult = await getAuth()
        .listUsers(1000, nextPageToken);

    // limit demo users from ever accessing non demo user information
    if (isDemoUser) {
      // If the user is a demo user, filter out sensitive information.
      listUsersResult.users.forEach((user) => {
        if (isDemoRoleFromClaimsList(user.customClaims)) {
          userList.push(user);
        }
      });
    } else {
      userList.push(...(listUsersResult.users));
    }

    if (listUsersResult.pageToken) {
      // List next batch of users.
      const nextUsers = await listAllUsers(request, listUsersResult.pageToken);

      userList.push(...nextUsers);
    }
  } catch (error) {
    logger.error("Error listing users:", error);
    throw new HttpsError(
        "internal",
        `Error listing users: ${error}`,
    );
  }

  logger.info("Finished listing users: ", userList);

  return userList;
};

/**
 * Converts a list of user records to a safe JSON format.
 * @param {UserRecord[]} listUsersResult The list of user records to convert.
 * @return {Object[]} The converted user objects as json.
 */
const convertUserListToSafeJson = (listUsersResult) => {
  const users = [];
  listUsersResult.forEach((userRecord) => {
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
  return users;
};

exports.getEmailUIDTable = onCall(async (request, context) => {
  logger.info(`getEmailUIDTable called from account ID: ${request.auth.uid}`);
  try {
    checkAuthentication(request);
    // TODO: this is safe,
    //  but it still feels wrong to allow demo users to access this
    checkIsAtLeast(request, Role.admin);

    // List all users
    const users = convertUserListToSafeJson(await listAllUsers(request));

    return {
      users: users,
    };
  } catch (error) {
    logger.error(`Error listing users: ${error}`);
    throw new HttpsError(
        "internal",
        `Error getting user list: ${error}`,
    );
  }
});

/**
 * This function sets the type for all users in the system based on their roles.
 * It was created solely for transitioning from type and permission roles to
 * separate type and permission roles.
 *
 * This function should probably not ever be called again,
 *  and it is here for reference only.
 */
// exports.setAllUserTypes = onCall(async (request) => {
//   logger.info(`setAllUserTypes called from account ID: ${request.auth.uid}`);
//   try {
//     checkAuthentication(request);
//     checkIsAtLeast(request, Role.admin, true);

//     // Start listing users from the beginning, 1000 at a time.
//     const userRecords = await listAllUsers(request);

//     for (const user of userRecords) {
//       const userRoles = getAllRolesFromClaimsList(user.customClaims);
//       let typeToSet = Type.unauthenticated_type;
//       if (userRoles.includes(Role.researcher)) {
//         logger.info(`setAllUserTypes(): User ${user.email} is a researcher,
//            will set type to researcher...`);
//         typeToSet = Type.researcher_type;
//       } else if (userRoles.includes(Role.parent)) {
//         logger.info(`setAllUserTypes(): User ${user.email} is a parent,
//            will set type to parent...`);
//         typeToSet = Type.parent_type;
//       } else {
//         logger.warn(`setAllUserTypes(): User ${user.email} is not a parent
//            or researcher, will set type and claims to parent...`);
//         await giveClaimByEmail(Role.parent, Role.admin, user.email, request);
//         typeToSet = Type.parent_type;
//       }

//       logger.info(`setAllUserTypes(): Setting type for user
//          ${user.email} to ${typeToSet.value.description}...`);

//       await setTypeClaimByEmail(typeToSet, Role.admin, user.email, request);

//       logger.info(`setAllUserTypes(): User ${user.email}
//          has been set to type ${typeToSet.value.description}.`);
//     }

//     return {
//       message: "All user types have been set successfully.",
//     };
//   } catch (error) {
//     logger.error(`Error setting user types: ${error}`);
//     throw new HttpsError(
//         "internal",
//         `Error setting user types: ${error}`,
//     );
//   }
// });

/**
 * Sets the demo status for all users in the system.
 * This function checks each user for demo status.
 * If they are a demo user, it changes nothing.
 * If they are not a demo user, it sets their demo status to false.
 *
 * This function was created during restructuring of demo roles
 *  and should not be called again unless the demo role is changed.
 * It is here for reference only.
 * @param {CallableRequest} request The request object containing the auth token
 * @throws {HttpsError} if the user is not authenticated,
 * if the user does not have the minimum role, or
 * if there is an error listing users
 */
// exports.setAllDemoStatus = onCall(async (request) => {
//   logger.info(`setAllDemoStatus called from account ID: ` +
//     `${request.auth.uid}`);
//   try {
//     checkAuthentication(request);
//     checkIsAtLeast(request, Role.admin, true);

//     // Start listing users from the beginning, 1000 at a time.
//     const userRecords = await listAllUsers(request);

//     for (const user of userRecords) {
//       const isDemo = isDemoRoleFromClaimsList(user.customClaims);
//       if (isDemo) {
//         logger.info(`setAllDemoStatus(): User ${user.email} is a demo user,
//           no action necessary...`);
//       } else {
//         logger.info(`setAllDemoStatus(): User ${user.email} is not a " +
//                   "demo user, will set demo status to false...`);
//         logger.info(`setAllDemoStatus(): Setting demo status
//            for user ${user.email} to ${isDemo}...`);

//         await setDemoClaimByEmail(isDemo, Role.admin, user.email, request);

//         logger.info(`setAllDemoStatus(): User ${user.email}'s
//            demo status has been set to ${isDemo}.`);
//       }
//     }

//     logger.info("setAllDemoStatus(): All demo statuses " +
//       "have been set successfully.");

//     return {
//       message: "All demo statuses have been set successfully.",
//     };
//   } catch (error) {
//     logger.error(`Error setting demo status: ${error}`);
//     throw new HttpsError(
//         "internal",
//         `Error setting demo status: ${error}`,
//     );
//   }
// });
