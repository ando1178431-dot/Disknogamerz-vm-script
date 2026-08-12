#!/bin/bash
set -euo pipefail

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║                      DISKNOGAMERZ VM MANAGER v5.2                         ║
# ║          Gorilla-Engine Virtualization Platform for Web & CLI            ║
# ╚═══════════════════════════════════════════════════════════════════════════╝

readonly RESET="\033[0m"
readonly BOLD="\033[1m"
readonly FG_RED="\033[31m"
readonly FG_GREEN="\033[32m"
readonly FG_YELLOW="\033[33m"
readonly FG_BLUE="\033[34m"
readonly FG_MAGENTA="\033[35m"
readonly FG_CYAN="\033[36m"
readonly FG_GRAY="\033[90m"
readonly FG_LIGHT_CYAN="\033[96m"
readonly FG_LIGHT_WHITE="\033[97m"

readonly ICON_RUNNING="${FG_GREEN}●${RESET}"
readonly ICON_STOPPED="${FG_RED}○${RESET}"

VM_DIR="${VM_DIR:-$HOME/vms}"
mkdir -p "$VM_DIR"

# ─────────────────────────────────────────────────────────────────────────────
# GORILLA ENGINE AUTO-DEPENDENCY INSTALLER
# ─────────────────────────────────────────────────────────────────────────────
install_dependencies() {
    local missing=()
    for cmd in qemu-system-x86_64 qemu-img cloud-localds wget curl openssl; do
        if ! command -v "$cmd" &>/dev/null; then
            missing+=("$cmd")
        fi
    done

    if [ ${#missing[@]} -ne 0 ]; then
        echo -e "${FG_YELLOW}[INFO] Installing missing system packages: ${missing[*]}...${RESET}"
        sudo apt-get update -y -qq || true
        sudo apt-get install -y -qq qemu-system-x86 qemu-utils cloud-image-utils wget curl openssl ttyd || true
    fi
}

print_status() {
    local type=$1
    local message=$2
    case $type in
        "INFO")    echo -e " ${FG_BLUE}[INFO]${RESET}    $message" ;;
        "WARN")    echo -e " ${FG_YELLOW}[WARN]${RESET}    $message" ;;
        "ERROR")   echo -e " ${FG_RED}[ERROR]${RESET}   $message" ;;
        "SUCCESS") echo -e " ${FG_GREEN}[SUCCESS]${RESET} $message" ;;
        "INPUT")   echo -ne " ${FG_CYAN}[INPUT]${RESET}   $message" ;;
    esac
}

# Flicker-free screen refresh mechanism
display_header() {
    printf "\033[H\033[2J"

    echo -e "${FG_CYAN}${BOLD}"
    cat << 'EOF'
  ██████╗ ██╗███████╗██╗  ██╗███╗   ██╗██████╗  █████╗ ███╗   ███╗███████╗██████╗ ███████╗
  ██╔══██╗██║██╔════╝██║ ██╔╝████╗  ██║██╔══██╗██╔══██╗████╗ ████║██╔════╝██╔══██╗╚══███╔╝
  ██║  ██║██║███████╗█████═╝ ██╔██╗ ██║██║  ██║███████║██╔████╔██║█████╗  ██████╔╝  ███╔╝ 
  ██║  ██║██║╚════██║██╔═██╗ ██║╚██╗██║██║  ██║██╔══██║██║╚██╔╝██║██╔══╝  ██╔══██╗ ███╔╝  
  ██████╔╝██║███████║██║  ██╗██║ ╚████║██████╔╝██║  ██║██║ ╚═╝ ██║███████╗██║  ██║███████╗
  ╚═════╝ ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚══════╝
EOF
    echo -e "${RESET}"

    echo -e "${FG_MAGENTA}╭──────────────────────────────────────────────────────────────────────────────────────────────────╮${RESET}"
    echo -e "${FG_MAGENTA}│${RESET}  ${BOLD}${FG_LIGHT_CYAN}❖  DISKNOGAMERZ VM MANAGER v5.2${RESET}  ${FG_GRAY}•${RESET}  ${FG_LIGHT_WHITE}Gorilla-Engine Powered Virtualization Platform${RESET}    ${FG_MAGENTA}│${RESET}"
    echo -e "${FG_MAGENTA}╰──────────────────────────────────────────────────────────────────────────────────────────────────╯${RESET}"
    
    local host_str="$(hostname)"
    local user_str="$(whoami)"
    local kernel_str="$(uname -r)"
    local date_str="$(date '+%d %b %Y, %I:%M %p')"

    echo -e " ${FG_GRAY}Host:${RESET} ${BOLD}$host_str${RESET} ${FG_GRAY}│${RESET} ${FG_GRAY}User:${RESET} ${BOLD}$user_str${RESET} ${FG_GRAY}│${RESET} ${FG_GRAY}Kernel:${RESET} ${BOLD}$kernel_str${RESET} ${FG_GRAY}│${RESET} ${FG_GRAY}Date:${RESET} ${BOLD}$date_str${RESET}"
    echo -e "${FG_GRAY}────────────────────────────────────────────────────────────────────────────────────────────────────${RESET}"
}

