/**
 * A role object to model authentication
 * @typedef {Object} Role
 * @property {Symbol} value the role value
 * @property {number} order the order of the role
 * @property {Role} admin the admin role
 * @property {Role} researcher the researcher role
 * @property {Role} parent the parent role
 * @property {Role} unauthenticated the unauthenticated role
 * @property {Role} demo_admin the demo admin role
 * @property {Role} demo_researcher the demo researcher role
 * @property {Role} demo_parent the demo user role
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
  },
  researcher: {
    value: Symbol("researcher"),
    order: 3,
  },
  parent: {
    value: Symbol("parent"),
    order: 6,
  },
  // demo roles are used for demo purposes. All prod roles should be above
  // demo roles must have order >= demo_admin.order < unauthenticated.order
  // Demo roles:
  demo_admin: {
    value: Symbol("demo_admin"),
    order: 50,
  },
  demo_researcher: {
    value: Symbol("demo_researcher"),
    order: 53,
  },
  demo_parent: {
    value: Symbol("demo_parent"),
    order: 56,
  },
  // unauthenticated role is the max order value
  unauthenticated: {
    value: Symbol("unauthenticated"),
    order: 100,
  },
});

/** * Checks if the given role is a demo role
 * @param {Role} role the role to check
 * @return {boolean} true if the role is a demo role, false otherwise
 */
function isDemoRole(role) {
  return role.order >= Role.demo_admin.order &&
         role.order < Role.unauthenticated.order;
}

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
  } else if (token[Role.demo_admin.value.description] === true) {
    return Role.demo_admin;
  } else if (token[Role.demo_researcher.value.description] === true) {
    return Role.demo_researcher;
  } else if (token[Role.demo_parent.value.description] === true) {
    return Role.demo_parent;
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
    case Role.demo_admin.value.description:
      return Role.demo_admin;
    case Role.demo_researcher.value.description:
      return Role.demo_researcher;
    case Role.demo_parent.value.description:
      return Role.demo_parent;
    // If the role is not recognized, return unauthenticated
    default:
      return Role.unauthenticated;
  }
}

module.exports = {
  Role,
  isDemoRole,
  getRoleFromToken,
  getRoleFromString,
};
