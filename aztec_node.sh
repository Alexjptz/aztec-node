#!/bin/bash

tput reset
tput civis

# SYSTEM COLOURS
show_orange() { echo -e "\e[33m$1\e[0m"; }
show_blue()   { echo -e "\e[34m$1\e[0m"; }
show_green()  { echo -e "\e[32m$1\e[0m"; }
show_red()    { echo -e "\e[31m$1\e[0m"; }
show_cyan()   { echo -e "\e[36m$1\e[0m"; }
show_purple() { echo -e "\e[35m$1\e[0m"; }
show_gray()   { echo -e "\e[90m$1\e[0m"; }
show_white()  { echo -e "\e[97m$1\e[0m"; }
show_blink()  { echo -e "\e[5m$1\e[0m"; }

# SYSTEM FUNCS
exit_script() {
    echo
    show_red   "🚫 Script terminated by user"
    show_gray  "────────────────────────────────────────────────────────────"
    show_orange "⚠️  All processes stopped. Returning to shell..."
    show_green "Goodbye, Agent. Stay legendary."
    echo
    sleep 1
    exit 0
}

incorrect_option() {
    echo
    show_red   "⛔️  Invalid option selected"
    show_orange "🔄  Please choose a valid option from the menu"
    show_gray  "Tip: Use numbers shown in brackets [1] [2] [3]..."
    echo
    sleep 1
}

process_notification() {
    local message="$1"
    local delay="${2:-1}"

    echo
    show_gray  "────────────────────────────────────────────────────────────"
    show_orange "🔔  $message"
    show_gray  "────────────────────────────────────────────────────────────"
    echo
    sleep "$delay"
}

run_commands() {
    local commands="$*"

    if eval "$commands"; then
        sleep 1
        show_green "✅ Success"
    else
        sleep 1
        show_red "❌ Error while executing command"
    fi
    echo
}

menu_header() {
    local container_status=$(docker inspect -f '{{.State.Status}}' aztec-sequencer 2>/dev/null || echo "not installed")
    local node_status="🔴 OFFLINE"

    if [ "$container_status" = "running" ]; then
        if docker exec aztec-sequencer pgrep -x node >/dev/null 2>&1; then
            node_status="🟢 ACTIVE"
        else
            node_status="🔴 NOT RUNNING"
        fi
    fi

    show_gray "────────────────────────────────────────────────────────────"
    show_cyan  "        ⚙️  AZTEC SEQUENCER - DOCKER CONTROL"
    show_gray "────────────────────────────────────────────────────────────"
    echo
    show_orange "Agent: $(whoami)   🕒 $(date +"%H:%M:%S")   📆 $(date +"%Y-%m-%d")"
    show_green  "Container: ${container_status^^}"
    show_blue   "Node status: $node_status"
    echo
}

menu_item() {
    local num="$1"
    local icon="$2"
    local title="$3"
    local description="$4"

    local formatted_line
    formatted_line=$(printf "  [%-1s] %-2s %-20s - %s" "$num" "$icon" "$title" "$description")
    show_blue "$formatted_line"
}

