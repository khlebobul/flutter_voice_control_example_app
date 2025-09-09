# Automation of installation and setup
.PHONY: help install-model clean-model run build test deps setup status check-model

# Colors for output
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
NC := \033[0m # No Color

# Variables
# https://github.com/k2-fsa/sherpa-onnx/releases/tag/asr-models

MODEL_URL := https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/sherpa-onnx-streaming-zipformer-en-kroko-2025-08-06.tar.bz2
MODEL_ARCHIVE_FILE := $(notdir $(MODEL_URL))
MODEL_NAME := $(MODEL_ARCHIVE_FILE:.tar.bz2=)
MODEL_DIR := assets/models/$(MODEL_NAME)
MODEL_ARCHIVE := assets/models/$(MODEL_ARCHIVE_FILE)

# Help
help:
	@echo "$(GREEN)Available commands:$(NC)"
	@echo "  $(YELLOW)make install-model$(NC)  - Install speech recognition model"
	@echo "  $(YELLOW)make clean-model$(NC)   - Remove speech recognition model"
	@echo "  $(YELLOW)make run$(NC)           - Run the application"
	@echo "  $(YELLOW)make build$(NC)         - Build the application"
	@echo "  $(YELLOW)make test$(NC)          - Run tests"
	@echo "  $(YELLOW)make clean$(NC)         - Clean build"
	@echo "  $(YELLOW)make help$(NC)          - Show this help"

# Install speech recognition model
install-model:
	@echo "$(GREEN)Installing speech recognition model...$(NC)"
	@if [ -d "$(MODEL_DIR)" ]; then \
		echo "$(YELLOW)Model is already installed.$(NC)"; \
		exit 0; \
	fi
	@echo "$(YELLOW)Downloading model...$(NC)"
	@mkdir -p assets/models
	@cd assets/models && wget -q --show-progress $(MODEL_URL)
	@if [ $$? -ne 0 ]; then \
		echo "$(RED)Error downloading model. Check your internet connection.$(NC)"; \
		exit 1; \
	fi
	@echo "$(YELLOW)Extracting archive...$(NC)"
	@cd assets/models && tar xf $(MODEL_ARCHIVE_FILE)
	@if [ $$? -ne 0 ]; then \
		echo "$(RED)Error extracting archive.$(NC)"; \
		exit 1; \
	fi
	@echo "$(YELLOW)Removing unnecessary files...$(NC)"
	@rm -rf $(MODEL_DIR)/test_wavs
	@rm -f $(MODEL_DIR)/README.md
	@rm -f $(MODEL_DIR)/bpe*
	@rm -f $(MODEL_DIR)/encoder-epoch-99-avg-1.onnx
	@rm -f $(MODEL_DIR)/decoder-epoch-99-avg-1.int8.onnx
	@rm -f $(MODEL_DIR)/joiner-epoch-99-avg-1.int8.onnx
	@rm -f $(MODEL_ARCHIVE)
	@echo "$(GREEN)Model installed successfully!$(NC)"
	@echo "$(YELLOW)File structure:$(NC)"
	@echo "assets/models/"
	@echo "└── $(MODEL_NAME)/"
	@echo "    ├── encoder*.onnx (or *.int8.onnx)"
	@echo "    ├── decoder*.onnx"
	@echo "    ├── joiner*.onnx"
	@echo "    └── tokens.txt"
	@echo "$(GREEN)Now you can run the application: make run$(NC)"

# Remove model
clean-model:
	@echo "$(YELLOW)Removing speech recognition model...$(NC)"
	@rm -rf $(MODEL_DIR)
	@rm -f $(MODEL_ARCHIVE)
	@echo "$(GREEN)Model removed.$(NC)"

# Run the application
run: check-model
	@echo "$(GREEN)Running the application...$(NC)"
	@flutter run

# Build the application
build: check-model
	@echo "$(GREEN)Building the application...$(NC)"
	@flutter build

# Run tests
test:
	@echo "$(GREEN)Running tests...$(NC)"
	@flutter test

# Clean build
clean:
	@echo "$(YELLOW)Cleaning build...$(NC)"
	@flutter clean
	@flutter pub get

# Check for model
check-model:
	@if [ ! -d "$(MODEL_DIR)" ]; then \
		echo "$(RED)Speech recognition model not found!$(NC)"; \
		echo "$(YELLOW)Install the model with: make install-model$(NC)"; \
		exit 1; \
	fi
	@if [ -z "$(shell ls $(MODEL_DIR)/decoder*.onnx 2>/dev/null)" ] || \
	   [ -z "$(shell ls $(MODEL_DIR)/encoder*.onnx 2>/dev/null)" ] || \
	   [ -z "$(shell ls $(MODEL_DIR)/joiner*.onnx 2>/dev/null)" ] || \
	   [ ! -f "$(MODEL_DIR)/tokens.txt" ]; then \
		echo "$(RED)Model is corrupted! Remove and reinstall:$(NC)"; \
		echo "$(YELLOW)   make clean-model && make install-model$(NC)"; \
		exit 1; \
	fi
	@echo "$(GREEN)Speech recognition model is ready to use.$(NC)"

# Install dependencies
deps:
	@echo "$(GREEN)Installing dependencies...$(NC)"
	@flutter pub get

# Full setup (dependencies + model)
setup: deps install-model
	@echo "$(GREEN)Full setup complete!$(NC)"
	@echo "$(YELLOW)Run the application: make run$(NC)"

# Status check
status:
	@echo "$(GREEN)Project status:$(NC)"
	@echo "$(YELLOW)Flutter SDK:$(NC)"
	@flutter --version | head -1
	@echo "$(YELLOW)Dependencies:$(NC)"
	@if [ -f "pubspec.lock" ]; then \
		echo "  Installed"; \
	else \
		echo "  Not installed (run: make deps)"; \
	fi
	@echo "$(YELLOW)Speech recognition model:$(NC)"
	@if [ -d "$(MODEL_DIR)" ]; then \
		echo "  Installed"; \
	else \
		echo "  Not installed (run: make install-model)"; \
	fi
	@echo "$(YELLOW)Ready to run:$(NC)"
	@if [ -d "$(MODEL_DIR)" ] && [ -f "pubspec.lock" ]; then \
		echo "  Ready (run: make run)"; \
	else \
		echo "  Not ready (run: make setup)"; \
	fi
