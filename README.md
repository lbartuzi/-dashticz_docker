# Dashticz Docker Container

A complete Docker setup for running Dashticz - an alternative dashboard for Domoticz home automation system.

## Features

- **PHP 7.4 with Apache** (can be upgraded to PHP 8.x)
- **All required PHP modules** pre-installed (xml, curl, mbstring, zip, opcache)
- **Automatic configuration** from environment variables
- **Persistent data** storage for custom configurations
- **Health checks** included
- **Easy management** with Make commands
- **Docker Compose** support with .env configuration

## Prerequisites

- Docker installed on your system
- Docker Compose (optional but recommended)
- Git (optional, for updates)

## Quick Start

### 1. Clone or download these files

```bash
# Create a directory for Dashticz
mkdir ~/dashticz-docker
cd ~/dashticz-docker

# Copy all the provided files here
```

### 2. Configure your settings

```bash
# Copy the example environment file
cp .env.example .env

# Edit the .env file with your settings
nano .env
```

Key settings to configure:
- `DOMOTICZ_IP`: Your Domoticz server address (e.g., 192.168.1.100:8080)
- `DASHTICZ_PORT`: Port to access Dashticz (default: 8082)
- `TIMEZONE`: Your timezone (default: Europe/Amsterdam)

### 3. Build and start the container

Using Make (recommended):
```bash
make build    # Build the Docker image
make up       # Start the container
```

Or using Docker Compose directly:
```bash
docker-compose up -d
```

### 4. Access Dashticz

Open your browser and navigate to:
```
http://localhost:8082
```

Or if running on a remote server:
```
http://YOUR_SERVER_IP:8082
```

## Directory Structure

```
dashticz-docker/
├── Dockerfile                 # Docker image definition
├── docker-compose.yml         # Basic Docker Compose config
├── docker-compose-env.yml     # Docker Compose with .env support
├── Makefile                   # Easy management commands
├── .env.example              # Environment variables template
├── .env                      # Your environment configuration (create from .env.example)
└── dashticz-data/            # Persistent data (created automatically)
    ├── custom/               # Your CONFIG.js and custom files
    ├── img/                  # Custom images
    └── logs/                 # Apache logs
```

## Configuration

### Initial Setup

On first run, the container will:
1. Clone the Dashticz repository
2. Copy `CONFIG_DEFAULT.js` to `CONFIG.js`
3. Replace the default Domoticz IP with your configured IP
4. Set up proper permissions

### Custom Configuration

Edit your Dashticz configuration:
```bash
make config-edit
# Or manually edit:
nano dashticz-data/custom/CONFIG.js
```

### Adding Custom Files

Place your custom files in:
- `dashticz-data/custom/` - For CONFIG.js, custom.css, custom.js
- `dashticz-data/img/` - For custom images and icons

## Management Commands

The Makefile provides easy management commands:

```bash
make help          # Show all available commands
make build         # Build the Docker image
make up            # Start the container
make down          # Stop the container
make restart       # Restart the container
make logs          # View live logs
make shell         # Open shell in container
make status        # Check container status
make backup        # Backup configuration
make restore       # Restore from backup
make update        # Update Dashticz to latest
make clean         # Remove everything (WARNING: deletes data!)
```

## Advanced Usage

### Using Different PHP Version

To use PHP 8.x, edit the Dockerfile:
```dockerfile
FROM php:8.2-apache
```

### Running with Domoticz

Uncomment the Domoticz service in docker-compose.yml to run both together:
```yaml
domoticz:
  image: linuxserver/domoticz:latest
  # ... configuration
```

### Custom Apache Configuration

Mount a custom Apache config:
```yaml
volumes:
  - ./custom-apache.conf:/etc/apache2/sites-available/dashticz.conf
```

### Development Mode

For development, mount the entire Dashticz directory:
```yaml
volumes:
  - ./dashticz:/var/www/html/dashticz
```

## Troubleshooting

### Container won't start

Check logs:
```bash
make logs
# Or
docker-compose logs dashticz
```

### Permission issues

Ensure correct ownership:
```bash
sudo chown -R 1000:1000 dashticz-data/
```

### Dashticz not loading

1. Check if container is running:
```bash
make status
```

2. Test connectivity:
```bash
make test
```

3. Check Apache error logs:
```bash
make dev-logs-apache
```

### Cannot connect to Domoticz

Verify Domoticz IP in .env or CONFIG.js:
```bash
# Edit .env
nano .env

# Or edit CONFIG.js directly
make config-edit
```

## Updating

### Update Dashticz
```bash
make update
```

### Update Docker image
```bash
make build
make restart
```

## Backup and Restore

### Create backup
```bash
make backup
```
Backups are stored in `backups/` directory with timestamp.

### Restore from backup
```bash
make restore
```
Restores the most recent backup.

## Security Notes

1. **Change default passwords** in CONFIG.js if authentication is enabled
2. **Use HTTPS** with a reverse proxy (nginx, Traefik) for production
3. **Limit port exposure** - only expose ports you need
4. **Regular updates** - Keep Docker images and Dashticz updated

## Environment Variables

All available environment variables (set in .env):

| Variable | Default | Description |
|----------|---------|-------------|
| DOMOTICZ_IP | 192.168.1.100:8080 | Domoticz server address |
| DASHTICZ_PORT | 8082 | Port to access Dashticz |
| DASHTICZ_BRANCH | master | Git branch (master/beta) |
| TIMEZONE | Europe/Amsterdam | System timezone |
| PHP_MEMORY_LIMIT | 256M | PHP memory limit |
| PHP_MAX_EXECUTION_TIME | 300 | Max execution time |
| PUID | 1000 | User ID for permissions |
| PGID | 1000 | Group ID for permissions |

## Support

- **Dashticz Documentation**: https://dashticz.readthedocs.io/
- **Dashticz GitHub**: https://github.com/Dashticz/dashticz
- **Domoticz Forum**: https://www.domoticz.com/forum/

## License

Dashticz is open source. This Docker setup is provided as-is for easy deployment.

## Contributing

Feel free to submit issues and enhancement requests!
