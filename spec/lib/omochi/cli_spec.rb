require 'rspec'
require 'omochi/cli'

describe Omochi::CLI do
  describe 'verify' do
    it 'trueがかえること' do
      expect(subject.verify).to eq true
    end
  end
end
