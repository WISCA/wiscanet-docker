# WiscaNET in Docker

## Getting Started

- Run `docker build wiscanet-docker` or `podman build wiscanet-docker` on this directory

- Uses UHD Dockerfile concepts from Ettus Research
  - https://github.com/EttusResearch/ettus-docker 

## B200/B210 Network

- To launch a small WISCANet network with 2 B210's attached run `./launch_wiscanet.sh`
  - WISCANet (due to prior design decisions) likes to have its own IP for each node, so rootfull networking is required and expected for this script as well (why it launches with sudo)
  - This script assumes you have two B200/B210's attached to the host computer over USB, it doesn't actually check for them, so it will go ahead and launch containers anyways
  - When running the cnode, no SSH keys are currently copied, so all password prompts can be answered with the password: `wisca` (Configured by the Dockerfile)

### Deprecated

- Currently uses Octave instead...
- Could potentially utilize MATLAB Dockerfile concepts from MathWorks
  - https://github.com/mathworks-ref-arch/matlab-dockerfile
