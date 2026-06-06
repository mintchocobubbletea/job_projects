# main.py
# FastAPI 애플리케이션 진입점
# 서버 시작 시 DB 테이블 자동 생성
# 각 기능별 라우터를 등록하여 API 엔드포인트 구성

from fastapi import FastAPI
from backend.models.database import engine, Base
from backend.routers import auth, posts, reports

# FastAPI 애플리케이션 인스턴스 생성
app = FastAPI()

# 서버 시작 시 실행되는 이벤트 핸들러
# SQLAlchemy 모델을 기반으로 DB 테이블 자동 생성
# 이미 테이블이 존재하면 무시 (데이터 보존)
@app.on_event("startup")
async def startup():
    async with engine.begin() as conn:
        # Base에 등록된 모든 모델(User, Post, Comment, Report)의
        # 테이블을 DB에 생성
        await conn.run_sync(Base.metadata.create_all)

# ── 라우터 등록 ───────────────────────────────────────
# 각 기능별로 분리된 라우터를 메인 앱에 등록
# prefix는 각 라우터 파일에서 설정

# 인증 관련 API (/auth/register, /auth/login 등)
app.include_router(auth.router)

# 게시글/댓글 관련 API (/posts/...) + WebSocket (/posts/ws/...)
app.include_router(posts.router)

# 신고 관련 API (/reports)
app.include_router(reports.router)

# 서버 상태 확인용 엔드포인트
@app.get("/")
def root():
    return {"message": "취직하잡 API 작동 중!"}