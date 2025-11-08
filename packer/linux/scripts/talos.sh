#!/bin/bash
set -e

################################################################################
# Talos Linux Installation Script with Enhanced Debug Logging
# 
# This script downloads and installs Talos Linux with comprehensive error
# handling, validation, and debug output.
################################################################################

# Configuration
SCRIPT_START_TIME=$(date +%s)
WORK_DIR="${WORK_DIR:-.}"
SCHEMATIC_FILE="$WORK_DIR/schematic.yaml"
TALOS_IMAGE_FILE="/tmp/talos.raw.xz"
TALOS_IMAGE_EXTRACTED="/tmp/talos.raw"
TARGET_DISK="/dev/sda"
FACTORY_URL="https://factory.talos.dev"
SCHEMATIC_ENDPOINT="$FACTORY_URL/schematics"
IMAGE_ENDPOINT="$FACTORY_URL/image"

# Cleanup function
cleanup_on_failure() {
    local exit_code=$?
    local line_number=$1
    
    if [ $exit_code -ne 0 ]; then
        log_error "Script failed at line $line_number with exit code $exit_code"
        log_info "Performing cleanup..."
        
        # Remove temporary files
        if [ -f "$TALOS_IMAGE_FILE" ]; then
            log_debug "Removing temporary image file: $TALOS_IMAGE_FILE"
            rm -f "$TALOS_IMAGE_FILE" || log_warn "Failed to remove $TALOS_IMAGE_FILE"
        fi
        
        if [ -f "$TALOS_IMAGE_EXTRACTED" ]; then
            log_debug "Removing extracted image file: $TALOS_IMAGE_EXTRACTED"
            rm -f "$TALOS_IMAGE_EXTRACTED" || log_warn "Failed to remove $TALOS_IMAGE_EXTRACTED"
        fi
        
        log_error "Installation failed. Please review the logs above."
    fi
    
    exit $exit_code
}

# Set trap to call cleanup on exit
trap 'cleanup_on_failure ${LINENO}' EXIT

################################################################################
# Logging Functions
################################################################################

log_debug() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[DEBUG] [$timestamp] $*" >&2
}

log_info() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[INFO]  [$timestamp] $*" >&2
}

log_warn() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[WARN]  [$timestamp] $*" >&2
}

log_error() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[ERROR] [$timestamp] $*" >&2
}

################################################################################
# Validation Functions
################################################################################

validate_environment_variables() {
    log_info "Validating required environment variables..."
    
    local missing_vars=0
    
    if [ -z "$PACKER_HTTP_IP" ]; then
        log_error "PACKER_HTTP_IP environment variable is not set"
        missing_vars=$((missing_vars + 1))
    else
        log_debug "PACKER_HTTP_IP: $PACKER_HTTP_IP"
    fi
    
    if [ -z "$PACKER_HTTP_PORT" ]; then
        log_error "PACKER_HTTP_PORT environment variable is not set"
        missing_vars=$((missing_vars + 1))
    else
        log_debug "PACKER_HTTP_PORT: $PACKER_HTTP_PORT"
    fi
    
    if [ -z "$OS_VERSION" ]; then
        log_error "OS_VERSION environment variable is not set"
        missing_vars=$((missing_vars + 1))
    else
        log_debug "OS_VERSION: $OS_VERSION"
    fi
    
    if [ $missing_vars -gt 0 ]; then
        log_error "Missing $missing_vars required environment variable(s)"
        return 1
    fi
    
    log_info "All required environment variables are set"
    return 0
}

validate_disk_space() {
    log_info "Checking available disk space..."
    
    # Estimate required space: ~1.5GB for compressed image + 2GB for extraction buffer
    local required_space=$((1500 + 2000))
    local available_space=$(df /tmp | awk 'NR==2 {print int($4/1024)}')
    
    log_debug "Required disk space: ${required_space}MB"
    log_debug "Available disk space in /tmp: ${available_space}MB"
    
    if [ "$available_space" -lt "$required_space" ]; then
        log_error "Insufficient disk space. Required: ${required_space}MB, Available: ${available_space}MB"
        return 1
    fi
    
    log_info "Disk space check passed"
    return 0
}

