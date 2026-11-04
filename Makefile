PYTHON ?= python3
NVIM ?= nvim

.PHONY: test smoke format format-check
test:
	$(PYTHON) -m unittest discover -s packages/agent-core/tests -v
	$(PYTHON) -m unittest discover -s tests/installer -v
	$(PYTHON) -m unittest discover -s tests/session -v
smoke:
	$(PYTHON) scripts/verify/smoke.py --nvim $(NVIM)
	$(PYTHON) scripts/verify/panels.py --nvim $(NVIM)
	$(PYTHON) scripts/verify/keymaps.py --nvim $(NVIM)
	$(PYTHON) scripts/verify/workspace-startup.py --nvim $(NVIM)
	$(PYTHON) scripts/verify/terminal-input.py --nvim $(NVIM)
	$(PYTHON) scripts/verify/replace-input.py --nvim $(NVIM)
format:
	stylua apps/nvim tests scripts/installer/plugins.lua scripts/setup/language-tools.lua
format-check:
	stylua --check apps/nvim tests scripts/installer/plugins.lua scripts/setup/language-tools.lua
