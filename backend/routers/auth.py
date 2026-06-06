# auth.py
# 사용자 인증 관련 API 라우터
# 회원가입, 로그인, 닉네임/비밀번호 변경, 회원탈퇴 기능 제공
# JWT(JSON Web Token)를 사용하여 로그인 상태 유지

from fastapi import APIRouter, Depends, HTTPException, Header
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from pydantic import BaseModel
from jose import jwt, JWTError
from datetime import datetime, timedelta
import bcrypt

from backend.models.database import get_db
from backend.models.user import User

# /auth 접두사로 모든 엔드포인트 등록
# 예: /auth/register, /auth/login 등
router = APIRouter(prefix="/auth", tags=["auth"])

# ── JWT 설정 ──────────────────────────────────────────
# JWT: 로그인 후 발급되는 토큰으로 이후 요청에서 사용자 인증에 사용
# 실제 서비스에서는 SECRET_KEY를 환경변수로 관리해야 함
SECRET_KEY = "job_community_secret_key_2026"

# 토큰 서명 알고리즘 (HMAC-SHA256)
ALGORITHM = "HS256"

# 토큰 만료 시간 (7일)
# 7일 후에는 자동으로 로그아웃되어 재로그인 필요
ACCESS_TOKEN_EXPIRE_DAYS = 7

# ── 요청 데이터 스키마 ────────────────────────────────
# Pydantic 모델: API 요청 데이터의 타입과 유효성 검사에 사용

class RegisterRequest(BaseModel):
    # 로그인용 아이디 (4글자 이상, 중복 불가)
    username: str
    # 커뮤니티에서 표시될 닉네임 (2글자 이상, 중복 불가)
    nickname: str
    # 비밀번호 (평문으로 전달, 서버에서 bcrypt로 암호화)
    password: str

class LoginRequest(BaseModel):
    # 로그인용 아이디
    username: str
    # 비밀번호 (평문)
    password: str

class NicknameRequest(BaseModel):
    # 변경할 새 닉네임
    nickname: str

class PasswordRequest(BaseModel):
    # 현재 비밀번호 (본인 확인용)
    current_password: str
    # 변경할 새 비밀번호 (6글자 이상)
    new_password: str

# ── 유틸리티 함수 ─────────────────────────────────────

def hash_password(password: str) -> str:
    """
    비밀번호를 bcrypt 알고리즘으로 암호화
    - bcrypt: 단방향 해시 함수로 복호화 불가
    - salt: 같은 비밀번호도 매번 다른 해시값 생성 (레인보우 테이블 공격 방어)
    """
    salt = bcrypt.gensalt()
    return bcrypt.hashpw(password.encode(), salt).decode()

def verify_password(plain: str, hashed: str) -> bool:
    """
    입력한 비밀번호와 저장된 해시 비교
    - plain: 사용자가 입력한 평문 비밀번호
    - hashed: DB에 저장된 암호화된 비밀번호
    - 반환값: 일치하면 True, 불일치하면 False
    """
    return bcrypt.checkpw(plain.encode(), hashed.encode())

def create_token(user_id: int, username: str, nickname: str) -> str:
    """
    JWT 토큰 생성
    - 토큰에 사용자 ID, 아이디, 닉네임, 만료 시간 포함
    - 클라이언트는 이 토큰을 저장하고 인증이 필요한 요청 시 헤더에 포함
    """
    data = {
        "sub": str(user_id),      # 사용자 ID (subject)
        "username": username,      # 로그인 아이디
        "nickname": nickname,      # 닉네임
        "exp": datetime.utcnow() + timedelta(days=ACCESS_TOKEN_EXPIRE_DAYS),  # 만료 시간
    }
    return jwt.encode(data, SECRET_KEY, algorithm=ALGORITHM)

async def get_current_user(authorization: str = Header(...)):
    """
    JWT 토큰에서 현재 로그인한 사용자 ID 추출
    - Authorization 헤더에서 "Bearer 토큰" 형식으로 토큰을 받음
    - 토큰이 유효하지 않거나 만료된 경우 401 에러 반환
    - FastAPI의 Depends()와 함께 사용하여 인증이 필요한 API에 적용
    """
    try:
        # "Bearer 토큰" 형식에서 토큰 부분만 추출
        token = authorization.split(" ")[1]
        # 토큰 디코딩 및 검증
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id = int(payload.get("sub"))
        return user_id
    except (JWTError, IndexError, ValueError):
        raise HTTPException(status_code=401, detail="인증이 필요합니다")

