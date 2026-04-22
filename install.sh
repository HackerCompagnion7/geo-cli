#!/usr/bin/env bash
# =============================================================================
# geo-cli — Auto-installation script
# Installs all required dependencies: chafa, ImageMagick, curl, bc
# =============================================================================
set -euo pipefail

# ─── Colors ──────────────────────────────────────────────────────────────────
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ─── Print helpers ───────────────────────────────────────────────────────────
print_ok()   { echo -e "  ${GREEN}✓${RESET} $1"; }
print_fail() { echo -e "  ${RED}✗${RESET} $1"; }
print_info() { echo -e "  ${CYAN}→${RESET} $1"; }

# ─── Detect package manager ─────────────────────────────────────────────────
detect_pkg_manager() {
    # Termux MUST be checked first — it has apt-get but NO sudo
    if command -v pkg &>/dev/null; then
        echo "termux"
    elif [[ -n "${TERMUX_VERSION:-}" ]] || [[ -d "/data/data/com.termux" ]]; then
        echo "termux"
    elif command -v apt-get &>/dev/null; then
        echo "apt"
    elif command -v dnf &>/dev/null; then
        echo "dnf"
    elif command -v yum &>/dev/null; then
        echo "yum"
    elif command -v pacman &>/dev/null; then
        echo "pacman"
    elif command -v zypper &>/dev/null; then
        echo "zypper"
    elif command -v brew &>/dev/null; then
        echo "brew"
    else
        echo "unknown"
    fi
}

# ─── Install via package manager ─────────────────────────────────────────────
install_pkg() {
    local pkg_mgr="$1"
    shift
    local pkgs=("$@")

    case "${pkg_mgr}" in
        termux)
            pkg install -y "${pkgs[@]}"
            ;;
        apt)
            sudo apt-get update -qq
            sudo apt-get install -y -qq "${pkgs[@]}"
            ;;
        dnf)
            sudo dnf install -y "${pkgs[@]}"
            ;;
        yum)
            sudo yum install -y "${pkgs[@]}"
            ;;
        pacman)
            sudo pacman -S --noconfirm --needed "${pkgs[@]}"
            ;;
        zypper)
            sudo zypper install -y "${pkgs[@]}"
            ;;
        brew)
            brew install "${pkgs[@]}"
            ;;
        *)
            echo -e "${RED}Unsupported package manager. Install manually:${RESET}"
            echo -e "  chafa, imagemagick, curl, bc"
            exit 1
            ;;
    esac
}

