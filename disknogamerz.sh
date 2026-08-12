#!/bin/bash

# ╔══════════════════════════════════════════════════════════════╗
# ║                 DISKNOGAMERZ VM MANAGER                      ║
# ║             Ultra-Fast Turbo Edition                         ║
# ╚══════════════════════════════════════════════════════════════╝

NC='\033[0m'
BOLD='\033[1m'
C_CYAN='\033[1;36m'
C_MAGENTA='\033[1;35m'
C_YELLOW='\033[1;33m'
C_RED='\033[1;31m'
C_NEON_PINK='\033[38;5;201m'
C_NEON_GREEN='\033[38;5;46m'
C_BRIGHT_CYAN='\033[38;5;51m'
C_GRAY='\033[38;5;244m'
BG_GREEN='\033[42;1;30m'
BG_RED='\033[41;1;37m'

declare -A OS_OPTIONS=(
    ["Ubuntu 24.04 LTS (Noble)"]="ubuntu|noble|https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img|disknogamerz-ubuntu|disknogamerz|disk123"
    ["Ubuntu 22.04 LTS (Jammy)"]="ubuntu|jammy|https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img|disknogamerz-ubuntu|disknogamerz|disk123"
    ["Debian 12 (Bookworm)"]="debian|bookworm|https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2|disknogamerz-debian|disknogamerz|disk123"
    ["Debian 11 (Bullseye)"]="debian|bullseye|https://cloud.debian.org/images/cloud/bullseye/latest/debian-11-generic-amd64.qcow2|disknogamerz-debian|disknogamerz|disk123"
    ["Fedora 39 Cloud"]="fedora|39|https://download.fedoraproject.org/pub/fedora/linux/releases/39/Cloud/x86_64/images/Fedora-Cloud-Base-39-1.5.x86_64.qcow2|disknogamerz-fedora|disknogamerz|disk123"
)

display_header() {
    clear
    tput civis 2>/dev/null || true

    echo -e "${C_NEON_PINK}"
    cat << 'EOF'
  ██████╗ ██╗███████╗██╗  ██╗███╗   ██╗██████╗ ██████╗  ██████╗ 
  ██╔══██╗██║██╔════╝██║ ██╔╝████╗  ██║██╔══██╗██╔══██╗██╔════╝ 
  ██║  ██║██║███████╗█████═╝ ██╔██╗ ██║██║  ██║██████╔╝██║  ███╗
  ██║  ██║██║╚════██║██╔═██╗ ██║╚██╗██║██║  ██║██╔══██╗██║   ██║
  ██████╔╝██║███████║██║  ██╗██║ ╚████║██████╔╝██║  ██║╚██████╔╝
  ╚═════╝ ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═════╝ ╚═╝  ╚═╝ ╚═════╝ 
EOF
    echo -e "${NC}"

    echo -e "${C_CYAN}╔══════════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${C_CYAN}║${NC} ${C_BRIGHT_CYAN}${BOLD}           DISKNOGAMERZ VIRTUAL MACHINE CONTROL CENTER (TURBO)${NC}           ${C_CYAN}║${NC}"
    echo -e "${C_CYAN}╠══════════════════════════════════════════════════════════════════════════════════╣${NC}"
    printf "${C_CYAN}║${NC} ${C_YELLOW}✦ Host:${NC} %-25s ${C_YELLOW}✦ User:${NC} %-26s ${C_CYAN}║${NC}\n" "$(hostname)" "$(whoami)"
    printf "${C_CYAN}║${NC} ${C_YELLOW}✦ Kernel:${NC} %-23s ${C_YELLOW}✦ Arch:${NC} %-26s ${C_CYAN}║${NC}\n" "$(uname -r)" "$(uname -m)"
    printf "${C_CYAN}║${NC} ${C_YELLOW}✦ Date:${NC} %-57s ${C_CYAN}║${NC}\n" "$(date '+%d %b %Y | %I:%M:%S %p')"
    echo -e "${C_CYAN}╚══════════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo
}

