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

require 'spec_helper'
require 'chef/knife/lpar_create.rb'

describe Chef::Knife::LparCreate do

  subject(:knife) do
    Chef::Knife::LparCreate.new(argv).tap do |c|
      allow(c).to receive(:output).and_return(true)
      c.parse_options(argv)
      c.merge_configs
    end
  end

  describe '#run' do

    context 'by default' do
      let(:argv) { %w[ create serverurl -n fakename --vios fakevios --virtual-server fakevirt --disk fakedisk -p fakeprof ] }

      it 'parses argv, gets password, and creates lpar' do
        expect(knife).to receive(:read_and_validate_params).and_call_original
        expect(knife).to receive(:get_password)
        expect(knife).to receive(:create_lpar)
        knife.run
      end
    end

  end

  describe '#read_and_validate_params' do

    context 'when argv is empty' do
      let(:argv) { [] }

      it 'prints usage and exits' do
        expect(knife).to receive(:read_and_validate_params).and_call_original
        expect(knife).to receive(:show_usage)
        expect { knife.run }.to raise_error(SystemExit)
      end
    end

    context 'when the name parameter is missing' do
      let(:argv) { %w[ create serverurl --vios fakevios --virtual-server fakevirt --disk fakedisk ] }

      it 'prints usage and exits' do
        expect(knife).to receive(:read_and_validate_params).and_call_original
        expect(knife).to receive(:show_usage)
        expect { knife.run }.to raise_error(SystemExit)
      end
    end

    context 'when the vios parameter is missing' do
      let(:argv) { %w[ create serverurl -n fakename --virtual-server fakevirt --disk fakedisk ] }

      it 'prints usage and exits' do
        expect(knife).to receive(:read_and_validate_params).and_call_original
        expect(knife).to receive(:show_usage)
        expect { knife.run }.to raise_error(SystemExit)
      end
    end

    context 'when the virtual-server parameter is missing' do
      let(:argv) { %w[ create serverurl -n fakename --vios fakevios --disk fakedisk ] }

      it 'prints usage and exits' do
        expect(knife).to receive(:read_and_validate_params).and_call_original
        expect(knife).to receive(:show_usage)
        expect { knife.run }.to raise_error(SystemExit)
      end
    end

    context 'when the disk parameter is missing' do
      let(:argv) { %w[ create serverurl -n fakename --vios fakevios --virtual-server fakevirt ] }

      it 'prints usage and exits' do
        expect(knife).to receive(:read_and_validate_params).and_call_original
        expect(knife).to receive(:show_usage)
        expect { knife.run }.to raise_error(SystemExit)
      end
    end

    context 'by default' do
      let(:argv) { %w[ create serverurl -n fakename --vios fakevios --virtual-server fakevirt --disk fakedisk -p fakeprof ] }

      it 'sets defaults' do
        expect(knife).to receive(:read_and_validate_params).and_call_original
        expect(knife).to receive(:get_password)
        expect(knife).to receive(:create_lpar)
        knife.run
        expect(knife.config[:profile]).to eq("fakeprof")
        expect(knife.config[:min_mem]).to eq(1024)
        expect(knife.config[:desired_mem]).to eq(4096)
        expect(knife.config[:max_mem]).to eq(16384)
        expect(knife.config[:min_procs]).to eq(1)
        expect(knife.config[:desired_procs]).to eq(2)
        expect(knife.config[:max_procs]).to eq(4)
        expect(knife.config[:min_proc_units]).to eq(1)
        expect(knife.config[:desired_proc_units]).to eq(2)
        expect(knife.config[:max_proc_units]).to eq(4)
      end
    end

    context 'without profile' do
      let(:argv) { %w[ create serverurl -n fakename --vios fakevios --virtual-server fakevirt --disk fakedisk ] }

      it 'defaults profile to name' do
        expect(knife).to receive(:read_and_validate_params).and_call_original
        expect(knife).to receive(:get_password)
        expect(knife).to receive(:create_lpar)
        knife.run
        expect(knife.config[:profile]).to eq("fakename")
      end
    end
  end

  context '#create_lpar' do
    before(:each) do
      Chef::Knife::LparCreate.load_deps
      @session = double(Net::SSH)
      allow(Net::SSH).to receive(:start).with("serverurl", "hscroot", :password => "testpass").and_yield(@session)
    end

    context 'with an existing lpar name' do
      let(:argv) { %w[ create serverurl -n fakename --vios fakevios --virtual-server fakevirt --disk fakedisk -p fakeprof] }

      it 'returns with an error since the lpar already exists' do
        expect(knife).to receive(:read_and_validate_params).and_call_original
        expect(knife).to receive(:get_password).and_return("testpass")
        expect(knife).to receive(:create_lpar).and_call_original

        expect(knife).to receive(:run_remote_command).with(@session, "lssyscfg -m fakevirt -F name -r lpar | grep fakename").and_return("fakename")
        expect(knife.ui).to receive(:fatal)
        expect { knife.run }.to raise_error(SystemExit)
      end
    end

    context 'with defaults' do
      let(:argv) { %w[ create serverurl -n fakename --vios fakevios --virtual-server fakevirt --disk fakedisk -p fakeprof] }

      it 'does things' do
        expect(knife).to receive(:read_and_validate_params).and_call_original
        expect(knife).to receive(:get_password).and_return("testpass")
        expect(knife).to receive(:create_lpar).and_call_original

        expect(knife).to receive(:run_remote_command).with(@session, "lssyscfg -m fakevirt -F name -r lpar | grep fakename").and_return(nil)
        expect(knife).to receive(:run_remote_command).with(@session, "viosvrcmd -m fakevirt -p fakevios -c \"lsdev -type disk -virtual -field name\" | tail -1").and_return("fakevscsi1")
        # this is real type of data it returns, deal with it :)
        expect(knife).to receive(:run_remote_command).with(@session, "viosvrcmd -m fakevirt -p fakevios -c \"lsdev -dev fakevscsi1 -field physloc -fmt \\\":\\\"\"").and_return("U8231.E1D.06A398T-V2-C108-L1")
        expect(knife).to receive(:run_remote_command).with(@session, "mksyscfg -m fakevirt -r lpar \
-i \"name=fakename, \
profile_name=fakeprof, \
lpar_env=aixlinux, \
min_mem=1024, \
desired_mem=4096, \
max_mem=16384, \
proc_mode=shared, \
min_procs=1, \
desired_procs=2, \
max_procs=4, \
min_proc_units=1, \
desired_proc_units=2, \
max_proc_units=4, \
sharing_mode=uncap, uncap_weight=128, \
boot_mode=norm, max_virtual_slots=10, \
\\\"virtual_eth_adapters=3/0/1//0/0\\\", \
\\\"virtual_scsi_adapters=2/client//fakevios/109/1\\\"\"")
         expect(knife).to receive(:run_remote_command).with(@session, "lssyscfg -m fakevirt --filter \"lpar_names=fakename\" -F lpar_id -r lpar").and_return("5")
         expect(knife).to receive(:run_remote_command).with(@session, "chhwres -r virtualio -m fakevirt -o a -p fakevios --rsubtype scsi -s 109 -a \"adapter_type=server, remote_lpar_name=fakename, remote_slot_num=2\"")
         expect(knife).to receive(:run_remote_command).with(@session, "viosvrcmd -m fakevirt -p fakevios -c \"mkvdev -fbo -vadapter vhost4\"").and_return("vadapter3")
         expect(knife).to receive(:run_remote_command).with(@session, "viosvrcmd -m fakevirt -p fakevios -c \"loadopt -vtd vadapter3 -disk fakedisk\"")
         expect(knife).to receive(:run_remote_command).with(@session, "viosvrcmd -m fakevirt -p fakevios -c \"mklv -lv fakename rootvg 50G\"")
         expect(knife).to receive(:run_remote_command).with(@session, "viosvrcmd -m fakevirt -p fakevios -c \"mkvdev -vdev fakename -vadapter vhost4\"").and_return("fakevtopt3 Virtual Optical Device")
         expect(knife).to receive(:run_remote_command).with(@session, "mksyscfg -r prof -m fakevirt -o save -p fakevios -n `lssyscfg -r lpar -m fakevirt --filter \"lpar_names=fakevios\" -F curr_profile` --force")
         expect(knife).to receive(:run_remote_command).with(@session, "viosvrcmd -m fakevirt -p fakevios -c \"cfgdev\"")
         expect(knife).to receive(:run_remote_command).with(@session, "chsysstate -r lpar -m fakevirt -o on -f fakeprof -b sms -n fakename")

        knife.run
      end
    end
  end
end
