# React ベストプラクティス

## コンポーネント設計

### 関数コンポーネントを使用する
```tsx
// Good - 関数コンポーネント
function UserProfile({ user }: { user: User }) {
  return (
    <div>
      <h1>{user.name}</h1>
      <p>{user.email}</p>
    </div>
  );
}

// Bad - クラスコンポーネント（レガシー）
class UserProfile extends React.Component<Props> {
  render() {
    return (
      <div>
        <h1>{this.props.user.name}</h1>
      </div>
    );
  }
}
```

### 単一責任の原則に従う
```tsx
// Good - 責務を分離
function UserList({ users }: { users: User[] }) {
  return (
    <ul>
      {users.map(user => (
        <UserListItem key={user.id} user={user} />
      ))}
    </ul>
  );
}

function UserListItem({ user }: { user: User }) {
  return (
    <li>
      <UserAvatar src={user.avatar} />
      <UserName name={user.name} />
    </li>
  );
}

// Bad - 1つのコンポーネントで全部やる
function UserList({ users }: { users: User[] }) {
  return (
    <ul>
      {users.map(user => (
        <li key={user.id}>
          <img src={user.avatar} alt="" />
          <span>{user.name}</span>
          <span>{user.email}</span>
          <button onClick={() => deleteUser(user.id)}>Delete</button>
          {/* さらに多くのロジック... */}
        </li>
      ))}
    </ul>
  );
}
```

### Props の型定義を明確にする
```tsx
// Good - 明確な Props 型
interface ButtonProps {
  variant: 'primary' | 'secondary' | 'danger';
  size?: 'sm' | 'md' | 'lg';
  disabled?: boolean;
  onClick: () => void;
  children: React.ReactNode;
}

function Button({
  variant,
  size = 'md',
  disabled = false,
  onClick,
  children
}: ButtonProps) {
  return (
    <button
      className={`btn btn-${variant} btn-${size}`}
      disabled={disabled}
      onClick={onClick}
    >
      {children}
    </button>
  );
}
```

## Hooks

### useState の適切な使用
```tsx
// Good - 関連する状態をグループ化
interface FormState {
  name: string;
  email: string;
  message: string;
}

function ContactForm() {
  const [form, setForm] = useState<FormState>({
    name: '',
    email: '',
    message: '',
  });

  const updateField = (field: keyof FormState, value: string) => {
    setForm(prev => ({ ...prev, [field]: value }));
  };

  return (
    <form>
      <input
        value={form.name}
        onChange={e => updateField('name', e.target.value)}
      />
    </form>
  );
}

// Bad - 過度に分割された状態
function ContactForm() {
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [message, setMessage] = useState('');
  // 状態が増えると管理が困難に
}
```

### useEffect の依存配列を正しく設定する
```tsx
// Good - 依存配列を正確に指定
function UserProfile({ userId }: { userId: number }) {
  const [user, setUser] = useState<User | null>(null);

  useEffect(() => {
    let cancelled = false;

    async function fetchUser() {
      const data = await getUser(userId);
      if (!cancelled) {
        setUser(data);
      }
    }

    fetchUser();

    return () => {
      cancelled = true;
    };
  }, [userId]);

  return user ? <div>{user.name}</div> : <div>Loading...</div>;
}

// Bad - 依存配列の問題
useEffect(() => {
  fetchUser(userId); // userId が依存配列にない
}, []); // ESLint 警告を無視しない

useEffect(() => {
  // 無限ループの可能性
  setCount(count + 1);
}, [count]);
```

### useMemo と useCallback を適切に使用する
```tsx
// Good - 高コストな計算をメモ化
function ProductList({ products, filter }: Props) {
  const filteredProducts = useMemo(
    () => products.filter(p => p.category === filter),
    [products, filter]
  );

  return (
    <ul>
      {filteredProducts.map(product => (
        <ProductItem key={product.id} product={product} />
      ))}
    </ul>
  );
}

// Good - コールバックをメモ化（子コンポーネントが memo の場合）
function Parent() {
  const [count, setCount] = useState(0);

  const handleClick = useCallback(() => {
    setCount(prev => prev + 1);
  }, []);

  return <MemoizedChild onClick={handleClick} />;
}

// Bad - 過度なメモ化（コストに見合わない）
function SimpleComponent({ value }: { value: string }) {
  // 単純な計算にメモ化は不要
  const upperValue = useMemo(() => value.toUpperCase(), [value]);
  return <span>{upperValue}</span>;
}
```

