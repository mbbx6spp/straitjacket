require 'spec_helper'
require 'sj/ugly/action'

module SJ
  module Ugly
    class AddAndPrint
      include SJ::Ugly::Action

      Outcome = Struct.new(:c)

      private

      def initialize(a:, b:)
        validates do |errors|
          errors << 'a non-numeric' unless a.kind_of?(Numeric)
          errors << 'b non-numeric' unless a.kind_of?(Numeric)
        end

        @a = a
        @b = b
      end

      def invoke!
        c = @a + @b
        puts c
        return Outcome.new(c)
      end
    end

    describe Action::Unit, pure: true do
      subject { described_class } # misnomer, as this is a global instance

      it 'is empty' do
        expect(subject.length).to be_zero
      end
    end

    describe Action, pure: true do
      let(:a) { 1 }
      let(:b) { 2 }

      let(:add_and_print) { AddAndPrint }

      before do
        allow_any_instance_of(add_and_print).to receive(:puts) # stub puts
      end

      def call!(&block)
        add_and_print.mk(
          a: a,
          b: b
        ).call!(&block)
      end

      describe 'validation' do
        it 'happens' do
          expect_any_instance_of(add_and_print).to receive(:validates)
          call!
        end

        context 'with bad inputs' do
          let(:a) { 'one' }
          let(:b) { 'two' }

          it 'raises ArgumentError' do
            expect {
              call!
            }.to raise_error(ArgumentError, /a non.*b non/)
          end
        end
      end

      describe 'invocation via #call!' do
        it 'calls #invoke!' do
          expect_any_instance_of(add_and_print).to receive(:invoke!)
          call!
        end
      end

      describe 'yielded outcome' do
        it 'is of correct type' do
          call! do |outcome|
            expect(outcome).to be_a(add_and_print::Outcome)
            call!
          end
        end
      end
    end
  end
end
