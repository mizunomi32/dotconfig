# PHP ベストプラクティス

## 基本設定

### 厳格な型宣言を有効にする
```php
<?php
// Good - ファイルの先頭で宣言
declare(strict_types=1);

function calculateTotal(float $price, int $quantity): float
{
    return $price * $quantity;
}

// Bad - 型宣言なし
function calculateTotal($price, $quantity)
{
    return $price * $quantity;
}
```

### エラーレポートを適切に設定する
```php
// 開発環境
error_reporting(E_ALL);
ini_set('display_errors', '1');

// 本番環境
error_reporting(E_ALL);
ini_set('display_errors', '0');
ini_set('log_errors', '1');
```

## 命名規則

### PSR-12 に従う
```php
// Good
class UserAccountService
{
    private const MAX_LOGIN_ATTEMPTS = 5;

    private int $loginAttempts;

    public function validateCredentials(string $email, string $password): bool
    {
        // 処理
    }

    private function hashPassword(string $password): string
    {
        // 処理
    }
}

// Bad - 一貫性のない命名
class user_account_service
{
    private $LoginAttempts;

    public function Validate_Credentials($Email, $password)
    {
        // 処理
    }
}
```

## 型システム

### 型宣言を最大限活用する
```php
// Good - PHP 8+ の機能を活用
class User
{
    public function __construct(
        private readonly int $id,
        private readonly string $name,
        private readonly ?string $email = null,
    ) {}

    public function getId(): int
    {
        return $this->id;
    }
}

// Union 型と Nullable 型
function processInput(string|int $input): ?array
{
    // 処理
}

// Bad - 型宣言なし
class User
{
    private $id;
    private $name;

    public function __construct($id, $name)
    {
        $this->id = $id;
        $this->name = $name;
    }
}
```

### Enum を使用する（PHP 8.1+）
```php
// Good
enum UserStatus: string
{
    case Active = 'active';
    case Inactive = 'inactive';
    case Suspended = 'suspended';

    public function label(): string
    {
        return match($this) {
            self::Active => 'アクティブ',
            self::Inactive => '非アクティブ',
            self::Suspended => '停止中',
        };
    }
}

// Bad - マジックストリング
class User
{
    public string $status = 'active'; // 何が有効な値かわからない
}
```

## セキュリティ

### SQL インジェクション対策
```php
// Good - プリペアドステートメント
$stmt = $pdo->prepare('SELECT * FROM users WHERE email = :email AND status = :status');
$stmt->execute([
    'email' => $email,
    'status' => $status,
]);
$user = $stmt->fetch();

// Bad - SQL インジェクション脆弱性
$query = "SELECT * FROM users WHERE email = '$email'";
$result = $pdo->query($query);
```

### XSS 対策
```php
// Good - 出力時にエスケープ
<p><?= htmlspecialchars($userInput, ENT_QUOTES, 'UTF-8') ?></p>

// ヘルパー関数を作成
function e(string $value): string
{
    return htmlspecialchars($value, ENT_QUOTES, 'UTF-8');
}

// Bad - エスケープなし
<p><?= $userInput ?></p>
```

### CSRF 対策
```php
// Good - トークンベースの検証
// トークン生成
$_SESSION['csrf_token'] = bin2hex(random_bytes(32));

// フォームに埋め込み
<input type="hidden" name="csrf_token" value="<?= e($_SESSION['csrf_token']) ?>">

// 検証
if (!hash_equals($_SESSION['csrf_token'], $_POST['csrf_token'] ?? '')) {
    throw new SecurityException('CSRF token mismatch');
}
```

### パスワードのハッシュ化
```php
// Good - password_hash を使用
$hashedPassword = password_hash($password, PASSWORD_DEFAULT);

// 検証
if (password_verify($inputPassword, $hashedPassword)) {
    // 認証成功
}

// Bad - MD5/SHA1 を使用
$hashedPassword = md5($password); // 脆弱
$hashedPassword = sha1($password); // 脆弱
```

## エラーハンドリング

### 例外を適切に使用する
```php
// Good - カスタム例外
class UserNotFoundException extends RuntimeException
{
    public function __construct(int $userId)
    {
        parent::__construct("User not found: {$userId}");
    }
}

class UserRepository
{
    public function findOrFail(int $id): User
    {
        $user = $this->find($id);

        if ($user === null) {
            throw new UserNotFoundException($id);
        }

        return $user;
    }
}

// 呼び出し側
try {
    $user = $repository->findOrFail($userId);
} catch (UserNotFoundException $e) {
    // ユーザーが見つからない場合の処理
}
```

### Null セーフ演算子を活用する（PHP 8+）
```php
// Good
$country = $user?->getAddress()?->getCountry()?->getName();

// Bad - 冗長なnullチェック
$country = null;
if ($user !== null) {
    $address = $user->getAddress();
    if ($address !== null) {
        $countryObj = $address->getCountry();
        if ($countryObj !== null) {
            $country = $countryObj->getName();
        }
    }
}
```

## データベース

### トランザクションを適切に使用する
```php
// Good
try {
    $pdo->beginTransaction();

    $stmt = $pdo->prepare('UPDATE accounts SET balance = balance - ? WHERE id = ?');
    $stmt->execute([$amount, $fromAccount]);

    $stmt = $pdo->prepare('UPDATE accounts SET balance = balance + ? WHERE id = ?');
    $stmt->execute([$amount, $toAccount]);

    $pdo->commit();
} catch (Exception $e) {
    $pdo->rollBack();
    throw $e;
}
```

