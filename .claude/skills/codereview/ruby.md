# Ruby ベストプラクティス

## コーディングスタイル

### インデントと空白
```ruby
# Good - 2スペースインデント
class User
  def initialize(name)
    @name = name
  end

  def greet
    "Hello, #{@name}!"
  end
end

# Good - メソッドチェーンの改行
result = users
  .select(&:active?)
  .map(&:name)
  .sort

# Bad - タブやインデント不統一
class User
    def initialize(name)
        @name = name
    end
end
```

### 命名規則
```ruby
# Good
class UserAccount          # クラス: CamelCase
  MAXIMUM_LOGIN_ATTEMPTS = 5  # 定数: SCREAMING_SNAKE_CASE

  attr_reader :email       # アクセサ: snake_case

  def initialize(email)
    @email = email         # インスタンス変数: @snake_case
  end

  def send_notification    # メソッド: snake_case
    # 処理
  end

  def active?              # 真偽値を返すメソッド: ?で終わる
    @status == :active
  end

  def activate!            # 破壊的メソッド: !で終わる
    @status = :active
  end
end

# Bad - 命名規則の不統一
class userAccount
  def SendNotification
  end
end
```

## メソッド設計

### 短く単一責任なメソッド
```ruby
# Good - 単一責任
def calculate_total(items)
  items.sum(&:price)
end

def apply_discount(total, discount_rate)
  total * (1 - discount_rate)
end

def format_price(amount)
  sprintf('$%.2f', amount)
end

# Bad - 複数の責任
def process_order(items, discount_rate)
  total = items.sum(&:price)
  discounted = total * (1 - discount_rate)
  send_email(discounted)
  update_database(items)
  sprintf('$%.2f', discounted)
end
```

### デフォルト引数とキーワード引数
```ruby
# Good - キーワード引数で明確に
def create_user(name:, email:, role: :user, active: true)
  User.new(name: name, email: email, role: role, active: active)
end

create_user(name: 'John', email: 'john@example.com')
create_user(name: 'Admin', email: 'admin@example.com', role: :admin)

# Bad - 位置引数が多すぎる
def create_user(name, email, role, active, created_at, updated_at)
  # 何番目が何かわからない
end
```

### 早期リターンでネストを減らす
```ruby
# Good - ガード節
def process_order(order)
  return nil if order.nil?
  return { error: 'Empty order' } if order.items.empty?
  return { error: 'Invalid status' } unless order.valid?

  # メインロジック
  calculate_total(order)
end

# Bad - 深いネスト
def process_order(order)
  if order
    if order.items.any?
      if order.valid?
        calculate_total(order)
      else
        { error: 'Invalid status' }
      end
    else
      { error: 'Empty order' }
    end
  end
end
```

## コレクション操作

### Enumerable メソッドを活用する
```ruby
# Good - 宣言的なスタイル
active_users = users.select(&:active?)
user_names = users.map(&:name)
admin = users.find { |u| u.role == :admin }
has_premium = users.any?(&:premium?)
total_age = users.sum(&:age)

# グループ化
users_by_role = users.group_by(&:role)

# ソート
sorted_users = users.sort_by { |u| [u.role, u.name] }

# Bad - 手続き的なスタイル
active_users = []
users.each do |user|
  if user.active?
    active_users << user
  end
end
```

### each より map/select を優先する
```ruby
# Good
squared = numbers.map { |n| n ** 2 }
evens = numbers.select(&:even?)

# Bad - each で配列を構築
squared = []
numbers.each { |n| squared << n ** 2 }
```

### Symbol#to_proc を活用する
```ruby
# Good
names = users.map(&:name)
active = users.select(&:active?)
emails = users.map(&:email).map(&:downcase)

# Bad - 冗長なブロック
names = users.map { |user| user.name }
active = users.select { |user| user.active? }
```

## クラス設計

### attr_accessor を適切に使用する
```ruby
# Good - 必要最小限のアクセサ
class User
  attr_reader :id, :email      # 読み取りのみ
  attr_accessor :name          # 読み書き

  def initialize(id:, email:, name:)
    @id = id
    @email = email
    @name = name
  end
end

# Bad - 全てを公開
class User
  attr_accessor :id, :email, :password_hash  # password_hash は公開すべきでない
end
```

