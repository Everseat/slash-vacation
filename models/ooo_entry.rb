class OooEntry < Sequel::Model

  def to_s
    type = self.type == "wfh" ? "working from home" : self.type
    date_format = "%B %-d, %Y"
    dates_description = if start_date == end_date
      "on *#{start_date.strftime date_format}*"
    else
      "from *#{start_date.strftime date_format}* to *#{end_date.strftime date_format}*"
    end
    note_formatted = note.blank? ? "" : " (#{note})"
    ">• @#{slack_name} is _#{type}_ #{dates_description}#{note_formatted}"
  end

end
