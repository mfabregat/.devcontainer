# Agnostic Dev Container Template

A minimal, robust `.devcontainer` skeleton optimized for Linux. It replicates `osrf/rocker` features while remaining app-agnostic and lightweight.

## Features

* **GUI:** Native X11 and Wayland forwarding.
* **NVIDIA:** Host GPU and CUDA access (`nvidia-smi` functional).
* **Permissions:** Automatic host UID/GID mirroring to prevent volume permission conflicts.
* **SSH:** Host SSH agent forwarding for secure Git operations.
* **IPC/Network:** Host network mode, host IPC, and privileged mode for hardware device access (`/dev`).
* **Resources:** Max shared memory (`shm_size: '8gb'`) for deep learning and middleware.

## Structure

```text
.devcontainer/
├── devcontainer.json    # Orchestration & editor settings
├── docker-compose.yaml  # Hardware, volumes, and privileges
├── Dockerfile           # Minimal Ubuntu base image
└── initialize.sh        # Environment initialization script

```

## Setup

1. Copy the `.devcontainer` folder into your project root.
2. Open the project directory in VS Code or Cursor.
3. Run the command palette (`Ctrl+Shift+P`) and select `Dev Containers: Rebuild and Reopen in Container`.

## Customization

### Adding Dependencies

Add packages to `.devcontainer/Dockerfile`:

```dockerfile
RUN apt-get update && apt-get install -y --no-install-recommends \
    <your-packages> \
    && rm -rf /var/lib/apt/lists/*

```

### Shell Automation (e.g., ROS 2)

Append workspace sources to `.bashrc` inside the `Dockerfile`:

```dockerfile
RUN cat << 'EOF' >> /home/${USER}/.bashrc
if [ -f /opt/ros/jazzy/setup.bash ]; then source /opt/ros/jazzy/setup.bash; fi
if [ -f /workspace/install/setup.bash ]; then source /workspace/install/setup.bash; fi
EOF

```