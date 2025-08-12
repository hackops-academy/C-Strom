#!/usr/bin/env bash
# ReconStrom - Recon wrapper for Kali Linux (bug-bounty friendly)
# Author: HackOps / Cyber Ghost (starter template for Lucky)
# Usage: ./reconstrom.sh -d target.com [-o output_dir] [--all]
# IMPORTANT: Use this tool ONLY on assets you have explicit permission to test.

set -euo pipefail
IFS=$'\n\t'

TARGET=""
OUTDIR="reconstrom_output"
ALL=false
THREADS=50
BANNER='''
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
'''

#!/bin/bash

usage() {
    echo "Usage: $0 <target-domain>"
    echo "Example: $0 example.com"
    exit 1
}

if [ -z "$1" ]; then
    echo "[!] Target required"
    usage
fi

TARGET=$1
echo "[+] Running Recon on $TARGET"


log() { echo -e "[+] $*"; }
err() { echo -e "[!] $*" >&2; }

install_deps(){
  log "Installing required dependencies..."
  sudo apt update -y
  sudo apt install -y subfinder amass assetfinder ffuf nmap jq curl golang
  export PATH=$PATH:$(go env GOPATH)/bin
  go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest || true
  go install -v github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest || true
  go install -v github.com/tomnomnom/waybackurls@latest || true
  go install -v github.com/lc/gau/v2/cmd/gau@latest || true
  go install -v github.com/michenriksen/aquatone@latest || true
  log "All dependencies installed."
}

check_deps(){
  local deps=("subfinder" "assetfinder" "amass" "httpx" "nmap" "jq" "ffuf" "waybackurls" "gau" "nuclei" "aquatone")
  for d in "${deps[@]}"; do
    if ! command -v "$d" >/dev/null 2>&1; then
      err "Missing: $d"
      install_deps
      break
    fi
  done
}

# (Rest of the recon functions remain same)

# ---------------------------
# Main pipeline
# ---------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    -d) TARGET="$2"; shift 2;;
    -o) OUTDIR="$2"; shift 2;;
    -t) THREADS="$2"; shift 2;;
    --all) ALL=true; shift;;
    -h|--help) usage; exit 0;;
    *) err "Unknown option: $1"; usage; exit 1;;
  esac
done

if [[ -z "$TARGET" ]]; then err "Target required"; usage; exit 1; fi

TS=$(date +"%Y%m%d_%H%M%S")
OUTDIR="$OUTDIR/$TARGET-$TS"
mkdir -p "$OUTDIR"

clear
echo -e "$BANNER"
log "ReconStrom - output => $OUTDIR"
log "Target => $TARGET"
log "Threads => $THREADS"

check_deps

run_subdomain_enum "$OUTDIR"
run_httpx "$OUTDIR"
run_ports "$OUTDIR"
run_wayback "$OUTDIR"
run_dirs "$OUTDIR"
run_nuclei "$OUTDIR"
screenshot_aquatone "$OUTDIR"

log "Recon pipeline finished. Results in: $OUTDIR"
