# ---------- Build stage ----------
FROM ghcr.io/cirruslabs/flutter:stable AS builder

# Set working directory
WORKDIR /app

# Copy all source files
COPY . .

# Install dependencies
RUN flutter pub get

# Build Flutter web release (with dynamic API base URL)
ARG API_BASE_URL
RUN flutter build web --release --dart-define=API_BASE_URL=${API_BASE_URL}

# ---------- Serve stage ----------
FROM nginx:alpine

# Copy the built web app to Nginx's default public directory
COPY --from=builder /app/build/web /usr/share/nginx/html

# Expose port 80 for the web server
EXPOSE 80

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
