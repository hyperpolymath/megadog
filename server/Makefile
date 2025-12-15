# MegaDog Server Makefile
# RSR Compliant: Pony Actor Model

PONYC := ponyc
CORRAL := corral
BUILD_DIR := build
SRC_DIR := src
TARGET := megadog-server

# Build flags
DEBUG_FLAGS := --debug
RELEASE_FLAGS := -O3 --runtimebc

.PHONY: all build release debug test clean run deps fmt check

all: build

# Fetch dependencies
deps:
	@echo "Fetching dependencies..."
	$(CORRAL) fetch

# Debug build (default)
build: deps
	@echo "Building $(TARGET) (debug)..."
	@mkdir -p $(BUILD_DIR)
	$(PONYC) $(DEBUG_FLAGS) $(SRC_DIR) -o $(BUILD_DIR) -b $(TARGET)
	@echo "Build complete: $(BUILD_DIR)/$(TARGET)"

# Release build with optimizations
release: deps
	@echo "Building $(TARGET) (release)..."
	@mkdir -p $(BUILD_DIR)
	$(PONYC) $(RELEASE_FLAGS) $(SRC_DIR) -o $(BUILD_DIR) -b $(TARGET)
	@echo "Release build complete: $(BUILD_DIR)/$(TARGET)"

# Debug build
debug: deps
	@echo "Building $(TARGET) (debug)..."
	@mkdir -p $(BUILD_DIR)
	$(PONYC) $(DEBUG_FLAGS) $(SRC_DIR) -o $(BUILD_DIR) -b $(TARGET)
	@echo "Debug build complete: $(BUILD_DIR)/$(TARGET)"

# Run tests
test: deps
	@echo "Running tests..."
	$(PONYC) --debug $(SRC_DIR) -o $(BUILD_DIR) -b $(TARGET)-test
	./$(BUILD_DIR)/$(TARGET)-test

# Syntax check without building
check: deps
	@echo "Checking syntax..."
	$(PONYC) --pass=syntax $(SRC_DIR)
	@echo "Syntax check passed"

# Format code (if pony-fmt available)
fmt:
	@echo "Formatting code..."
	@find $(SRC_DIR) -name "*.pony" -exec pony-fmt {} \; 2>/dev/null || echo "pony-fmt not available"

# Clean build artifacts
clean:
	@echo "Cleaning..."
	@rm -rf $(BUILD_DIR)
	@rm -f $(SRC_DIR)/*.o
	@echo "Clean complete"

# Run the server
run: build
	@echo "Starting MegaDog server..."
	./$(BUILD_DIR)/$(TARGET)

# Run with hot reload (requires entr)
watch:
	@echo "Watching for changes..."
	@find $(SRC_DIR) -name "*.pony" | entr -r make run

# Build container image
container:
	@echo "Building container image..."
	podman build -t megadog-server:latest -f Containerfile .

# Run in container
container-run: container
	podman run -it --rm -p 8080:8080 megadog-server:latest

# Print help
help:
	@echo "MegaDog Server Build System"
	@echo ""
	@echo "Targets:"
	@echo "  all       - Build debug version (default)"
	@echo "  build     - Build debug version"
	@echo "  release   - Build optimized release version"
	@echo "  debug     - Build with debug symbols"
	@echo "  test      - Run tests"
	@echo "  check     - Syntax check only"
	@echo "  fmt       - Format code"
	@echo "  clean     - Remove build artifacts"
	@echo "  run       - Build and run server"
	@echo "  watch     - Build and run with hot reload"
	@echo "  container - Build container image"
	@echo "  help      - Show this help"
