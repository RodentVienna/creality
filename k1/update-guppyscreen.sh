#!/bin/sh

config_overrides=true
apply_overrides=true
update_guppyscreen=true
while true; do
    if [ "$1" = "--config-overrides" ]; then
        apply_overrides=false
        update_guppyscreen=false
        shift
    elif [ "$1" = "--apply-overrides" ]; then
        config_overrides=false
        update_guppyscreen=false
        shift
    fi
    break
done

if [ "$config_overrides" = "true" ]; then
    if [ -f /usr/data/pellcorp-backups/guppyscreen.json ] && [ -f /usr/data/guppyscreen/guppyscreen.json ]; then
        [ -f /usr/data/pellcorp-overrides/guppyscreen.json ] && rm /usr/data/pellcorp-overrides/guppyscreen.json
        for entry in display_brightness invert_z_icon display_sleep_sec theme; do
            stock_value=$(jq -cr ".$entry" /usr/data/pellcorp-backups/guppyscreen.json)
            new_value=$(jq -cr ".$entry" /usr/data/guppyscreen/guppyscreen.json)
            # you know what its not an actual json file its just the properties we support updating
            if [ "$stock_value" != "null" ] && [ "$new_value" != "null" ] && [ "$stock_value" != "$new_value" ]; then
                echo "$entry=$new_value" >> /usr/data/pellcorp-overrides/guppyscreen.json
            fi
        done
        if [ -f /usr/data/pellcorp-overrides/guppyscreen.json ]; then
            echo "INFO: Saving overrides to /usr/data/pellcorp-overrides/guppyscreen.json"
            sync
        fi
    else
        echo "INFO: Overrides not supported for $file"
    fi
fi

if [ "$update_guppyscreen" = "true" ]; then
    target=main
    if [ -n "$1" ]; then
      target=$1
    fi
    curl -L "https://github.com/pellcorp/guppyscreen/releases/download/$target/guppyscreen.tar.gz" -o /usr/data/guppyscreen.tar.gz || exit $?
    tar xf /usr/data/guppyscreen.tar.gz -C /usr/data/ || exit $?
    rm /usr/data/guppyscreen.tar.gz
fi

if [ "$apply_overrides" = "true" ] && [ -f /usr/data/pellcorp-overrides/guppyscreen.json ]; then
    command=""
    for entry in display_brightness invert_z_icon display_sleep_sec theme; do
      value=$(cat /usr/data/pellcorp-overrides/guppyscreen.json | grep "${entry}=" | awk -F '=' '{print $2}')
      if [ -n "$value" ]; then
          if [ -n "$command" ]; then
              command="$command | "
          fi
          if [ "$entry" = "theme" ]; then
              command="${command}.${entry} = \"$value\""
          else
              command="${command}.${entry} = $value"
          fi
      fi
    done

    if [ -n "$command" ]; then
        echo "Applying overrides /usr/data/guppyscreen/guppyscreen.json ..."
        jq "$command" /usr/data/guppyscreen/guppyscreen.json > /usr/data/guppyscreen/guppyscreen.json.$$
        mv /usr/data/guppyscreen/guppyscreen.json.$$ /usr/data/guppyscreen/guppyscreen.json
    fi
fi

if [ "$update_guppyscreen" = "true" ]; then
    /etc/init.d/S99guppyscreen restart
fi
