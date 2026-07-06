FROM ubuntu:24.04

ARG USER=marc
ARG USER_UID=1000
ARG USER_GID=1000

ENV DEBIAN_FRONTEND=noninteractive

# Essential dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    sudo \
    curl \
    git \
    git-lfs \
    openssh-client \
    gpg \
    mesa-utils \
    python3-pip \
    python-is-python3 \
    && rm -rf /var/lib/apt/lists/*

# Remove user if exists and create the new user
RUN (userdel -r $(getent passwd ${USER_UID} | cut -d: -f1) 2>/dev/null || true) && \
    (groupdel $(getent group ${USER_GID} | cut -d: -f1) 2>/dev/null || true) && \
    groupadd -g ${USER_GID} ${USER} && \
    useradd -m -u ${USER_UID} -g ${USER_GID} -s /bin/bash ${USER} && \
    echo "${USER} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USER} && \
    chmod 0440 /etc/sudoers.d/${USER} && \
    usermod -aG sudo ${USER} 2>/dev/null || true && \
    touch /home/${USER}/.sudo_as_admin_successful # Silence the sudo warning

USER ${USER}

# Install OpenCode
RUN curl -fsSL https://opencode.ai/install | bash

USER ${USER}
CMD [ "/bin/bash" ]