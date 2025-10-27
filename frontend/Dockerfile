# #Build stage
# FROM cirrusci/flutter:latest AS builder
# WORKDIR /app
# COPY . .
# RUN flutter pub get
# RUN flutter build web --release --dart-define=API_BASE_URL=${API_BASE_URL}

# #Serve with nginx
# FROM nginx:alpine
# COPY --from=builder /app/build/web /usr/share/nginx/html
# EXPOSE 80
# CMD ["nginx", "-g", "daemon off;"]



#MacOS config

# Build stage
FROM mobiledevops/flutter-sdk-image:3.19.4 AS builder

# Create non-root user
RUN useradd -m flutteruser

# Create .config, .pub-cache, and .dart-tool directories for flutteruser and mobiledevops, and fix ownership
RUN mkdir -p /home/flutteruser/.config /home/flutteruser/.pub-cache /home/flutteruser/.dart-tool \
    /home/mobiledevops/.pub-cache /home/mobiledevops/.dart-tool && \
    chown -R flutteruser:flutteruser /home/mobiledevops/.flutter-sdk /home/mobiledevops/.pub-cache /home/mobiledevops/.dart-tool \
    /home/flutteruser/.config /home/flutteruser/.pub-cache /home/flutteruser/.dart-tool

# Add /home/mobiledevops/.flutter-sdk to Git's safe directory list
RUN git config --global --add safe.directory /home/mobiledevops/.flutter-sdk

# Set Flutter path
ENV PATH="/home/mobiledevops/.flutter-sdk/bin:${PATH}"

# Set PUB_CACHE to flutteruser's home directory
ENV PUB_CACHE="/home/flutteruser/.pub-cache"

USER flutteruser

# Clean Pub cache as flutteruser
RUN dart pub cache clean

WORKDIR /app
COPY --chown=flutteruser:flutteruser . .

# Flutter config (disable analytics) and pub get
RUN flutter config --no-analytics
RUN flutter pub get

# Flutter web build
ARG API_BASE_URL
RUN flutter build web --release --dart-define=API_BASE_URL=${API_BASE_URL}

# Serve with nginx
FROM nginx:alpine
COPY --from=builder /app/build/web /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
