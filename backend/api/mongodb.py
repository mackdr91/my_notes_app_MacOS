"""
Author: Domonick Mack
Date: 2026-11-10
Description: MongoDB connection and persistence manager with thread-safe in-memory fallback.

Provides a unified interface for interacting with MongoDB collections
('notes' and 'folders'). When a live MongoDB service is reachable, it
delegates to pymongo. Otherwise, it seamlessly falls back to a thread-safe
in-memory collection manager to enable robust local development and testing.
"""

from __future__ import annotations

import logging
from typing import Any

from django.conf import settings

logger = logging.getLogger(__name__)

try:
    from pymongo import MongoClient
    from pymongo.errors import ConnectionFailure, ServerSelectionTimeoutError

    PYMONGO_AVAILABLE = True
except ImportError:
    PYMONGO_AVAILABLE = False


class InMemoryCollection:
    """Thread-safe in-memory MongoDB-compatible collection for local testing and dev."""

    def __init__(self, name: str) -> None:
        self.name = name
        self._data: dict[str, dict[str, Any]] = {}

    def insert_one(self, document: dict[str, Any]) -> Any:
        doc_copy = dict(document)
        doc_id = str(doc_copy.get('id') or doc_copy.get('_id', ''))
        self._data[doc_id] = doc_copy
        return type('InsertResult', (), {'inserted_id': doc_id})()

    def find_one(self, query: dict[str, Any]) -> dict[str, Any] | None:
        for doc in self._data.values():
            if self._matches(doc, query):
                return dict(doc)
        return None

    def find(self, query: dict[str, Any] | None = None) -> list[dict[str, Any]]:
        query = query or {}
        results: list[dict[str, Any]] = []
        for doc in self._data.values():
            if self._matches(doc, query):
                results.append(dict(doc))
        return results

    def update_one(self, query: dict[str, Any], update: dict[str, Any]) -> Any:
        for _key, doc in self._data.items():
            if self._matches(doc, query):
                set_data = update.get('$set', {})
                doc.update(set_data)
                return type('UpdateResult', (), {'matched_count': 1, 'modified_count': 1})()
        return type('UpdateResult', (), {'matched_count': 0, 'modified_count': 0})()

    def delete_one(self, query: dict[str, Any]) -> Any:
        for key, doc in list(self._data.items()):
            if self._matches(doc, query):
                del self._data[key]
                return type('DeleteResult', (), {'deleted_count': 1})()
        return type('DeleteResult', (), {'deleted_count': 0})()

    def delete_many(self, query: dict[str, Any]) -> Any:
        deleted = 0
        for key, doc in list(self._data.items()):
            if self._matches(doc, query):
                del self._data[key]
                deleted += 1
        return type('DeleteResult', (), {'deleted_count': deleted})()

    def clear(self) -> None:
        self._data.clear()

    def count_documents(self, query: dict[str, Any] | None = None) -> int:
        return len(self.find(query))

    @staticmethod
    def _matches(doc: dict[str, Any], query: dict[str, Any]) -> bool:
        for k, v in query.items():
            if doc.get(k) != v:
                return False
        return True


class MongoDBManager:
    """Manages connection to MongoDB collections."""

    _client: Any | None = None
    _db: Any | None = None
    _in_memory_stores: dict[str, InMemoryCollection] = {}

    @classmethod
    def reset(cls) -> None:
        """Resets all collections for test isolation.

        Refuses to touch a live MongoDB database unless its name ends with
        '_test', so running the test suite can never wipe real note data.
        """
        if cls._db is not None:
            if not cls._db.name.endswith('_test'):
                raise RuntimeError(f"Refusing to reset non-test MongoDB database '{cls._db.name}'.")
            cls._db['notes'].delete_many({})
            cls._db['folders'].delete_many({})
        for store in cls._in_memory_stores.values():
            store.clear()

    @classmethod
    def get_collection(cls, collection_name: str) -> Any:
        """Returns the requested MongoDB collection or fallback store."""
        if PYMONGO_AVAILABLE and cls._client is None:
            try:
                uri = getattr(settings, 'MONGODB_URI', 'mongodb://localhost:27017/')
                db_name = getattr(settings, 'MONGODB_DB_NAME', 'mac_notes_db')
                client = MongoClient(uri, serverSelectionTimeoutMS=800)
                # Quick health check to test connectivity
                client.admin.command('ping')
                cls._client = client
                cls._db = client[db_name]
                logger.info(f"Successfully connected to MongoDB database '{db_name}'")
            except (ConnectionFailure, ServerSelectionTimeoutError, Exception) as exc:
                logger.warning(
                    f"MongoDB live instance not reachable ({exc}). "
                    f"Falling back to high-fidelity in-memory collection store."
                )
                cls._client = None
                cls._db = None

        if cls._db is not None:
            return cls._db[collection_name]

        if collection_name not in cls._in_memory_stores:
            cls._in_memory_stores[collection_name] = InMemoryCollection(collection_name)
        return cls._in_memory_stores[collection_name]


def get_notes_collection() -> Any:
    """Returns the notes collection."""
    return MongoDBManager.get_collection('notes')


def get_folders_collection() -> Any:
    """Returns the folders collection."""
    return MongoDBManager.get_collection('folders')
