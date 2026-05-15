#!/usr/bin/env bash
# ARCH-10 - Report Generator

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/colors.sh"

REPORT_DIR="$HOME/arch10/reports"

header "📊 REPORT GENERATOR" $C

echo -e "  ${R}[${Y}1${R}]${N} ${G}Generate Summary${N} ${D}- Create markdown summary of all scans${N}"
echo -e "  ${R}[${Y}2${R}]${N} ${G}List Reports${N}    ${D}- Show all report files${N}"
echo -e "  ${R}[${Y}3${R}]${N} ${G}Export${N}          ${D}- Export reports to single file${N}"
echo -e "  ${R}[${Y}00${R}]${N} ${Y}Back${N}"
echo ""

read -p "$(echo -e ${C}"[${Y}REPORT${C}]${N} > ")" ch

case $ch in
    1|summary)
        local summary="$REPORT_DIR/summary_$(date +%Y%m%d).md"
        {
            echo "# ARCH-10 Pentest Summary"
            echo "**Date:** $(date)"
            echo "**Host:** $(hostname)"
            echo ""
            echo "## Reports"
            echo ""
            find "$REPORT_DIR" -type f -name "*.txt" -mtime -1 2>/dev/null | while read f; do
                lines=$(wc -l < "$f")
                issues=$(grep -ciE '(vulnerability|critical|high|open|found)' "$f" 2>/dev/null)
                echo "- $(basename $f): $lines lines, $issues findings"
            done
            echo ""
            echo "## Tools Available"
            echo ""
            for tool in nmap nuclei metasploit sqlmap bettercap burpsuite hydra hashcat john enum4linux; do
                if command -v "$tool" &>/dev/null; then
                    echo "- $tool: $(which $tool)"
                fi
            done
        } > "$summary"
        success "Summary saved: $summary"
        cat "$summary"
        ;;
    2|list)
        echo -e "${C}Reports in ${G}${REPORT_DIR}${N}:"
        find "$REPORT_DIR" -type f 2>/dev/null | while read f; do
            size=$(du -h "$f" 2>/dev/null | cut -f1)
            echo -e "  ${Y}[${size}]${N} ${G}$(basename $f)${N}"
        done
        ;;
    3|export)
        local export_file="$REPORT_DIR/export_$(date +%Y%m%d).txt"
        {
            echo "=========================================="
            echo "ARCH-10 REPORT EXPORT"
            echo "Date: $(date)"
            echo "=========================================="
            echo ""
            find "$REPORT_DIR" -type f -name "*.txt" 2>/dev/null | while read f; do
                echo "------------------------------------------"
                echo "FILE: $(basename $f)"
                echo "------------------------------------------"
                cat "$f"
                echo ""
            done
        } > "$export_file"
        success "Exported: $export_file ($(du -h "$export_file" | cut -f1))"
        ;;
    00|0|back) exit 0 ;;
esac
