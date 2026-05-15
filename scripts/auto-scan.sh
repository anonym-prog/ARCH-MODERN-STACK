#!/usr/bin/env bash
# ARCH-10 - Auto Scan Script
# Usage: ./auto-scan.sh <target>

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/colors.sh"

TARGET="$1"
[ -z "$TARGET" ] && read -p "$(echo -e ${Y}"[?] Target: "${N})" TARGET
[ -z "$TARGET" ] && { error "Target required!"; exit 1; }

REPORT_DIR="$HOME/arch10/reports/auto_scan_${TARGET}_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$REPORT_DIR"

clear
echo -e "${R}"
echo "╔══════════════════════════════════════════════════════════╗"
echo "║              ⚡ ARCH-10 AUTO SCAN ⚡                    ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo -e "${N}"
echo -e "  ${C}Target:${N}  ${Y}${TARGET}${N}"
echo -e "  ${C}Date:${N}   ${Y}$(date)${N}"
echo ""

# Phase 1: Nmap
header "PHASE 1: PORT SCAN" $R
echo -e "${R}[${Y}●${R}]${N} ${G}Nmap - Service detection...${N}"
nmap -sC -sV -T4 "$TARGET" -oN "$REPORT_DIR/nmap_services.txt" 2>/dev/null
echo -e "  ${G}✓${N} Services saved"

echo -e "${R}[${Y}●${R}]${N} ${G}Nmap - Full port scan...${N}"
nmap -p- --min-rate=1000 "$TARGET" -oN "$REPORT_DIR/nmap_allports.txt" 2>/dev/null
echo -e "  ${G}✓${N} All ports saved"

# Phase 2: Nuclei
header "PHASE 2: VULNERABILITY SCAN" $Y
echo -e "${R}[${Y}●${R}]${N} ${G}Nuclei - Template scan...${N}"
nuclei -u "http://$TARGET" -severity low,medium,high,critical -o "$REPORT_DIR/nuclei.txt" 2>/dev/null || \
nuclei -u "https://$TARGET" -severity low,medium,high,critical -o "$REPORT_DIR/nuclei.txt" 2>/dev/null
echo -e "  ${G}✓${N} Nuclei scan saved"

# Phase 3: Enumeration
header "PHASE 3: ENUMERATION" $B
echo -e "${R}[${Y}●${R}]${N} ${B}Enum4linux - SMB enum...${N}"
enum4linux -a "$TARGET" > "$REPORT_DIR/enum4linux.txt" 2>/dev/null
echo -e "  ${G}✓${N} SMB enum saved"

echo -e "${R}[${Y}●${R}]${N} ${B}WhatWeb - Technology...${N}"
whatweb "$TARGET" > "$REPORT_DIR/whatweb.txt" 2>/dev/null
echo -e "  ${G}✓${N} Technology saved"

# Complete
echo ""
echo -e "${G}╔══════════════════════════════════════════════════════════╗${N}"
echo -e "${G}║${N}              ${Y}⚡ AUTO SCAN COMPLETE ⚡${N}              ${G}║${N}"
echo -e "${G}╚══════════════════════════════════════════════════════════╝${N}"
echo ""
echo -e "  ${C}Target:${N}  ${Y}${TARGET}${N}"
echo -e "  ${C}Reports:${N} ${G}${REPORT_DIR}/${N}"
echo ""
ls -la "$REPORT_DIR/"
