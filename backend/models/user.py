from sqlalchemy import Integer, String, Column, DateTime
from sqlalchemy.sql import func
from .database import Base

# 유저 테이블 정의
class User(Base):
    __tablename__ = "users"

    # 고유 ID (자동 증가)
    id = Column(Integer, primary_key=True, index=True)
    # 로그인용 아이디 (중복 불가)
    username = Column(String, unique=True, nullable=False, index=True)
    # 닉네임 (채팅방에서 표시될 이름)
    nickname = Column(String, nullable=False)
    # 암호화된 비밀번호
    hashed_password = Column(String, nullable=False)
    # 계정 생성일
    created_at = Column(DateTime, server_default=func.now())