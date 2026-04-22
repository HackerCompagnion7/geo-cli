# geo-cli

**IP Geolocation CLI with real map rendering in terminal**

A command-line tool that resolves the geolocation of any IP address or domain and renders a real world map directly in your terminal with a precision pin marking the location.

## Features

- Real world map rendered in terminal (not ASCII art)
- Precise pin marker on the geographic location
- Supports both IP addresses and domain names
- Clean, professional ANSI-colored output
- Auto-downloads map image if missing
- Works in Termux, Linux, and macOS

## Installation

```bash
git clone <repo-url>
cd geo-cli
chmod +x install.sh
./install.sh
```

The install script automatically detects your package manager and installs:

| Dependency | Purpose |
|------------|---------|
| `chafa` | Terminal image rendering |
| `imagemagick` | Image manipulation (pin drawing) |
| `curl` | API requests |
| `bc` | Calculations |
| `python3` | JSON parsing |

## Usage

```bash
./geo-cli <ip-address|domain>
```

### Examples

```bash
# Query by IP
./geo-cli 8.8.8.8

# Query another IP
./geo-cli 1.1.1.1

# Query by domain name
./geo-cli google.com
```

### Options

```
-h, --help     Show help message
-v, --version  Show version
```

## Output

The tool displays:

```
  ╔══════════════════════════════════════╗
  ║  geo-cli  ·  IP Geolocation Map      ║
  ╚══════════════════════════════════════╝

  ┌─────────────────────────────────────────────┐
  │  IP:          8.8.8.8
  │  Location:    Mountain View, California, United States
  │  Coordinates: 37.4°N, 122.1°W
  │  ISP:         Google LLC
  └─────────────────────────────────────────────┘

  [ Real map with pin rendered here ]
```

## How It Works

1. **Resolve** — Domain names are resolved to IP addresses via DNS
2. **Query** — IP geolocation data is fetched from `ip-api.com` (free, no key required)
3. **Project** — Coordinates are converted to pixel positions using equirectangular projection:
   ```
   x = (lon + 180) / 360 × width
   y = (90 - lat) / 180 × height
   ```
4. **Draw** — A red pin (glow + ring + dot) is composited onto the map using ImageMagick
5. **Render** — The final image is rendered in the terminal using `chafa`

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

## License

MIT
