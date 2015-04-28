require 'rubygems'
require 'puppet'
require 'puppet/module_tool'
require 'json'
require 'optparse'
require 'fileutils'
require 'semver'


class PPBoot
  def initialize boot_dir_path, input_file = nil
    @boot_dir_path = boot_dir_path
    @inputfile = input_file
    @vardir = Dir.mktmpdir
    Puppet.settings[:vardir]= @vardir
    case Gem.loaded_specs['puppet'].version
    when proc{ |n| n < Gem::Version.new('3.5.0') }
      Puppet.settings[:modulepath]= boot_dir_path
      @fake_env = Puppet::Node::Environment.new('temp')
    else
      @fake_env = Puppet::Node::Environment.create('temp',[boot_dir_path])
    end
      @boot_dir = Puppet::ModuleTool::InstallDirectory.new(Pathname.new(boot_dir_path))
  end

  def report
    rep=Array.new
    case Gem.loaded_specs['puppet'].version
    when proc{ |n| n < Gem::Version.new('3.6.0') }
      @fake_env.modules_by_path[@boot_dir_path].each do |mod|
        p="#{mod.forge_name}-#{mod.version}"
        rep << p
      end
    else
      Puppet::ModuleTool::InstalledModules.new(@fake_env).by_name.each do |key,imodule|
        p="#{imodule.forge_name}-#{imodule.metadata['version']}"
        rep << p
      end
    end

    rep
  end

  def install fmodule, version = '>=0.0.0'
    case Gem.loaded_specs['puppet'].version
    when proc{ |n| n < Gem::Version.new('3.6.0') }
      inst = Puppet::ModuleTool::Applications::Installer.new(fmodule, Puppet::Forge.new("PMT", SemVer.new('0.0.0')), @boot_dir, {:environment_instance => @fake_env, :target_dir => @boot_dir_path, :version => version})
    else
      inst = Puppet::ModuleTool::Applications::Installer.new(fmodule, @boot_dir, {:environment_instance => @fake_env, :version => version})
    end
    begin
      r = inst.run
    rescue RuntimeError => e
      puts e.message
      return :failure
    end
    r[:result]
  end

  def run!(verbose = false)
    deps = get_dependencies

    deps.each do |fmod|
      print "installing #{fmod['name']}... "
      r = install fmod['name'], fmod['version_requirement']
      case r
      when :failure
        print "failed\n"
      when :noop
        print "skipped\n"
      when :success
        print "done\n"
      end
    end

    report.each do |item|
      puts item
    end
  end

  def get_dependencies
    begin
      JSON.load(File.read(@inputfile))["dependencies"]
    rescue
      raise "The input file provided is not readable, not a valid json or doesn't contain `dependencies` section"
    end
  end
end

if __FILE__ == $0
  options = {
    :verbose    => false,
    :modulepath => "/etc/puppet/modules",
    :input      => File.expand_path(File.dirname(__FILE__))+'/metadata.json'
  }
  OptionParser.new do |opts|
    opts.banner = "Usage: install_deps.rb [options]"

    opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
      options[:verbose] = v
    end

    opts.on("-mMODULEPATH", "--modulepath MODULEPATH", "A path to install modules. It will default to /etc/puppet/modules") do |m|
      options[:modulepath] = m
    end

    opts.on("-iINPUT", "--input INPUT", "Source metadata.json file") do |i|
      options[:input] = i
    end
  end.parse!

  p = PPBoot.new(options[:modulepath], options[:input])
  p.run!


end
