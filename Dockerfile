FROM nvcr.io/nvidia/isaac-sim:6.0.1

SHELL ["/bin/bash", "-c"]

ARG USER=marc
ARG USER_UID=1000
ARG USER_GID=1000
ARG HOME=/home/${USER}
ARG WORKSPACE_PATH=${HOME}/Documents/code/workspace

# Isaac Sim environment
ENV ISAACSIM_ROOT_PATH=/isaac-sim
ENV ACCEPT_EULA=Y
ENV LANG=C.UTF-8
ENV DEBIAN_FRONTEND=noninteractive

USER root

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    sudo \
    curl \
    git \
    git-lfs \
    openssh-client \
    gpg \
    mesa-utils \
    build-essential \
    cmake \
    libglib2.0-0 \
    ncurses-term \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Remove user if exists and create the new user
RUN (userdel -r $(getent passwd ${USER_UID} | cut -d: -f1) 2>/dev/null || true) && \
    (groupdel $(getent group ${USER_GID} | cut -d: -f1) 2>/dev/null || true) && \
    groupadd -g ${USER_GID} "${USER}" && \
    useradd --no-log-init -l -u ${USER_UID} -g ${USER_GID} -s /bin/bash \
            -d "${HOME}" -m "${USER}" && \
    echo "${USER} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/devcontainer_user && \
    chmod 0440 /etc/sudoers.d/devcontainer_user && \
    usermod -aG sudo "${USER}" 2>/dev/null || true && \
    touch ${HOME}/.sudo_as_admin_successful

# Isaac Lab path (matches the workspace bind-mount target)
ENV ISAACLAB_PATH=${WORKSPACE_PATH}/IsaacLab

# Copy Isaac Lab source into the image for build-time install
COPY IsaacLab/ ${ISAACLAB_PATH}/

# Fix line endings and set execute permission
RUN find ${ISAACLAB_PATH} -type f -name "*.sh" -exec sed -i 's/\r$//' {} +
RUN chmod +x ${ISAACLAB_PATH}/isaaclab.sh

# Create symbolic link from Isaac Lab to Isaac Sim
RUN ln -sf ${ISAACSIM_ROOT_PATH} ${ISAACLAB_PATH}/_isaac_sim

# Install toml dependency
RUN ${ISAACLAB_PATH}/isaaclab.sh -p -m pip install toml

# Install apt dependencies declared by extensions
RUN ${ISAACLAB_PATH}/isaaclab.sh -p ${ISAACLAB_PATH}/tools/install_deps.py apt ${ISAACLAB_PATH}/source && \
    apt-get -y autoremove && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Pre-create named-volume mount points so fresh volumes inherit correct ownership
RUN mkdir -p ${ISAACSIM_ROOT_PATH}/kit/cache && \
    mkdir -p ${ISAACSIM_ROOT_PATH}/kit/data && \
    mkdir -p ${HOME}/.cache/ov && \
    mkdir -p ${HOME}/.cache/pip && \
    mkdir -p ${HOME}/.cache/nvidia/GLCache && \
    mkdir -p ${HOME}/.nv/ComputeCache && \
    mkdir -p ${HOME}/.nvidia-omniverse/logs && \
    mkdir -p ${ISAACSIM_ROOT_PATH}/kit/logs/Kit/Isaac-Sim && \
    mkdir -p ${HOME}/.local/share/ov/data && \
    mkdir -p ${HOME}/Documents

# Install Isaac Lab extensions (editable pip install) with all extras
# Runs as root because Isaac Sim's site-packages under /isaac-sim need root write
ENV PIP_DEFAULT_TIMEOUT=120
RUN ${ISAACLAB_PATH}/isaaclab.sh --install

# Make home and Isaac Sim cache dirs writable by the runtime user
RUN chown -R ${USER}:${USER} ${HOME} && \
    chown -R ${USER}:${USER} ${ISAACSIM_ROOT_PATH}/kit/cache ${ISAACSIM_ROOT_PATH}/kit/data ${ISAACSIM_ROOT_PATH}/kit/logs/Kit/Isaac-Sim && \
    chmod 755 ${ISAACSIM_ROOT_PATH} && \
    chmod 750 ${HOME}

# Convenience aliases
RUN echo "export ISAACLAB_PATH=${ISAACLAB_PATH}" >> ${HOME}/.bashrc && \
    echo "alias isaaclab=${ISAACLAB_PATH}/isaaclab.sh" >> ${HOME}/.bashrc && \
    echo "alias python=${ISAACLAB_PATH}/_isaac_sim/python.sh" >> ${HOME}/.bashrc && \
    echo "alias python3=${ISAACLAB_PATH}/_isaac_sim/python.sh" >> ${HOME}/.bashrc && \
    echo "alias pip='${ISAACLAB_PATH}/_isaac_sim/python.sh -m pip'" >> ${HOME}/.bashrc && \
    echo "alias pip3='${ISAACLAB_PATH}/_isaac_sim/python.sh -m pip'" >> ${HOME}/.bashrc

USER ${USER}

# Install OpenCode
RUN curl -fsSL https://opencode.ai/install | bash

WORKDIR ${WORKSPACE_PATH}
CMD ["/bin/bash"]
