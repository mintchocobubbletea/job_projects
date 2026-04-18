from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from typing import List, Dict

router = APIRouter()

# 룸별 연결 관리
class ConnectionManager:
    def __init__(self):
        # {"백엔드 개발자": [ws1, ws2], ...} 형태
        self.rooms: Dict[str, List[WebSocket]] = {}

    async def connect(self, websocket: WebSocket, room: str):
        await websocket.accept()
        if room not in self.rooms:
            self.rooms[room] = []
        self.rooms[room].append(websocket)

    def disconnect(self, websocket: WebSocket, room: str):
        self.rooms[room].remove(websocket)

    async def broadcast(self, message: str, room: str):
        # 같은 룸 사람들에게만 전송
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
            await manager.broadcast(f"{username}: {data}", room)
    except WebSocketDisconnect:
        manager.disconnect(websocket, room)
        await manager.broadcast(f"🔴 {username}님이 퇴장했습니다.", room)