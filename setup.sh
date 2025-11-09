#!/bin/bash

# Dashticz Docker Quick Setup Script
# This script automates the initial setup process

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

print_header() {
    echo -e "\n${GREEN}========================================${NC}"
    echo -e "${GREEN}    Dashticz Docker Setup Script${NC}"
    echo -e "${GREEN}========================================${NC}\n"
}

# Check for required commands
check_requirements() {
    local missing_deps=()
    
    if ! command -v docker &> /dev/null; then
        missing_deps+=("docker")
    fi
    
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null 2>&1; then
        missing_deps+=("docker-compose")
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_error "Missing required dependencies: ${missing_deps[*]}"
        echo "Would you like to install them? (requires sudo)"
        read -p "Install dependencies? [y/N]: " install_deps
        
        if [[ "$install_deps" =~ ^[Yy]$ ]]; then
            install_dependencies
        else
            echo "Please install Docker and Docker Compose manually and run this script again."
            exit 1
        fi
    else
        print_success "All requirements met!"
    fi
}

install_dependencies() {
    print_info "Installing Docker and Docker Compose..."
    
    # Install Docker
    if ! command -v docker &> /dev/null; then
        curl -fsSL https://get.docker.com | sudo sh
        sudo usermod -aG docker $USER
        print_success "Docker installed!"
    fi
    
    # Install Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        sudo apt-get update
        sudo apt-get install -y docker-compose
        print_success "Docker Compose installed!"
    fi
    
    print_info "You may need to log out and back in for Docker group changes to take effect."
}

# Setup configuration
setup_config() {
    print_info "Setting up configuration..."
    
    # Copy .env.example to .env if it doesn't exist
    if [ ! -f .env ]; then
        if [ -f .env.example ]; then
            cp .env.example .env
            print_success "Created .env from .env.example"
        else
            print_error ".env.example not found!"
            exit 1
        fi
    else
        print_info ".env already exists, skipping..."
    fi
    
    # Ask for Domoticz IP
    echo -e "\n${YELLOW}Please provide your Domoticz configuration:${NC}"
    read -p "Domoticz IP:Port (default: 192.168.1.100:8080): " domoticz_ip
    domoticz_ip=${domoticz_ip:-192.168.1.100:8080}
    
    # Update .env with Domoticz IP
    sed -i "s/DOMOTICZ_IP=.*/DOMOTICZ_IP=$domoticz_ip/" .env
    print_success "Updated Domoticz IP to: $domoticz_ip"
    
    # Ask for port
    read -p "Dashticz port (default: 8082): " dashticz_port
    dashticz_port=${dashticz_port:-8082}
    sed -i "s/DASHTICZ_PORT=.*/DASHTICZ_PORT=$dashticz_port/" .env
    print_success "Updated Dashticz port to: $dashticz_port"
    
    # Ask for branch
    echo -e "\nWhich Dashticz branch would you like to use?"
    echo "  1) master (stable)"
    echo "  2) beta (latest features)"
    read -p "Select branch [1-2] (default: 1): " branch_choice
    
    case $branch_choice in
        2)
            sed -i "s/DASHTICZ_BRANCH=.*/DASHTICZ_BRANCH=beta/" .env
            print_success "Using beta branch"
            ;;
        *)
            sed -i "s/DASHTICZ_BRANCH=.*/DASHTICZ_BRANCH=master/" .env
            print_success "Using master branch"
            ;;
    esac
}

# Build options
select_build() {
    echo -e "\n${YELLOW}Select Docker image type:${NC}"
    echo "  1) Standard (Debian-based, ~400MB, more compatible)"
    echo "  2) Alpine (Lightweight, ~100MB, smaller footprint)"
    read -p "Select image [1-2] (default: 1): " image_choice
    
    case $image_choice in
        2)
            # Use Alpine Dockerfile
            mv docker-compose.yml docker-compose.debian.yml 2>/dev/null || true
            sed 's/Dockerfile/Dockerfile.alpine/' docker-compose-env.yml > docker-compose.yml
            print_success "Using Alpine image"
            ;;
        *)
            # Use standard Dockerfile
            if [ -f docker-compose-env.yml ]; then
                cp docker-compose-env.yml docker-compose.yml
            fi
            print_success "Using standard Debian image"
            ;;
    esac
}

# Build and start
build_and_start() {
    echo -e "\n${YELLOW}Building and starting Dashticz...${NC}"
    
    # Build image
    print_info "Building Docker image (this may take a few minutes)..."
    if docker-compose build --quiet 2>/dev/null; then
        print_success "Docker image built successfully!"
    else
        docker-compose build
    fi
    
    # Start container
    print_info "Starting container..."
    if docker-compose up -d; then
        print_success "Container started successfully!"
    else
        print_error "Failed to start container"
        exit 1
    fi
    
    # Wait for container to be ready
    print_info "Waiting for Dashticz to be ready..."
    sleep 5
    
    # Check if container is running
    if docker ps | grep -q dashticz; then
        print_success "Dashticz is running!"
    else
        print_error "Container is not running. Check logs with: docker-compose logs"
        exit 1
    fi
}

# Display success message
show_success() {
    local port=$(grep DASHTICZ_PORT .env | cut -d'=' -f2)
    port=${port:-8082}
    
    echo -e "\n${GREEN}========================================${NC}"
    echo -e "${GREEN}     Dashticz Setup Complete! 🎉${NC}"
    echo -e "${GREEN}========================================${NC}\n"
    
    print_success "Dashticz is now available at:"
    echo -e "  ${GREEN}http://localhost:${port}${NC}"
    
    if [ -f /etc/hostname ]; then
        local hostname=$(cat /etc/hostname)
        echo -e "  ${GREEN}http://${hostname}:${port}${NC}"
    fi
    
    # Get container IP if possible
    local container_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' dashticz 2>/dev/null)
    if [ ! -z "$container_ip" ]; then
        echo -e "  ${GREEN}http://${container_ip}${NC} (container IP)"
    fi
    
    echo -e "\n${YELLOW}Useful commands:${NC}"
    echo "  View logs:        make logs"
    echo "  Stop container:   make down"
    echo "  Restart:          make restart"
    echo "  Edit config:      make config-edit"
    echo "  Show all:         make help"
    
    echo -e "\n${YELLOW}Configuration files:${NC}"
    echo "  Main config:      dashticz-data/custom/CONFIG.js"
    echo "  Custom CSS:       dashticz-data/custom/custom.css"
    echo "  Custom JS:        dashticz-data/custom/custom.js"
    
    echo -e "\n${GREEN}Enjoy your Dashticz dashboard!${NC}\n"
}

# Main execution
main() {
    print_header
    
    # Check if we're in the right directory
    if [ ! -f "Dockerfile" ] || [ ! -f "docker-compose.yml" ] && [ ! -f "docker-compose-env.yml" ]; then
        print_error "Required files not found. Please run this script in the Dashticz Docker directory."
        exit 1
    fi
    
    check_requirements
    setup_config
    select_build
    build_and_start
    show_success
}

# Handle errors
trap 'print_error "An error occurred. Exiting..."; exit 1' ERR

# Run main function
main
