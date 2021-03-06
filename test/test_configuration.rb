require 'helper'

class TestConfiguration < Minitest::Test
  def setup
    @configuration = OSRM::Configuration.send(:new)
  end

  def test_defaults
    assert_nil @configuration.server
    assert_nil @configuration.port
    refute @configuration.use_ssl?

    assert_equal 3, @configuration.timeout
    assert_match /\AOSRMRubyGem\/\d+\.\d+\.\d+\z/, @configuration.user_agent
    assert_nil @configuration.before_request
    assert_nil @configuration.after_request

    assert_nil @configuration.cache
    assert_match /\A.{2,10}\{url\}\z/, @configuration.cache_key

    refute @configuration.use_demo_server?
  end

  def test_merge
    @configuration.server  = 'server.com'
    @configuration.port    = 51
    @configuration.use_ssl = true
    @configuration.before_request = -> {}
    @configuration.after_request  = -> {}
    @configuration.cache   = nil
    @configuration.merge!(
      port:    123,
      use_ssl: false,
      invalid: 'invalid option!',

      timeout:       42,
      user_agent:    'OneAgent/6.0',
      after_request: nil,

      cache:      {},
      cache_key:  'one-agent-{url}'
    )
    assert_equal 'server.com', @configuration.server
    assert_equal 123, @configuration.port
    refute @configuration.use_ssl?

    assert_equal 42, @configuration.timeout
    assert_equal 'OneAgent/6.0', @configuration.user_agent
    assert_kind_of Proc, @configuration.before_request
    assert_nil @configuration.after_request

    assert_kind_of Hash, @configuration.cache
    assert_empty @configuration.cache
    assert_equal 'one-agent-{url}', @configuration.cache_key
    refute_respond_to @configuration, :invalid

    assert_same @configuration, @configuration.merge!(key: 'value')
  end

  def test_server
    @configuration.server = 'example.com'
    assert_equal 'example.com', @configuration.server
    refute @configuration.use_demo_server?
  end

  def test_demo_server
    @configuration.server = :demo
    assert_equal OSRM::Configuration::DEMO_SERVER, @configuration.server
    assert @configuration.use_demo_server?
  end

  def test_server_change
    randomize_change(:test_server, :test_demo_server)
  end

  def test_port
    @configuration.port = '123'
    assert_equal 123, @configuration.port
    assert_instance_of Fixnum, @configuration.port
  end

  def test_ssl_true
    @configuration.use_ssl = true
    assert @configuration.use_ssl?
  end

  def test_ssl_false
    @configuration.use_ssl = false
    refute @configuration.use_ssl?
  end

  def test_ssl_change
    randomize_change(:test_ssl_true, :test_ssl_false)
  end

  def test_timeout
    @configuration.timeout = 5.0
    assert_equal 5, @configuration.timeout
    assert_instance_of Fixnum, @configuration.timeout
  end

  def test_user_agent
    @configuration.user_agent = 'Bot/0.1'
    assert_equal 'Bot/0.1', @configuration.user_agent
  end

  def test_before_after_request
    @configuration.before_request = proc {}
    @configuration.after_request  = -> {}
    assert_kind_of Proc, @configuration.before_request
    assert_kind_of Proc, @configuration.after_request
    refute @configuration.before_request.lambda?
    assert @configuration.after_request.lambda?
  end

  def test_nil_cache
    @configuration.cache = nil
    assert_nil @configuration.cache
  end

  def test_cache
    @configuration.cache = { 'a' => '1', 'b' => '2' }
    refute_empty @configuration.cache
    assert_equal '1', @configuration.cache['a']
    assert_equal '2', @configuration.cache['b']
  end

  def test_cache_change
    randomize_change(:test_nil_cache, :test_cache)
  end

  def test_cache_key
    @configuration.cache_key = 'test $ {url}'
    assert_equal 'test $ {url}', @configuration.cache_key

    assert_raises(RuntimeError) { @configuration.cache_key = 'invalid key' }
  end

  def randomize_change(method_1, method_2)
    method_1_first = rand(2).zero?
    public_send(method_1) if method_1_first
    public_send(method_2)
    public_send(method_1)
    public_send(method_2) unless method_1_first
  end
end
