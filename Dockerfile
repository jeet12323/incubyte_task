# syntax=docker/dockerfile:1
# Single image: build the React app, then run Rails, which serves both the API and the SPA.

# --- 1. Frontend build ---------------------------------------------------------------------------
FROM node:22-slim AS frontend
WORKDIR /frontend
COPY frontend/package.json frontend/package-lock.json ./
RUN npm ci
COPY frontend/ ./
RUN npm run build

# --- 2. Ruby gems ---------------------------------------------------------------------------------
FROM ruby:3.3-slim AS gems
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential libpq-dev libyaml-dev git && \
    rm -rf /var/lib/apt/lists/*
ENV BUNDLE_DEPLOYMENT=1 BUNDLE_WITHOUT="development:test" BUNDLE_PATH=/usr/local/bundle
WORKDIR /app
COPY backend/Gemfile backend/Gemfile.lock ./
RUN bundle install && rm -rf "${BUNDLE_PATH}"/ruby/*/cache

# --- 3. Runtime -----------------------------------------------------------------------------------
FROM ruby:3.3-slim
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y libpq5 libyaml-0-2 curl && \
    rm -rf /var/lib/apt/lists/*
ENV RAILS_ENV=production BUNDLE_DEPLOYMENT=1 BUNDLE_WITHOUT="development:test" BUNDLE_PATH=/usr/local/bundle
WORKDIR /app
COPY --from=gems /usr/local/bundle /usr/local/bundle
COPY backend/ ./
COPY --from=frontend /frontend/dist/ ./public/
RUN bundle exec bootsnap precompile app/ lib/ && \
    useradd --create-home rails && chown -R rails:rails log tmp
USER rails

EXPOSE 3000
# Migrate, seed the demo data on first boot only, then start Puma.
CMD ["sh", "-c", "bin/rails db:prepare && bin/rails db:seed_if_empty && bundle exec puma -C config/puma.rb"]
