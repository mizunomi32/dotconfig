# TypeScript ベストプラクティス

## 型設定

### 厳格モードを有効にする
```json
// tsconfig.json
{
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "exactOptionalPropertyTypes": true
  }
}
```

### any を避ける
```typescript
// Good - 具体的な型を使用
function processData(data: UserData): ProcessedResult {
  return { id: data.id, name: data.name.toUpperCase() };
}

// unknown を使用して安全に処理
function parseJSON(json: string): unknown {
  return JSON.parse(json);
}

// Bad - any は型安全性を失う
function processData(data: any): any {
  return { id: data.id, name: data.name.toUpperCase() };
}
```

## 型定義

### interface と type の使い分け
```typescript
// Good - オブジェクト型には interface
interface User {
  id: number;
  name: string;
  email: string;
}

// 拡張が必要な場合
interface AdminUser extends User {
  permissions: string[];
}

// Good - Union型やマッピング型には type
type Status = 'pending' | 'active' | 'inactive';
type UserKeys = keyof User;
type ReadonlyUser = Readonly<User>;

// Bad - 使い分けが不明確
type User = {
  id: number;
  name: string;
};
```

### ユーティリティ型を活用する
```typescript
// Partial - すべてのプロパティをオプショナルに
function updateUser(id: number, updates: Partial<User>): User {
  // 処理
}

// Pick - 必要なプロパティのみ抽出
type UserPreview = Pick<User, 'id' | 'name'>;

// Omit - 特定のプロパティを除外
type CreateUserInput = Omit<User, 'id' | 'createdAt'>;

// Required - すべてのプロパティを必須に
type CompleteUser = Required<User>;

// Record - キーと値の型を定義
type UserRoles = Record<string, 'admin' | 'user' | 'guest'>;
```

### Branded Types でプリミティブを区別する
```typescript
// Good - 型で意味を明確にする
type UserId = number & { readonly brand: unique symbol };
type PostId = number & { readonly brand: unique symbol };

function createUserId(id: number): UserId {
  return id as UserId;
}

function getUser(id: UserId): User {
  // UserId のみ受け付ける
}

const userId = createUserId(1);
const postId = 2 as PostId;

getUser(userId); // OK
getUser(postId); // Error: PostId は UserId に代入できない
```

## 型ガード

### 型述語を使用する
```typescript
// Good - is キーワードで型を絞り込む
function isUser(value: unknown): value is User {
  return (
    typeof value === 'object' &&
    value !== null &&
    'id' in value &&
    'name' in value
  );
}

function processValue(value: unknown) {
  if (isUser(value)) {
    // ここでは value は User 型
    console.log(value.name);
  }
}
```

### in 演算子と discriminated union
```typescript
// Good - Discriminated Union
type Result<T> =
  | { success: true; data: T }
  | { success: false; error: Error };

function handleResult<T>(result: Result<T>) {
  if (result.success) {
    // result.data にアクセス可能
    console.log(result.data);
  } else {
    // result.error にアクセス可能
    console.error(result.error.message);
  }
}

// API レスポンスの型
type ApiResponse =
  | { status: 'loading' }
  | { status: 'success'; data: User[] }
  | { status: 'error'; message: string };
```

### satisfies 演算子を使用する（TypeScript 4.9+）
```typescript
// Good - 型推論を維持しつつ型チェック
const config = {
  apiUrl: 'https://api.example.com',
  timeout: 5000,
  retries: 3,
} satisfies Record<string, string | number>;

// config.apiUrl は string 型として推論される
config.apiUrl.toUpperCase(); // OK

// Bad - as const では readonly になる
const config = {
  apiUrl: 'https://api.example.com',
} as const;
// config.apiUrl は 'https://api.example.com' リテラル型
```

## ジェネリクス

### 適切な制約を設定する
```typescript
// Good - 制約付きジェネリクス
function getProperty<T, K extends keyof T>(obj: T, key: K): T[K] {
  return obj[key];
}

// 複数の制約
function merge<T extends object, U extends object>(obj1: T, obj2: U): T & U {
  return { ...obj1, ...obj2 };
}

// Bad - 制約なし（any と同じ問題）
function getProperty<T>(obj: T, key: string): any {
  return obj[key];
}
```

### デフォルト型パラメータを使用する
```typescript
// Good
interface ApiResponse<T = unknown> {
  data: T;
  status: number;
  timestamp: Date;
}

// 型引数なしで使用可能
const response: ApiResponse = { data: null, status: 200, timestamp: new Date() };

// 型引数を指定
const userResponse: ApiResponse<User> = { data: user, status: 200, timestamp: new Date() };
```

## 関数

### オーバーロードを適切に使用する
```typescript
// Good - オーバーロードシグネチャ
function createElement(tag: 'div'): HTMLDivElement;
function createElement(tag: 'span'): HTMLSpanElement;
function createElement(tag: 'input'): HTMLInputElement;
function createElement(tag: string): HTMLElement {
  return document.createElement(tag);
}

const div = createElement('div'); // HTMLDivElement
const input = createElement('input'); // HTMLInputElement
```

