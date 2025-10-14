const {logger} = require("firebase-functions");
const https = require("firebase-functions/v2/https");

const splitName = (displayName) => {
  if (!displayName || typeof displayName !== "string") {
    return {firstName: null, lastName: null};
  }
  const parts = displayName.trim().split(/\s+/);
  if (!parts.length) {
    return {firstName: null, lastName: null};
  }
  const firstName = parts.shift();
  const lastName = parts.length ? parts.join(" ") : null;
  return {firstName, lastName};
};

/**
 * Migrates users from old Parent/Researcher collections to new UserProfile
 *
 * Usage:
 * - Call with {dryRun: true} to see what would be migrated
 * - Call with {dryRun: false} to actually migrate
 *
 * Requires admin authentication
 */
exports.migrateToUserProfile = https.onCall(async (req, context) => {
  // Import admin here to avoid initialization issues
  const admin = require("firebase-admin");
  const db = admin.firestore();
  // Require admin authentication
  if (!context.auth || !context.auth.token.admin) {
    throw new https.HttpsError(
        "permission-denied",
        "Admin access required for migration",
    );
  }

  const dryRun = req.data.dryRun !== false; // Default to dry run for safety
  const results = {
    parents: {migrated: 0, skipped: 0, errors: []},
    researchers: {migrated: 0, skipped: 0, errors: []},
    totalMigrated: 0,
    totalSkipped: 0,
    totalErrors: 0,
  };

  logger.info(`Starting migration... (dryRun: ${dryRun})`);

  try {
    // ==================== MIGRATE PARENTS ====================
    logger.info("Migrating Parent documents...");
    const parentSnapshot = await db.collection("Parent").get();

    for (const parentDoc of parentSnapshot.docs) {
      const parentId = parentDoc.id;
      const parentData = parentDoc.data();

      try {
        // Check if already migrated
        const profileExists = await db
            .collection("UserProfile")
            .doc(parentId)
            .get();
        if (profileExists.exists) {
          logger.info(
              // eslint-disable-next-line max-len
              `${dryRun ? "[DRY RUN] " : ""}Skipping ${parentId} - already migrated`,
          );
          results.parents.skipped++;
          continue;
        }

        const nameFromParent = parentData.name || null;
        const parsedParentName = splitName(nameFromParent);

        // Create UserProfile from Parent data
        const userProfile = {
          role: "parent",
          status: "active",
          email: null, // Will get from auth
          name: nameFromParent,
          firstName: parsedParentName.firstName,
          lastName: parsedParentName.lastName,
          emailVerified: false,
          twoFactorEnabled: false,
          acceptedPrivacyPolicy: parentData.acceptedPrivacyPolicy || false,
          policyVersion: parentData.policyVersion || null,
          consentDate: parentData.consentDate || null,
          surveyCompleted: parentData.preStudySurveyComplete || false,
          surveyVersion:
            parentData.preStudySurveyComplete ? "legacy" : null,
          childIDs: parentData.childIDs || [],
          preferredLanguage: parentData.language || "en",
          // Metadata
          migratedFrom: "Parent",
          migratedAt: admin.firestore.FieldValue.serverTimestamp(),
          createdAt: parentData.createdAt ||
            admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        };

        // Get email from Firebase Auth
        try {
          const userRecord = await admin.auth().getUser(parentId);
          if (!userProfile.email) {
            userProfile.email = userRecord.email;
          }
          if (!userProfile.name && userRecord.displayName) {
            userProfile.name = userRecord.displayName;
          }
          const parsedAuthName = splitName(userRecord.displayName);
          if (!userProfile.firstName && parsedAuthName.firstName) {
            userProfile.firstName = parsedAuthName.firstName;
          }
          if (!userProfile.lastName && parsedAuthName.lastName) {
            userProfile.lastName = parsedAuthName.lastName;
          }
          userProfile.emailVerified = userRecord.emailVerified;
        } catch (authError) {
          logger.warn(
              `Could not get auth data for ${parentId}: ${authError}`,
          );
        }

        if (!dryRun) {
          await db.collection("UserProfile").doc(parentId).set(userProfile);
        }

        results.parents.migrated++;
        logger.info(
            `${dryRun ? "[DRY RUN] " : ""}Migrated Parent ${parentId}`,
        );
      } catch (error) {
        logger.error(`Error migrating Parent ${parentId}: ${error}`);
        results.parents.errors.push({
          id: parentId,
          error: error.toString(),
        });
      }
    }

    // ==================== MIGRATE RESEARCHERS ====================
    logger.info("Migrating Researcher documents...");
    const researcherSnapshot = await db.collection("Researcher").get();

    for (const researcherDoc of researcherSnapshot.docs) {
      const researcherId = researcherDoc.id;
      const researcherData = researcherDoc.data();

      try {
        // Check if already migrated
        const profileExists = await db
            .collection("UserProfile")
            .doc(researcherId)
            .get();
        if (profileExists.exists) {
          logger.info(
              // eslint-disable-next-line max-len
              `${dryRun ? "[DRY RUN] " : ""}Skipping ${researcherId} - already migrated`,
          );
          results.researchers.skipped++;
          continue;
        }

        const nameFromResearcher = researcherData.name || null;
        const parsedResearcherName = splitName(nameFromResearcher);

        const userProfile = {
          role: "researcher",
          status: "active",
          email: researcherData.email || null,
          name: nameFromResearcher,
          firstName: parsedResearcherName.firstName,
          lastName: parsedResearcherName.lastName,
          phoneNumber: researcherData.phoneNumber || null,
          institution: researcherData.institution || null,
          emailVerified: false,
          twoFactorEnabled: false,
          acceptedPrivacyPolicy:
            researcherData.acceptedPrivacyPolicy || false,
          policyVersion: researcherData.policyVersion || null,
          consentDate: researcherData.consentDate || null,
          surveyCompleted: true, // Researchers don't need survey
          childIDs: [],
          // Metadata
          migratedFrom: "Researcher",
          migratedAt: admin.firestore.FieldValue.serverTimestamp(),
          createdAt: researcherData.createdAt ||
            admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        };

        // Get email from Firebase Auth if not set
        try {
          const userRecord = await admin.auth().getUser(researcherId);
          if (!userProfile.email) {
            userProfile.email = userRecord.email;
          }
          if (!userProfile.name && userRecord.displayName) {
            userProfile.name = userRecord.displayName;
          }
          const parsedAuthName = splitName(userRecord.displayName);
          if (!userProfile.firstName && parsedAuthName.firstName) {
            userProfile.firstName = parsedAuthName.firstName;
          }
          if (!userProfile.lastName && parsedAuthName.lastName) {
            userProfile.lastName = parsedAuthName.lastName;
          }
          userProfile.emailVerified = userRecord.emailVerified;
        } catch (authError) {
          logger.warn(
              `Could not get auth data for ${researcherId}: ${authError}`,
          );
        }

        if (!dryRun) {
          await db
              .collection("UserProfile")
              .doc(researcherId)
              .set(userProfile);
        }

        results.researchers.migrated++;
        logger.info(
            `${dryRun ? "[DRY RUN] " : ""}Migrated Researcher ${researcherId}`,
        );
      } catch (error) {
        logger.error(
            `Error migrating Researcher ${researcherId}: ${error}`,
        );
        results.researchers.errors.push({
          id: researcherId,
          error: error.toString(),
        });
      }
    }

    // ==================== FINAL RESULTS ====================
    results.totalMigrated =
      results.parents.migrated + results.researchers.migrated;
    results.totalSkipped =
      results.parents.skipped + results.researchers.skipped;
    results.totalErrors =
      results.parents.errors.length + results.researchers.errors.length;

    logger.info("Migration complete!", results);

    return {
      success: true,
      dryRun: dryRun,
      ...results,
    };
  } catch (error) {
    logger.error("Migration failed:", error);
    throw new https.HttpsError(
        "internal",
        `Migration failed: ${error}`,
    );
  }
});
