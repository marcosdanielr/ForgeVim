PYTHON ?= python3
NVIM ?= nvim

.PHONY: test smoke format format-check
test:
	$(PYTHON) -m unittest discover -s packages/agent-core/tests -v
smoke:
	$(PYTHON) scripts/smoke.py --nvim $(NVIM)
	$(PYTHON) scripts/panels-smoke.py --nvim $(NVIM)
format:
	stylua apps/nvim tests
format-check:
	stylua --check apps/nvim tests
