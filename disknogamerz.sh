#!/bin/bash
set -euo pipefail

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║                      DISKNOGAMERZ VM MANAGER v5.0                         ║
# ║                  Next-Gen Enterprise Virtualization CLI                  ║
# ╚═══════════════════════════════════════════════════════════════════════════╝

# ─────────────────────────────────────────────────────────────────────────────
# COLOR & STYLE DEFINITIONS
# ─────────────────────────────────────────────────────────────────────────────
readonly RESET="\033[0m"
readonly BOLD="\033[1m"
readonly DIM="\033[2m"
readonly ITALIC="\033[3m"
readonly UNDERLINE="\033[4m"

# Foreground Colors
readonly FG_BLACK="\033[30m"
readonly FG_RED="\033[31m"
readonly FG_GREEN="\033[32m"
readonly FG_YELLOW="\033[33m"
readonly FG_BLUE="\033[34m"
readonly FG_MAGENTA="\033[35m"
readonly FG_CYAN="\033[36m"
readonly FG_WHITE="\033[37m"
readonly FG_GRAY="\033[90m"
readonly FG_LIGHT_CYAN="\033[96m"
readonly FG_LIGHT_WHITE="\033[97m"

# Background Colors
readonly BG_BLUE="\033[44m"
readonly BG_MAGENTA="\033[45m"
readonly BG_CYAN="\033[46m"
readonly BG_DARK_GRAY="\033[100m"

# Icons & Symbols
readonly ICON_CHECK="${FG_GREEN}✔${RESET}"
readonly ICON_CROSS="${FG_RED}✖${RESET}"
readonly ICON_WARN="${FG_YELLOW}⚠${RESET}"
readonly ICON_INFO="${FG_CYAN}ℹ${RESET}"
readonly ICON_RUNNING="${FG_GREEN}●${RESET}"
readonly ICON_STOPPED="${FG_RED}○${RESET}"
readonly ICON_GEAR="${FG_CYAN}⚙${RESET}"
readonly ICON_ARROW="${FG_LIGHT_CYAN}❯${RESET}"

# ─────────────────────────────────────────────────────────────────────────────
# SYSTEM & HELPER FUNCTIONS
# ─────────────────────────────────────────────────────────────────────────────

cleanup() {
    tput cnorm 2>/dev/null || true
    rm -f user-data meta-data 2>/dev/null || true
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
        *)         echo -e " [$type] $message" ;;
    esac
}

display_header() {
    clear
    tput civis 2>/dev/null || true

    # Big ASCII Logo
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
    echo -e "${FG_MAGENTA}│${RESET}  ${BOLD}${FG_LIGHT_CYAN}❖  DISKNOGAMERZ VM MANAGER v5.0${RESET}  ${FG_GRAY}•${RESET}  ${FG_LIGHT_WHITE}Enterprise Virtualization Platform${RESET}                      ${FG_MAGENTA}│${RESET}"
    echo -e "${FG_MAGENTA}╰──────────────────────────────────────────────────────────────────────────────────────────────────╯${RESET}"
    
    # System Telemetry Bar
    local host_str="$(hostname)"
    local user_str="$(whoami)"
    local kernel_str="$(uname -r)"
    local date_str="$(date '+%d %b %Y, %I:%M %p')"

    echo -e " ${FG_GRAY}Host:${RESET} ${BOLD}$host_str${RESET} ${FG_GRAY}│${RESET} ${FG_GRAY}User:${RESET} ${BOLD}$user_str${RESET} ${FG_GRAY}│${RESET} ${FG_GRAY}Kernel:${RESET} ${BOLD}$kernel_str${RESET} ${FG_GRAY}│${RESET} ${FG_GRAY}Date:${RESET} ${BOLD}$date_str${RESET}"
    echo -e "${FG_GRAY}────────────────────────────────────────────────────────────────────────────────────────────────────${RESET}"
}

