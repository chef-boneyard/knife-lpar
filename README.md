# Knife Lpar

This is the official Chef plugin for managing AIX lightweight partitions (LPAR).
This plugin gives knife the ability to initialize and start LPARs.

For more information about LPARs and terminology, see the following:
http://www.redbooks.ibm.com/abstracts/sg247491.html?Open

# Installation

## Build Locally
If you would like to build the gem from source locally, please clone this
repository on to your local machine and build the gem locally.
    $ bundle install
    $ bundle exec gem install

## Subcommands
This plugin provides the following Knife subcommands. Specific command options
can be found by invoking the subcommand with a `--help` flag.

# Subcommands

## knife lpar create HMC (options)
Creates a new LPAR based on defaults found below. Creates a 50GB backing device (vscsi)
with the same name as the LPAR. This is currently not configurable. Once it completes
successfully, the LPAR is booted into SMS mode to allow for any extra manual configuration
and OS installation.

*Required*
  * `HMC`:
    The name or IP of the Hardware Management Console (example: `hmc01.myurl.com`)
  * `--name`:
    The friendly name of the LPAR (example: `lpar01`)
  * `--vios`:
    The name of the Virtual I/O Server Partition that provides I/O services for the LPARs on the Virtual Server (example: `vios01`)
  * `--virtual-server`:
    The name of the Physical Virtual Server that all of the Partitions are running on (example: `aixvirt01`)
  * `--disk-name`:
    The name of the virtual ISO that has been previously loaded into your Virtual Server's Virtual Media Library to install (example: `AIX6_Disk01`)

*Optional*

  * `--profile`:
    The name of the profile to be used (if not specified, defaults to `--name`)
  * `--min-mem`:
    Minimum Memory in mb (default 1024)
  * `--desired-mem`:
    Desired Memory in mb (default 4096)
  * `--max-mem`:
    Max Memory in mb (default 16384)
  * `--min-procs`:
    Minimum number of allocated physical processors (default 1)
  * `--desired-procs`:
    Desired number of allocated physical processors (default 2)
  * `--max-procs`:
    Max number of allocated physical processors (default 4)
  * `--min-proc_units`:
    Minimum number of processor units (default 1)
  * `--desired-proc_units`:
    Desired number of processor units (default 2)
  * `--max-proc_units`:
    Max number of processor units (default 4)


## knife lpar delete HMC (options)
Removes a specific LPAR from a virtual server and removes any backing devices,
logical volumes, virtual optical devices, networking devices, device VIOS mappings,
and finally the LPAR itself.

This requires the LPAR to be powered off.

*Required*
  * `HMC`:
    The name or IP of the Hardware Management Console (example: `hmc01.myurl.com`)
  * `--name`:
    The friendly name of the LPAR (example: `lpar01`)
  * `--vios`:
    The name of the Virtual I/O Server Partition that provides I/O services for the LPARs on the Virtual Server (example: `vios01`)
  * `--virtual-server`:
    The name of the Physical Virtual Server that all of the Partitions are running on (example: `aixvirt01`)

## Contributing
Please read [CONTRIBUTING.md](CONTRIBUTING.md)

## License
Full License: [here](LICENSE)

Knife-Lpar - a Knife plugin for LPARs

Author:: Scott Hain (<shain@getchef.com>)  

Copyright:: Copyright (c) 2014 Chef Software, Inc.  
License:: Apache License, Version 2.0

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
