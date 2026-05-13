from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from pydantic import BaseModel
from jose import jwt
from datetime import datetime, timedelta
import bcrypt

from backend.models.database import get_db
from backend.models.user import User

router = APIRouter(prefix="/auth", tags=["auth"])

# JWT 설정
# 실제 서비스에서는 환경변수로 관리해야 함
SECRET_KEY = "job_community_secret_key_2026"
ALGORITHM = "HS256"
# 토큰 만료 시간 (7일)
ACCESS_TOKEN_EXPIRE_DAYS = 7

# 요청 데이터 스키마
class RegisterRequest(BaseModel):
    # 로그인용 아이디
    username: str
    # 채팅/커뮤니티에서 표시될 닉네임
    nickname: str
    # 비밀번호 (평문, 서버에서 암호화)
    password: str

class LoginRequest(BaseModel):
    username: str
    password: str

# 비밀번호 암호화 함수
def hash_password(password: str) -> str:
    # bcrypt로 비밀번호 해싱
    salt = bcrypt.gensalt()
    return bcrypt.hashpw(password.encode(), salt).decode()

# 비밀번호 검증 함수
def verify_password(plain: str, hashed: str) -> bool:
    # 입력한 비밀번호와 저장된 해시 비교
    return bcrypt.checkpw(plain.encode(), hashed.encode())

# JWT 토큰 생성 함수
def create_token(user_id: int, username: str, nickname: str) -> str:
    # 토큰에 담을 데이터
    data = {
        "sub": str(user_id),
        "username": username,
        "nickname": nickname,
        # 만료 시간
        "exp": datetime.utcnow() + timedelta(days=ACCESS_TOKEN_EXPIRE_DAYS),
    }
    return jwt.encode(data, SECRET_KEY, algorithm=ALGORITHM)

# 회원가입 엔드포인트
@router.post("/register")
async def register(req: RegisterRequest, db: AsyncSession = Depends(get_db)):
    # 아이디 중복 확인
    result = await db.execute(select(User).where(User.username == req.username))
    existing = result.scalar_one_or_none()
    if existing:
        raise HTTPException(status_code=400, detail="이미 사용 중인 아이디입니다")

    # 닉네임 중복 확인
    result = await db.execute(select(User).where(User.nickname == req.nickname))
    existing = result.scalar_one_or_none()
    if existing:
        raise HTTPException(status_code=400, detail="이미 사용 중인 닉네임입니다")

    # 비밀번호 암호화 후 저장
    new_user = User(
        username=req.username,
        nickname=req.nickname,
        hashed_password=hash_password(req.password),
    )
    db.add(new_user)
    await db.commit()
    await db.refresh(new_user)

    # 회원가입 성공 시 토큰 발급
    token = create_token(new_user.id, new_user.username, new_user.nickname)
    return {
        "token": token,
        "nickname": new_user.nickname,
        "message": "회원가입 성공",
    }

# 로그인 엔드포인트
@router.post("/login")
async def login(req: LoginRequest, db: AsyncSession = Depends(get_db)):
    # 아이디로 유저 조회
    result = await db.execute(select(User).where(User.username == req.username))
    user = result.scalar_one_or_none()

    # 유저 없거나 비밀번호 틀리면 에러
    if not user or not verify_password(req.password, user.hashed_password):
        raise HTTPException(status_code=401, detail="아이디 또는 비밀번호가 틀렸습니다")

    # 로그인 성공 시 토큰 발급
    token = create_token(user.id, user.username, user.nickname)
    return {
        "token": token,
        "nickname": user.nickname,
        "message": "로그인 성공",
    }