require "treetop"

class ParseError < StandardError; end

class CommandDetails < Treetop::Runtime::SyntaxNode
  def date_range
    if elements.first.respond_to? :start_date
      range = elements.first
      [range.start_date.to_date, range.end_date.to_date]
    else
      date = elements.first.to_date
      [date, date]
    end
  end
  def note
    elements.last.note.text_value
  rescue NoMethodError
    ""
  end
end

class DateLiteral < Treetop::Runtime::SyntaxNode
  def to_date
    Date.strptime "#{text_value}/#{year}", "%m/%d/%Y"
  end
  def year
    elements.last.year.text_value.to_i
  rescue NoMethodError
    Date.today.year
  end
end


base_path = File.expand_path File.dirname(__FILE__)
Treetop.load(File.join base_path, 'grammar.tt')

class Parser

  @@parser = ScheduleParser.new

  def self.parse(data)
    tree = @@parser.parse data.strip

    if tree.nil?
      fail ParseError, "Parse error at offset: #{@@parser.index}"
    end

    tree
  end

end
