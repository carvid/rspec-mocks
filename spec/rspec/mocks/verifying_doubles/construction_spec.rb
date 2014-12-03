require 'support/doubled_classes'

module RSpec
  module Mocks
    RSpec.describe 'Constructing a verifying double' do
      include_context 'with isolated configuration'

      class ClassThatDynamicallyDefinesMethods
        def self.define_attribute_methods!
          define_method(:some_method_defined_dynamically) { true }
        end
      end

      module CustomModule
      end

      describe 'instance doubles' do
        it 'cannot be constructed with a non-module object' do
          expect {
            instance_double(Object.new)
          }.to raise_error(/Module or String expected/)
        end

        it 'can be constructed with a struct' do
          o = instance_double(Struct.new(:defined_method), :defined_method => 1)
          expect(o.defined_method).to eq(1)
        end

        it 'allows constants to be looked up and declared to verifying double callbacks' do
          expect { |probe|
            RSpec.configuration.mock_with(:rspec) do |config|
              config.verify_doubled_constant_names = true
              config.when_declaring_verifying_double(&probe)
            end

            instance_double("RSpec::Mocks::ClassThatDynamicallyDefinesMethods")
          }.to yield_with_args(have_attributes :target => ClassThatDynamicallyDefinesMethods)
        end

        it 'allows classes to be customised' do
          test_class = Class.new(ClassThatDynamicallyDefinesMethods)

          RSpec.configuration.mock_with(:rspec) do |config|
            config.when_declaring_verifying_double do |reference|
              reference.target.define_attribute_methods!
            end
          end

          instance_double(test_class, :some_method_defined_dynamically => true)
        end
      end

      describe 'class doubles' do
        it 'cannot be constructed with a non-module object' do
          expect {
            class_double(Object.new)
          }.to raise_error(/Module or String expected/)
        end

        it 'declares the module to verifying double callbacks' do
          expect { |probe|
            RSpec.configuration.mock_with(:rspec) do |config|
              config.when_declaring_verifying_double(&probe)
            end
            class_double CustomModule
          }.to yield_with_args(have_attributes :target => CustomModule)
        end
      end

      describe 'object doubles' do
        it 'declares the class to verifying double callbacks' do
          expect { |probe|
            RSpec.configuration.mock_with(:rspec) do |config|
              config.when_declaring_verifying_double(&probe)
            end
            object_double Object.new
          }.to yield_with_args(have_attributes :target => Object)
        end
      end

      describe 'when verify_doubled_constant_names config option is set' do

        before do
          RSpec::Mocks.configuration.verify_doubled_constant_names = true
        end

        it 'prevents creation of instance doubles for unloaded constants' do
          expect {
            instance_double('LoadedClas')
          }.to raise_error(VerifyingDoubleNotDefinedError)
        end

        it 'prevents creation of class doubles for unloaded constants' do
          expect {
            class_double('LoadedClas')
          }.to raise_error(VerifyingDoubleNotDefinedError)
        end
      end

      it 'can only be named with a string or a module' do
        expect { instance_double(1) }.to raise_error(ArgumentError)
        expect { instance_double(nil) }.to raise_error(ArgumentError)
      end
    end
  end
end
