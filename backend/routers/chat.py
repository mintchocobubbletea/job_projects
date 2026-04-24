from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from typing import List, Dict

router = APIRouter()

# ── 욕설 필터링 ────────────────────────────────────────
# 나중에 단어 추가 가능
BANNED_WORDS = [
    "욕설1", "욕설2", "욕설3",  # 실제 욕설로 교체하세요
    "바보", "멍청이", "꺼져",    # 예시
]

def filter_message(message: str) -> str:
    # 금지어를 ***로 대체
    filtered = message
    for word in BANNED_WORDS:
        filtered = filtered.replace(word, "*" * len(word))
    return filtered

# ── 신고 기록 저장 ─────────────────────────────────────
# 실제 서비스에서는 DB에 저장해야 함
reports: List[Dict] = []

# ── 룸 관리 ───────────────────────────────────────────
class ConnectionManager:
    def __init__(self):
        self.rooms: Dict[str, List[WebSocket]] = {}

    async def connect(self, websocket: WebSocket, room: str):
        await websocket.accept()
        if room not in self.rooms:
            self.rooms[room] = []
        self.rooms[room].append(websocket)

    def disconnect(self, websocket: WebSocket, room: str):
        self.rooms[room].remove(websocket)

    async def broadcast(self, message: str, room: str):
        for connection in self.rooms.get(room, []):
            await connection.send_text(message)

manager = ConnectionManager()

@router.websocket("/ws/{room}/{username}")
async def websocket_endpoint(websocket: WebSocket, room: str, username: str):
    await manager.connect(websocket, room)
    await manager.broadcast(f"🟢 {username}님이 [{room}] 방에 입장했습니다.", room)
    try:
        while True:
            data = await websocket.receive_text()

            # 신고 메시지 처리 ("REPORT:신고할닉네임:이유" 형식)
            if data.startswith("REPORT:"):
                parts = data.split(":", 2)
                if len(parts) == 3:
                    reported_user = parts[1]
                    reason = parts[2]
                    reports.append({
                        "reporter": username,
                        "reported": reported_user,
                        "reason": reason,
                        "room": room,
                    })
                    # 신고자에게만 확인 메시지 전송
                    await websocket.send_text(f"🚨 {reported_user}님을 신고했습니다.")
                continue

            # 욕설 필터링 후 브로드캐스트
            filtered = filter_message(data)
            await manager.broadcast(f"{username}: {filtered}", room)

    except WebSocketDisconnect:
        manager.disconnect(websocket, room)
        await manager.broadcast(f"🔴 {username}님이 퇴장했습니다.", room)

# 신고 목록 조회 API (관리자용)
@router.get("/reports")
async def get_reports():
    return {"reports": reports}