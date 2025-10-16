import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/badges_data.dart';

/// Utility script to populate all 35 badges into Firestore
/// Run this once to seed the /badges collection
/// 
/// Usage: Call this function from a screen or startup (admin only)
class BadgePopulator {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Populate all badges into Firestore
  /// Set overwrite to true to replace existing badges
  Future<void> populateBadges({bool overwrite = false}) async {
    final badges = BadgesData.getAllBadges();
    
    print('🏅 Starting badge population...');
    print('Total badges to upload: ${badges.length}');

    int created = 0;
    int updated = 0;
    int skipped = 0;

    for (final badge in badges) {
      try {
        final docRef = _firestore.collection('badges').doc(badge.id);
        final doc = await docRef.get();

        if (doc.exists && !overwrite) {
          print('⏭️  Skipping ${badge.id} (already exists)');
          skipped++;
          continue;
        }

        await docRef.set(badge.toFirestore());
        
        if (doc.exists) {
          print('🔄 Updated: ${badge.name} (${badge.category})');
          updated++;
        } else {
          print('✅ Created: ${badge.name} (${badge.category})');
          created++;
        }
      } catch (e) {
        print('❌ Error uploading ${badge.id}: $e');
      }
    }

    print('\n📊 Badge Population Summary:');
    print('  ✅ Created: $created');
    print('  🔄 Updated: $updated');
    print('  ⏭️  Skipped: $skipped');
    print('  📦 Total: ${created + updated + skipped}/${badges.length}');
    print('🎉 Badge population complete!');
  }

  /// Populate badges by category
  Future<void> populateBadgesByCategory(String category, {bool overwrite = false}) async {
    List<dynamic> badges;
    
    switch (category) {
      case 'milestone':
        badges = BadgesData.getMilestoneBadges();
        break;
      case 'streak':
        badges = BadgesData.getStreakBadges();
        break;
      case 'mastery':
        badges = BadgesData.getMasteryBadges();
        break;
      case 'social':
        badges = BadgesData.getSocialBadges();
        break;
      case 'special':
        badges = BadgesData.getSpecialBadges();
        break;
      default:
        print('❌ Invalid category: $category');
        return;
    }

    print('🏅 Populating $category badges (${badges.length} total)...');

    for (final badge in badges) {
      try {
        final docRef = _firestore.collection('badges').doc(badge.id);
        final doc = await docRef.get();

        if (doc.exists && !overwrite) {
          print('⏭️  Skipping ${badge.id}');
          continue;
        }

        await docRef.set(badge.toFirestore());
        print('✅ Uploaded: ${badge.name}');
      } catch (e) {
        print('❌ Error: $e');
      }
    }

    print('✅ $category badges populated!');
  }

  /// Delete all badges (use with caution)
  Future<void> clearAllBadges() async {
    print('🗑️  Deleting all badges...');
    
    final snapshot = await _firestore.collection('badges').get();
    final batch = _firestore.batch();

    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
    print('✅ All badges deleted (${snapshot.docs.length} total)');
  }

  /// Verify badge counts
  Future<void> verifyBadges() async {
    print('🔍 Verifying badge setup...\n');

    final snapshot = await _firestore.collection('badges').get();
    final totalCount = snapshot.docs.length;

    print('📊 Total badges in Firestore: $totalCount/35');

    // Count by category
    final categories = ['milestone', 'streak', 'mastery', 'social', 'special'];
    final expectedCounts = [10, 6, 7, 6, 6];

    for (int i = 0; i < categories.length; i++) {
      final category = categories[i];
      final expected = expectedCounts[i];
      final actual = snapshot.docs
          .where((doc) => doc.data()['category'] == category)
          .length;

      final status = actual == expected ? '✅' : '❌';
      print('$status $category: $actual/$expected');
    }

    if (totalCount == 35) {
      print('\n🎉 All badges verified successfully!');
    } else {
      print('\n⚠️  Badge count mismatch. Expected 35, found $totalCount');
    }
  }
}

