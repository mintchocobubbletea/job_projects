import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

// StatefulWidget에 username 추가
class ChatScreen extends StatefulWidget {
  final String room;
  final String username; // 로그인 화면에서 받아온 닉네임

  const ChatScreen({super.key, required this.room, required this.username});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late WebSocketChannel channel;
  final TextEditingController _controller = TextEditingController();
  // 스크롤 컨트롤러 (새 메시지 오면 자동으로 아래로 스크롤)
  final ScrollController _scrollController = ScrollController();
  // 메시지 목록 저장 (StreamBuilder 대신 리스트로 관리)
  final List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    channel = WebSocketChannel.connect(
      // widget.username으로 StatefulWidget의 값에 접근
      Uri.parse('ws://192.168.0.20:8000/ws/${widget.room}/${widget.username}'),
    );

    // WebSocket에서 메시지 수신 시 리스트에 추가
    channel.stream.listen((message) {
      setState(() {
        _messages.add({
          'text': message,
          // 내가 보낸 메시지인지 확인 (닉네임으로 구분)
          'isMe': message.startsWith('${widget.username}:'),
        });
      });
      // 새 메시지 오면 자동으로 맨 아래로 스크롤
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }

  void sendMessage() {
    if (_controller.text.isNotEmpty) {
      channel.sink.add(_controller.text);
      _controller.clear();
    }
  }

  @override
  void dispose() {
    channel.sink.close();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.room} 채팅방'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            // 메시지 목록 영역
            Expanded(
              child: _messages.isEmpty
                  ? const Center(
                      child: Text(
                        '첫 메시지를 보내보세요!',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        final isMe = message['isMe'] as bool;
                        final isSystem =
                            message['text'].startsWith('🟢') ||
                            message['text'].startsWith('🔴');

                        // 입장/퇴장 시스템 메시지
                        if (isSystem) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Center(
                              child: Text(
                                message['text'],
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          );
                        }

                        // 내 메시지 / 상대 메시지 말풍선
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            // 내 메시지는 오른쪽, 상대 메시지는 왼쪽
                            mainAxisAlignment: isMe
                                ? MainAxisAlignment.end
                                : MainAxisAlignment.start,
                            children: [
                              Container(
                                constraints: BoxConstraints(
                                  // 말풍선 최대 너비 화면의 70%
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.7,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  // 내 메시지는 인디고, 상대는 회색
                                  color: isMe
                                      ? Colors.indigo
                                      : Colors.grey.shade200,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight: const Radius.circular(16),
                                    bottomLeft: Radius.circular(isMe ? 16 : 4),
                                    bottomRight: Radius.circular(isMe ? 4 : 16),
                                  ),
                                ),
                                child: Text(
                                  message['text'],
                                  style: TextStyle(
                                    color: isMe ? Colors.white : Colors.black87,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            // 메시지 입력 영역
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: '메시지 입력',
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      onSubmitted: (_) => sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Colors.indigo,
                    child: IconButton(
                      onPressed: sendMessage,
                      icon: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