# ── 회원가입 / 로그인 ─────────────────────────────────

@router.post("/register")
async def register(req: RegisterRequest, db: AsyncSession = Depends(get_db)):
    """
    회원가입 API
    1. 아이디 중복 확인
    2. 닉네임 중복 확인
    3. 비밀번호 암호화 후 DB 저장
    4. JWT 토큰 발급 후 반환 (가입 즉시 로그인 상태)
    """
    # 아이디 중복 확인
    result = await db.execute(select(User).where(User.username == req.username))
    if result.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="이미 사용 중인 아이디입니다")

    # 닉네임 중복 확인
    result = await db.execute(select(User).where(User.nickname == req.nickname))
    if result.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="이미 사용 중인 닉네임입니다")

    # 비밀번호 암호화 후 새 유저 생성
    new_user = User(
        username=req.username,
        nickname=req.nickname,
        hashed_password=hash_password(req.password),
    )
    db.add(new_user)
    await db.commit()
    await db.refresh(new_user)

    # 회원가입 성공 시 JWT 토큰 발급 (자동 로그인)
    token = create_token(new_user.id, new_user.username, new_user.nickname)
    return {
        "token": token,
        "nickname": new_user.nickname,
        "message": "회원가입 성공",
    }

@router.post("/login")
async def login(req: LoginRequest, db: AsyncSession = Depends(get_db)):
    """
    로그인 API
    1. 아이디로 유저 조회
    2. 비밀번호 검증
    3. JWT 토큰 발급 후 반환
    """
    # 아이디로 유저 조회
    result = await db.execute(select(User).where(User.username == req.username))
    user = result.scalar_one_or_none()

    # 유저가 없거나 비밀번호가 틀린 경우 동일한 에러 반환
    # (보안상 아이디/비밀번호 중 어느 것이 틀렸는지 구분하지 않음)
    if not user or not verify_password(req.password, user.hashed_password):
        raise HTTPException(status_code=401, detail="아이디 또는 비밀번호가 틀렸습니다")

    # 로그인 성공 시 JWT 토큰 발급
    token = create_token(user.id, user.username, user.nickname)
    return {
        "token": token,
        "nickname": user.nickname,
        "message": "로그인 성공",
    }

# ── 계정 설정 ─────────────────────────────────────────

@router.patch("/nickname")
async def change_nickname(
    req: NicknameRequest,
    user_id: int = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    닉네임 변경 API
    - JWT 토큰으로 본인 확인 후 닉네임 변경
    - 다른 사용자가 사용 중인 닉네임으로 변경 불가
    """
    # 닉네임 중복 확인 (자기 자신 제외)
    result = await db.execute(select(User).where(User.nickname == req.nickname))
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

@router.patch("/password")
async def change_password(
    req: PasswordRequest,
    user_id: int = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    비밀번호 변경 API
    - 현재 비밀번호 확인 후 새 비밀번호로 변경
    - 새 비밀번호는 bcrypt로 암호화하여 저장
    """
    # 유저 조회
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="유저를 찾을 수 없습니다")

    # 현재 비밀번호 검증
    if not verify_password(req.current_password, user.hashed_password):
        raise HTTPException(status_code=400, detail="현재 비밀번호가 틀렸습니다")

    # 새 비밀번호 암호화 후 저장
    user.hashed_password = hash_password(req.new_password)
    await db.commit()
    return {"message": "비밀번호가 변경됐습니다"}

@router.delete("/delete")
async def delete_account(
    user_id: int = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    회원 탈퇴 API
    - JWT 토큰으로 본인 확인 후 계정 삭제
    - 삭제된 계정은 복구 불가
    """
    # 유저 조회
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="유저를 찾을 수 없습니다")

    # 계정 삭제
    await db.delete(user)
    await db.commit()
    return {"message": "회원 탈퇴가 완료됐습니다"}