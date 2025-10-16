const {onSchedule} = require("firebase-functions/v2/scheduler");
const {onDocumentCreated, onDocumentDeleted} = require("firebase-functions/v2/firestore");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const PDFDocument = require("pdfkit");
const QRCode = require("qrcode");

admin.initializeApp();
const db = admin.firestore();
const storage = admin.storage().bucket();

/**
 * Scheduled Function: Daily Leaderboard Update
 * Runs every day at 2:00 AM IST (20:30 UTC previous day)
 * Aggregates leaderboards for all scopes (national, state, school, classroom)
 */
exports.dailyLeaderboardUpdate = onSchedule({
  schedule: "30 20 * * *", // 2:00 AM IST = 20:30 UTC
  timeZone: "Asia/Kolkata",
}, async (event) => {
  console.log("Starting daily leaderboard update...");

  try {
    const now = admin.firestore.Timestamp.now();
    const weekAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
    const monthAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);

    // Get all users
    const usersSnapshot = await db.collection("users").get();
    const users = usersSnapshot.docs.map((doc) => ({
      uid: doc.id,
      ...doc.data(),
    }));

    // Helper function to create leaderboard entry
    const createEntry = (user, rank) => ({
      userId: user.uid,
      displayName: user.displayName || "Anonymous",
      avatarUrl: user.avatarUrl || null,
      totalXP: user.totalXP || 0,
      rank,
    });

    // Helper function to save leaderboard
    const saveLeaderboard = async (scope, type, period, entries, identifier = null) => {
      const docId = [scope, type, period, identifier].filter(Boolean).join("_");
      await db.collection("leaderboard_cache").doc(docId).set({
        id: docId,
        scope,
        type,
        period,
        identifier,
        entries,
        lastUpdatedAt: now,
      });
    };

    // **NATIONAL LEADERBOARDS**
    // All-time, all learners
    const nationalAllTime = users
        .filter((u) => u.totalXP > 0)
        .sort((a, b) => b.totalXP - a.totalXP)
        .slice(0, 100)
        .map((user, i) => createEntry(user, i + 1));
    await saveLeaderboard("national", "all", "allTime", nationalAllTime);

    // All-time, solo learners (not in any classroom)
    const nationalSolo = users
        .filter((u) => u.totalXP > 0 && (!u.classroomIds || u.classroomIds.length === 0))
        .sort((a, b) => b.totalXP - a.totalXP)
        .slice(0, 100)
        .map((user, i) => createEntry(user, i + 1));
    await saveLeaderboard("national", "solo", "allTime", nationalSolo);

    console.log("National leaderboards updated");

    // **STATE LEADERBOARDS**
    const stateGroups = {};
    users.forEach((user) => {
      if (user.state && user.totalXP > 0) {
        if (!stateGroups[user.state]) stateGroups[user.state] = [];
        stateGroups[user.state].push(user);
      }
    });

    for (const [state, stateUsers] of Object.entries(stateGroups)) {
      const stateLeaderboard = stateUsers
          .sort((a, b) => b.totalXP - a.totalXP)
          .slice(0, 100)
          .map((user, i) => createEntry(user, i + 1));
      await saveLeaderboard("state", "all", "allTime", stateLeaderboard, state);
    }

    console.log(`State leaderboards updated for ${Object.keys(stateGroups).length} states`);

    // **SCHOOL LEADERBOARDS**
    const schoolsSnapshot = await db.collection("schools").get();
    for (const schoolDoc of schoolsSnapshot.docs) {
      const school = schoolDoc.data();
      const schoolUsers = users.filter((u) => u.schoolTag === school.id && u.totalXP > 0);

      if (schoolUsers.length > 0) {
        const schoolLeaderboard = schoolUsers
            .sort((a, b) => b.totalXP - a.totalXP)
            .slice(0, 100)
            .map((user, i) => createEntry(user, i + 1));
        await saveLeaderboard("school", "all", "allTime", schoolLeaderboard, school.id);
      }
    }

    console.log("School leaderboards updated");

    // **CLASSROOM LEADERBOARDS**
    const classroomsSnapshot = await db.collection("classrooms").get();
    for (const classroomDoc of classroomsSnapshot.docs) {
      const classroom = classroomDoc.data();
      const classroomUsers = users.filter((u) =>
        u.classroomIds && u.classroomIds.includes(classroomDoc.id) && u.totalXP > 0,
      );

      if (classroomUsers.length > 0) {
        const classroomLeaderboard = classroomUsers
            .sort((a, b) => b.totalXP - a.totalXP)
            .slice(0, 100)
            .map((user, i) => createEntry(user, i + 1));
        await saveLeaderboard("classroom", "all", "allTime", classroomLeaderboard, classroomDoc.id);
      }
    }

    console.log("Classroom leaderboards updated");
    console.log("Daily leaderboard update complete!");
  } catch (error) {
    console.error("Error updating leaderboards:", error);
  }
});

