# Serves the Flutter web build. Prerequisite: `flutter build web --release`
# (build/ is gitignored, so the image is built locally after a web build).
FROM nginx:1.27-alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY build/web /usr/share/nginx/html
EXPOSE 80
HEALTHCHECK --interval=30s --timeout=3s CMD wget -qO- http://localhost/ >/dev/null || exit 1