### N+1 問題を避ける
```php
// Good - JOIN またはバッチ取得
$stmt = $pdo->prepare('
    SELECT users.*, posts.title as post_title
    FROM users
    LEFT JOIN posts ON users.id = posts.user_id
    WHERE users.status = ?
');
$stmt->execute(['active']);

// Bad - N+1 問題
$users = $pdo->query('SELECT * FROM users')->fetchAll();
foreach ($users as $user) {
    $posts = $pdo->query("SELECT * FROM posts WHERE user_id = {$user['id']}")->fetchAll();
}
```

## クラス設計

### 依存性注入を使用する
```php
// Good - コンストラクタインジェクション
class UserService
{
    public function __construct(
        private readonly UserRepository $repository,
        private readonly EmailService $emailService,
        private readonly LoggerInterface $logger,
    ) {}

    public function register(array $data): User
    {
        $user = $this->repository->create($data);
        $this->emailService->sendWelcome($user);
        $this->logger->info('User registered', ['id' => $user->getId()]);

        return $user;
    }
}

// Bad - 密結合
class UserService
{
    public function register(array $data): User
    {
        $repository = new UserRepository(new PDO(...)); // 密結合
        $user = $repository->create($data);

        mail($user->email, 'Welcome', '...'); // テスト困難

        return $user;
    }
}
```

### インターフェースに依存する
```php
// Good
interface PaymentGatewayInterface
{
    public function charge(int $amount, string $currency): PaymentResult;
}

class StripeGateway implements PaymentGatewayInterface
{
    public function charge(int $amount, string $currency): PaymentResult
    {
        // Stripe 固有の実装
    }
}

class PaymentService
{
    public function __construct(
        private readonly PaymentGatewayInterface $gateway,
    ) {}
}

// Bad - 具象クラスに依存
class PaymentService
{
    public function __construct(
        private readonly StripeGateway $gateway, // 具象クラス
    ) {}
}
```

## 配列とコレクション

### 配列関数を活用する
```php
// Good
$activeUsers = array_filter($users, fn($user) => $user->isActive());
$userNames = array_map(fn($user) => $user->getName(), $users);
$totalAge = array_reduce($users, fn($sum, $user) => $sum + $user->getAge(), 0);

// Bad - 常に foreach を使用
$activeUsers = [];
foreach ($users as $user) {
    if ($user->isActive()) {
        $activeUsers[] = $user;
    }
}
```

### スプレッド演算子を活用する
```php
// Good
$merged = [...$array1, ...$array2];

function sum(int ...$numbers): int
{
    return array_sum($numbers);
}

$result = sum(...$values);

// Bad
$merged = array_merge($array1, $array2);
$result = call_user_func_array('sum', $values);
```

## パフォーマンス

### Opcode キャッシュを活用する
```php
// php.ini で OPcache を有効化
// opcache.enable=1
// opcache.memory_consumption=128
// opcache.interned_strings_buffer=8
// opcache.max_accelerated_files=10000
```

### 遅延読み込みを使用する
```php
// Good - 必要な時にのみ読み込む
class UserService
{
    private ?ExpensiveService $expensiveService = null;

    private function getExpensiveService(): ExpensiveService
    {
        return $this->expensiveService ??= new ExpensiveService();
    }
}

// ジェネレータを使用してメモリを節約
function readLargeFile(string $path): Generator
{
    $handle = fopen($path, 'r');
    while (($line = fgets($handle)) !== false) {
        yield $line;
    }
    fclose($handle);
}

foreach (readLargeFile('large.csv') as $line) {
    // 1行ずつ処理（メモリ効率が良い）
}
```

## Composer とオートロード

### PSR-4 オートロードを使用する
```json
// composer.json
{
    "autoload": {
        "psr-4": {
            "App\\": "src/"
        }
    },
    "autoload-dev": {
        "psr-4": {
            "Tests\\": "tests/"
        }
    }
}
```

### require/include を避ける
```php
// Good - オートロードに任せる
use App\Services\UserService;

$service = new UserService();

// Bad - 手動で読み込み
require_once 'src/Services/UserService.php';
```

## テスト

### テストしやすいコードを書く
```php
// Good - モック可能な設計
class OrderService
{
    public function __construct(
        private readonly PaymentGatewayInterface $payment,
        private readonly InventoryServiceInterface $inventory,
    ) {}

    public function process(Order $order): bool
    {
        if (!$this->inventory->check($order->getItems())) {
            return false;
        }

        return $this->payment->charge($order->getTotal());
    }
}

// テスト
public function testProcessOrder(): void
{
    $payment = $this->createMock(PaymentGatewayInterface::class);
    $payment->method('charge')->willReturn(true);

    $inventory = $this->createMock(InventoryServiceInterface::class);
    $inventory->method('check')->willReturn(true);

    $service = new OrderService($payment, $inventory);

    $this->assertTrue($service->process($order));
}
```

### データプロバイダを使用する
```php
#[DataProvider('emailProvider')]
public function testValidateEmail(string $email, bool $expected): void
{
    $this->assertSame($expected, $this->validator->validateEmail($email));
}

public static function emailProvider(): array
{
    return [
        'valid email' => ['test@example.com', true],
        'invalid - no @' => ['testexample.com', false],
        'invalid - no domain' => ['test@', false],
        'valid with subdomain' => ['test@sub.example.com', true],
    ];
}
```
