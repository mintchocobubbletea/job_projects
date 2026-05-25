from sqlalchemy import Integer, String, Column, DateTime, ForeignKey
from sqlalchemy.sql import func
from .database import Base

# 신고 테이블
class Report(Base):
    __tablename__ = "reports"

    # 고유 ID
    id = Column(Integer, primary_key=True, index=True)
    # 신고 유형 (post: 게시글, comment: 댓글)
    report_type = Column(String, nullable=False)
    # 신고 대상 ID (게시글 ID 또는 댓글 ID)
    target_id = Column(Integer, nullable=False)
    # 신고 사유
    reason = Column(String, nullable=False)
    # 신고자 닉네임
    reporter = Column(String, nullable=False)
    # 신고 대상자 닉네임
    reported_user = Column(String, nullable=False)
    # 신고 일시
    created_at = Column(DateTime, server_default=func.now())