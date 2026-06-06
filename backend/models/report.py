# report.py
# 신고 테이블 정의 모듈
# 게시글/댓글 신고 내역을 저장하고 자동 제재 처리에 활용

from sqlalchemy import Integer, String, Column, DateTime
from sqlalchemy.sql import func
from .database import Base

class Report(Base):
    """
    신고 테이블
    - 게시글/댓글 신고 내역 저장
    - 신고 누적 횟수에 따른 자동 제재:
        30회 이상: 해당 게시글/댓글 자동 숨김
        50회 이상: 신고 대상자의 모든 게시글 숨김
    - 중복 신고 방지 (같은 사용자가 같은 게시물 중복 신고 불가)
    """
    __tablename__ = "reports"

    # 고유 식별자 (자동 증가)
    id = Column(Integer, primary_key=True, index=True)

    # 신고 유형
    # - "post": 게시글 신고
    # - "comment": 댓글 신고
    report_type = Column(String, nullable=False)

    # 신고 대상 ID (게시글 ID 또는 댓글 ID)
    target_id = Column(Integer, nullable=False)

    # 신고 사유 (욕설/비방, 스팸/광고, 개인정보 유출, 불쾌한 언행, 허위 정보, 기타)
    reason = Column(String, nullable=False)

    # 신고자 닉네임
    reporter = Column(String, nullable=False)

    # 신고 대상자 닉네임
    reported_user = Column(String, nullable=False)

    # 신고 일시 (서버 시간 기준 자동 설정)
    created_at = Column(DateTime, server_default=func.now())