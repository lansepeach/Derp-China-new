#!/usr/bin/env sh

#Start tailscaled and connect to tailnet
/usr/sbin/tailscaled --state=/var/lib/tailscale/tailscaled.state >> /dev/stdout &
/usr/bin/tailscale up --accept-routes=true --accept-dns=true --auth-key $TAILSCALE_AUTH_KEY >> /dev/stdout &

#Check for and or create certs directory
if [[ ! -d "/root/derper/$TAILSCALE_DERP_HOSTNAME" ]]
then
    mkdir -p /root/derper/$TAILSCALE_DERP_HOSTNAME
fi

#Start Tailscale derp server
/root/go/bin/derper --hostname=$TAILSCALE_DERP_HOSTNAME --a=$TAILSCALE_DERP_ADDR --http-port=$TAILSCALE_DERP_HTTP_PORT --stun-port=$TAILSCALE_DERP_STUN_PORT --verify-clients=$TAILSCALE_DERP_VERIFY_CLIENTS
