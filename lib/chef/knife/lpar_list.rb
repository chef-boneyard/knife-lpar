#
# Author:: Julian C. Dunn (<jdunn@chef.io>)
# Copyright:: Copyright (c) 2014-2016 Chef Software Inc.
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
    class LparList < Knife
      include Chef::Knife::LparBase

      banner "knife lpar list HMC [options]"

      option :virtual_server,
        :short => "-v SERVER",
        :long => "--virtual-server",
        :description => "Virtual Server Name"

      option :help,
        :long => "--help",
        :description => "Prints this menu"

      #
      # Run the plugin
      #
      def run
        read_and_validate_params
        @password = get_password
        list_lpars
      end

      private

      #
      # Reads the input parameters and validates them.
      # Will exit if it encounters an error
      #
      def read_and_validate_params
        if @name_args.length < 1
          show_usage
          exit 1
        end

        if config[:virtual_server].nil?
          show_usage
          exit 1
        end
      end

      def list_lpars
        lpar_list = [
            ui.color('LPAR ID', :bold),
            ui.color('Type', :bold),
            ui.color('Name', :bold),
            ui.color('OS Version', :bold)
        ].flatten.compact

        output_column_count = lpar_list.length

        Net::SSH.start(@name_args[0], 'hscroot', :password => @password) do |ssh|

          command = "lssyscfg -m #{config[:virtual_server]} -F lpar_id,lpar_env,name,os_version -r lpar"
          output = run_remote_command(ssh, command)
          output.each_line do |lpar|
            lpar.split(',').each do |field|
              lpar_list << field.chomp
            end
          end
          puts "\n"
          puts ui.list(lpar_list, :uneven_columns_across, output_column_count)
        end
      end
    end
  end
end
