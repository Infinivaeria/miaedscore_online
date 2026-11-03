require 'minitest/autorun'
require 'rack/mock'
require 'roda'
require 'json'
require 'erb'
require 'cgi'
require 'uri'
require 'tmpdir'
require_relative '../lib/partitioned_array/lib/managed_partitioned_array'

class GalleryTagsTest < Minitest::Test
  class FakeTable
    attr_reader :record, :reads, :saves, :full_saves, :saved_ids

    def initialize(images = [])
      @record = {}
      @images = images
      @reads = 0
      @saves = 0
      @full_saves = 0
      @saved_ids = []
    end

    def data_arr
      @reads += 1
      @images
    end

    def get(*) = @record

    def set(*) = yield(@record)

    def save_everything_to_files! = @full_saves += 1

    def save_partition_by_id_to_file!(id)
      @saved_ids << id
      @saves += 1
    end

    def save_partition_to_file!(*) = nil
  end

  class FakePad
    def initialize(tables) = @tables = tables

    def pad = self

    def [](_database, table) = @tables.fetch(table)
  end

  def setup
    @images = [{ 'tags' => 'red, blue, red' }, nil, {}, { 'tags' => 'red, green' }]
    @gallery = FakeTable.new(@images)
    @cache = FakeTable.new
    pad = FakePad.new('gallery_table' => @gallery, 'cache_system_table' => @cache,
                      'blog_statistics_table' => FakeTable.new)

    app = Class.new(Roda) do
      def user_failcheck(*) = nil

      def domain_name(*) = 'https://example.test'

      def view(template, **)
        if template.end_with?('tags_search')
          JSON.generate('images' => @images_to_find, 'terms' => @search_params_set&.to_a,
                        'only_search' => @only_search, 'similar' => @similar_tags_set)
        else
          JSON.generate('tags' => @tags_set, 'similar' => @similar_tags)
        end
      end
    end
    app.class_variable_set(:@@line_db, { 'alice' => pad })
    source = File.read(File.expand_path('../cgmfs/routes/gallery.rb', __dir__)).gsub("\r\n", "\n")
    helper_start = source.index('  def gallery_tag_link(')
    helper_end = source.index('  class AECalendar', helper_start)
    app.class_eval(source[helper_start...helper_end], __FILE__, __LINE__)
    start = source.index("    r.is 'view', String, 'tags', 'search' do |user|")
    raise 'gallery tags search route not found' unless start

    finish = source.index('    # /gallery/edit/user/id/ID', start)
    raise 'gallery tags route end not found' unless finish

    app.class_eval("route do |r|\n#{source[start...finish]}\nend", __FILE__, __LINE__)
    @app = app
    @client = Rack::MockRequest.new(app.app)
  end

  def test_rebuilds_before_rendering_and_reuses_cache
    first = tags_response
    assert_equal 3, first['tags'].length
    assert(first['tags'].any? { |tag| tag.include?('red(2)') })
    assert_equal %w[blue green], first['similar']['red']
    assert_equal first, tags_response
    assert_equal 1, @gallery.reads
    assert_equal 1, @cache.saves
    assert_equal [0], @cache.saved_ids
    assert_equal 0, @cache.full_saves
  end

  def test_rebuilds_invalidated_cache
    tags_response
    @images << { 'tags' => 'blue' }
    @cache.record['recache'] = true
    assert(tags_response['tags'].any? { |tag| tag.include?('blue(2)') })
    assert_equal 2, @gallery.reads
    assert_equal 2, @cache.saves
  end

  def test_tag_links_search_literal_values_and_escape_html
    @images << { 'tags' => '++red, ||blue, --green, fish & chips, <script>' }
    links = tags_response['tags']
    ['++red', '||blue', '--green', 'fish & chips', '<script>'].each do |tag|
      label = CGI.escapeHTML("#{tag}(1)")
      link = links.find { |entry| entry.include?(label) }
      refute_nil link
      url = URI(CGI.unescapeHTML(link[/href='([^']+)'/, 1]))
      response = @client.get(url.request_uri.sub(%r{\A/gallery/}, '/'))
      assert_equal [{ 'tags' => '++red, ||blue, --green, fish & chips, <script>' }], JSON.parse(response.body)['images']
    end
    refute(links.any? { |link| link.include?('<script>') })
  end

  def test_old_tag_link_cache_is_rebuilt
    @cache.record.merge!('tags_set' => ['old'], 'similar_tags' => {}, 'recache' => false)
    refute_includes tags_response['tags'], 'old'
    assert_equal 1, @cache.record['tag_link_version']
  end

  def test_parse_tags_uses_literal_and_html_safe_links
    output = @app.allocate.parse_tags(user: 'alice', tag_string: '++red, <script>')
    assert_includes output, 'search_tags=%5C%2B%2Bred'
    assert_includes output, '&lt;script&gt;'
    refute_includes output, '<script>'
  end

  def test_empty_and_incomplete_caches_are_rebuilt
    @images.clear
    @cache.record['recache'] = false
    assert_equal({ 'tags' => [], 'similar' => {} }, tags_response)
    assert_equal 1, @gallery.reads
    assert_equal 1, @cache.saves
  end

  def test_partition_save_survives_reload
    Dir.mktmpdir('gallery-cache-') do |directory|
      options = { max_capacity: 'data_arr_size', has_capacity: true, db_size: 5,
                  partition_amount_and_offset: 4, db_path: directory, db_name: 'cache' }
      table = ManagedPartitionedArray.new(**options)
      table.allocate
      table.save_everything_to_files!
      expected = { 'tags_set' => ['red(2)'], 'similar_tags' => { 'red' => ['blue'] }, 'recache' => false }
      table.set(0) { |entry| entry.merge!(expected) }
      table.save_partition_by_id_to_file!(0)

      reloaded = ManagedPartitionedArray.new(**options)
      reloaded.load_everything_from_files!
      assert_equal expected, reloaded.get(0)
    end
  end

  def test_search_combines_required_and_excluded_tags
    response = @client.get('/view/alice/tags/search', params: { 'search_tags' => '++ red,blue,--green' })
    assert_equal 200, response.status
    result = JSON.parse(response.body)
    assert_equal %w[red blue], result['terms']
    assert_equal [{ 'tags' => 'red, blue, red' }], result['images']
    assert_equal({}, result['similar'])
    assert_equal 1, @gallery.reads
  end

  def test_search_with_exclusions_only_and_without_query
    response = @client.get('/view/alice/tags/search', params: { 'search_tags' => '--blue' })
    assert_equal [{ 'tags' => 'red, green' }], JSON.parse(response.body)['images']

    response = @client.get('/view/alice/tags/search')
    assert JSON.parse(response.body)['only_search']
    assert_equal 1, @gallery.reads
  end

  def test_search_preserves_bare_tags_and_related_tag_lookup
    @cache.record['similar_tags'] = { 'red' => ['blue'] }
    response = @client.get('/view/alice/tags/search', params: { 'search_tags' => 'red, blue, --green, --unused' })
    result = JSON.parse(response.body)
    assert_equal %w[red blue], result['terms']
    assert_equal ['blue'], result['similar']['red']
    assert_equal [{ 'tags' => 'red, blue, red' }], result['images']
  end

  def test_search_any_terms_can_be_combined_with_required_and_excluded_tags
    @images << { 'tags' => 'yellow, green' }
    response = @client.get('/view/alice/tags/search', params: { 'search_tags' => '||blue, ||green' })
    assert_equal 3, JSON.parse(response.body)['images'].length

    response = @client.get('/view/alice/tags/search', params: { 'search_tags' => '++red, ||blue, ||green, --blue' })
    assert_equal [{ 'tags' => 'red, green' }], JSON.parse(response.body)['images']

    response = @client.get('/view/alice/tags/search', params: { 'search_tags' => 'red, ||yellow' })
    assert_empty JSON.parse(response.body)['images']
  end

  def test_search_escapes_literal_operator_prefixes
    @images << { 'tags' => '||blue, ++red, --green' }
    response = @client.get('/view/alice/tags/search', params: { 'search_tags' => '\\||blue, \\++red, \\--green' })
    assert_equal [{ 'tags' => '||blue, ++red, --green' }], JSON.parse(response.body)['images']
  end

  def test_search_template_uses_normalized_terms_for_related_tags
    scope = Object.new
    def scope.domain_name(*) = 'https://example.test'

    def scope.parse_tags(user:, tag_string:, **) = "[#{tag_string}]"
    scope.instance_variable_set(:@user, 'alice')
    scope.instance_variable_set(:@only_search, false)
    scope.instance_variable_set(:@search_params, '++red, --green')
    scope.instance_variable_set(:@search_params_set, Set['red'])
    scope.instance_variable_set(:@any_tags, Set['green'])
    scope.instance_variable_set(:@similar_tags_set, { 'red' => ['blue'], 'green' => ['yellow'] })
    scope.instance_variable_set(:@images_to_find, [])
    template = File.read(File.expand_path('../views/blog/gallery/view_user_gallery_image_tags_search.html.erb',
                                          __dir__))
    output = ERB.new(template).result(scope.instance_eval { binding })
    assert_includes output, '[blue]'
    assert_includes output, '[yellow]'
    assert_includes output, 'Tag search options'
    assert_includes output, '||blue, ||green'

    scope.instance_variable_set(:@only_search, true)
    output = ERB.new(template).result(scope.instance_eval { binding })
    assert_includes output, 'Tag search options'
    assert_includes output, '\||blue'
  end

  def test_tags_page_documents_search_options
    scope = Object.new
    def scope.domain_name(*) = 'https://example.test'

    scope.instance_variable_set(:@user, 'alice')
    scope.instance_variable_set(:@tags_set, [])
    template = File.read(File.expand_path('../views/blog/gallery/view_user_gallery_image_tags.html.erb', __dir__))
    output = ERB.new(template).result(scope.instance_eval { binding })
    ['Tag search options', 'red, ++blue', '--green', '||blue, ||green', '\||blue', '\++', '\--',
     'Matching is case-sensitive'].each do |text|
      assert_includes output, text
    end
  end

  private

  def tags_response
    response = @client.get('/view/alice/tags')
    assert_equal 200, response.status
    JSON.parse(response.body)
  end
end