### カスタムフックで再利用可能なロジックを抽出する
```tsx
// Good - ロジックをカスタムフックに抽出
function useAsync<T>(asyncFn: () => Promise<T>, deps: unknown[]) {
  const [state, setState] = useState<{
    data: T | null;
    loading: boolean;
    error: Error | null;
  }>({
    data: null,
    loading: true,
    error: null,
  });

  useEffect(() => {
    let cancelled = false;

    setState(prev => ({ ...prev, loading: true }));

    asyncFn()
      .then(data => {
        if (!cancelled) {
          setState({ data, loading: false, error: null });
        }
      })
      .catch(error => {
        if (!cancelled) {
          setState({ data: null, loading: false, error });
        }
      });

    return () => {
      cancelled = true;
    };
  }, deps);

  return state;
}

// 使用例
function UserProfile({ userId }: { userId: number }) {
  const { data: user, loading, error } = useAsync(
    () => fetchUser(userId),
    [userId]
  );

  if (loading) return <Spinner />;
  if (error) return <ErrorMessage error={error} />;
  return <div>{user?.name}</div>;
}
```

## パフォーマンス

### React.memo で不要な再レンダリングを防ぐ
```tsx
// Good - 純粋なコンポーネントをメモ化
interface ItemProps {
  item: Item;
  onSelect: (id: number) => void;
}

const ListItem = memo(function ListItem({ item, onSelect }: ItemProps) {
  return (
    <li onClick={() => onSelect(item.id)}>
      {item.name}
    </li>
  );
});

// カスタム比較関数
const ListItem = memo(
  function ListItem({ item, onSelect }: ItemProps) {
    return <li>{item.name}</li>;
  },
  (prevProps, nextProps) => prevProps.item.id === nextProps.item.id
);
```

### 大量リストには仮想化を使用する
```tsx
// Good - react-window で仮想化
import { FixedSizeList } from 'react-window';

function VirtualizedList({ items }: { items: Item[] }) {
  return (
    <FixedSizeList
      height={400}
      width={300}
      itemCount={items.length}
      itemSize={50}
    >
      {({ index, style }) => (
        <div style={style}>
          {items[index].name}
        </div>
      )}
    </FixedSizeList>
  );
}

// Bad - 大量の DOM を一度にレンダリング
function List({ items }: { items: Item[] }) {
  return (
    <ul>
      {items.map(item => ( // 10000件のアイテム
        <li key={item.id}>{item.name}</li>
      ))}
    </ul>
  );
}
```

### コード分割と遅延読み込み
```tsx
// Good - React.lazy でコード分割
const Dashboard = lazy(() => import('./pages/Dashboard'));
const Settings = lazy(() => import('./pages/Settings'));

function App() {
  return (
    <Suspense fallback={<LoadingSpinner />}>
      <Routes>
        <Route path="/dashboard" element={<Dashboard />} />
        <Route path="/settings" element={<Settings />} />
      </Routes>
    </Suspense>
  );
}
```

## 状態管理

### 状態を適切な場所に配置する
```tsx
// Good - 状態のリフトアップ
function Parent() {
  const [selectedId, setSelectedId] = useState<number | null>(null);

  return (
    <>
      <List items={items} onSelect={setSelectedId} />
      <Detail itemId={selectedId} />
    </>
  );
}

// Good - 状態のコロケーション（必要な場所に置く）
function SearchForm() {
  // 検索フォームでのみ使用する状態
  const [query, setQuery] = useState('');

  return (
    <input
      value={query}
      onChange={e => setQuery(e.target.value)}
    />
  );
}
```

