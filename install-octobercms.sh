#!/bin/bash

DIRECTORY=$1

APP_ENV_DEFAULT="dev"
APP_DEBUG_DEFAULT="true"
APP_URL_DEFAULT="http://localhost"

DB_CONNECTION_DEFAULT="mysql"
DB_HOST_DEFAULT="localhost"
DB_PORT_DEFAULT="33060"
DB_DATABASE_DEFAULT="app"
DB_USERNAME_DEFAULT="homestead"
DB_PASSWORD_DEFAULT="secret"

function installOctoberCMS {

	echo "=== Installing OctoberCMS ==="
	composer create-project october/october $DIRECTORY

	echo "=== Updating composer ==="
	cd $DIRECTORY
	composer update
}

function setupHomestead {

	echo "=== Setup homestead ==="
	composer require laravel/homestead --dev
	php vendor/bin/homestead make --hostname=default
}

function setupOctoberCMS {

	php artisan october:env

	rm -Rf .env

	echo "=== Add Development env file ==="

	read -p "APP_ENV: [$APP_ENV_DEFAULT]: " APP_ENV
	APP_ENV="${APP_ENV:-$APP_ENV_DEFAULT}"

	read -p "APP_DEBUG: [$APP_DEBUG_DEFAULT]: " APP_DEBUG
	APP_DEBUG="${APP_DEBUG:-$APP_DEBUG_DEFAULT}"

	read -p "APP_URL: [$APP_URL_DEFAULT]: " APP_URL
	APP_URL="${APP_URL:-$APP_URL_DEFAULT}"

	read -p "DB_CONNECTION: [$DB_CONNECTION_DEFAULT]: " DB_CONNECTION
	DB_CONNECTION="${DB_CONNECTION:-$DB_CONNECTION_DEFAULT}"

	read -p "DB_HOST: [$DB_HOST_DEFAULT]: " DB_HOST
	DB_HOST="${DB_HOST:-$DB_HOST_DEFAULT}"

	read -p "DB_PORT: [$DB_PORT_DEFAULT]: " DB_PORT
	DB_PORT="${DB_PORT:-$DB_PORT_DEFAULT}"

	read -p "DB_DATABASE: [$DB_DATABASE_DEFAULT]: " DB_DATABASE
	DB_DATABASE="${DB_DATABASE:-$DB_DATABASE_DEFAULT}"

	read -p "DB_USERNAME: [$DB_USERNAME_DEFAULT]: " DB_USERNAME
	DB_USERNAME="${DB_USERNAME:-$DB_USERNAME_DEFAULT}"

	read -p "DB_PASSWORD: [$DB_PASSWORD_DEFAULT]: " DB_PASSWORD
	DB_PASSWORD="${DB_PASSWORD:-$DB_PASSWORD_DEFAULT}"

	printf "APP_ENV=$APP_ENV\nAPP_DEBUG=$APP_DEBUG\nAPP_URL=$APP_URL\n\nDB_CONNECTION=$DB_CONNECTION\nDB_HOST=$DB_HOST\nDB_PORT=$DB_PORT\nDB_DATABASE=$DB_DATABASE\nDB_USERNAME=$DB_USERNAME\nDB_PASSWORD=$DB_PASSWORD" > .env
}

function editHomesteadFile {

	echo "=== Edit homestead file ==="
	perl -pi -e 's/public//' Homestead.yaml
	perl -pi -e 's/sites\:/sites\:\n    - map\: adminer.db\n      to\: \/home\/vagrant\/adminer/s' Homestead.yaml
}

function editVagrantFile {

	perl -pi -e 's/aliasesPath = \"aliases\"/octoberCMSInstaller = \"..\/october-shell-provision\/setup.sh\"\n$&/s' Vagrantfile
	perl -pi -e 's/Homestead.configure\(config, settings\)/if File.exist\? octoberCMSInstaller then\nconfig.vm.provision \"shell\", path: octoberCMSInstaller\nend\n$&/s' Vagrantfile

	echo "=== OctoberCMS setup complete ==="
}

function runVagrant {

	vagrant up
	vagrant ssh  -- -t 'mysql -uhomestead -psecret -e "CREATE DATABASE app"'
	echo "=== Added database $DB_DATABASE ==="

	vagrant ssh  -- -t "cd Code/$DIRECTORY; php artisan october:up"
	echo "=== Seeded $DB_DATABASE ==="
}

installOctoberCMS
setupHomestead
setupOctoberCMS
editHomesteadFile
editVagrantFile
runVagrant