print_status() {
    local type=$1
    local message=$2
    case $type in
        "INFO")    echo -e " ${C_CYAN}ℹ [INFO]${NC} $message" ;;
        "WARN")    echo -e " ${C_YELLOW}⚡ [WARN]${NC} $message" ;;
        "ERROR")   echo -e " ${C_RED}✖ [ERROR]${NC} ${C_RED}$message${NC}" ;;
        "SUCCESS") echo -e " ${C_NEON_GREEN}✔ [SUCCESS]${NC} $message" ;;
        "INPUT")   echo -e " ${C_NEON_PINK}✦ [INPUT]${NC} $message" ;;
        *)         echo -e " [$type] $message" ;;
    esac
}

validate_input() {
    local type=$1
    local value=$2
    case $type in
        "number") [[ "$value" =~ ^[0-9]+$ ]] || { print_status "ERROR" "Must be a positive integer."; return 1; } ;;
        "cpu")
            if [[ "$value" =~ ^[0-9]+$ ]] && [ "$value" -ge 1 ] && [ "$value" -le 255 ]; then
                return 0
            else
                print_status "ERROR" "CPU cores must be between 1 and 255."
                return 1
            fi
            ;;
        "size") [[ "$value" =~ ^[0-9]+[GgMm]$ ]] || { print_status "ERROR" "Invalid disk size format (e.g. 20G)"; return 1; } ;;
        "port")
            if [[ "$value" =~ ^[0-9]+$ ]] && [ "$value" -ge 22 ] && [ "$value" -le 65535 ]; then
                return 0
            else
                print_status "ERROR" "Port must be 22-65535"; return 1;
            fi
            ;;
        "name") [[ "$value" =~ ^[a-zA-Z0-9_-]+$ ]] || { print_status "ERROR" "Only letters, numbers, hyphens allowed"; return 1; } ;;
        "username") [[ "$value" =~ ^[a-z_][a-z0-9_-]*$ ]] || { print_status "ERROR" "Invalid username format"; return 1; } ;;
    esac
    return 0
}

check_dependencies() {
    local deps=("qemu-system-x86_64" "wget" "cloud-localds" "qemu-img")
    local missing_deps=()
    for dep in "${deps[@]}"; do
        command -v "$dep" &> /dev/null || missing_deps+=("$dep")
    done
    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_status "WARN" "Installing missing dependencies..."
        sudo apt-get update && sudo apt-get install -y qemu-system-x86-64 qemu-utils cloud-image-utils wget
    fi
}

cleanup() {
    rm -f user-data meta-data
    tput cnorm 2>/dev/null || true
}

get_vm_list() {
    find "$VM_DIR" -maxdepth 1 -name "*.conf" -exec basename {} .conf \; 2>/dev/null | sort
}

load_vm_config() {
    local vm_name=$1
    local config_file="$VM_DIR/$vm_name.conf"
    if [[ -f "$config_file" ]]; then
        unset VM_NAME OS_TYPE CODENAME IMG_URL HOSTNAME USERNAME PASSWORD
        unset DISK_SIZE MEMORY CPUS SSH_PORT GUI_MODE PORT_FORWARDS IMG_FILE SEED_FILE CREATED
        source "$config_file"
        return 0
    else
        print_status "ERROR" "Configuration not found"
        return 1
    fi
}

save_vm_config() {
    local config_file="$VM_DIR/$VM_NAME.conf"
    cat > "$config_file" <<EOF
VM_NAME="$VM_NAME"
OS_TYPE="$OS_TYPE"
CODENAME="$CODENAME"
IMG_URL="$IMG_URL"
HOSTNAME="$HOSTNAME"
USERNAME="$USERNAME"
PASSWORD="$PASSWORD"
DISK_SIZE="$DISK_SIZE"
MEMORY="$MEMORY"
CPUS="$CPUS"
SSH_PORT="$SSH_PORT"
GUI_MODE="$GUI_MODE"
PORT_FORWARDS="$PORT_FORWARDS"
IMG_FILE="$IMG_FILE"
SEED_FILE="$SEED_FILE"
CREATED="$CREATED"
EOF
    print_status "SUCCESS" "Saved configuration."
}

