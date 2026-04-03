"""Round-trip tests for token encryption."""
from cryptography.fernet import Fernet


def test_encrypt_decrypt_roundtrip(monkeypatch):
    from app.core import config
    from app.core import token_vault

    key = Fernet.generate_key().decode()
    monkeypatch.setattr(config, "TOKEN_ENCRYPTION_KEY", key)

    payload = {"access_token": "at", "refresh_token": "rt", "expires_at_epoch": 123.0}
    ct = token_vault.encrypt_json(payload)
    assert ct != ""
    out = token_vault.decrypt_json(ct)
    assert out["access_token"] == "at"
    assert out["refresh_token"] == "rt"