/**
 * Scheduled Function: Daily Challenge Generation
 * Runs every day at 12:01 AM IST (18:31 UTC previous day)
 * Creates a new daily challenge with 5 random questions
 */
exports.dailyChallengeGeneration = onSchedule({
  schedule: "31 18 * * *", // 12:01 AM IST = 18:31 UTC
  timeZone: "Asia/Kolkata",
}, async (event) => {
  console.log("Generating daily challenge...");

  try {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const expiresAt = new Date(today);
    expiresAt.setDate(expiresAt.getDate() + 1);

    // Question bank (in production, this would be a larger collection)
    const questionBank = [
      {
        question: "What is the term of copyright protection in India for original literary works?",
        options: ["50 years", "60 years", "70 years", "Lifetime + 60 years"],
        correctAnswer: 3,
        explanation: "In India, copyright lasts for the lifetime of the author plus 60 years.",
      },
      {
        question: "Which symbol is used to indicate a registered trademark?",
        options: ["©", "™", "®", "℗"],
        correctAnswer: 2,
        explanation: "® symbol indicates a registered trademark.",
      },
      {
        question: "What is the maximum term for a patent in India?",
        options: ["10 years", "20 years", "25 years", "30 years"],
        correctAnswer: 1,
        explanation: "Patents in India are valid for 20 years from the date of filing.",
      },
      {
        question: "Which of the following is NOT protected under copyright?",
        options: ["Ideas", "Books", "Music", "Paintings"],
        correctAnswer: 0,
        explanation: "Copyright protects expression, not ideas themselves.",
      },
      {
        question: "GI stands for:",
        options: ["Global Indication", "Geographical Indication", "General Indication", "Government Indication"],
        correctAnswer: 1,
        explanation: "GI stands for Geographical Indication.",
      },
      {
        question: "What is the primary purpose of a trademark?",
        options: ["Protect inventions", "Identify goods/services", "Protect artistic works", "Protect designs"],
        correctAnswer: 1,
        explanation: "Trademarks identify and distinguish goods or services.",
      },
      {
        question: "Which Indian product was the first to receive GI tag?",
        options: ["Basmati Rice", "Darjeeling Tea", "Mysore Silk", "Kanchipuram Silk"],
        correctAnswer: 1,
        explanation: "Darjeeling Tea was the first Indian product to get GI tag in 2003.",
      },
      {
        question: "What does 'patent pending' mean?",
        options: ["Patent granted", "Patent application filed", "Patent rejected", "Patent expired"],
        correctAnswer: 1,
        explanation: "Patent pending means a patent application has been filed but not yet granted.",
      },
    ];

    // Select 5 random questions
    const shuffled = questionBank.sort(() => 0.5 - Math.random());
    const selected = shuffled.slice(0, 5);

    const challenge = {
      id: `challenge_${today.toISOString().split("T")[0]}`,
      date: admin.firestore.Timestamp.fromDate(today),
      questions: selected,
      xpReward: 50,
      expiresAt: admin.firestore.Timestamp.fromDate(expiresAt),
    };

    await db.collection("daily_challenges").doc(challenge.id).set(challenge);
    console.log("Daily challenge generated:", challenge.id);
  } catch (error) {
    console.error("Error generating daily challenge:", error);
  }
});

/**
 * Firestore Trigger: Generate Certificate on Progress Update
 * Triggers when user's progressSummary is updated
 * Generates PDF certificate when a realm is completed
 */