setup_vm_image() {
    print_status "INFO" "Preparing OS base image..."
    mkdir -p "$VM_DIR"
    
    if [[ ! -f "$IMG_FILE" ]]; then
        print_status "INFO" "Downloading image..."
        wget --progress=bar:force "$IMG_URL" -O "$IMG_FILE.tmp"
        mv "$IMG_FILE.tmp" "$IMG_FILE"
    fi
    
    print_status "INFO" "Resizing disk to $DISK_SIZE..."
    qemu-img resize "$IMG_FILE" "$DISK_SIZE" 2>/dev/null || true

    print_status "INFO" "Generating Cloud-Init configuration..."
    cat > user-data <<EOF
#cloud-config
hostname: $HOSTNAME
ssh_pwauth: true
disable_root: false
users:
  - name: $USERNAME
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    password: $(openssl passwd -6 "$PASSWORD" | tr -d '\n')
chpasswd:
  list: |
    root:$PASSWORD
    $USERNAME:$PASSWORD
  expire: false
EOF

    cat > meta-data <<EOF
instance-id: iid-$VM_NAME
local-hostname: $HOSTNAME
EOF

    cloud-localds "$SEED_FILE" user-data meta-data
    print_status "SUCCESS" "VM '$VM_NAME' configured!"
}

