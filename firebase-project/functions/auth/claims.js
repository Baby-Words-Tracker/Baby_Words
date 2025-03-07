const {getAuth} = require("firebase-admin/auth");

// v2 functions
const https = require("firebase-functions/v2/https");

const {logger} = require("firebase-functions");

// authentication functions
const {checkAuthentication, checkIsAtLeast} = require("./auth");

/**
 * Assigns a role to a user checking authentication and permissions
 * @param {Role} newRole The role to assign to the user
 * @param {Role} minimumRole The minimum role required to perform the action
 * @param {string} targetUid The UID of the user to assign the role to
 * @param {Object} data The teh data associated with the https call
 * @throws {https.HttpsError} if the user does not have the minimum role
 *  or is not authenticated
 */
async function giveClaim(newRole, minimumRole, targetUid, data) {
  checkAuthentication(data);

  const roleName = newRole.value.description;

  try {
    checkIsAtLeast(data, minimumRole);

    const targetUser = await getAuth().getUser(targetUid);
    const currentClaims = targetUser.customClaims || {};

    currentClaims[roleName] = true;

    // Assign the new role to the target user
    await getAuth().setCustomUserClaims(targetUid, currentClaims);
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
 * @param {string} targetUid The UID of the user to remove the role from
 * @param {Object} data The data object
 * @throws {https.HttpsError} if the user does not have the minimum role
 *  or is not authenticated
 */
async function removeClaim(role, minimumRole, targetUid, data) {
  checkAuthentication(data);

  const roleName = role.value.description;

  try {
    checkIsAtLeast(data, minimumRole);

    const targetUser = await getAuth().getUser(targetUid);
    const currentClaims = targetUser.customClaims || {};

    delete currentClaims[roleName];

    // Remove the role from the target user
    await getAuth().setCustomUserClaims(targetUid, currentClaims);
  } catch (error) {
    // Handle errors (e.g., user not found, failed to set claims)
    throw new https.HttpsError(
        "internal", "Failed to remove " + roleName + " role", error);
  }
}

// Export all functions
module.exports = {
  giveClaim,
  removeClaim,
};
