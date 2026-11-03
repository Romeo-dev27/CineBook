"""
auth.py — Routes REST pour l'inscription, la connexion et le profil utilisateur
"""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from database import get_db
from models import User
from schemas import UserRegister, UserLogin, UserOut, TokenOut
from auth import hash_password, verify_password, create_access_token, get_current_user

router = APIRouter(prefix="/api/auth", tags=["Authentification & Comptes"])


@router.post(
    "/register",
    response_model=TokenOut,
    status_code=status.HTTP_201_CREATED,
    summary="Créer un nouveau compte utilisateur",
    description="Inscrit un utilisateur avec un email et mot de passe, puis retourne immédiatement son JWT d'authentification."
)
def register(user_data: UserRegister, db: Session = Depends(get_db)):
    email = user_data.email.lower().strip()

    # Vérifier l'unicité de l'email
    existing = db.query(User).filter(User.email == email).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Un compte avec cette adresse email existe déjà."
        )

    # Création du compte
    hashed = hash_password(user_data.password)
    user = User(email=email, hashed_password=hashed)
    db.add(user)
    db.commit()
    db.refresh(user)

    # Génération du token JWT
    token = create_access_token({"sub": str(user.id), "email": user.email})

    return TokenOut(
        access_token=token,
        token_type="bearer",
        user=UserOut.model_validate(user)
    )


@router.post(
    "/login",
    response_model=TokenOut,
    summary="Connexion utilisateur",
    description="Authentifie un utilisateur et renvoie son JWT d'accès."
)
def login(credentials: UserLogin, db: Session = Depends(get_db)):
    email = credentials.email.lower().strip()
    user = db.query(User).filter(User.email == email).first()

    if not user or not verify_password(credentials.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Identifiants incorrects (email ou mot de passe invalide).",
            headers={"WWW-Authenticate": "Bearer"},
        )

    token = create_access_token({"sub": str(user.id), "email": user.email})

    return TokenOut(
        access_token=token,
        token_type="bearer",
        user=UserOut.model_validate(user)
    )


@router.get(
    "/me",
    response_model=UserOut,
    summary="Profil de l'utilisateur connecté",
    description="Retourne les informations du compte actuellement authentifié via son Bearer token."
)
def get_me(current_user: User = Depends(get_current_user)):
    return UserOut.model_validate(current_user)
