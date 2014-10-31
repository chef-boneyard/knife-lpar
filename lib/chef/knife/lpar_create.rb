#
# Copyright:: Copyright (c) 2014 Chef Software Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'chef/knife'
require 'chef/knife/lpar_base'

class Chef
  class Knife
    class LparCreate < Knife
      include Chef::Knife::LparBase

      banner "knife lpar create HMC [options]"

      option :name,
        :short => "-n NAME",
        :long => "--name",
        :description => "LPAR Name"

      option :profile,
        :short => "-p PROFILE",
        :long => "--profile",
        :description => "LPAR Profile Name"

      option :virtual_server,
        :short => "-v SERVER",
        :long => "--virtual-server",
        :description => "Virtual Server Name"

      option :vios,
        :long => "--vios NAME",
        :description => "Virtual I/O Server LPAR Name"

      option :min_mem,
        :long => "--min-mem MEM",
        :description => "Minimum Memory in mb (default 1024)",
        :default => 1024

      option :desired_mem,
        :long => "--desired-mem MEM",
        :description => "Desired Memory in mb (default 4096)",
        :default => 4096

      option :max_mem,
        :long => "--max-mem MEM",
        :description => "Max Memory in mb (default 16384)",
        :default => 16384

      option :min_procs,
        :long => "--min-procs PROCS",
        :description => "Minimum number of Processors (default 1)",
        :default => 1

      option :desired_procs,
        :long => "--desired-procs PROCS",
        :description => "Desired number of Processors (default 2)",
        :default => 2

      option :max_procs,
        :long => "--max-procs PROCS",
        :description => "Max number of Processors (default 4)",
        :default => 4

      option :min_proc_units,
        :long => "--min-proc_units UNITS",
        :description => "Minimum number of processor units (default 1)",
        :default => 1

      option :desired_proc_units,
        :long => "--desired-proc_units UNITS",
        :description => "Desired number of processor units (default 2)",
        :default => 2

      option :max_proc_units,
        :long => "--max-proc_units UNITS",
        :description => "Max number of processor units (default 4)",
        :default => 4

      option :help,
        :long => "--help",
        :description => "Prints this menu"

      option :disk_name,
        :long => "--disk-name DISK",
        :description => "Disk image name (e.g. AIX_6_1_vol1)"

      #
      # Run the plugin
      #
      def run
        read_and_validate_params
        @password = get_password
        create_lpar
      end

      #
      # Reads the input parameters and validates them.
      # Will exit if it encounters an error
      #
      def read_and_validate_params
        if @name_args.length < 1
          show_usage
          exit 1
        end

        if config[:name].nil? ||
            config[:vios].nil? ||
            config[:virtual_server].nil? ||
            config[:disk_name].nil?
          show_usage
          exit 1
        end

        if config[:profile].nil?
          config[:profile] = config[:name]
        end
      end

      def create_lpar
        Net::SSH.start(@name_args[0], 'hscroot', :password => @password) do |ssh|
          # some background checks
          # check for existing lpar with name
          ui.info "Searching for existing lpar with name: #{config[:name]}"
          command = "lssyscfg -m #{config[:virtual_server]} -F name -r lpar | grep #{config[:name]}"
          output = run_remote_command(ssh, command)
          unless output.nil?
            ui.fatal "An lpar already exists with the name #{config[:name]}"
            exit 1
          end
          ui.info "lpar not found, creation imminent"

          # find the last vscsi device number
          ui.info "Looking for next device number in sequence"
          command = "viosvrcmd -m #{config[:virtual_server]} -p #{config[:vios]} -c \"lsdev -type disk -virtual -field name\" | tail -1"
          last_vscsi = run_remote_command(ssh, command)
          ui.info "Found existing device - #{last_vscsi}"

          # use the vscsi number to find the actual physical ID so we can find which vios slot it's in
          ui.info "Finding vios mapping for device - #{last_vscsi}"
          command = "viosvrcmd -m #{config[:virtual_server]} -p #{config[:vios]} -c \"lsdev -dev #{last_vscsi} -field physloc -fmt \\\":\\\"\""
          last_vscsi_phy_loc = run_remote_command(ssh, command)
          prev_loc = last_vscsi_phy_loc.match('.*-C(\d+)-.*')[1]
          ui.info "Found vios mapping #{prev_loc}"
          new_virt_loc = prev_loc.to_i + 1
          ui.info "Will use new mapping #{new_virt_loc}"

          # create the new lpar
          ui.info "Creating new lpar #{config[:name]}"
          command = "mksyscfg -m #{config[:virtual_server]} -r lpar \
-i \"name=#{config[:name]}, \
profile_name=#{config[:profile]}, \
lpar_env=aixlinux, \
min_mem=#{config[:min_mem]}, \
desired_mem=#{config[:desired_mem]}, \
max_mem=#{config[:max_mem]}, \
proc_mode=shared, \
min_procs=#{config[:min_procs]}, \
desired_procs=#{config[:desired_procs]}, \
max_procs=#{config[:max_procs]}, \
min_proc_units=#{config[:min_proc_units]}, \
desired_proc_units=#{config[:desired_proc_units]}, \
max_proc_units=#{config[:max_proc_units]}, \
sharing_mode=uncap, uncap_weight=128, \
boot_mode=norm, max_virtual_slots=10, \
\\\"virtual_eth_adapters=3/0/1//0/0\\\", \
\\\"virtual_scsi_adapters=2/client//#{config[:vios]}/#{new_virt_loc}/1\\\"\""
          output = run_remote_command(ssh, command)
          ui.info "Creation Successful"

          # now we have to figure out what the hell lpar we just created
          ui.info "Finding vhost name"
          command = "lssyscfg -m #{config[:virtual_server]} --filter \"lpar_names=#{config[:name]}\" -F lpar_id -r lpar"
          output = run_remote_command(ssh, command)
          # and of course it doesn't match, 0 based vs 1 based counting
          vhost = output.to_i - 1
          vhost_name = "vhost#{vhost.to_s}"
          ui.info "#{config[:name]} is #{vhost_name}"

          # Add the virtual io server vscsi mapping
          ui.info "Mapping #{new_virt_loc} between #{config[:vios]} and #{config[:name]}"
          command = "chhwres -r virtualio -m #{config[:virtual_server]} -o a -p #{config[:vios]} --rsubtype scsi -s #{new_virt_loc} -a \"adapter_type=server, remote_lpar_name=#{config[:name]}, remote_slot_num=2\""
          output = run_remote_command(ssh, command)
          ui.info "Mapping Successful"

          # make a file backed optical drive
          ui.info "Creating virtual file backed optical device"
          command = "viosvrcmd -m #{config[:virtual_server]} -p #{config[:vios]} -c \"mkvdev -fbo -vadapter #{vhost_name}\""
          vopt_name = run_remote_command(ssh, command).split(' ')[0]
          ui.info "Created device #{vopt_name}"

          # load the iso
          ui.info "Loading disk in optical drive"
          command = "viosvrcmd -m #{config[:virtual_server]} -p #{config[:vios]} -c \"loadopt -vtd #{vopt_name} -disk #{config[:disk_name]}\""
          output = run_remote_command(ssh, command)
          ui.info "Loading Successful"

          # create logical volume
          ui.info "Creating logical volume"
          command = "viosvrcmd -m #{config[:virtual_server]} -p #{config[:vios]} -c \"mklv -lv #{config[:name]} rootvg 50G\""
          lv_name = run_remote_command(ssh, command)
          ui.info "Created logical volume #{lv_name}"

          # attach it
          ui.info "Attaching lv to lpar"
          command = "viosvrcmd -m #{config[:virtual_server]} -p #{config[:vios]} -c \"mkvdev -vdev #{config[:name]} -vadapter #{vhost_name}\""
          vtscsi_name = run_remote_command(ssh, command).split(' ')[0]
          ui.info "Attach Successful as #{vtscsi_name}"

          # save the virtual io server profile
          ui.info "Activating virtual io server profile"
          command = "mksyscfg -r prof -m #{config[:virtual_server]} -o save -p #{config[:vios]} -n `lssyscfg -r lpar -m #{config[:virtual_server]} --filter \"lpar_names=#{config[:vios]}\" -F curr_profile` --force"
          output = run_remote_command(ssh, command)
          ui.info "Activation Successful"

          # smack the lpar a bit so it knows it has new devices
          ui.info "Reload virtual io server to re-read devices"
          command = "viosvrcmd -m #{config[:virtual_server]} -p #{config[:vios]} -c \"cfgdev\""
          output = run_remote_command(ssh, command)
          ui.info "Reload Successful"

          # could start it up here, we'll see
          ui.info "Boot lpar in SMS mode"
          command = "chsysstate -r lpar -m #{config[:virtual_server]} -o on -f #{config[:profile]} -b sms -n #{config[:name]}"
          output = run_remote_command(ssh, command)
          unless output.nil?
            ui.info output.to_s
          end
          ui.info "Boot Successful"
        end
      end

    end
  end
end
