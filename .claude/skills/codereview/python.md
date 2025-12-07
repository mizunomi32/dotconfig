# Python ベストプラクティス

## コーディングスタイル

### PEP 8 に従う
```python
# Good - 4スペースインデント
class UserService:
    def __init__(self, repository):
        self.repository = repository

    def find_user(self, user_id):
        return self.repository.find(user_id)


# Good - 適切な空行
import os
import sys

from myapp.models import User
from myapp.services import EmailService


class MyClass:
    pass
```

### 命名規則
```python
# Good
class UserAccount:              # クラス: PascalCase
    MAX_LOGIN_ATTEMPTS = 5      # 定数: SCREAMING_SNAKE_CASE

    def __init__(self, email):
        self.email = email      # インスタンス変数: snake_case
        self._cache = {}        # プライベート: _prefix

    def send_notification(self):  # メソッド: snake_case
        pass

    def _internal_method(self):   # プライベートメソッド: _prefix
        pass


# モジュールレベル
user_count = 0                  # 変数: snake_case


# Bad - 命名規則の不統一
class userAccount:
    def SendNotification(self):
        pass
```

## 型ヒント

### 型アノテーションを使用する
```python
from typing import Optional, List, Dict, Tuple, Union
from collections.abc import Callable, Iterator

# Good - 型ヒント付き関数
def greet(name: str, times: int = 1) -> str:
    return f"Hello, {name}! " * times


def find_user(user_id: int) -> Optional[User]:
    return users.get(user_id)


def process_items(items: List[str]) -> Dict[str, int]:
    return {item: len(item) for item in items}


# Python 3.10+ - Union の簡略化
def parse_value(value: str | int | None) -> str:
    if value is None:
        return ""
    return str(value)


# Bad - 型ヒントなし
def greet(name, times=1):
    return f"Hello, {name}! " * times
```

### TypedDict と dataclass を活用する
```python
from typing import TypedDict
from dataclasses import dataclass, field


# TypedDict - 辞書の型定義
class UserDict(TypedDict):
    id: int
    name: str
    email: str
    is_active: bool


# dataclass - データクラス
@dataclass
class User:
    id: int
    name: str
    email: str
    is_active: bool = True
    tags: list[str] = field(default_factory=list)


# frozen=True で不変オブジェクト
@dataclass(frozen=True)
class Point:
    x: float
    y: float

    def distance_from_origin(self) -> float:
        return (self.x ** 2 + self.y ** 2) ** 0.5
```

### Protocol で構造的部分型を定義する
```python
from typing import Protocol


# Good - インターフェースとして Protocol を使用
class Serializable(Protocol):
    def to_dict(self) -> dict: ...
    def to_json(self) -> str: ...


class Repository(Protocol[T]):
    def find(self, id: int) -> Optional[T]: ...
    def save(self, entity: T) -> T: ...
    def delete(self, id: int) -> bool: ...


# Protocol を実装（明示的な継承不要）
class UserRepository:
    def find(self, id: int) -> Optional[User]:
        pass

    def save(self, entity: User) -> User:
        pass

    def delete(self, id: int) -> bool:
        pass
```

## 関数設計

### 単一責任の原則に従う
```python
# Good - 単一責任
def validate_email(email: str) -> bool:
    pattern = r'^[^\s@]+@[^\s@]+\.[^\s@]+$'
    return bool(re.match(pattern, email))


def send_email(to: str, subject: str, body: str) -> None:
    # メール送信ロジック
    pass


def notify_user(user: User, message: str) -> None:
    if validate_email(user.email):
        send_email(user.email, "Notification", message)


# Bad - 複数の責任
def validate_and_send_email(user, subject, body):
    # バリデーションと送信を同時に行う
    pass
```

### キーワード引数を活用する
```python
# Good - キーワード専用引数
def create_user(
    *,
    name: str,
    email: str,
    role: str = "user",
    is_active: bool = True,
) -> User:
    return User(name=name, email=email, role=role, is_active=is_active)


# 呼び出し側で明確
user = create_user(name="John", email="john@example.com")
admin = create_user(name="Admin", email="admin@example.com", role="admin")


# Bad - 位置引数が多すぎる
def create_user(name, email, role, is_active, created_at, updated_at):
    pass
```