### コールバックの型を明確にする
```typescript
// Good - 明確なコールバック型
type EventHandler<T> = (event: T) => void;
type AsyncHandler<T, R> = (input: T) => Promise<R>;

function addEventListener<K extends keyof HTMLElementEventMap>(
  element: HTMLElement,
  event: K,
  handler: EventHandler<HTMLElementEventMap[K]>
): void {
  element.addEventListener(event, handler);
}
```

## クラス

### アクセス修飾子を活用する
```typescript
// Good
class UserService {
  private readonly repository: UserRepository;
  protected logger: Logger;

  constructor(repository: UserRepository, logger: Logger) {
    this.repository = repository;
    this.logger = logger;
  }

  public async findUser(id: number): Promise<User | null> {
    this.logger.debug(`Finding user: ${id}`);
    return this.repository.findById(id);
  }

  private validateUser(user: User): boolean {
    // 内部メソッド
  }
}
```

### コンストラクタでのプロパティ宣言
```typescript
// Good - 簡潔なプロパティ宣言
class ApiClient {
  constructor(
    private readonly baseUrl: string,
    private readonly timeout: number = 5000,
  ) {}

  async fetch<T>(endpoint: string): Promise<T> {
    // this.baseUrl と this.timeout が使用可能
  }
}

// Bad - 冗長
class ApiClient {
  private readonly baseUrl: string;
  private readonly timeout: number;

  constructor(baseUrl: string, timeout: number = 5000) {
    this.baseUrl = baseUrl;
    this.timeout = timeout;
  }
}
```

## 非同期処理

### Promise の型を明確にする
```typescript
// Good - 戻り値の型を明示
async function fetchUser(id: number): Promise<User> {
  const response = await fetch(`/api/users/${id}`);
  if (!response.ok) {
    throw new Error(`Failed to fetch user: ${response.status}`);
  }
  return response.json() as Promise<User>;
}

// Promise.all の型
async function fetchAllData(): Promise<[User[], Post[], Comment[]]> {
  return Promise.all([fetchUsers(), fetchPosts(), fetchComments()]);
}
```

### 型安全なエラーハンドリング
```typescript
// Good - Result 型パターン
type Result<T, E = Error> =
  | { ok: true; value: T }
  | { ok: false; error: E };

async function safeParseJSON<T>(json: string): Promise<Result<T>> {
  try {
    const data = JSON.parse(json) as T;
    return { ok: true, value: data };
  } catch (e) {
    return { ok: false, error: e instanceof Error ? e : new Error(String(e)) };
  }
}

const result = await safeParseJSON<User>(jsonString);
if (result.ok) {
  console.log(result.value.name);
} else {
  console.error(result.error.message);
}
```

## モジュール

### 明示的な型のエクスポート
```typescript
// Good - 型と値を区別してエクスポート
export interface User {
  id: number;
  name: string;
}

export type UserStatus = 'active' | 'inactive';

export function createUser(name: string): User {
  return { id: Date.now(), name };
}

// インポート側（type-only import）
import type { User, UserStatus } from './user';
import { createUser } from './user';
```

### バレルファイルで整理する
```typescript
// src/models/index.ts
export type { User, UserStatus } from './user';
export type { Post, PostStatus } from './post';
export type { Comment } from './comment';

// 使用側
import type { User, Post, Comment } from '@/models';
```

## Null/Undefined 処理

### Non-null アサーションは避ける
```typescript
// Good - 適切なnullチェック
function getLength(value: string | null): number {
  if (value === null) {
    return 0;
  }
  return value.length;
}

// Optional chaining と Nullish coalescing
const length = value?.length ?? 0;

// Bad - Non-null アサーション（!）は危険
function getLength(value: string | null): number {
  return value!.length; // 実行時エラーの可能性
}
```

### strictNullChecks を活用する
```typescript
// Good - 明示的な undefined チェック
function findUser(id: number): User | undefined {
  return users.find(u => u.id === id);
}

const user = findUser(1);
if (user) {
  console.log(user.name); // user は User 型
}

// noUncheckedIndexedAccess が有効な場合
const item = array[0]; // item は T | undefined
if (item !== undefined) {
  // item は T 型
}
```

## const アサーション

### リテラル型を保持する
```typescript
// Good - as const でリテラル型を保持
const ROUTES = {
  HOME: '/',
  USERS: '/users',
  SETTINGS: '/settings',
} as const;

type Route = typeof ROUTES[keyof typeof ROUTES];
// type Route = '/' | '/users' | '/settings'

// 配列にも適用可能
const STATUSES = ['pending', 'active', 'inactive'] as const;
type Status = typeof STATUSES[number];
// type Status = 'pending' | 'active' | 'inactive'
```

## テスト

### 型安全なモック
```typescript
// Good - Partial を使用したモック
function createMockUser(overrides: Partial<User> = {}): User {
  return {
    id: 1,
    name: 'Test User',
    email: 'test@example.com',
    ...overrides,
  };
}

// jest.Mocked を使用
import type { UserService } from './UserService';

const mockUserService: jest.Mocked<UserService> = {
  findUser: jest.fn(),
  createUser: jest.fn(),
  deleteUser: jest.fn(),
};
```

### 型のテスト
```typescript
// 型が正しいことをコンパイル時に検証
import { expectType } from 'tsd';

expectType<string>(getString());
expectType<User>(getUser());

// エラーになるべき型
// @ts-expect-error - number は string に代入できない
const str: string = 123;
```
