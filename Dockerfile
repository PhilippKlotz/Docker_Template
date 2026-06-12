# =============================================================================
#  Dockerfile — AI Coding Agents Workshop
#  https://github.com/AlexRieber/Workshops/Docker
#
#  Sets up: R, Python, Claude Code, OpenAI Codex, Google Gemini CLI, Aider
#  Build:   docker buildx build -t coding-agent .
#  Run:     docker compose up -d && docker exec -it my-agent bash
# =============================================================================

# === Base Image: Ubuntu 24.04 LTS ===
FROM ubuntu:24.04

# Avoid interactive prompts during package installation (build-time only)
ARG DEBIAN_FRONTEND=noninteractive

# === 1. System Tools ===
RUN apt-get update && apt-get install -y \
    curl wget git build-essential \
    software-properties-common \
    locales sudo nano jq tree \
    texlive texlive-latex-extra texlive-fonts-recommended texlive-xetex \
    && locale-gen en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# === 2. R (from CRAN repository for the latest stable version) ===
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        software-properties-common dirmngr && \
    wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | \
        tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc && \
    add-apt-repository "deb https://cloud.r-project.org/bin/linux/ubuntu noble-cran40/" && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        r-base r-base-dev \
        libcurl4-openssl-dev libssl-dev libxml2-dev \
        libfontconfig1-dev libharfbuzz-dev libfribidi-dev \
        libfreetype6-dev libpng-dev libtiff-dev libjpeg-dev && \
    rm -rf /var/lib/apt/lists/*

# Install core R packages (this step takes ~10-15 minutes)
RUN Rscript -e "install.packages(c( \
    'tidyverse', 'data.table', 'fixest', 'modelsummary', \
    'haven', 'labelled', 'sandwich', 'lmtest', \
    'ivreg', 'plm', 'rdrobust', 'rddensity', \
    'did', 'binsreg', 'marginaleffects', \
    'patchwork', 'scales', \
    'rmarkdown', 'knitr', 'bookdown', \
    'devtools', 'testthat', 'targets', 'here' \
    ), repos='https://cloud.r-project.org', Ncpus=4)"

# === 3. Python ===
RUN apt-get update && apt-get install -y \
    python3 python3-pip python3-venv && \
    rm -rf /var/lib/apt/lists/*

RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
RUN pip install --no-cache-dir \
    numpy pandas matplotlib jupyter

# Python SDKs for AI providers (used by Aider and for building custom agents)
RUN pip install --no-cache-dir \
    openai anthropic google-genai

# Aider: open-source AI coding agent with OpenRouter support
RUN pip install --no-cache-dir aider-chat

# Utilities for building custom agents
RUN pip install --no-cache-dir \
    rich prompt_toolkit pydantic

# === 4. Node.js 24 LTS (required for Codex and Gemini CLI) ===
RUN curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | \
        gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_24.x nodistro main" | \
        tee /etc/apt/sources.list.d/nodesource.list > /dev/null && \
    apt-get update && apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# === 5. Claude Code (native binary, does not require Node.js) ===
RUN curl -fsSL https://claude.ai/install.sh | bash

# === 6. OpenAI Codex ===
RUN npm install -g @openai/codex

# === 7. Google Gemini CLI ===
RUN npm install -g @google/gemini-cli

# === 8. Working Directories ===
RUN mkdir -p /home/agent/project \
             /home/agent/output \
             /home/agent/data/original \
             /home/agent/data/processed \
             /home/agent/code

WORKDIR /home/agent

# === 9. Copy Configuration (CLAUDE.md is mounted at runtime) ===
# The CLAUDE.md file is mounted as a volume so you can edit it
# without rebuilding the image.

CMD ["bash"]