create_new_vm() {
    echo -e "\n${C_YELLOW}Available Operating Systems:${NC}"
    local os_options=()
    local i=1
    for os in "${!OS_OPTIONS[@]}"; do
        echo -e "  ${C_CYAN}[$i]${NC} $os"
        os_options[$i]="$os"
        ((i++))
    done
    
    while true; do
        read -p "$(print_status "INPUT" "Select OS (1-${#OS_OPTIONS[@]}): ")" choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#OS_OPTIONS[@]} ]; then
            local os="${os_options[$choice]}"
            IFS='|' read -r OS_TYPE CODENAME IMG_URL DEFAULT_HOSTNAME DEFAULT_USERNAME DEFAULT_PASSWORD <<< "${OS_OPTIONS[$os]}"
            break
        fi
    done

    while true; do
        read -p "$(print_status "INPUT" "VM Name (default: $DEFAULT_HOSTNAME): ")" VM_NAME
        VM_NAME="${VM_NAME:-$DEFAULT_HOSTNAME}"
        if validate_input "name" "$VM_NAME"; then
            [[ -f "$VM_DIR/$VM_NAME.conf" ]] && print_status "ERROR" "VM name exists!" || break
        fi
    done

    while true; do
        read -p "$(print_status "INPUT" "Hostname (default: $VM_NAME): ")" HOSTNAME
        HOSTNAME="${HOSTNAME:-$VM_NAME}"
        validate_input "name" "$HOSTNAME" && break
    done

    while true; do
        read -p "$(print_status "INPUT" "Username (default: $DEFAULT_USERNAME): ")" USERNAME
        USERNAME="${USERNAME:-$DEFAULT_USERNAME}"
        validate_input "username" "$USERNAME" && break
    done

    read -s -p "$(print_status "INPUT" "Password (default: $DEFAULT_PASSWORD): ")" PASSWORD
    PASSWORD="${PASSWORD:-$DEFAULT_PASSWORD}"
    echo

    while true; do
        read -p "$(print_status "INPUT" "Disk Size (default: 20G): ")" DISK_SIZE
        DISK_SIZE="${DISK_SIZE:-20G}"
        validate_input "size" "$DISK_SIZE" && break
    done

    while true; do
        read -p "$(print_status "INPUT" "Memory in MB (default: 2048): ")" MEMORY
        MEMORY="${MEMORY:-2048}"
        validate_input "number" "$MEMORY" && break
    done

    while true; do
        read -p "$(print_status "INPUT" "CPU Cores [1-255] (default: 2): ")" CPUS
        CPUS="${CPUS:-2}"
        validate_input "cpu" "$CPUS" && break
    done

    while true; do
        read -p "$(print_status "INPUT" "SSH Port Forward (default: 2222): ")" SSH_PORT
        SSH_PORT="${SSH_PORT:-2222}"
        validate_input "port" "$SSH_PORT" && break
    done

    GUI_MODE=false
    read -p "$(print_status "INPUT" "Enable GUI Mode? (y/N): ")" gui_input
    [[ "$gui_input" =~ ^[Yy]$ ]] && GUI_MODE=true

    read -p "$(print_status "INPUT" "Additional Port Forwards (e.g., 8080:80): ")" PORT_FORWARDS

    IMG_FILE="$VM_DIR/$VM_NAME.img"
    SEED_FILE="$VM_DIR/$VM_NAME-seed.iso"
    CREATED="$(date)"

    setup_vm_image
    save_vm_config
}

start_vm() {
    local vm_name=$1
    if load_vm_config "$vm_name"; then
        echo -e "\n${C_BRIGHT_CYAN}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${C_BRIGHT_CYAN}║${NC} ${C_NEON_GREEN}${BOLD}LAUNCHING VIRTUAL MACHINE: $vm_name${NC}"
        echo -e "${C_BRIGHT_CYAN}╠══════════════════════════════════════════════════════════════════════════╣${NC}"
        echo -e "${C_BRIGHT_CYAN}║${NC} ${C_YELLOW}SSH Command :${NC} ssh -p $SSH_PORT $USERNAME@localhost"
        echo -e "${C_BRIGHT_CYAN}║${NC} ${C_YELLOW}Password    :${NC} $PASSWORD"
        echo -e "${C_BRIGHT_CYAN}╚══════════════════════════════════════════════════════════════════════════╝${NC}\n"
        
        # Acceleration & CPU Optimization Detection
        local accel_flags=("-machine" "q35,accel=kvm:tcg" "-cpu" "max")
        if [ -c /dev/kvm ] && [ -w /dev/kvm ]; then
            accel_flags=("-enable-kvm" "-cpu" "host")
            print_status "INFO" "Hardware KVM Acceleration: ENABLED 🚀"
        else
            print_status "WARN" "Software Emulation (KVM not available). Enabling Turbo TCG settings..."
        fi

        local qemu_cmd=(
            qemu-system-x86_64
            "${accel_flags[@]}"
            -m "$MEMORY"
            -smp "$CPUS"
            -drive "file=$IMG_FILE,format=qcow2,if=virtio,cache=writeback,aio=threads"
            -drive "file=$SEED_FILE,format=raw,if=virtio"
            -boot order=c
            -netdev "user,id=n0,hostfwd=tcp::$SSH_PORT-:22"
            -device virtio-net-pci,netdev=n0
        )

        if [[ -n "${PORT_FORWARDS:-}" ]]; then
            IFS=',' read -ra forwards <<< "$PORT_FORWARDS"
            local idx=1
            for forward in "${forwards[@]}"; do
                IFS=':' read -r host_port guest_port <<< "$forward"
                qemu_cmd+=(-netdev "user,id=n${idx},hostfwd=tcp::$host_port-:$guest_port" -device "virtio-net-pci,netdev=n${idx}")
                ((idx++))
            done
        fi

        if [[ "$GUI_MODE" == true ]]; then
            qemu_cmd+=(-vga virtio -display gtk)
        else
            qemu_cmd+=(-nographic -serial mon:stdio)
        fi

        print_status "INFO" "Booting VM Kernel..."
        "${qemu_cmd[@]}"
    fi
}

is_vm_running() {
    pgrep -f "qemu-system-x86_64.*$1.img" >/dev/null
}

stop_vm() {
    local vm_name=$1
    if load_vm_config "$vm_name"; then
        if is_vm_running "$vm_name"; then
            print_status "INFO" "Stopping VM: $vm_name"
            pkill -f "qemu-system-x86_64.*$IMG_FILE"
            print_status "SUCCESS" "VM stopped."
        else
            print_status "INFO" "VM is not running."
        fi
    fi
}

delete_vm() {
    local vm_name=$1
    read -p "$(print_status "WARN" "Delete VM '$vm_name'? (y/N): ")" -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if load_vm_config "$vm_name"; then
            rm -f "$IMG_FILE" "$SEED_FILE" "$VM_DIR/$vm_name.conf"
            print_status "SUCCESS" "VM deleted."
        fi
    fi
}

show_vm_info() {
    local vm_name=$1
    if load_vm_config "$vm_name"; then
        echo -e "\n${C_MAGENTA}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${C_MAGENTA}║${NC} ${C_BRIGHT_CYAN}${BOLD}SPECIFICATIONS FOR: $vm_name${NC}"
        echo -e "${C_MAGENTA}╠══════════════════════════════════════════════════════════════════════════╣${NC}"
        printf "${C_MAGENTA}║${NC} %-15s : %-53s ${C_MAGENTA}║${NC}\n" "OS Base" "$OS_TYPE"
        printf "${C_MAGENTA}║${NC} %-15s : %-53s ${C_MAGENTA}║${NC}\n" "Hostname" "$HOSTNAME"
        printf "${C_MAGENTA}║${NC} %-15s : %-53s ${C_MAGENTA}║${NC}\n" "Username" "$USERNAME"
        printf "${C_MAGENTA}║${NC} %-15s : %-53s ${C_MAGENTA}║${NC}\n" "SSH Port" "$SSH_PORT"
        printf "${C_MAGENTA}║${NC} %-15s : %-53s ${C_MAGENTA}║${NC}\n" "RAM" "$MEMORY MB"
        printf "${C_MAGENTA}║${NC} %-15s : %-53s ${C_MAGENTA}║${NC}\n" "CPUs" "$CPUS Cores"
        printf "${C_MAGENTA}║${NC} %-15s : %-53s ${C_MAGENTA}║${NC}\n" "Disk" "$DISK_SIZE"
        echo -e "${C_MAGENTA}╚══════════════════════════════════════════════════════════════════════════╝${NC}\n"
        read -p "$(print_status "INPUT" "Press [Enter] to return...")"
    fi
}

main_menu() {
    while true; do
        display_header
        local vms=($(get_vm_list))
        local vm_count=${#vms[@]}
        
        if [ $vm_count -gt 0 ]; then
            echo -e " ${C_BRIGHT_CYAN}${BOLD}EXISTING VIRTUAL MACHINES:${NC}"
            for i in "${!vms[@]}"; do
                local status_badge="${BG_RED} STOPPED ${NC}"
                is_vm_running "${vms[$i]}" && status_badge="${BG_GREEN} RUNNING ${NC}"
                printf "   ${C_NEON_PINK}[%d]${NC} %-25s %b\n" $((i+1)) "${vms[$i]}" "$status_badge"
            done
            echo
        fi
        
        echo -e " ${C_YELLOW}${BOLD}DISKNOGAMERZ CONTROL OPTIONS:${NC}"
        echo -e "   ${C_CYAN}[1]${NC} ➕ Create New VM"
        if [ $vm_count -gt 0 ]; then
            echo -e "   ${C_CYAN}[2]${NC} ▶  Start VM"
            echo -e "   ${C_CYAN}[3]${NC} ⏹  Stop VM"
            echo -e "   ${C_CYAN}[4]${NC} ℹ  Show Spec Info"
            echo -e "   ${C_CYAN}[5]${NC} 🗑  Delete VM"
        fi
        echo -e "   ${C_CYAN}[0]${NC} 🚪 Exit Manager"
        echo
        
        read -p "$(print_status "INPUT" "Select Option: ")" choice
        case $choice in
            1) create_new_vm ;;
            2) 
               read -p "$(print_status "INPUT" "Enter VM index to START: ")" vm_num
               [[ "$vm_num" =~ ^[0-9]+$ ]] && [ "$vm_num" -le $vm_count ] && start_vm "${vms[$((vm_num-1))]}"
               ;;
            3)
               read -p "$(print_status "INPUT" "Enter VM index to STOP: ")" vm_num
               [[ "$vm_num" =~ ^[0-9]+$ ]] && [ "$vm_num" -le $vm_count ] && stop_vm "${vms[$((vm_num-1))]}"
               ;;
            4)
               read -p "$(print_status "INPUT" "Enter VM index: ")" vm_num
               [[ "$vm_num" =~ ^[0-9]+$ ]] && [ "$vm_num" -le $vm_count ] && show_vm_info "${vms[$((vm_num-1))]}"
               ;;
            5)
               read -p "$(print_status "INPUT" "Enter VM index to DELETE: ")" vm_num
               [[ "$vm_num" =~ ^[0-9]+$ ]] && [ "$vm_num" -le $vm_count ] && delete_vm "${vms[$((vm_num-1))]}"
               ;;
            0) exit 0 ;;
        esac
        read -p "$(print_status "INPUT" "Press [Enter] to continue...")"
    done
}

trap cleanup EXIT
VM_DIR="${VM_DIR:-$HOME/disknogamerz-vms}"
mkdir -p "$VM_DIR"

check_dependencies
main_menu
