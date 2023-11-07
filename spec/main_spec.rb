# frozen_string_literal: true

require 'rspec'
require_relative '../main'

describe 'StringFormat.remove_os_restricted' do
  it 'removes os restricted symbols from a input string' do
    input_string = '<Lorem> ipsum: "dolor" /sit\ amet |consectetur? adipiscing* elit #sed@ do& eiusmod'
    cleaned_string = StringFormat.remove_os_restricted(input_string)
    expect(cleaned_string).to eq('Lorem ipsum dolor sit amet consectetur adipiscing elit sed do eiusmod')
  end
end

describe 'StringFormat.replace_multi' do
  it 'replaces multiple patterns in a string' do
    string = 'Hello World'
    pattern = {
      'Hello' => 'Hello',
      'World' => 'Ruby'
    }

    result = StringFormat.replace_multi(string, pattern)

    expect(result).to eq('Hello Ruby')
  end
end
