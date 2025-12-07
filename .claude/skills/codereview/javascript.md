# JavaScript ベストプラクティス

## 変数と宣言

### const / let を使用する
```javascript
// Good
const MAX_COUNT = 100;
let currentCount = 0;

// Bad - var は避ける
var count = 0;
```

### 意味のある変数名を使用する
```javascript
// Good
const userAuthenticationStatus = true;
const maxRetryAttempts = 3;

// Bad
const x = true;
const n = 3;
```

## 関数

### 単一責任の原則に従う
```javascript
// Good - 1つの関数は1つのことを行う
function validateEmail(email) {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
}

function sendEmail(email, content) {
  // メール送信のロジック
}

// Bad - 複数の責任を持つ関数
function validateAndSendEmail(email, content) {
  // バリデーションと送信を同時に行う
}
```

### デフォルトパラメータを活用する
```javascript
// Good
function createUser(name, role = 'user', isActive = true) {
  return { name, role, isActive };
}

// Bad
function createUser(name, role, isActive) {
  role = role || 'user';
  isActive = isActive !== undefined ? isActive : true;
  return { name, role, isActive };
}
```

### 早期リターンでネストを減らす
```javascript
// Good
function processUser(user) {
  if (!user) return null;
  if (!user.isActive) return null;

  return user.data;
}

// Bad
function processUser(user) {
  if (user) {
    if (user.isActive) {
      return user.data;
    }
  }
  return null;
}
```

## 配列とオブジェクト

### スプレッド構文を使用する
```javascript
// Good
const newArray = [...oldArray, newItem];
const newObject = { ...oldObject, newProperty: value };

// Bad
const newArray = oldArray.concat([newItem]);
const newObject = Object.assign({}, oldObject, { newProperty: value });
```

### 分割代入を活用する
```javascript
// Good
const { name, email, role } = user;
const [first, second, ...rest] = items;

// Bad
const name = user.name;
const email = user.email;
const role = user.role;
```

### 配列メソッドを適切に使用する
```javascript
// Good - 適切なメソッドを選択
const activeUsers = users.filter(user => user.isActive);
const userNames = users.map(user => user.name);
const hasAdmin = users.some(user => user.role === 'admin');
const totalAge = users.reduce((sum, user) => sum + user.age, 0);

// Bad - 常に forEach を使う
const activeUsers = [];
users.forEach(user => {
  if (user.isActive) activeUsers.push(user);
});
```

## 非同期処理

### async/await を優先する
```javascript
// Good
async function fetchUserData(userId) {
  try {
    const response = await fetch(`/api/users/${userId}`);
    const data = await response.json();
    return data;
  } catch (error) {
    console.error('Failed to fetch user:', error);
    throw error;
  }
}

// Bad - Promise チェーン（複雑な場合）
function fetchUserData(userId) {
  return fetch(`/api/users/${userId}`)
    .then(response => response.json())
    .then(data => data)
    .catch(error => {
      console.error('Failed to fetch user:', error);
      throw error;
    });
}
```

### Promise.all で並列処理
```javascript
// Good - 並列で実行
async function fetchAllData() {
  const [users, posts, comments] = await Promise.all([
    fetchUsers(),
    fetchPosts(),
    fetchComments()
  ]);
  return { users, posts, comments };
}

// Bad - 直列で実行（不必要に遅い）
async function fetchAllData() {
  const users = await fetchUsers();
  const posts = await fetchPosts();
  const comments = await fetchComments();
  return { users, posts, comments };
}
```

## エラーハンドリング

### 具体的なエラーメッセージを提供する
```javascript
// Good
function divide(a, b) {
  if (b === 0) {
    throw new Error(`Division by zero: cannot divide ${a} by 0`);
  }
  return a / b;
}

// Bad
function divide(a, b) {
  if (b === 0) {
    throw new Error('Error');
  }
  return a / b;
}
```

### カスタムエラークラスを作成する
```javascript
// Good
class ValidationError extends Error {
  constructor(field, message) {
    super(message);
    this.name = 'ValidationError';
    this.field = field;
  }
}

throw new ValidationError('email', 'Invalid email format');
```

## セキュリティ

### ユーザー入力を常にサニタイズする
```javascript
// Good
function sanitizeInput(input) {
  return input
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#x27;');
}

// innerHTML の代わりに textContent を使用
element.textContent = userInput;

// Bad
element.innerHTML = userInput; // XSS 脆弱性
```

### eval() を避ける
```javascript
// Good
const result = JSON.parse(jsonString);

// Bad - セキュリティリスク
const result = eval('(' + jsonString + ')');
```

### 機密情報をハードコードしない
```javascript
// Good
const apiKey = process.env.API_KEY;

// Bad
const apiKey = 'sk-1234567890abcdef';
```

## パフォーマンス

### 不要な再計算を避ける
```javascript
// Good - ループ外で長さを取得
const length = items.length;
for (let i = 0; i < length; i++) {
  // 処理
}

// メモ化を活用
const memoizedValue = useMemo(() => expensiveCalculation(input), [input]);
```

### DOM 操作を最小限にする
```javascript
// Good - DocumentFragment を使用
const fragment = document.createDocumentFragment();
items.forEach(item => {
  const li = document.createElement('li');
  li.textContent = item;
  fragment.appendChild(li);
});
list.appendChild(fragment);

// Bad - 毎回 DOM を更新
items.forEach(item => {
  const li = document.createElement('li');
  li.textContent = item;
  list.appendChild(li); // 毎回リフローが発生
});
```

### 適切なデータ構造を選択する
```javascript
// Good - 頻繁な検索には Set/Map を使用
const userIds = new Set([1, 2, 3, 4, 5]);
if (userIds.has(targetId)) {
  // O(1) の検索
}

// Bad - 配列での検索は O(n)
const userIds = [1, 2, 3, 4, 5];
if (userIds.includes(targetId)) {
  // O(n) の検索
}
```

## モジュール

### 名前付きエクスポートを優先する
```javascript
// Good - 名前付きエクスポート
export function validateEmail(email) { /* ... */ }
export function validatePassword(password) { /* ... */ }

// 使用側
import { validateEmail, validatePassword } from './validators';

// Bad - デフォルトエクスポート（大きなオブジェクト）
export default {
  validateEmail,
  validatePassword,
  // ...多数の関数
};
```

### 循環依存を避ける
```javascript
// Good - 依存関係を整理
// utils.js
export function helper() { /* ... */ }

// service.js
import { helper } from './utils';

// Bad - 循環依存
// a.js imports from b.js
// b.js imports from a.js
```

## テスト

### テストしやすいコードを書く
```javascript
// Good - 依存性注入
function createUserService(database, emailService) {
  return {
    async createUser(userData) {
      const user = await database.save(userData);
      await emailService.sendWelcome(user.email);
      return user;
    }
  };
}

// Bad - 密結合
function createUser(userData) {
  const user = db.save(userData); // グローバルな db に依存
  sendEmail(user.email); // グローバルな関数に依存
  return user;
}
```

### 純粋関数を多用する
```javascript
// Good - 純粋関数（テストが容易）
function calculateTotal(items, taxRate) {
  const subtotal = items.reduce((sum, item) => sum + item.price, 0);
  return subtotal * (1 + taxRate);
}

// Bad - 副作用がある（テストが困難）
let taxRate = 0.1;
function calculateTotal(items) {
  const subtotal = items.reduce((sum, item) => sum + item.price, 0);
  return subtotal * (1 + taxRate); // 外部状態に依存
}
```
