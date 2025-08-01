/**
 * A role object to model authentication
 * Note: the ending _type is reserved for user and any role with a
 * value ending in _type will be deleted when type is changed.
 * @typedef {Object} Role
 * @property {Symbol} value the role value
 * @property {number} order the order of the role
 * @property {Role} demo marks a user as a demo user.
 *  This role is a marker separate from other roles.
 *  It will not be detected by the getRoleFromClaimsList function
 *  and must be checked using isDemoRoleFromClaimsList.
 */
const DemoRole = Object.freeze({
  // The demo role marks a user as a demo user.
  // To get the corresponding order of a non demo role,
  // add the order of the demo role to the prod role's order.
  // All prod roles should have order < demo.order
  // Demo role:
  demo: {
    value: Symbol("demo"),
    order: 50,
  },
});

/**
 * Gets the demo order for a role
 * @param {Role} role the role to get the demo order for
 * @return {number} the demo order for the role
 */
function getDemoOrder(role) {
  return role.order + DemoRole.demo.order;
}


/**
 * Checks if the user is a demo user
 * @param {string[]} token the token object (requst.auth.token)
 *  (or a list of strings with role names)
 * @return {boolean} true if the user is a demo user, false otherwise
 */
function isDemoRoleFromClaimsList(token) {
  // This function checks if the user is a demo user
  // It is used to determine if the user is a demo user
  if (token == null) {
    return false;
  }

  if (token[DemoRole.demo.value.description] === true) {
    return true;
  }
  return false;
}

/**
 * Gets the Role object from a string representation
 * @param {string} roleString the string representation of the role
 * @return {Role} the corresponding Role object
 */
function stringMatchesDemoRole(roleString) {
  switch (roleString) {
    case DemoRole.demo.value.description:
      return true;
    default:
      return false;
  }
}

module.exports = {
  DemoRole,
  getDemoOrder,
  isDemoRoleFromClaimsList,
  stringMatchesDemoRole,
};