### Context を適切に使用する
```tsx
// Good - Context を分割して不要な再レンダリングを防ぐ
const UserContext = createContext<User | null>(null);
const UserActionsContext = createContext<UserActions | null>(null);

function UserProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);

  const actions = useMemo(() => ({
    login: async (credentials: Credentials) => {
      const user = await loginApi(credentials);
      setUser(user);
    },
    logout: () => setUser(null),
  }), []);

  return (
    <UserContext.Provider value={user}>
      <UserActionsContext.Provider value={actions}>
        {children}
      </UserActionsContext.Provider>
    </UserContext.Provider>
  );
}

// カスタムフックで使いやすく
function useUser() {
  const user = useContext(UserContext);
  if (user === undefined) {
    throw new Error('useUser must be used within UserProvider');
  }
  return user;
}
```

### useReducer で複雑な状態を管理する
```tsx
// Good - 複雑な状態ロジックを reducer で管理
type State = {
  items: Item[];
  loading: boolean;
  error: Error | null;
};

type Action =
  | { type: 'FETCH_START' }
  | { type: 'FETCH_SUCCESS'; payload: Item[] }
  | { type: 'FETCH_ERROR'; payload: Error }
  | { type: 'ADD_ITEM'; payload: Item }
  | { type: 'REMOVE_ITEM'; payload: number };

function reducer(state: State, action: Action): State {
  switch (action.type) {
    case 'FETCH_START':
      return { ...state, loading: true, error: null };
    case 'FETCH_SUCCESS':
      return { ...state, loading: false, items: action.payload };
    case 'FETCH_ERROR':
      return { ...state, loading: false, error: action.payload };
    case 'ADD_ITEM':
      return { ...state, items: [...state.items, action.payload] };
    case 'REMOVE_ITEM':
      return { ...state, items: state.items.filter(i => i.id !== action.payload) };
    default:
      return state;
  }
}
```

## フォーム

### 制御コンポーネントを使用する
```tsx
// Good - 制御コンポーネント
function LoginForm({ onSubmit }: { onSubmit: (data: LoginData) => void }) {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [errors, setErrors] = useState<Record<string, string>>({});

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();

    const newErrors: Record<string, string> = {};
    if (!email) newErrors.email = 'Email is required';
    if (!password) newErrors.password = 'Password is required';

    if (Object.keys(newErrors).length > 0) {
      setErrors(newErrors);
      return;
    }

    onSubmit({ email, password });
  };

  return (
    <form onSubmit={handleSubmit}>
      <input
        type="email"
        value={email}
        onChange={e => setEmail(e.target.value)}
        aria-invalid={!!errors.email}
      />
      {errors.email && <span role="alert">{errors.email}</span>}
    </form>
  );
}
```

### フォームライブラリを活用する
```tsx
// Good - React Hook Form で効率的なフォーム管理
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';

const schema = z.object({
  email: z.string().email('Invalid email'),
  password: z.string().min(8, 'Password must be at least 8 characters'),
});

type FormData = z.infer<typeof schema>;

function LoginForm() {
  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<FormData>({
    resolver: zodResolver(schema),
  });

  const onSubmit = async (data: FormData) => {
    await login(data);
  };

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <input {...register('email')} />
      {errors.email && <span>{errors.email.message}</span>}

      <input type="password" {...register('password')} />
      {errors.password && <span>{errors.password.message}</span>}

      <button type="submit" disabled={isSubmitting}>
        Login
      </button>
    </form>
  );
}
```

## エラーハンドリング

### Error Boundary を使用する
```tsx
// Good - Error Boundary で UI クラッシュを防ぐ
class ErrorBoundary extends React.Component<
  { children: React.ReactNode; fallback: React.ReactNode },
  { hasError: boolean }
> {
  state = { hasError: false };

  static getDerivedStateFromError() {
    return { hasError: true };
  }

  componentDidCatch(error: Error, info: React.ErrorInfo) {
    console.error('Error caught:', error, info);
    // エラー報告サービスに送信
  }

  render() {
    if (this.state.hasError) {
      return this.props.fallback;
    }
    return this.props.children;
  }
}

// 使用例
function App() {
  return (
    <ErrorBoundary fallback={<ErrorPage />}>
      <MainContent />
    </ErrorBoundary>
  );
}
```

