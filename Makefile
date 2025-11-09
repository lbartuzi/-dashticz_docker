# Makefile for Dashticz Docker Container Management

# Variables
COMPOSE = docker-compose
DOCKER = docker
CONTAINER_NAME = dashticz
IMAGE_NAME = dashticz:latest

# Colors for output
GREEN = \033[0;32m
YELLOW = \033[0;33m
RED = \033[0;31m
NC = \033[0m # No Color

.PHONY: help build up down restart logs shell clean status backup restore update

help: ## Show this help message
	@echo "$(GREEN)Dashticz Docker Container Management$(NC)"
	@echo ""
	@echo "Available commands:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-15s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(GREEN)Examples:$(NC)"
	@echo "  make build      # Build the Docker image"
	@echo "  make up         # Start the container"
	@echo "  make logs       # View container logs"

build: ## Build the Docker image
	@echo "$(GREEN)Building Dashticz Docker image...$(NC)"
	$(COMPOSE) build --no-cache
	@echo "$(GREEN)Build complete!$(NC)"

up: ## Start the container (build if needed)
	@echo "$(GREEN)Starting Dashticz container...$(NC)"
	$(COMPOSE) up -d
	@echo "$(GREEN)Dashticz is running at http://localhost:8082$(NC)"

down: ## Stop and remove the container
	@echo "$(YELLOW)Stopping Dashticz container...$(NC)"
	$(COMPOSE) down
	@echo "$(GREEN)Container stopped!$(NC)"

restart: ## Restart the container
	@echo "$(YELLOW)Restarting Dashticz container...$(NC)"
	$(COMPOSE) restart
	@echo "$(GREEN)Container restarted!$(NC)"

logs: ## Show container logs (live)
	@echo "$(GREEN)Showing Dashticz logs (Ctrl+C to exit)...$(NC)"
	$(COMPOSE) logs -f

logs-tail: ## Show last 100 lines of logs
	@echo "$(GREEN)Last 100 lines of logs:$(NC)"
	$(COMPOSE) logs --tail=100

shell: ## Open a shell in the running container
	@echo "$(GREEN)Opening shell in Dashticz container...$(NC)"
	$(DOCKER) exec -it $(CONTAINER_NAME) /bin/bash

status: ## Show container status
	@echo "$(GREEN)Container Status:$(NC)"
	@$(DOCKER) ps -a | grep $(CONTAINER_NAME) || echo "$(RED)Container not found$(NC)"
	@echo ""
	@echo "$(GREEN)Container Details:$(NC)"
	@$(DOCKER) inspect $(CONTAINER_NAME) --format='Name: {{.Name}}\nStatus: {{.State.Status}}\nStarted: {{.State.StartedAt}}\nIP: {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' 2>/dev/null || echo "$(YELLOW)Container not running$(NC)"

clean: ## Remove container, image, and volumes (WARNING: Deletes all data!)
	@echo "$(RED)WARNING: This will delete all Dashticz data!$(NC)"
	@read -p "Are you sure? [y/N] " confirm && [ "$$confirm" = "y" ] || exit 1
	$(COMPOSE) down -v
	$(DOCKER) rmi $(IMAGE_NAME) 2>/dev/null || true
	rm -rf dashticz-data 2>/dev/null || true
	@echo "$(GREEN)Cleanup complete!$(NC)"

backup: ## Backup Dashticz configuration
	@echo "$(GREEN)Creating backup...$(NC)"
	@mkdir -p backups
	@tar -czf backups/dashticz-backup-$$(date +%Y%m%d-%H%M%S).tar.gz dashticz-data/
	@echo "$(GREEN)Backup created in backups/ directory$(NC)"

restore: ## Restore latest backup
	@echo "$(YELLOW)Restoring from latest backup...$(NC)"
	@if [ -z "$$(ls -A backups 2>/dev/null)" ]; then \
		echo "$(RED)No backups found!$(NC)"; \
		exit 1; \
	fi
	@LATEST_BACKUP=$$(ls -t backups/*.tar.gz | head -1); \
	echo "Restoring from: $$LATEST_BACKUP"; \
	tar -xzf $$LATEST_BACKUP
	@echo "$(GREEN)Restore complete!$(NC)"

update: ## Update Dashticz to latest version
	@echo "$(GREEN)Updating Dashticz...$(NC)"
	$(DOCKER) exec $(CONTAINER_NAME) bash -c "cd /var/www/html/dashticz && git pull"
	$(COMPOSE) restart
	@echo "$(GREEN)Update complete!$(NC)"

test: ## Test if Dashticz is responding
	@echo "$(GREEN)Testing Dashticz availability...$(NC)"
	@curl -f http://localhost:8082 > /dev/null 2>&1 && \
		echo "$(GREEN)✓ Dashticz is running and responding$(NC)" || \
		echo "$(RED)✗ Dashticz is not responding$(NC)"

install-dependencies: ## Install Docker and Docker Compose (requires sudo)
	@echo "$(GREEN)Installing Docker and Docker Compose...$(NC)"
	@which docker > /dev/null 2>&1 || (echo "Installing Docker..." && curl -fsSL https://get.docker.com | sh)
	@which docker-compose > /dev/null 2>&1 || (echo "Installing Docker Compose..." && sudo apt-get update && sudo apt-get install -y docker-compose)
	@echo "$(GREEN)Dependencies installed!$(NC)"

config-edit: ## Edit CONFIG.js file
	@echo "$(GREEN)Opening CONFIG.js for editing...$(NC)"
	@if [ -f dashticz-data/custom/CONFIG.js ]; then \
		$${EDITOR:-nano} dashticz-data/custom/CONFIG.js; \
	else \
		echo "$(RED)CONFIG.js not found! Start the container first with 'make up'$(NC)"; \
	fi

# Development targets
dev-build: ## Build with no cache (fresh build)
	$(COMPOSE) build --no-cache

dev-logs-apache: ## Show Apache error logs
	$(DOCKER) exec $(CONTAINER_NAME) tail -f /var/log/apache2/dashticz-error.log

dev-php-info: ## Show PHP configuration
	$(DOCKER) exec $(CONTAINER_NAME) php -i
