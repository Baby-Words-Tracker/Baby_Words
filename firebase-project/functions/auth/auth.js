// v2 functions
const https = require("firebase-functions/v2/https");

// The Cloud Functions for Firebase SDK to create Cloud Functions and triggers.
const {logger} = require("firebase-functions");

// Role enum
const {getRoleFromToken} = require("./roles");

/**
 * checks if the user is authenticated
 * @param {Object} data the data object
 * @return {boolean} true if the user is authenticated, false otherwise
 */
function isAuthenticated(data) {
  return !!data.auth;
}

/**
 * checks if the user is authenticated
 * @param {Object} data the data object
 * @throws {https.HttpsError} if the user is not authenticated
 */
function checkAuthentication(data) {
  if (!isAuthenticated(data)) {
    throw new https.HttpsError(
        "unauthenticated", "User must be authenticated");
  } else {
    logger.debug("User is authenticated.");
  }
}

/**
 * checks if the user is at least the minimum role
 * @param {Object} data the data object
 * @param {Role} minimumRole the minimum role required to perform the action
 * @return {boolean} true if the user is at least the minimum role,
 *   false otherwise
 */
function isAtLeast(data, minimumRole) {
  const userRole = getRoleFromToken(data.auth.token);
  return userRole.order <= minimumRole.order;
}

/**
 * checks if the user is at least the minimum role
 * @param {Object} data the context object
 * @param {Role} minimumRole the minimum role required to perform the action
 * @throws {https.HttpsError} if the user does not have the minimum role
 */
function checkIsAtLeast(data, minimumRole) {
  if (!isAtLeast(data, minimumRole)) {
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
