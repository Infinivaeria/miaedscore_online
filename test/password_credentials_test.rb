require 'minitest/autorun'
require 'rack/mock'
require 'roda'
require_relative '../lib/password_credentials'

class PasswordCredentialsTest < Minitest::Test
  def test_hashes_are_salted_and_verify_the_password
    first = PasswordCredentials.create('correct horse')
    second = PasswordCredentials.create('correct horse')

    refute_equal first, second
    refute_includes first, 'correct horse'
    assert PasswordCredentials.valid?(first, 'correct horse')
    refute PasswordCredentials.valid?(first, 'wrong')
  end

  def test_legacy_passwords_remain_usable
    assert PasswordCredentials.valid?('legacy', 'legacy')
    refute PasswordCredentials.valid?('legacy', 'wrong')
    refute PasswordCredentials.valid?(nil, '')
  end

  def test_malformed_hashes_are_rejected
    refute PasswordCredentials.valid?('$pbkdf2-sha256$600000$invalid$invalid', 'password')
    refute PasswordCredentials.valid?('$pbkdf2-sha256$999999999$x$y', 'password')
    refute PasswordCredentials.valid?("#{PasswordCredentials.create('password')}$extra", 'password')
  end
end

class PasswordRoutesTest < Minitest::Test
  class FakeTable
    attr_reader :records

    def initialize
      @records = {}
    end

    def pad = self

    def [](*) = self

    def new_table!(**) = nil

    def get(*) = @records

    def set(*) = yield(@records)

    def save_everything_to_files! = nil
  end

  class FakeDatabase
    attr_reader :credentials

    def initialize
      @credentials = FakeTable.new
      @databases = { 'user_blog_database' => @credentials }
    end

    def [](name) = @databases[name]

    def add_db!(name) = @databases[name] = FakeTable.new

    def update_databases = nil
  end

  def setup
    @database = FakeDatabase.new
    app = Class.new(Roda)
    app.plugin :sessions, secret: 's' * 64
    app.const_set(:SUPER_PASSWORD, 'gate')
    app.class_variable_set(:@@line_db, @database)
    source = File.read(File.expand_path('../cgmfs/routes/blog.rb', __dir__)).gsub("\r\n", "\n")
    start = source.index("    r.on 'login' do\n")
    finish = source.index('    # for something like,', start)
    raise 'login or signup route not found' unless start && finish

    app.class_eval(
      "route do |r|\n  r.get('seed_admin') { session['admin'] = true; 'ok' }\n  r.on('blog') do\n#{source[start...finish]}\n  end\nend", __FILE__, __LINE__
    )
    @client = Rack::MockRequest.new(app.app)
  end

  def test_signup_hashes_password_and_login_checks_it
    result = nil
    capture_io do
      result = @client.post('/blog/signup', params: { 'blog_user_name' => 'Alice', 'blog_password_name' => 'secret' })
    end
    assert_equal 'User created successfully!', result.body
    stored = @database.credentials.records['alice']
    assert stored.start_with?(PasswordCredentials::PREFIX)
    refute_equal 'secret', stored
    assert_equal 302, login('alice', 'secret').status
    assert_equal 200, login('alice', 'wrong').status
  end

  def test_legacy_login_and_blank_signup
    @database.add_db!('legacy')
    @database.credentials.records['legacy'] = 'old password'
    assert_equal 302, login('legacy', 'old password').status

    result = nil
    capture_io do
      result = @client.post('/blog/signup', params: { 'blog_user_name' => 'empty', 'blog_password_name' => '' })
    end
    assert_equal 'Password must not be empty.', result.body
    assert_nil @database['empty']
  end

  def test_invalid_gate_does_not_run_password_verification
    @database.add_db!('legacy')
    stored = Class.new(String) do
      def start_with?(*) = raise('unexpected password verification')
    end
    @database.credentials.records['legacy'] = stored.new('old password')
    result = @client.post('/blog/login', params: { 'blog_user_name' => 'legacy', 'blog_password_name' => 'old password',
                                                   'super_password' => 'wrong' })
    assert_equal 200, result.status
    assert_includes result.body, 'Incorrect information'
  end

  def test_admin_override_hashes_the_replacement_password
    @database.add_db!('alice')
    @database.credentials.records['alice'] = 'old password'
    cookie = @client.get('/seed_admin')['set-cookie'].split(';', 2).first
    result = nil
    capture_io do
      result = @client.post('/blog/signup', 'HTTP_COOKIE' => cookie,
                                            params: { 'blog_user_name' => 'alice', 'blog_password_name' => 'replacement' })
    end
    assert_equal 'User created successfully! Admin override.', result.body
    assert @database.credentials.records['alice'].start_with?(PasswordCredentials::PREFIX)
    assert_equal 302, login('alice', 'replacement').status
    assert_equal 200, login('alice', 'old password').status
  end

  def test_startup_hashes_superadmin_password
    source = File.read(File.expand_path('../cgmfs.rb', __dir__)).gsub("\r\n", "\n")
    start = source.index("  @@line_db['user_blog_database'].pad['user_name_database', 'user_password_table'].set(0) do |hash|")
    finish = source.index("\n  end", start)
    raise 'superadmin initialization not found' unless start && finish

    initializer = Class.new
    initializer.const_set(:SUPERADMIN_PASSWORD, 'admin password')
    initializer.class_variable_set(:@@line_db, @database)
    initializer.class_eval(source[start...(finish + 6)], __FILE__, __LINE__)
    stored = @database.credentials.records['superadmin']
    assert stored.start_with?(PasswordCredentials::PREFIX)
    assert PasswordCredentials.valid?(stored, 'admin password')
  end

  private

  def login(user_name, password)
    @client.post('/blog/login', params: { 'blog_user_name' => user_name, 'blog_password_name' => password,
                                          'super_password' => 'gate' })
  end
end
