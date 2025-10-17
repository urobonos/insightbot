#!/usr/bin/env bash
set -e

export PATH="$HOME/.pyenv/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

# =========================
# 사용자 설정
# =========================
# 설치할 Python 버전 목록
PYTHON_VERSIONS=("3.12.11" "3.12.11" "3.13.7" "3.13.7" "3.13.7")
# 각 버전별 생성할 가상환경 이름 (배열 길이 동일해야 함)
VENV_NAMES=("chroma" "gemini" "mysql" "prompt" "rag")

# =========================
# pyenv 설치 확인
# =========================
echo "=== pyenv 설치 확인 ==="
if ! command -v pyenv >/dev/null 2>&1; then
    echo "⚙️ pyenv 설치 중..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        [[ ! $(command -v brew) ]] && /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        brew update
        brew install pyenv pyenv-virtualenv
    else
        sudo apt update -y
        sudo apt install -y make build-essential libssl-dev zlib1g-dev \
          libbz2-dev libreadline-dev libsqlite3-dev curl git \
          libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev
        curl https://pyenv.run | bash
    fi
    export PATH="$HOME/.pyenv/bin:$PATH"
    eval "$(pyenv init -)"
    eval "$(pyenv virtualenv-init -)"
else
    echo "✅ pyenv 이미 설치됨"
fi

# 버전별 설치 및 가상환경 생성
for i in "${!PYTHON_VERSIONS[@]}"; do
    PY_VERSION="${PYTHON_VERSIONS[$i]}"
    VENV_NAME="${VENV_NAMES[$i]}_env"

    echo
    if !(pyenv versions --bare | grep -qx "$PY_VERSION";) then
        echo "⚙️ $PY_VERSION 설치 중..."
        pyenv install "$PY_VERSION"
    fi

    echo "=== 가상환경 '$VENV_NAME' 확인 ==="
    if pyenv virtualenvs --bare | grep -qx "$VENV_NAME"; then
        echo "✅ 가상환경 '$VENV_NAME' 이미 존재"
    else
        echo "⚙️ 가상환경 '$VENV_NAME' 생성 중..."
        pyenv virtualenv "$PY_VERSION" "$VENV_NAME"
    fi
done

#echo
#echo "🎉 모든 Python 버전 및 가상환경 준비 완료!"
#echo "가상환경 활성화:"
#for VENV_NAME in "${VENV_NAMES[@]}"; do
#    echo "pyenv activate $VENV_NAME"
#done
#echo "비활성화: pyenv deactivate"

# =========================
# 가상환경 순회하며 requirements 설치
# =========================
REQ_FILE="requirements.txt"  # 프로젝트별 requirements 경로

for VENV_NAME in "${VENV_NAMES[@]}"; do
    VENV_REPO="msa_${VENV_NAME}"
    VENV_NAME="${VENV_NAME}_env"
    echo
    echo "=== 가상환경 '$VENV_NAME' 활성화 ==="
    pyenv activate "$VENV_NAME"

    if [ -f "../$VENV_REPO/$REQ_FILE" ]; then
        echo "⚙️ $REQ_FILE 설치 중..."
        pip install -r "../$VENV_REPO/$REQ_FILE"
    else
        echo "⚠️ $REQ_FILE 파일을 찾을 수 없음. 건너뜀."
    fi

    pyenv deactivate
done

echo
echo "🎉 모든 가상환경에 requirements 설치 완료!"