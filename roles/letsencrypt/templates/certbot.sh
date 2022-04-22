/usr/local/bin/certbot certonly \
  --non-interactive \
  --agree-tos \
  --email {{ certbot_email }} \
  --dns-cloudflare \
  --dns-cloudflare-credentials /home/{{ inventory_hostname }}/scripts/cloudflare.ini \
  --dns-cloudflare-propagation-seconds 300 \
  -d "{{ domain_name }}" \
  -d "www.{{ domain_name }}"
