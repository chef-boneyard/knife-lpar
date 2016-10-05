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
require "chef/knife/lpar_base.rb"

describe Chef::Knife::LparBase do
  class Chef
    class Knife
      class DummyClass < Knife
        include Knife::LparBase
      end
    end
  end

  subject(:dummy) do
    Chef::Knife::DummyClass.new
  end

  describe "#print_with_output" do
    it "should print the message when there is no extra output" do
      expect(dummy.ui).to receive(:info).with("Message")
      return_val = dummy.print_with_output("Message", nil)
    end

    it "should concatenate output to the message" do
      expect(dummy.ui).to receive(:info).with("Message - with some output and whatnot")
      return_val = dummy.print_with_output("Message", "with some output and whatnot")
    end
  end

  describe "#run_remote_command" do
    before(:each) do
      @session = double(Net::SSH)
    end

    # Not sure how to do the stdout part
    it "should return a value in :stdout" do
      expect(dummy).to receive(:run_remote_command).and_call_original
      expect(@session).to receive(:exec!).with("TestCommand")
      dummy.run_remote_command(@session, "TestCommand")
    end
  end
end
