# Run test

## How to run ansible on ubuntu docker images 
Run ansible script on ubuntu dockers
```
cd test_docker
# Ubuntu latest LTS
./run.sh
# On many ubuntu latest versions
./run.sh all
# When dockers are already built
./run.sh all skip_build
```

## How to kill all ubuntu dockers
docker ps --filter "name=^ubuntu" -q | xargs -r docker kill