validate_target_disk() {
    log_info "Validating target disk: $TARGET_DISK"
    
    if [ ! -b "$TARGET_DISK" ]; then
        log_error "Target disk $TARGET_DISK does not exist or is not a block device"
        return 1
    fi
    
    log_debug "Target disk $TARGET_DISK exists"
    
    local disk_size=$(blockdev --getsize64 "$TARGET_DISK" 2>/dev/null || echo "0")
    if [ "$disk_size" -eq 0 ]; then
        log_warn "Could not determine disk size for $TARGET_DISK"
    else
        local disk_size_gb=$((disk_size / 1024 / 1024 / 1024))
        log_debug "Target disk size: ${disk_size_gb}GB"
    fi
    
    log_info "Target disk validation passed"
    return 0
}

################################################################################
# Network Functions
################################################################################

download_schematic() {
    log_info "Downloading Talos schematic from Packer HTTP server..."
    log_debug "URL: http://$PACKER_HTTP_IP:$PACKER_HTTP_PORT/schematic.yaml"
    log_debug "Output file: $SCHEMATIC_FILE"
    
    if ! curl -v -L \
        --max-time 30 \
        --retry 3 \
        --retry-delay 2 \
        "http://$PACKER_HTTP_IP:$PACKER_HTTP_PORT/schematic.yaml" \
        -o "$SCHEMATIC_FILE" 2>&1 | tee /tmp/curl_schematic.log; then
        log_error "Failed to download schematic"
        return 1
    fi
    
    if [ ! -f "$SCHEMATIC_FILE" ]; then
        log_error "Schematic file was not created at $SCHEMATIC_FILE"
        return 1
    fi
    
    local file_size=$(stat -f%z "$SCHEMATIC_FILE" 2>/dev/null || stat -c%s "$SCHEMATIC_FILE" 2>/dev/null || echo "0")
    log_debug "Schematic file size: $file_size bytes"
    
    if [ "$file_size" -eq 0 ]; then
        log_error "Schematic file is empty"
        return 1
    fi
    
    log_info "Schematic downloaded successfully"
    log_debug "Schematic content preview:"
    head -5 "$SCHEMATIC_FILE" | sed 's/^/  /'
    
    return 0
}

generate_schematic_id() {
    log_info "Generating Talos schematic ID..."
    log_debug "Posting schematic to: $SCHEMATIC_ENDPOINT"
    
    if [ ! -f "$SCHEMATIC_FILE" ]; then
        log_error "Schematic file not found at $SCHEMATIC_FILE"
        return 1
    fi
    
    local response
    if ! response=$(curl -v -L -X POST \
        --max-time 60 \
        --retry 3 \
        --retry-delay 2 \
        --data-binary "@$SCHEMATIC_FILE" \
        "$SCHEMATIC_ENDPOINT" 2>&1); then
        log_error "Failed to post schematic to factory"
        log_debug "Response: $response"
        return 1
    fi
    
    log_debug "Factory response:"
    echo "$response" | sed 's/^/  /'
    
    # Extract schematic ID
    SCHEMATIC=$(echo "$response" | grep -o '"id":"[^"]*' | grep -o '[^"]*$' || true)
    
    if [ -z "$SCHEMATIC" ]; then
        log_error "Failed to extract schematic ID from factory response"
        log_debug "Full response was: $response"
        return 1
    fi
    
    log_info "Schematic ID generated successfully: $SCHEMATIC"
    log_debug "Exporting SCHEMATIC=$SCHEMATIC"
    export SCHEMATIC
    
    return 0
}

download_talos_image() {
    log_info "Downloading Talos image..."
    
    local image_url="$IMAGE_ENDPOINT/$SCHEMATIC/v$OS_VERSION/nocloud-amd64.raw.xz"
    log_debug "Image URL: $image_url"
    log_debug "Output file: $TALOS_IMAGE_FILE"
    
    if ! curl -v -L \
        --max-time 300 \
        --retry 3 \
        --retry-delay 5 \
        --progress-bar \
        "$image_url" \
        -o "$TALOS_IMAGE_FILE" 2>&1 | tee /tmp/curl_image.log; then
        log_error "Failed to download Talos image"
        return 1
    fi
    
    if [ ! -f "$TALOS_IMAGE_FILE" ]; then
        log_error "Image file was not created at $TALOS_IMAGE_FILE"
        return 1
    fi
    
    local file_size=$(stat -f%z "$TALOS_IMAGE_FILE" 2>/dev/null || stat -c%s "$TALOS_IMAGE_FILE" 2>/dev/null || echo "0")
    local file_size_mb=$((file_size / 1024 / 1024))
    log_debug "Image file size: ${file_size_mb}MB ($file_size bytes)"
    
    if [ "$file_size" -eq 0 ]; then
        log_error "Image file is empty"
        return 1
    fi
    
    log_info "Talos image downloaded successfully"
    
    return 0
}