get_vm_list() {
    find "$VM_DIR" -maxdepth 1 -name "*.conf" -exec basename {} .conf \; 2>/dev/null | sort
}

load_vm_config() {
    local vm_name=$1
    local config_file="$VM_DIR/$vm_name.conf"
    if [[ -f "$config_file" ]]; then
        source "$config_file"
        return 0
    fi
    return 1
}

is_vm_running() {
    local vm_name=$1
    pgrep -f "qemu-system-x86_64.*$vm_name\.qcow2" >/dev/null 2>&1
}

# ─────────────────────────────────────────────────────────────────────────────
# GORILLA ENGINE VM BUILDER & RUNNER
# ─────────────────────────────────────────────────────────────────────────────

declare -A OS_OPTIONS=(
    ["Ubuntu 22.04 LTS"]="ubuntu|jammy|https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img|ubuntu-vm|ubuntu|ubuntu"
    ["Ubuntu 24.04 LTS"]="ubuntu|noble|https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img|ubuntu-noble|ubuntu|ubuntu"
    ["Debian 12 (Bookworm)"]="debian|bookworm|https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2|debian-vm|debian|debian"
    ["Alpine Linux 3.19"]="alpine|3.19|https://dl-cdn.alpinelinux.org/alpine/v3.19/releases/x86_64/alpine-nocloud-3.19.1-x86_64.qcow2|alpine-vm|alpine|alpine"
)

create_new_vm() {
    display_header
    echo -e " ${BOLD}${FG_LIGHT_CYAN}CREATE NEW VIRTUAL MACHINE${RESET}\n"
    
    local os_keys=("${!OS_OPTIONS[@]}")
    print_status "INFO" "Select OS Template:"
    for i in "${!os_keys[@]}"; do
        printf "   ${BOLD}${FG_CYAN}%2d)${RESET} %-35s\n" "$((i+1))" "${os_keys[$i]}"
    done
    echo
    
    read -rp " Select OS option (1-${#os_keys[@]}): " choice
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt "${#os_keys[@]}" ]; then
        print_status "ERROR" "Invalid option."
        return
    fi

    local os="${os_keys[$((choice-1))]}"
    IFS='|' read -r OS_TYPE CODENAME IMG_URL DEFAULT_HOSTNAME DEFAULT_USERNAME DEFAULT_PASSWORD <<< "${OS_OPTIONS[$os]}"

    read -rp " VM Name [$DEFAULT_HOSTNAME]: " VM_NAME
    VM_NAME="${VM_NAME:-$DEFAULT_HOSTNAME}"
    
    read -rp " Admin Username [$DEFAULT_USERNAME]: " USERNAME
    USERNAME="${USERNAME:-$DEFAULT_USERNAME}"

    read -rsp " Admin Password [$DEFAULT_PASSWORD]: " PASSWORD
    PASSWORD="${PASSWORD:-$DEFAULT_PASSWORD}"
    echo

    read -rp " Virtual Disk Size [20G]: " DISK_SIZE
    DISK_SIZE="${DISK_SIZE:-20G}"

    read -rp " RAM Allocation (MB) [2048]: " MEMORY
    MEMORY="${MEMORY:-2048}"

    read -rp " CPU Cores [2]: " CPUS
    CPUS="${CPUS:-2}"

    read -rp " SSH Port [2222]: " SSH_PORT
    SSH_PORT="${SSH_PORT:-2222}"

    read -rp " Enable Web Terminal (ttyd)? (Y/n): " ENABLE_TTYD
    ENABLE_TTYD="${ENABLE_TTYD:-y}"

    IMG_FILE="$VM_DIR/$VM_NAME.qcow2"
    SEED_FILE="$VM_DIR/$VM_NAME-seed.iso"

    print_status "INFO" "Downloading Cloud Image base..."
    if [[ ! -f "$IMG_FILE" ]]; then
        wget -q --show-progress "$IMG_URL" -O "$IMG_FILE.tmp"
        mv "$IMG_FILE.tmp" "$IMG_FILE"
    fi

    qemu-img resize "$IMG_FILE" "$DISK_SIZE" &>/dev/null || true

    cat > user-data <<EOF
