class Test < ApplicationRecord

  belongs_to :request

  serialize :key
  serialize :value
  serialize :history

  scope :failing, -> { where(:status => false) }
  scope :passing, -> { where(:status => true) }

  def run

    purge_history
  	
    if request.response_body.nil? or request.response_code.nil?
      new_failure = self.new_failure? false
      self.status = false
      add_history false
      self.save
  	  return new_failure
  	end

  	begin
      body = nil
      if request.format == "xml"
        body = Hash.from_xml(request.response_body)
      else
        body = JSON.parse(request.response_body)
      end

      code = request.response_code
      
      #Replace every instance of _body_ with the actual body of the response. 
      #Replace every instance of _code_ with the actual code of the response.
      decoded_key = self.key.gsub('_body_', body.to_s).gsub('_code_', code.to_s)      
      
      result = eval(decoded_key)
      new_status = (result.to_s == value.to_s)
      new_failure = self.new_failure? new_status
      self.status = new_status
      add_history new_status
      self.save
      return new_failure
    rescue
      new_failure = self.new_failure? false
      self.status = false
      add_history false
      self.save
      return new_failure 
    end

  end

  def new_failure? new_status
    if self.status and not new_status
      return true
    else
      return false
    end
  end

  # Delete all history over 2 weeks old 
  # todo: make this 2 weeks a configurable
  def purge_history
    unless history.nil?
      two_weeks_ago = Time.now - 2.weeks
      self.history.delete_if { |x| x[:time] < two_weeks_ago }
      self.save
    end
  end

  def add_history result
    if self.history.nil?
      self.history = []
    end
    self.history << {time: Time.now, result: result}
  end

  def pass_rate
    if history.count == 0
      return 0.0
    end
    # Successes / Total 
    (history.count{ |x| x[:result] == true }).to_f / history.count.to_f
  end

end
