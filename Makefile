SHELL := /bin/zsh
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := help
.NOTPARALLEL:
MAKEFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))

MODEL ?= qwen3.5:4b
OLLAMA_URL ?= http://127.0.0.1:11434
CONTEXT_TOKENS ?= 32768
PROMPT_TOKENS ?= 24576
OUTPUT_TOKENS ?= 4096
LOCAL_MODEL ?= local-coding-$(subst :,-,$(notdir $(MODEL)))-$(CONTEXT_TOKENS)
START_TIMEOUT ?= 60
VERIFY_TIMEOUT ?= 300
MIN_MEMORY_GIB ?= $(if $(filter qwen3.5:9b,$(MODEL)),16,8)
MIN_DISK_GIB ?= 10
COPILOT_ARGS ?=
COPILOT_LOCAL_HOME ?= $(HOME)/.copilot-local-offline
OLLAMA_MODELS_DIR ?= $(HOME)/.ollama/models
OLLAMA_LAUNCH_AGENT ?= $(HOME)/Library/LaunchAgents/sh.brew.ollama.plist
COLOR ?= auto
CURL = curl --noproxy '*' --connect-timeout 2
OLLAMA = env OLLAMA_HOST="$(OLLAMA_URL)" ollama

COLOR_ENABLED := $(shell if [ "$(COLOR)" = "always" ] || { \
	[ "$(COLOR)" = "auto" ] && [ -t 2 ] && [ -z "$${NO_COLOR+x}" ] && \
	[ "$${TERM:-}" != "dumb" ]; \
}; then printf yes; fi)

