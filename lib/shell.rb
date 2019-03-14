# frozen_string_literal: true

class Shell
  def initialize
    @shell_context = TOPLEVEL_BINDING
    @input = Input.new
  end

  def run
    print "> "

    Signal.trap("SIGINT") do
      @input.clear
      print "\n> "
      next
    end

    while new_cmd = gets
      @input.append new_cmd

      if new_cmd.chomp === "quit"
        puts "closing..."
        break
      elsif @input.ready_to_evaluate?
        evaluate_input
      end

      print "> "
    end
  end

  def evaluate_input
    print Kernel.eval(@input.value, @shell_context), "\n"
  rescue Exception => err
    print "#{err.class}: #{err.message}\n"
  ensure
    @input.clear
  end
end

class Input
  attr_reader :value

  KEYWORDS_EXPECTING_END = [
    # not exhaustive
    # add some more for full ruby language support
    "class",
    "module",
    "def",
    "begin",
    "do",
    "if",
    "unless",
  ].freeze

  COLLECTION_STARTERS = {
    "[" => "]",
    "{" => "}",
    "(" => ")"
  }.freeze

  def initialize
    @value = ""
  end

  def ready_to_evaluate?
    all_starters_matched? && all_collections_closed?
  end

  def clear
    value = ""
  end

  def append(input)
    @value += input
  end

  private

  def all_starters_matched?
    number_of_ends_in_statement >= expected_number_ends
  end

  def expected_number_ends
    KEYWORDS_EXPECTING_END.sum do |keyword|
      keyword_regex = /(\W|^)#{keyword}(\W|$)/
      @value.scan(keyword_regex).length
    end
  end

  def number_of_ends_in_statement
    @value.scan(/(\W|^)end(\W|$)/).length
  end

  def all_collections_closed?
    COLLECTION_STARTERS.all? do |starter, ender|
      num_starters = @value.scan(/#{"\\" + starter}/).length
      num_enders = @value.scan(/#{"\\" + ender}/).length
      num_starters == num_enders
    end
  end
end