exports.generateCertificate = onDocumentCreated("users/{userId}", async (event) => {
  const userId = event.params.userId;
  const userData = event.data.data();

  if (!userData.progressSummary) return;

  try {
    // Check each realm for completion
    const realms = [
      {id: "realm_copyright", name: "Copyright"},
      {id: "realm_trademark", name: "Trademark"},
      {id: "realm_patent", name: "Patent"},
      {id: "realm_design", name: "Industrial Design"},
      {id: "realm_gi", name: "Geographical Indication"},
      {id: "realm_secrets", name: "Trade Secrets"},
    ];

    for (const realm of realms) {
      const realmProgress = userData.progressSummary[realm.id];

      if (realmProgress && realmProgress.completed) {
        // Check if certificate already exists
        const existingCert = await db.collection("certificates")
            .where("userId", "==", userId)
            .where("realmId", "==", realm.id)
            .limit(1)
            .get();

        if (existingCert.empty) {
          // Generate certificate
          const certificateNumber = `IPLAY-${realm.id.toUpperCase()}-${Date.now()}`;
          const certificateId = `${userId}_${realm.id}`;

          // Create PDF (simplified version)
          const pdfPath = `certificates/${userId}/${certificateId}.pdf`;
          const pdfDoc = new PDFDocument();
          const buffers = [];

          pdfDoc.on("data", buffers.push.bind(buffers));
          pdfDoc.on("end", async () => {
            const pdfBuffer = Buffer.concat(buffers);

            // Upload to Storage
            const file = storage.file(pdfPath);
            await file.save(pdfBuffer, {
              metadata: {contentType: "application/pdf"},
            });

            // Save certificate record
            await db.collection("certificates").doc(certificateId).set({
              id: certificateId,
              userId,
              certificateType: "realm",
              realmId: realm.id,
              realmName: realm.name,
              certificateUrl: `gs://${storage.name}/${pdfPath}`,
              certificateNumber,
              issuedAt: admin.firestore.Timestamp.now(),
            });

            console.log(`Certificate generated: ${certificateNumber}`);
          });

          // Generate QR code
          const qrCodeData = await QRCode.toDataURL(`https://iplay.app/verify/${certificateNumber}`);

          // Create PDF content
          pdfDoc.fontSize(30).text("Certificate of Achievement", 100, 100);
          pdfDoc.fontSize(20).text(`This certifies that`, 100, 200);
          pdfDoc.fontSize(25).text(userData.displayName || "Student", 100, 250, {bold: true});
          pdfDoc.fontSize(20).text(`has successfully completed the`, 100, 300);
          pdfDoc.fontSize(25).text(`${realm.name} Realm`, 100, 350, {bold: true});
          pdfDoc.fontSize(12).text(`Certificate Number: ${certificateNumber}`, 100, 450);
          pdfDoc.fontSize(12).text(`Issued: ${new Date().toLocaleDateString()}`, 100, 470);

          // Add QR code (simplified - actual implementation would decode base64)
          pdfDoc.fontSize(10).text("Verify at iplay.app/verify", 100, 500);

          pdfDoc.end();
        }
      }
    }
  } catch (error) {
    console.error("Error generating certificate:", error);
  }
});

/**
 * Firestore Trigger: Cleanup on User Deletion
 * Triggers when a user document is deleted
 * Removes all user data (progress, certificates, etc.)
 */
exports.onUserDeleted = onDocumentDeleted("users/{userId}", async (event) => {
  const userId = event.params.userId;

  try {
    const batch = db.batch();

    // Delete progress
    const progressDocs = await db.collection("progress").where("userId", "==", userId).get();
    progressDocs.forEach((doc) => batch.delete(doc.ref));

    // Delete certificates
    const certDocs = await db.collection("certificates").where("userId", "==", userId).get();
    certDocs.forEach((doc) => batch.delete(doc.ref));

    // Delete daily challenge attempts
    const attemptDocs = await db.collection("daily_challenge_attempts").where("userId", "==", userId).get();
    attemptDocs.forEach((doc) => batch.delete(doc.ref));

    // Remove from classrooms
    const classroomDocs = await db.collection("classrooms").where("studentIds", "array-contains", userId).get();
    classroomDocs.forEach((doc) => {
      batch.update(doc.ref, {
        studentIds: admin.firestore.FieldValue.arrayRemove(userId),
      });
    });

    await batch.commit();
    console.log(`User ${userId} data cleaned up`);
  } catch (error) {
    console.error("Error cleaning up user data:", error);
  }
});

