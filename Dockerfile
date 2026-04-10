FROM nvidia/cuda:12.1.1-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN echo "Acquire::http::Pipeline-Depth 0;" > /etc/apt/apt.conf.d/99custom && \
    echo "Acquire::http::No-Cache true;" >> /etc/apt/apt.conf.d/99custom && \
    echo "Acquire::BrokenProxy    true;" >> /etc/apt/apt.conf.d/99custom

# System deps - ffmpeg and libgl required by SPAG4D
RUN apt-get update && apt-get upgrade -y && apt-get install -y --no-install-recommends \
    software-properties-common build-essential wget curl git ca-certificates \
    ffmpeg libgl1 libglib2.0-0 \
    && add-apt-repository ppa:deadsnakes/ppa && apt-get update \
    && apt-get install -y --no-install-recommends \
    python3.11 python3.11-dev python3.11-venv \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN python3.11 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

RUN mkdir /workspace
WORKDIR /workspace

# Clone SPAG4D
RUN git clone https://github.com/cedarconnor/SPAG4d.git --depth 1
WORKDIR /workspace/SPAG4d

# PyTorch — cu121 as specified in README
RUN pip install --no-cache-dir torch torchvision \
    --index-url https://download.pytorch.org/whl/cu121

# SPAG4D dependencies from requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# DA360 depth model (recommended over DAP per README)
RUN git clone https://github.com/Insta360-Research-Team/DA360 \
    spag4d/da360_arch/DA360 --depth 1

# DAP submodule (also needed as fallback)
RUN git submodule update --init --recursive --depth 1

# plyfile — listed as optional in README but needed for .ply export
RUN pip install --no-cache-dir plyfile

# runpod — your existing infrastructure requirement
RUN pip install --no-cache-dir runpod

WORKDIR /workspace
COPY startup.py .

# Model weights download at runtime via startup.py
# keeps the image lean and puts weights on the persistent volume
ENV HF_HOME="/runpod-volume/huggingface/data_Cache"
ENV HF_HUB_CACHE="/runpod-volume/huggingface/model_Cache"
ENV TMPDIR="/runpod-volume/tmp"

# Point SPAG4D model cache to volume so weights persist across rebuilds
ENV SPAG4D_MODEL_DIR="/runpod-volume/spag4d_models"

RUN mkdir -p /runpod-volume/huggingface/data_Cache \
             /runpod-volume/huggingface/model_Cache \
             /runpod-volume/tmp \
             /runpod-volume/spag4d_models

VOLUME ["/runpod-volume"]

CMD ["python3.11", "-u", "startup.py"]
