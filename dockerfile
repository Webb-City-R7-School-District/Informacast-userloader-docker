# Use an official lightweight base image
FROM ubuntu:20.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive

# Install required packages, including Java
RUN apt-get update && \
    apt-get install -y git cron curl openjdk-21-jre && \
    apt-get clean

# Create a user for running the script
RUN useradd -ms /bin/bash loaderuser

# Switch to the root user to set up cron and log file
USER root
WORKDIR /home/loaderuser

# Set a build-time variable for the GitHub token
ARG GITHUB_TOKEN
ARG GITHUB_REPO

# Create the crontab file with the desired command using git pull
RUN echo "0 * * * * cd /home/loaderuser/Informacast-User-Loader && git pull >> /proc/1/fd/1 && chmod +x /home/loaderuser/Informacast-User-Loader/loader.sh >> /proc/1/fd/1 && /home/loaderuser/Informacast-User-Loader/loader.sh --do-upload >> /proc/1/fd/1" > /etc/cron.d/loader-cron

# Give execution rights on the cron job
RUN chmod 0644 /etc/cron.d/loader-cron

# Apply cron job
RUN crontab /etc/cron.d/loader-cron

# Create necessary directories and set permissions
RUN mkdir -p /var/run/ && \
    touch /var/log/cron.log && \
    chown loaderuser:loaderuser /var/log/cron.log && \
    chown root:root /var/run && chmod 755 /var/run

# Run cron in the foreground and clone the repo on startup
CMD ["bash", "-c", "[ ! -d /home/loaderuser/Informacast-User-Loader ] && git clone https://$GITHUB_TOKEN@$GITHUB_REPO /home/loaderuser/Informacast-User-Loader || echo 'Repo already exists'; chmod -R 777 /home/loaderuser/Informacast-User-Loader; chmod +x /home/loaderuser/Informacast-User-Loader/loader.sh; cron -f"]
