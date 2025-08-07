#!/bin/bash

# ReconStorm v2 - Automated Reconnaissance Framework
# Author: Lucky | HackOps
# License: MIT
# Tested on: Kali Linux / Ubuntu

# ========== Banner ==========
banner() {
    clear
    echo -e "\e[1;36m"
    cat << "EOF"
                                                                                                         
@@@@@@@   @@@@@@@@   @@@@@@@   @@@@@@   @@@  @@@   @@@@@@   @@@@@@@  @@@@@@@    @@@@@@   @@@@@@@@@@      
@@@@@@@@  @@@@@@@@  @@@@@@@@  @@@@@@@@  @@@@ @@@  @@@@@@@   @@@@@@@  @@@@@@@@  @@@@@@@@  @@@@@@@@@@@     
@@!  @@@  @@!       !@@       @@!  @@@  @@!@!@@@  !@@         @@!    @@!  @@@  @@!  @@@  @@! @@! @@!     
!@!  @!@  !@!       !@!       !@!  @!@  !@!!@!@!  !@!         !@!    !@!  @!@  !@!  @!@  !@! !@! !@!     
@!@!!@!   @!!!:!    !@!       @!@  !@!  @!@ !!@!  !!@@!!      @!!    @!@!!@!   @!@  !@!  @!! !!@ @!@     
!!@!@!    !!!!!:    !!!       !@!  !!!  !@!  !!!   !!@!!!     !!!    !!@!@!    !@!  !!!  !@!   ! !@!     
!!: :!!   !!:       :!!       !!:  !!!  !!:  !!!       !:!    !!:    !!: :!!   !!:  !!!  !!:     !!:     
:!:  !:!  :!:       :!:       :!:  !:!  :!:  !:!      !:!     :!:    :!:  !:!  :!:  !:!  :!:     :!:     
::   :::   :: ::::   ::: :::  ::::: ::   ::   ::  :::: ::      ::    ::   :::  ::::: ::  :::     ::      
 :   : :  : :: ::    :: :: :   : :  :   ::    :   :: : :       :      :   : :   : :  :    :      :       

EOF
    echo -e "\e[1;32m                  [+] Created by Lucky (Cyber Ghost) | HackOps Team\e[0m"
    echo ""
}

# ========== Tool Installation ==========
install_tools() {
    echo -e "\n\e[1;33m[+] Checking and installing required tools...\e[0m"

    declare -a apt_tools=(nmap whois dnsutils whatweb theharvester tor proxychains jq git curl)
    declare -a go_tools=(subfinder httpx amass)

    for tool in "${apt_tools[@]}"; do
        if ! command -v "$tool" &>/dev/null; then
            echo -e "\e[34m[*] Installing $tool via apt...\e[0m"
            sudo apt install -y "$tool" &>/dev/null
        else
            echo -e "\e[32m[✓] $tool already installed.\e[0m"
        fi
    done

    if ! command -v go &>/dev/null; then
        echo -e "\e[31m[!] Go is not installed. Please install Golang to continue.\e[0m"
        exit 1
    fi

    export PATH=$PATH:$(go env GOPATH)/bin

    for gotool in "${go_tools[@]}"; do
        if ! command -v "$gotool" &>/dev/null; then
            echo -e "\e[34m[*] Installing $gotool via go...\e[0m"
            go install github.com/projectdiscovery/"$gotool"/cmd/"$gotool"@latest
        else
            echo -e "\e[32m[✓] $gotool already installed.\e[0m"
        fi
    done

    echo -e "\e[1;32m[+] All tools installed and ready!\e[0m"
}

# ========== Recon Functions ==========
start_recon() {
    echo ""
    read -p $'\e[1;36m[?] Enter Target Domain: \e[0m' domain

    output_dir="reports/$domain"
    mkdir -p "$output_dir"

    echo -e "\n\e[1;33m[+] Running Subdomain Enumeration with Subfinder...\e[0m"
    subfinder -d "$domain" -o "$output_dir/subfinder.txt"

    echo -e "\n\e[1;33m[+] Running Passive Recon with Amass...\e[0m"
    amass enum -passive -d "$domain" -o "$output_dir/amass.txt"

    echo -e "\n\e[1;33m[+] Resolving Alive Hosts with Httpx...\e[0m"
    cat "$output_dir/subfinder.txt" "$output_dir/amass.txt" | sort -u | httpx -silent -o "$output_dir/httpx_alive.txt"

    echo -e "\n\e[1;33m[+] Running Nmap on Live Hosts...\e[0m"
    nmap -iL "$output_dir/httpx_alive.txt" -T4 -Pn -oN "$output_dir/nmap.txt"

    echo -e "\n\e[1;33m[+] Running Whois Lookup...\e[0m"
    whois "$domain" > "$output_dir/whois.txt"

    echo -e "\n\e[1;33m[+] Running WhatWeb for Tech Stack...\e[0m"
    whatweb -i "$output_dir/httpx_alive.txt" > "$output_dir/whatweb.txt"

    echo -e "\n\e[1;33m[+] Running theHarvester...\e[0m"
    theHarvester -d "$domain" -b all -f "$output_dir/theharvester.html"

    echo -e "\n\e[1;32m[✓] Recon Complete. Reports saved in: $output_dir\e[0m"
}

# ========== Main Menu ==========
main_menu() {
    banner
    PS3=$'\e[1;36mChoose an option: \e[0m'
    options=("Install All Tools" "Start Recon" "Exit")
    select opt in "${options[@]}"; do
        case $opt in
            "Install All Tools")
                install_tools
                ;;
            "Start Recon")
                start_recon
                ;;
            "Exit")
                echo -e "\e[1;33m[!] Exiting ReconStorm. Stay stealthy.\e[0m"
                exit 0
                ;;
            *)
                echo -e "\e[1;31m[!] Invalid Option. Try again.\e[0m"
                ;;
        esac
    done
}

# ========== Start Script ==========
main_menu
