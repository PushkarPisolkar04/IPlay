import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/design/app_design_system.dart';
import '../../services/simplified_chat_service.dart';
import '../../widgets/loading_skeleton.dart';
import 'chat_screen.dart';
import '../teacher/all_students_screen.dart';
import 'select_teacher_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final SimplifiedChatService _chatService = SimplifiedChatService();
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists && mounted) {
        setState(() {
          _userRole = userDoc.data()?['role'];
        });
      }
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 0) {
      if (diff.inDays == 1) return 'Yesterday';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${date.day}/${date.month}';
    }
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  Future<Map<String, dynamic>?> _getUserData(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      return doc.data();
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text('Messages', style: AppDesignSystem.h5),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      floatingActionButton: _userRole != null
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => _userRole == 'teacher'
                        ? const AllStudentsScreen()
                        : const SelectTeacherScreen(),
                  ),
                );
              },
              backgroundColor: AppDesignSystem.primaryIndigo,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('New Message', style: TextStyle(color: Colors.white)),
            )
          : null,
      body: StreamBuilder<QuerySnapshot>(
        stream: _chatService.getUserChats(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppDesignSystem.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading chats',
                    style: AppDesignSystem.h5,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: AppDesignSystem.bodySmall.copyWith(
                      color: AppDesignSystem.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const ListSkeleton(itemCount: 5);
          }

          final chats = snapshot.data?.docs ?? [];

          if (chats.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async {
                // Force refresh by rebuilding
                setState(() {});
              },
              color: AppDesignSystem.primaryIndigo,
              child: ListView(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height - 200,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 80,
                            color: AppDesignSystem.textTertiary,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'No messages yet',
                            style: AppDesignSystem.h4.copyWith(
                              color: AppDesignSystem.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 48),
                            child: Text(
                              _userRole == 'student'
                                  ? 'No messages yet\n\nTap the button below to message your teachers!'
                                  : 'No messages yet\n\nTap the button below to message your students!',
                              style: AppDesignSystem.bodyMedium.copyWith(
                                color: AppDesignSystem.textTertiary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              // Force refresh by rebuilding
              setState(() {});
            },
            color: AppDesignSystem.primaryIndigo,
            child: ListView.separated(
            itemCount: chats.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final chat = chats[index].data() as Map<String, dynamic>;
              final chatId = chats[index].id;
              final participants = List<String>.from(chat['participants'] ?? []);
              final otherUserId = participants.firstWhere(
                (id) => id != currentUserId,
                orElse: () => '',
              );
              final lastMessage = chat['lastMessage'] as String? ?? '';
              final lastMessageAt = chat['lastMessageAt'] as Timestamp?;
              final unreadCount = (chat['unreadCount'] as Map<String, dynamic>?)?[currentUserId] ?? 0;

              return FutureBuilder<Map<String, dynamic>?>(
                future: _getUserData(otherUserId),
                builder: (context, userSnapshot) {
                  final userData = userSnapshot.data;
                  final userName = userData?['displayName'] ?? 'User';
                  final userAvatar = userData?['avatarUrl'];

                  return ListTile(
                    leading: Stack(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppDesignSystem.primaryIndigo.withValues(alpha: 0.1),
                          backgroundImage: userAvatar != null ? NetworkImage(userAvatar) : null,
                          child: userAvatar == null
                              ? Text(
                                  userName[0].toUpperCase(),
                                  style: AppDesignSystem.h6.copyWith(
                                    color: AppDesignSystem.primaryIndigo,
                                  ),
                                )
                              : null,
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppDesignSystem.error,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 20,
                                minHeight: 20,
                              ),
                              child: Text(
                                unreadCount > 9 ? '9+' : unreadCount.toString(),
                                style: AppDesignSystem.caption.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                    title: Text(
                      userName,
                      style: AppDesignSystem.bodyMedium.copyWith(
                        fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      lastMessage.isEmpty ? 'No messages yet' : lastMessage,
                      style: AppDesignSystem.bodySmall.copyWith(
                        color: unreadCount > 0
                            ? AppDesignSystem.textPrimary
                            : AppDesignSystem.textSecondary,
                        fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatTimestamp(lastMessageAt),
                          style: AppDesignSystem.caption.copyWith(
                            color: unreadCount > 0
                                ? AppDesignSystem.primaryIndigo
                                : AppDesignSystem.textTertiary,
                            fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            chatId: chatId,
                            otherUserName: userName,
                            otherUserAvatar: userAvatar,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
            ),
          );
        },
      ),
    );
  }
}
