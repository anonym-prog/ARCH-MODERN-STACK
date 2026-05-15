#!/usr/bin/env bash
# ARCH-10 - Installer for Arch Linux

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/colors.sh"

trap 'echo -e "\n${R}[${CROSS}] Installation interrupted!${N}"; exit 1' SIGINT SIGTERM

[ "$EUID" -eq 0 ] && SUDO="" || SUDO="sudo"

clear
cat "$SCRIPT_DIR/.banner.txt" 2>/dev/null || true
header "ARCH-10 INSTALLER v1.0"

# Check Arch
if ! grep -qi "arch" /etc/os-release 2>/dev/null; then
    warning "This installer is for Arch Linux only"
    confirm "Continue anyway?" || exit 1
fi

# Update system
header "UPDATING SYSTEM"
$SUDO pacman -Syu --noconfirm
success "System updated!"

# BlackArch repo
header "BLACKARCH REPOSITORY"
if ! pacman -Sl blackarch 2>/dev/null | grep -q .; then
    info "Adding BlackArch repository..."
    curl -s https://blackarch.org/strap.sh | $SUDO bash
    $SUDO pacman -Syyu --noconfirm
    success "BlackArch added!"
else
    info "BlackArch already configured"
fi

# Install base deps
header "BASE DEPENDENCIES"
$SUDO pacman -S --noconfirm --needed git curl wget base-devel python python-pip go
success "Base dependencies installed!"

# Install AUR helper
if ! command -v yay &>/dev/null; then
    info "Installing yay..."
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    cd /tmp/yay && makepkg -si --noconfirm && cd "$SCRIPT_DIR"
    success "yay installed!"
fi

# ============================================
# INSTALL 10 TOOLS
# ============================================
header "INSTALLING 10 CORE TOOLS"

TOOLS=(
    "nmap"           # 1. Recon
    "nuclei"         # 2. Recon
    "metasploit"     # 3. Exploit
    "sqlmap"         # 4. SQL Injection
    "bettercap"      # 5. MITM
    "burpsuite"      # 6. Web App
    "hydra"          # 7. Password
    "hashcat"        # 8. Password
    "john"           # 9. Password
    "enum4linux"     # 10. Enumeration
)

