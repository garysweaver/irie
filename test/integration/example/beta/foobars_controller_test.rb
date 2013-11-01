require 'test_helper'

class Example::Beta::TestFoobarsController < ActionDispatch::IntegrationTest
  
  def setup
    ::DatabaseCleaner.start
    ::Irie.update_should_return_entity = true
    @controller = Example::Beta::FoobarsController.new
    $test_role = 'admin'

    10.times do |c|
      bar = Bar.where(id: c).first || Bar.create(id: c, code: "abc#{c}", open_hours: c)
      foo = Foo.create(id: c, code: "123#{c}", bar: bar)
      Foobar.create(foo: foo)
    end
  end

  def teardown
    DatabaseCleaner.clean
  end
  
  # unimportant test that same controller name, same model, in two namespaces works somewhat
  test 'create allowed for accepted params' do
    Foobar.delete_all
    before_count = Foobar.count
    code = "new#{rand(99999)}"
    post "/example/beta/foobars.json", foobar: {foo_attributes: {code: code}}
    assert_equal before_count + 1, Foobar.count, "Didn't create Foobar"
    assert_equal code, Foobar.last.foo.code
    # RFC 2616 conformance checks. See: http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html#sec10.2.1
    assert_equal "http://www.example.com/example/beta/foobars/#{Foobar.last.id}", response.headers['Location'], "didn't include expected location header. was #{response.headers['Location']}"
    assert_equal "application/json; charset=utf-8", response.headers['Content-Type'], "didn't include expected content-type. was #{response.headers['Content-Type']}"
    assert_equal 200, response.status, "Bad response code (got #{response.status}): #{response.body}"
    
    assert_equal "{\"check\":\"foobars-create: #{Foobar.last.id}\"}", response.body
  end

end