/**
 * Firestore Trigger: Cleanup on Classroom Deletion
 * Triggers when a classroom document is deleted
 * Removes classroom from all students and related data
 */
exports.onClassroomDeleted = onDocumentDeleted("classrooms/{classroomId}", async (event) => {
  const classroomId = event.params.classroomId;
  const classroomData = event.data.data();

  try {
    const batch = db.batch();

    // Remove classroom from students
    if (classroomData.studentIds) {
      for (const studentId of classroomData.studentIds) {
        const studentRef = db.collection("users").doc(studentId);
        batch.update(studentRef, {
          classroomIds: admin.firestore.FieldValue.arrayRemove(classroomId),
        });
      }
    }

    // Delete join requests
    const requestDocs = await db.collection("join_requests").where("classroomId", "==", classroomId).get();
    requestDocs.forEach((doc) => batch.delete(doc.ref));

    // Delete announcements
    const announcementDocs = await db.collection("announcements").where("classroomId", "==", classroomId).get();
    announcementDocs.forEach((doc) => batch.delete(doc.ref));

    // Delete assignments
    const assignmentDocs = await db.collection("assignments").where("classroomId", "==", classroomId).get();
    assignmentDocs.forEach((doc) => batch.delete(doc.ref));

    await batch.commit();
    console.log(`Classroom ${classroomId} data cleaned up`);
  } catch (error) {
    console.error("Error cleaning up classroom data:", error);
  }
});

/**
 * Callable Function: Transfer School Ownership
 * Transfers principal role from one user to another
 */
exports.transferSchoolOwnership = onCall(async (request) => {
  const {schoolId, newPrincipalId} = request.data;
  const callerId = request.auth.uid;

  if (!schoolId || !newPrincipalId) {
    throw new HttpsError("invalid-argument", "Missing required parameters");
  }

  try {
    // Get school
    const schoolDoc = await db.collection("schools").doc(schoolId).get();
    if (!schoolDoc.exists) {
      throw new HttpsError("not-found", "School not found");
    }

    const school = schoolDoc.data();

    // Verify caller is current principal
    if (school.principalId !== callerId) {
      throw new HttpsError("permission-denied", "Only the current principal can transfer ownership");
    }

    // Update school
    await db.collection("schools").doc(schoolId).update({
      principalId: newPrincipalId,
      updatedAt: admin.firestore.Timestamp.now(),
    });

    // Update old principal
    await db.collection("users").doc(callerId).update({
      isPrincipal: false,
      principalOfSchool: admin.firestore.FieldValue.delete(),
    });

    // Update new principal
    await db.collection("users").doc(newPrincipalId).update({
      isPrincipal: true,
      principalOfSchool: schoolId,
    });

    return {success: true, message: "School ownership transferred"};
  } catch (error) {
    console.error("Error transferring school ownership:", error);
    throw new HttpsError("internal", error.message);
  }
});

/**
 * Callable Function: Ban User
 * Admin-only function to ban a user and remove them from all classrooms
 */
exports.banUser = onCall(async (request) => {
  const {targetUserId, reason} = request.data;
  const callerId = request.auth.uid;

  if (!targetUserId) {
    throw new HttpsError("invalid-argument", "Missing targetUserId");
  }

  try {
    // Verify caller is admin
    const callerDoc = await db.collection("users").doc(callerId).get();
    if (!callerDoc.exists || callerDoc.data().role !== "admin") {
      throw new HttpsError("permission-denied", "Admin access required");
    }

    // Update user
    await db.collection("users").doc(targetUserId).update({
      isBanned: true,
      bannedAt: admin.firestore.Timestamp.now(),
      bannedBy: callerId,
      banReason: reason || "Violation of terms",
    });

    // Remove from all classrooms
    const classroomDocs = await db.collection("classrooms").where("studentIds", "array-contains", targetUserId).get();
    const batch = db.batch();
    classroomDocs.forEach((doc) => {
      batch.update(doc.ref, {
        studentIds: admin.firestore.FieldValue.arrayRemove(targetUserId),
      });
    });
    await batch.commit();

    return {success: true, message: "User banned successfully"};
  } catch (error) {
    console.error("Error banning user:", error);
    throw new HttpsError("internal", error.message);
  }
});

