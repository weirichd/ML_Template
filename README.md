# {{package_name}}

Machine Learning / Deep Learning Project Template  
Supports local development, Dockerized training & serving, MLflow tracking, GPU/CPU flexibility.

---

## Getting Started

### 1. Clone the template

```bash
git clone https://github.com/yourusername/your-repo.git
cd your-repo
```

---

### 2. Rename the project

```bash
chmod +x rename.sh
./rename.sh yourpackagename
```

---

### 3. Initialize the project locally

```bash
make init
```

---

## Building & Running

|Command|Purpose|
|-------|-------|
|make build-cli|Build GPU training image|
|make build-cli-cpu|Build CPU-only training image|
|make run-cli|Run training (auto GPU or CPU)|
|make build-api|Build API server image|
|make run-api|Run API server (auto GPU or CPU)|
|make build-notebook|Build Jupyter image|
|make run-notebook|Run Jupyter (auto GPU or CPU)|
|make test|Run tests|
|make lint|Run pre-commit checks|
|make upgrade|Upgrade deps to latest|
|make mlflow-up|Start MLflow UI|

---

## MLflow Tracking

After `make mlflow-up` → UI available at:

```
http://localhost:5000
```

---

## Notes on Docker GPU/CPU Handling

- `make check-gpu` runs automatically
- If no GPU detected → `.no-gpu` file is created
- All `run-*` targets check for `.no-gpu` and fallback to CPU image automatically

---

## Requirements Management

- Poetry is the source of truth
- Export `requirements.txt` via:

```bash
make export-requirements
```

---

## Keeping Dependencies Fresh

Check for outdated packages:

```bash
make upgrade
```

---

## Files Specific To The Template Repo Only

|File|Purpose|
|----|-------|
|.github/workflows/upgrade.yml|Auto-upgrade dependencies for the template repo only|
|.github/TEMPLATE_ONLY.md|Explains what is template-specific|

Safe to delete in cloned projects.

---

## Project Structure

```
.
├── src/yourpackagename/   # Python code
├── tests/                 # Tests
├── notebooks/             # Exploration notebooks
├── models/                # Saved models
├── data/                  # Local data (not versioned)
├── apt-packages.txt       # System deps
├── .env                   # Environment config
├── Dockerfile.*           # Docker build files
├── docker-compose.yml     # MLflow service
├── Makefile               # Command center
└── README.md              # This file
```

---

## Future Enhancements

- AWS / Remote Training Ready
- Optional Docker Compose for all services
- Optional MLflow Model Registry
- Optional TensorBoard Service
- Optional Distributed Training Support

