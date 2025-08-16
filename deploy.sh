#!/bin/bash

# Retell AI Widget - Complete Deployment Script
# This script handles the full deployment process

set -e

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
DOMAIN=${1:-""}
DEPLOY_TYPE=${2:-"nginx"} # nginx, docker, or manual

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Retell AI Widget Deployment Script   ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
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
    echo -e "${YELLOW}Deploying with Nginx...${NC}"
    
    if [ -z "$DOMAIN" ]; then
        echo -e "${RED}Domain name required for Nginx deployment${NC}"
        echo "Usage: ./deploy.sh yourdomain.com nginx"
        exit 1
    fi
    
    # Run Nginx setup
    sudo ./nginx-setup.sh $DOMAIN
    
    # Setup systemd service
    sudo ./systemd-setup.sh
    
    # Copy built files
    echo "Copying built files to web root..."
    sudo cp -r dist/* /var/www/retell-widget/dist/
    sudo chown -R www-data:www-data /var/www/retell-widget
    
    # Setup SSL
    echo ""
    echo -e "${YELLOW}Setting up SSL certificate...${NC}"
    sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN
    
    echo -e "${GREEN}✓ Nginx deployment complete${NC}"
}

# Function to deploy with Docker
deploy_docker() {
    echo ""
    echo -e "${YELLOW}Deploying with Docker...${NC}"
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}Docker is not installed${NC}"
        exit 1
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
        echo -e "${BLUE}https://$DOMAIN${NC}"
    elif [ "$DEPLOY_TYPE" == "docker" ]; then
        echo "Your widget is now available at:"
        echo -e "${BLUE}http://localhost${NC}"
    fi
    
    echo ""
    echo "Next steps:"
    echo "1. Test the widget by visiting your site"
    echo "2. Monitor logs for any issues"
    echo "3. Set up monitoring and backups"
}

# Run main function
main
