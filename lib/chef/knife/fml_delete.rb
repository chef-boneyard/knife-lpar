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
require 'chef/knife/fml_base'

class Chef
  class Knife
    class FmlDelete < Knife
      include Knife::FmlBase

      deps do
        require 'io/console'
        require 'net/ssh'
      end

      banner "knife fml delete SERVER [options]"

      option :name,
        :short => "-n NAME",
        :long => "--name",
        :description => "LPAR Name",
        :required => true

      option :virtual_server,
        :short => "-v SERVER",
        :long => "--virtual-server",
        :description => "Virtual Server Name",
        :required => true

      option :vios,
        :long => "--vios NAME",
        :description => "Virtual I/O Server LPAR Name",
        :required => true

      #
      # Run the plugin
      #
      def run
        read_and_validate_params
        #TODO - make this more non-hardwired
#        @password = get_password
        delete_lpar
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
      end

      def delete_lpar
        Net::SSH.start(@name_args[0], 'hscroot', :password => '123Opscode!') do |ssh|
        # Net::SSH.start(@name_args[0], 'hscroot', :password => @password) do |ssh|
          # some background checks

          # check for existing lpar with name
          ui.info "Verifying #{config[:name]} exists"
          command = "lssyscfg -m #{config[:virtual_server]} -F name -r lpar --filter \"lpar_names=#{config[:name]}\""
          output = run_remote_command(ssh, command)
          # weird hacky crap!
          unless output.eql? config[:name]
            ui.error output
            Kernel.exit(1)
          end

          # Check to see if it's running
          ui.info "Verifying #{config[:name]} is not running"
          command = "lssyscfg -m #{config[:virtual_server]} -F state -r lpar --filter \"lpar_names=#{config[:name]}\""
          output = run_remote_command(ssh, command)
          # weird hacky crap!
          unless output.eql? "Not Activated"
            ui.error output
            Kernel.exit(1)
          end

          # first let's find the host mapping
          ui.info "Searching for host mapping"
          command = "lssyscfg -m #{config[:virtual_server]} --filter \"lpar_names=#{config[:name]}\" -F lpar_id -r lpar"
          output = run_remote_command(ssh, command)
          # and of course it doesn't match, 0 based vs 1 based counting
          vhost = output.to_i - 1
          vhost_name = "vhost#{vhost.to_s}"
          print_with_output("Found host id of #{output} - mapping to #{vhost_name}", nil)

          # mapping for the drive
          ui.info "Searching for vscsi mapping"
          command = "lssyscfg -m #{config[:virtual_server]} -r prof --filter \"lpar_names=#{config[:name]}\" -F virtual_scsi_adapters"
          output = run_remote_command(ssh, command)
          vscsi_id = output.match('.*\/.*\/.*\/.*\/(.*)\/.*')[1]
          print_with_output("Found vscsi mapping #{vscsi_id}", output)

          # find the mapping for the vopt
          ui.info "Searching for vtopt mapping"
          command = "viosvrcmd -m #{config[:virtual_server]} -p #{config[:vios]} -c \"lsmap -vadapter #{vhost_name} -type file_opt -field vtd -fmt \\\":\\\"\""
          vtopt_id = run_remote_command(ssh, command)
          print_with_output("Found vtopt mapping #{vtopt_id}", output)

          # find lv mapping
          ui.info "Searching for logical volume mapping"
          command = "viosvrcmd -m #{config[:virtual_server]} -p #{config[:vios]} -c \"lsmap -vadapter #{vhost_name} -type lv -field vtd -fmt \\\":\\\"\""
          lv_id = run_remote_command(ssh, command)
          print_with_output("Found lv mapping #{lv_id}", output)

          # find lv backing device
          ui.info "Searching for lv backing device"
          command = "viosvrcmd -m #{config[:virtual_server]} -p #{config[:vios]} -c \"lsmap -vadapter #{vhost_name} -type lv -field backing -fmt \\\":\\\"\""
          backing_device = run_remote_command(ssh, command)
          print_with_output("Found device #{backing_device}")

          # now delete the file backed optical drive mapping
          ui.info "Removing #{vtopt_id}"
          command = "viosvrcmd -m #{config[:virtual_server]} -p #{config[:vios]} -c \"rmvdev -vtd #{vtopt_id}\""
          output = run_remote_command(ssh, command)
          print_with_output("#{vtopt_id} Removed", output)

          # now delete the vtscsi device
          ui.info "Removing vscsi #{lv_id}"
          command = "viosvrcmd -m #{config[:virtual_server]} -p #{config[:vios]} -c \"rmvdev -vtd #{lv_id}\""
          output = run_remote_command(ssh, command)
          print_with_output("#{lv_id} Removed", output)

          # now delete the logical volume
          ui.info "Removing lv #{backing_device}"
          command = "viosvrcmd -m #{config[:virtual_server]} -p #{config[:vios]} -c \"rmlv -f #{backing_device}\""
          output = run_remote_command(ssh, command)
          print_with_output("#{backing_device} Removed", output)

          # now that we know the id, let's remove it from the virtual io server
          ui.info "Removing vtscsi mapping from vios"
          command = "chhwres -r virtualio -m #{config[:virtual_server]} -o r -p #{config[:vios]} --rsubtype scsi -s #{vscsi_id}"
          output = run_remote_command(ssh, command)
          print_with_output("Mapping Removed", output)

          # save the virtual io server profile
          ui.info "Saving updated vios profile on #{config[:vios]}"
          command = "mksyscfg -r prof -m #{config[:virtual_server]} -o save -p #{config[:vios]} -n `lssyscfg -r lpar -m #{config[:virtual_server]} --filter \"lpar_names=#{config[:vios]}\" -F curr_profile` --force"
          output = run_remote_command(ssh, command)
          print_with_output("Profile Saved", output)

          # now remove the lpar completely
          ui.info "Removing #{config[:name]} completely"
          command = "rmsyscfg -r lpar -m #{config[:virtual_server]} -n #{config[:name]}"
          output = run_remote_command(ssh, command)
          print_with_output("#{config[:name]} Terminated", output)
        end
      end
    end
  end
end
