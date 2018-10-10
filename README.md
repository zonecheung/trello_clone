# README

This app is developed using Ruby v2.5.1, Rails v5.2.1, Vue.js v2.5.7, with Postgres as database back-end.

Tested working in latest Chrome browser.

## Installation

 1. Clone or download from this repo to a directory.

 2. Run `bundle install` in that directory.

 3. Run `yarn install` to install front-end related packages.

 4. Create `config/database.yml` or copy & edit from `config/database.yml-example`.

 5. Run `rake db:setup` to create the database for development and test envs.

## Run

 1. Run `rails s` to start the server at the default port 3000.

 2. Run `bin/webpack-dev-server` (optional) to start the webpack in development mode.

 3. Open the browser and visit `http://localhost:3000` to load the page.

## Testing

For Rails, run `rake spec`.

## Files & Directories

The files for Rails are located in `app` directory as usual, and the specs are in `spec`.

The files for Vue.js are located in `app/javascript/packs`, and the tests are in `test/javascripts`.

## Miscellaneous

The code is also written based on certain `rubocop` recommendations, run `rubocop` to verify if there's any offenses.
