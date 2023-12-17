require 'rspec'
require 'omochi/cli'

describe 'Omochi::CLI' do
  describe 'verify' do
    it '存在すること' do
      expect(subject.verify).to be_truthy
    end
  end
end
