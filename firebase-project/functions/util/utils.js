// eslint-disable-next-line require-jsdoc
function logDataObject(data) {
  try {
    console.log("Full data object:", JSON.stringify(data, null, 2));
  } catch (error) {
    console.error("Could not stringify data object:", error);
  }
  console.log("Type of data:", typeof data);
  console.log("Keys in data:", Object.keys(data));
}

module.exports = {
  logDataObject,
};
