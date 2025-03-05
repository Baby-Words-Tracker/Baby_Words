

/**
 * A role object to model authentication
 * @typedef {Object} Role
 * @property {Symbol} value the role value
 * @property {number} order the order of the role
 * @property {Role} Admin the admin role
 * @property {Role} Researcher the researcher role
 * @property {Role} Parent the parent role
 * @property {Role} Unauthenticated the unauthenticated role
 */
const Role = Object.freeze({
  Admin: {value: Symbol("Admin"), order: 0},
  Researcher: {value: Symbol("Researcher"), order: 1},
  Parent: {value: Symbol("Parent"), order: 2},
  // DO NOT CHECK THE UNAUTHENTICATED VALUE DIRECTLY!
  // It can change in the future and is only used for comparison.
  Unauthenticated: {value: Symbol("Unauthenticated"), order: 100},
});


/**
 * Gets the user's Role object from the token
 * @param {unknown} token the token object (context.auth.token)
 * @return {Role} the user's corresponding Role object
 */
function getRoleFromToken(token) {
  if (token.admin === true) {
    return Role.Admin;
  } else if (token.parent === true) {
    return Role.Parent;
  } else if (token.researcher === true) {
    return Role.Researcher;
  } else {
    return Role.Unauthenticated;
  }
}

module.exports = {
  Role,
  getRoleFromToken,
};