### 早期リターンでネストを減らす
```python
# Good - ガード節
def process_order(order: Optional[Order]) -> dict:
    if order is None:
        return {"error": "Order not found"}

    if not order.items:
        return {"error": "Empty order"}

    if not order.is_valid():
        return {"error": "Invalid order"}

    # メインロジック
    return calculate_total(order)


# Bad - 深いネスト
def process_order(order):
    if order is not None:
        if order.items:
            if order.is_valid():
                return calculate_total(order)
            else:
                return {"error": "Invalid order"}
        else:
            return {"error": "Empty order"}
    return {"error": "Order not found"}
```

## コレクション操作

### リスト内包表記を活用する
```python
# Good - リスト内包表記
squares = [x ** 2 for x in range(10)]
active_users = [u for u in users if u.is_active]
user_emails = [u.email.lower() for u in users]

# 辞書内包表記
user_by_id = {u.id: u for u in users}

# 集合内包表記
unique_domains = {u.email.split("@")[1] for u in users}

# Bad - 冗長なループ
squares = []
for x in range(10):
    squares.append(x ** 2)
```

### ジェネレータで遅延評価
```python
# Good - ジェネレータ式（メモリ効率）
total = sum(u.balance for u in users)
any_active = any(u.is_active for u in users)

# ジェネレータ関数
def read_large_file(path: str) -> Iterator[str]:
    with open(path) as f:
        for line in f:
            yield line.strip()


# Bad - 大量データを一度にリストに読み込む
lines = [line.strip() for line in open(path)]  # メモリを大量消費
total = sum([u.balance for u in users])  # 不要なリスト作成
```

### 組み込み関数を活用する
```python
# Good - 組み込み関数
numbers = [3, 1, 4, 1, 5, 9]
sorted_nums = sorted(numbers)
max_value = max(numbers)
min_value = min(numbers)
total = sum(numbers)

# any / all
has_negative = any(n < 0 for n in numbers)
all_positive = all(n > 0 for n in numbers)

# zip / enumerate
for i, item in enumerate(items):
    print(f"{i}: {item}")

for name, age in zip(names, ages):
    print(f"{name} is {age}")

# map / filter（リスト内包表記の方が読みやすい場合も）
doubled = list(map(lambda x: x * 2, numbers))
```

## クラス設計

### プロパティを使用する
```python
class Circle:
    def __init__(self, radius: float):
        self._radius = radius

    @property
    def radius(self) -> float:
        return self._radius

    @radius.setter
    def radius(self, value: float) -> None:
        if value < 0:
            raise ValueError("Radius cannot be negative")
        self._radius = value

    @property
    def area(self) -> float:
        return 3.14159 * self._radius ** 2


# 使用
circle = Circle(5)
print(circle.area)  # 78.53975
circle.radius = 10
```

### __slots__ でメモリを節約する
```python
# Good - 多数のインスタンスを作成する場合
class Point:
    __slots__ = ('x', 'y')

    def __init__(self, x: float, y: float):
        self.x = x
        self.y = y


# Bad - デフォルトでは __dict__ を持つ
class Point:
    def __init__(self, x: float, y: float):
        self.x = x
        self.y = y
```

### コンテキストマネージャを実装する
```python
from contextlib import contextmanager


# クラスベース
class DatabaseConnection:
    def __init__(self, connection_string: str):
        self.connection_string = connection_string
        self.connection = None

    def __enter__(self):
        self.connection = create_connection(self.connection_string)
        return self.connection

    def __exit__(self, exc_type, exc_val, exc_tb):
        if self.connection:
            self.connection.close()
        return False  # 例外を再送出


# デコレータベース
@contextmanager
def timer(label: str):
    start = time.time()
    try:
        yield
    finally:
        elapsed = time.time() - start
        print(f"{label}: {elapsed:.3f}s")


# 使用
with timer("Processing"):
    process_data()
```

## エラーハンドリング

