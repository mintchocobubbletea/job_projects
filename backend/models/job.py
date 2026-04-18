from sqlalchemy import Integer, String, Column
from .database import Base

# 공고 테이블 정의
class Job(Base):
    __tablename__ = "jobs"  # DB 테이블 이름

    id = Column(Integer, primary_key=True, index=True)  # 고유 ID
    title = Column(String, nullable=False)               # 공고 제목
    company = Column(String, nullable=False)             # 회사명
    location = Column(String, nullable=False)            # 근무지
    description = Column(String, nullable=True)          # 공고 상세 내용