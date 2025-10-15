/**
 * User roles in the system
 * Lower priority = higher permissions
 */
const UserRole = Object.freeze({
  admin: {name: "admin", priority: 0},
  researcher: {name: "researcher", priority: 3},
  parent: {name: "parent", priority: 5},
});

/**
 * User status in the system
 */
const UserStatus = Object.freeze({
  active: "active",
  demo: "demo",
  suspended: "suspended",
});

/**
 * Gets the user's role from custom claims
 * @param {Object} token the token object (context.auth.token)
 * @return {Object} the user's role object
 */
function getRoleFromToken(token) {
  if (token.admin === true) return UserRole.admin;
  if (token.researcher === true) return UserRole.researcher;
  if (token.parent === true) return UserRole.parent;
  return null; // No role assigned
}

/**
 * Gets the user's status from custom claims
 * @param {Object} token the token object (context.auth.token)
 * @return {string} the user's status
 */
function getStatusFromToken(token) {
  if (token.demo === true) return UserStatus.demo;
  if (token.suspended === true) return UserStatus.suspended;
  return UserStatus.active;
}

/**
 * Check if role has permission (for backward compatibility)
 * @param {Object} userRole the user's role
 * @param {Object} requiredRole the required role
 * @return {boolean} true if user has permission
 */
function hasPermission(userRole, requiredRole) {
  if (!userRole || !requiredRole) return false;
  return userRole.priority <= requiredRole.priority;
}

// Export legacy Role for backward compatibility
const Role = Object.freeze({
  admin: {value: Symbol("admin"), order: 0},
  researcher: {value: Symbol("researcher"), order: 3},
  parent: {value: Symbol("parent"), order: 5},
  unauthenticated: {value: Symbol("unauthenticated"), order: 100},
});

module.exports = {
  UserRole,
  UserStatus,
  getRoleFromToken,
  getStatusFromToken,
  hasPermission,
  Role, // Keep for backward compatibility
};
