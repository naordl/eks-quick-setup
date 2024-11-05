# Debian is pretty stable
FROM debian

# Install necessary tools
RUN apt update && apt install -y curl git awscli

# Install Helm
RUN curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && chmod +x kubectl && mv kubectl /usr/local/bin/

# Change working directory
WORKDIR helm-charts

# Copy files from the helm folder into the container
COPY . .

# Ensure that the setup script is executable
RUN chmod +x setup.sh

# Run the setup script when the container starts as opposed to running it at buildtime
ENTRYPOINT ["./setup.sh"]
