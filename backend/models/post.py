from sqlalchemy import Integer, String, Column, DateTime, ForeignKey, Text
from sqlalchemy.sql import func
from .database import Base

# 게시글 테이블
class Post(Base):
    __tablename__ = "posts"

    # 고유 ID
    id = Column(Integer, primary_key=True, index=True)
    # 게시판 카테고리 (면접 꿀팁, 자기소개서 등)
    category = Column(String, nullable=False, index=True)
    # 게시글 제목
    title = Column(String, nullable=False)
    # 게시글 내용
    content = Column(Text, nullable=False)
    # 작성자 닉네임
    author = Column(String, nullable=False)
    # 조회수
    views = Column(Integer, default=0)
    # 작성일
    created_at = Column(DateTime, server_default=func.now())

# 댓글 테이블
class Comment(Base):
    __tablename__ = "comments"

    # 고유 ID
    id = Column(Integer, primary_key=True, index=True)
    # 어떤 게시글의 댓글인지 (posts.id 참조)
    post_id = Column(Integer, ForeignKey("posts.id"), nullable=False, index=True)
    # 댓글 내용
    content = Column(Text, nullable=False)
    # 작성자 닉네임
    author = Column(String, nullable=False)
    # 작성일
    created_at = Column(DateTime, server_default=func.now())