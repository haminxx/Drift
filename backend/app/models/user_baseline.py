"""Optional: per-user baseline storage (e.g. Firestore). Used when Firebase is configured."""
# When Firebase/Firestore is added: define helpers to read/write
# users/{uid}/baselines and sessions. Backend can stay stateless with in-memory
# baseline per request or per session_id until then.