## アクセシビリティ

### セマンティック HTML を使用する
```tsx
// Good - 適切なセマンティクス
function Navigation() {
  return (
    <nav aria-label="Main navigation">
      <ul role="menubar">
        <li role="none">
          <a href="/" role="menuitem">Home</a>
        </li>
        <li role="none">
          <a href="/about" role="menuitem">About</a>
        </li>
      </ul>
    </nav>
  );
}

// Good - アクセシブルなボタン
function IconButton({
  icon,
  label,
  onClick
}: {
  icon: React.ReactNode;
  label: string;
  onClick: () => void;
}) {
  return (
    <button onClick={onClick} aria-label={label}>
      {icon}
    </button>
  );
}

// Bad - div でクリック可能要素を作る
<div onClick={handleClick}>Click me</div>
```

### キーボードナビゲーションをサポートする
```tsx
// Good - キーボード操作を考慮
function Dropdown({ options, onSelect }: DropdownProps) {
  const [isOpen, setIsOpen] = useState(false);
  const [focusIndex, setFocusIndex] = useState(0);

  const handleKeyDown = (e: React.KeyboardEvent) => {
    switch (e.key) {
      case 'ArrowDown':
        e.preventDefault();
        setFocusIndex(i => Math.min(i + 1, options.length - 1));
        break;
      case 'ArrowUp':
        e.preventDefault();
        setFocusIndex(i => Math.max(i - 1, 0));
        break;
      case 'Enter':
      case ' ':
        e.preventDefault();
        onSelect(options[focusIndex]);
        setIsOpen(false);
        break;
      case 'Escape':
        setIsOpen(false);
        break;
    }
  };

  return (
    <div onKeyDown={handleKeyDown} role="listbox" tabIndex={0}>
      {/* オプションのレンダリング */}
    </div>
  );
}
```

## テスト

### React Testing Library を使用する
```tsx
// Good - ユーザー視点でテスト
import { render, screen, userEvent } from '@testing-library/react';

describe('LoginForm', () => {
  it('shows validation error for empty email', async () => {
    const user = userEvent.setup();
    render(<LoginForm onSubmit={jest.fn()} />);

    await user.click(screen.getByRole('button', { name: /submit/i }));

    expect(screen.getByRole('alert')).toHaveTextContent('Email is required');
  });

  it('calls onSubmit with form data', async () => {
    const user = userEvent.setup();
    const handleSubmit = jest.fn();
    render(<LoginForm onSubmit={handleSubmit} />);

    await user.type(screen.getByLabelText(/email/i), 'test@example.com');
    await user.type(screen.getByLabelText(/password/i), 'password123');
    await user.click(screen.getByRole('button', { name: /submit/i }));

    expect(handleSubmit).toHaveBeenCalledWith({
      email: 'test@example.com',
      password: 'password123',
    });
  });
});

// Bad - 実装の詳細をテスト
it('updates state when input changes', () => {
  const { container } = render(<LoginForm />);
  // querySelector や state の直接チェックは避ける
});
```

## ファイル構成

### 機能ベースのディレクトリ構成
```
src/
├── features/
│   ├── auth/
│   │   ├── components/
│   │   │   ├── LoginForm.tsx
│   │   │   └── SignupForm.tsx
│   │   ├── hooks/
│   │   │   └── useAuth.ts
│   │   ├── api/
│   │   │   └── authApi.ts
│   │   └── index.ts
│   └── users/
│       ├── components/
│       ├── hooks/
│       └── index.ts
├── components/
│   └── ui/           # 共通 UI コンポーネント
│       ├── Button.tsx
│       └── Input.tsx
├── hooks/            # 共通フック
├── utils/            # ユーティリティ
└── App.tsx
```
