# Databricks Medallion CI/CD Pipeline

End-to-end data pipeline with automated CI/CD across three environments, built to mirror real enterprise DE workflows.

## What This Does

Raw TPC-H data (orders, customers, suppliers, 30M+ rows) flows through a Bronze → Silver → Gold medallion architecture on Databricks Unity Catalog. Every code change goes through an automated pipeline that validates, tests, and promotes across dev, staging, and prod without manual intervention.

## Architecture
GitHub (feature branch)
→ Pull Request → CI validates notebooks
→ Merge to main → Deploy to tpch_dev
→ Deploy to tpch_staging
→ Deploy to tpch_prod (manual gate)

Each environment is an isolated Unity Catalog. Same code, different target. No hardcoded configs.

## Tech Stack

Databricks (Unity Catalog, Workflows, Serverless), PySpark, Delta Lake, GitHub Actions, Azure DevOps Pipelines, Python

## Key Engineering Decisions

**Parameterized environments over code duplication.** A single `target_catalog` widget drives all three environments. The CI/CD pipeline passes the value at runtime, bronze to gold never knows which environment it's running in.

**MERGE over overwrite in silver.** All silver tables use Delta MERGE with ROW_NUMBER dedup to handle late-arriving and duplicate records from the ingestion layer. Lineitem required a composite key condition (`l_orderkey + l_linenumber`) after hitting DELTA_MULTIPLE_SOURCE_ROW_MATCHING_TARGET_ROW in the first run, a real production scenario.

**Broadcast joins on dimension tables.** Nation (25 rows) and region (5 rows) are explicitly broadcast in gold joins against the 30M-row lineitem table, eliminating unnecessary shuffles.

**Dual CI/CD.** GitHub Actions handles the primary pipeline. Azure DevOps replicates the same validate → dev → staging → prod flow using Azure Pipelines YAML, demonstrating the same pattern across both ecosystems.

## Repo Structure
notebooks/
bronze/   → Raw ingestion from samples.tpch to Delta
silver/   → Dedup, cleanse, MERGE via composite keys
gold/     → Business marts (revenue by region/quarter, supplier performance)
.github/workflows/cicd.yml     → GitHub Actions pipeline
azure-pipelines.yml            → Azure DevOps pipeline

## CI/CD Flow

On every PR: notebook syntax validation runs, deployment is blocked.  
On merge to main: validate → dev → staging → prod, sequential, automated.  
Prod requires manual approval gate before deployment.

## Problems Solved

Composite key MERGE failure on lineitem (30M rows, multi-column primary key). Session-aware notebook parameterization using dbutils widgets so the same notebook runs interactively and as a scheduled job. Environment drift eliminated by treating catalog name as a runtime parameter, not a hardcoded value.
