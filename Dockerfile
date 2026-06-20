# Stage 1: Build the Flutter web application
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

# Copy pubspec and get dependencies
COPY pubspec.* ./
RUN flutter pub get

# Copy the rest of the application
COPY . .

# Build the web application
RUN flutter build web

# Stage 2: Serve the application using Nginx
FROM nginx:alpine

# Copy the build artifacts from the previous stage
COPY --from=build /app/build/web /usr/share/nginx/html

# Copy a custom nginx config for SPA routing
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port 80
EXPOSE 80

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
