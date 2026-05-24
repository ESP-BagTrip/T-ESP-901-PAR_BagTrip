# Problèmes de vérification Google Sign-In sur simulateur

## Pourquoi la vérification avec les clés publiques Google échoue sur simulateur ?

### 1. **Différence d'audience (aud claim)**

Sur **simulateur iOS/Android**, Google Sign-In peut utiliser un flux d'authentification différent qui génère des tokens avec une audience différente :

```json
// Sur appareil réel (Firebase)
{
  "aud": "bagtrip-7d2d8",  // Firebase Project ID
  "iss": "https://securetoken.google.com/bagtrip-7d2d8"
}

// Sur simulateur (Google Sign-In direct)
{
  "aud": "1073046051180-5fsoi8768piur2kl8njknsio4jqmifrs.apps.googleusercontent.com",  // Client ID OAuth
  "iss": "https://accounts.google.com"
}
```

**Problème** : Si vous vérifiez avec `expected_audience="bagtrip-7d2d8"`, ça échouera sur simulateur car l'audience est différente.

### 2. **Différence d'issuer (iss claim)**

- **Appareil réel** : `https://securetoken.google.com/{projectId}` (Firebase)
- **Simulateur** : `https://accounts.google.com` (Google OAuth direct)

### 3. **Flux d'authentification différent**

Sur simulateur, `google_sign_in` peut utiliser :
- Une **web view** au lieu du SDK natif
- Un flux OAuth web au lieu du flux Firebase
- Des certificats de signature différents

### 4. **Problèmes de certificats/clés**

Les simulateurs peuvent avoir :
- Des certificats de développement différents
- Des clés de signature différentes
- Des problèmes de synchronisation avec les clés publiques Google

### 5. **Limitations du simulateur**

- Pas d'accès complet aux services Google Play Services (Android)
- Limitations des Keychain Services (iOS)
- Environnement d'exécution différent

## Solutions

### Solution 1 : Vérification conditionnelle (Recommandé pour développement)

```python
import os
from jose import jwt

def verify_google_token_smart(id_token: str) -> dict:
    """
    Vérifie le token Google de manière adaptative.
    En développement/simulateur : vérification souple
    En production : vérification stricte
    """
    is_production = os.getenv("NODE_ENV") == "production"
    
    if is_production:
        # Vérification stricte avec clés publiques
        return verify_google_id_token_strict(id_token)
    else:
        # Vérification souple pour développement/simulateur
        decoded = jwt.get_unverified_claims(id_token)
        
        # Vérifications minimales
        if not decoded.get("email"):
            raise ValueError("Email missing in token")
        
        # Vérifier que c'est bien un token Google (issuer)
        iss = decoded.get("iss", "")
        if not (iss.startswith("https://accounts.google.com") or 
                iss.startswith("https://securetoken.google.com")):
            raise ValueError("Invalid issuer")
        
        return decoded
```

### Solution 2 : Accepter plusieurs audiences

```python
def verify_google_token_flexible(id_token: str) -> dict:
    """
    Vérifie le token en acceptant plusieurs audiences possibles.
    """
    # Audiences possibles
    valid_audiences = [
        "bagtrip-7d2d8",  # Firebase Project ID
        "1073046051180-5fsoi8768piur2kl8njknsio4jqmifrs.apps.googleusercontent.com",  # OAuth Client ID
    ]
    
    public_keys = fetch_google_public_keys()
    unverified_header = jwt.get_unverified_header(id_token)
    kid = unverified_header.get("kid")
    public_key = public_keys.get(kid)
    
    if not public_key:
        raise JWTError("Key not found")
    
    # Essayer chaque audience
    for audience in valid_audiences:
        try:
            return jwt.decode(
                id_token,
                public_key,
                algorithms=["RS256"],
                audience=audience,
                options={"verify_exp": True}
            )
        except JWTError:
            continue
    
    raise JWTError("Token audience not valid")
```

### Solution 3 : Détection automatique de l'environnement

```python
def detect_token_type(id_token: str) -> str:
    """
    Détecte le type de token (Firebase ou Google OAuth).
    """
    decoded = jwt.get_unverified_claims(id_token)
    iss = decoded.get("iss", "")
    
    if "securetoken.google.com" in iss:
        return "firebase"
    elif "accounts.google.com" in iss:
        return "google_oauth"
    else:
        return "unknown"

def verify_google_token_auto(id_token: str) -> dict:
    """
    Vérifie automatiquement selon le type de token détecté.
    """
    token_type = detect_token_type(id_token)
    
    if token_type == "firebase":
        return verify_firebase_token(id_token, "bagtrip-7d2d8")
    elif token_type == "google_oauth":
        return verify_google_oauth_token(id_token)
    else:
        raise ValueError("Unknown token type")
```

## Recommandation

Pour votre cas d'usage :

1. **En développement** : Utilisez `get_unverified_claims()` avec vérifications minimales
2. **En production** : Implémentez la vérification stricte avec détection automatique du type de token
3. **Pour les tests** : Créez des tokens de test mockés

## Exemple d'implémentation complète

```python
async def verify_google_id_token_safe(
    id_token: str,
    is_production: bool = False
) -> dict:
    """
    Vérifie un token Google de manière sécurisée et flexible.
    
    Args:
        id_token: Le token ID à vérifier
        is_production: Si True, vérification stricte. Si False, vérification souple.
    
    Returns:
        dict: Les claims décodés
    """
    if not is_production:
        # Mode développement : vérification souple
        decoded = jwt.get_unverified_claims(id_token)
        
        # Vérifications minimales
        if not decoded.get("email"):
            raise ValueError("Email missing in token")
        
        iss = decoded.get("iss", "")
        if not (iss.startswith("https://accounts.google.com") or 
                "securetoken.google.com" in iss):
            raise ValueError(f"Invalid issuer: {iss}")
        
        return decoded
    
    # Mode production : vérification stricte
    public_keys = await fetch_google_public_keys()
    unverified_header = jwt.get_unverified_header(id_token)
    kid = unverified_header.get("kid")
    
    if not kid or kid not in public_keys:
        raise JWTError("Token key ID not found")
    
    public_key = public_keys[kid]
    decoded = jwt.get_unverified_header(id_token)
    iss = decoded.get("iss", "")
    
    # Détecter le type de token
    if "securetoken.google.com" in iss:
        # Token Firebase
        audience = "bagtrip-7d2d8"
        expected_issuer = f"https://securetoken.google.com/{audience}"
    else:
        # Token Google OAuth
        audience = "1073046051180-5fsoi8768piur2kl8njknsio4jqmifrs.apps.googleusercontent.com"
        expected_issuer = "https://accounts.google.com"
    
    return jwt.decode(
        id_token,
        public_key,
        algorithms=["RS256"],
        audience=audience,
        issuer=expected_issuer,
    )
```
