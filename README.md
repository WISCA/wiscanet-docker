# WiscaNET in Docker

## Getting Started

- Run `sudo docker build wiscanet-docker` or `sudo podman build wiscanet-docker` on this directory (JBH typically uses `sudo podman build --rm -t wisca/wiscanet wiscanet-docker`)
- This container expects you have the ability to run `systemd` inside a docker container, as it handles launching sshd and provides a *proper* (i.e. not bash or some other pale alternative) PID 1 for the container
  - This can be achieved out of the box by using `podman` or with proper configuration of `docker`
     - For `podman` the only magic is `sudo setsebool -P container_manage_cgroup true`
     - `docker` the magic can be found with a google search, all test systems have used `podman`
- There is an expectation of rootfull networking (where each container gets its own network interface [and therefore IP] within a network namespace)

## Sharing files with containers and interacting

- A folder `~/wdemo` is bound into the current users (aka your) home directory from the cnode.
- `sudo podman volume create --opt type=none --opt o=bind --opt device=${YOUR_PATH_HERE}/wdemo cnode_wdemo`
- don't forget to `mkdir -p ${YOUR_PATH_HERE}/wdemo` before running `./launch_wiscanet.sh`
- This volume may need to be recreated with new versions of the container (aka software, so that the appropriate files get copied in on load )
- The scripts do this for you, so remember, `wdemo` is cleared and recreated on every start of the launch script

## Licensing

- Place a `cnode.lic`, `enode0.lic`, `enode1.lic` file containg a valid matlab license (can point to license server) in a folder called `licenses` next to the `wiscanet-docker` folder.
- The `launch_wiscanet.sh` script looks for this folder at `../licenses/` from wherever it is run

## B200/B210 Network

- To launch a small WISCANet network with 2 B210's attached run `./launch_wiscanet_b210.sh`
  - WISCANet (due to prior design decisions) likes to have its own IP for each node, so rootfull networking is required and expected for this script as well (why it launches with sudo)
  - This script assumes you have two B200/B210's attached to the host computer over USB, it doesn't actually check for them, so it will go ahead and launch containers anyways
  - When running the cnode, no SSH keys are currently copied, so all password prompts can be answered with the password: `wisca` (Configured by the Dockerfile)
- Once the network is launched, ssh into each of the nodes (cnode, enode0, enode1) and launch
  - cnode: `cd wdemo/run/cnode/bin && ./cnode`
  - enode{0,1}: `cd wdemo/run/enode/bin && ./enode`

## X300/X310 Network

- To launch a small WISCANet network with 2 X310s attached, run `./launch_wiscanet_x310.sh`
  - As in the B210 network, rootfull networking is required, so it launches with sudo
  - In the script, configure the RADIO0 and RADIO1 variables with appropriate device strings from the ettus documentation
    - found here: https://files.ettus.com/manual/page_identification.html
- As above, once the network is launched, ssh into each of the nodes (cnode, enode0, enode1) and launch
  - cnode: `cd wdemo/run/cnode/bin && ./cnode`
  - enode{0,1}: `cd wdemo/run/enode/bin && ./enode`

## MATLAB

- To add MATLAB to the container, place a complete Linux MATLAB installation at `matlab-install/MATLAB`.  Do not place it in any versioned folder.  The Dockerfile and other components are written without versioning, to avoid extra changes when upgrading, or otherwise changing MATLAB versions.

## Container Networking Convenience

- You may consider adding this snippet to your `/etc/cni/net.d/87-podman-bridge.conflist` file to enable DNS for the default network, substituting `example.com` for your local domain name

    ```
    {
    "type": "dnsname",
    "domainName": "example.com"
    }
  ```

### References

- Uses UHD Dockerfile from Ettus Research
  - https://github.com/EttusResearch/ettus-docker
- Uses MATLAB (mathworks.com)
- WISCANET 2017 paper

## Legal
Copyright 2020, WISCANET Contributors

Refer to `wiscanet_source` for full licensing information
