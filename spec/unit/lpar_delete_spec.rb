#
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

require "spec_helper"
require "chef/knife/lpar_delete.rb"

describe Chef::Knife::LparDelete do

  subject(:knife) do
    Chef::Knife::LparDelete.new(argv).tap do |c|
      allow(c).to receive(:output).and_return(true)
      c.parse_options(argv)
      c.merge_configs
    end
  end

  describe "#run" do
    context "by default" do
      let(:argv) { %w{ delete serverurl -n fakename --vios fakevios --virtual-server fakevirt } }

      it "parses argv, gets password, and deletes lpar" do
        expect(knife).to receive(:read_and_validate_params).and_call_original
        expect(knife).to receive(:get_password)
        expect(knife).to receive(:delete_lpar)
        knife.run
      end
    end
  end

  describe "#read_and_validate_params" do
    context "when argv is empty" do
      let(:argv) { [] }

      it "prints usage and exits" do
        expect(knife).to receive(:read_and_validate_params).and_call_original
        expect(knife).to receive(:show_usage)
        expect { knife.run }.to raise_error(SystemExit)
      end
    end

    context "when the name parameter is missing" do
      let(:argv) { %w{ delete serverurl --vios fakevios --virtual-server fakevirt } }

      it "prints usage and exits" do
        expect(knife).to receive(:read_and_validate_params).and_call_original
        expect(knife).to receive(:show_usage)
        expect { knife.run }.to raise_error(SystemExit)
      end
    end

    context "when the vios parameter is missing" do
      let(:argv) { %w{ delete serverurl -n fakename --virtual-server fakevirt } }

      it "prints usage and exits" do
        expect(knife).to receive(:read_and_validate_params).and_call_original
        expect(knife).to receive(:show_usage)
        expect { knife.run }.to raise_error(SystemExit)
      end
    end

    context "when the virtual-server parameter is missing" do
      let(:argv) { %w{ delete serverurl -n fakename --vios fakevios } }

      it "prints usage and exits" do
        expect(knife).to receive(:read_and_validate_params).and_call_original
        expect(knife).to receive(:show_usage)
        expect { knife.run }.to raise_error(SystemExit)
      end
    end
  end

  describe "#delete_lpar" do
    before(:each) do
      Chef::Knife::LparDelete.load_deps
      @session = double(Net::SSH)
      allow(Net::SSH).to receive(:start).with("serverurl", "hscroot", :password => "testpass").and_yield(@session)
    end

    context "when lpar does not exist" do
      let(:argv) { %w{ delete serverurl -n fakename --vios fakevios --virtual-server fakevirt } }

      it "returns with an error since the lpar does not exist" do
        expect(knife).to receive(:read_and_validate_params).and_call_original
        expect(knife).to receive(:get_password).and_return("testpass")
        expect(knife).to receive(:delete_lpar).and_call_original

        expect(knife).to receive(:run_remote_command).with(@session, "lssyscfg -m fakevirt -F name -r lpar --filter \"lpar_names=fakename\"").and_return(nil)
        expect(knife.ui).to receive(:fatal)
        expect { knife.run }.to raise_error(SystemExit)
      end

      it "returns with an error since the lpar exists but is not activated/running" do
        expect(knife).to receive(:read_and_validate_params).and_call_original
        expect(knife).to receive(:get_password).and_return("testpass")
        expect(knife).to receive(:delete_lpar).and_call_original

        expect(knife).to receive(:run_remote_command).with(@session, "lssyscfg -m fakevirt -F name -r lpar --filter \"lpar_names=fakename\"").and_return("fakename")
        expect(knife).to receive(:run_remote_command).with(@session, "lssyscfg -m fakevirt -F state -r lpar --filter \"lpar_names=fakename\"").and_return("Running")
        expect(knife.ui).to receive(:fatal)
        expect { knife.run }.to raise_error(SystemExit)
      end

      it "does things" do
        expect(knife).to receive(:read_and_validate_params).and_call_original
        expect(knife).to receive(:get_password).and_return("testpass")
        expect(knife).to receive(:delete_lpar).and_call_original

        expect(knife).to receive(:run_remote_command).with(@session, "lssyscfg -m fakevirt -F name -r lpar --filter \"lpar_names=fakename\"").and_return("fakename")
        expect(knife).to receive(:run_remote_command).with(@session, "lssyscfg -m fakevirt -F state -r lpar --filter \"lpar_names=fakename\"").and_return("Not Activated")
        expect(knife).to receive(:run_remote_command).with(@session, "lssyscfg -m fakevirt --filter \"lpar_names=fakename\" -F lpar_id -r lpar").and_return(8)
        expect(knife).to receive(:run_remote_command).with(@session, "lssyscfg -m fakevirt -r prof --filter \"lpar_names=fakename\" -F virtual_scsi_adapters").and_return("2/client/2/fakevirt/106/1")
        expect(knife).to receive(:run_remote_command).with(@session, "viosvrcmd -m fakevirt -p fakevios -c \"lsmap -vadapter vhost7 -type file_opt -field vtd -fmt \\\":\\\"\"").and_return("vtopt4")
        expect(knife).to receive(:run_remote_command).with(@session, "viosvrcmd -m fakevirt -p fakevios -c \"lsmap -vadapter vhost7 -type lv -field vtd -fmt \\\":\\\"\"").and_return("vtscsi3")
        expect(knife).to receive(:run_remote_command).with(@session, "viosvrcmd -m fakevirt -p fakevios -c \"lsmap -vadapter vhost7 -type lv -field backing -fmt \\\":\\\"\"").and_return("backingdevice")
        expect(knife).to receive(:run_remote_command).with(@session, "viosvrcmd -m fakevirt -p fakevios -c \"rmvdev -vtd vtopt4\"")
        expect(knife).to receive(:run_remote_command).with(@session, "viosvrcmd -m fakevirt -p fakevios -c \"rmvdev -vtd vtscsi3\"")
        expect(knife).to receive(:run_remote_command).with(@session, "viosvrcmd -m fakevirt -p fakevios -c \"rmlv -f backingdevice\"")
        expect(knife).to receive(:run_remote_command).with(@session, "chhwres -r virtualio -m fakevirt -o r -p fakevios --rsubtype scsi -s 106")
        expect(knife).to receive(:run_remote_command).with(@session, "mksyscfg -r prof -m fakevirt -o save -p fakevios -n `lssyscfg -r lpar -m fakevirt --filter \"lpar_names=fakevios\" -F curr_profile` --force")
        expect(knife).to receive(:run_remote_command).with(@session, "rmsyscfg -r lpar -m fakevirt -n fakename")

        knife.run
      end
    end
  end
end
