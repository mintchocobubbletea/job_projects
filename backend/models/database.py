from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import DeclarativeBase, sessionmaker

# SQLite DB 파일 경로 (job_projects/backend/jobs.db 로 생성됨)
DATABASE_URL = "sqlite+aiosqlite:///./jobs.db"

# DB 엔진 생성 (비동기 방식)
engine = create_async_engine(DATABASE_URL, echo=True)

# DB 세션 팩토리 (요청마다 새 세션 생성)
AsyncSessionLocal = sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
)

# 모든 모델의 부모 클래스
class Base(DeclarativeBase):
    pass

# DB 세션을 API 엔드포인트에 제공하는 의존성 함수
async def get_db():
    async with AsyncSessionLocal() as session:
        yield session