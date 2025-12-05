# dotconfig更新チェック（1日1回）
_dotconfig_update_check() {
    # ~/.config のシンボリックリンク先（dotconfigリポジトリ）を解決
    local CONFIG_DIR="${HOME}/.config"
    local DOTCONFIG_DIR
    if [[ -L "$CONFIG_DIR" ]]; then
        DOTCONFIG_DIR="$(dirname "$(readlink "$CONFIG_DIR")")"
    else
        return 0
    fi
    local CACHE_FILE="${HOME}/.cache/dotconfig-last-check"
    local CHECK_INTERVAL=$((24 * 60 * 60))  # 24時間

    # gitリポジトリでない場合はスキップ
    [[ ! -d "$DOTCONFIG_DIR/.git" ]] && return 0

    # キャッシュディレクトリ作成
    mkdir -p "$(dirname "$CACHE_FILE")"

    # 前回チェックからの経過時間を確認
    if [[ -f "$CACHE_FILE" ]]; then
        local last_check=$(cat "$CACHE_FILE")
        local now=$(date +%s)
        if (( now - last_check < CHECK_INTERVAL )); then
            return 0
        fi
    fi

    # 現在時刻を記録
    date +%s > "$CACHE_FILE"

    # バックグラウンドでチェック
    (
        local messages=()

        # dotconfig更新チェック
        cd "$DOTCONFIG_DIR" || return
        git fetch origin main --quiet 2>/dev/null

        local LOCAL=$(git rev-parse HEAD 2>/dev/null)
        local REMOTE=$(git rev-parse origin/main 2>/dev/null)

        if [[ -n "$LOCAL" && -n "$REMOTE" && "$LOCAL" != "$REMOTE" ]]; then
            messages+=("\033[1;33m[dotconfig]\033[0m 更新があります: ~/.config/scripts/update.sh")
        fi

        # brew更新チェック
        if command -v brew &>/dev/null; then
            brew update --quiet 2>/dev/null
            local outdated=$(brew outdated --quiet 2>/dev/null)
            if [[ -n "$outdated" ]]; then
                local count=$(echo "$outdated" | wc -l | tr -d ' ')
                messages+=("\033[1;33m[brew]\033[0m ${count}個のパッケージが更新可能: brew upgrade")
            fi
        fi

        # メッセージがあれば表示
        if [[ ${#messages[@]} -gt 0 ]]; then
            echo ""
            for msg in "${messages[@]}"; do
                echo "$msg"
            done
            echo ""
        fi
    ) &!
}

_dotconfig_update_check