print_logo() {
    clear
    tput civis

    local logo_lines=(
        "      ___       ________  .___________. _______   ______ "
        "     /   \     |       /  |           ||   ____| /      | "
        "    /  ^  \     ---/  /    ---|  |---- |  |__   |   ----' "
        "   /  /_\  \      /  /        |  |     |   __|  |  | "
        "  /  _____  \    /  /----.    |  |     |  |____ |   ----. "
        " /__/     \__\  /________|    |__|     |_______| \______| "
    )

    local messages=(
        ">> Initializing Sequencer module..."
        ">> Establishing secure connection..."
        ">> Loading node configuration..."
        ">> Syncing with Aztec Network..."
        ">> Checking system requirements..."
        ">> Terminal integrity: OK"
    )

    echo
    show_cyan "🛰️ INITIALIZING MODULE: \c"
    show_purple "AZTEC NETWORK"
    show_gray "────────────────────────────────────────────────────────────"
    echo
    sleep 0.5

    show_gray "Loading: \c"
    for i in {1..30}; do
        echo -ne "\e[32m█\e[0m"
        sleep 0.02
    done
    show_green " [100%]"
    echo
    sleep 0.3

    for msg in "${messages[@]}"; do
        show_gray "$msg"
        sleep 0.15
    done
    echo
    sleep 0.5

    for line in "${logo_lines[@]}"; do
        show_cyan "$line"
        sleep 0.08
    done

    echo
    show_green "⚙️  SYSTEM STATUS: ACTIVE"
    show_orange ">> ACCESS GRANTED. WELCOME TO AZTEC NETWORK."
    show_gray "[AZTEC-SEQUENCER:latest / Secure Terminal Session]"
    echo

    echo -ne "\e[1;37mAwaiting commands"
    for i in {1..3}; do
        echo -ne "."
        sleep 0.4
    done
    echo -e "\e[0m"
    sleep 0.5

    tput cnorm
}

confirm_prompt() {
    local prompt="$1"
    read -p "$prompt (y/N): " response
    response=$(echo "$response" | xargs)
    case "$response" in
        [yY][eE][sS]|[yY]) return 0 ;;
        *) return 1 ;;
    esac
}

prompt_input() {
    local prompt="$1"
    local var
    read -p "$prompt" var
    echo "$var" | xargs
}

return_back () {
    show_gray "↩️  Returning to main menu..."
    sleep 0.5
}

# NODE FUNC

docker_installation () {
    if command -v docker >/dev/null; then
        DOCKER_VERSION=$(docker --version | cut -d' ' -f3 | tr -d ',')
        show_green "✅ Docker already installed (version $DOCKER_VERSION)"
    else
        show_orange "ℹ️ Docker not found. Installing..."

        if run_commands "curl -fsSL https://get.docker.com | sudo sh"; then
            show_green "✓ Docker installed successfully"

            if run_commands "sudo usermod -aG docker $USER"; then
                show_green "✓ User added to docker group"

                NEW_VERSION=$(docker --version 2>/dev/null | cut -d' ' -f3 | tr -d ',')
                if [ -n "$NEW_VERSION" ]; then
                    show_green "✅ Docker $NEW_VERSION ready to use"
                    show_orange "⚠️ Please re-login or run: newgrp docker"
                    show_blue "💡 After re-login, restart this script to continue"
                else
                    show_red "❌ Docker installed but not working properly"
                    show_gray "Try manual installation: https://docs.docker.com/engine/install/"
                fi
            else
                show_red "❌ Failed to add user to docker group"
                show_gray "You may need to run docker commands with sudo"
            fi
        else
            show_red "❌ Docker installation failed!"
            show_gray "Check internet connection and try again"
            show_gray "Or install manually: https://docs.docker.com/engine/install/"
            exit 1
        fi

        sleep 2
        if ! docker ps &>/dev/null; then
            show_orange "⚠️ Starting Docker daemon..."
            if run_commands "sudo systemctl enable --now docker"; then
                show_green "✓ Docker daemon started"
            else
                show_red "❌ Failed to start Docker daemon"
                show_gray "Try manually: sudo systemctl start docker"
                exit 1
            fi
        fi

        exit 0
    fi
}

