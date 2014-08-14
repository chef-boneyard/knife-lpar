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
require 'chef/mixin/shell_out'

class Chef
  class Knife
    class FmlDelete < Knife
      include Chef::Mixin::ShellOut

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
        @password = get_password
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

      # quick and dirty password prompt, because I'm cool like that
      def get_password
        print "Enter root password for HMC: "
        STDIN.noecho(&:gets).chomp
      end

      def delete_lpar
        Net::SSH.start(@name_args[0], 'hscroot', :password => @password) do |ssh|
          # some background checks
          # check for existing lpar with name
          command = "lssyscfg -m #{config[:virtual_server]} -F name -r lpar --filter \"lpar_names=#{config[:name]}\""
          output = run_remote_command(ssh, command)
          # weird hacky crap!
          unless output.eql? config[:name]
            puts output
            Kernel.exit(1)
          end

          # first let's find the host mapping
          command = "lssyscfg -m #{config[:virtual_server]} --filter \"lpar_names=#{config[:name]}\" -F lpar_id -r lpar"
          output = run_remote_command(ssh, command)
          # and of course it doesn't match, 0 based vs 1 based counting
          vhost = output.to_i - 1
          vhost_name = "vhost#{vhost.to_s}"

          # mapping for the drive
          command = "lssyscfg -m #{config[:virtual_server]} -r prof --filter \"lpar_names=#{config[:name]}\" -F virtual_scsi_adapters"
          output = run_remote_command(ssh, command)
          vscsi_id = output.match('.*\/.*\/.*\/.*\/(.*)\/.*')[1]

          # now that we know the id, let's remove it from the virtual io server
          command = "chhwres -r virtualio -m #{config[:virtual_server]} -o r -p #{config[:vios]} --rsubtype scsi -s #{vscsi_id} -a \"adapter_type=server, remote_lpar_name=#{config[:name]}, remote_slot_num=2\""
          output = run_remote_command(ssh, command)
          unless output.nil?
            puts "command: " + command
            puts output.to_s
          end

          # find the mapping for the vopt
          command = "viosvrcmd -m #{config[:virtual_server]} -p #{config[:vios]} -c \"lsmap -vadapter #{vhost_name} -type file_opt -field vtd -fmt \\\":\\\"\""
          vopt_id = run_remote_command(ssh, command)

          # now delete the file backed optical drive mapping
          command = "viosvrcmd -m #{config[:virtual_server]} -p #{config[:vios]} -c \"rmvdev -vtd #{vopt_id}\""
          output = run_remote_command(ssh, command)
          unless output.nil?
            puts "command: " + command
            puts output.to_s
          end

          # save the virtual io server profile
          command = "mksyscfg -r prof -m #{config[:virtual_server]} -o save -p #{config[:vios]} -n `lssyscfg -r lpar -m #{config[:virtual_server]} --filter \"lpar_names=#{config[:vios]}\" -F curr_profile` --force"
          output = run_remote_command(ssh, command)
          unless output.nil?
            puts "command: " + command
            puts output.to_s
          end

          # now remove the lpar completely
          command = "rmsyscfg -r lpar -m #{config[:virtual_server]} -n #{config[:name]}"
          output = run_remote_command(ssh, command)
          unless output.nil?
            puts "command: " + command
            puts output.to_s
          end

          # TODO actually finish delete

        end
      end

      def run_remote_command(ssh, command)
        return_val = nil
        ssh.exec! command do |ch, stream, data|
          if stream == :stdout
            return_val = data.chomp
          else
            # some exception is in order I think
            puts "SOMETHING ASPLODE!!!!"
            puts data.to_s
            Kernel.exit(1)
          end
        end
        return return_val
      end
    end
  end
end
