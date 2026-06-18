# Lab 07 - Release Workflow and Infrastructure as Code (Java)

**Duration:** ~90 min  
**SDLC Phase:** Integration → Deployment → Release  
**Autonomy Level:** 🟡 Human reviews, Copilot automates  
**Prerequisites:** Java 17+, Maven or Gradle, Git + a remote repository (GitHub or Azure DevOps Repos), VS Code with GitHub Copilot, [HVE Core](https://marketplace.visualstudio.com/items?itemName=ise-hve-essentials.hve-core) extension  
**Works with:** GitHub Issues · Azure DevOps Work Items · Jira (see Part 1 for tracker-specific steps)

---

Lab 07 is self-contained. It focuses on operationalizing release work by opening a PR with supply chain security awareness, scanning dependencies for vulnerabilities, building containerized configurations in YAML/Docker Compose, and expressing infrastructure as code with GitOps and observability patterns. Together, these exercises simulate a full SDLC path from implementation to production readiness using 2026 DevOps best practices.

## What You'll Practice

| Part | Skill | Time | Copilot Feature |
|------|-------|------|-----------------|
| **1** | Create a PR with supply chain context | 15 min | Chat PR workflow + SBOM awareness |
| **2** | Supply chain security (hands-on) | 12 min | SBOM generation + vulnerability scanning |
| **3** | YAML + container fundamentals | 25 min | Chat + Docker Compose + inline YAML |
| **4** | IaC + GitOps + observability | 30 min | MCP tools + code samples + monitoring |
| **5** | Merge, validate, cost review | 8 min | Chat verification + cost analysis |

---

## Setup

```bash
cd lab07

# Maven
mvn install

# Or Gradle
./gradlew build
```

---

## The Scenario

You've got a working release artifact set for Lab 07. Now it's time to:

1. **Create a PR** with supply chain security context
2. **Generate a bill-of-materials** and scan dependencies for vulnerabilities
3. **Build containerized configurations** with YAML and Docker Compose
4. **Define infrastructure as code** with GitOps and observability patterns (Bicep or Terraform)
5. **Validate and cost-estimate** everything locally

This mirrors a real 2026 DevOps pipeline where infrastructure, containers, and monitoring are defined as versioned code with security-first practices.

## Lab 07 Starter Artifacts

This lab is self-contained. Everything you need is created locally during the exercises.

### What you'll produce

1. `pom.xml` (Maven) or `build.gradle` (Gradle) for dependency scanning
2. `config.yml` for generic YAML practice
3. `docker-compose.yml` for local container orchestration
4. `main.bicep` or `main.tf` for local IaC authoring
5. Optional local evidence notes in `SECURITY_SCAN.md` and `COST_ESTIMATE.md`

### Copy/paste checkpoints for your PR description

Use this block in your PR body and replace placeholders:

```markdown
## Lab 07 handoff

- Feature implemented: Release workflow and infrastructure setup
- Test status: <paste local validation summary>
- Evidence artifact: <path to your local scan or validation notes>
- Tracker references: <optional issue or task IDs>

## Validation

- [ ] Release workflow reviewed
- [ ] SBOM generated
- [ ] Vulnerability scan completed
- [ ] Local validation notes captured

## Supply Chain Security

- [ ] SBOM (bill-of-materials) generated from dependencies
- [ ] Vulnerability scan completed: <summary of findings>
- [ ] No unresolved CVEs with severity ≥ HIGH
- [ ] Signed commits required for merge
```

### Suggested review prompts

Use these prompts with Copilot during PR review:

1. `Review this PR for completeness: does it include SBOM, vulnerability scan report, YAML/Docker Compose, and IaC files?`
2. `Check whether the SECURITY_SCAN.md findings are addressed before merging.`
3. `Suggest a concise merge checklist based on the changed files and validation results.`

---

## Part 1 — Create a Pull Request (15 min)

### Your tasks

1. **Create a feature branch:**
   ```bash
   git checkout -b lab07/pr-workflow
   git commit --allow-empty -m "lab07: Add CI/CD and IaC"
   ```

2. **Push your branch** (same for everyone):
   ```bash
   git push origin lab07/pr-workflow
   ```

3. **Open a PR — follow the path for your team's setup:**

   > **Group A — GitHub for code, Azure DevOps for PM**
   >
   > - Open a PR on GitHub (repository → Pull requests → New pull request)
   > - Or use Copilot Chat → `/createPullRequest` to generate the PR directly from VS Code
   > - Reference work items with `AB#<ID>` (e.g., `AB#42`) — GitHub links automatically to Azure DevOps

   > **Group B — Azure DevOps for code, Jira for PM**
   >
   > - Open a PR in Azure DevOps (Repos → Pull requests → New pull request)
   > - Copilot Chat's `/createPullRequest` command targets the active repository — works with Azure DevOps Repos when the repo remote is an ADO URL
   > - Reference Jira tickets in the PR description as `PROJ-<ID>` (e.g., `PROJ-42`)

4. **Use this PR description template** (replace placeholders for your tracker):
   ```markdown
   ## Description
   Lab 07 implementation: CI/CD pipeline and infrastructure setup

   ## Changes
   - YAML configuration and release workflow updates
   - Infrastructure-as-Code (Bicep/Terraform) provisioning
   - Dependency automation policy and review guidance

   ## Related Issues
   <!-- Group A (ADO work items): AB#42 -->
   <!-- Group B (Jira):           PROJ-42 -->
   <!-- GitHub Issues:            Closes #42 -->
   ```

5. **Request code review:**
   - Mention reviewers: `@<reviewer>`
   - Request feedback on: workflow logic, infrastructure code, security practices

---

## Part 2 — Supply Chain Security: SBOM & Vulnerability Scanning (12 min)

Modern DevOps requires supply chain security awareness. You'll generate a bill-of-materials (SBOM) and scan for vulnerabilities—practices that are mandatory in 2026.

### What is an SBOM?

A Software Bill of Materials (SBOM) is a machine-readable inventory of all dependencies in your software. It:

- Lists every dependency and its version
- Enables vulnerability tracking across your supply chain
- Supports compliance audits and security policies
- Integrates with automated scanning tools

### Your tasks

#### Task 1: Generate SBOM from dependencies (5 min)

If you don't yet have a build file in this directory, create a minimal one so you have real dependencies to scan:

- **Maven** — ask Copilot:
  ```
  Generate a minimal pom.xml for a Java 17 project that includes
  Spring Boot Web, Spring Data JPA, and Lombok as dependencies.
  ```

- **Gradle** — ask Copilot:
  ```
  Generate a minimal build.gradle for a Java 17 project that includes
  Spring Boot Web, Spring Data JPA, and Lombok as dependencies.
  ```

**Maven — generate SBOM with CycloneDX:**

1. Add the plugin to `pom.xml`:
   ```xml
   <build>
     <plugins>
       <plugin>
         <groupId>org.cyclonedx</groupId>
         <artifactId>cyclonedx-maven-plugin</artifactId>
         <version>2.8.0</version>
       </plugin>
     </plugins>
   </build>
   ```

2. Run:
   ```bash
   mvn org.cyclonedx:cyclonedx-maven-plugin:makeAggregateBom
   # Output: target/bom.xml
   cat target/bom.xml
   ```

**Gradle — generate SBOM with CycloneDX:**

1. Add the plugin to `build.gradle`:
   ```groovy
   plugins {
     id 'org.cyclonedx.bom' version '1.8.2'
   }
   ```

2. Run:
   ```bash
   ./gradlew cyclonedxBom
   # Output: build/reports/bom.xml
   cat build/reports/bom.xml
   ```

**Use Copilot to summarize the SBOM:**
```
Chat prompt: "Create a markdown summary of this CycloneDX SBOM showing:
- Total number of dependencies
- High-level dependency categories (web framework, database, testing, etc.)
- Any dependencies that appear outdated

Format as a table with columns: Package, Version, Category"
```

**Commit your SBOM:**
```bash
# Maven
git add target/bom.xml
git commit -m "lab07: Add CycloneDX SBOM"

# Gradle
git add build/reports/bom.xml
git commit -m "lab07: Add CycloneDX SBOM"
```

#### Task 2: Vulnerability scanning (7 min)

**Option A — OWASP Dependency Check (Maven):**
```bash
mvn org.owasp:dependency-check-maven:check
# Report: target/dependency-check-report.html
# Opens a browser-friendly HTML report with CVE details
```

**Option B — OWASP Dependency Check (Gradle):**
```bash
./gradlew dependencyCheckAnalyze
# Report: build/reports/dependency-check-report.html
```

**Option C — Copilot analysis** (if CLI tools are not installed):
```
Chat prompt: "Analyze this pom.xml (or build.gradle) for known CVEs and security issues.

[paste your dependency list]

For each potential issue, provide:
- Artifact name and group
- Current version
- Known CVE ID
- Severity (LOW, MEDIUM, HIGH, CRITICAL)
- Recommended action"
```

**Document findings:**
```bash
cat > SECURITY_SCAN.md << EOF
# Security Scan Report

Date: $(date)

## Summary
- Total dependencies scanned: <N>
- High/Critical vulnerabilities: <count>
- Medium vulnerabilities: <count>
- Low vulnerabilities: <count>

## Findings
(Add scan output or Copilot's analysis here)

## Remediation Plan
(Add action items from Copilot)
EOF
```

```bash
git add SECURITY_SCAN.md
git commit -m "lab07: Add security vulnerability scan report"
```

### Dependency Update Policy

Document this in your PR description:

```markdown
## Dependency & Supply Chain Policy

- **SBOM requirement**: All releases must include an updated SBOM
- **Vulnerability scanning**: Mandatory before PR merge
- **Severity thresholds**:
  - CRITICAL: Block merge immediately, remediate before release
  - HIGH: Address within 72 hours
  - MEDIUM: Address within 2 weeks
  - LOW: Track and batch with regular updates
- **Update cadence**: Dependencies reviewed and updated monthly
- **Approval**: Security team reviews scan reports before merge
```

### Key Insight

Supply chain security is not optional in 2026. SBOM + scanning are now standard practices in enterprise DevOps.

---

## Part 3 — YAML & Container Fundamentals (25 min)

YAML is the lingua franca of infrastructure and DevOps. By 2026, YAML is inseparable from containerization. This part teaches you YAML syntax and applies it to Docker Compose—a practical container orchestration tool.

### Subsection A: YAML Essentials (10 min)

#### Your tasks

1. **Create a generic YAML configuration file:**
   ```bash
   touch config.yml
   ```

2. **Use Copilot to create a well-structured YAML file:**
   - Chat prompt:
     ```
     Create a comprehensive YAML file that demonstrates:
     - Top-level keys and nested structures
     - Lists and arrays
     - Key-value pairs with various data types (strings, numbers, booleans)
     - Comments explaining each section
     - Proper indentation (2-space standard)

     Make it a generic configuration file (not specific to one tool).
     Include a description, metadata, configuration section, and rules.
     ```

3. **YAML essentials to understand:**

   | Concept | Example |
   |---------|---------|
   | **Key-Value Pairs** | `name: auth-service` |
   | **Nesting** | Indentation defines hierarchy |
   | **Lists** | `- item1` on separate lines with `-` |
   | **Strings** | `"text"` or `'text'` or unquoted |
   | **Numbers** | `42`, `3.14` (no quotes) |
   | **Booleans** | `true`, `false`, `yes`, `no` |
   | **Null** | `~` or `null` |
   | **Comments** | `# This is a comment` |

4. **Review and validate:**
   - Check **indentation consistency** (spaces, not tabs!)
   - Verify **no trailing spaces**
   - Ask Copilot: **"Validate this YAML for syntax errors"**
   - Ask: **"Explain best practices I should follow in YAML"**

5. **Commit your generic config:**
   ```bash
   git add config.yml
   git commit -m "lab07: Add YAML configuration file"
   git push origin lab07/pr-workflow
   ```

### Subsection B: Docker Compose — YAML in Action (15 min)

Docker Compose is production-grade containerization defined entirely in YAML. This teaches you YAML in a real deployment scenario.

#### Your tasks

1. **Create a Docker Compose file:**
   ```bash
   touch docker-compose.yml
   ```

2. **Use Copilot to build a multi-service composition:**
   - Chat prompt:
     ```
     Create a docker-compose.yml file that:
     - Defines a Java Spring Boot service (built from a Dockerfile)
     - Includes a PostgreSQL database service
     - Sets up environment variables for database connection (spring.datasource.url, etc.)
     - Configures volume mounts for data persistence
     - Defines a custom bridge network for service-to-service communication
     - Includes health checks for both services
     - Contains comments explaining each section

     Make it production-ready with proper error handling.
     ```

3. **Your docker-compose.yml will include:**
   ```yaml
   services:
     app:
       # Java Spring Boot service
       build: .
       environment:
         SPRING_DATASOURCE_URL: jdbc:postgresql://postgres:5432/appdb
     postgres:
       # Database service
     # networks, volumes, health checks defined below
   ```

   > **Note:** Omit `version:` — it is obsolete in Docker Compose v2 and later.

4. **Validate the Docker Compose file:**
   ```bash
   # Check syntax (requires Docker)
   docker compose config

   # Or validate with Copilot:
   # "Validate this docker-compose.yml for syntax and best practices"
   ```

5. **Understand why Docker Compose matters in 2026:**
   - **Local parity**: Developers test exactly what runs in production
   - **Container standards**: YAML + containers are the deployment baseline
   - **Orchestration foundation**: Docker Compose is the bridge to Kubernetes and production orchestration
   - **DevOps fluency**: Every engineer must read/write container configs

6. **Commit and push:**
   ```bash
   git add docker-compose.yml
   git commit -m "lab07: Add Docker Compose for containerized deployment"
   git push origin lab07/pr-workflow
   ```

### Key Insight

YAML + containers are inseparable in 2026. Mastering both is essential for modern deployment workflows.

---

## Part 4 — Infrastructure-as-Code + GitOps + Observability (30 min)

Modern infrastructure must be **versioned**, **auditable**, and **observable**. This section teaches IaC fundamentals while introducing GitOps patterns and monitoring—the three pillars of 2026 DevOps.

### Subsection A: Infrastructure-as-Code Fundamentals (20 min)

You have **two tracks**: Choose Bicep (Azure-native) or Terraform (multi-cloud).

#### Track A: Bicep (Azure-native)

**What is Bicep?**  
Bicep is an Azure-native DSL for Infrastructure-as-Code. It compiles to ARM templates.

##### Your tasks

1. **Create a Bicep file:**
   ```bash
   touch main.bicep
   ```

2. **Use Microsoft Learn MCP to build the Bicep template:**
   - Chat prompt:
     ```
     Use the Microsoft Learn MCP tool to find official Bicep examples for:
     - Creating an Azure Container Apps environment for a Java Spring Boot service
     - Configuring access controls and network security
     - Adding monitoring and logging with Application Insights

     Then generate a Bicep file with these resources.
     Include metadata comments explaining the deployment pattern.
     ```

3. **Copilot will use the MCP to fetch code samples** from Microsoft Learn documentation

4. **Review the generated Bicep:**
   - Ensure it follows Azure naming conventions
   - Verify security best practices (encryption, access control)
   - Check for monitoring configuration

5. **Validate locally (no Azure deployment):**
   ```bash
   # Just validate syntax; don't deploy
   # bicep CLI: install from https://aka.ms/install-bicep if not present
   bicep build main.bicep  # (or ask Copilot: "Validate this Bicep syntax")
   ```

#### Track B: Terraform (Multi-cloud)

**What is Terraform?**  
Terraform is a cloud-agnostic IaC tool supporting AWS, Azure, GCP, and more.

##### Your tasks

1. **Create Terraform files:**
   ```bash
   touch main.tf variables.tf outputs.tf
   ```

2. **Use Microsoft Learn MCP for Terraform + Azure:**
   - Chat prompt:
     ```
     Use the Microsoft Learn MCP to fetch official Terraform examples for:
     - Azure Resource Group with naming conventions
     - Azure Container Apps for deploying a Java Spring Boot container
     - Application Insights for observability

     Generate a Terraform configuration that demonstrates modern cloud deployment.
     Include comments explaining resource dependencies.
     ```

3. **Copilot will retrieve code samples** from Microsoft Learn

4. **Structure your Terraform:**
   ```hcl
   # main.tf
   terraform {
     required_providers {
       azurerm = {
         source  = "hashicorp/azurerm"
         version = "~> 3.0"
       }
     }
   }

   provider "azurerm" {
     features {}
   }

   # Resources from Microsoft Learn samples
   # (container apps, monitoring, networking)
   ```

5. **Validate locally (no deployment):**
   ```bash
   # terraform CLI: install from https://developer.hashicorp.com/terraform/install if not present
   terraform init -backend=false
   terraform validate
   # Don't run "terraform apply" — validation only
   ```

### Subsection B: GitOps Pattern (5 min)

GitOps means **Git is your single source of truth for infrastructure and deployment state**. Your IaC files in Git become the authoritative declaration of your infrastructure.

#### Your task

1. **Add GitOps declaration to your IaC file:**
   - For Bicep, add a comment block:
     ```bicep
     /*
     GitOps Deployment:
     This file is the source of truth for infrastructure state.

     Deployment method (choose one for production):
     1. Azure DevOps Pipelines: Triggered on commit to main
     2. GitHub Actions: Automated deployment on merge
     3. ArgoCD (Kubernetes): Continuous sync from Git
     4. Flux (Kubernetes): GitOps reconciliation loop

     All infrastructure changes must go through Git PR → Review → Merge → Deploy
     Never apply infrastructure changes directly (no manual "az" or "terraform apply" in production)
     */
     ```

   - For Terraform, add to `main.tf`:
     ```hcl
     # GitOps Declaration
     # This file is version-controlled and represents the desired infrastructure state.
     # Deployment flows: Git commit -> CI/CD pipeline -> terraform apply
     # All changes tracked in Git history for auditability.
     ```

2. **Understand why GitOps matters:**
   - Every infrastructure change is auditable (in Git history)
   - Rollback is as simple as reverting a commit
   - Multiple environments can be managed as code branches
   - Drift detection: Compare Git state vs. actual infrastructure

### Subsection C: Observability & Monitoring (5 min)

Deployed infrastructure without observability is operationally blind. By 2026, monitoring is non-negotiable.

#### Your task

1. **Add monitoring to your IaC:**
   - For Bicep, ask Copilot:
     ```
     Add an Azure Application Insights resource to this Bicep file for monitoring.
     Configure it to track:
     - JVM metrics and garbage collection
     - HTTP request latency and error rates
     - Custom business events
     ```

   - For Terraform, ask Copilot:
     ```
     Add an azurerm_application_insights resource to this Terraform configuration.
     Include outputs that show the instrumentation key and workspace ID.
     ```

2. **Configure basic logging:**
   ```bash
   # Document where logs will be sent
   # In your IaC, add:
   # - Log destination (Azure Monitor, CloudWatch, DataDog, etc.)
   # - Log retention policy
   # - Alert thresholds for critical events
   ```

3. **Commit your observability setup:**
   ```bash
   git add main.bicep  # or main.tf/variables.tf/outputs.tf
   git commit -m "lab07: Add IaC with GitOps and observability patterns"
   git push origin lab07/pr-workflow
   ```

### Key Insight

**Infrastructure-as-Code** ensures your infrastructure is versioned and reproducible.  
**GitOps** ensures all changes flow through Git and CI/CD, never manual.  
**Observability** ensures you know what's happening in production.

Together, they form the foundation of **reliable, auditable, 2026-grade DevOps**.

---

## Part 5 — Merge, Validate & Cost Review (8 min)

### Your tasks

#### Task 1: Validate YAML & containers (3 min)

1. **Validate your YAML files:**
   ```bash
   # Validate generic config.yml (python3 available in most devcontainers)
   python3 -c "import yaml; yaml.safe_load(open('config.yml')); print('✓ config.yml is valid')"

   # Or ask Copilot to validate docker-compose.yml:
   # "Validate this docker-compose.yml for syntax and best practices"
   ```

2. **Check for common issues:**
   - Indentation is 2 spaces (not tabs)
   - No trailing spaces
   - All required fields are present

#### Task 2: Validate infrastructure code (2 min)

1. **Validate Bicep or Terraform (no deployment):**
   ```bash
   # For Bicep
   bicep build main.bicep  # (or use Copilot validation)

   # For Terraform
   terraform init -backend=false
   terraform validate
   ```

2. **Security review with Copilot:**
   ```
   Chat prompt: "Review this [Bicep/Terraform] code for security best practices:
   - Encryption at rest and in transit
   - Network isolation and access controls
   - Secrets management (no hardcoded credentials)
   - Monitoring and logging

   Flag any issues and suggest fixes."
   ```

#### Task 3: Cost estimation (3 min)

**This is NEW in 2026 DevOps best practices.**

1. **Estimate deployment cost with Copilot:**
   ```
   Chat prompt: "Based on this Bicep/Terraform configuration, estimate monthly cost:

   [paste your IaC]

   Assume:
   - Standard Azure regions (East US)
   - 24/7 uptime
   - Typical storage: 100 GB/month
   - Typical data transfer: 1 TB/month egress
   - Java app: 2 vCPU, 4 GB RAM

   Provide:
   - Per-resource cost breakdown
   - Total estimated monthly cost
   - Cost optimization recommendations"
   ```

2. **Document cost assumptions in your PR:**
   ```markdown
   ## Cost Estimate

   - Container Apps environment: $X/month
   - Application Insights: $Y/month
   - Data Transfer: $Z/month
   - **Total estimated: $TOTAL/month**

   Assumptions: [list from Copilot analysis]
   Optimization opportunities: [list from Copilot]
   ```

3. **Commit your cost review:**
   ```bash
   git add COST_ESTIMATE.md  # (or include in PR description)
   git commit -m "lab07: Add infrastructure cost analysis"
   git push origin lab07/pr-workflow
   ```

#### Task 4: Merge when ready (optional)

When your PR passes all validations:

```bash
# After reviewing and validating everything locally
# (Don't actually deploy to Azure — just validate locally)

# Merge to main
git checkout main
git pull origin main
git merge lab07/pr-workflow
git push origin main

# Clean up feature branch
git branch -d lab07/pr-workflow
git push origin --delete lab07/pr-workflow
```

### Key Insight

By 2026, validation includes not just syntax and security, but also **cost awareness**. Engineers who understand infrastructure economics are more valuable to their teams.

---

## Summary

In this lab, you've learned **2026 DevOps best practices** with a Java toolchain:

✅ **Supply Chain Security** — CycloneDX SBOM from Maven/Gradle + OWASP Dependency Check  
✅ **Container Fundamentals** — Docker Compose + YAML for reproducible Java deployments  
✅ **GitOps Patterns** — Git as source of truth for infrastructure  
✅ **Observability** — Monitoring and logging as first-class infrastructure concerns  
✅ **Cost Awareness** — Understanding infrastructure economics and optimization  
✅ **Infrastructure-as-Code** — Bicep or Terraform for auditable, versionable infrastructure  
✅ **Code Review Culture** — Leverage Copilot to accelerate (not replace) human review  

These skills form the foundation of **modern DevOps + GitOps + Security** practices expected in 2026 and beyond.
