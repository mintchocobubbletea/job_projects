from fastapi import FastAPI
from backend.models.database import engine, Base
from backend.routers import jobs, chat, auth, posts, reports 

app = FastAPI()

@app.on_event("startup")
async def startup():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

app.include_router(jobs.router)
app.include_router(chat.router)
app.include_router(auth.router)
app.include_router(posts.router)
app.include_router(reports.router) 

@app.get("/")
def root():
    return {"message": "구직 커뮤니티 API 작동 중!"}