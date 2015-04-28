require 'rspec'
require 'rspec/mocks'
require File.join(File.dirname(__FILE__), '../..', 'ppboot.rb')

RSpec.configure do |config|
  config.color = true
  config.formatter = :documentation
  # original_stderr = $stderr
  # original_stdout = $stdout
  # config.before(:all) do
  #   # Redirect stderr and stdout
  #   $stderr = File.new(File.join(File.dirname(__FILE__), 'null.txt'), 'w')
  #   $stdout = File.new(File.join(File.dirname(__FILE__), 'null.txt'), 'w')
  # end
  # config.after(:all) do
  #   $stderr = original_stderr
  #   $stdout = original_stdout
  # end
end

describe 'PPBoot' do
  context "default" do
    before :each do
      boot=Dir.mktmpdir
      # boot='/tmp/foo'
      @ppboot = PPBoot.new(boot)
    end

    describe '#install' do
      it "should install module puppetlabs-stdlib" do
        expect(@ppboot.install 'puppetlabs-stdlib').to eql(:success)
        if Gem.loaded_specs['puppet'].version >= Gem::Version.new('3.6.0')
          expect(@ppboot.install 'puppetlabs-stdlib').to eql(:noop)
        else
          expect(@ppboot.install 'puppetlabs-stdlib').to eql(:failure)
        end
      end

      it "should fail module puppetlabs-notfound" do
        expect(@ppboot.install 'puppetlabs-notfound').to eql(:failure)
      end

    end

    describe '#get_dependencies' do
      context 'valid JSON' do
        before :each do
          data = '{ "dependencies": [ {"name":"puppetlabs-stdlib","version_requirement":">= 1.0.0"} ] }'
          allow(File).to receive(:read).and_return(data)
          @ret = @ppboot.get_dependencies
        end

        it "should return 1 item array" do
          expect(@ret.count).to eql(1)
        end

        it "should have element with name" do
          expect(@ret.first['name']).to eql('puppetlabs-stdlib')
        end
      end

      context "invalid JSON" do
        before :each do
          allow(File).to receive(:read).and_return('abc')
        end

        it "should raise Error" do
          expect{@ppboot.get_dependencies}.to raise_error
        end

      end

    end

    describe "#report" do
      it "should report one installed module" do
        @ppboot.install 'puppetlabs-stdlib'
        expect( @ppboot.report.count).to eql(1)
      end

      it "should report three installed modules" do
        @ppboot.install 'puppetlabs-apache', '1.3.0'
        expect( @ppboot.report.count).to eql(3)
      end

      it "should install module puppetlabs-stdlib version <=3.2.2" do
        expect( @ppboot.install 'puppetlabs-stdlib', '<=3.2.2').to eql(:success)
        expect( @ppboot.report.first).to eql('puppetlabs/stdlib-3.2.2')
      end
    end
  end

  context "run" do
    before :each do
      boot=Dir.mktmpdir
      @ppboot = PPBoot.new(boot, File.join(File.dirname(__FILE__), '../fixtures', 'metadata.json'))
    end
    describe "#run" do
      it "should install properly" do
        r = @ppboot.run!
        expect(r.count).to eql(3)
        expect(r.first).to eql('puppetlabs/apache-1.3.0')
        expect(r.last).to match(/puppetlabs\/stdlib-\d+.\d+.\d+/)
      end
    end
  end
end
