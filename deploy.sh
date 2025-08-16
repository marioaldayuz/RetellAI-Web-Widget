#!/bin/bash

# Retell AI Widget - Complete Deployment Script
# Domain Agnostic Version

set -e

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Parse command line arguments
DOMAIN=""
DEPLOY_TYPE="nginx"
EMAIL=""
INCLUDE_WWW="auto"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --no-www)
            INCLUDE_WWW="false"
            shift
            ;;
        --www)
            INCLUDE_WWW="true"
            shift
            ;;
        --help|-h)
            show_usage
            exit 0
            ;;
        *)
            if [ -z "$DOMAIN" ]; then
                DOMAIN="$1"
            elif [ -z "$DEPLOY_TYPE" ] || [[ "$1" =~ ^(nginx|docker|manual)$ ]]; then
                DEPLOY_TYPE="$1"
            elif [[ "$1" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
                EMAIL="$1"
            fi
            shift
            ;;
    esac
done

# Auto-detect www support if not explicitly set
if [ "$INCLUDE_WWW" = "auto" ]; then
    # Count dots in domain - if more than 1, it's likely a subdomain
    dot_count=$(echo "$DOMAIN" | tr -cd '.' | wc -c)
    if [ "$dot_count" -gt 1 ]; then
        INCLUDE_WWW="false"  # Subdomain - skip www
    else
        INCLUDE_WWW="true"   # Root domain - include www
    fi
fi

# Function to display usage
show_usage() {
    echo "Usage: $0 <domain> [deploy_type] [email] [options]"
    echo ""
    echo "Arguments:"
    echo "  domain       - Your domain name (required for nginx deployment)"
    echo "  deploy_type  - Deployment type: nginx, docker, or manual (default: nginx)"
    echo "  email        - Email for SSL certificate (optional)"
    echo ""
    echo "Options:"
    echo "  --www        - Force include www subdomain"
    echo "  --no-www     - Force exclude www subdomain"
    echo "  --help, -h   - Show this help"
    echo ""
    echo "Auto-detection:"
    echo "  - Root domains (example.com) → includes www.example.com"
    echo "  - Subdomains (api.example.com) → no www support"
    echo ""
    echo "Examples:"
    echo "  $0 example.com                           # includes www.example.com"
    echo "  $0 api.example.com                       # no www (auto-detected)"
    echo "  $0 example.com nginx admin@example.com"
    echo "  $0 example.com --no-www                  # no www (explicit)"
    echo "  $0 localhost docker"
    echo ""
}

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Retell AI Widget Deployment Script   ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Validate inputs based on deployment type
if [ "$DEPLOY_TYPE" == "nginx" ] && [ -z "$DOMAIN" ]; then
    echo -e "${RED}Error: Domain name is required for nginx deployment!${NC}"
    echo ""
    show_usage
    exit 1
fi

if [ -n "$DOMAIN" ]; then
    echo -e "${BLUE}Domain: $DOMAIN${NC}"
fi
echo -e "${BLUE}Deployment Type: $DEPLOY_TYPE${NC}"
echo ""

# Function to check prerequisites
check_prerequisites() {
    echo -e "${YELLOW}Checking prerequisites...${NC}"
    
    # Check Node.js
    if ! command -v node &> /dev/null; then
        echo -e "${RED}✗ Node.js is not installed${NC}"
        exit 1
    else
        echo -e "${GREEN}✓ Node.js $(node -v)${NC}"
    fi
    
    # Check npm
    if ! command -v npm &> /dev/null; then
        echo -e "${RED}✗ npm is not installed${NC}"
        exit 1
    else
        echo -e "${GREEN}✓ npm $(npm -v)${NC}"
    fi
    
    # Check .env file
    if [ ! -f .env ]; then
        echo -e "${RED}✗ .env file not found${NC}"
        echo "Please create a .env file with your RETELL_API_KEY"
        echo ""
        echo "Creating .env from template..."
        if [ -f .env.example ]; then
            cp .env.example .env
            echo -e "${YELLOW}Created .env from .env.example - Please add your RETELL_API_KEY${NC}"
        else
            echo "RETELL_API_KEY=your_key_here" > .env
            echo -e "${YELLOW}Created basic .env - Please add your RETELL_API_KEY${NC}"
        fi
        exit 1
    else
        echo -e "${GREEN}✓ .env file found${NC}"
    fi
}

# Function to build the project
build_project() {
    echo ""
    echo -e "${YELLOW}Building the project...${NC}"
    
    # Install dependencies
    echo "Installing frontend dependencies..."
    npm install
    
    echo "Installing backend dependencies..."
    cd server
    npm install
    cd ..
    
    # Build frontend
    echo "Building frontend..."
    npm run build
    
    echo -e "${GREEN}✓ Project built successfully${NC}"
}

# Function to deploy with Nginx
deploy_nginx() {
    echo ""
    echo -e "${YELLOW}Deploying with Nginx for $DOMAIN...${NC}"
    
    # Make scripts executable
    chmod +x nginx-setup-fixed.sh enable-ssl.sh systemd-setup.sh
    
    # Run Nginx setup
    if [ "$INCLUDE_WWW" = "true" ]; then
        sudo ./nginx-setup-fixed.sh $DOMAIN 3001 5173 $EMAIL --www
    else
        sudo ./nginx-setup-fixed.sh $DOMAIN 3001 5173 $EMAIL --no-www
    fi
    
    # Setup systemd service
    if [ -f systemd-setup.sh ]; then
        sudo ./systemd-setup.sh
    fi
    
    # Copy built files
    echo "Copying built files to web root..."
    sudo cp -r dist/* /var/www/retell-widget/dist/
    sudo chown -R www-data:www-data /var/www/retell-widget
    
    # Setup SSL
    echo ""
    echo -e "${YELLOW}Setting up SSL certificate for $DOMAIN...${NC}"
    
    if [ -n "$EMAIL" ]; then
        if [ "$INCLUDE_WWW" = "true" ]; then
            sudo certbot certonly --webroot -w /var/www/certbot -d $DOMAIN -d www.$DOMAIN --non-interactive --agree-tos --email $EMAIL
        else
            sudo certbot certonly --webroot -w /var/www/certbot -d $DOMAIN --non-interactive --agree-tos --email $EMAIL
        fi
    else
        echo -e "${YELLOW}No email provided. Certbot will prompt for email.${NC}"
        if [ "$INCLUDE_WWW" = "true" ]; then
            sudo certbot certonly --webroot -w /var/www/certbot -d $DOMAIN -d www.$DOMAIN
        else
            sudo certbot certonly --webroot -w /var/www/certbot -d $DOMAIN
        fi
    fi
    
    # Enable SSL
    if [ "$INCLUDE_WWW" = "true" ]; then
        sudo ./enable-ssl.sh $DOMAIN --www
    else
        sudo ./enable-ssl.sh $DOMAIN --no-www
    fi
    
    echo -e "${GREEN}✓ Nginx deployment complete${NC}"
}

# Function to deploy with Docker
deploy_docker() {
    echo ""
    echo -e "${YELLOW}Deploying with Docker...${NC}"
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}Docker is not installed${NC}"
        echo "Please install Docker first: https://docs.docker.com/get-docker/"
        exit 1
    fi
    
    # Check docker-compose
    if ! command -v docker-compose &> /dev/null; then
        echo -e "${YELLOW}Installing docker-compose...${NC}"
        sudo apt-get update
        sudo apt-get install -y docker-compose
    fi
    
    # Build and start containers
    docker-compose build
    docker-compose up -d
    
    echo -e "${GREEN}✓ Docker deployment complete${NC}"
    echo "Containers are running. Check logs with: docker-compose logs -f"
}

# Function for manual deployment
deploy_manual() {
    echo ""
    echo -e "${YELLOW}Manual deployment instructions:${NC}"
    echo ""
    echo "1. Start the backend server:"
    echo "   cd server && npm start"
    echo ""
    echo "2. Serve the frontend files from dist/ directory"
    echo "   - Use any static file server"
    echo "   - Or upload to CDN/hosting service"
    echo ""
    echo "3. Configure your reverse proxy to:"
    echo "   - Route /api/* to backend server (port 3001)"
    echo "   - Serve static files from dist/"
    echo ""
    if [ -n "$DOMAIN" ]; then
        echo "4. Configure SSL for $DOMAIN"
        echo "   - Use Let's Encrypt or your SSL provider"
        echo "   - Point domain to your server IP"
    fi
    echo ""
    echo -e "${GREEN}Build complete. Files ready in dist/ directory${NC}"
}

# Main deployment flow
main() {
    check_prerequisites
    build_project
    
    case $DEPLOY_TYPE in
        nginx)
            deploy_nginx
            ;;
        docker)
            deploy_docker
            ;;
        manual)
            deploy_manual
            ;;
        *)
            echo -e "${RED}Invalid deployment type: $DEPLOY_TYPE${NC}"
            echo "Valid options: nginx, docker, manual"
            show_usage
            exit 1
            ;;
    esac
    
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║     Deployment Complete! 🎉            ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
    echo ""
    
    if [ "$DEPLOY_TYPE" == "nginx" ]; then
        echo "Your widget is now available at:"
        echo -e "${BLUE}🔒 https://$DOMAIN${NC}"
    elif [ "$DEPLOY_TYPE" == "docker" ]; then
        echo "Your widget is now available at:"
        echo -e "${BLUE}http://localhost${NC}"
        if [ -n "$DOMAIN" ]; then
            echo -e "${BLUE}Configure your domain $DOMAIN to point to this server${NC}"
        fi
    fi
    
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "1. Test the widget by visiting your site"
    echo "2. Monitor logs for any issues:"
    if [ "$DEPLOY_TYPE" == "nginx" ]; then
        echo "   • Nginx: sudo tail -f /var/log/nginx/${DOMAIN}-*.log"
        echo "   • Backend: sudo journalctl -u retell-backend -f"
    elif [ "$DEPLOY_TYPE" == "docker" ]; then
        echo "   • Docker: docker-compose logs -f"
    fi
    echo "3. Set up monitoring and backups"
    echo "4. Configure firewall rules if needed"
}

# Run main function
main