/**
 * Scheduled Function: Weekly Cleanup
 * Runs every Sunday at 3:00 AM IST (21:30 UTC Saturday)
 * Cleans up old join requests and expired announcements
 */
exports.weeklyCleanup = onSchedule({
  schedule: "30 21 * * 6", // 3:00 AM IST Sunday = 21:30 UTC Saturday
  timeZone: "Asia/Kolkata",
}, async (event) => {
  console.log("Starting weekly cleanup...");

  try {
    const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);

    // Delete old resolved join requests
    const oldRequests = await db.collection("join_requests")
        .where("resolvedAt", "<", admin.firestore.Timestamp.fromDate(thirtyDaysAgo))
        .get();

    const batch = db.batch();
    oldRequests.forEach((doc) => batch.delete(doc.ref));

    // Delete expired announcements
    const expiredAnnouncements = await db.collection("announcements")
        .where("expiresAt", "<", admin.firestore.Timestamp.now())
        .get();

    expiredAnnouncements.forEach((doc) => batch.delete(doc.ref));

    await batch.commit();
    console.log(`Cleaned up ${oldRequests.size} old requests and ${expiredAnnouncements.size} expired announcements`);
  } catch (error) {
    console.error("Error in weekly cleanup:", error);
  }
});

// Weekly Backup (Sunday 3 AM IST)
exports.weeklyBackup = onSchedule("0 3 * * 0", async (event) => {
  console.log("Starting weekly backup...");
  const bucket = admin.storage().bucket();
  const timestamp = new Date().toISOString().split("T")[0];
  const collections = ["users", "schools", "classrooms", "progress", "certificates"];

  for (const collectionName of collections) {
    const snapshot = await db.collection(collectionName).get();
    const data = snapshot.docs.map((doc) => ({id: doc.id, ...doc.data()}));
    const fileName = `backups/${timestamp}/${collectionName}.json`;
    await bucket.file(fileName).save(JSON.stringify(data, null, 2), {contentType: "application/json"});
    console.log(`Backed up ${collectionName}: ${data.length} documents`);
  }
  console.log("Backup complete");
});

// Generate unique classroom code (callable)
exports.generateClassroomCode = onCall(async (request) => {
  for (let i = 0; i < 10; i++) {
    const chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
    const code = "CLS-" + Array.from({length: 5}, () => chars[Math.floor(Math.random() * chars.length)]).join("");
    const existing = await db.collection("classrooms").where("joinCode", "==", code).limit(1).get();
    if (existing.empty) return {code};
  }
  throw new Error("Failed to generate unique code");
});

// Generate unique school code (callable)
exports.generateSchoolCode = onCall(async (request) => {
  for (let i = 0; i < 10; i++) {
    const chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
    const code = "SCH-" + Array.from({length: 5}, () => chars[Math.floor(Math.random() * chars.length)]).join("");
    const existing = await db.collection("schools").where("schoolCode", "==", code).limit(1).get();
    if (existing.empty) return {code};
  }
  throw new Error("Failed to generate unique code");
});

// Moderate content (callable, admin only)
exports.moderateContent = onCall(async (request) => {
  const {reportId, action, resolution} = request.data;
  const adminId = request.auth?.uid;
  if (!adminId) throw new Error("Unauthorized");

  const adminDoc = await db.collection("users").doc(adminId).get();
  if (!adminDoc.exists || adminDoc.data().role !== "admin") throw new Error("Admin only");

  const reportDoc = await db.collection("reports").doc(reportId).get();
  if (!reportDoc.exists) throw new Error("Report not found");

  const report = reportDoc.data();
  const batch = db.batch();

  batch.update(db.collection("reports").doc(reportId), {
    status: action === "dismiss" ? "dismissed" : "resolved",
    reviewedAt: admin.firestore.Timestamp.now(),
    reviewedBy: adminId,
    resolution: resolution || `Action: ${action}`,
  });

  if (action === "delete") {
    batch.delete(db.collection(report.reportType + "s").doc(report.reportedItemId));
  } else if (action === "ban") {
    batch.update(db.collection("users").doc(report.reporterId), {
      isBanned: true,
      bannedAt: admin.firestore.Timestamp.now(),
      bannedBy: adminId,
      banReason: resolution || "Policy violation",
    });
  }

  await batch.commit();
  console.log(`Report ${reportId} moderated: ${action}`);
  return {success: true};
});

