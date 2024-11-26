# Use the official Ruby image as a base
FROM ruby:3.3.2

# Install required system dependencies
RUN apt-get update -qq && apt-get install -y \
    build-essential \
    libpq-dev \
    curl \
    postgresql-client

# Install Node.js and Yarn
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g yarn

# Set environment variables for Bundler
ENV BUNDLE_PATH=/bundle \
    BUNDLE_BIN=/bundle/bin \
    GEM_HOME=/bundle \
    PATH=/bundle/bin:$PATH

# Set the working directory in the container
WORKDIR /app

# Copy application dependencies
COPY Gemfile Gemfile.lock /app/

# Install Ruby gems
RUN bundle install

# Copy package.json and yarn.lock
COPY package.json yarn.lock /app/

# Test the presence of package.json and yarn.lock
RUN ls -l /app

# Install JavaScript dependencies
RUN yarn install

# Copy the rest of the application code
COPY . /app

# Precompile assets (if needed)
RUN RAILS_ENV=production bundle exec rails assets:precompile

# Expose port 3000
EXPOSE 3000

# Start the server
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
