// v2 functions
const https = require("firebase-functions/v2/https");

// Role enum
const {getRoleFromToken} = require("./roles");

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
        "You do not have correct permissions.",
    );
  }
}

// Export all functions
module.exports = {
  isAtLeast,
  checkIsAtLeast,
};