#cloud-config
hostname: $VM_NAME
ssh_pwauth: true
disable_root: false
users:
  - name: $USERNAME
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    password: $(openssl passwd -6 "$PASSWORD")
chpasswd:
  list: |
    root:$PASSWORD
    $USERNAME:$PASSWORD
  expire: false
EOF

    cat > meta-data <<EOF
instance-id: iid-$VM_NAME
local-hostname: $VM_NAME
EOF

    cloud-localds "$SEED_FILE" user-data meta-data
    rm -f user-data meta-data

    cat > "$VM_DIR/$VM_NAME.conf" <<EOF
VM_NAME="$VM_NAME"
OS_TYPE="$OS_TYPE"
CODENAME="$CODENAME"
USERNAME="$USERNAME"
PASSWORD="$PASSWORD"
DISK_SIZE="$DISK_SIZE"
MEMORY="$MEMORY"
CPUS="$CPUS"
SSH_PORT="$SSH_PORT"
ENABLE_TTYD="$ENABLE_TTYD"
IMG_FILE="$IMG_FILE"
SEED_FILE="$SEED_FILE"
CREATED="$(date)"
EOF

    print_status "SUCCESS" "VM '$VM_NAME' created successfully!"
}

start_vm() {
    local vm_name=$1
    if load_vm_config "$vm_name"; then
        if is_vm_running "$vm_name"; then
            print_status "WARN" "VM '$vm_name' is already running!"
            return
        fi

        print_status "INFO" "Booting Gorilla-Engine Virtual Machine '$vm_name'..."

        local cpu_accel="-cpu host"
        local kvm_flag="-enable-kvm"
        if ! [ -w /dev/kvm ]; then
            cpu_accel="-cpu qemu64"
            kvm_flag=""
        fi

        nohup qemu-system-x86_64 \
            $kvm_flag \
            -m "$MEMORY" \
            -smp "$CPUS" \
            $cpu_accel \
            -drive "file=$IMG_FILE,format=qcow2,if=virtio" \
            -drive "file=$SEED_FILE,format=raw,if=virtio" \
            -nographic \
            -netdev "user,id=n1,hostfwd=tcp::$SSH_PORT-:22" \
            -device "virtio-net-pci,netdev=n1" > "$VM_DIR/$vm_name.log" 2>&1 &

        sleep 2
        if is_vm_running "$vm_name"; then
            print_status "SUCCESS" "VM '$vm_name' is now running in background!"
            echo -e " ${FG_GRAY}─────────────────────────────────────────────────────────${RESET}"
            echo -e "  ${BOLD}SSH Command:${RESET} ${FG_CYAN}ssh -p $SSH_PORT $USERNAME@localhost${RESET}"
            echo -e "  ${BOLD}Credentials:${RESET} ${FG_GRAY}User:${RESET} $USERNAME ${FG_GRAY}│ Password:${RESET} $PASSWORD"
            echo -e " ${FG_GRAY}─────────────────────────────────────────────────────────${RESET}"

            # Gorilla-Engine Cloudflare/ttyd launcher option
            if [[ "$ENABLE_TTYD" =~ ^[Yy]$ ]] && command -v ttyd &>/dev/null; then
                nohup ttyd -p $((SSH_PORT + 1000)) ssh -p "$SSH_PORT" "$USERNAME@localhost" >/dev/null 2>&1 &
                print_status "SUCCESS" "Web Terminal active at: http://localhost:$((SSH_PORT + 1000))"
            fi
        else
            print_status "ERROR" "Failed to start VM. Check logs at $VM_DIR/$vm_name.log"
        fi
    fi
}

stop_vm() {
    local vm_name=$1
    if is_vm_running "$vm_name"; then
        print_status "INFO" "Stopping VM '$vm_name'..."
        pkill -f "qemu-system-x86_64.*$vm_name\.qcow2" || true
        pkill -f "ttyd.*$vm_name" || true
        print_status "SUCCESS" "VM '$vm_name' stopped."
    else
        print_status "INFO" "VM '$vm_name' is not running."
    fi
}

