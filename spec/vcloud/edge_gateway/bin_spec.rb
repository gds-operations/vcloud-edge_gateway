require 'spec_helper'

class CommandRun
  attr_accessor :stdout, :stderr, :exitstatus

  def initialize(args)
    out = StringIO.new
    err = StringIO.new

    $stdout = out
    $stderr = err

    begin
      Vcloud::EdgeGateway::Bin.new(args).run
      @exitstatus = 0
    rescue SystemExit => e
      # Capture exit(n) value.
      @exitstatus = e.status
    rescue
      # Uncaught exception which would normally exit 1.
      @exitstatus = 1
    end

    @stdout = out.string.strip
    @stderr = err.string.strip

    $stdout = STDOUT
    $stderr = STDERR
  end
end

describe Vcloud::EdgeGateway::Bin do
  subject { CommandRun.new(args) }
  let(:mock_configure) {
    double(:configure, :update => true)
  }

  describe "normal usage" do
    context "when given a single config file" do
      let(:args) { %w{config.yaml} }

      it "should pass single argument and exit normally" do
        expect(Vcloud::EdgeGateway::Configure).to receive(:new).
          with('config.yaml').and_return(mock_configure)
        expect(mock_configure).to receive(:update)
        expect(subject.exitstatus).to eq(0)
      end
    end

    context "when given --template-vars and config file" do
      let(:args) { %w{--template-vars vars.yaml config.yaml} }

      it "should pass two arguments and exit normally" do
        expect(Vcloud::EdgeGateway::Configure).to receive(:new).
          with('config.yaml', 'vars.yaml').and_return(mock_configure)
        expect(mock_configure).to receive(:update)
        expect(subject.exitstatus).to eq(0)
      end
    end

    context "when asked to display version" do
      let(:args) { %w{--version} }

      it "should not call Configure" do
        expect(Vcloud::EdgeGateway::Configure).not_to receive(:new)
      end

      it "should print version and exit normally" do
        expect(subject.stdout).to eq(Vcloud::EdgeGateway::VERSION)
        expect(subject.exitstatus).to eq(0)
      end
    end

    context "when asked to display help" do
      let(:args) { %w{--help} }

      it "should not call Configure" do
        expect(Vcloud::EdgeGateway::Configure).not_to receive(:new)
      end

      it "should print usage and exit normally" do
        expect(subject.stdout).to match(/\AUsage: \S+ \[options\] config_file\n/)
        expect(subject.exitstatus).to eq(0)
      end
    end
  end

  describe "incorrect usage" do
    shared_examples "print usage and exit abnormally" do |error|
      it "should not call Configure" do
        expect(Vcloud::EdgeGateway::Configure).not_to receive(:new)
      end

      it "should print error message and usage" do
        expect(subject.stdout).to match(/\A\S+: #{error}\nUsage: \S+/)
      end

      it "should exit abnormally for incorrect usage" do
        expect(subject.exitstatus).to eq(2)
      end
    end

    context "when run without any arguments" do
      let(:args) { %w{} }

      it_behaves_like "print usage and exit abnormally", "must supply config_file"
    end

    context "when given a multiple config files" do
      let(:args) { %w{one.yaml two.yaml} }

      it_behaves_like "print usage and exit abnormally", "must supply config_file"
    end

    context "when given an unrecognised argument" do
      let(:args) { %w{--this-is-garbage} }

      it_behaves_like "print usage and exit abnormally", "invalid option: --this-is-garbage"
    end
  end
end
