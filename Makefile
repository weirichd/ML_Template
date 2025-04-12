PACKAGE_NAME_CHECK := {{package_name}}

TF_IMAGE_GPU = tensorflow/tensorflow:$(TF_VERSION)-gpu
TF_IMAGE_CPU = tensorflow/tensorflow:$(TF_VERSION)

TF_IMAGE_GPU_NOTEBOOK = tensorflow/tensorflow:$(TF_VERSION)-gpu-jupyter
TF_IMAGE_CPU_NOTEBOOK = tensorflow/tensorflow:$(TF_VERSION)-jupyter

TF_IMAGE_GPU_API = tensorflow/tensorflow:$(TF_VERSION)-gpu
TF_IMAGE_CPU_API = tensorflow/tensorflow:$(TF_VERSION)

.DEFAULT_GOAL := help

help:  ## Show available make commands
	@grep -E '^[a-zA-Z_-]+:.*?## ' Makefile | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

init: check-renamed check-python-version ## Initial project setup
	poetry install
	pre-commit install
	make export-requirements

check-renamed:
	@if grep -rq '{{package_name}}' . \
		--exclude-dir=.git --exclude=rename.sh  \
		--exclude=Makefile --exclude=tags; then \
		echo "ERROR: Looks like you haven't run ./rename.sh yet."; \
		echo "Please run:"; \
		echo "    ./rename.sh yourpackagename"; \
		exit 1; \
	fi

check-python-version:
	@PY_VERSION=$$(poetry env info --path 2>/dev/null || echo "none"); \
	if [ "$$PY_VERSION" = "none" ]; then \
		echo "WARNING: No poetry environment found."; \
		echo "Attempting to use Python 3.11..."; \
		poetry env use 3.11 || echo "ERROR: Python 3.11 not found. Please install with pyenv."; \
	else \
		POETRY_PY=$$(poetry run python --version | awk '{print $$2}'); \
		echo "Poetry is using Python $$POETRY_PY"; \
		if ! echo $$POETRY_PY | grep -q '^3\.11'; then \
			echo "ERROR: Poetry is using Python $$POETRY_PY but this project requires Python 3.11.x"; \
			echo "To fix: pyenv install 3.11.x && poetry env use 3.11"; \
			exit 1; \
		fi \
	fi

export-requirements: ## Export requirements.txt from poetry
	poetry export --without-hashes --format=requirements.txt -o requirements.txt

upgrade: ## Upgrade dependencies to latest versions
	poetry self add poetry-plugin-up || true
	poetry up --latest
	make export-requirements

lint: ## Run pre-commit checks
	pre-commit run --all-files

test: ## Run tests
	poetry run pytest -v

ci: lint test ## Run pre-commit and tests (local CI)

notebook: ## Run local Jupyter Notebook
	poetry run notebook

shell: ## Run IPython shell
	poetry run ipython

# CLI ------------------------------------------------------------

build-cli: export-requirements
	docker build --build-arg TF_IMAGE=$(TF_IMAGE_GPU) -f Dockerfile.tensorflow-cli -t $(IMAGE_BASE_NAME)-cli:${TF_VERSION} .

build-cli-cpu: export-requirements
	docker build --build-arg TF_IMAGE=$(TF_IMAGE_CPU) -f Dockerfile.tensorflow-cli -t $(IMAGE_BASE_NAME)-cli:${TF_VERSION}-cpu .

run-cli: check-gpu
	@if [ -f .no-gpu ]; then \
		echo "Running CLI in CPU mode..."; \
		docker run -it --rm -v $(shell pwd):/workspace $(IMAGE_BASE_NAME)-cli:${TF_VERSION}-cpu; \
	else \
		echo "Running CLI in GPU mode..."; \
		docker run --gpus all -it --rm -v $(shell pwd):/workspace $(IMAGE_BASE_NAME)-cli:${TF_VERSION}; \
	fi

