import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/design/app_design_system.dart';

/// Messages icon with unread count badge
class MessagesIcon extends StatelessWidget {
  const MessagesIcon({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) {
      return IconButton(
        icon: const Icon(
          Icons.chat_bubble_outline,
          color: AppDesignSystem.textPrimary,
          size: 26,
        ),
        onPressed: () {
          Navigator.pushNamed(context, '/chat-list');
        },
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: currentUserId)
          .snapshots(),
      builder: (context, snapshot) {
        int unreadCount = 0;

        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final unreadMap = data['unreadCount'] as Map<String, dynamic>? ?? {};
            unreadCount += (unreadMap[currentUserId] as int? ?? 0);
          }
        }

        return Stack(
          children: [
            IconButton(
              icon: const Icon(
                Icons.chat_bubble_outline,
                color: AppDesignSystem.textPrimary,
                size: 26,
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/chat-list');
              },
            ),
            if (unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppDesignSystem.primaryIndigo,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Center(
                    child: Text(
                      unreadCount > 99 ? '99+' : unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
