#!/usr/bin/env bash

CACHE=${XDG_CONFIG_CACHE:-~/.cache}/bloatless-twitch
AUTH_URL=https://antiscuff.com/oauth

_open() { open $@ || xdg-open $@; }

USER_CACHE=$CACHE/username
if [[ ! -f $USER_CACHE ]]; then
  echo No cached twitch username found
  read -rp "User name: " user
  echo $user > $USER_CACHE
fi

TOKEN_CACHE=$CACHE/token
if [[ ! -f $TOKEN_CACHE ]]; then
  echo No cached twitch oath token found

  echo "Generate your OAuth token here: $AUTH_URL"
  read -rp "Open in your web browser? [y|N]" resp
  [[ ''${resp,,} == y ]] && _open $AUTH_URL

  read -rp "Paste (starting with 'oauth:'): " token
  mkdir -p $CACHE
  echo $token > $TOKEN_CACHE 
fi

CHANNEL_NAME=$1
CHANNEL_CACHE=$CACHE/channels

# if no channel name argument is given, prompt the user for input
if [[ -z "$CHANNEL_NAME" ]]; then
  # return query + potentional matched cached channel name
  query=$(echo "$(cat $CHANNEL_CACHE)" | fzf --no-sort --print-query | xargs)
  channel=;

  len=$(echo $query | wc -w)

  # if a cached channel name was matched
  if [[ $len -eq 2 ]]; then
    channel=$(echo $query | cut -d ' ' -f 2)
    
  # if query contains unique channel name
  elif [[ $len -eq 1 ]]; then
    channel=$query

  else
    echo Invalid channel name
    exit 1
  fi

  # add channel name to cache if it doesn't already exist
  if ! grep -q $channel "$CHANNEL_CACHE"; then
    echo "$channel" >> $CHANNEL_CACHE
  fi

  CHANNEL_NAME=$channel
fi

STREAM_URL="https://twitch.tv/$CHANNEL_NAME"
TOKEN=$(cat $TOKEN_CACHE)
USER=$(cat $USER_CACHE)

write_twitch_tui_config() 
{
user=$1
token=$2
file=$3
tmp=$(mktemp)
curl -s https://raw.githubusercontent.com/Xithrius/twitch-tui/main/default-config.toml -o $tmp
sed -i '1,14d' $tmp
cat <<EOF > $tmp
[twitch]
server = "irc.chat.twitch.tv"
username = "$user"
channel = "$user"
token = "$token"
EOF
cat $tmp > $file
}

# twitch-tui only support emotes in kitty
# if you don't want extra emoji bloat you can disable in ~/.config/twt
if [[ -f "$(which kitty)" ]] && [[ -f "$(which twt)" ]]; then
  echo Opening chat in new kitty window

  twt_config=${XDG_CONFIG_HOME:-~/.config}/twt
  if [[ ! -d "$twt_config" ]]; then
    echo Generting twitch-tui configuration

    mkdir -p $twt_config
    write_twitch_tui_config $USER $TOKEN $twt_config/config.toml
  fi

  kitty twt -u --channel $CHANNEL_NAME --first-state normal &
fi

# you can enable this flag to pause the player while ads are playing
# only enable this if you're not authenticated with twitch or using a proxy
# --twitch-disable-ads

streamlink $STREAM_URL \
  --twitch-low-latency \
  --twitch-api-header="Authorization=$TOKEN" \
  --twitch-proxy-playlist=https://lb-eu.cdn-perfprod.com \
  --player mpv \
  best