### 具体的な例外をキャッチする
```python
# Good - 具体的な例外
def fetch_user_data(user_id: int) -> dict:
    try:
        response = requests.get(f"/api/users/{user_id}")
        response.raise_for_status()
        return response.json()
    except requests.HTTPError as e:
        logger.error(f"HTTP error: {e}")
        raise UserFetchError(f"Failed to fetch user: {user_id}") from e
    except requests.JSONDecodeError as e:
        logger.error(f"JSON decode error: {e}")
        raise UserFetchError("Invalid response format") from e


# Bad - 広すぎる例外キャッチ
def fetch_user_data(user_id):
    try:
        # 処理
        pass
    except Exception:  # 全ての例外をキャッチ
        return None  # エラーを握りつぶす
```

### カスタム例外を定義する
```python
# Good - ドメイン固有の例外
class AppError(Exception):
    """アプリケーション基底例外"""
    pass


class ValidationError(AppError):
    """バリデーションエラー"""
    def __init__(self, field: str, message: str):
        self.field = field
        self.message = message
        super().__init__(f"{field}: {message}")


class NotFoundError(AppError):
    """リソースが見つからない"""
    def __init__(self, resource: str, id: int):
        self.resource = resource
        self.id = id
        super().__init__(f"{resource} not found: {id}")


# 使用
raise ValidationError("email", "Invalid email format")
raise NotFoundError("User", 123)
```

### EAFP スタイルを優先する
```python
# Good - EAFP (Easier to Ask Forgiveness than Permission)
def get_user_email(user_dict: dict) -> str:
    try:
        return user_dict["email"]
    except KeyError:
        return ""


# 許容される LBYL (Look Before You Leap)
def get_user_email(user_dict: dict) -> str:
    return user_dict.get("email", "")


# Bad - 冗長な LBYL
def get_user_email(user_dict: dict) -> str:
    if "email" in user_dict:
        return user_dict["email"]
    return ""
```

## セキュリティ

### 入力をサニタイズする
```python
import html
from pathlib import Path


# XSS 対策
def sanitize_html(user_input: str) -> str:
    return html.escape(user_input)


# パストラバーサル対策
def safe_path(base_dir: Path, user_path: str) -> Path:
    full_path = (base_dir / user_path).resolve()
    if not str(full_path).startswith(str(base_dir.resolve())):
        raise ValueError("Invalid path")
    return full_path


# SQL インジェクション対策 - パラメータ化クエリ
cursor.execute(
    "SELECT * FROM users WHERE email = %s AND status = %s",
    (email, status)
)
```

### 機密情報を保護する
```python
import os
from functools import lru_cache


# Good - 環境変数から取得
@lru_cache
def get_config():
    return {
        "database_url": os.environ["DATABASE_URL"],
        "api_key": os.environ["API_KEY"],
    }


# Bad - ハードコード
API_KEY = "sk-1234567890abcdef"
```

### secrets モジュールを使用する
```python
import secrets

# Good - 暗号学的に安全なランダム値
token = secrets.token_urlsafe(32)
api_key = secrets.token_hex(32)

# 安全な比較（タイミング攻撃対策）
is_valid = secrets.compare_digest(provided_token, stored_token)

# Bad - 予測可能なランダム値
import random
token = ''.join(random.choices('abcdef0123456789', k=32))
```

## パフォーマンス

### 適切なデータ構造を選択する
```python
# Good - 検索には set/dict を使用
valid_statuses = {'pending', 'active', 'inactive'}

def is_valid_status(status: str) -> bool:
    return status in valid_statuses  # O(1)


# Bad - list での検索
valid_statuses = ['pending', 'active', 'inactive']

def is_valid_status(status: str) -> bool:
    return status in valid_statuses  # O(n)
```

### functools でキャッシュする
```python
from functools import lru_cache, cache


# lru_cache - サイズ制限付きキャッシュ
@lru_cache(maxsize=128)
def fibonacci(n: int) -> int:
    if n < 2:
        return n
    return fibonacci(n - 1) + fibonacci(n - 2)


# cache - 無制限キャッシュ（Python 3.9+）
@cache
def factorial(n: int) -> int:
    if n <= 1:
        return 1
    return n * factorial(n - 1)
```

### 文字列の結合は join を使用する
```python
# Good - join で結合
parts = ["Hello", "World", "!"]
result = " ".join(parts)

# 大量の文字列を結合
lines = []
for item in items:
    lines.append(str(item))
result = "\n".join(lines)

# Bad - += で結合（毎回新しい文字列を作成）
result = ""
for item in items:
    result += str(item) + "\n"
```

