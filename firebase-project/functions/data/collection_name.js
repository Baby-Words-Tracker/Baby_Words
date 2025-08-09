/* eslint-disable require-jsdoc */

const parentSymbol = Symbol("User");
const researcherSymbol = Symbol("User");
const childSymbol = Symbol("Child");
const unknownSymbol = Symbol("Unknown");

/**
 * Collection names for Firestore
 * @typedef {Object} CollectionName
 * @property {String} name - The name of the collection
 * @property {String} demoName - The name of the demo collection
 * @property {CollectionName} parent - The parent collection
 * @property {CollectionName} researcher - The researcher collection
 * @property {CollectionName} user - The user collection
 * @property {CollectionName} child - The child collection
 * @property {CollectionName} unknown - The unknown collection
 */
const CollectionName = Object.freeze({
  parent: {
    name: parentSymbol.description,
    demoName: "demo_" + parentSymbol.description,
  },
  researcher: {
    name: researcherSymbol.description,
    demoName: "demo_" + researcherSymbol.description,
  },
  child: {
    name: childSymbol.description,
    demoName: "demo_" + childSymbol.description,
  },
  unknown: {
    name: unknownSymbol.description,
    demoName: "demo_" + unknownSymbol.description,
  },
});


/**
 * Gets the CollectionName object from a string representation
 * @param {string} nameString the string representation of the name
 * @return {CollectionName} the corresponding CollectionName object
 */
function getCollectionNameFromString(nameString) {
  switch (nameString) {
    case CollectionName.parent.name:
    case CollectionName.parent.demoName:
      return CollectionName.parent;
    case CollectionName.researcher.name:
    case CollectionName.researcher.demoName:
      return CollectionName.researcher;
    case CollectionName.child.name:
    case CollectionName.child.demoName:
      return CollectionName.child;
    default:
      return CollectionName.unknown;
  }
}

exports = {
  CollectionName,
  getCollectionNameFromString,
};
