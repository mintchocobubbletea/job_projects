# user.py
# 사용자 계정 테이블 정의 모듈
# 회원가입, 로그인, 계정 관리에 사용되는 User 모델

from sqlalchemy import Integer, String, Column, DateTime
from sqlalchemy.sql import func
from .database import Base

class User(Base):
    """
    사용자 계정 테이블
    - 회원가입 시 생성
    - 로그인, 닉네임/비밀번호 변경, 회원탈퇴에 사용
    """
    __tablename__ = "users"

    # 고유 식별자 (자동 증가)
    id = Column(Integer, primary_key=True, index=True)

    # 로그인용 아이디 (중복 불가, 인덱스 설정으로 빠른 조회)
    username = Column(String, unique=True, nullable=False, index=True)

    # 커뮤니티에서 표시될 닉네임 (중복 불가)
    nickname = Column(String, nullable=False)

    # bcrypt로 암호화된 비밀번호 (평문 저장 금지)
    hashed_password = Column(String, nullable=False)

    # 계정 생성 일시 (서버 시간 기준 자동 설정)
    created_at = Column(DateTime, server_default=func.now())