# NOTEBOOK --------------------------------------------------------

build-notebook: export-requirements
	docker build --build-arg TF_IMAGE=$(TF_IMAGE_GPU_NOTEBOOK) -f Dockerfile.tensorflow-notebook -t $(IMAGE_BASE_NAME)-notebook:${TF_VERSION} .

build-notebook-cpu: export-requirements
	docker build --build-arg TF_IMAGE=$(TF_IMAGE_CPU_NOTEBOOK) -f Dockerfile.tensorflow-notebook -t $(IMAGE_BASE_NAME)-notebook:${TF_VERSION}-cpu .

run-notebook: check-gpu
	@if [ -f .no-gpu ]; then \
		echo "Running Notebook in CPU mode..."; \
		docker run -it --rm -p $(NOTEBOOK_PORT):8888 -v $(shell pwd):/workspace $(IMAGE_BASE_NAME)-notebook:${TF_VERSION}-cpu; \
	else \
		echo "Running Notebook in GPU mode..."; \
		docker run --gpus all -it --rm -p $(NOTEBOOK_PORT):8888 -v $(shell pwd):/workspace $(IMAGE_BASE_NAME)-notebook:${TF_VERSION}; \
	fi

# API ------------------------------------------------------------

build-api: export-requirements
	docker build --build-arg TF_IMAGE=$(TF_IMAGE_GPU_API) -f Dockerfile.tensorflow-api -t $(IMAGE_BASE_NAME)-api:${TF_VERSION} .

build-api-cpu: export-requirements
	docker build --build-arg TF_IMAGE=$(TF_IMAGE_CPU_API) -f Dockerfile.tensorflow-api -t $(IMAGE_BASE_NAME)-api:${TF_VERSION}-cpu .

run-api: check-gpu
	@if [ -f .no-gpu ]; then \
		echo "Running API in CPU mode..."; \
		docker run -it --rm -p $(API_PORT):8000 -v $(shell pwd):/workspace $(IMAGE_BASE_NAME)-api:${TF_VERSION}-cpu; \
	else \
		echo "Running API in GPU mode..."; \
		docker run --gpus all -it --rm -p $(API_PORT):8000 -v $(shell pwd):/workspace $(IMAGE_BASE_NAME)-api:${TF_VERSION}; \
	fi

# MLFLOW ----------------------------------------------------------

mlflow-up: ## Start MLflow UI via docker compose
	docker compose up mlflow

# GPU DETECTION ---------------------------------------------------

check-gpu:
	@if docker run --gpus all --rm $(IMAGE_BASE_NAME)-cli:${TF_VERSION} python3 -c "import tensorflow as tf; assert tf.config.list_physical_devices('GPU')" 2>/dev/null; then \
		echo "GPUs are available."; \
		rm -f .no-gpu; \
	else \
		echo "WARNING: No GPUs detected inside container."; \
		echo "Defaulting to CPU mode."; \
		touch .no-gpu; \
	fi

clean: ## Remove local docker containers/images
	docker rm -f $(shell docker ps -aq --filter ancestor=$(IMAGE_BASE_NAME)-cli:${TF_VERSION}) || true
	docker rm -f $(shell docker ps -aq --filter ancestor=$(IMAGE_NAME)-cli:${TF_VERSION}-cpu) || true
	docker rmi -f $(IMAGE_BASE_NAME)-cli:${TF_VERSION} || true
	docker rmi -f $(IMAGE_BASE_NAME)-cli:${TF_VERSION}-cpu || true
	docker rmi -f $(IMAGE_BASE_NAME)-notebook:${TF_VERSION} || true
	docker rmi -f $(IMAGE_BASE_NAME)-notebook:${TF_VERSION}-cpu || true
	docker rmi -f $(IMAGE_BASE_NAME)-api:${TF_VERSION} || true
	docker rmi -f $(IMAGE_BASE_NAME)-api:${TF_VERSION}-cpu || true

