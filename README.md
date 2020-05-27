# WiscaNET in Docker

## Getting Started

- Run `sudo docker build wiscanet-docker` or `sudo podman build wiscanet-docker` on this directory (JBH typically uses `sudo podman build --rm -t jholtom/wiscanet wiscanet-docker`)
- This container expects you have the ability to run `systemd` inside a docker container, as it handles launching ssh and provides a *proper* (i.e. not bash or some other pale alternative) PID 1 for the container
  - This can be achieved out of the box by using `podman` or with proper configuration of `docker`
     - For `podman` the only magic is `sudo setsebool -P container_manage_cgroup true`
     - `docker` the magic can be found with a google search, all test systems have used `podman`
- There is an expectation of rootfull networking (where each container gets its own IP within a network namespace)

- Uses UHD Dockerfile concepts from Ettus Research
  - https://github.com/EttusResearch/ettus-docker 

## B200/B210 Network

- To launch a small WISCANet network with 2 B210's attached run `./launch_wiscanet.sh`
  - WISCANet (due to prior design decisions) likes to have its own IP for each node, so rootfull networking is required and expected for this script as well (why it launches with sudo)
  - This script assumes you have two B200/B210's attached to the host computer over USB, it doesn't actually check for them, so it will go ahead and launch containers anyways
  - When running the cnode, no SSH keys are currently copied, so all password prompts can be answered with the password: `wisca` (Configured by the Dockerfile)
- Once the network is launched, ssh into each of the nodes (cnode, enode0, enode1) and launch
  - cnode: `cd wdemo/run/cnode/bin && ./cnode`
  - enode{0,1}: `cd wdemo/run/enode/bin && ./enode`

### Deprecated

- Currently uses Octave instead...
- Could potentially utilize MATLAB Dockerfile concepts from MathWorks
  - https://github.com/mathworks-ref-arch/matlab-dockerfile
