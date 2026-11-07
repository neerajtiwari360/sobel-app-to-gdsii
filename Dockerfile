# OpenROAD Flow Scripts image: synthesis, technology mapping, place/route, GDSII.
FROM openroad/orfs:latest

USER root
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
       iverilog python3 python3-numpy ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
CMD ["bash", "/workspace/docker/run-all.sh"]