### 初期化とバリデーション
```ruby
# Good - freeze で不変オブジェクトを作成
class Config
  attr_reader :api_key, :timeout

  def initialize(api_key:, timeout: 30)
    @api_key = api_key.freeze
    @timeout = timeout
    freeze
  end
end

# Good - バリデーション
class User
  def initialize(email:)
    raise ArgumentError, 'Email is required' if email.nil? || email.empty?
    raise ArgumentError, 'Invalid email format' unless email.match?(URI::MailTo::EMAIL_REGEXP)

    @email = email
  end
end
```

### Struct と Data を活用する
```ruby
# Good - 単純なデータ構造には Struct
Point = Struct.new(:x, :y, keyword_init: true) do
  def distance_from_origin
    Math.sqrt(x**2 + y**2)
  end
end

point = Point.new(x: 3, y: 4)
point.distance_from_origin  # => 5.0

# Ruby 3.2+ - 不変の Data クラス
Point = Data.define(:x, :y) do
  def distance_from_origin
    Math.sqrt(x**2 + y**2)
  end
end
```

### モジュールで機能を共有する
```ruby
# Good - 関心事の分離
module Authenticatable
  def authenticate(password)
    BCrypt::Password.new(password_hash) == password
  end

  def generate_token
    SecureRandom.urlsafe_base64(32)
  end
end

module Notifiable
  def send_notification(message)
    NotificationService.deliver(email, message)
  end
end

class User
  include Authenticatable
  include Notifiable
end
```

## エラーハンドリング

### カスタム例外を定義する
```ruby
# Good - ドメイン固有の例外
module MyApp
  class Error < StandardError; end
  class ValidationError < Error; end
  class NotFoundError < Error; end
  class AuthenticationError < Error; end
end

class UserService
  def find!(id)
    user = User.find_by(id: id)
    raise MyApp::NotFoundError, "User not found: #{id}" unless user
    user
  end
end
```

### 例外を適切にキャッチする
```ruby
# Good - 具体的な例外をキャッチ
def fetch_user_data(user_id)
  response = api_client.get("/users/#{user_id}")
  JSON.parse(response.body)
rescue Net::HTTPError => e
  logger.error("HTTP error: #{e.message}")
  raise MyApp::ApiError, "Failed to fetch user"
rescue JSON::ParserError => e
  logger.error("JSON parse error: #{e.message}")
  raise MyApp::ApiError, "Invalid response format"
end

# Bad - 全ての例外をキャッチ
def fetch_user_data(user_id)
  # 処理
rescue => e  # StandardError 全てをキャッチ
  nil  # エラーを握りつぶす
end

# Bad - Exception をキャッチ（システム例外も含む）
rescue Exception => e  # 絶対にやらない
```

### ensure でリソースを解放する
```ruby
# Good - ensure でクリーンアップ
def process_file(path)
  file = File.open(path)
  # 処理
  file.read
ensure
  file&.close
end

# Better - ブロック構文を使用
def process_file(path)
  File.open(path) do |file|
    file.read
  end
end
```

## 文字列操作

### 文字列補間を使用する
```ruby
# Good - 文字列補間
name = 'Alice'
greeting = "Hello, #{name}!"
message = "User #{user.id} created at #{Time.now}"

# Bad - 文字列連結
greeting = 'Hello, ' + name + '!'
message = 'User ' + user.id.to_s + ' created at ' + Time.now.to_s
```

### freeze で文字列リテラルを最適化する
```ruby
# Good - 定数には freeze
API_VERSION = 'v1'.freeze
DEFAULT_ENCODING = 'UTF-8'.freeze

# frozen_string_literal マジックコメント（ファイル先頭）
# frozen_string_literal: true

class MyClass
  def greeting
    'Hello, World!'  # 自動的に freeze される
  end
end
```

### ヒアドキュメントを使用する
```ruby
# Good - 複数行の文字列
sql = <<~SQL
  SELECT users.*, orders.total
  FROM users
  LEFT JOIN orders ON users.id = orders.user_id
  WHERE users.active = true
SQL

message = <<~MESSAGE.strip
  Dear #{user.name},

  Thank you for your order.
MESSAGE
```

## パフォーマンス

### メモ化で計算結果をキャッシュする
```ruby
# Good - メモ化
class User
  def full_name
    @full_name ||= "#{first_name} #{last_name}"
  end

  def orders
    @orders ||= Order.where(user_id: id).to_a
  end
end

# nil/false も考慮したメモ化
def admin?
  return @admin if defined?(@admin)
  @admin = roles.include?(:admin)
end
```

