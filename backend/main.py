from fastapi import FastAPI
from backend.models.database import engine, Base
from backend.routers import jobs, chat

app = FastAPI()

# 앱 시작할 때 DB 테이블 자동 생성
@app.on_event("startup")
async def startup():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

# 라우터 등록
app.include_router(jobs.router)   # /jobs 엔드포인트
app.include_router(chat.router)   # /ws 엔드포인트

@app.get("/")
def root():
    return {"message": "구직 커뮤니티 API 작동 중!"}