delete_vm() {
    local vm_name=$1
    read -rp " Confirm deletion of '$vm_name'? (y/N): " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        stop_vm "$vm_name"
        rm -f "$VM_DIR/$vm_name.qcow2" "$VM_DIR/$vm_name-seed.iso" "$VM_DIR/$vm_name.conf" "$VM_DIR/$vm_name.log"
        print_status "SUCCESS" "VM '$vm_name' deleted."
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# MAIN MENU
# ─────────────────────────────────────────────────────────────────────────────
main_menu() {
    while true; do
        display_header
        local vms=($(get_vm_list))
        local vm_count=${#vms[@]}

        echo -e " ${BOLD}${FG_LIGHT_WHITE}VIRTUAL MACHINES OVERVIEW${RESET}"
        echo -e "${FG_CYAN}┌────┬──────────────────────┬─────────────┬──────────────┬────────────┬──────────────┐${RESET}"
        echo -e "${FG_CYAN}│${RESET} ${BOLD}#${RESET}  ${FG_CYAN}│${RESET} ${BOLD}VM NAME              ${RESET}${FG_CYAN}│${RESET} ${BOLD}OS / TYPE   ${RESET}${FG_CYAN}│${RESET} ${BOLD}RAM / CPU    ${RESET}${FG_CYAN}│${RESET} ${BOLD}SSH PORT   ${RESET}${FG_CYAN}│${RESET} ${BOLD}STATUS        ${RESET}${FG_CYAN}│${RESET}"
        echo -e "${FG_CYAN}├────┼──────────────────────┼─────────────┼──────────────┼────────────┼──────────────┤${RESET}"

        if [ "$vm_count" -gt 0 ]; then
            for i in "${!vms[@]}"; do
                local vm="${vms[$i]}"
                local status_badge="${ICON_STOPPED} ${FG_RED}STOPPED${RESET}"
                load_vm_config "$vm" || true

                if is_vm_running "$vm"; then
                    status_badge="${ICON_RUNNING} ${FG_GREEN}RUNNING${RESET}"
                fi

                printf "${FG_CYAN}│${RESET} %2d ${FG_CYAN}│${RESET} %-20s ${FG_CYAN}│${RESET} %-11s ${FG_CYAN}│${RESET} %-12s ${FG_CYAN}│${RESET} %-10s ${FG_CYAN}│${RESET} %-22b ${FG_CYAN}│${RESET}\n" \
                    "$((i+1))" "$vm" "${OS_TYPE:-N/A}" "${MEMORY:-2048}M/${CPUS:-2}c" "${SSH_PORT:-2222}" "$status_badge"
            done
        else
            printf "${FG_CYAN}│${RESET} %-76s ${FG_CYAN}│${RESET}\n" " ${FG_GRAY}No virtual machines configured yet. Select option [1] to create one.${RESET}"
        fi
        echo -e "${FG_CYAN}└────┴──────────────────────┴─────────────┴──────────────┴────────────┴──────────────┘${RESET}\n"

        echo -e "  ${BOLD}${FG_CYAN}1)${RESET} Create New VM                ${FG_GRAY}│${RESET} ${BOLD}${FG_CYAN}3)${RESET} Stop VM"
        echo -e "  ${BOLD}${FG_CYAN}2)${RESET} Start VM                     ${FG_GRAY}│${RESET} ${BOLD}${FG_CYAN}4)${RESET} Delete VM"
        echo -e "  ${BOLD}${FG_RED}0)${RESET} Exit"
        echo -e " ${FG_GRAY}────────────────────────────────────────────────────────────────────────────────────${RESET}\n"

        read -rp " Select option: " choice
        case $choice in
            1) create_new_vm ;;
            2)
                if [ "$vm_count" -gt 0 ]; then
                    read -rp " Enter VM number to start: " num
                    if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le "$vm_count" ]; then
                        start_vm "${vms[$((num-1))]}"
                    fi
                fi
                ;;
            3)
                if [ "$vm_count" -gt 0 ]; then
                    read -rp " Enter VM number to stop: " num
                    if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le "$vm_count" ]; then
                        stop_vm "${vms[$((num-1))]}"
                    fi
                fi
                ;;
            4)
                if [ "$vm_count" -gt 0 ]; then
                    read -rp " Enter VM number to delete: " num
                    if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le "$vm_count" ]; then
                        delete_vm "${vms[$((num-1))]}"
                    fi
                fi
                ;;
            0) exit 0 ;;
        esac
        
        echo
        read -rp " Press [ENTER] to return to menu..." _
    done
}

install_dependencies
main_menu
