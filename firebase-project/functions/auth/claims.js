const {getAuth} = require("firebase-admin/auth");

// v2 functions
const https = require("firebase-functions/v2/https");

// const {logger} = require("firebase-functions");

// authentication functions
// eslint-disable-next-line max-len
const {checkAuthentication, checkIsAtLeast, checkDemoStatusesMatch} = require("./auth");

/**
 * Gets a users record by uid
 * @param {string} targetUid The UID of the user record to get
 * @return {UserRecord} The user record of the target user
 * @throws {https.HttpsError} if the user does not have the minimum role
 *  or is not authenticated
 */
async function getUserRecordByUID(targetUid) {
  try {
    return await getAuth().getUser(targetUid);
  } catch (error) {
    // Handle errors (e.g., user not found, failed to set claims)
    throw new https.HttpsError(
        "internal",
        "Error: Failed to get user record with uid: ",
        targetUid,
        "Error: " + error);
  }
}

/**
 * Gets a user's record using email
 * @param {string} targetEmail The email of the user record to get
 * @return {UserRecord} The user record of the target user
 * @throws {https.HttpsError} if the user does not have the minimum role
 *  or is not authenticated
 */
async function getUserRecordByEmail(targetEmail) {
  try {
    return await getAuth().getUserByEmail(targetEmail);
  } catch (error) {
    // Handle errors (e.g., user not found, failed to set claims)
    throw new https.HttpsError(
        "internal",
        "Error: Failed to get user record with email: ",
        targetEmail,
        "Error: " + error);
  }
}


/**
 * Assigns a role to a user checking authentication and permissions
 * @param {Role} newRole The role to assign to the user
 * @param {Role} minimumRole The minimum role required to perform the action
 * @param {UserRecord} targetUser The UID of the user to assign the role to
 * @param {https.CallableRequest} request The request associated
 *  with the https call
 * @throws {https.HttpsError} if the user does not have the minimum role
 *  or is not authenticated
 */
async function giveClaim(newRole, minimumRole, targetUser, request) {
  checkAuthentication(request);

  const roleName = newRole.value.description;

  checkDemoStatusesMatch(request, targetUser);

  try {
    checkIsAtLeast(request, minimumRole);

    const currentClaims = targetUser.customClaims || {};

    currentClaims[roleName] = true;

    // Assign the new role to the target user
    await getAuth().setCustomUserClaims(targetUser.uid, currentClaims);
  } catch (error) {
    // Handle errors (e.g., user not found, failed to set claims)
    throw new https.HttpsError(
        "internal", "Failed to assign " + roleName + " role", error);
  }
}

/**
 * removes a role from a user checking authentication and permissions
 * @param {Role} role The role to remove from the user
 * @param {Role} minimumRole The minimum role required to perform the action
 * @param {UserRecord} targetUser The UID of the user to remove the role from
 * @param {https.CallableRequest} request The request object associated
 *  with the https call
 * @throws {https.HttpsError} if the user does not have the minimum role
 *  or is not authenticated
 */
async function removeClaim(role, minimumRole, targetUser, request) {
  checkAuthentication(request);

  const roleName = role.value.description;

  checkDemoStatusesMatch(request, targetUser);

  try {
    checkIsAtLeast(request, minimumRole);

    const currentClaims = targetUser.customClaims || {};

    delete currentClaims[roleName];

    // Remove the role from the target user
    await getAuth().setCustomUserClaims(targetUser.uid, currentClaims);
  } catch (error) {
    // Handle errors (e.g., user not found, failed to set claims)
    throw new https.HttpsError(
        "internal", "Failed to remove " + roleName + " role", error);
  }
}

/**
 * Assigns a role to a user checking authentication and permissions
 * @param {Type} newType The role to assign to the user
 * @param {Role} minimumRole The minimum role required to perform the action
 * @param {UserRecord} targetUser The UID of the user to assign the role to
 * @param {https.CallableRequest} request The request associated with
 *  the https call
 * @throws {https.HttpsError} if the user does not have the minimum role
 *  or is not authenticated
 */
async function setTypeClaim(newType, minimumRole, targetUser, request) {
  checkAuthentication(request);

  const typeName = newType.value.description;

  checkDemoStatusesMatch(request, targetUser);

  try {
    checkIsAtLeast(request, minimumRole);

    const currentClaims = targetUser.customClaims || {};

    // Clear all existing type claims
    for (const key in currentClaims) {
      if (key.endsWith("_type")) {
        delete currentClaims[key];
      }
    }

    currentClaims[typeName] = true;

    // Assign the new type to the target user
    await getAuth().setCustomUserClaims(targetUser.uid, currentClaims);
  } catch (error) {
    // Handle errors (e.g., user not found, failed to set claims)
    throw new https.HttpsError(
        "internal", "Failed to assign " + typeName + " type", error);
  }
}

