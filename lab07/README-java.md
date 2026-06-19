# Lab 07 - Copilot for Deployment (Java)

**Duration:** ~90 min  
**SDLC Phase:** Integration → Deployment → Release  
**Autonomy Level:** 🟡 Human reviews, Copilot automates  
**Prerequisites:** Java 17+, Maven or Gradle, Git + a remote repository (GitHub or Azure DevOps Repos), VS Code with GitHub Copilot, [HVE Core](https://marketplace.visualstudio.com/items?itemName=ise-hve-essentials.hve-core) extension  
**Works with:** GitHub Issues · Azure DevOps Work Items · Jira (see Part 1 for tracker-specific steps)

---

Lab 07 is self-contained. **Copilot is your pair programmer throughout**: it generates the Bicep or Terraform that provisions your infrastructure, scaffolds the CI/CD pipeline YAML that enforces SBOM and CVE gates, and helps reason about cost before any resource is created. The lab covers the full path from a local commit to a pipeline-gated, infrastructure-validated, Copilot-assisted deployment — using a Java (Maven/Gradle) toolchain throughout.

## What You'll Practice

| Part | Skill | Time | Copilot Feature |
|------|-------|------|-----------------|
| **1** | Branch setup | 5 min | Copilot PR scaffold |
| **2** | Supply chain security (hands-on) | 12 min | SBOM generation + vulnerability scanning |
| **3** | Docker Compose — containerised deployment | 15 min | Copilot chat + inline YAML |
| **4** | CI/CD pipeline as code | 20 min | GitHub Actions / Azure Pipelines YAML authoring |
| **5** | IaC + GitOps | 25 min | MCP tools + code samples |
| **6** | Open PR, validate, cost review, deploy | 13 min | Chat verification + cost analysis + deployment |

---

## Setup

```bash
cd lab07

# Verify Java and build tools are available
java -version        # expect Java 17+
mvn -version         # Maven — or use Gradle below
# ./gradlew --version  # uncomment if using Gradle
```

> **Note:** There is no `pom.xml` or `build.gradle` in this directory yet. You create your build file in Part 2 as the first exercise step.

---

## The Scenario

You're an engineer taking a feature from a local commit to a production-ready deployment. **Copilot is your pair programmer for every artifact**: it generates the IaC that provisions resources, scaffolds the pipeline YAML that enforces security gates, and helps you reason about cost before any resource is created.

Your path through the lab:
1. **Create a feature branch** — your unit of deployable change
2. **Scan the supply chain** — generate an SBOM and surface CVEs before the pipeline does
3. **Containerise the service** — Docker Compose with Copilot-generated YAML for a Spring Boot app
4. **Author the CI/CD pipeline** — build → scan → validate-iac → approval → deploy stages
5. **Provision infrastructure** — Bicep or Terraform generated and validated with Copilot + MCP
6. **Open the PR and ship** — real artifacts, enforced gates, Copilot-assisted cost review

## Lab 07 Starter Artifacts

This lab is self-contained. Everything you need is created locally during the exercises.

### What you'll produce

1. `pom.xml` (Maven) or `build.gradle` (Gradle) for dependency scanning
2. `docker-compose.yml` for containerised deployment
3. `.github/workflows/lab07-pipeline.yml` (or `azure-pipelines.yml`) — CI/CD pipeline with supply-chain gates
4. `main.bicep` or `main.tf` — IaC generated with Copilot and validated locally
5. Optional evidence notes in `SECURITY_SCAN.md` and `COST_ESTIMATE.md`

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

## Part 1 — Branch Setup (5 min)

Create your working branch now. The PR opens in Part 6, once real artifacts exist — not on an empty commit.

### Your tasks

1. **Create and track your feature branch:**
   ```bash
   git checkout -b lab07/pr-workflow
   git push -u origin lab07/pr-workflow
   ```

2. **Ask Copilot to draft your PR description** (you’ll paste it when opening the PR in Part 6):
   ```
   Chat prompt: “Draft a GitHub PR description for a lab07 deployment branch (Java/Spring Boot).
   Include sections: Description, Changes (SBOM, pipeline YAML, IaC),
   Supply Chain Security checklist, Cost Estimate placeholder.
   Use markdown. Keep it under 30 lines.”
   ```
   Save the draft — you’ll fill in real findings as you work through the lab.

---

## Part 2 — Supply Chain Security: SBOM & Vulnerability Scanning (12 min)

Modern DevOps requires supply chain security awareness. You'll generate a bill-of-materials (SBOM) and scan for vulnerabilities — practices that are now standard in enterprise pipelines.

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

Supply chain security is not optional. SBOM generation and vulnerability scanning are standard practices in enterprise DevOps.

---

## Part 3 — Docker Compose: Containerised Deployment (15 min)

Docker Compose defines your entire service topology as YAML — the same format as CI/CD pipeline jobs (Part 4) and IaC modules (Part 5). Copilot generates the file; your job is to validate, understand, and commit it.

### Your tasks

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

5. **Understand why Docker Compose matters:**
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

Docker Compose gives you a reproducible, infrastructure-parity environment in a single YAML file. The same patterns — named services, environment variables, health checks — appear in Kubernetes manifests and cloud container services.

---

## Part 4 — CI/CD Pipeline as Code (20 min)

A markdown checklist is a reminder. A required status check is a **contract**. This part closes that gap: you'll author the pipeline YAML so that SBOM generation, CVE scanning, and IaC validation are enforced job gates — not aspirational bullet points.

### Pipeline structure

```
build → scan → validate-iac → (manual-approval) → deploy
```

Each job depends on the previous one (`needs:`). A CVE above the threshold fails `scan`, which prevents `validate-iac` from starting, which prevents the approval gate from appearing. Evidence artifacts are uploaded with `if: failure()` so reviewers can inspect findings in the run.

---

### Your tasks

#### Task 1: Author the pipeline YAML (10 min)

**GitHub Actions track:**

1. Create the workflow file:
   ```bash
   mkdir -p .github/workflows
   touch .github/workflows/lab07-pipeline.yml
   ```

2. Use Copilot to scaffold it:
   ```
   Chat prompt: "Create a GitHub Actions workflow named 'Lab07 Supply-Chain CI/CD'
   triggered on push to lab07/pr-workflow and pull_request to main.

   Define these jobs in sequence using 'needs:':

   build:
     - checkout, setup Java 17 (temurin distribution)
     - build with Maven: mvn -f lab07/pom.xml package -DskipTests
     - generate CycloneDX SBOM: mvn -f lab07/pom.xml org.cyclonedx:cyclonedx-maven-plugin:makeAggregateBom
     - upload lab07/target/bom.xml as artifact 'sbom'

   scan:
     - download artifact 'sbom'
     - run OWASP Dependency Check: mvn -f lab07/pom.xml org.owasp:dependency-check-maven:check
     - upload lab07/target/dependency-check-report.html as artifact 'cve-report' using 'if: failure()'
     - add a step with 'if: failure()' that prints ::error:: and exits 1

   validate-iac:
     - if hashFiles('lab07/main.bicep') != '', run: az bicep install && az bicep build --file lab07/main.bicep
     - if hashFiles('lab07/main.tf') != '', run: cd lab07 && terraform init -backend=false && terraform validate
     - add a step with 'if: failure()' that prints ::error:: IaC validation failed

   manual-approval:
     - runs-on: ubuntu-latest, environment: production
     - single step: echo 'All gates passed. Pending approval.'

   deploy:
     - dry-run only: echo 'Would run: az deployment group create --what-if / terraform plan'
     - no real deployment"
   ```

3. Review the generated file against this reference structure:
   ```yaml
   name: Lab07 Supply-Chain CI/CD

   on:
     push:
       branches: [lab07/pr-workflow]
     pull_request:
       branches: [main]

   jobs:
     build:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v4
         - uses: actions/setup-java@v4
           with:
             java-version: '17'
             distribution: 'temurin'
         - name: Build (skip tests)
           run: mvn -f lab07/pom.xml package -DskipTests
         - name: Generate SBOM (CycloneDX)
           run: mvn -f lab07/pom.xml org.cyclonedx:cyclonedx-maven-plugin:makeAggregateBom
         - uses: actions/upload-artifact@v4
           with: { name: sbom, path: lab07/target/bom.xml }

     scan:
       runs-on: ubuntu-latest
       needs: build
       steps:
         - uses: actions/checkout@v4
         - uses: actions/setup-java@v4
           with:
             java-version: '17'
             distribution: 'temurin'
         - uses: actions/download-artifact@v4
           with: { name: sbom, path: lab07/target/ }
         - name: OWASP Dependency Check
           run: mvn -f lab07/pom.xml org.owasp:dependency-check-maven:check
         - name: Upload CVE report on failure
           if: failure()
           uses: actions/upload-artifact@v4
           with: { name: cve-report, path: lab07/target/dependency-check-report.html }
         - name: Surface CVE failures
           if: failure()
           run: |
             echo "::error::CVE scan failed. Download the cve-report artifact for details."
             exit 1

     validate-iac:
       runs-on: ubuntu-latest
       needs: scan
       steps:
         - uses: actions/checkout@v4
         - name: Validate Bicep
           if: hashFiles('lab07/main.bicep') != ''
           run: az bicep install && az bicep build --file lab07/main.bicep
         - name: Validate Terraform
           if: hashFiles('lab07/main.tf') != ''
           run: |
             cd lab07
             terraform init -backend=false && terraform validate
         - name: Surface IaC errors
           if: failure()
           run: echo "::error::IaC validation failed — fix before requesting approval."

     manual-approval:
       runs-on: ubuntu-latest
       needs: validate-iac
       environment: production   # configure Required reviewers in Settings → Environments
       steps:
         - run: echo "All gates passed. Awaiting reviewer approval."

     deploy:
       runs-on: ubuntu-latest
       needs: manual-approval
       steps:
         - uses: actions/checkout@v4
         - name: Dry-run deploy (no real resources)
           run: |
             echo "Would run: az deployment group create --what-if ..."
             echo "Or: terraform plan -out=tfplan"
   ```

   > **Gradle users:** Replace the Maven steps with `./gradlew lab07:build`, `./gradlew lab07:cyclonedxBom`, and `./gradlew lab07:dependencyCheckAnalyze`. Adjust artifact paths from `target/` to `build/reports/`.

4. Commit the pipeline:
   ```bash
   git add .github/workflows/lab07-pipeline.yml
   git commit -m "lab07: Add CI/CD pipeline with supply-chain gates"
   git push origin lab07/pr-workflow
   ```

**Azure Pipelines track (alternative):**

If your team uses Azure DevOps Repos, create `azure-pipelines.yml` at the repo root:

1. Ask Copilot:
   ```
   Chat prompt: "Translate the Lab07 GitHub Actions pipeline into Azure Pipelines YAML with
   equivalent stages: Build → Scan → ValidateIaC → ManualApproval → Deploy (dry-run).
   Use Maven (Java 17) for build and OWASP Dependency Check for CVE scanning.
   Use 'condition: failed()' for evidence-upload tasks and an ADO Environment named
   'production' for the approval gate."
   ```

2. Key structural differences:

   | Concept | GitHub Actions | Azure Pipelines |
   |---------|---------------|-----------------|
   | Job sequencing | `needs:` | `dependsOn:` inside `stages:` |
   | Conditional steps | `if: failure()` | `condition: failed()` |
   | Manual gate | GitHub Environment + required reviewers | ADO Environment + Approvals and checks |
   | Artifact upload | `upload-artifact` action | `PublishBuildArtifacts` task |
   | IaC validation failure | `echo "::error::"` | `Write-Host "##vso[task.logissue type=error]"` |

---

#### Task 2: Configure required status checks (5 min)

Required status checks turn optional CI runs into **merge blockers**. Without this step, the pipeline is advisory — a developer can merge even if `scan` is red.

**GitHub branch protection:**

1. Go to **Settings → Branches → Add branch protection rule** for `main`
2. Enable **"Require status checks to pass before merging"**
3. Search for and add these as required checks:
   - `scan`
   - `validate-iac`
4. Enable **"Require branches to be up to date before merging"**

   > Copilot prompt: `"What branch protection settings enforce supply-chain security gates on a Java Maven repo? Include status checks and signed commits."`

**GitHub Environment for manual approval:**

1. Go to **Settings → Environments → New environment** → name it `production`
2. Add **Required reviewers** (yourself or a teammate)
3. The `manual-approval` job will pause at this gate until a reviewer approves in the Actions UI

**Azure DevOps equivalent:**

1. Go to **Pipelines → Environments → New environment** → name it `production`
2. Add an **Approvals and checks** rule with required approvers
3. Reference it in the `ManualApproval` stage — the pipeline blocks until approved

---

#### Task 3: Verify gate behavior (5 min)

1. **Break the CVE scan intentionally** — add a known-vulnerable dependency to `pom.xml`:
   ```xml
   <!-- Add inside <dependencies> — Spring Framework with known CVEs -->
   <dependency>
     <groupId>org.springframework</groupId>
     <artifactId>spring-core</artifactId>
     <version>5.2.0.RELEASE</version>
   </dependency>
   ```
   ```bash
   git add lab07/pom.xml
   git commit -m "lab07: TEST — introduce CVE to verify gate"
   git push origin lab07/pr-workflow
   ```

2. **Observe the pipeline run:**
   - The `scan` job should fail
   - `validate-iac`, `manual-approval`, and `deploy` should never start
   - The `cve-report` artifact should be downloadable from the failed run
   - The PR merge button should be blocked (if required status checks are configured)

3. **Ask Copilot to review your pipeline:**
   ```
   Chat prompt: "Review this GitHub Actions pipeline for supply-chain security best practices:
   - Are job dependencies correctly sequenced with 'needs:'?
   - Are failure handlers using 'if: failure()' in the right places?
   - Is the manual approval gate positioned correctly in the flow?
   - What additional hardening would you recommend (pinned action SHAs,
     OIDC federation instead of long-lived secrets, artifact attestation)?"
   ```

4. **Revert the intentional CVE and push a clean commit:**
   ```bash
   git add lab07/pom.xml
   git commit -m "lab07: Revert test CVE — restore clean pom.xml"
   git push origin lab07/pr-workflow
   ```

### Key Insight

Embedding SBOM generation and CVE scanning as **pipeline job steps** with `if: failure()` gates and required-status-check enforcement is the difference between *documenting* supply-chain policy and *enforcing* it. Manual approval gates ensure that every deployment to production has a human sign-off — after all automated gates pass, never before.

---

## Part 5 — Infrastructure-as-Code + GitOps (25 min)

Modern infrastructure must be **versioned** and **auditable**. This section teaches IaC fundamentals alongside GitOps patterns.

### Subsection A: Infrastructure-as-Code Fundamentals (18 min)

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

3. **Commit your IaC:**
   ```bash
   git add main.bicep  # or main.tf/variables.tf/outputs.tf
   git commit -m "lab07: Add IaC with GitOps pattern"
   git push origin lab07/pr-workflow
   ```

### Key Insight

**Infrastructure-as-Code** ensures your infrastructure is versioned and reproducible.  
**GitOps** ensures all changes flow through Git and CI/CD, never manual.

---

## Part 6 — Open PR, Validate, Cost Review & Deploy (13 min)

### Your tasks

#### Task 1: Open your pull request (2 min)

You now have real artifacts to ship. Use Copilot to write the PR description from your branch diff — not from the placeholder you drafted in Part 1.

1. **Ask Copilot to write the PR description from your diff:**
   ```
   Chat prompt: “Write a PR description for the lab07/pr-workflow branch (Java/Spring Boot).
   Summarise: the SBOM and CVE scan findings (Part 2), the CI/CD pipeline
   structure with its security gates (Part 4), and the IaC resources defined
   (Part 5). Include the supply chain security checklist and cost estimate
   placeholder.”
   ```

2. **Open the PR:**
   - GitHub: use `/createPullRequest` in Copilot Chat, or repository → Pull requests → New pull request
   - Azure DevOps: Repos → Pull requests → New pull request

3. **Reference tracker items:**
   - Group A (ADO work items): `AB#<ID>`
   - Group B (Jira): `PROJ-<ID>`
   - GitHub Issues: `Closes #<ID>`

#### Task 2: Validate containers (2 min)

1. **Validate your docker-compose.yml:**
   ```bash
   # Check syntax (requires Docker)
   docker compose config

   # Or ask Copilot:
   # "Validate this docker-compose.yml for syntax and best practices"
   ```

2. **Check for common issues:**
   - Indentation is 2 spaces (not tabs)
   - No trailing spaces
   - All required fields are present

#### Task 3: Validate infrastructure code (2 min)

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

#### Task 4: Cost estimation (3 min)

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

#### Task 5: Merge when ready (optional)

When your PR passes all gates and a reviewer approves:

```bash
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

Validation covers syntax, security, and **cost awareness**. Engineers who understand infrastructure economics ship more confidently.

---

## Summary

In this lab, you’ve practised **Copilot-assisted deployment** with a Java toolchain:

✅ **Supply Chain Security** — CycloneDX SBOM from Maven/Gradle + OWASP Dependency Check as enforced pipeline gates  
✅ **Containerised Deployment** — Docker Compose generated and validated with Copilot for Spring Boot  
✅ **CI/CD Pipeline Authoring** — build → scan → validate-iac → approval → deploy in GitHub Actions or Azure Pipelines  
✅ **Policy-as-Code** — CVE and IaC failures as required status checks, not markdown checklists  
✅ **Infrastructure-as-Code** — Bicep or Terraform generated with Copilot + MCP, validated locally  
✅ **GitOps Patterns** — Git as single source of truth for infrastructure state  
✅ **Cost Awareness** — Copilot-assisted infrastructure economics before deployment  
✅ **PR Authoring** — Copilot writes the PR description from your branch diff, not from a template  

These skills form the foundation of **Copilot-assisted DevOps** practice.
