#!/usr/bin/env bash
set -eu
bundle exec rails runner /homework/Демонстрация/redmine/project.rb
exec bundle exec rails server -b 0.0.0.0 -p 3000