ifeq ($(COLOR_ENABLED),yes)
BOLD := \033[1m
DIM := \033[2m
RED := \033[31m
GREEN := \033[32m
YELLOW := \033[33m
CYAN := \033[36m
RESET := \033[0m
endif

INFO := $(CYAN)[INFO]$(RESET)
OK := $(GREEN)[ OK ]$(RESET)
SKIP := $(DIM)[SKIP]$(RESET)
WARN := $(YELLOW)[WARN]$(RESET)
FAIL := $(RED)[FAIL]$(RESET)

COPILOT_LOCAL = env \
	-u COPILOT_PROVIDER_API_KEY \
	-u COPILOT_PROVIDER_API_KEY_COMMAND \
	-u COPILOT_PROVIDER_BEARER_TOKEN \
	-u COPILOT_PROVIDER_HEADERS \
	-u COPILOT_PROVIDER_MODEL_ID \
	-u COPILOT_PROVIDER_WIRE_MODEL \
	-u COPILOT_ALLOW_ALL \
	-u COPILOT_CUSTOM_INSTRUCTIONS_DIRS \
	-u COPILOT_GITHUB_TOKEN \
	-u GH_TOKEN \
	-u GITHUB_TOKEN \
	-u COPILOT_OTEL_FILE_EXPORTER_PATH \
	-u OTEL_EXPORTER_OTLP_ENDPOINT \
	-u OTEL_EXPORTER_OTLP_TRACES_ENDPOINT \
	-u OTEL_EXPORTER_OTLP_METRICS_ENDPOINT \
	-u OTEL_EXPORTER_OTLP_HEADERS \
	-u HTTP_PROXY \
	-u HTTPS_PROXY \
	-u http_proxy \
	-u https_proxy \
	-u ALL_PROXY \
	-u all_proxy \
	COPILOT_HOME="$(COPILOT_LOCAL_HOME)" \
	COPILOT_PROVIDER_TYPE=openai \
	COPILOT_PROVIDER_BASE_URL="$(OLLAMA_URL)/v1" \
	COPILOT_PROVIDER_WIRE_API=completions \
	COPILOT_PROVIDER_TRANSPORT=http \
	COPILOT_MODEL="$(LOCAL_MODEL)" \
	COPILOT_PROVIDER_MAX_PROMPT_TOKENS=$(PROMPT_TOKENS) \
	COPILOT_PROVIDER_MAX_OUTPUT_TOKENS=$(OUTPUT_TOKENS) \
	COPILOT_OFFLINE=true \
	COPILOT_AUTO_UPDATE=false \
	COPILOT_OTEL_ENABLED=false \
	OTEL_SDK_DISABLED=true \
	OTEL_INSTRUMENTATION_GENAI_CAPTURE_MESSAGE_CONTENT=false \
	NO_PROXY=127.0.0.1,localhost \
	no_proxy=127.0.0.1,localhost \
	copilot --model "$(LOCAL_MODEL)" --disable-builtin-mcps --no-auto-update \
		--no-remote-export

.PHONY: help setup check-macos check-brew check-capacity prepare-copilot-home \
	install-ollama install-copilot install-jq start-ollama pull-model configure-model start stop status \
	check-config check-state verify verify-ollama verify-copilot docs docs-serve

help:
	@printf '\n$(BOLD)Local Ollama + GitHub Copilot CLI$(RESET)\n'
	@printf 'A private, offline coding assistant for macOS.\n\n'
	@printf '$(BOLD)Usage$(RESET)\n  make $(CYAN)<target>$(RESET)\n\n'
	@printf '$(BOLD)Targets$(RESET)\n'
	@printf '  $(CYAN)%-12s$(RESET) %s\n' \
		'setup' 'Install tools, start Ollama, and download the model' \
		'start' 'Start Ollama and open Copilot CLI with the local model' \
		'stop' 'Stop Ollama (exit Copilot separately from its UI)' \
		'status' 'Show service, API, and model status' \
		'check-state' 'Validate required external files and services' \
		'verify' 'Test inference and Copilot tool execution' \
		'docs' 'Build the documentation site into site/, failing on any warning' \
		'docs-serve' 'Preview the documentation site at http://localhost:8000' \
		'help' 'Show this help'
	@printf '\n$(BOLD)Overrides$(RESET)\n'
	@printf '  MODEL=%s OLLAMA_URL=%s\n' \
		'$(MODEL)' '$(OLLAMA_URL)'
	@printf '  CONTEXT_TOKENS=%s PROMPT_TOKENS=%s OUTPUT_TOKENS=%s\n' \
		'$(CONTEXT_TOKENS)' '$(PROMPT_TOKENS)' '$(OUTPUT_TOKENS)'
	@printf '  COPILOT_LOCAL_HOME=$$HOME/.copilot-local-offline\n'
	@printf '  COLOR=always|never  $(DIM)(or set NO_COLOR=1)$(RESET)\n\n'

setup: check-macos check-brew check-capacity install-jq install-ollama install-copilot configure-model
	@$(MAKE) --no-print-directory -f "$(MAKEFILE_PATH)" check-state
	@printf '\n$(OK) $(BOLD)Setup complete.$(RESET) Run "make verify" or "make start".\n'

check-macos:
	@if [ "$$(uname -s)" != "Darwin" ]; then \
		printf '$(FAIL) This Makefile supports macOS only.\n' >&2; \
		exit 1; \
	fi
	@if [ "$$(uname -m)" != "arm64" ]; then \
		printf '$(FAIL) This setup requires an Apple Silicon Mac.\n' >&2; exit 1; \
	fi

check-config:
	@if [ "$(PROMPT_TOKENS)" -le 0 ] || [ "$(OUTPUT_TOKENS)" -le 0 ] || \
		[ "$$(( $(PROMPT_TOKENS) + $(OUTPUT_TOKENS) ))" -gt "$(CONTEXT_TOKENS)" ]; then \
		printf '$(FAIL) Positive prompt and output budgets must fit within CONTEXT_TOKENS.\n' >&2; \
		exit 1; \
	fi

check-brew: check-macos
	@if ! command -v brew >/dev/null 2>&1; then \
		printf '$(FAIL) %s\n' \
			'Homebrew is required.' \
			'Install it from https://brew.sh and run "make setup" again.' >&2; \
		exit 1; \
	fi

check-capacity: check-macos check-config
	@memory_bytes="$$(sysctl -n hw.memsize)"; \
	minimum_bytes="$$(( $(MIN_MEMORY_GIB) * 1024 * 1024 * 1024 ))"; \
	if [ "$$memory_bytes" -lt "$$minimum_bytes" ]; then \
		printf '$(FAIL) %s GiB unified memory is required; this Mac has %s GiB.\n' \
			"$(MIN_MEMORY_GIB)" "$$(( memory_bytes / 1024 / 1024 / 1024 ))" >&2; \
		exit 1; \
	fi; \
	free_kib="$$(df -Pk "$$HOME" | awk 'NR == 2 { print $$4 }')"; \
	minimum_kib="$$(( $(MIN_DISK_GIB) * 1024 * 1024 ))"; \
	if [ "$$free_kib" -lt "$$minimum_kib" ]; then \
		printf '$(FAIL) %s GiB free disk is required; only %s GiB is available.\n' \
			"$(MIN_DISK_GIB)" "$$(( free_kib / 1024 / 1024 ))" >&2; \
		exit 1; \
	fi; \
	printf '$(OK) Capacity: %s GiB memory, %s GiB free disk.\n' \
		"$$(( memory_bytes / 1024 / 1024 / 1024 ))" \
		"$$(( free_kib / 1024 / 1024 ))"

install-ollama: check-brew
	@if brew list --formula ollama >/dev/null 2>&1; then \
		printf '$(SKIP) Ollama is already installed: '; \
		brew list --versions ollama; \
	else \
		printf '$(INFO) Installing Ollama with Homebrew...\n'; \
		brew install ollama; \
	fi

install-jq: check-brew
	@if command -v jq >/dev/null 2>&1; then \
		printf '$(SKIP) jq is already installed.\n'; \
	else \
		brew install jq; \
	fi

prepare-copilot-home: check-macos
	@mkdir -p "$(COPILOT_LOCAL_HOME)"
	@chmod 700 "$(COPILOT_LOCAL_HOME)"
	@printf '$(OK) Isolated Copilot home: %s $(DIM)(mode 0700)$(RESET)\n' \
		"$(COPILOT_LOCAL_HOME)"

install-copilot: check-brew prepare-copilot-home
	@if command -v copilot >/dev/null 2>&1; then \
		printf '$(SKIP) GitHub Copilot CLI is already installed: '; \
		$(COPILOT_LOCAL) --version | head -1; \
	else \
		printf '$(INFO) Installing GitHub Copilot CLI with Homebrew...\n'; \
		brew install --cask copilot-cli; \
	fi

start-ollama: install-ollama
	@if $(CURL) --max-time 2 -fsS "$(OLLAMA_URL)/api/version" >/dev/null 2>&1; then \
		printf '$(SKIP) Ollama is already running at %s.\n' "$(OLLAMA_URL)"; \
	else \
		printf '$(INFO) Starting the Ollama Homebrew service...\n'; \
		brew services start ollama; \
	fi
	@SECONDS=0; \
	until $(CURL) --max-time 2 -fsS "$(OLLAMA_URL)/api/version" >/dev/null 2>&1; do \
		if [ "$$SECONDS" -ge "$(START_TIMEOUT)" ]; then \
			printf '$(FAIL) Ollama did not become healthy within %s seconds.\n' \
				"$(START_TIMEOUT)" >&2; \
			exit 1; \
		fi; \
		sleep 1; \
	done
	@printf '$(OK) Ollama API is healthy at %s.\n' "$(OLLAMA_URL)"

pull-model: check-capacity start-ollama
	@if $(OLLAMA) show "$(MODEL)" >/dev/null 2>&1; then \
		printf '$(SKIP) Model %s is already downloaded.\n' "$(MODEL)"; \
	else \
		printf '$(INFO) Downloading model %s...\n' "$(MODEL)"; \
		$(OLLAMA) pull "$(MODEL)"; \
	fi

configure-model: install-jq pull-model
	@model_file="$$(mktemp "$${TMPDIR:-/tmp}/local-coding-model.XXXXXX")"; \
	trap 'rm -f -- "$$model_file"' EXIT; \
	printf 'FROM %s\nPARAMETER num_ctx %s\n' "$(MODEL)" "$(CONTEXT_TOKENS)" > "$$model_file"; \
	$(OLLAMA) create "$(LOCAL_MODEL)" -f "$$model_file"; \
	printf '$(OK) Model %s configured with %s context tokens.\n' "$(LOCAL_MODEL)" "$(CONTEXT_TOKENS)"

start: check-macos install-copilot configure-model
	@$(MAKE) --no-print-directory -f "$(MAKEFILE_PATH)" check-state
	@printf '\n$(INFO) $(BOLD)Starting Copilot CLI$(RESET) with %s\n' "$(LOCAL_MODEL)"
	@printf '$(DIM)Exit Copilot from its UI, then run "make stop" to stop Ollama.$(RESET)\n\n'
	@$(COPILOT_LOCAL) $(COPILOT_ARGS)

stop: check-brew
	@if ! brew list --formula ollama >/dev/null 2>&1; then \
		printf '$(SKIP) Ollama is not installed; nothing to stop.\n'; \
	else \
		printf '$(INFO) Stopping the Ollama Homebrew service...\n'; \
		brew services stop ollama; \
		if $(CURL) --max-time 2 -fsS "$(OLLAMA_URL)/api/version" >/dev/null 2>&1; then \
			printf '$(FAIL) The API is still reachable; check for another Ollama process.\n' >&2; exit 1; \
		fi; \
	fi

status: check-brew
	@printf '\n$(BOLD)Homebrew service$(RESET)\n'
	@brew services list | grep -E '^(Name|ollama)[[:space:]]' || true
	@printf '\n$(BOLD)API$(RESET)\n'
	@if $(CURL) --max-time 2 -fsS "$(OLLAMA_URL)/api/version" 2>/dev/null; then \
		printf '\n'; \
	else \
		printf '$(WARN) Not reachable at %s\n' "$(OLLAMA_URL)"; \
	fi
	@if command -v ollama >/dev/null 2>&1; then \
		printf '\n$(BOLD)Downloaded models$(RESET)\n'; \
		$(OLLAMA) list 2>/dev/null || printf '$(WARN) Ollama is not running.\n'; \
		printf '\n$(BOLD)Loaded models$(RESET)\n'; \
		$(OLLAMA) ps 2>/dev/null || printf '$(WARN) Ollama is not running.\n'; \
	fi

check-state: check-macos check-brew check-config
	@failed=0; \
	if [ ! -d "$(COPILOT_LOCAL_HOME)" ]; then \
		printf '$(FAIL) Isolated Copilot home is missing: %s\n' \
			"$(COPILOT_LOCAL_HOME)" >&2; \
		failed=1; \
	elif [ "$$(stat -f '%Lp' "$(COPILOT_LOCAL_HOME)")" != "700" ]; then \
		printf '$(FAIL) Isolated Copilot home must have mode 0700: %s\n' \
			"$(COPILOT_LOCAL_HOME)" >&2; \
		failed=1; \
	fi; \
	if [ ! -d "$(OLLAMA_MODELS_DIR)" ]; then \
		printf '$(FAIL) Ollama model directory is missing: %s\n' \
			"$(OLLAMA_MODELS_DIR)" >&2; \
		failed=1; \
	fi; \
	if [ ! -e "$(OLLAMA_LAUNCH_AGENT)" ]; then \
		printf '$(FAIL) Ollama Homebrew launch agent is missing: %s\n' \
			"$(OLLAMA_LAUNCH_AGENT)" >&2; \
		failed=1; \
	fi; \
	if ! command -v copilot >/dev/null 2>&1; then \
		printf '$(FAIL) GitHub Copilot CLI is not installed or not on PATH.\n' >&2; \
		failed=1; \
	fi; \
	if ! command -v ollama >/dev/null 2>&1; then \
		printf '$(FAIL) Ollama is not installed or not on PATH.\n' >&2; \
		failed=1; \
	fi; \
	if ! command -v jq >/dev/null 2>&1; then \
		printf '$(FAIL) jq is not installed or not on PATH.\n' >&2; failed=1; \
	fi; \
	if ! $(CURL) --max-time 2 -fsS "$(OLLAMA_URL)/api/version" >/dev/null 2>&1; then \
		printf '$(FAIL) Ollama API is not reachable at %s.\n' "$(OLLAMA_URL)" >&2; \
		failed=1; \
	fi; \
	if command -v ollama >/dev/null 2>&1 && \
		! $(OLLAMA) show "$(MODEL)" >/dev/null 2>&1; then \
		printf '$(FAIL) Required model is unavailable: %s\n' "$(MODEL)" >&2; \
		failed=1; \
	fi; \
	if ! $(OLLAMA) show "$(LOCAL_MODEL)" --parameters 2>/dev/null | \
		awk '$$1 == "num_ctx" { print $$2 }' | grep -qx '$(CONTEXT_TOKENS)'; then \
		printf '$(FAIL) Configured model or context is missing: %s\n' "$(LOCAL_MODEL)" >&2; failed=1; \
	fi; \
	if [ "$$failed" -ne 0 ]; then \
		printf '$(INFO) Run "make setup" to create or repair the expected state.\n' >&2; \
		printf '$(INFO) %s\n' \
			'For intentional custom paths, override COPILOT_LOCAL_HOME,' \
			'OLLAMA_MODELS_DIR, or OLLAMA_LAUNCH_AGENT consistently.' >&2; \
		exit 1; \
	fi; \
	printf '$(OK) External state is ready.\n'

verify: verify-copilot verify-ollama
	@$(MAKE) --no-print-directory -f "$(MAKEFILE_PATH)" check-state
	@printf '\n$(OK) $(BOLD)All local-model checks passed.$(RESET)\n'

verify-ollama: configure-model
	@printf '$(INFO) Testing Ollama inference...\n'
	@response="$$($(CURL) --max-time "$(VERIFY_TIMEOUT)" -fsS "$(OLLAMA_URL)/v1/chat/completions" \
		-H 'Content-Type: application/json' \
		-d '{"model":"$(LOCAL_MODEL)","messages":[{"role":"user","content":"Reply with exactly: MAKEFILE_OLLAMA_OK"}],"stream":false,"temperature":0,"max_tokens":$(OUTPUT_TOKENS),"reasoning_effort":"none"}')"; \
	if ! printf '%s\n' "$$response" | jq -e '.choices[0].message.content == "MAKEFILE_OLLAMA_OK"' >/dev/null; then \
		printf '$(FAIL) Ollama did not return the expected assistant content.\n%s\n' "$$response" >&2; exit 1; \
	fi; \
	printf '$(OK) Ollama returned the expected response.\n'

verify-copilot: install-copilot configure-model
	@printf '$(INFO) Testing Copilot CLI tool execution...\n'
	@tmp_dir="$$(mktemp -d "$${TMPDIR:-/tmp}/local-llm-coding.XXXXXX")"; \
	tmp_dir="$$(cd "$$tmp_dir" && pwd -P)"; \
	trap 'rm -rf -- "$$tmp_dir"' EXIT INT TERM; \
	if ! response="$$(cd "$$tmp_dir" && $(COPILOT_LOCAL) \
		--deny-tool=shell \
		--allow-tool="write($$tmp_dir/probe.txt)" \
		--disallow-temp-dir --no-custom-instructions --no-ask-user \
		--output-format=json \
		-p "Use the create tool to create $$tmp_dir/probe.txt with file_text exactly MAKEFILE_COPILOT_TOOL_OK (no newline). Use that exact absolute path. Then reply with exactly: MAKEFILE_COPILOT_OK")"; then \
		printf '$(FAIL) Copilot CLI inference failed.\n' >&2; \
		exit 1; \
	fi; \
	if [ ! -f "$$tmp_dir/probe.txt" ]; then \
		printf '$(FAIL) Copilot did not execute its file tool.\n' >&2; \
		printf '$(DIM)%s$(RESET)\n' "$$response" >&2; \
		exit 1; \
	fi; \
	if ! printf 'MAKEFILE_COPILOT_TOOL_OK' | cmp -s - "$$tmp_dir/probe.txt"; then \
		printf '$(FAIL) Copilot created probe.txt with unexpected content.\n' >&2; \
		exit 1; \
	fi; \
	final_response="$$(printf '%s\n' "$$response" | jq -sr \
		'[.[] | select(.type == "assistant.message") | .data.content | select(type == "string" and length > 0)] | last // empty')"; \
	if [ "$$final_response" != "MAKEFILE_COPILOT_OK" ]; then \
		printf '$(FAIL) Copilot did not return the expected final response.\n' >&2; \
		printf '$(DIM)%s$(RESET)\n' "$$response" >&2; \
		exit 1; \
	fi; \
	printf '$(OK) Copilot executed a file tool and returned the expected response.\n'

docs:
	uv run --locked zensical build --strict --clean

docs-serve:
	uv run --locked zensical serve --open