total=${#TOOLS[@]}
count=0

for tool in "${TOOLS[@]}"; do
    count=$((count + 1))
    echo -ne "\r${Y}[${count}/${total}]${N} Installing ${G}${tool}${N}...          "
    
    if pacman -Qi "$tool" &>/dev/null; then
        echo -ne "\r${G}[${CHECK}]${N} ${tool} ${D}already installed${N}          \n"
    else
        if $SUDO pacman -S --noconfirm --needed "$tool" 2>/dev/null; then
            echo -ne "\r${G}[${CHECK}]${N} ${tool} ${G}installed!${N}          \n"
        else
            yay -S --noconfirm "$tool" 2>/dev/null && \
                echo -ne "\r${G}[${CHECK}]${N} ${tool} ${G}installed!${N}          \n" || \
                echo -ne "\r${Y}[${WARN}]${N} ${tool} ${Y}failed${N}           \n"
        fi
    fi
done

success "All 10 tools installed!"

# Install Go tools (Nuclei templates)
header "NUCLEI TEMPLATES"
if command -v nuclei &>/dev/null; then
    info "Updating Nuclei templates..."
    nuclei -update-templates 2>/dev/null && success "Templates updated!" || warning "Template update skipped"
fi

# Setup directories
header "SETTING UP"
ARCH10_DIR="$HOME/arch10"
mkdir -p "$ARCH10_DIR"/{reports,wordlists,logs}

# Download wordlist
if [ ! -f "$ARCH10_DIR/wordlists/rockyou.txt" ]; then
    info "Downloading rockyou wordlist..."
    curl -L -o /tmp/rockyou.txt.gz "https://github.com/brannondorsey/naive-hashcat/releases/download/data/rockyou.txt" 2>/dev/null
    gunzip -f /tmp/rockyou.txt.gz 2>/dev/null
    mv /tmp/rockyou.txt "$ARCH10_DIR/wordlists/" 2>/dev/null && success "rockyou.txt downloaded!" || warning "Wordlist download failed"
fi

# Install launcher
$SUDO cp "$SCRIPT_DIR/arch10.sh" /usr/local/bin/arch10
$SUDO chmod +x /usr/local/bin/arch10
success "Launcher installed! Type 'arch10' to start"

# Shell config
BASHRC="$HOME/.bashrc"
if ! grep -q "ARCH-10" "$BASHRC" 2>/dev/null; then
    cat >> "$BASHRC" << 'EOF'

# ===== ARCH-10 CONFIG =====
export PATH="$PATH:$HOME/go/bin"
export PATH="$PATH:$HOME/arch10"
alias a10='arch10'
alias a10-recon='arch10 recon'
alias a10-exploit='arch10 exploit'
alias a10-sql='arch10 sql'
alias a10-mitm='arch10 mitm'
alias a10-web='arch10 web'
alias a10-crack='arch10 password'
alias a10-scan='arch10 scan'
EOF
    success "Aliases added to .bashrc"
fi

# ============================================
# VERIFY
# ============================================
header "VERIFYING INSTALLATION"

echo ""
echo -e "${C}┌─────────────┬──────────┐${N}"
echo -e "${C}│${N} ${Y}TOOL${N}          ${C}│${N} ${Y}STATUS${N}    ${C}│${N}"
echo -e "${C}├─────────────┼──────────┤${N}"

for tool in "${TOOLS[@]}"; do
    if command -v "$tool" &>/dev/null || pacman -Qi "$tool" &>/dev/null; then
        printf "│ %-13s │ ${G}%-8s${N} │\n" "$tool" "✓ OK"
    else
        printf "│ %-13s │ ${R}%-8s${N} │\n" "$tool" "✗ MISSING"
    fi
done

echo -e "${C}└─────────────┴──────────┘${N}"
echo ""

# ============================================
# COMPLETE
# ============================================
clear
echo -e "${R}"
echo "████████████████████████████████████████████████████████████████"
echo "██                                                            ██"
echo "██    █████╗ ██████╗  ██████╗██╗  ██╗    ██╗  ██╗ ██████╗     ██"
echo "██   ██╔══██╗██╔══██╗██╔════╝██║  ██║    ██║  ██║██╔═══██╗    ██"
echo "██   ███████║██████╔╝██║     ███████║    ███████║██║   ██║    ██"
echo "██   ██╔══██║██╔══██╗██║     ██╔══██║    ██╔══██║██║   ██║    ██"
echo "██   ██║  ██║██║  ██║╚██████╗██║  ██║    ██║  ██║╚██████╔╝    ██"
echo "██   ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝    ╚═╝  ╚═╝ ╚═════╝     ██"
echo "██                                                            ██"
echo "██              ╔══════════════════════════════╗              ██"
echo "██              ║   INSTALLATION COMPLETE!    ║              ██"
echo "██              ╚══════════════════════════════╝              ██"
echo "██                                                            ██"
echo "██  ${G}⚡ LAUNCH${N}                    ${R}⚡ COMMANDS${N}               ██"
echo "██  ${G}━━━━━━━━━${N}                    ${R}━━━━━━━━━━${N}              ██"
echo "██  ${Y}arch10${N}         - Main menu   ${Y}a10-scan <ip>${N}          ██"
echo "██  ${Y}a10-recon${N}      - Recon       ${Y}a10-mitm <iface>${N}       ██"
echo "██  ${Y}a10-exploit${N}    - Exploit     ${Y}a10-crack <hash>${N}       ██"
echo "██  ${Y}a10-sql${N}        - SQLMap      ${Y}a10-web${N}                ██"
echo "██  ${Y}a10-mitm${N}       - Bettercap   ${Y}a10-scan <target>${N}      ██"
echo "██                                                            ██"
echo "██  ${G}📁 Wordlists:${N} ~/arch10/wordlists/                    ██"
echo "██  ${G}📁 Reports:${N}   ~/arch10/reports/                       ██"
echo "██                                                            ██"
echo "██  ${R}☠ AUTHORIZED PENTESTING ONLY ${N}                       ██"
echo "██                                                            ██"
echo "████████████████████████████████████████████████████████████████"
echo -e "${N}"
echo ""
echo -e "  ${Y}Reboot terminal or run:${N} ${G}source ~/.bashrc${N}"
echo ""

source ~/.bashrc 2>/dev/null || true
exit 0

---

### 2️⃣ **`colors.sh`**

```bash
#!/usr/bin/env bash
# ARCH-10 - Color Configuration
# Theme: Red • Green • Yellow • Blue • Purple • Cyan

R='\033[1;31m'
G='\033[1;32m'
Y='\033[1;33m'
B='\033[1;34m'
P='\033[1;35m'
C='\033[1;36m'
W='\033[1;37m'
N='\033[0m'
D='\033[2m'
BD='\033[1m'

# Icons
CHECK="${G}✓${N}"
CROSS="${R}✗${N}"
WARN="${Y}⚠${N}"
ARROW="${C}→${N}"
BOLT="${Y}⚡${N}"
TARGET="${R}🎯${N}"

# Functions
header() {
    local title="$1"
    local color="${2:-$R}"
    echo ""
    echo -e "${color}╔══════════════════════════════════════════════════════════╗${N}"
    echo -e "${color}║${N}  ${Y}${BD}◆${N} ${W}${BD}${title}${N} ${Y}${BD}◆${N}"
    echo -e "${color}╚══════════════════════════════════════════════════════════╝${N}"
    echo ""
}

success() { echo -e " ${G}[${CHECK}]${N} ${1}"; }
error() { echo -e " ${R}[${CROSS}]${N} ${1}"; }
warning() { echo -e " ${Y}[${WARN}]${N} ${1}"; }
info() { echo -e " ${C}[${ARROW}]${N} ${1}"; }

tool_banner() {
    local name="$1"
    local category="$2"
    local color="${3:-$R}"
    echo ""
    echo -e "${color}╔══════════════════════════════════════════════════════════╗${N}"
    echo -e "${color}║${N} ${Y}${BOLT}${N} ${W}${BD}${name}${N} ${D}(${category})${N}"
    echo -e "${color}╚══════════════════════════════════════════════════════════╝${N}"
    echo ""
}

confirm() {
    local prompt="$1"
    local yn
    read -p "$(echo -e ${Y}"[?] ${prompt} [y/N]: "${N})" yn
    case "$yn" in [Yy]*) return 0 ;; *) return 1 ;; esac
}

export R G Y B P C W N D BD CHECK CROSS WARN ARROW BOLT TARGET