## 非同期処理

### asyncio を使用する
```python
import asyncio
import aiohttp


# Good - 非同期関数
async def fetch_url(session: aiohttp.ClientSession, url: str) -> str:
    async with session.get(url) as response:
        return await response.text()


async def fetch_all(urls: list[str]) -> list[str]:
    async with aiohttp.ClientSession() as session:
        tasks = [fetch_url(session, url) for url in urls]
        return await asyncio.gather(*tasks)


# 実行
results = asyncio.run(fetch_all(urls))
```

### 非同期コンテキストマネージャ
```python
class AsyncDatabaseConnection:
    async def __aenter__(self):
        self.connection = await create_async_connection()
        return self.connection

    async def __aexit__(self, exc_type, exc_val, exc_tb):
        await self.connection.close()
        return False


# 使用
async with AsyncDatabaseConnection() as conn:
    result = await conn.execute(query)
```

## テスト

### pytest を使用する
```python
import pytest


# Good - 説明的なテスト名
def test_validate_email_returns_true_for_valid_email():
    assert validate_email("test@example.com") is True


def test_validate_email_returns_false_for_invalid_email():
    assert validate_email("invalid-email") is False


# パラメータ化テスト
@pytest.mark.parametrize("email,expected", [
    ("test@example.com", True),
    ("user@domain.org", True),
    ("invalid-email", False),
    ("@nodomain.com", False),
    ("", False),
])
def test_validate_email(email: str, expected: bool):
    assert validate_email(email) is expected
```

### フィクスチャを活用する
```python
import pytest


@pytest.fixture
def user():
    return User(id=1, name="Test User", email="test@example.com")


@pytest.fixture
def user_service(mocker):
    repository = mocker.Mock()
    return UserService(repository)


def test_find_user(user_service, user):
    user_service.repository.find.return_value = user

    result = user_service.find_user(1)

    assert result == user
    user_service.repository.find.assert_called_once_with(1)
```

### モックを適切に使用する
```python
from unittest.mock import Mock, patch, AsyncMock


# patch でモジュールをモック
@patch("myapp.services.requests.get")
def test_fetch_user_data(mock_get):
    mock_response = Mock()
    mock_response.json.return_value = {"id": 1, "name": "Test"}
    mock_get.return_value = mock_response

    result = fetch_user_data(1)

    assert result["name"] == "Test"
    mock_get.assert_called_once_with("/api/users/1")


# 非同期関数のモック
@pytest.mark.asyncio
async def test_async_fetch(mocker):
    mock_fetch = mocker.patch("myapp.services.fetch_url", new_callable=AsyncMock)
    mock_fetch.return_value = "response"

    result = await fetch_url("http://example.com")

    assert result == "response"
```

## Python 3.10+ の機能

### match 文（構造的パターンマッチング）
```python
# Good - パターンマッチング
def handle_response(response: dict) -> str:
    match response:
        case {"status": 200, "data": data}:
            return f"Success: {data}"
        case {"status": 404}:
            return "Not found"
        case {"status": 500, "error": error}:
            return f"Server error: {error}"
        case _:
            return "Unknown response"


# クラスのパターンマッチング
match point:
    case Point(x=0, y=0):
        print("Origin")
    case Point(x=0, y=y):
        print(f"On Y-axis at {y}")
    case Point(x=x, y=0):
        print(f"On X-axis at {x}")
    case Point(x=x, y=y):
        print(f"Point at ({x}, {y})")
```

### | 演算子で Union 型
```python
# Python 3.10+
def process(value: str | int | None) -> str:
    if value is None:
        return ""
    return str(value)


# dict のマージ
merged = dict1 | dict2
dict1 |= dict2  # インプレース更新
```

### TypeGuard で型を絞り込む
```python
from typing import TypeGuard


def is_string_list(val: list[object]) -> TypeGuard[list[str]]:
    return all(isinstance(x, str) for x in val)


def process_strings(items: list[object]) -> None:
    if is_string_list(items):
        # items は list[str] として扱われる
        for item in items:
            print(item.upper())
```