display_boot_animation() {
    display_header
    echo -e "\n ${BOLD}${FG_CYAN}Initializing Hypervisor Environment${RESET}\n"

    local steps=(
        "Loading Hypervisor Engine"
        "Detecting CPU Virtualization"
        "Initializing Cloud-Init Engine"
        "Loading Storage Subsystem"
        "Verifying Network Interface"
        "Scanning Virtual Machines"
    )

    for step in "${steps[@]}"; do
        printf "  %-38s " "${step}..."
        for _ in {1..8}; do
            printf "${FG_CYAN}━${RESET}"
            sleep 0.008
        done
        printf " ${FG_GREEN}READY${RESET}\n"
    done
    echo
    sleep 0.2
}

validate_input() {
    local type=$1
    local value=$2
    
    case $type in
        "number")
            if ! [[ "$value" =~ ^[0-9]+$ ]]; then
                print_status "ERROR" "Must be a valid positive integer."
                return 1
            fi
            ;;
        "size")
            if ! [[ "$value" =~ ^[0-9]+[GgMm]$ ]]; then
                print_status "ERROR" "Must be a valid size (e.g., 20G, 512M)."
                return 1
            fi
            ;;
        "port")
            if ! [[ "$value" =~ ^[0-9]+$ ]] || [ "$value" -lt 22 ] || [ "$value" -gt 65535 ]; then
                print_status "ERROR" "Must be a valid port number (22-65535)."
                return 1
            fi
            ;;
        "name")
            if ! [[ "$value" =~ ^[a-zA-Z0-9_-]+$ ]]; then
                print_status "ERROR" "Name can only contain alphanumeric characters, hyphens, and underscores."
                return 1
            fi
            ;;
        "username")
            if ! [[ "$value" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
                print_status "ERROR" "Username must start with a lowercase letter/underscore and contain valid characters."
                return 1
            fi
            ;;
    esac
    return 0
}

check_dependencies() {
    local deps=("qemu-system-x86_64" "wget" "cloud-localds" "qemu-img" "openssl")
    local missing_deps=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        display_header
        print_status "ERROR" "Missing required dependencies: ${BOLD}${missing_deps[*]}${RESET}"
        print_status "INFO" "Install them using:"
        echo -e "\n   ${FG_YELLOW}sudo apt update && sudo apt install -y qemu-system-x86 cloud-image-utils wget qemu-utils openssl${RESET}\n"
        exit 1
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# CONFIGURATION & DISK MANAGEMENT
# ─────────────────────────────────────────────────────────────────────────────

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
        print_status "ERROR" "Configuration file for '${vm_name}' not found."
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
    echo
    print_status "INFO" "Preparing base virtual disk image..."
    mkdir -p "$VM_DIR"
    
    if [[ ! -f "$IMG_FILE" ]]; then
        print_status "INFO" "Downloading cloud image from remote source..."
        echo -e " ${FG_GRAY}URL: $IMG_URL${RESET}"
        if ! wget --progress=bar:force:noscroll "$IMG_URL" -O "$IMG_FILE.tmp"; then
            print_status "ERROR" "Failed to download image from source URL."
            rm -f "$IMG_FILE.tmp"
            exit 1
        fi
        mv "$IMG_FILE.tmp" "$IMG_FILE"
    else
        print_status "INFO" "Base image file detected locally. Skipping download."
    fi
    
    print_status "INFO" "Expanding disk image to target capacity ($DISK_SIZE)..."
    qemu-img resize "$IMG_FILE" "$DISK_SIZE" &>/dev/null || true

    print_status "INFO" "Generating Cloud-Init user-data and meta-data ISO..."
    cat > user-data <<EOF
#cloud-config
hostname: $HOSTNAME
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
local-hostname: $HOSTNAME
EOF

    if ! cloud-localds "$SEED_FILE" user-data meta-data; then
        print_status "ERROR" "Failed to construct Cloud-Init ISO seed image."
        exit 1
    fi
    
    rm -f user-data meta-data
    print_status "SUCCESS" "Cloud-Init initialization image successfully built."
}

is_vm_running() {
    local vm_name=$1
    pgrep -f "qemu-system-x86_64.*$vm_name\.qcow2" >/dev/null 2>&1
}

# ─────────────────────────────────────────────────────────────────────────────
# CORE VM OPERATIONAL ACTIONS
# ─────────────────────────────────────────────────────────────────────────────

create_new_vm() {
    display_header
    echo -e " ${BOLD}${FG_LIGHT_CYAN}╭──────────────────────────────────────────────────────────╮${RESET}"
    echo -e " ${BOLD}${FG_LIGHT_CYAN}│                   CREATE NEW VIRTUAL MACHINE             │${RESET}"
    echo -e " ${BOLD}${FG_LIGHT_CYAN}╰──────────────────────────────────────────────────────────╯${RESET}\n"
    
    local os_keys=("${!OS_OPTIONS[@]}")
    print_status "INFO" "Select Operating System Template:"
    echo
    
    for i in "${!os_keys[@]}"; do
        printf "   ${BOLD}${FG_CYAN}%2d)${RESET} %-35s\n" "$((i+1))" "${os_keys[$i]}"
    done
    echo
    
    local choice
    while true; do
        print_status "INPUT" "Select OS option (1-${#os_keys[@]}): "
        read -r choice || choice=""
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#os_keys[@]}" ]; then
            local os="${os_keys[$((choice-1))]}"
            IFS='|' read -r OS_TYPE CODENAME IMG_URL DEFAULT_HOSTNAME DEFAULT_USERNAME DEFAULT_PASSWORD <<< "${OS_OPTIONS[$os]}"
            break
        else
            print_status "ERROR" "Invalid choice. Please select between 1 and ${#os_keys[@]}."
        fi
    done

    echo
    while true; do
        print_status "INPUT" "VM Identifier [Default: $DEFAULT_HOSTNAME]: "
        read -r VM_NAME || VM_NAME=""
        VM_NAME="${VM_NAME:-$DEFAULT_HOSTNAME}"
        if validate_input "name" "$VM_NAME"; then
            if [[ -f "$VM_DIR/$VM_NAME.conf" ]]; then
                print_status "ERROR" "A virtual machine with name '$VM_NAME' already exists."
            else
                break
            fi
        fi
    done

    while true; do
        print_status "INPUT" "System Hostname [Default: $VM_NAME]: "
        read -r HOSTNAME || HOSTNAME=""
        HOSTNAME="${HOSTNAME:-$VM_NAME}"
        if validate_input "name" "$HOSTNAME"; then break; fi
    done

    while true; do
        print_status "INPUT" "Admin Username [Default: $DEFAULT_USERNAME]: "
        read -r USERNAME || USERNAME=""
        USERNAME="${USERNAME:-$DEFAULT_USERNAME}"
        if validate_input "username" "$USERNAME"; then break; fi
    done

    while true; do
        print_status "INPUT" "Admin Password [Default: $DEFAULT_PASSWORD]: "
        read -rs PASSWORD || PASSWORD=""
        PASSWORD="${PASSWORD:-$DEFAULT_PASSWORD}"
        echo
        if [ -n "$PASSWORD" ]; then break; else print_status "ERROR" "Password cannot be empty."; fi
    done

    while true; do
        print_status "INPUT" "Virtual Disk Size [Default: 20G]: "
        read -r DISK_SIZE || DISK_SIZE=""
        DISK_SIZE="${DISK_SIZE:-20G}"
        if validate_input "size" "$DISK_SIZE"; then break; fi
    done

    while true; do
        print_status "INPUT" "RAM Allocation in MB [Default: 2048]: "
        read -r MEMORY || MEMORY=""
        MEMORY="${MEMORY:-2048}"
        if validate_input "number" "$MEMORY"; then break; fi
    done

    while true; do
        print_status "INPUT" "CPU Cores [Default: 2]: "
        read -r CPUS || CPUS=""
        CPUS="${CPUS:-2}"
        if validate_input "number" "$CPUS"; then break; fi
    done

    while true; do
        print_status "INPUT" "SSH Host Forward Port [Default: 2222]: "
        read -r SSH_PORT || SSH_PORT=""
        SSH_PORT="${SSH_PORT:-2222}"
        if validate_input "port" "$SSH_PORT"; then
            if ss -tln 2>/dev/null | grep -q ":$SSH_PORT "; then
                print_status "ERROR" "Port $SSH_PORT is currently bound by host system."
            else
                break
            fi
        fi
    done

    while true; do
        print_status "INPUT" "Enable Graphical Display (GUI)? (y/N) [Default: N]: "
        read -r gui_input || gui_input=""
        gui_input="${gui_input:-n}"
        if [[ "$gui_input" =~ ^[Yy]$ ]]; then 
            GUI_MODE=true
            break
        elif [[ "$gui_input" =~ ^[Nn]$ ]]; then
            GUI_MODE=false
            break
        fi
    done

    print_status "INPUT" "Additional Forward Ports (e.g., 8080:80,8443:443) [Optional]: "
    read -r PORT_FORWARDS || PORT_FORWARDS=""

    IMG_FILE="$VM_DIR/$VM_NAME.qcow2"
    SEED_FILE="$VM_DIR/$VM_NAME-seed.iso"
    CREATED="$(date)"

    setup_vm_image
    save_vm_config
}

start_vm() {
    local vm_name=$1
    if load_vm_config "$vm_name"; then
        if is_vm_running "$vm_name"; then
            print_status "WARN" "Virtual Machine '$vm_name' is already active!"
            return 0
        fi

        echo
        print_status "INFO" "Booting Virtual Machine: ${BOLD}$vm_name${RESET}"
        echo -e " ${FG_GRAY}─────────────────────────────────────────────────────────${RESET}"
        echo -e "  ${BOLD}SSH Command:${RESET} ${FG_CYAN}ssh -p $SSH_PORT $USERNAME@localhost${RESET}"
        echo -e "  ${BOLD}Credentials:${RESET} ${FG_GRAY}User:${RESET} $USERNAME ${FG_GRAY}│ Password:${RESET} $PASSWORD"
        echo -e " ${FG_GRAY}─────────────────────────────────────────────────────────${RESET}\n"
        
        local qemu_cmd=(
            qemu-system-x86_64
            -m "$MEMORY"
            -smp "$CPUS"
            -cpu host
            -enable-kvm
            -drive "file=$IMG_FILE,format=qcow2,if=virtio"
            -drive "file=$SEED_FILE,format=raw,if=virtio"
            -boot order=c
            -device virtio-net-pci,netdev=n0
            -netdev "user,id=n0,hostfwd=tcp::$SSH_PORT-:22"
        )

        # KVM hardware virtualization fallback check
        if ! [ -w /dev/kvm ]; then
            print_status "WARN" "/dev/kvm unreadable or missing. Falling back to software emulation (qemu64)..."
            qemu_cmd=("${qemu_cmd[@]/-enable-kvm/}")
            qemu_cmd=("${qemu_cmd[@]/-cpu host/-cpu qemu64}")
        fi

        if [[ -n "$PORT_FORWARDS" ]]; then
            IFS=',' read -ra forwards <<< "$PORT_FORWARDS"
            local p_idx=1
            for forward in "${forwards[@]}"; do
                IFS=':' read -r host_port guest_port <<< "$forward"
                qemu_cmd+=(-device "virtio-net-pci,netdev=n$p_idx")
                qemu_cmd+=(-netdev "user,id=n$p_idx,hostfwd=tcp::$host_port-:$guest_port")
                ((p_idx++))
            done
        fi

        if [[ "$GUI_MODE" == true ]]; then
            qemu_cmd+=(-vga virtio -display gtk)
        else
            qemu_cmd+=(-nographic -serial mon:stdio)
        fi

        qemu_cmd+=(
            -device virtio-balloon-pci
            -object rng-random,filename=/dev/urandom,id=rng0
            -device virtio-rng-pci,rng=rng0
        )

        tput cnorm 2>/dev/null || true
        "${qemu_cmd[@]}" || print_status "ERROR" "QEMU execution exited with error code."
        print_status "INFO" "Virtual Machine '$vm_name' execution ended."
    fi
}

stop_vm() {
    local vm_name=$1
    if load_vm_config "$vm_name"; then
        if is_vm_running "$vm_name"; then
            print_status "INFO" "Sending SIGTERM to VM process: ${BOLD}$vm_name${RESET}..."
            pkill -f "qemu-system-x86_64.*$vm_name\.qcow2" || true
            sleep 2
            if is_vm_running "$vm_name"; then
                print_status "WARN" "Process non-responsive. Issuing SIGKILL..."
                pkill -9 -f "qemu-system-x86_64.*$vm_name\.qcow2" || true
            fi
            print_status "SUCCESS" "Virtual Machine '$vm_name' stopped."
        else
            print_status "INFO" "Virtual Machine '$vm_name' is not currently running."
        fi
    fi
}

show_vm_info() {
    local vm_name=$1
    if load_vm_config "$vm_name"; then
        echo
        echo -e " ${BOLD}${FG_CYAN}╭──────────────────────────────────────────────────────────────────────────╮${RESET}"
        echo -e " ${BOLD}${FG_CYAN}│                     VM CONFIGURATION OVERVIEW                            │${RESET}"
        echo -e " ${BOLD}${FG_CYAN}╰──────────────────────────────────────────────────────────────────────────╯${RESET}"
        
        printf "  %-18s : ${BOLD}%s${RESET} (%s)\n" "OS Platform" "$OS_TYPE" "$CODENAME"
        printf "  %-18s : ${BOLD}%s${RESET}\n" "Hostname" "$HOSTNAME"
        printf "  %-18s : ${BOLD}%s${RESET}\n" "Admin Account" "$USERNAME"
        printf "  %-18s : ${BOLD}%s${RESET}\n" "Password" "$PASSWORD"
        printf "  %-18s : ${BOLD}%s${RESET}\n" "SSH Host Port" "$SSH_PORT"
        printf "  %-18s : ${BOLD}%s MB${RESET}\n" "RAM Memory" "$MEMORY"
        printf "  %-18s : ${BOLD}%s Cores${RESET}\n" "CPU Allocation" "$CPUS"
        printf "  %-18s : ${BOLD}%s${RESET}\n" "Virtual Disk" "$DISK_SIZE"
        printf "  %-18s : ${BOLD}%s${RESET}\n" "GUI Display Mode" "$GUI_MODE"
        printf "  %-18s : ${BOLD}%s${RESET}\n" "Extra Port Maps" "${PORT_FORWARDS:-None}"
        printf "  %-18s : ${FG_GRAY}%s${RESET}\n" "Creation Timestamp" "$CREATED"
        printf "  %-18s : ${FG_GRAY}%s${RESET}\n" "Disk File Path" "$IMG_FILE"
        printf "  %-18s : ${FG_GRAY}%s${RESET}\n" "Seed File Path" "$SEED_FILE"
        echo -e " ${FG_GRAY}──────────────────────────────────────────────────────────────────────────${RESET}\n"
    fi
}

delete_vm() {
    local vm_name=$1
    echo
    print_status "WARN" "Permanent Deletion Warning for '${BOLD}$vm_name${RESET}'!"
    print_status "WARN" "This action will purge all virtual disks and associated configs!"
    
    print_status "INPUT" "Confirm destruction by typing 'y': "
    read -rn 1 reply || reply=""
    echo
    if [[ "$reply" =~ ^[Yy]$ ]]; then
        if load_vm_config "$vm_name"; then
            rm -f "$IMG_FILE" "$SEED_FILE" "$VM_DIR/$vm_name.conf"
            print_status "SUCCESS" "Virtual machine '$vm_name' permanently deleted."
        fi
    else
        print_status "INFO" "Deletion aborted by user."
    fi
}

resize_vm_disk() {
    local vm_name=$1
    if load_vm_config "$vm_name"; then
        echo
        print_status "INFO" "Current Disk Capacity: ${BOLD}$DISK_SIZE${RESET}"
        print_status "INPUT" "Enter new disk capacity (e.g. 40G): "
        read -r new_disk_size || new_disk_size=""
        if validate_input "size" "$new_disk_size"; then
            if qemu-img resize "$IMG_FILE" "$new_disk_size"; then
                DISK_SIZE="$new_disk_size"
                save_vm_config
                print_status "SUCCESS" "Disk resized successfully to $new_disk_size."
            else
                print_status "ERROR" "Failed to expand virtual disk image file."
            fi
        fi
    fi
}

show_vm_performance() {
    local vm_name=$1
    if load_vm_config "$vm_name"; then
        echo
        if is_vm_running "$vm_name"; then
            local pid
            pid=$(pgrep -f "qemu-system-x86_64.*$vm_name\.qcow2")
            echo -e " ${BOLD}${FG_CYAN}Process Resource Telemetry (PID: $pid)${RESET}"
            echo -e " ${FG_GRAY}──────────────────────────────────────────────────────────────────────────${RESET}"
            ps -p "$pid" -o pid,%cpu,%mem,rss,cmd --no-headers 2>/dev/null | awk '{printf "  PID: %-6s │ CPU: %-6s%% │ MEM: %-6s%% │ RSS: %-8s KB\n", $1, $2, $3, $4}' || true
            echo -e " ${FG_GRAY}──────────────────────────────────────────────────────────────────────────${RESET}\n"
        else
            print_status "INFO" "Virtual Machine '$vm_name' is currently stopped."
        fi
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# MAIN DASHBOARD & CONTROLLER
# ─────────────────────────────────────────────────────────────────────────────

main_menu() {
    while true; do
        display_header
        
        local vms=($(get_vm_list))
        local vm_count=${#vms[@]}
        
        # Table Header
        echo -e " ${BOLD}${FG_LIGHT_WHITE}VIRTUAL MACHINES OVERVIEW${RESET}"
        echo -e "${FG_CYAN}┌────┬──────────────────────┬─────────────┬──────────────┬────────────┬──────────────┐${RESET}"
        echo -e "${FG_CYAN}│${RESET} ${BOLD}#${RESET}  ${FG_CYAN}│${RESET} ${BOLD}VM NAME              ${RESET}${FG_CYAN}│${RESET} ${BOLD}OS / TYPE   ${RESET}${FG_CYAN}│${RESET} ${BOLD}RAM / CPU    ${RESET}${FG_CYAN}│${RESET} ${BOLD}SSH PORT   ${RESET}${FG_CYAN}│${RESET} ${BOLD}STATUS        ${RESET}${FG_CYAN}│${RESET}"
        echo -e "${FG_CYAN}├────┼──────────────────────┼─────────────┼──────────────┼────────────┼──────────────┤${RESET}"
        
        if [ "$vm_count" -gt 0 ]; then
            for i in "${!vms[@]}"; do
                local vm="${vms[$i]}"
                local status_badge="${ICON_STOPPED} ${FG_RED}STOPPED${RESET}"
                local os_disp="Unknown"
                local specs_disp="-- / --"
                local port_disp="--"

                if load_vm_config "$vm"; then
                    os_disp="${OS_TYPE:-N/A}"
                    specs_disp="${MEMORY}M / ${CPUS}c"
                    port_disp="${SSH_PORT:-2222}"
                fi

                if is_vm_running "$vm"; then
                    status_badge="${ICON_RUNNING} ${FG_GREEN}RUNNING${RESET}"
                fi

                printf "${FG_CYAN}│${RESET} %2d ${FG_CYAN}│${RESET} %-20s ${FG_CYAN}│${RESET} %-11s ${FG_CYAN}│${RESET} %-12s ${FG_CYAN}│${RESET} %-10s ${FG_CYAN}│${RESET} %-22b ${FG_CYAN}│${RESET}\n" \
                    "$((i+1))" "$vm" "$os_disp" "$specs_disp" "$port_disp" "$status_badge"
            done
        else
            printf "${FG_CYAN}│${RESET} %-76s ${FG_CYAN}│${RESET}\n" " ${FG_GRAY}No virtual machines configured yet. Select option [1] to create one.${RESET}"
        fi
        echo -e "${FG_CYAN}└────┴──────────────────────┴─────────────┴──────────────┴────────────┴──────────────┘${RESET}\n"

        # Action Panel
        tput cnorm 2>/dev/null || true
        echo -e " ${BOLD}${FG_LIGHT_WHITE}AVAILABLE MANAGEMENT ACTIONS${RESET}"
        echo -e " ${FG_GRAY}────────────────────────────────────────────────────────────────────────────────────${RESET}"
        echo -e "  ${BOLD}${FG_CYAN}1)${RESET} Create New Virtual Machine          ${FG_GRAY}│${RESET} ${BOLD}${FG_CYAN}5)${RESET} Expand VM Disk Capacity"
        
        if [ "$vm_count" -gt 0 ]; then
            echo -e "  ${BOLD}${FG_CYAN}2)${RESET} Start Virtual Machine               ${FG_GRAY}│${RESET} ${BOLD}${FG_CYAN}6)${RESET} View Resource Telemetry"
            echo -e "  ${BOLD}${FG_CYAN}3)${RESET} Stop Virtual Machine                ${FG_GRAY}│${RESET} ${BOLD}${FG_CYAN}7)${RESET} Delete Virtual Machine"
            echo -e "  ${BOLD}${FG_CYAN}4)${RESET} Inspect VM Configuration            ${FG_GRAY}│${RESET}"
        fi
        echo -e "  ${BOLD}${FG_RED}0)${RESET} Exit Manager"
        echo -e " ${FG_GRAY}────────────────────────────────────────────────────────────────────────────────────${RESET}\n"

        print_status "INPUT" "Select menu option: "
        read -r choice || choice=""
        
        case $choice in
            1) create_new_vm ;;
            2)
                if [ "$vm_count" -gt 0 ]; then
                    print_status "INPUT" "Enter VM number to start: "
                    read -r num || num=""
                    if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le "$vm_count" ]; then
                        start_vm "${vms[$((num-1))]}"
                    fi
                fi
                ;;
            3)
                if [ "$vm_count" -gt 0 ]; then
                    print_status "INPUT" "Enter VM number to stop: "
                    read -r num || num=""
                    if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le "$vm_count" ]; then
                        stop_vm "${vms[$((num-1))]}"
                    fi
                fi
                ;;
            4)
                if [ "$vm_count" -gt 0 ]; then
                    print_status "INPUT" "Enter VM number to inspect: "
                    read -r num || num=""
                    if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le "$vm_count" ]; then
                        show_vm_info "${vms[$((num-1))]}"
                    fi
                fi
                ;;
            5)
                if [ "$vm_count" -gt 0 ]; then
                    print_status "INPUT" "Enter VM number to resize disk: "
                    read -r num || num=""
                    if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le "$vm_count" ]; then
                        resize_vm_disk "${vms[$((num-1))]}"
                    fi
                fi
                ;;
            6)
                if [ "$vm_count" -gt 0 ]; then
                    print_status "INPUT" "Enter VM number for telemetry: "
                    read -r num || num=""
                    if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le "$vm_count" ]; then
                        show_vm_performance "${vms[$((num-1))]}"
                    fi
                fi
                ;;
            7)
                if [ "$vm_count" -gt 0 ]; then
                    print_status "INPUT" "Enter VM number to delete: "
                    read -r num || num=""
                    if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le "$vm_count" ]; then
                        delete_vm "${vms[$((num-1))]}"
                    fi
                fi
                ;;
            0)
                echo
                print_status "INFO" "Exiting VM Manager. Good Bye!"
                exit 0
                ;;
            *)
                print_status "ERROR" "Invalid option. Please try again."
                ;;
        esac
        
        echo
        print_status "INPUT" "Press [ENTER] to return to dashboard..."
        read -r _ || true
    done
}

# ─────────────────────────────────────────────────────────────────────────────
# INITIALIZATION & EXECUTION
# ─────────────────────────────────────────────────────────────────────────────

trap cleanup EXIT
check_dependencies

VM_DIR="${VM_DIR:-$HOME/vms}"
mkdir -p "$VM_DIR"

declare -A OS_OPTIONS=(
    ["Ubuntu 22.04 LTS"]="ubuntu|jammy|https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img|ubuntu-vm|ubuntu|ubuntu"
    ["Ubuntu 24.04 LTS"]="ubuntu|noble|https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img|ubuntu-noble|ubuntu|ubuntu"
    ["Debian 12 (Bookworm)"]="debian|bookworm|https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2|debian-vm|debian|debian"
    ["AlmaLinux 9"]="almalinux|9|https://repo.almalinux.org/almalinux/9/cloud/x86_64/images/AlmaLinux-9-GenericCloud-latest.x86_64.qcow2|alma-vm|almalinux|almalinux"
    ["Alpine Linux 3.19"]="alpine|3.19|https://dl-cdn.alpinelinux.org/alpine/v3.19/releases/x86_64/alpine-nocloud-3.19.1-x86_64.qcow2|alpine-vm|alpine|alpine"
)

display_boot_animation
main_menu