/**
 * Assign a claim to a user by UID
 * @param {Role} role The role to give
 * @param {Role} minimumRole The minimum role to allow to perform the action
 * @param {String} targetUid The target user's uid
 * @param {https.CallableRequest} request The request object associated
 *  with the https request
 * @throws {https.HttpsError} if the user does not have the minimum role
 *  or is not authenticated
 */
async function giveClaimByUID(role, minimumRole, targetUid, request) {
  try {
    const targetUser = await getUserRecordByUID(targetUid);
    await giveClaim(role, minimumRole, targetUser, request);
  } catch (error) {
    // Handle errors (e.g., user not found, failed to set claims)
    throw new https.HttpsError(
        "internal", "Error: Failed to assign role by UID; Error:", error);
  }
}

/**
 * Assign a claim to a user by email
 * @param {Role} role The role to give
 * @param {Role} minimumRole The minimum role to allow to perform the action
 * @param {String} targetEmail The target user's email
 * @param {https.CallableRequest} req The request object associated
 *  with the https request
 * @throws {https.HttpsError} if the user does not have the minimum role
 *  or is not authenticated
 */
async function giveClaimByEmail(role, minimumRole, targetEmail, req) {
  try {
    const targetUser = await getUserRecordByEmail(targetEmail);
    await giveClaim(role, minimumRole, targetUser, req);
  } catch (error) {
    // Handle errors (e.g., user not found, failed to set claims)
    throw new https.HttpsError(
        "internal", "Error: Failed to assign role by email; Error:", error);
  }
}

/**
 * Removes a claim from a user by UID
 * @param {Role} role The role to remove
 * @param {Role} minimumRole The minimum role to allow to perform the action
 * @param {String} targetUid The target user's uid
 * @param {https.CallableRequest} request The request object associated
 *  with the https call
 * @throws {https.HttpsError} if the user does not have the minimum role
 *  or is not authenticated
 */
async function removeClaimByUID(role, minimumRole, targetUid, request) {
  try {
    const targetUser = await getUserRecordByUID(targetUid);
    await removeClaim(role, minimumRole, targetUser, request);
  } catch (error) {
    // Handle errors (e.g., user not found, failed to set claims)
    throw new https.HttpsError(
        "internal", "Error: Failed to remove role by UID; Error:", error);
  }
}

/**
 * Removes a claim from a user by email
 * @param {Role} role The role to remove
 * @param {Role} minimumRole The minimum role to allow to perform the action
 * @param {String} targetEmail The target user's email
 * @param {https.CallableRequest} request The request object associated
 *  with the https call
 * @throws {https.HttpsError} if the user does not have the minimum role
 *  or is not authenticated
 */
async function removeClaimByEmail(role, minimumRole, targetEmail, request) {
  try {
    const targetUser = await getUserRecordByEmail(targetEmail);
    await removeClaim(role, minimumRole, targetUser, request);
  } catch (error) {
    // Handle errors (e.g., user not found, failed to set claims)
    throw new https.HttpsError(
        "internal", "Error: Failed to remove role by email; Error:", error);
  }
}

/**
 * Assign a type claim to a user by UID
 * @param {Type} type The type to give
 * @param {Role} minimumRole The minimum role to allow to perform the action
 * @param {String} targetUid The target user's uid
 * @param {https.CallableRequest} request The request object associated
 *  with the https request
 * @throws {https.HttpsError} if the user does not have the minimum role
 *  or is not authenticated
 */
async function setTypeClaimByUID(type, minimumRole, targetUid, request) {
  try {
    const targetUser = await getUserRecordByUID(targetUid);
    await setTypeClaim(type, minimumRole, targetUser, request);
  } catch (error) {
    // Handle errors (e.g., user not found, failed to set claims)
    throw new https.HttpsError(
        "internal", "Error: Failed to assign type by UID; Error:", error);
  }
}

/**
 * Assign a type claim to a user by email
 * @param {Type} type The type to give
 * @param {Role} minimumRole The minimum role to allow to perform the action
 * @param {String} targetEmail The target user's email
 * @param {https.CallableRequest} req The request object associated
 *  with the https request
 * @throws {https.HttpsError} if the user does not have the minimum role
 *  or is not authenticated
 */
async function setTypeClaimByEmail(type, minimumRole, targetEmail, req) {
  try {
    const targetUser = await getUserRecordByEmail(targetEmail);
    await setTypeClaim(type, minimumRole, targetUser, req);
  } catch (error) {
    // Handle errors (e.g., user not found, failed to set claims)
    throw new https.HttpsError(
        "internal", "Error: Failed to assign type by email; Error:", error);
  }
}


// Export all functions
module.exports = {
  giveClaimByEmail,
  giveClaimByUID,
  removeClaimByEmail,
  removeClaimByUID,
  setTypeClaimByEmail,
  setTypeClaimByUID,
};
