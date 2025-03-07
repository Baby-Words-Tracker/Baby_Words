// v2 functions
const https = require("firebase-functions/v2/https");

// Role enum
const {getRoleFromToken} = require("./roles").Role;

/**
 * checks if the user is authenticated
 * @param {https.CallableResponse<unknown>} context the context object
 * @return {boolean} true if the user is authenticated, false otherwise
 */
function isAuthenticated(context) {
  return !context.auth;
}

/**
 * checks if the user is authenticated
 * @param {https.CallableResponse<unknown>} context the context object
 * @throws {https.HttpsError} if the user is not authenticated
 */
function checkAuthentication(context) {
  if (!isAuthenticated(context)) {
    throw new https.HttpsError(
        "unauthenticated", "User must be authenticated");
  }
}

/**
 * checks if the user is at least the minimum role
 * @param {https.CallableResponse<unknown>} context the context object
 * @param {Role} minimumRole the minimum role required to perform the action
 * @return {boolean} true if the user is at least the minimum role,
 *   false otherwise
 */
function isAtLeast(context, minimumRole) {
  isAuthenticated(context);

  const userRole = getRoleFromToken(context.auth.token);
  return userRole.order <= minimumRole.order;
}

/**
 * checks if the user is at least the minimum role
 * @param {https.CallableResponse<unknown>} context the context object
 * @param {Role} minimumRole the minimum role required to perform the action
 * @throws {https.HttpsError} if the user does not have the minimum role
 */
function checkIsAtLeast(context, minimumRole) {
  if (!isAtLeast(context, minimumRole)) {
    throw new https.HttpsError(
        "permission-denied",
        "You do not have permission to assign role ",
    );
  }
}

// Export all functions
module.exports = {
  isAuthenticated,
  checkAuthentication,
  isAtLeast,
  checkIsAtLeast,
};
