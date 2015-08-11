require 'spec_helper'

describe StateMachinesActiverecordRspec::Matchers::HandleEventMatcher do
  describe '#matches?' do
    context 'when :when state is specified' do
      context 'but the state doesn\'t exist' do
        before do
          matcher_class = Class.new do
            state_machine :state, initial: :mathy
          end
          @matcher_subject = matcher_class.new
          @matcher = described_class.new([when: :artsy])
        end

        it 'raises' do
          expect { @matcher.matches? @matcher_subject }.
            to raise_error StateMachineIntrospectorError
        end
      end

      context 'and that state exists' do
        before do
          matcher_class = Class.new do
            state_machine :state, initial: :mathy do
              state :artsy
            end
          end
          @matcher_subject = matcher_class.new
          @matcher = described_class.new([when: :artsy])
        end

        it 'sets the state' do
          @matcher.matches? @matcher_subject
          expect(@matcher_subject.state).to  eq 'artsy'
        end
      end
    end

    context 'when subject can perform events' do
      before do
        matcher_class = Class.new do
          state_machine :mathiness, initial: :mathy do
            event(:mathematize) { transition any => same }
          end
        end
        @matcher_subject = matcher_class.new
        @matcher = described_class.new([:mathematize, on: :mathiness])
      end

      it 'does not set a failure message' do
        @matcher.matches? @matcher_subject
        expect(@matcher.failure_message).to  be_nil
      end
      it 'returns true' do
        expect(@matcher.matches?(@matcher_subject)).to be_truthy
      end
    end

    context 'when subject cannot perform events' do
      before do
        matcher_class = Class.new do
          state_machine :state, initial: :mathy do
            state :polynomial

            event(:mathematize) { transition any => same }
            event(:algebraify) { transition :polynomial => same }
            event(:trigonomalize) { transition :trigonomalize => same }
          end
        end
        @matcher_subject = matcher_class.new
      end

      context 'because it cannot perform the transition' do
        before do
          @matcher = described_class.new([:mathematize, :algebraify, :trigonomalize])
        end

        it 'sets a failure message' do
          @matcher.matches? @matcher_subject
          expect(@matcher.failure_message).to eq('Expected to be able to handle events: algebraify, trigonomalize ' +
                                                 'in state: mathy')
        end
        it 'returns false' do
          expect(@matcher.matches?(@matcher_subject)).to be_falsey
        end
      end

      context 'because no such events exist' do
        before do
          @matcher = described_class.new([:polynomialize, :eulerasterize])
        end

        it 'does not raise' do
          expect { @matcher.matches?(@matcher_subject) }.not_to raise_error
        end
        it 'sets a failure message' do
          @matcher.matches? @matcher_subject
          expect(@matcher.failure_message).to eq('state_machine: state does not ' +
                                                 'define events: polynomialize, eulerasterize')
        end
        it 'returns false' do
          expect(@matcher.matches?(@matcher_subject)).to be_falsey
        end
      end
    end
  end

  describe '#description' do
    context 'with no options' do
      let(:matcher) { described_class.new([:placate, :mollify]) }

      it 'returns a string description' do
        expect(matcher.description).to  eq('handle :placate, :mollify')
      end
    end

    context 'when :when state is specified' do
      let(:matcher) { described_class.new([:destroy_food, when: :hangry]) }

      it 'mentions the requisite state' do
        expect(matcher.description).to eq('handle :destroy_food when :hangry')
      end
    end

    context 'when :on is specified' do
      let(:matcher) { described_class.new([:ensmarmify, on: :tired_investors]) }

      it 'mentions the state machine variable' do
        expect(matcher.description).to eq('handle :ensmarmify on :tired_investors')
      end
    end
  end
end