### lazy で遅延評価する
```ruby
# Good - 大量データの遅延処理
File.open('large_file.txt')
    .each_line
    .lazy
    .map(&:strip)
    .reject(&:empty?)
    .first(10)

# 無限シーケンスの処理
(1..Float::INFINITY)
  .lazy
  .select { |n| n % 3 == 0 }
  .first(5)
```

### Set で高速な検索
```ruby
require 'set'

# Good - Set で O(1) 検索
VALID_STATUSES = Set[:pending, :active, :inactive].freeze

def valid_status?(status)
  VALID_STATUSES.include?(status)
end

# Bad - Array で O(n) 検索
VALID_STATUSES = [:pending, :active, :inactive]

def valid_status?(status)
  VALID_STATUSES.include?(status)
end
```

## セキュリティ

### 入力をサニタイズする
```ruby
# Good - パラメータのホワイトリスト
def user_params
  params.require(:user).permit(:name, :email)
end

# SQLインジェクション対策
User.where('email = ?', email)  # プレースホルダを使用
User.where(email: email)        # ハッシュ構文

# Bad - 文字列展開
User.where("email = '#{email}'")  # SQLインジェクション脆弱性
```

### 機密情報を保護する
```ruby
# Good - 環境変数から取得
database_url = ENV.fetch('DATABASE_URL')
api_key = ENV.fetch('API_KEY')

# Good - credentials を使用（Rails）
Rails.application.credentials.api_key

# Bad - ハードコード
API_KEY = 'sk-1234567890abcdef'
```

### 安全な比較
```ruby
# Good - タイミング攻撃対策
require 'securerandom'

def verify_token(provided_token)
  ActiveSupport::SecurityUtils.secure_compare(
    stored_token,
    provided_token
  )
end

# Bad - 通常の比較（タイミング攻撃に脆弱）
def verify_token(provided_token)
  stored_token == provided_token
end
```

## テスト

### RSpec のベストプラクティス
```ruby
# Good - 説明的な describe/context/it
RSpec.describe User do
  describe '#full_name' do
    context 'when first_name and last_name are present' do
      it 'returns the combined name' do
        user = User.new(first_name: 'John', last_name: 'Doe')
        expect(user.full_name).to eq('John Doe')
      end
    end

    context 'when last_name is nil' do
      it 'returns only the first_name' do
        user = User.new(first_name: 'John', last_name: nil)
        expect(user.full_name).to eq('John')
      end
    end
  end
end
```

### ファクトリを使用する
```ruby
# Good - FactoryBot
FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    name { 'Test User' }
    role { :user }

    trait :admin do
      role { :admin }
    end

    trait :with_orders do
      after(:create) do |user|
        create_list(:order, 3, user: user)
      end
    end
  end
end

# 使用例
user = create(:user)
admin = create(:user, :admin)
user_with_orders = create(:user, :with_orders)
```

### let と before を適切に使用する
```ruby
RSpec.describe OrderService do
  # 遅延評価される
  let(:user) { create(:user) }
  let(:items) { create_list(:item, 3) }
  let(:service) { described_class.new(user) }

  # 即座に評価される
  let!(:existing_order) { create(:order, user: user) }

  before do
    # 各テスト前に実行
    allow(PaymentGateway).to receive(:charge).and_return(true)
  end

  describe '#create_order' do
    subject { service.create_order(items) }

    it { is_expected.to be_a(Order) }
    it { is_expected.to have_attributes(status: :pending) }
  end
end
```

## Ruby 3.x の機能

### パターンマッチング
```ruby
# Good - パターンマッチング
case response
in { status: 200, body: { data: users } }
  process_users(users)
in { status: 404 }
  handle_not_found
in { status: 500, body: { error: message } }
  log_error(message)
else
  raise UnexpectedResponseError
end

# 配列のパターンマッチング
case coordinates
in [x, y]
  Point2D.new(x, y)
in [x, y, z]
  Point3D.new(x, y, z)
end
```

### 右代入と1行パターンマッチ
```ruby
# 右代入
api_response => { data: { users: } }
# users 変数に値が代入される

# 1行パターンマッチ
user in { name:, email: } or raise InvalidUserError
```

### Ractor で並行処理
```ruby
# Ruby 3.0+ - Ractor による並行処理
ractors = 4.times.map do |i|
  Ractor.new(i) do |index|
    # 並行処理
    heavy_computation(index)
  end
end

results = ractors.map(&:take)
```
