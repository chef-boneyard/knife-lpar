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

class Chef
  class Knife
    module FmlBase

      # I hate this name but I'm not thinking of anything better right now.
      def print_with_output(message, output=nil)
        if output.nil? or output.empty?
          ui.info message
        else
          ui.info message + " - " + output
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

      # quick and dirty password prompt, because I'm cool like that
      def get_password
        print "Enter root password for HMC: "
        STDIN.noecho(&:gets).chomp
      end

    end
  end
end
