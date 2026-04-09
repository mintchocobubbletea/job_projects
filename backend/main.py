from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from typing import List, Dict

app = FastAPI()

# ── 임시 데이터 (나중에 DB로 교체) ────────────────────────
# 실제 서비스에서는 PostgreSQL, SQLite 등 DB에서 가져옴
fake_jobs = [
    {"id": 1, "title": "백엔드 개발자", "company": "스타트업A", "location": "서울"},
    {"id": 2, "title": "프론트엔드 개발자", "company": "테크B", "location": "판교"},
    {"id": 3, "title": "AI 엔지니어", "company": "딥테크C", "location": "원격"},
]

# ── HTTP API 엔드포인트 ────────────────────────────────────
# HTTP는 요청 → 응답 후 연결이 끊기는 방식 (WebSocket과 다름)

@app.get("/")
def root():
    # 서버가 살아있는지 확인용 엔드포인트
    return {"message": "구직 커뮤니티 API 작동 중!"}

@app.get("/jobs")
def get_jobs():
    # 전체 공고 목록 반환
    return {"jobs": fake_jobs}

@app.get("/jobs/{job_id}")
def get_job(job_id: int):
    # job_id로 특정 공고 하나만 반환
    # URL 예시: /jobs/1 → 첫 번째 공고 반환
    for job in fake_jobs:
        if job["id"] == job_id:
            return job
    return {"error": "공고를 찾을 수 없습니다"}

# ── WebSocket 룸 관리 ──────────────────────────────────────
# WebSocket은 연결을 유지하면서 실시간으로 메시지를 주고받는 방식
# HTTP와 달리 서버가 먼저 클라이언트에게 메시지를 보낼 수 있음

class ConnectionManager:
    def __init__(self):
        # 룸별로 연결된 WebSocket 목록을 딕셔너리로 관리
        # 예시: {"백엔드": [ws1, ws2], "AI": [ws3]}
        self.rooms: Dict[str, List[WebSocket]] = {}

    async def connect(self, websocket: WebSocket, room: str):
        # 클라이언트 연결 수락
        await websocket.accept()
        # 해당 룸이 없으면 새로 만들기
        if room not in self.rooms:
            self.rooms[room] = []
        # 해당 룸의 연결 목록에 추가
        self.rooms[room].append(websocket)

    def disconnect(self, websocket: WebSocket, room: str):
        # 클라이언트 연결 해제 시 해당 룸에서 제거
        self.rooms[room].remove(websocket)

    async def broadcast(self, message: str, room: str):
        # 같은 룸에 있는 모든 클라이언트에게만 메시지 전송
        # 다른 룸에는 전송되지 않음
        for connection in self.rooms.get(room, []):
            await connection.send_text(message)

# ConnectionManager 인스턴스 생성 (앱 전체에서 하나만 사용)
manager = ConnectionManager()

# ── WebSocket 엔드포인트 ───────────────────────────────────
# URL 형식: /ws/{room}/{username}
# 예시: /ws/백엔드/가희 → 백엔드 룸에 가희로 입장

@app.websocket("/ws/{room}/{username}")
async def websocket_endpoint(websocket: WebSocket, room: str, username: str):
    # 1. 연결 수락 및 룸에 추가
    await manager.connect(websocket, room)
    # 2. 입장 메시지를 같은 룸 전체에 브로드캐스트
    await manager.broadcast(f"🟢 {username}님이 [{room}] 방에 입장했습니다.", room)
    try:
        # 3. 연결이 유지되는 동안 메시지를 계속 수신
        while True:
            data = await websocket.receive_text()
            # 받은 메시지를 같은 룸 전체에 브로드캐스트
            await manager.broadcast(f"{username}: {data}", room)
    except WebSocketDisconnect:
        # 4. 연결이 끊기면 룸에서 제거하고 퇴장 메시지 브로드캐스트
        manager.disconnect(websocket, room)
        await manager.broadcast(f"🔴 {username}님이 퇴장했습니다.", room)