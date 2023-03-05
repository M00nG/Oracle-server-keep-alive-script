# Oracle-server-keep-alive-script

## Oracle Server Keep Alive Script


All resources are dynamically occupied and adjusted in real time to avoid the server having any other resources that have exceeded the limit and still occupy resources.


Adaptation system: temporarily verified in Ubuntu, Debian without problems, other mainstream systems should also be no problem


Optional usage: CPU, memory, bandwidth


After installation, wait 5 minutes to see the occupancy (CPU occupancy initial pressure parameter is very low, not enough time to see the load), if more than 10 minutes no occupancy, there is a problem, please uninstall the script feedback problem


~~ because the update has a delay need to wait for the CDN to load the latest script, be sure to use the latest script to avoid some historical bugs are not fixed ~~


To avoid GitHub's CDN jerking off and not loading new content, all new updates have been made using the [Gitlab repository](https://gitlab.com/spiritysdx/Oracle-server-keep-alive-script), and this repository is only for archival purposes

Please note the current update date of the script: 2023.02.22.17.53


### Development is finished, testing, please give feedback in issues


Option 1 install, option 2 uninstall, option 3 exit script


Installation process brainless carriage return then all optional occupancy are occupied, do not need what occupancy input ```n ``` and then carriage return


Finally, you will be asked whether you need to customize the parameters of bandwidth occupation, at this time the default option is ```n```, enter to use the default configuration, enter ```y``` and enter again, you need to follow the prompts to customize the parameters

```
curl -L https://gitlab.com/spiritysdx/Oracle-server-keep-alive-script/-/raw/main/oalive.sh -o oalive.sh && chmod +x oalive.sh && bash oalive.sh
```

or

```
bash oalive.sh
```

or

```
bash <(wget -qO- --no-check-certificate https://gitlab.com/spiritysdx/Oracle-server-keep-alive-script/-/raw/main/oalive.sh)
```

### Description

- CPU occupancy is freely selectable between DD simulation occupancy mode and scientific computing mode, and the set occupancy range is 15~25%.
- CPU usage is dynamic, it is detected every few seconds, the calculation task is dynamically adjusted, the detection interval is also dynamically adjusted
- CPU usage is doubly insured, not only dynamically adjusted, but also the maximum usage is set in the daemon
- CPU occupancy default 25% maximum (core ✖12% if set below 25%, above 25% in accordance with the calculated ratio)
- CPU occupancy specially handled the case of multi-core (2, 3, 4 cores) to ensure that the CPU history occupancy is sufficient
- Memory occupancy set to occupy 20% of the total memory, occupy 300 seconds to rest 300 seconds
- Memory occupancy every 300 seconds to detect once, dynamically adjust the size of the increase in occupancy, if your memory is greater than 20% will not increase occupancy
- Bandwidth occupancy every 45 minutes to download 1G ~ 10G size files to occupy, only download not save, the download process will not occupy the hard disk
- Bandwidth occupancy dynamically adjusts the actual download bandwidth/rate, limiting the download length to a maximum of 10 minutes, testing the maximum available bandwidth before each download real-time adjustment to 20% bandwidth download
- Use daemon and boot-up service to ensure the continuous and effective occupation of tasks during the occupation process
- Optional one-click uninstallation of all occupied services, the uninstallation will uninstall all scripts and services, including tasks, daemons and boot settings
- New one-click check for update, update is limited to script update, please reset the occupied services after update
- Add uniqueness detection for all process execution to avoid duplicate runs

### Content to be developed

Use docker to integrate all scripts for ease of use

### Friendly links

VPS fusion monster measurement script

https://github.com/spiritLHLS/ecs

## Stargazers over time

[![Stargazers over time](https://starchart.cc/spiritLHLS/Oracle-server-keep-alive-script.svg)](https://starchart.cc/spiritLHLS/Oracle-server-keep-alive-script)

### SEO Keywords

Oracle guaranteed live, Oracle OCI guaranteed live, Oracle resource hogging, Oracle free server, Oracle server idle use essential.

Resources are wasted periodically and can be used for Oracle Oracle Live Assurance.

Script made to cope with Oracle's latest recycling mechanism.


