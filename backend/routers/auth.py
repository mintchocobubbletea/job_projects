from fastapi import APIRouter, Depends, HTTPException, Header
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from pydantic import BaseModel
from jose import jwt, JWTError
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

# ── 요청 데이터 스키마 ────────────────────────────────

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

class NicknameRequest(BaseModel):
    # 변경할 새 닉네임
    nickname: str

class PasswordRequest(BaseModel):
    # 현재 비밀번호 (검증용)
    current_password: str
    # 변경할 새 비밀번호
    new_password: str

# ── 유틸리티 함수 ─────────────────────────────────────

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

# 토큰에서 유저 ID 추출 (인증이 필요한 API에서 사용)
async def get_current_user(authorization: str = Header(...)):
    try:
        # "Bearer 토큰" 형식에서 토큰만 추출
        token = authorization.split(" ")[1]
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id = int(payload.get("sub"))
        return user_id
    except (JWTError, IndexError, ValueError):
        raise HTTPException(status_code=401, detail="인증이 필요합니다")

# ── 회원가입 / 로그인 ─────────────────────────────────

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

# ── 계정 설정 ─────────────────────────────────────────

# 닉네임 변경
@router.patch("/nickname")
async def change_nickname(
    req: NicknameRequest,
    user_id: int = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    # 닉네임 중복 확인
    result = await db.execute(
        select(User).where(User.nickname == req.nickname)
    )
    existing = result.scalar_one_or_none()
    if existing and existing.id != user_id:
        raise HTTPException(status_code=400, detail="이미 사용 중인 닉네임입니다")

    # 유저 조회 후 닉네임 업데이트
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="유저를 찾을 수 없습니다")

    user.nickname = req.nickname
    await db.commit()
    return {"message": "닉네임이 변경됐습니다"}

# 비밀번호 변경
@router.patch("/password")
async def change_password(
    req: PasswordRequest,
    user_id: int = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    # 유저 조회
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="유저를 찾을 수 없습니다")

    # 현재 비밀번호 확인
    if not verify_password(req.current_password, user.hashed_password):
        raise HTTPException(status_code=400, detail="현재 비밀번호가 틀렸습니다")

    # 새 비밀번호로 업데이트
    user.hashed_password = hash_password(req.new_password)
    await db.commit()
    return {"message": "비밀번호가 변경됐습니다"}

# 회원 탈퇴
@router.delete("/delete")
async def delete_account(
    user_id: int = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    # 유저 조회
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="유저를 찾을 수 없습니다")

    # 유저 삭제
    await db.delete(user)
    await db.commit()
    return {"message": "회원 탈퇴가 완료됐습니다"}