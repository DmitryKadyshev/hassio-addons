#!/usr/bin/env bashio
# declare port
# declare admin_password
# declare black_hole
WAIT_PIDS=()

bashio::log.info "starting jackett"

# if ! bashio::fs.directory_exists '/config/jackett'; then
# 	mkdir -p /config/Jackett || bashio::exit.nok "error in folder creation"
# fi

# black_hole=$(bashio::config 'black_hole')
# admin_password=$(bashio::config 'admin_password')

# bashio::log.info "Black hole: ${black_hole}"

# if ! bashio::fs.directory_exists "${black_hole}"; then
# 	mkdir -p $black_hole || bashio::exit.nok "error in folder creation 3"
# fi

# mv /Jackett/ServerConfig.json /config/Jackett/ServerConfig.json || bashio::exit.nok "error in config move"

# sed -i "s#%%black_hole%%#${black_hole}#g" /config/Jackett/ServerConfig.json || bashio::exit.nok "error in blackhole sed"

# sed -i "s#%%admin_password%%#${admin_password}#g" /config/Jackett/ServerConfig.json || bashio::exit.nok "error in port sed"


cd /opt/Jackett || bashio::exit.nok "setup gone wrong!"

exec ./jackett -d /config --NoUpdates &
WAIT_PIDS+=($!)

function stop_addon() {
	bashio::log.info "Kill Processes..."
	kill -15 "${WAIT_PIDS[@]}"
	bashio::log.info "Done"
}

trap "stop_addon" SIGTERM SIGHUP

#Wait until all is done
bashio::log.info "All is running smoothly"
wait "${WAIT_PIDS[@]}"
