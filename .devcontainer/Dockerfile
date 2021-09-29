# See here for image contents: https://github.com/microsoft/vscode-dev-containers/tree/v0.194.0/containers/dotnet/.devcontainer/base.Dockerfile

# [Choice] .NET version: 5.0, 3.1, 2.1
ARG VARIANT="5.0"
FROM mcr.microsoft.com/vscode/devcontainers/dotnet:0-${VARIANT}

# [Option] Install Azure CLI
ARG INSTALL_AZURE_CLI="false"

# Copy everything from library scripts to new container
COPY library-scripts/* /tmp/library-scripts/
RUN apt-get update && /bin/bash /tmp/library-scripts/docker-debian.sh
#RUN apt-get update && /bin/bash /tmp/library-scripts/docker-in-docker-debian.sh
RUN if [ "$INSTALL_AZURE_CLI" = "true" ]; then bash /tmp/library-scripts/azcli-debian.sh; fi \
    && apt-get clean -y \ 
    && rm -rf /var/lib/apt/lists/*

# [Optional] Uncomment this section to install additional OS packages.
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends iputils-ping trickle cron \
    && apt-get clean -y \ 
    && rm -rf /var/lib/apt/lists/*

RUN sudo service cron start

CMD ["sleep", "infinity"]
ENTRYPOINT ["/usr/local/share/docker-init.sh"]

