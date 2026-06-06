# post.py
# 게시글 및 댓글 테이블 정의 모듈
# 커뮤니티 게시판의 게시글과 댓글 데이터를 저장

from sqlalchemy import Integer, String, Column, DateTime, ForeignKey, Text, Boolean
from sqlalchemy.sql import func
from .database import Base

class Post(Base):
    """
    게시글 테이블
    - 커뮤니티 게시판의 게시글 저장
    - 카테고리별로 분류 (면접 꿀팁, 자기소개서, 취업 후기 등)
    - 신고 30회 이상 시 자동 숨김 처리
    """
    __tablename__ = "posts"

    # 고유 식별자 (자동 증가)
    id = Column(Integer, primary_key=True, index=True)

    # 게시판 카테고리 (면접 꿀팁, 자기소개서, 취업 후기, 프로그램 후기, 취업 고민)
    # 인덱스 설정으로 카테고리별 조회 성능 향상
    category = Column(String, nullable=False, index=True)

    # 게시글 제목
    title = Column(String, nullable=False)

    # 게시글 본문 내용 (Text: 긴 문자열 저장 가능)
    content = Column(Text, nullable=False)

    # 작성자 닉네임 (users 테이블의 nickname 참조)
    author = Column(String, nullable=False)

    # 조회수 (게시글 상세 조회 시 자동 증가)
    views = Column(Integer, default=0)

    # 숨김 처리 여부
    # - 신고 30회 이상: 해당 게시글 숨김
    # - 신고 50회 이상: 작성자의 모든 게시글 숨김
    is_hidden = Column(Boolean, default=False)

    # 작성 일시 (서버 시간 기준 자동 설정)
    created_at = Column(DateTime, server_default=func.now())


class Comment(Base):
    """
    댓글 테이블
    - 게시글에 달린 댓글 저장
    - WebSocket을 통해 실시간으로 작성/표시
    - 신고 30회 이상 시 자동 숨김 처리
    """
    __tablename__ = "comments"

    # 고유 식별자 (자동 증가)
    id = Column(Integer, primary_key=True, index=True)

    # 어떤 게시글의 댓글인지 (posts.id 외래키 참조)
    # 인덱스 설정으로 게시글별 댓글 조회 성능 향상
    post_id = Column(Integer, ForeignKey("posts.id"), nullable=False, index=True)

    # 댓글 내용
    content = Column(Text, nullable=False)

    # 작성자 닉네임
    author = Column(String, nullable=False)

    # 숨김 처리 여부 (신고 30회 이상 시 자동 숨김)
    is_hidden = Column(Boolean, default=False)

    # 작성 일시 (서버 시간 기준 자동 설정)
    created_at = Column(DateTime, server_default=func.now())