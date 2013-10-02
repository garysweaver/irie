require 'test_helper'

describe ::Actionizer::Extensions::Common::ParamToThrough do
  it "handles single symbol" do
    ::Actionizer::Extensions::Common::ParamToThrough.parse_through_options(:a, Foo).must_equal nil
  end

  it "handles single-depth hash" do
    ::Actionizer::Extensions::Common::ParamToThrough.parse_through_options({a: :b}, Foo).must_equal nil
  end

  it "handles double-depth hash" do
    ::Actionizer::Extensions::Common::ParamToThrough.parse_through_options({a: {b: :c}}, Foo).must_equal nil
  end

  it "handles triple-depth hash" do
    ::Actionizer::Extensions::Common::ParamToThrough.parse_through_options({a: {b: {c: :d}}, Foo).must_equal nil
  end
end
