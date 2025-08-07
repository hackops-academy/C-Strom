#!/bin/bash

# ReconStorm v1.0 - Automated Recon Tool by HackOps
# Author: Lucky (Cyber Ghost)
# Platform: Kali Linux / Ubuntu
# Language: Bash
# License: MIT

trap ctrl_c INT
ctrl_c() {
    echo -e "\n\n[!] Exiting ReconStorm..."
    exit 1
}

# ====== Colors ======
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
CYAN="\e[36m"
RESET="\e[0m"

# ====== Banner ======
banner() {
    clear
    echo -e "${CYAN}"
    echo "@@@@@@@   @@@@@@@@   @@@@@@@   @@@@@@   @@@  @@@   @@@@@@   @@@@@@@  @@@@@@@    @@@@@@   @@@@@@@@@@"
    echo "@@@@@@@@  @@@@@@@@  @@@@@@@@  @@@@@@@@  @@@@ @@@  @@@@@@@   @@@@@@@  @@@@@@@@  @@@@@@@@  @@@@@@@@@@@"
    echo "@@!  @@@  @@!       !@@       @@!  @@@  @@!@!@@@  !@@         @@!    @@!  @@@  @@!  @@@  @@! @@! @@!"
    echo "!@!  @!@  !@!       !@!       !@!  @!@  !@!!@!@!  !@!         !@!    !@!  @!@  !@!  @!@  !@! !@! !@!"
    echo "@!@!!@!   @!!!:!    !@!       @!@  !@!  @!@ !!@!  !!@@!!      @!!    @!@!!@!   @!@  !@!  @!! !!@ @!@"
    echo "!!@!@!    !!!!!:    !!!       !@!  !!!  !@!  !!!   !!@!!!     !!!    !!@!@!    !@!  !!!  !@!   ! !@!"
    echo "!!: :!!   !!:       :!!       !!:  !!!  !!:  !!!       !:!    !!:    !!: :!!   !!:  !!!  !!:     !!:"
    echo ":!:  !:!  :!:       :!:       :!:  !:!  :!:  !:!      !:!     :!:    :!:  !:!  :!:  !:!  :!:     :!:"
    echo "::   :::   :: ::::   ::: :::  ::::: ::   ::   ::  :::: ::      ::    ::   :::  ::::: ::  :::     ::"
    echo ":   : :  : :: ::    :: :: :   : :  :   ::    :   :: : :       :      :   : :   : :  :    :      :"
    echo -e "${YELLOW}                             By HackOps | v1.0 ${RESET}"
    echo
}

# ====== Dependency Check ======
check_dependencies() {
    echo -e "${YELLOW}[*] Checking required tools...${RESET}"
    deps=(curl jq whois dig nmap)

    missing=false
    for dep in "${deps[@]}"; do
        if ! command -v $dep >/dev/null 2>&1; then
            echo -e "${RED}[!] Missing: $dep${RESET}"
            missing=true
        fi
    done

    if $missing; then
        echo -e "\n${RED}[X] One or more required tools are missing. Install them and try again.${RESET}"
        exit 1
    fi
}

# ====== Menu ======
menu() {
    echo -e "${GREEN}[1]${RESET} Start Tor"
    echo -e "${GREEN}[2]${RESET} Subdomain Enumeration"
    echo -e "${GREEN}[3]${RESET} WHOIS Lookup"
    echo -e "${GREEN}[4]${RESET} DNS Records"
    echo -e "${GREEN}[5]${RESET} HTTP Headers"
    echo -e "${GREEN}[6]${RESET} Nmap Scan"
    echo -e "${GREEN}[7]${RESET} Run All Recon"
    echo -e "${GREEN}[0]${RESET} Exit"
}

# ====== Execution Start ======
banner
check_dependencies

read -p "Enter target domain (example.com): " target

mkdir -p reports
timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
outfile="reports/${target}-${timestamp}.txt"
echo -e "[*] ReconStorm Report for: $target\nDate: $(date)\n" > "$outfile"

while true; do
    menu
    echo
    read -p "Choose an option: " choice

    case $choice in
        1)
            echo -e "${YELLOW}[*] Starting Tor service...${RESET}"
            sudo systemctl start tor && echo -e "${GREEN}[+] Tor started.${RESET}" || echo -e "${RED}[!] Failed to start Tor.${RESET}"
            ;;
        2)
            echo -e "\n[+] Subdomain Enumeration:" | tee -a "$outfile"
            curl -s "https://crt.sh/?q=%25.$target&output=json" | jq -r '.[].name_value' | sort -u | tee -a "$outfile"
            ;;
        3)
            echo -e "\n[+] WHOIS Lookup:" | tee -a "$outfile"
            whois $target | tee -a "$outfile"
            ;;
        4)
            echo -e "\n[+] DNS Records:" | tee -a "$outfile"
            dig $target any +noall +answer | tee -a "$outfile"
            ;;
        5)
            echo -e "\n[+] HTTP Headers:" | tee -a "$outfile"
            curl -I https://$target | tee -a "$outfile"
            ;;
        6)
            echo -e "\n[+] Nmap Scan:" | tee -a "$outfile"
            nmap -sC -sV -Pn $target | tee -a "$outfile"
            ;;
        7)
            echo -e "\n[+] Running Full Recon...${RESET}" | tee -a "$outfile"

            echo -e "\n[*] Subdomain Enumeration:" | tee -a "$outfile"
            curl -s "https://crt.sh/?q=%25.$target&output=json" | jq -r '.[].name_value' | sort -u | tee -a "$outfile"

            echo -e "\n[*] WHOIS Lookup:" | tee -a "$outfile"
            whois $target | tee -a "$outfile"

            echo -e "\n[*] DNS Records:" | tee -a "$outfile"
            dig $target any +noall +answer | tee -a "$outfile"

            echo -e "\n[*] HTTP Headers:" | tee -a "$outfile"
            curl -I https://$target | tee -a "$outfile"

            echo -e "\n[*] Nmap Scan:" | tee -a "$outfile"
            nmap -sC -sV -Pn $target | tee -a "$outfile"

            echo -e "\n[✓] Full Recon complete. Results saved in $outfile"
            ;;
        0)
            echo -e "${GREEN}[+] Exiting. Report saved at $outfile${RESET}"
            exit 0
            ;;
        *)
            echo -e "${RED}[!] Invalid option. Try again.${RESET}"
            ;;
    esac
    echo
done
