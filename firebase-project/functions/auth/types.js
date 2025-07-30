/**
 * A type object to model user types. Each user should only have one type claim.
 * NOTE: all values for types must end with _type.
 * @typedef {Object} Type
 * @property {Symbol} value the role value
//  * @property {Type} demo_type the corresponding demo type
 * @property {Type} researcher_type the researcher role
 * @property {Type} parent_type the parent role
//  * @property {Type} demo_researcher_type the demo researcher role
//  * @property {Type} demo_parent_type the demo user role
 */
const Type = Object.freeze({
  // Production types:
  researcher_type: {
    value: Symbol("researcher_type"),
  },
  parent_type: {
    value: Symbol("parent_type"),
  },
  unauthenticated_type: {
    value: Symbol("unauthenticated_type"),
  },
});

/**
 * Gets the user's Type object from the token
 * @param {unknown} token the token object (context.auth.token)
 * @return {Type} the user's corresponding Type object
 */
function getTypeFromToken(token) {
  if (token[Type.researcher_type.value.description] === true) {
    return Type.researcher_type;
  } else if (token[Type.parent_type.value.description] === true) {
    return Type.parent_type;
  } else {
    return Type.unauthenticated_type;
  }
}

/**
 * Gets the Type object from a string representation
 * @param {string} typeString the string representation of the type
 * @return {Type} the corresponding Type object
 */
function getTypeFromString(typeString) {
  switch (typeString) {
    case Type.researcher_type.value.description:
      return Type.researcher_type;
    case Type.parent_type.value.description:
      return Type.parent_type;
    default:
      return Type.unauthenticated_type;
  }
}

module.exports = {
  Type,
  getTypeFromToken,
  getTypeFromString,
};
