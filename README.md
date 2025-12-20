# Kiosk

Tracks Drinks, Orders, Clients and Monthly Reports, Settlements and Payments.

## Docker


```
docker build --platform linux/amd64 -t kiosk .
docker image tag grekkokiosk-rails8-rails-app diskstation.local:5005/kiosk
docker image push diskstation.local:5005/kiosk
``
