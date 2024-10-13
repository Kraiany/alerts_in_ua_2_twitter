# Use an official Ruby runtime as a parent image
FROM ruby:3.1.3-alpine3.17

# install pg, bigdecimal and development dependencies
RUN apk add --no-cache postgresql-dev libffi-dev build-base

# Set the working directory in the container
WORKDIR /app

# Copy the current directory contents into the container at /app
COPY . /app

# Install any needed packages specified in Gemfile
RUN bundle install

# Run the alert_twitter script when the container launches
CMD ["ruby", "bin/alert_twitter"]

