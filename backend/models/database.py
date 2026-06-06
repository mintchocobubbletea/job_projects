# database.py
# 데이터베이스 연결 설정 및 세션 관리 모듈
# SQLAlchemy를 사용하여 비동기 방식으로 SQLite DB에 연결

from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import DeclarativeBase, sessionmaker

# SQLite DB 파일 경로 설정
# aiosqlite: 비동기 SQLite 드라이버
# jobs.db 파일이 프로젝트 루트에 생성됨
DATABASE_URL = "sqlite+aiosqlite:///./jobs.db"

# 비동기 DB 엔진 생성
# echo=True: SQL 쿼리를 콘솔에 출력 (개발/디버깅용)
engine = create_async_engine(DATABASE_URL, echo=True)

# 비동기 세션 팩토리 생성
# - class_=AsyncSession: 비동기 세션 클래스 사용
# - expire_on_commit=False: 커밋 후 객체 만료 방지
#   (커밋 후에도 객체 속성에 접근 가능하도록 설정)
AsyncSessionLocal = sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
)

# 모든 ORM 모델의 부모 클래스
# 각 모델 클래스는 Base를 상속받아 테이블 구조를 정의
class Base(DeclarativeBase):
    pass

# DB 세션 의존성 함수
# FastAPI의 Depends()와 함께 사용하여
# 각 API 요청마다 새로운 DB 세션을 생성하고
# 요청이 완료되면 자동으로 세션을 닫음
async def get_db():
    async with AsyncSessionLocal() as session:
        yield session