ARG UBUNTU_VERSION=24.04
FROM ubuntu:${UBUNTU_VERSION}

ENV DEBIAN_FRONTEND=noninteractive

# Basic packages
RUN apt-get update && apt-get install -y \
    sudo \
    openssh-server \
    curl \
    ca-certificates \
    git \
    wget \
    nano \
    python3 \
    python3-pip \
    ansible-core \
    passwd \
    software-properties-common \
    && rm -rf /var/lib/apt/lists/*

RUN service dbus start

# Create a user for SSH access
RUN useradd -m -s /bin/bash ubuntu_user && \
    echo "ubuntu_user ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    mkdir -p /home/ubuntu_user/.ssh && \
    chmod 700 /home/ubuntu_user/.ssh && \
    chown -R ubuntu_user:ubuntu_user /home/ubuntu_user/.ssh



# Set empty passwrd for ubuntu_user 
RUN usermod -p "" ubuntu_user

# SSH without auth(it's local for test only!)
RUN mkdir -p /run/sshd && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PermitEmptyPasswords no/PermitEmptyPasswords yes/' /etc/ssh/sshd_config

EXPOSE 22

COPY entrypoint.sh /entrypoint.sh
CMD ["/entrypoint.sh"]


