// v2 functions
const https = require("firebase-functions/v2/https");

// The Cloud Functions for Firebase SDK to create Cloud Functions and triggers.
const {logger} = require("firebase-functions");

// Role enum
const {getRoleFromToken} = require("./roles");

// Demo Role enum
const {isDemoRoleFromToken} = require("./demo_role");

// eslint-disable-next-line no-unused-vars
const {UserRecord} = require("firebase-admin/auth");

/**
 * checks if the user is authenticated
 * @param {https.CallableRequest} request the request object sent
 *  to the onCall functions
 * @return {boolean} true if the user is authenticated, false otherwise
 */
function isAuthenticated(request) {
  return !!request.auth;
}

/**
 * checks if the user is authenticated
 * @param {https.CallableRequest} request the request object sent
 *  to the onCall function
 * @throws {https.HttpsError} if the user is not authenticated
 */
function checkAuthentication(request) {
  if (!isAuthenticated(request)) {
    throw new https.HttpsError(
        "unauthenticated", "User must be authenticated");
  } else {
    logger.debug("User is authenticated.");
  }
}

/**
 * checks if the user is at least the minimum role
 * @param {https.CallableRequest} request the request object
 * @param {Role} minimumRole the minimum role required to perform the action
 * @return {boolean} true if the user is at least the minimum role,
 *   false otherwise
 */
function isAtLeast(request, minimumRole) {
  const userRole = getRoleFromToken(request.auth.token);
  return userRole.order <= minimumRole.order;
}

/**
 * checks if the user is at least the minimum role
 * @param {https.CallableRequest} request the request object
 * @param {Role} minimumRole the minimum role required to perform the action
 * @param {boolean} disallowDemo if true, the user must not be a demo user
 * @throws {https.HttpsError} if the user does not have the minimum role
 */
function checkIsAtLeast(request, minimumRole, disallowDemo = false) {
  let allowed = true;
  if (disallowDemo && isDemoRoleFromToken(request.auth.token)) {
    allowed = false;
    // eslint-disable-next-line max-len
    logger.info(`User ${request.auth.uid} attempted to perform an action that requires a non-demo role.`);
  }
  if (!isAtLeast(request, minimumRole)) {
    allowed = false;
    // eslint-disable-next-line max-len
    logger.info(`User ${request.auth.uid} attempted to perform an action that requires at least the ${minimumRole.value.description} role.`);
  }
  if (!allowed) {
    throw new https.HttpsError(
        "permission-denied",
        "You do not have permission to perform this action.",
    );
  }
}

/**
 * Checks if the user is a demo user and
 * returns false if the target user is not.
 * @param {https.CallableRequest} request - The request object
 *    sent with the function call
 * @param {UserRecord} targetUserRecord - The user record of the target user
 * @return {boolean} - False if the requesting user is a demo user and
 *    the target user is not, true otherwise
 */
function demoStatusesMatch(request, targetUserRecord) {
  const isDemo = isDemoRoleFromToken(request.auth.token);
  const targetIsDemo = isDemoRoleFromToken(targetUserRecord.customClaims);
  return !isDemo || targetIsDemo;
}

/**
 * A helper function to check if the user is a demo user
 * and make sure they can only interact with other demo users if so.
 * @param {https.CallableRequest} request the request object
 *    sent with the function call
 * @param {UserRecord} targetUserRecord the user record of the target user
 * @throws {https.HttpsError} if the user is a demo user
 *   and the target user is not a demo user.
 * @return {void} does not return anything,
 *   just throws an error if the check fails
 */
function checkDemoStatusesMatch(request, targetUserRecord) {
  if (!demoStatusesMatch(request, targetUserRecord)) {
    throw new https.HttpsError(
        "permission-denied",
        "Demo users can only interact with other demo users.",
    );
  }
}

// Export all functions
module.exports = {
  isAuthenticated,
  checkAuthentication,
  isAtLeast,
  checkIsAtLeast,
  demoStatusesMatch,
  checkDemoStatusesMatch,
};