dependencies_installation() {
    process_notification "🔧 Installing system dependencies..."

    local steps=(
        "📥 Updating package list"
        "📦 Installing iptables-persistent"
        "📦 Installing required packages"
        "🛡️  Allowing TCP port 40400"
        "🛡️  Allowing UDP port 40400"
        "🛡️  Allowing TCP port 8080"
        "💾 Saving iptables rules"
        "🚀 Starting Docker installation..."
    )

    local current=0 total=${#steps[@]}
    step_progress() {
        current=$((current + 1))
        echo
        show_gray "[Step $current/$total] ${steps[$((current - 1))]}..."
        echo
        sleep 0.3
    }

    step_progress
    run_commands "sudo apt update -y >/dev/null 2>&1 && sudo apt upgrade -y"

    step_progress
    run_commands "sudo apt install -y iptables-persistent"

    step_progress
    run_commands "sudo apt install -y \\
        curl iptables mc build-essential git wget lz4 jq make gcc nano \\
        automake autoconf tmux htop nvme-cli libgbm1 pkg-config \\
        libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip"

    step_progress
    run_commands "sudo iptables -I INPUT -p tcp --dport 40400 -j ACCEPT"

    step_progress
    run_commands "sudo iptables -I INPUT -p udp --dport 40400 -j ACCEPT"

    step_progress
    run_commands "sudo iptables -I INPUT -p tcp --dport 8080 -j ACCEPT"

    step_progress
    run_commands "sudo sh -c 'iptables-save > /etc/iptables/rules.v4'"

    step_progress
    docker_installation
    echo
    show_green "✅ Dependencies installed and firewall configured"
    echo
}

node_installation() {
    process_notification "🚀 Starting Aztec Sequencer Node installation..."

    local steps=(
        "📁 Creating installation directory"
        "🐳 Pulling Docker image"
        "🧾 Collecting configuration inputs"
        "🌐 Fetching server IP"
        "📄 Writing .env configuration"
        "🐳 Launching Docker container"
    )

    local current=0 total=${#steps[@]}
    step_progress() {
        current=$((current + 1))
        echo
        show_gray "[Step $current/$total] ${steps[$((current - 1))]}..."
        echo
        sleep 0.3
    }

    step_progress
    run_commands "mkdir -p \"\$HOME/aztec-sequencer\" && cd \"\$HOME/aztec-sequencer\""

    step_progress
    run_commands "docker pull aztecprotocol/aztec:latest"

    step_progress
    RPC=$(prompt_input "🔗 Enter your Sepolia RPC URL:")
    CONSENSUS=$(prompt_input "🔗 Enter your Sepolia Beacon URL:")
    PRIVATE_KEY=$(prompt_input "🔑 Enter your PRIVATE KEY:")
    WALLET=$(prompt_input "💰 Enter your WALLET address (0x…):")

    step_progress
    SERVER_IP=$(curl -s https://api.ipify.org)
    show_green "🌍 Public IP detected: $SERVER_IP"

    step_progress
    cat > .evm <<EOF
ETHEREUM_HOSTS=$RPC
L1_CONSENSUS_HOST_URLS=$CONSENSUS
VALIDATOR_PRIVATE_KEY=$PRIVATE_KEY
P2P_IP=$SERVER_IP
WALLET=$WALLET
GOVERNANCE_PROPOSER_PAYLOAD_ADDRESS=0x54F7fe24E349993b363A5Fa1bccdAe2589D5E5Ef
EOF
    show_green "✅ .evm configuration saved."

    step_progress
    run_commands "docker run -d \
      --name aztec-sequencer \
      --network host \
      --entrypoint /bin/sh \
      --env-file \"$HOME/aztec-sequencer/.evm\" \
      -e DATA_DIRECTORY=/data \
      -e LOG_LEVEL=debug \
      -v \"$HOME/my-node/node\":/data \
      aztecprotocol/aztec:latest \
      -c 'node --no-warnings /usr/src/yarn-project/aztec/dest/bin/index.js \
        start --network alpha-testnet --node --archiver --sequencer'"
    cd $HOME
    echo
    show_green "🎉 Aztec Sequencer Node successfully installed and running in Docker"
}

get_role() {
    process_notification "🧩 Getting validator role..."

    show_gray "📡 Requesting latest proven block from node..."
    TIP_RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" \
      -d '{"jsonrpc":"2.0","method":"node_getL2Tips","params":[],"id":67}' \
      http://localhost:8080)

    BLOCK_NUMBER=$(printf '%s' "$TIP_RESPONSE" | jq -r '.result.proven.number')

    if ! [[ "$BLOCK_NUMBER" =~ ^[0-9]+$ ]]; then
        show_red "❌ Error: Expected an integer block number, got: $BLOCK_NUMBER"
        return
    fi

    show_green "✅ Block height fetched: $BLOCK_NUMBER"
    sleep 1

    show_gray "📦 Requesting archive proof for block $BLOCK_NUMBER..."
    ARCHIVE_PROOF=$(curl -s -X POST -H "Content-Type: application/json" \
      -d "{\"jsonrpc\":\"2.0\",\"method\":\"node_getArchiveSiblingPath\",\"params\":[$BLOCK_NUMBER,$BLOCK_NUMBER],\"id\":67}" \
      http://localhost:8080 | jq -r '.result')

    if [[ -z "$ARCHIVE_PROOF" || "$ARCHIVE_PROOF" == "null" ]]; then
        show_red "❌ Failed to retrieve proof for block $BLOCK_NUMBER"
        return
    fi

    echo
    show_green "✅ Archive proof for block $BLOCK_NUMBER:"
    echo "$ARCHIVE_PROOF"
    echo
}

register_validator() {
    process_notification "📝 Registering as validator..."

    local VARS_FILE="$HOME/aztec-sequencer/.evm"

    if [[ ! -f "$VARS_FILE" ]]; then
        show_red "❌ Variables file not found: $VARS_FILE"
        return
    fi

    show_gray "📂 Loading environment variables..."
    export $(grep -v '^\s*#' "$VARS_FILE" | xargs)

    sleep 1
    show_gray "🚀 Executing registration inside container..."

    output=$(docker exec -i aztec-sequencer \
        sh -c 'node /usr/src/yarn-project/aztec/dest/bin/index.js add-l1-validator \
        --l1-rpc-urls "'"${ETHEREUM_HOSTS}"'" \
        --private-key "'"${VALIDATOR_PRIVATE_KEY}"'" \
        --attester "'"${WALLET}"'" \
        --proposer-eoa "'"${WALLET}"'" \
        --staking-asset-handler 0xF739D03e98e23A7B65940848aBA8921fF3bAc4b2 \
        --l1-chain-id 11155111' 2>&1) || true

    if echo "$output" | grep -q 'ValidatorQuotaFilledUntil'; then
        ts=$(echo "$output" | grep -oP '\(\K[0-9]+(?=\))' | head -n1)
        now=$(date +%s)
        delta=$(( ts - now ))
        hours=$(( delta / 3600 ))
        mins=$(( (delta % 3600) / 60 ))

        echo
        show_red "❌ Validator registration quota exceeded."
        show_orange "⏳ You can try again in $hours h $mins m."
        echo
    else
        echo
        show_green "📄 Registration response:"
        echo "$output"
        echo
    fi
}

update_node() {
    process_notification "🔄 Updating Aztec Node..."

    local steps=(
        "📥 Pulling latest Docker image"
        "🛑 Stopping current container"
        "🧹 Removing container and old data"
        "🚀 Restarting node with latest image"
    )

    local current=0 total=${#steps[@]}
    step_progress() {
        current=$((current + 1))
        echo -ne "\e[90m[Step $current/$total]\e[0m ${steps[$((current - 1))]}...\n"
    }

    step_progress
    run_commands "docker pull aztecprotocol/aztec:latest"

    step_progress
    run_commands "docker stop aztec-sequencer"
    run_commands "docker rm aztec-sequencer"

    step_progress
    run_commands "rm -rf \"$HOME/my-node/node/\"*"

    step_progress
    run_commands "docker run -d \
        --name aztec-sequencer \
        --network host \
        --entrypoint /bin/sh \
        --env-file \"$HOME/aztec-sequencer/.evm\" \
        -e DATA_DIRECTORY=/data \
        -e LOG_LEVEL=debug \
        -v \"$HOME/my-node/node\":/data \
        aztecprotocol/aztec:latest \
        -c 'node --no-warnings /usr/src/yarn-project/aztec/dest/bin/index.js \
        start --network alpha-testnet --node --archiver --sequencer'"

    show_green "✅ Node updated successfully"
    echo
}

view_logs() {
    process_notification "📜 Просмотр логов Aztec ноды..."

    if docker ps -a --format '{{.Names}}' | grep -q "^aztec-sequencer$"; then
        show_orange "🔍 Последние 100 строк журнала (нажми Ctrl+C для выхода):"
        echo
        docker logs --tail 100 -f aztec-sequencer
    else
        show_red "🚫 Контейнер aztec-sequencer не найден"
    fi

    echo
}

restart_node() {
    process_notification "🔁 Перезапуск ноды Aztec..."

    if docker ps -a --format '{{.Names}}' | grep -q "^aztec-sequencer$"; then
        if run_commands "docker restart aztec-sequencer"; then
            show_green "✅ Нода успешно перезапущена"
        else
            show_red "❌ Не удалось перезапустить ноду"
        fi
    else
        show_red "🚫 Контейнер aztec-sequencer не найден"
    fi

    echo
}

delete_node() {
    process_notification "🗑 Aztec Node Deletion..."

    if ! confirm_prompt "⚠️ Are you sure you want to delete the Aztec node?"; then
        show_orange "❎ Deletion cancelled by user."
        return
    fi

    if docker ps -a --format '{{.Names}}' | grep -q "^aztec-sequencer$"; then
        run_commands "docker stop aztec-sequencer"
        run_commands "docker rm aztec-sequencer"
    else
        show_orange "ℹ️ Container 'aztec-sequencer' not found"
    fi

    if [[ -d "$HOME/my-node/node" ]]; then
        run_commands "rm -rf \"$HOME/my-node/node/\"*"
    fi

    if [[ -d "$HOME/aztec-sequencer" ]]; then
        run_commands "rm -rf \"$HOME/aztec-sequencer\""
    fi

    show_green "✅ Aztec node deleted successfully"
    echo
}

operation_menu () {
    while true; do
        menu_header
        show_gray "────────────────────────────────────────────────────────────"
        show_cyan "           ⚙️  OPERATION MENU"
        show_gray "────────────────────────────────────────────────────────────"
        sleep 0.3
        menu_item 1 "🛡️" "Get Role"           "Получение роли"
        menu_item 2 "📮" "Register Validator" "Регистрация валидатора"
        menu_item 3 "🔄" "Update Node"        "Обновление ноды"
        menu_item 4 "↩️" "Back"               "Вернуться в главное меню"
        show_gray "────────────────────────────────────────────────────────────"
        echo

        read -p "$(show_gray 'Select option ➤ ') " opt
        echo
        case $opt in
        1) get_role ;;
        2) register_validator ;;
        3) update_node ;;
        4) return_back; clear; return ;;
        *) incorrect_option ;;
        esac
    done
}

main_menu () {
    print_logo
    while true; do
        menu_header
        show_gray "────────────────────────────────────────────────────────────"
        show_cyan "           🔋 MAIN OPERATIONS MENU 🔋"
        show_gray "────────────────────────────────────────────────────────────"
        sleep 0.3

        menu_item 1 "🚀" "Install Node"       "Установка ноды"
        menu_item 2 "⚙️" "Operations"         "Роль/Регистрация/Обновление"
        menu_item 3 "📜" "View Logs"          "Просмотр логов"
        menu_item 4 "♻️" "Restart Node"       "Рестарт ноды"
        menu_item 5 "🗑️" "Delete Node"        "Удаление ноды"
        menu_item 6 "🚪" "Exit"               "Выход"

        show_gray "────────────────────────────────────────────────────────────"
        echo

        read -p "$(show_gray 'Select option ➤ ') " opt
        echo

        case $opt in
        1) dependencies_installation; node_installation ;;
        2) operation_menu ;;
        3) view_logs ;;
        4) restart_node ;;
        5) delete_node ;;
        6) exit_script ;;
        *) incorrect_option ;;
        esac
    done
}

main_menu
