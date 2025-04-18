const {getAuth} = require("firebase-admin/auth");

// v2 functions
const https = require("firebase-functions/v2/https");

// const {logger} = require("firebase-functions");

// authentication functions
const {checkAuthentication, checkIsAtLeast} = require("./auth");

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
 * @param {Object} data The teh data associated with the https call
 * @throws {https.HttpsError} if the user does not have the minimum role
 *  or is not authenticated
 */
async function giveClaim(newRole, minimumRole, targetUser, data) {
  checkAuthentication(data);

  const roleName = newRole.value.description;

  try {
    checkIsAtLeast(data, minimumRole);

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
 * @param {Object} data The data object
 * @throws {https.HttpsError} if the user does not have the minimum role
 *  or is not authenticated
 */
async function removeClaim(role, minimumRole, targetUser, data) {
  checkAuthentication(data);

  const roleName = role.value.description;

  try {
    checkIsAtLeast(data, minimumRole);

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
 * Assign a claim to a user by UID
 * @param {Role} role The role to give
 * @param {Role} minimumRole The minimum role to allow to perform the action
 * @param {String} targetUid The target user's uid
 * @param {Object} req The request object associated witht he https request
 * @throws {https.HttpsError} if the user does not have the minimum role
 *  or is not authenticated
 */
async function giveClaimByUID(role, minimumRole, targetUid, req) {
  try {
    const targetUser = await getUserRecordByUID(targetUid);
    await giveClaim(role, minimumRole, targetUser, req);
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
 * @param {Object} req The request object associated witht he https request
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
 * @param {Object} data The data object associated with the https request
 * @throws {https.HttpsError} if the user does not have the minimum role
 *  or is not authenticated
 */
async function removeClaimByUID(role, minimumRole, targetUid, data) {
  try {
    const targetUser = await getUserRecordByUID(targetUid);
    await removeClaim(role, minimumRole, targetUser, data);
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
 * @param {Object} data The data object associated with the https request
 * @throws {https.HttpsError} if the user does not have the minimum role
 *  or is not authenticated
 */
async function removeClaimByEmail(role, minimumRole, targetEmail, data) {
  try {
    const targetUser = await getUserRecordByEmail(targetEmail);
    await removeClaim(role, minimumRole, targetUser, data);
  } catch (error) {
    // Handle errors (e.g., user not found, failed to set claims)
    throw new https.HttpsError(
        "internal", "Error: Failed to remove role by email; Error:", error);
  }
}

// Export all functions
module.exports = {
  giveClaimByEmail,
  giveClaimByUID,
  removeClaimByEmail,
  removeClaimByUID,
};
