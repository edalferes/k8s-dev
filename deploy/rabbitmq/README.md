# Rabbitmq

## Test connection and performance

```
docker run -it --rm pivotalrabbitmq/perf-test:latest \
    -x 1 -y 2 -u "throughput-test-1" -a --id "test 1" \
    --uri amqp://admin:rabbitmq@<MYIP>
```