<h1 align="center">🖥️ LocalStack Daily Startup Workflow</h1>
<h3 align="center">Windows + Docker + PowerShell — Repeatable Local AWS Environment Setup</h3>

---

## 🏗️ Architecture You Are Running

Docker Desktop
↓
LocalStack Container
↓
AWS Service Emulation
↓
AWS CLI → localhost:4566

### 🧰 Tools in Use

| Tool               | Purpose                                     |
| ------------------ | ------------------------------------------- |
| **Docker Desktop** | Container runtime                           |
| **LocalStack**     | AWS service emulation inside Docker         |
| **AWS CLI**        | Command-line interface for AWS operations   |
| **PowerShell**     | Primary DevOps terminal                     |
| **Git Bash**       | Optional — navigation & general shell usage |

---

## ⚠️ Important Terminal Strategy

### Use Git Bash For:

- Linux-like shell usage
- Git operations
- Bash scripts
- General development

### Use PowerShell For:

- Python virtual environments
- AWS CLI
- LocalStack infrastructure commands
- Terraform
- kubectl
- Docker-heavy workflows

> ⚠️ **Compatibility Warning:** Git Bash + AWS CLI v2 on Windows can produce compatibility problems because AWS CLI is a compiled Windows executable.

> ✅ **Stable Production-Like Workflow:**
>
> - Git Bash → optional
> - PowerShell → **primary DevOps terminal**

---

## 📋 Daily Startup Workflow

Follow this **exact order** after every laptop restart.

---

### ## Step 1 — Start Docker Desktop 🐳

Open **Docker Desktop** and wait until the engine status shows:

Engine running

> ⚠️ Do **NOT** continue before the Docker engine is fully active.

---

### ## Step 2 — Open PowerShell 💻

Use either:

- **Windows Terminal + PowerShell**
- **Standard PowerShell**

---

### ## Step 3 — Move To Project 📁

```powershell
cd D:\Study_after_format\AgroCdAppDeploy-FORKED
```

---

### ## Step 4 — Activate Virtual Environment 🐍

```powershell
.\venv\Scripts\Activate.ps1
```

You should see your prompt change to:
(venv)

---

### ## Step 5 — Start LocalStack 🚀

```powershell
localstack start -d
```

**What this does:**

- Starts the Docker container
- Launches LocalStack services
- Exposes AWS APIs on port `4566`

---

### ## Step 6 — Verify LocalStack Is Running ✅

```powershell
docker ps
```

You should see a LocalStack container in the output.

Also verify the health endpoint:

```powershell
curl http://localhost:4566/health
```

📤 **Expected Output:**

```json
{"services": ...}
```

---

## 💡 Quality-of-Life Improvement — Endpoint Variable

Typing `--endpoint-url=http://localhost:4566` on every command gets tedious fast.

### ## Step 7 — Create LocalStack Endpoint Variable 🔧

Inside PowerShell, set an environment variable:

```powershell
$env:AWS_ENDPOINT_URL="http://localhost:4566"
```

Now commands become cleaner:

```powershell
aws --endpoint-url=$env:AWS_ENDPOINT_URL s3 ls
```

---

### ### 🚀 Even Better — Create a PowerShell Alias

Add the following function to your PowerShell session:

```powershell
function awsls {
    aws --endpoint-url=http://localhost:4566 @args
}
```

Now you can simply run:

```powershell
awsls s3 ls
```

```powershell
awsls ec2 create-vpc --cidr-block 10.0.0.0/16
```

> 💡 This effectively replaces the broken `awslocal` command on Windows.

---

### ### 📌 Make the Alias Permanent

Open your PowerShell profile in Notepad:

```powershell
notepad $PROFILE
```

> 💡 If prompted to create the file, choose **YES**.

Add the following block to the file:

```powershell
function awsls {
    aws --endpoint-url=http://localhost:4566 @args
}
```

Save the file and **restart PowerShell**.

> ✅ `awsls` will now work permanently across all sessions.

---

## 💻 Daily Commands You Will Use

### List S3 Buckets

```powershell
awsls s3 ls
```

### Create a VPC

```powershell
awsls ec2 create-vpc --cidr-block 10.0.0.0/16
```

### List VPCs

```powershell
awsls ec2 describe-vpcs
```

### Create a Subnet

```powershell
awsls ec2 create-subnet `
  --vpc-id vpc-xxxx `
  --cidr-block 10.0.1.0/24
```

---

## ⚠️ Important — Persistence Understanding

By default, **LocalStack data may disappear** after a container is recreated.

If you want your infrastructure to survive restarts, you need to enable **volume persistence**.

---

### ## Step 8 — Persistent LocalStack State 💾

Instead of the plain start command:

```powershell
localstack start -d
```

Use the volume-backed version:

```powershell
localstack start -d --volume-dir ./localstack-data
```

This stores all state on disk. The following will now **survive container restarts**:

- S3 Buckets
- VPCs
- Resources
- Infrastructure state

---

## 📋 Your Final Daily Workflow

### Every Day — Follow These Steps:

Start Docker Desktop
Open PowerShell
cd into project
Activate venv
Start LocalStack (with volume)
Use awsls commands

### 📋 Example Full Session

```powershell
cd D:\Study_after_format\AgroCdAppDeploy-FORKED
.\venv\Scripts\Activate.ps1
localstack start -d --volume-dir ./localstack-data
awsls s3 ls
awsls ec2 describe-vpcs
```

---

### 🚀 Quick Reference Cheat Sheet

| Step                   | Command                                                              | Purpose                                |
| ---------------------- | -------------------------------------------------------------------- | -------------------------------------- |
| Move to project        | `cd D:\Study_after_format\AgroCdAppDeploy-FORKED`                    | Navigate to working directory          |
| Activate venv          | `.\venv\Scripts\Activate.ps1`                                        | Enable Python virtual environment      |
| Start LocalStack       | `localstack start -d`                                                | Launch LocalStack in background        |
| Start with persistence | `localstack start -d --volume-dir ./localstack-data`                 | Launch with disk-backed state          |
| Check containers       | `docker ps`                                                          | Verify LocalStack container is running |
| Health check           | `curl http://localhost:4566/health`                                  | Confirm AWS APIs are live              |
| Set endpoint var       | `$env:AWS_ENDPOINT_URL="http://localhost:4566"`                      | Avoid repeating endpoint URL           |
| List S3 buckets        | `awsls s3 ls`                                                        | View all local S3 buckets              |
| Create VPC             | `awsls ec2 create-vpc --cidr-block 10.0.0.0/16`                      | Provision a new local VPC              |
| List VPCs              | `awsls ec2 describe-vpcs`                                            | View all local VPCs                    |
| Create Subnet          | `awsls ec2 create-subnet --vpc-id vpc-xxxx --cidr-block 10.0.1.0/24` | Add subnet to a VPC                    |

---

<div align="center">*Consistency in your startup sequence means zero confusion, zero lost infrastructure, and a workflow that mirrors real AWS environments. 📌*</div>
