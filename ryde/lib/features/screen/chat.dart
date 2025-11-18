import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

// ============================================================================
// 1. CONSTANTS & CONFIGURATION
// ============================================================================

// In a real app, get this from FirebaseAuth.instance.currentUser.uid
const String currentUserId = 'user_123_demo';
const types.User currentUser = types.User(id: currentUserId, firstName: 'Me');

// ============================================================================
// 2. DATA MODELS
// ============================================================================

/// Represents a conversation item in the inbox list
class ChatSummary {
  final String id;
  final String name;
  final String subtitle;
  final String? avatarUrl;
  final String lastMessage;
  final DateTime lastMessageTime;
  final bool isActive;

  ChatSummary({
    required this.id,
    required this.name,
    required this.subtitle,
    this.avatarUrl,
    required this.lastMessage,
    required this.lastMessageTime,
    this.isActive = false,
  });
}

// ============================================================================
// 3. FIREBASE SERVICE
// ============================================================================

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Creates a test chat in Firestore to verify the integration
  Future<void> createTestChat() async {
    final chatRoomId = const Uuid().v4();

    // 1. Create the Chat Document
    await _firestore.collection('chats').doc(chatRoomId).set({
      'participants': [currentUserId, 'driver_mike'],
      'names': {currentUserId: 'Me', 'driver_mike': 'Michael (Driver)'},
      'subtitles': {'driver_mike': 'Toyota Camry • 4.9★'},
      'avatars': {'driver_mike': 'https://i.pravatar.cc/150?u=1'},
      'lastMessage': 'Driver is on the way!',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'isActive': true,
    });

    // 2. Add an initial message
    await sendMessage(
      chatRoomId,
      "I'm on my way to the pickup point.",
      system: false,
      customAuthorId: 'driver_mike',
    );
  }

  /// Stream of Chat List (Inbox) for the current user
  Stream<List<ChatSummary>> getChats() {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();

            // Logic to find the "Other" user's name/details
            final Map<String, dynamic> names = data['names'] ?? {};
            final Map<String, dynamic> subtitles = data['subtitles'] ?? {};
            final Map<String, dynamic> avatars = data['avatars'] ?? {};

            // Find the key that is NOT the current user
            String otherId = names.keys.firstWhere(
              (k) => k != currentUserId,
              orElse: () => 'Unknown',
            );

            final timestamp = data['lastMessageTime'] as Timestamp?;

            return ChatSummary(
              id: doc.id,
              name: names[otherId] ?? 'Unknown User',
              subtitle: subtitles[otherId] ?? 'Driver',
              avatarUrl: avatars[otherId],
              lastMessage: data['lastMessage'] ?? '',
              lastMessageTime: timestamp?.toDate() ?? DateTime.now(),
              isActive: data['isActive'] ?? false,
            );
          }).toList();
        });
  }

  /// Stream of Messages for a specific chat room
  Stream<List<types.Message>> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();

            return types.TextMessage(
              author: types.User(
                id: data['authorId'],
                firstName: data['authorName'],
              ),
              createdAt: data['createdAt'],
              id: doc.id,
              text: data['text'],
            );
          }).toList();
        });
  }

  /// Send a text message
  Future<void> sendMessage(
    String chatId,
    String text, {
    bool system = false,
    String? customAuthorId,
  }) async {
    final String authorId =
        customAuthorId ?? (system ? 'system' : currentUserId);

    final messageData = {
      'authorId': authorId,
      'authorName': system ? 'System' : 'User',
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'text': text,
      'type': 'text',
    };

    // 1. Add message to 'messages' subcollection
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(messageData);

    // 2. Update the main chat document with the last message preview
    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
  }
}

// ============================================================================
// 4. SCREEN: INBOX LIST (Uber Style)
// ============================================================================

class UberChatListScreen extends StatelessWidget {
  const UberChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = ChatService();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Messages",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          // DEBUG BUTTON: Creates a fake chat for testing
          TextButton.icon(
            onPressed: () async {
              await service.createTestChat();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Test Chat Created! Refreshing..."),
                  ),
                );
              }
            },
            icon: const Icon(Icons.add, color: Colors.black),
            label: const Text(
              "New Test Chat",
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<ChatSummary>>(
        stream: service.getChats(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final chats = snapshot.data ?? [];

          if (chats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 60,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No messages yet",
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Tap 'New Test Chat' above to start.",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: chats.length,
            separatorBuilder: (_, __) =>
                const Divider(indent: 82, height: 1, color: Color(0xFFEEEEEE)),
            itemBuilder: (ctx, i) {
              final chat = chats[i];
              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UberChatDetailScreen(
                        chatId: chat.id,
                        title: chat.name,
                        subtitle: chat.subtitle,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      // Avatar
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: const Color(0xFFF6F6F6),
                            backgroundImage: chat.avatarUrl != null
                                ? NetworkImage(chat.avatarUrl!)
                                : null,
                            child: chat.avatarUrl == null
                                ? const Icon(Icons.person, color: Colors.grey)
                                : null,
                          ),
                          if (chat.isActive)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF276EF1), // Uber Blue
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      // Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  chat.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  _formatTime(chat.lastMessageTime),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              chat.lastMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey[800],
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              chat.subtitle,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatTime(DateTime time) {
    // Simple formatter: "10:30 AM" or "Yesterday"
    final now = DateTime.now();
    if (now.day == time.day &&
        now.month == time.month &&
        now.year == time.year) {
      return DateFormat('h:mm a').format(time);
    }
    return DateFormat('MMM d').format(time);
  }
}

// ============================================================================
// 5. SCREEN: CHAT ROOM (Uber Style)
// ============================================================================

class UberChatDetailScreen extends StatelessWidget {
  final String chatId;
  final String title;
  final String subtitle;

  const UberChatDetailScreen({
    super.key,
    required this.chatId,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final service = ChatService();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.grey.withOpacity(0.1),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            // Mini Avatar in App Bar
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[200],
              child: const Icon(Icons.person, size: 18, color: Colors.grey),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone, color: Colors.black),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.shield_outlined, color: Colors.blue),
            onPressed: () {},
          ),
        ],
      ),
      body: StreamBuilder<List<types.Message>>(
        stream: service.getMessages(chatId),
        builder: (context, snapshot) {
          // Loading State
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Chat UI Widget
          return Chat(
            messages: snapshot.data ?? [],
            onSendPressed: (partialText) {
              service.sendMessage(chatId, partialText.text);
            },
            user: currentUser,
            showUserAvatars: true,
            showUserNames: false, // Uber style usually hides names inside chat
            // --------------------------------------------------
            // UBER THEME CONFIGURATION
            // --------------------------------------------------
            theme: const DefaultChatTheme(
              // Colors
              primaryColor: Colors.black, // My bubbles: Black
              secondaryColor: Color(0xFFF3F3F3), // Their bubbles: Light Grey
              backgroundColor: Colors.white, // Background: White
              // Input Field
              inputBackgroundColor: Colors.white,
              inputTextColor: Colors.black,
              inputBorderRadius: BorderRadius.zero, // Flat input style
              inputContainerDecoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
              ),

              // Typography
              sentMessageBodyTextStyle: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
              receivedMessageBodyTextStyle: TextStyle(
                color: Colors.black,
                fontSize: 16,
              ),
            ),
          );
        },
      ),
    );
  }
}