# ─── Main installation ──────────────────────────────────────────────────────
main() {
    echo -e ""
    echo -e "${BOLD}${CYAN}  ╔══════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${CYAN}  ║${RESET}${BOLD}  geo-cli  ·  Installation Wizard     ${BOLD}${CYAN}║${RESET}"
    echo -e "${BOLD}${CYAN}  ╚══════════════════════════════════════╝${RESET}"
    echo -e ""

    local pkg_mgr
    pkg_mgr=$(detect_pkg_manager)
    echo -e "  ${DIM}Detected package manager: ${pkg_mgr}${RESET}"
    echo -e ""

    # ─── Check and install each dependency ───────────────────────────────
    local to_install=()
    local all_ok=true

    # curl
    if command -v curl &>/dev/null; then
        print_ok "curl is already installed"
    else
        print_info "curl is missing — will install"
        to_install+=("curl")
        all_ok=false
    fi

    # bc
    if command -v bc &>/dev/null; then
        print_ok "bc is already installed"
    else
        print_info "bc is missing — will install"
        to_install+=("bc")
        all_ok=false
    fi

    # ImageMagick
    if command -v convert &>/dev/null || command -v magick &>/dev/null; then
        print_ok "ImageMagick is already installed"
    else
        print_info "ImageMagick is missing — will install"
        # Different package names per distro
        case "${pkg_mgr}" in
            termux) to_install+=("imagemagick") ;;
            apt|dnf|yum|zypper) to_install+=("imagemagick") ;;
            pacman) to_install+=("imagemagick") ;;
            brew) to_install+=("imagemagick") ;;
            *) to_install+=("imagemagick") ;;
        esac
        all_ok=false
    fi

    # chafa
    if command -v chafa &>/dev/null; then
        print_ok "chafa is already installed"
    else
        print_info "chafa is missing — will install"
        case "${pkg_mgr}" in
            termux) to_install+=("chafa") ;;
            apt|dnf|yum|zypper) to_install+=("chafa") ;;
            pacman) to_install+=("chafa") ;;
            brew) to_install+=("chafa") ;;
            *)
                # If not in repos, build from source
                print_info "chafa may not be in your repos. Trying to install from source..."
                to_install+=("chafa")
                ;;
        esac
        all_ok=false
    fi

    # python3 (for JSON parsing)
    if command -v python3 &>/dev/null; then
        print_ok "python3 is already installed"
    else
        print_info "python3 is missing — will install"
        to_install+=("python3")
        all_ok=false
    fi

    echo -e ""

    # ─── Install missing packages ────────────────────────────────────────
    if [[ ${#to_install[@]} -gt 0 ]]; then
        echo -e "  ${BOLD}Installing:${RESET} ${to_install[*]}"
        echo -e ""
        install_pkg "${pkg_mgr}" "${to_install[@]}"

        # Verify installations
        echo -e ""
        echo -e "  ${BOLD}Verifying installations...${RESET}"
        for pkg in "${to_install[@]}"; do
            if command -v "${pkg}" &>/dev/null; then
                print_ok "${pkg} installed successfully"
            fi
        done
    fi

    # ─── Ensure chafa is available (fallback: build from source) ─────────
    if ! command -v chafa &>/dev/null; then
        echo -e ""
        print_info "chafa not found in repos. Building from source..."
        local chafa_tmp
        local _tmp_base
        if [[ -n "${TMPDIR:-}" ]]; then
            _tmp_base="${TMPDIR}"
        elif [[ -d "/tmp" && -w "/tmp" ]]; then
            _tmp_base="/tmp"
        else
            _tmp_base="${SCRIPT_DIR}"
        fi
        chafa_tmp="$(mktemp -d "${_tmp_base}/chafa-build.XXXXXX")"

        if command -v git &>/dev/null && command -v gcc &>/dev/null && command -v make &>/dev/null; then
            # Determine install prefix based on environment
            local install_prefix="/usr/local"
            if [[ -n "${TERMUX_VERSION:-}" ]] || [[ -d "/data/data/com.termux" ]]; then
                install_prefix="${PREFIX:-/data/data/com.termux/files/usr}"
            fi
            (
                cd "${chafa_tmp}"
                git clone https://github.com/hpjansson/chafa.git 2>/dev/null
                cd chafa
                ./autogen.sh --prefix="${install_prefix}" 2>/dev/null || true
                ./configure --prefix="${install_prefix}" 2>/dev/null || true
                make -j"$(nproc 2>/dev/null || echo 2)" 2>/dev/null
                make install DESTDIR= 2>/dev/null || sudo make install 2>/dev/null || true
            ) || true
        fi

        rm -rf "${chafa_tmp}"

        if command -v chafa &>/dev/null; then
            print_ok "chafa built and installed from source"
        else
            print_fail "Could not build chafa from source"
            echo -e "  ${DIM}Install manually: https://github.com/hpjansson/chafa${RESET}"
        fi
    fi

    # ─── Set permissions on main script ──────────────────────────────────
    if [[ -f "${SCRIPT_DIR}/geo-cli" ]]; then
        chmod +x "${SCRIPT_DIR}/geo-cli" 2>/dev/null || true
        print_ok "geo-cli script is executable"
    fi

    # ─── Ensure map file exists ──────────────────────────────────────────
    if [[ ! -f "${SCRIPT_DIR}/assets/world_map.png" ]]; then
        print_info "Downloading world map image..."
        mkdir -p "${SCRIPT_DIR}/assets"
        if curl -sL -o "${SCRIPT_DIR}/assets/world_map.png" \
            "https://upload.wikimedia.org/wikipedia/commons/e/ea/Equirectangular-projection.jpg" \
            -H "User-Agent: Mozilla/5.0"; then
            # Resize to proper equirectangular dimensions
            if command -v convert &>/dev/null; then
                convert "${SCRIPT_DIR}/assets/world_map.png" -resize 2048x1024! \
                    "${SCRIPT_DIR}/assets/world_map.png.tmp" 2>/dev/null && \
                    mv "${SCRIPT_DIR}/assets/world_map.png.tmp" "${SCRIPT_DIR}/assets/world_map.png"
            elif command -v python3 &>/dev/null; then
                python3 -c "
from PIL import Image
img = Image.open('${SCRIPT_DIR}/assets/world_map.png')
img = img.resize((2048, 1024), Image.LANCZOS)
img.save('${SCRIPT_DIR}/assets/world_map.png', 'PNG')
" 2>/dev/null
            fi
            print_ok "World map downloaded"
        else
            print_fail "Could not download world map"
            echo -e "  ${DIM}The map will be auto-downloaded on first run.${RESET}"
        fi
    else
        print_ok "World map image found"
    fi

    echo -e ""
    if ${all_ok} && command -v chafa &>/dev/null && { command -v convert &>/dev/null || command -v magick &>/dev/null; }; then
        echo -e "  ${GREEN}${BOLD}All dependencies satisfied!${RESET}"
        echo -e ""
        echo -e "  ${BOLD}Usage:${RESET}  ./geo-cli 8.8.8.8"
    else
        echo -e "  ${YELLOW}Some dependencies may still be missing.${RESET}"
        echo -e "  ${DIM}Please check the output above for any failures.${RESET}"
    fi
    echo -e ""
}

main "$@"
