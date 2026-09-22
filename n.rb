# frozen_string_literal: true
# rubocop:disable all
# nerit_batteries.rb
require 'set'
require 'json'
require 'fileutils'
require 'open3'

class Nerit
  # ----- Trit -----
  class Trit
    DOMAIN = [:x, :y, :z].freeze
    TOP = Set.new(DOMAIN)

    attr_reader :set
    def initialize(set)
      @set = set.to_set & TOP
    end

    def self.parse(lit) # "n.<x|y|z>"
      inner = lit[3..-2] || ""
      return Trit.new(Set.new) if inner.empty?
      Trit.new(inner.split('|').map!(&:to_sym))
    end

    def self.from_symbol(sym)
      case sym
      when :x then Trit.new([:x])
      when :y then Trit.new([:y])
      when :z then Trit.new([:z])
      else nil
      end
    end

    def self.from_pipe_string(str)
      return nil unless str.is_a?(String)
      return nil unless str.match?(/\A[xyz](?:\|[xyz])*\z/)
      Trit.new(str.split('|').map! { |s| s.to_sym })
    end

    def |(o) Trit.new(set | o.set) end
    def &(o) Trit.new(set & o.set) end
    def ^(o) Trit.new((set - o.set) | (o.set - set)) end
    def ~@
      Trit.new(TOP - set)
    end

    def include?(sym)
      set.include?(sym)
    end

    def empty?
      set.empty?
    end

    def rot
      map = { x: :y, y: :z, z: :x }
      Trit.new(set.map { |s| map[s] })
    end
    def succ = rot
    def pred
      map = { x: :z, z: :y, y: :x }
      Trit.new(set.map { |s| map[s] })
    end

    def tri_add(k)
      k = k.to_i % 3
      t = self
      k.times { t = t.succ }
      t
    end

    def to_i
      return 0 if set == Set[:x]
      return 1 if set == Set[:y]
      return 2 if set == Set[:z]
      return 1 if set.empty? # documented neutral fallback
      order = { x: 0, y: 1, z: 2 }
      order[set.min_by { |s| order[s] }]
    end

    def to_s
      elems = set.to_a.map!(&:to_s)
      "n.<#{elems.join("|")}>"
    end
  end

  # ----- Values -----
  Opaque = Struct.new(:ruby)
  KwPair = Struct.new(:k, :v)

  # ----- Lexer -----
  TOKEN = /
    n\.<[xyz](?:\|[xyz])*> |         # trit literal
    fn|return|let|mut|if|else|while|for|in|match|
    true|false|
    syscall|:ruby|
    ->|\.\.|==|!=|<=|>=|\|\||&&|\^|~|\?|     # multi-char ops and ?
    [{}(),;=+\-*\/%<>:&

\[\]

] |               # single-char symbols
    "(?:\\.|[^"])*" |                        # string literal
    [A-Za-z_]\w* | \d+                       # identifiers and numbers
  /x

  def tokenize(code)
    code
      .gsub(/\/\/.*$/, '')
      .scan(TOKEN)
      .map!(&:strip)
  end

  # ----- Parser -----
  def parse(code)
    @ts = tokenize(code)
    nodes = []
    until eof?
      if peek == 'fn'
        nodes << parse_fn
      else
        raise error("toplevel must be fn")
      end
    end
    nodes
  end

  def parse_fn
    expect('fn'); name = ident
    expect('('); args = []
    unless peek == ')'
      loop do
        an = ident; expect(':'); at = ident
        args << [an, at]
        break if peek == ')'
        expect(',')
      end
    end
    expect(')')
    expect('->'); _ret = ident
    body = parse_block
    { type: :fn, name: name, args: args, body: body }
  end

  def parse_block
    expect('{')
    stmts = []
    until peek == '}'
      stmts << parse_stmt
    end
    expect('}')
    { type: :block, stmts: stmts }
  end

  def parse_stmt
    case peek
    when 'let' then parse_let
    when 'return'
      next_tok
      e = parse_expr
      semi
      { type: :return, expr: e }
    when 'if'    then parse_if
    when 'while' then parse_while
    when 'for'   then parse_for
    when 'match'
      e = parse_match
      semi_opt
      { type: :expr, expr: e }
    else
      if lookahead_assign?
        name = ident
        expect('=')
        e = parse_expr
        semi
        { type: :assign, name: name, expr: e }
      else
        e = parse_expr
        semi
        { type: :expr, expr: e }
      end
    end
  end

  def parse_let
    expect('let')
    mut = false
    if peek == 'mut'
      mut = true
      next_tok
    end
    name = ident
    ty = nil
    if peek == ':'
      next_tok
      ty = ident
    end
    expect('=')
    e = parse_expr
    semi
    { type: :let, name: name, mut: mut, ty: ty, expr: e }
  end

  def parse_if
    expect('if'); expect('('); c = parse_expr; expect(')')
    tb = parse_block
    eb = nil
    if peek == 'else'
      next_tok
      eb = (peek == '{') ? parse_block : parse_if
    end
    { type: :if, cond: c, then: tb, else: eb }
  end

  def parse_while
    expect('while'); expect('('); c = parse_expr; expect(')'); b = parse_block
    { type: :while, cond: c, body: b }
  end

  def parse_for
    expect('for'); expect('('); it = ident; expect('in'); a = parse_expr; expect('..'); b = parse_expr; expect(')')
    body = parse_block
    { type: :desugared_for, var: it, a: a, b: b, body: body }
  end

  def parse_match
    expect('match')
    e = parse_expr
    expect('{')
    arms = []
    until peek == '}'
      pat = parse_pattern
      expect('=>')
      rhs = parse_expr
      comma_opt
      arms << [pat, rhs]
    end
    expect('}')
    { type: :match, expr: e, arms: arms }
  end

  def parse_pattern
    if peek == '_'
      next_tok
      return { type: :pat_any }
    end
    tok = peek
    if tok =~ /\A\d+\z/
      return { type: :pat_int, val: next_tok.to_i }
    elsif tok.start_with?('n.<')
      return { type: :pat_tri, set: Trit.parse(next_tok).set }
    else
      raise error("pattern")
    end
  end

  # Precedence climbing
  def parse_expr     ; parse_or    end
  def parse_or
    l = parse_and
    while peek == '||'
      next_tok; r = parse_and
      l = bin('||', l, r)
    end
    l
  end
  def parse_and
    l = parse_bitor
    while peek == '&&'
      next_tok; r = parse_bitor
      l = bin('&&', l, r)
    end
    l
  end
  def parse_bitor
    l = parse_bitxor
    while peek == '|'
      next_tok; r = parse_bitxor
      l = bin('|', l, r)
    end
    l
  end
  def parse_bitxor
    l = parse_bitand
    while peek == '^'
      next_tok; r = parse_bitand
      l = bin('^', l, r)
    end
    l
  end
  def parse_bitand
    l = parse_eq
    while peek == '&'
      next_tok; r = parse_eq
      l = bin('&', l, r)
    end
    l
  end
  def parse_eq
    l = parse_rel
    while %w[== !=].include?(peek)
      op = next_tok; r = parse_rel
      l = bin(op, l, r)
    end
    l
  end
  def parse_rel
    l = parse_add
    while %w[< <= > >=].include?(peek)
      op = next_tok; r = parse_add
      l = bin(op, l, r)
    end
    l
  end
  def parse_add
    l = parse_mul
    while %w[+ -].include?(peek)
      op = next_tok; r = parse_mul
      l = bin(op, l, r)
    end
    l
  end
  def parse_mul
    l = parse_unary
    while %w[* / %].include?(peek)
      op = next_tok; r = parse_unary
      l = bin(op, l, r)
    end
    l
  end
  def parse_unary
    if peek == '!'
      next_tok
      return { type: :un, op: '!', expr: parse_unary }
    end
    if peek == '~'
      next_tok
      return { type: :un, op: '~', expr: parse_unary }
    end
    parse_postfix
  end

  def parse_postfix
    e = parse_primary
    loop do
      case peek
      when '('
        next_tok
        args = []
        unless peek == ')'
          loop do
            args << parse_expr
            break if peek == ')'
            expect(',')
          end
        end
        expect(')')
        e = { type: :call, callee: e, args: args }
      when '?'
        next_tok
        sym = ident
        unless %w[x y z].include?(sym)
          raise error("expected x|y|z after ?")
        end
        e = { type: :tri_has, expr: e, sym: sym.to_sym }
      else
        break
      end
    end
    e
  end

  def parse_primary
    tok = next_tok
    case tok
    when '('
      e = parse_expr; expect(')'); e
    when '['
      # array literal
      arr = []
      unless peek == ']'
        loop do
          arr << parse_expr
          break if peek == ']'
          expect(',')
        end
      end
      expect(']')
      { type: :array, elems: arr }
    when /\A\d+\z/
      { type: :int, val: tok.to_i }
    when /\A"(?:\\.|[^"])*"\z/
      { type: :str, val: tok[1..-2] }
    when 'true'
      { type: :bool, val: true }
    when 'false'
      { type: :bool, val: false }
    when 'syscall'
      expect(':ruby'); expect(',')
      tgt = string
      args = []
      while peek == ','
        next_tok
        args << parse_expr
      end
      { type: :syscall, target: tgt, args: args }
    when /\An\.<[xyz](?:\|[xyz])*>/
      { type: :tri, set: Trit.parse(tok).set }
    when /\A[A-Za-z_]\w*\z/
      { type: :var, name: tok }
    else
      raise error("primary")
    end
  end

  def bin(op, l, r) { type: :bin, op: op, left: l, right: r } end
  def string
    s = next_tok
    raise error("string") unless s[0] == '"'
    s[1..-2]
  end

  # ----- Helpers: token stream -----
  def peek      = @ts[0]
  def next_tok  = @ts.shift
  def eof?      = @ts.empty?
  def expect(x)
    t = next_tok
    raise error("expected #{x}, got #{t.inspect}") unless t == x
    t
  end
  def semi     ; expect(';') end
  def semi_opt ; semi if peek == ';' end
  def comma_opt; expect(',') if peek == ',' end
  def ident
    t = next_tok
    raise error("ident") unless t =~ /\A[A-Za-z_]\w*\z/
    t
  end
  def lookahead_assign?
    @ts[0] =~ /\A[A-Za-z_]\w*\z/ && @ts[1] == '='
  end
  def error(msg) "ParseError: #{msg} at #{(@ts[0..5] || []).inspect}" end

  # ----- Interpreter -----
  Return = Struct.new(:val)

  def run(code)
    ast = parse(code)
    @funcs = {}
    ast.each { |n| @funcs[n[:name]] = n }
    res = call_fn('main', [])
    res
  end

  def call_fn(name, args)
    fn = @funcs[name] or raise "No function #{name}"
    env = {}
    fn[:args].each_with_index { |(an, _ty), i| env[an] = { val: args[i], mut: false } }
    r = exec_block(env, fn[:body])
    r.is_a?(Return) ? r.val : r
  end

  def exec_block(env, blk)
    blk[:stmts].each do |s|
      r = exec_stmt(env, s)
      return r if r.is_a?(Return)
    end
    0
  end

  def exec_stmt(env, s)
    case s[:type]
    when :let
      val = eval_expr(env, s[:expr])
      env[s[:name]] = { val: val, mut: s[:mut] }
    when :assign
      slot = env[s[:name]] or raise "Unbound #{s[:name]}"
      raise "Immutable #{s[:name]}" unless slot[:mut]
      slot[:val] = eval_expr(env, s[:expr])
    when :return
      Return.new(eval_expr(env, s[:expr]))
    when :if
      if truthy(eval_expr(env, s[:cond]))
        r = exec_block(env.dup, s[:then]); return r if r.is_a?(Return)
      elsif s[:else]
        r = s[:else][:type] == :block ? exec_block(env.dup, s[:else]) : exec_stmt(env, s[:else])
        return r if r.is_a?(Return)
      end
    when :while
      while truthy(eval_expr(env, s[:cond]))
        r = exec_block(env.dup, s[:body]); return r if r.is_a?(Return)
      end
    when :desugared_for
      a = eval_expr(env, s[:a]); b = eval_expr(env, s[:b])
      env[s[:var]] = { val: a, mut: true }
      while env[s[:var]][:val] < b
        r = exec_block(env.dup, s[:body]); return r if r.is_a?(Return)
        env[s[:var]][:val] += 1
      end
    when :expr
      eval_expr(env, s[:expr])
    else
      raise "stmt #{s[:type]}"
    end
  end

  def truthy(v)
    case v
    when Trit then v.set.include?(:y) || v.set.include?(:z)
    else !!v
    end
  end

  def eval_expr(env, e)
    case e[:type]
    when :int  then e[:val]
    when :str  then interpolate(env, e[:val])
    when :bool then e[:val]
    when :var  then (env[e[:name]] or raise "Unbound #{e[:name]}")[:val]
    when :array then e[:elems].map { |el| eval_expr(env, el) }
    when :tri  then Trit.new(e[:set])
    when :un
      v = eval_expr(env, e[:expr])
      case e[:op]
      when '!' then !truthy(v)
      when '~' then v.is_a?(Trit) ? ~v : (raise "Bad ~ for non-trit")
      else raise "un #{e[:op]}"
      end
    when :bin
      l = eval_expr(env, e[:left]); r = eval_expr(env, e[:right])
      case e[:op]
      when '+'  then l + r
      when '-'  then l - r
      when '*'  then l * r
      when '/'  then l / r
      when '%'  then l % r
      when '==' then eq(l, r)
      when '!=' then !eq(l, r)
      when '<'  then l < r
      when '<=' then l <= r
      when '>'  then l > r
      when '>=' then l >= r
      when '&&' then truthy(l) && truthy(r)
      when '||' then truthy(l) || truthy(r)
      when '&'  then tri_op(l, r, :&)
      when '|'  then tri_op(l, r, :|)
      when '^'  then tri_op(l, r, :^)
      else raise "op #{e[:op]}"
      end
    when :call
      cal = e[:callee]
      if cal[:type] == :var
        name = cal[:name]
        args = e[:args].map { |a| eval_expr(env, a) }
        return call_builtin(name, args) if builtin?(name)
        return call_fn(name, args)
      else
        raise "Unsupported callee"
      end
    when :tri_has
      v = eval_expr(env, e[:expr])
      raise "t?x needs tri" unless v.is_a?(Trit)
      v.include?(e[:sym])
    when :match
      val = eval_expr(env, e[:expr])
      e[:arms].each do |(pat, rhs)|
        if match_pat?(val, pat)
          return eval_expr(env, rhs)
        end
      end
      raise "non-exhaustive match"
    when :syscall
      tgt = e[:target]
      args = e[:args].map { |a| eval_expr(env, a) }
      marshal_in(call_ruby(tgt, args))
    else
      raise "expr #{e[:type]}"
    end
  end

  def eq(l, r)
    if l.is_a?(Trit) && r.is_a?(Trit)
      l.set == r.set
    else
      l == r
    end
  end

  def match_pat?(val, pat)
    case pat[:type]
    when :pat_any then true
    when :pat_int then val == pat[:val]
    when :pat_tri then val.is_a?(Trit) && val.set == pat[:set]
    else false
    end
  end

  def tri_op(l, r, op)
    if l.is_a?(Trit) && r.is_a?(Trit)
      return l.send(op, r)
    end
    raise "tri op #{op} needs trits"
  end

  # ----- Builtins: batteries included -----
  def builtin?(name)
    %w[
      rot succ pred is_empty mask tri_add to_int
      kw rb rb_new rb_call rb_const rb_send
      env_get env_set read_file write_file append_file file_exists mkdir_p rm_rf
      sh run time_now sleep_ms json_parse json_dump
    ].include?(name)
  end

  def call_builtin(name, args)
    case name
    # tri
    when 'rot'      then ensure_trit(args[0]).rot
    when 'succ'     then args[0].is_a?(Trit) ? args[0].succ : args[0] + 1
    when 'pred'     then args[0].is_a?(Trit) ? args[0].pred : args[0] - 1
    when 'is_empty' then ensure_trit(args[0]).empty?
    when 'mask'     then ensure_trit(args[0]) & ensure_trit(args[1])
    when 'tri_add'  then ensure_trit(args[0]).tri_add(args[1])
    when 'to_int'   then args[0].is_a?(Trit) ? args[0].to_i : args[0].to_i

    # keyword args builder
    when 'kw'       then KwPair.new(args[0].to_s, args[1])

    # general Ruby bridges
    when 'rb'
      path = args[0].to_s
      pos, kw = split_pos_kw(args[1..])
      marshal_in(call_ruby(path, pos, kw: kw))
    when 'rb_new'
      kpath = args[0].to_s
      pos, kw = split_pos_kw(args[1..])
      marshal_in(call_ruby("#{kpath}.new", pos, kw: kw))
    when 'rb_const' then marshal_in(resolve_const(args[0].to_s))
    when 'rb_call'
      recv = unwrap_opaque(args[0])
      m    = args[1].to_s
      pos, kw = split_pos_kw(args[2..])
      marshal_in(recv.public_send(m, *marshal_out_list(pos), **kw))
    when 'rb_send'
      path = args[0].to_s
      pos, kw = split_pos_kw(args[1..])
      marshal_in(call_ruby(path, pos, kw: kw))

    # env + io + fs + process + time + json
    when 'env_get'    then ENV[args[0].to_s]
    when 'env_set'    then ENV[args[0].to_s] = args[1].to_s
    when 'read_file'  then File.read(args[0].to_s)
    when 'write_file' then File.write(args[0].to_s, args[1].to_s)
    when 'append_file'then File.open(args[0].to_s, 'a') { |f| f << args[1].to_s; f.flush; f.sync }
    when 'file_exists'then File.exist?(args[0].to_s)
    when 'mkdir_p'    then FileUtils.mkdir_p(args[0].to_s)
    when 'rm_rf'      then FileUtils.rm_rf(args[0].to_s)
    when 'sh'
      cmd = args[0].to_s
      out, err, status = Open3.capture3(cmd)
      { 'out' => out, 'err' => err, 'status' => status.exitstatus }
    when 'run'
      ok = system(args[0].to_s)
      ok ? 0 : 1
    when 'time_now'   then Time.now.to_f
    when 'sleep_ms'   then sleep(args[0].to_f / 1000.0)
    when 'json_parse' then JSON.parse(args[0].to_s)
    when 'json_dump'  then JSON.dump(args[0])
    else
      raise "unknown builtin #{name}"
    end
  end

  def split_pos_kw(args)
    pos = []
    kw = {}
    (args || []).each do |a|
      if a.is_a?(KwPair)
        kw[a.k.to_sym] = marshal_out(a.v)
      else
        pos << a
      end
    end
    [pos, kw]
  end

  def ensure_trit(v)
    raise "expected tri" unless v.is_a?(Trit)
    v
  end

  def interpolate(env, s)
    s.gsub(/\#\{([A-Za-z_]\w*)\}/) do
      name = Regexp.last_match(1)
      (env[name] or raise "Unbound #{name}")[:val].to_s
    end
  end

  # ----- Syscall plumbing -----
  def marshal_out(v)
    case v
    when Trit
      if v.set.size == 1
        v.set.first
      else
        v.set.to_a.map!(&:to_s).sort.join('|')
      end
    when Opaque then v.ruby
    else
      v
    end
  end

  def marshal_out_list(arr)
    (arr || []).map { |a| marshal_out(a) }
  end

  def marshal_in(v)
    case v
    when Trit then v
    when Symbol
      Trit.from_symbol(v) || Opaque.new(v)
    when String
      tri = Trit.from_pipe_string(v)
      tri || v
    when Integer, Float, TrueClass, FalseClass
      v
    when Array
      v
    when Hash
      v
    else
      Opaque.new(v)
    end
  end

  def unwrap_opaque(v)
    v.is_a?(Opaque) ? v.ruby : v
  end

  def resolve_const(path)
    path.split('::').inject(Object) { |o, c| o.const_get(c) }
  end

  # Supports:
  # - "Kernel.puts"
  # - "Time.now"
  # - "File::Stat.new" (constructor)
  # - ".upcase" => instance method; first arg must be receiver
  # Keyword args via KwPair
  def call_ruby(target, args, kw: {})
    if target.start_with?('.')
      m = target[1..-1]
      raise "instance call needs receiver" if args.nil? || args.empty?
      recv = unwrap_opaque(args.shift)
      return recv.public_send(m, *marshal_out_list(args), **kw)
    end

    if target.end_with?('.new')
      kpath = target.sub(/\.new\z/, '')
      klass = resolve_const(kpath)
      return klass.new(*marshal_out_list(args), **kw)
    end

    modpath, mname = target.split('.', 2)
    mod = resolve_const(modpath)
    if mname.nil?
      return mod
    end
    mod.public_send(mname, *marshal_out_list(args), **kw)
  end
end

# ---- Demo ----
if __FILE__ == $0
  code = <<~NERIT
    fn classify(t: tri) -> i64 {
      match t {
        n.<x> => 0,
        n.<y> => 1,
        n.<z> => 2,
        _     => 9
      };
    }

    fn main() -> i64 {
      let t: tri = n.<x|z>;
      syscall :ruby, "Kernel.puts", "t=#{t}";
      let u: tri = rot(t) & n.<y|z>;
      syscall :ruby, "Kernel.puts", "u=#{u}";
      let k: i64 = to_int(u);
      syscall :ruby, "Kernel.puts", "k=#{k}";

      // Batteries: env, file, time, json, processes
      syscall :ruby, "Kernel.puts", env_get("HOME");
      write_file("nerit_tmp.txt", "hello");
      let exists = file_exists("nerit_tmp.txt");
      syscall :ruby, "Kernel.puts", "exists=#{exists}";
      append_file("nerit_tmp.txt", "\\nworld");
      let txt = read_file("nerit_tmp.txt");
      syscall :ruby, "Kernel.puts", txt;

      let now = time_now();
      syscall :ruby, "Kernel.puts", "now=#{now}";
      let j = json_dump([1,2,3]);
      syscall :ruby, "Kernel.puts", j;
      let arr = json_parse("[4,5,6]");
      syscall :ruby, "Kernel.puts", rb(".join", arr, kw("sep", "-"));

      // General Ruby bridge with keywords
      syscall :ruby, "Kernel.puts", rb("Math.sqrt", 144);
      let up = rb(".upcase", "hey");
      syscall :ruby, "Kernel.puts", up;
      let st = rb_new("File::Stat", "nerit_tmp.txt");
      syscall :ruby, "Kernel.puts", rb_call(st, "size");

      // Ternary branching
      let decision = if (u?y) { 10 } else { 20 };
      syscall :ruby, "Kernel.puts", "decision=#{decision}";

      // Loop and match
      let mut s: i64 = 0;
      for (i in 0..5) {
        s = s + classify(rot(n.<x|y|z>));
      }

      // Clean up
      rm_rf("nerit_tmp.txt");

      s
    }
  NERIT

  puts Nerit.new.run(code)
end
