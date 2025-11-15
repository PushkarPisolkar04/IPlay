/**
 * Set Admin Custom Claim for User
 * 
 * This script sets the isAdmin custom claim for a user,
 * allowing them to access admin-only features and the CMS.
 * 
 * Usage:
 *   node scripts/set_admin.js <email>
 * 
 * Example:
 *   node scripts/set_admin.js admin@example.com
 */

const admin = require('firebase-admin');
const serviceAccount = require('../serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

async function setAdminClaim(email) {
  try {
    console.log(`🔍 Looking up user: ${email}`);
    
    // Get user by email
    const user = await admin.auth().getUserByEmail(email);
    console.log(`✅ Found user: ${user.uid}`);
    
    // Set custom claim
    await admin.auth().setCustomUserClaims(user.uid, { isAdmin: true });
    console.log(`✅ Set admin claim for ${email}`);
    
    // Verify the claim was set
    const updatedUser = await admin.auth().getUser(user.uid);
    console.log(`\n📋 User custom claims:`, updatedUser.customClaims);
    
    console.log(`\n✨ Success! ${email} is now an admin.`);
    console.log(`\n⚠️  Important: User must sign out and sign back in for changes to take effect.`);
    
  } catch (error) {
    console.error('❌ Error setting admin claim:', error.message);
    
    if (error.code === 'auth/user-not-found') {
      console.log('\n💡 Tip: Make sure the user has signed up in the app first.');
    }
    
    throw error;
  }
}

// Get email from command line argument
const email = process.argv[2];

if (!email) {
  console.error('❌ Error: Email address required');
  console.log('\nUsage: node scripts/set_admin.js <email>');
  console.log('Example: node scripts/set_admin.js admin@example.com');
  process.exit(1);
}

// Validate email format
const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
if (!emailRegex.test(email)) {
  console.error('❌ Error: Invalid email format');
  process.exit(1);
}

// Run the script
setAdminClaim(email)
  .then(() => {
    console.log('\n🎉 Done!');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\n💥 Failed:', error);
    process.exit(1);
  });