################################################################################
# Installation Functions
################################################################################

extract_and_install_image() {
    log_info "Extracting and installing Talos image to $TARGET_DISK..."
    log_debug "Compressed image: $TALOS_IMAGE_FILE"
    log_debug "Target disk: $TARGET_DISK"
    
    if [ ! -f "$TALOS_IMAGE_FILE" ]; then
        log_error "Image file not found at $TALOS_IMAGE_FILE"
        return 1
    fi
    
    log_info "Starting decompression and disk write (this may take several minutes)..."
    log_debug "Command: xz -d -c $TALOS_IMAGE_FILE | dd of=$TARGET_DISK"
    
    # Use pv (pipe viewer) if available for progress, otherwise use dd with status
    if command -v pv &> /dev/null; then
        log_debug "Using pv for progress indication"
        if ! xz -d -c "$TALOS_IMAGE_FILE" | pv -N "Writing to $TARGET_DISK" | dd of="$TARGET_DISK" bs=4M; then
            log_error "Failed to write image to disk"
            return 1
        fi
    else
        log_debug "pv not available, using dd with status=progress"
        if ! xz -d -c "$TALOS_IMAGE_FILE" | dd of="$TARGET_DISK" bs=4M status=progress; then
            log_error "Failed to write image to disk"
            return 1
        fi
    fi
    
    log_info "Syncing filesystem..."
    if ! sync; then
        log_error "Failed to sync filesystem"
        return 1
    fi
    
    log_info "Image extraction and installation completed successfully"
    
    return 0
}

################################################################################
# Main Execution
################################################################################

main() {
    local start_time=$(date '+%Y-%m-%d %H:%M:%S')
    log_info "=========================================="
    log_info "Talos Linux Installation Script Started"
    log_info "Start time: $start_time"
    log_info "=========================================="
    
    # Step 1: Validate environment
    log_info "Step 1/5: Validating environment..."
    if ! validate_environment_variables; then
        log_error "Environment validation failed"
        return 1
    fi
    
    # Step 2: Check disk space
    log_info "Step 2/5: Checking disk space..."
    if ! validate_disk_space; then
        log_error "Disk space check failed"
        return 1
    fi
    
    # Step 3: Validate target disk
    log_info "Step 3/5: Validating target disk..."
    if ! validate_target_disk; then
        log_error "Target disk validation failed"
        return 1
    fi
    
    # Step 4: Download and generate schematic
    log_info "Step 4/5: Downloading schematic and generating ID..."
    if ! download_schematic; then
        log_error "Schematic download failed"
        return 1
    fi
    
    if ! generate_schematic_id; then
        log_error "Schematic ID generation failed"
        return 1
    fi
    
    # Step 5: Download image and install
    log_info "Step 5/5: Downloading and installing Talos image..."
    if ! download_talos_image; then
        log_error "Image download failed"
        return 1
    fi
    
    if ! extract_and_install_image; then
        log_error "Image installation failed"
        return 1
    fi
    
    # Success
    local end_time=$(date '+%Y-%m-%d %H:%M:%S')
    local elapsed=$(($(date +%s) - SCRIPT_START_TIME))
    local elapsed_min=$((elapsed / 60))
    local elapsed_sec=$((elapsed % 60))
    
    log_info "=========================================="
    log_info "Talos Linux Installation Completed Successfully"
    log_info "End time: $end_time"
    log_info "Total time: ${elapsed_min}m ${elapsed_sec}s"
    log_info "=========================================="
    
    return 0
}

# Run main function
main "$@"
