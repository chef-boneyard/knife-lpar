require 'spec_helper'
require 'chef/knife/lpar_base.rb'

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
