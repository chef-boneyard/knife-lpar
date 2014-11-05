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
require 'chef/knife/lpar_list.rb'

describe Chef::Knife::LparList do

  subject(:knife) do
    Chef::Knife::LparList.new(argv).tap do |c|
      allow(c).to receive(:output).and_return(true)
      c.parse_options(argv)
      c.merge_configs
    end
  end

  describe '#run' do
    context 'by default' do
      let(:argv) { %w[ list serverurl --virtual-server fakevirt ] }

      it 'parses argv, gets password, and lists lpars' do
        expect(knife).to receive(:read_and_validate_params).and_call_original
        expect(knife).to receive(:get_password)
        expect(knife).to receive(:list_lpars)
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

    context 'when the virtual-server parameter is missing' do
      let(:argv) { %w[ list serverurl ] }

      it 'prints usage and exits' do
        expect(knife).to receive(:read_and_validate_params).and_call_original
        expect(knife).to receive(:show_usage)
        expect { knife.run }.to raise_error(SystemExit)
      end
    end
  end

  describe '#list_lpars' do
    before(:each) do
      Chef::Knife::LparList.load_deps
      @session = double(Net::SSH)
      allow(Net::SSH).to receive(:start).with("serverurl", "hscroot", :password => "testpass").and_yield(@session)
    end

    context 'listing lpars' do
      let(:argv) { %w[ list serverurl --virtual-server fakevirt ] }

      it 'lists lpars' do

        expect(knife).to receive(:read_and_validate_params).and_call_original
        expect(knife).to receive(:get_password).and_return("testpass")
        expect(knife).to receive(:list_lpars).and_call_original
        expect(knife).to receive(:run_remote_command).with(@session, "lssyscfg -m fakevirt -F lpar_id,lpar_env,name,os_version -r lpar").and_return("1,vios,whee,VIOS 1.2.3.4\n")

        knife.run
      end
    end
  end
end
