# geo-cli

**IP Geolocation CLI with real map rendering in terminal**

A command-line tool that resolves the geolocation of any IP address or domain and renders a real world map directly in your terminal with a precision pin marking the location.

## Features

- Real world map rendered in terminal (not ASCII art)
- Precise pin marker on the geographic location
- Supports both IP addresses and domain names
- Proxy / VPN / Hosting detection
- Timezone, ISP, AS number, organization data
- Batch mode for processing multiple IPs
- JSON output for scripting
- Loading spinner with progress indication
- Clean, professional ANSI-colored output with box drawing
- Auto-downloads map image if missing
- Works in Termux, Linux, and macOS

## Installation

```bash
git clone https://github.com/HackerCompagnion7/geo-cli.git
cd geo-cli
chmod +x install.sh
./install.sh
```

The install script automatically detects your package manager (Termux, apt, dnf, pacman, brew) and installs all dependencies.

## Usage

### Basic

```bash
./geo-cli 8.8.8.8
./geo-cli google.com
```

### Options

```
--json       Output raw JSON (for scripting)
--no-map     Skip map rendering (faster)
--verbose    Show extra details (org, AS, ZIP, continent)
-h, --help   Show help message
-v, --version Show version
```

### Examples

```bash
# Basic lookup
./geo-cli 8.8.8.8

# Verbose mode with extra data
./geo-cli 8.8.8.8 --verbose

# JSON output for scripting
./geo-cli 8.8.8.8 --json

# Skip map (fast, text only)
./geo-cli 8.8.8.8 --no-map

# Batch mode — process a file of IPs
./geo-cli ip_list.txt

# Batch with no map for speed
./geo-cli ip_list.txt --no-map
```

### Batch File Format

Create a text file with one IP/domain per line:

```
# Comment lines start with #
8.8.8.8
1.1.1.1
cloudflare.com
208.67.222.222
```

## Output

### Normal mode

```
  ╔═══════════════════════════════════════╗
  ║   geo-cli v2.0.0  ·  IP Geolocation  ║
  ╚═══════════════════════════════════════╝

  ┌──────────────────────────────────────────────────┐
  │                                                  
  │  IP            8.8.8.8 🇺🇸
  │  Location      Ashburn, Virginia, United States
  │  Coordinates   39.03°N, 77.5°W
  │  Timezone      America/New_York
  │  Connection    HOSTING
  │  ISP           Google LLC
  │                                                  
  └──────────────────────────────────────────────────┘

  [ Real map with pin rendered here ]
```

### Connection Types

| Badge | Meaning |
|-------|---------|
| 🟢 RESIDENTIAL | Normal residential connection |
| 🟡 HOSTING | Datacenter / cloud provider |
| 🔴 PROXY | Proxy or VPN detected |

### JSON mode

```json
{
  "status": "success",
  "country": "United States",
  "countryCode": "US",
  "regionName": "Virginia",
  "city": "Ashburn",
  "zip": "20149",
  "lat": 39.03,
  "lon": -77.5,
  "timezone": "America/New_York",
  "isp": "Google LLC",
  "org": "Google Public DNS",
  "as": "AS15169 Google LLC",
  "query": "8.8.8.8",
  "proxy": false,
  "hosting": true
}
```

## How It Works

1. **Resolve** — Domain names are resolved to IP addresses via DNS
2. **Query** — IP geolocation data is fetched from `ip-api.com` (free, no key required)
3. **Project** — Coordinates are converted to pixel positions using equirectangular projection:
   ```
   x = (lon + 180) / 360 × width
   y = (90 - lat) / 180 × height
   ```
4. **Draw** — A red pin (glow + ring + dot) is composited onto the map using ImageMagick or Pillow
5. **Render** — The final image is rendered in the terminal using `chafa` (sixel or symbols mode)

## Project Structure

```
geo-cli/
├── install.sh          # Auto-installation script
├── geo-cli             # Main CLI script
├── assets/
│   └── world_map.png   # Equirectangular map (2048×1024)
└── README.md
```

## Requirements

- Bash 4+
- Terminal with 256-color support
- Internet connection (for API queries)

## Dependencies

| Dependency | Purpose |
|------------|---------|
| `chafa` | Terminal image rendering |
| `imagemagick` or `python3-pillow` | Image manipulation (pin drawing) |
| `curl` | API requests |
| `python3` | JSON parsing |

## License

MIT
