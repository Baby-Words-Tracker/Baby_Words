/**
 * A role object to model authentication
 * @typedef {Object} Role
 * @property {Symbol} value the role value
 * @property {number} order the order of the role
 * @property {Role} admin the admin role
 * @property {Role} researcher the researcher role
 * @property {Role} parent the parent role
 * @property {Role} unauthenticated the unauthenticated role
 */
const Role = Object.freeze({
  // DO NOT CHECK ORDER VALUES DIRECTLY!
  // They can change in the future and are only used for comparison.
  admin: { value: Symbol("admin"), order: 0 },
  researcher: { value: Symbol("researcher"), order: 3 },
  parent: { value: Symbol("parent"), order: 5 },
  unauthenticated: { value: Symbol("unauthenticated"), order: 100 },
});

/**
 * Gets the user's Role object from the token
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

module.exports = {
  Role,
  getRoleFromToken,
};
