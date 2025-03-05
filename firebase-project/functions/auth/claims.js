const {https} = require("firebase-functions/v2/https");
const {getAuth} = require("firebase-admin/auth");

// Role enum
const {Role} = require("./roles");

// authentication functions
const {checkAuthentication, checkIsAtLeast} = require("./auth");

/**
 * Assigns a role to a user checking authentication and permissions
 * @param {Role} newRole The role to assign to the user
 * @param {Role} minimumRole The minimum role required to perform the action
 * @param {string} targetUid The UID of the user to assign the role to
 * @param {https.CallableResponse<unknown>} context The context object
 * @throws {https.HttpsError} if the user does not have the minimum role
 *  or is not authenticated
 */
async function giveClaim(newRole, minimumRole, targetUid, context) {
  checkAuthentication(context);

  const roleName = newRole.value.description;

  try {
    checkIsAtLeast(context, Role.Admin);

    // Assign the new role to the target user
    await getAuth().setCustomUserClaims(targetUid, {[roleName]: true});
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
 * @param {https.CallableResponse<unknown>} context The context object
 * @throws {https.HttpsError} if the user does not have the minimum role
 *  or is not authenticated
 */
async function removeClaim(role, minimumRole, targetUid, context) {
  checkAuthentication(context);

  const roleName = role.value.description;

  try {
    checkIsAtLeast(context, minimumRole);

    // Remove the role from the target user
    await getAuth().setCustomUserClaims(targetUid, {[roleName]: false});
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
