# frozen_string_literal: true

source "https://rubygems.org"

gemspec

# mihari-logger n'est pas publié sur RubyGems : dans le monorepo, la dépendance
# déclarée par la gemspec se résout sur le paquet voisin.
gem "mihari-logger", path: "../ruby"

group :development, :test do
  gem "rails", ">= 6.1", "< 8.0"
end
