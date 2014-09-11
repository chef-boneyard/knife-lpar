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

  # subject(:knife) do
  #   Chef::Knife::LparCreate.new(argv).tap do |c|
  #     allow(c).to receive(:output).and_return(true)
  #     c.parse_options(argv)
  #     c.merge_configs
  #   end
  # end

  describe '#run' do
    # before(:each) do
    #   @knife = Chef::Knife::LparCreate.new
    #   # @knife.stub(:read_and_validate_params)
    #   # @knife.stub(:get_password)
    #   # @knife.stub(:create_lpar)
    #   @knife
    # end

    subject(:knife) do
      Chef::Knife::LparCreate.new(argv).tap do |c|
        allow(c).to receive(:output).and_return(true)
        c.parse_options(argv)
        c.merge_configs
      end
    end

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

    # subject(:knife) do
    #   Chef::Knife::LparCreate.new(argv).tap do |c|
    #     # allow(c).to receive(:output).and_return(true)
    #     # c.parse_options(argv)
    #     # c.merge_configs
    #   end
    # end

    # before(:each) do
    #   expect(knife.config[:name]).to eq("fakename")
    #   expect(knife.config[:virtual_server]).to eq("fakevirt")
    #   expect(knife.config[:vios]).to eq("fakevios")
    #   expect(knife.config[:disk_name]).to eq("fakedisk")
    # end

    # before(:each) do
    #   @knife = Chef::Knife::LparCreate.new
    #   @knife.stub(:read_and_validate_params)
    #   @knife.stub(:get_password)
    #   @knife.stub(:create_lpar)
    # end
    #
    #
    context 'when argv is empty' do
      let(:argv) { %W[] }
      let(:knife) do
        knife = Chef::Knife::LparCreate.new(argv)
        knife
      end

      it 'prints usage and exits' do
        expect(knife).to receive(:read_and_validate_params)

        expect(knife).to receive(:show_usage)
        # expect(knife.ui).to receive(:fatal)
        expect { knife.run }.to raise_error(SystemExit)
      end
    end

    # context 'by default' do
    #   let(:argv) { %w[ create serverurl -n fakename --vios fakevios --virtual-server fakevirt --disk fakedisk -p fakeprof ] }
    #
    #   it 'sets defaults' do
    #     expect(knife).to receive(:read_and_validate_params).and_call_original
    #     expect(knife).to receive(:get_password)
    #     expect(knife).to receive(:create_lpar)
    #     knife.run
    #     expect(knife.config[:profile]).to eq("fakeprof")
    #     expect(knife.config[:min_mem]).to eq(1024)
    #     expect(knife.config[:desired_mem]).to eq(4096)
    #     expect(knife.config[:max_mem]).to eq(16384)
    #     expect(knife.config[:min_procs]).to eq(1)
    #     expect(knife.config[:desired_procs]).to eq(2)
    #     expect(knife.config[:max_procs]).to eq(4)
    #     expect(knife.config[:min_proc_units]).to eq(1)
    #     expect(knife.config[:desired_proc_units]).to eq(2)
    #     expect(knife.config[:max_proc_units]).to eq(4)
    #   end
    # end
    #
    # context 'without profile' do
    #   let(:argv) { %w[ create serverurl -n fakename --vios fakevios --virtual-server fakevirt --disk fakedisk ] }
    #
    #   it 'defaults profile to name' do
    #     expect(knife).to receive(:read_and_validate_params).and_call_original
    #     expect(knife).to receive(:get_password)
    #     expect(knife).to receive(:create_lpar)
    #     knife.run
    #     expect(knife.config[:profile]).to eq("fakename")
    #   end
    # end
  end
end
