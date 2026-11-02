PYTHON ?= python3
NVIM ?= nvim

.PHONY: test smoke format format-check
test:
	$(PYTHON) -m unittest discover -s packages/agent-core/tests -v
	$(PYTHON) -m unittest discover -s tests/installer -v
smoke:
	$(PYTHON) scripts/smoke.py --nvim $(NVIM)
	$(PYTHON) scripts/panels-smoke.py --nvim $(NVIM)
	$(PYTHON) scripts/keymaps-smoke.py --nvim $(NVIM)
	$(PYTHON) scripts/terminal-input-smoke.py --nvim $(NVIM)
format:
	stylua apps/nvim tests scripts/installer/plugins.lua
format-check:
	stylua --check apps/nvim tests scripts/installer/plugins.lua
