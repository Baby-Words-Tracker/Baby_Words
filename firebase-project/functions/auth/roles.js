/**
 * A role object to model authentication
 * Note: the ending _type is reserved for user and any role with a
 * value ending in _type will be deleted when type is changed.
 * @typedef {Object} Role
 * @property {Symbol} value the role value
 * @property {number} order the order of the role
 * @property {Role} admin the admin role
 * @property {Role} researcher the researcher role
 * @property {Role} parent the parent role
 * @property {Role} unauthenticated the unauthenticated role
 *  This role is a marker separate from other roles.
 *  It will not be detected by the getRoleFromToken function
 *  and must be checked using isDemoRoleFromToken.
 */
const Role = Object.freeze({
  // DO NOT CHECK ORDER VALUES USING CONSTANTS! ONLY COMPARE THEM!
  // They can change in the future and are only used for comparison.
  // The order is used to determine the hierarchy of roles
  // Production roles must have order < demo_admin.order
  // Production roles:
  admin: {
    value: Symbol("admin"),
    order: 0,
    demo_order: this.order + this.Role.demo.order,
  },
  researcher: {
    value: Symbol("researcher"),
    order: 3,
    demo_order: this.order + this.Role.demo.order,
  },
  parent: {
    value: Symbol("parent"),
    order: 6,
    demo_order: this.order + this.Role.demo.order,
  },
  // Note: The demo role marks a user as a demo user.
  //  To get the corresponding order of a non demo role,
  //  add the order of the demo role to the prod role's order.
  //  All prod roles should have order < DemoRole.demo.order
  //  see demo_role.js for the demo role (order == 50 on 7/30/2025)
  // unauthenticated role is the max order value
  unauthenticated: {
    value: Symbol("unauthenticated"),
    order: 100,
  },

});

/**
 * Gets the user's Role object from the token
 * This function must return the highestr role the user has.
 * If the user has multiple roles, the one with the highest
 * order will be returned.
 * @param {unknown} token the token object (context.auth.token)
 * @return {Role} the user's corresponding Role object
 */
function getRoleFromToken(token) {
  if (token[Role.admin.value.description] === true) {
    return Role.admin;
  } else if (token[Role.researcher.value.description] === true) {
    return Role.researcher;
  } else if (token[Role.parent.value.description] === true) {
    return Role.parent;
  } else {
    return Role.unauthenticated;
  }
}

/**
 * Gets the Role object from a string representation
 * @param {string} roleString the string representation of the role
 * @return {Role} the corresponding Role object
 */
function getRoleFromString(roleString) {
  switch (roleString) {
    case Role.admin.value.description:
      return Role.admin;
    case Role.researcher.value.description:
      return Role.researcher;
    case Role.parent.value.description:
      return Role.parent;
    // If the role is not recognized, return unauthenticated
    default:
      return Role.unauthenticated;
  }
}

module.exports = {
  Role,
  getRoleFromToken,
  getRoleFromString,
};
