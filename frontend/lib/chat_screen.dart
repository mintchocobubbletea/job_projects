import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart'; // WebSocket용

class ChatScreen extends StatefulWidget {
  // 어떤 룸에 입장할지 받아옴 (공고 목록에서 전달)
  final String room;

  const ChatScreen({super.key, required this.room});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // WebSocket 채널 (서버와의 연결)
  late WebSocketChannel channel;
  // 메시지 입력 컨트롤러
  final TextEditingController _controller = TextEditingController();
  // 닉네임 (나중에 로그인 기능 붙이면 실제 유저명으로 교체)
  final String username = '가희';

  @override
  void initState() {
    super.initState();
    // WebSocket 연결 시작
    // 실제 폰 연결 시에는 10.0.2.2 → PC의 실제 IP로 변경
    channel = WebSocketChannel.connect(
      Uri.parse('ws://10.0.2.2:8000/ws/${widget.room}/$username'),
    );
  }

  // 메시지 전송 함수
  void sendMessage() {
    if (_controller.text.isNotEmpty) {
      // WebSocket으로 메시지 전송
      channel.sink.add(_controller.text);
      _controller.clear();
    }
  }

  @override
  void dispose() {
    // 화면 나갈 때 WebSocket 연결 해제 (메모리 누수 방지)
    channel.sink.close();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // 룸 이름을 앱바에 표시
        title: Text('${widget.room} 채팅방'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // 메시지 목록 영역
          Expanded(
            child: StreamBuilder(
              // WebSocket에서 오는 메시지를 실시간으로 수신
              stream: channel.stream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: Text('메시지를 기다리는 중...'));
                }
                // 새 메시지 수신 시 화면에 표시
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(snapshot.data.toString()),
                    ),
                  ],
                );
              },
            ),
          ),
          // 메시지 입력 영역
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: '메시지 입력',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    // 키보드에서 완료 누르면 전송
                    onSubmitted: (_) => sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: sendMessage,
                  icon: const Icon(Icons.send),
                  color: Colors.indigo,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
