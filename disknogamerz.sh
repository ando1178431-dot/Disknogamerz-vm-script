#!/bin/bash

# ╔══════════════════════════════════════════════════════════════╗
# ║                 DISKNOGAMERZ VM MANAGER                      ║
# ║            Professional Multi-VM Virtualization             ║
# ╚══════════════════════════════════════════════════════════════╝

# Supported OS Cloud Images
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

    cat << 'EOF'
  ___  _ ____ _  _ _  _ ____ ____ ____ _  _ ____ ____ ____ 
  |  \ | |___ |_/  |\ | |  | | __ |__| |\/| |___ |__/  __/ 
  |__/ | ____||  \_| \| |__| |__] |  | |  | |___ |  \ /___ 
EOF

    echo
    printf "\e[1;35m══════════════════════════════════════════════════════════════════════════════════════\e[0m\n"
    printf "\e[1;37m                 DISKNOGAMERZ VIRTUAL MACHINE CONTROL CENTER\e[0m\n"
    printf "\e[1;90m                    Powered by QEMU • KVM • Cloud-Init • Linux\e[0m\n"
    echo

    printf "\e[1;36m Hostname      \e[0m : %s\n" "$(hostname)"
    printf "\e[1;36m User          \e[0m : %s\n" "$(whoami)"
    printf "\e[1;36m Kernel        \e[0m : %s\n" "$(uname -r)"
    printf "\e[1;36m Architecture  \e[0m : %s\n" "$(uname -m)"
    printf "\e[1;36m Date          \e[0m : %s\n" "$(date '+%d %b %Y %I:%M:%S %p')"
    printf "\e[1;35m────────────────────────────────────────────────────────────────────────────────────\e[0m\n"
    echo
}

print_status() {
    local type=$1
    local message=$2
    case $type in
        "INFO") echo -e "\033[1;34m[INFO]\033[0m $message" ;;
        "WARN") echo -e "\033[1;33m[WARN]\033[0m $message" ;;
        "ERROR") echo -e "\033[1;31m[ERROR]\033[0m $message" ;;
        "SUCCESS") echo -e "\033[1;32m[SUCCESS]\033[0m $message" ;;
        "INPUT") echo -e "\033[1;36m[INPUT]\033[0m $message" ;;
        *) echo "[$type] $message" ;;
    esac
}

validate_input() {
    local type=$1
    local value=$2
    case $type in
        "number")
            [[ "$value" =~ ^[0-9]+$ ]] || { print_status "ERROR" "Must be a valid positive integer"; return 1; }
            ;;
        "size")
            [[ "$value" =~ ^[0-9]+[GgMm]$ ]] || { print_status "ERROR" "Invalid disk size format! Example: 20G or 2048M"; return 1; }
            ;;
        "port")
            if [[ "$value" =~ ^[0-9]+$ ]] && [ "$value" -ge 22 ] && [ "$value" -le 65535 ]; then
                return 0
            else
                print_status "ERROR" "Port must be a number between 22 and 65535"
                return 1
            fi
            ;;
        "name")
            [[ "$value" =~ ^[a-zA-Z0-9_-]+$ ]] || { print_status "ERROR" "Only letters, numbers, hyphens, and underscores allowed"; return 1; }
            ;;
        "username")
            [[ "$value" =~ ^[a-z_][a-z0-9_-]*$ ]] || { print_status "ERROR" "Must start with a lowercase letter and contain no special characters"; return 1; }
            ;;
    esac
    return 0
}

check_dependencies() {
    local deps=("qemu-system-x86_64" "wget" "cloud-localds" "qemu-img")
    local missing_deps=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_status "WARN" "Missing required tools: ${missing_deps[*]}"
        read -p "$(print_status "INPUT" "Attempt to install dependencies automatically via apt? (y/N): ")" -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            sudo apt-get update && sudo apt-get install -y qemu-system-x86-64 qemu-utils cloud-image-utils wget
        else
            print_status "ERROR" "Cannot proceed without required dependencies."
            exit 1
        fi
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
        print_status "ERROR" "Configuration for VM '$vm_name' not found"
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
    print_status "SUCCESS" "Configuration saved to $config_file"
}

setup_vm_image() {
    print_status "INFO" "Preparing OS base image..."
    mkdir -p "$VM_DIR"
    
    if [[ ! -f "$IMG_FILE" ]]; then
        print_status "INFO" "Downloading base image from $IMG_URL..."
        wget --progress=bar:force "$IMG_URL" -O "$IMG_FILE.tmp"
        mv "$IMG_FILE.tmp" "$IMG_FILE"
    fi
    
    print_status "INFO" "Setting disk capacity to $DISK_SIZE..."
    qemu-img resize "$IMG_FILE" "$DISK_SIZE" 2>/dev/null || true

    print_status "INFO" "Generating Cloud-Init config..."
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
    print_status "SUCCESS" "VM '$VM_NAME' configured successfully."
}

