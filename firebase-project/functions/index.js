// The Cloud Functions for Firebase SDK to create Cloud Functions and triggers.
const {logger} = require("firebase-functions");

// The Firebase Admin SDK to access Firestore.
const {initializeApp} = require("firebase-admin/app");
const {getAuth} = require("firebase-admin/auth");

// Import our auth module
const {Role} = require("./auth/roles");
const {giveClaim, removeClaim} = require("./auth/claims");

// functions
// v1 functions
const auth = require("firebase-functions/v1/auth");

// v2 functions
const https = require("firebase-functions/v2/https");

initializeApp();

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
 * @param {string} uid The UID of the user to assign the role to
 */
function checkUID(uid) {
  if (!uid) {
    throw new https.HttpsError(
        "invalid-argument", "Target user UID is required");
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
  checkUID(targetUid);

  // Assign the 'researcher' role to the target user
  try {
    giveClaim(Role.researcher, Role.researcher, targetUid, data);
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
  checkUID(targetUid);

  try {
    removeClaim(Role.researcher, Role.researcher, targetUid, data);
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
  checkUID(targetUid);

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
  checkUID(targetUid);

  try {
    removeClaim(Role.parent, Role.researcher, targetUid, data);
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
  checkUID(targetUid);

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
  checkUID(targetUid);

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