create_new_vm() {
    print_status "INFO" "Creating a new VM"
    
    echo "Available Operating Systems:"
    local os_options=()
    local i=1
    for os in "${!OS_OPTIONS[@]}"; do
        echo "  $i) $os"
        os_options[$i]="$os"
        ((i++))
    done
    
    while true; do
        read -p "$(print_status "INPUT" "Select OS (1-${#OS_OPTIONS[@]}): ")" choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#OS_OPTIONS[@]} ]; then
            local os="${os_options[$choice]}"
            IFS='|' read -r OS_TYPE CODENAME IMG_URL DEFAULT_HOSTNAME DEFAULT_USERNAME DEFAULT_PASSWORD <<< "${OS_OPTIONS[$os]}"
            break
        else
            print_status "ERROR" "Invalid selection."
        fi
    done

    while true; do
        read -p "$(print_status "INPUT" "VM Name (default: $DEFAULT_HOSTNAME): ")" VM_NAME
        VM_NAME="${VM_NAME:-$DEFAULT_HOSTNAME}"
        if validate_input "name" "$VM_NAME"; then
            if [[ -f "$VM_DIR/$VM_NAME.conf" ]]; then
                print_status "ERROR" "VM name already exists"
            else
                break
            fi
        fi
    done

    while true; do
        read -p "$(print_status "INPUT" "Hostname (default: $VM_NAME): ")" HOSTNAME
        HOSTNAME="${HOSTNAME:-$VM_NAME}"
        if validate_input "name" "$HOSTNAME"; then break; fi
    done

    while true; do
        read -p "$(print_status "INPUT" "Username (default: $DEFAULT_USERNAME): ")" USERNAME
        USERNAME="${USERNAME:-$DEFAULT_USERNAME}"
        if validate_input "username" "$USERNAME"; then break; fi
    done

    read -s -p "$(print_status "INPUT" "Password (default: $DEFAULT_PASSWORD): ")" PASSWORD
    PASSWORD="${PASSWORD:-$DEFAULT_PASSWORD}"
    echo

    while true; do
        read -p "$(print_status "INPUT" "Disk Size e.g., 20G (default: 20G): ")" DISK_SIZE
        DISK_SIZE="${DISK_SIZE:-20G}"
        if validate_input "size" "$DISK_SIZE"; then break; fi
    done

    while true; do
        read -p "$(print_status "INPUT" "Memory in MB e.g., 2048 (default: 2048): ")" MEMORY
        MEMORY="${MEMORY:-2048}"
        if validate_input "number" "$MEMORY"; then break; fi
    done

    while true; do
        read -p "$(print_status "INPUT" "CPU Cores e.g., 2 (default: 2): ")" CPUS
        CPUS="${CPUS:-2}"
        if validate_input "number" "$CPUS"; then break; fi
    done

    while true; do
        read -p "$(print_status "INPUT" "SSH Port Forward e.g., 2222 (default: 2222): ")" SSH_PORT
        SSH_PORT="${SSH_PORT:-2222}"
        if validate_input "port" "$SSH_PORT"; then break; fi
    done

    GUI_MODE=false
    read -p "$(print_status "INPUT" "Enable GUI mode? (y/N): ")" gui_input
    [[ "$gui_input" =~ ^[Yy]$ ]] && GUI_MODE=true

    while true; do
        read -p "$(print_status "INPUT" "Additional Port Forwards (e.g., 8080:80, press Enter for none): ")" PORT_FORWARDS
        if [[ -z "$PORT_FORWARDS" ]]; then
            break
        fi
        
        valid=true
        IFS=',' read -ra forwards <<< "$PORT_FORWARDS"
        for forward in "${forwards[@]}"; do
            if [[ ! "$forward" =~ ^[0-9]+:[0-9]+$ ]]; then
                valid=false
                break
            fi
        done

        if $valid; then
            break
        else
            print_status "ERROR" "Invalid port format! Must be in format host:guest (e.g., 8080:80 or 8080:80,9090:90)"
        fi
    done

    IMG_FILE="$VM_DIR/$VM_NAME.img"
    SEED_FILE="$VM_DIR/$VM_NAME-seed.iso"
    CREATED="$(date)"

    setup_vm_image
    save_vm_config
}

start_vm() {
    local vm_name=$1
    if load_vm_config "$vm_name"; then
        print_status "INFO" "Starting VM: $vm_name"
        print_status "INFO" "SSH Connection: ssh -p $SSH_PORT $USERNAME@localhost"
        print_status "INFO" "Password: $PASSWORD"
        
        local qemu_cmd=(
            qemu-system-x86_64
            -m "$MEMORY"
            -smp "$CPUS"
            -drive "file=$IMG_FILE,format=qcow2,if=virtio"
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

        print_status "INFO" "Executing QEMU..."
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
            print_status "SUCCESS" "VM process terminated."
        else
            print_status "INFO" "VM $vm_name is not running."
        fi
    fi
}

delete_vm() {
    local vm_name=$1
    read -p "$(print_status "WARN" "Delete VM '$vm_name' permanently? (y/N): ")" -n 1 -r
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
        echo
        print_status "INFO" "VM Configuration Details ($vm_name):"
        echo "=========================================="
        echo "OS          : $OS_TYPE"
        echo "Hostname    : $HOSTNAME"
        echo "Username    : $USERNAME"
        echo "SSH Port    : $SSH_PORT"
        echo "Memory      : $MEMORY MB"
        echo "CPUs        : $CPUS Cores"
        echo "Disk Size   : $DISK_SIZE"
        echo "GUI Mode    : $GUI_MODE"
        echo "Port Fwds   : ${PORT_FORWARDS:-None}"
        echo "Created     : $CREATED"
        echo "=========================================="
        read -p "$(print_status "INPUT" "Press Enter to return...")"
    fi
}

main_menu() {
    while true; do
        display_header
        local vms=($(get_vm_list))
        local vm_count=${#vms[@]}
        
        if [ $vm_count -gt 0 ]; then
            print_status "INFO" "Existing Virtual Machines:"
            for i in "${!vms[@]}"; do
                local status="Stopped"
                is_vm_running "${vms[$i]}" && status="Running"
                printf "  %2d) %-15s [%s]\n" $((i+1)) "${vms[$i]}" "$status"
            done
            echo
        fi
        
        echo "Disknogamerz Control Menu:"
        echo "  1) Create New VM"
        if [ $vm_count -gt 0 ]; then
            echo "  2) Start VM"
            echo "  3) Stop VM"
            echo "  4) Show VM Details"
            echo "  5) Delete VM"
        fi
        echo "  0) Exit"
        echo
        
        read -p "$(print_status "INPUT" "Select an option: ")" choice
        case $choice in
            1) create_new_vm ;;
            2) 
               read -p "$(print_status "INPUT" "Enter VM index number to start: ")" vm_num
               if [[ "$vm_num" =~ ^[0-9]+$ ]] && [ "$vm_num" -ge 1 ] && [ "$vm_num" -le $vm_count ]; then
                   start_vm "${vms[$((vm_num-1))]}"
               else
                   print_status "ERROR" "Invalid VM number."
               fi
               ;;
            3)
               read -p "$(print_status "INPUT" "Enter VM index number to stop: ")" vm_num
               if [[ "$vm_num" =~ ^[0-9]+$ ]] && [ "$vm_num" -ge 1 ] && [ "$vm_num" -le $vm_count ]; then
                   stop_vm "${vms[$((vm_num-1))]}"
               else
                   print_status "ERROR" "Invalid VM number."
               fi
               ;;
            4)
               read -p "$(print_status "INPUT" "Enter VM index number: ")" vm_num
               if [[ "$vm_num" =~ ^[0-9]+$ ]] && [ "$vm_num" -ge 1 ] && [ "$vm_num" -le $vm_count ]; then
                   show_vm_info "${vms[$((vm_num-1))]}"
               else
                   print_status "ERROR" "Invalid VM number."
               fi
               ;;
            5)
               read -p "$(print_status "INPUT" "Enter VM index number to delete: ")" vm_num
               if [[ "$vm_num" =~ ^[0-9]+$ ]] && [ "$vm_num" -ge 1 ] && [ "$vm_num" -le $vm_count ]; then
                   delete_vm "${vms[$((vm_num-1))]}"
               else
                   print_status "ERROR" "Invalid VM number."
               fi
               ;;
            0) print_status "INFO" "Exiting Disknogamerz VM Manager."; exit 0 ;;
            *) print_status "ERROR" "Invalid option." ;;
        esac
        read -p "$(print_status "INPUT" "Press Enter to continue...")"
    done
}

trap cleanup EXIT
VM_DIR="${VM_DIR:-$HOME/disknogamerz-vms}"
mkdir -p "$VM_DIR"

check_dependencies
main_menu
