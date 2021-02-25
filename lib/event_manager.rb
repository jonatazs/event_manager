
require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'

def clean_zipcode(zipcode)
  #zipcode.to_s.rjust(5,"0")[0..4]
  if zipcode.nil?
    '00000'
  elsif zipcode.length < 5
    zipcode.rjust(5, '0')
  elsif zipcode.length > 5
    zipcode[0..4]
  else
    zipcode
  end
end

def clean_phone_number(phone_number)
  phone_number.gsub!(/[^\d]/,'')
 if phone_number.length==10
   phone_number
 elsif phone_number.length == 11 && phone_number[0] == "1"
   phone_number[1..10]
 else
   nil
 end
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exists?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def get_hour(datetime)
  datetime = DateTime.strptime(datetime, '%m/%d/%Y %H:%M')
  datetime.hour
end

def get_day(datetime)
  datetime = DateTime.strptime(datetime, '%m/%d/%Y %H:%M')
  datetime.wday
end

def frequency(array)

  for item in array.max_by do
    array.count(item)  
  end
  #array.max_by{|item| array.count(item)} 
end





puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

days = {'0' => 'Monday', '1' => 'Tuesday', '2' => 'Wednesday', '3' => 'Thursday',
'4' => 'Friday', '5' => 'Saturday', '6' => 'Sunday'}
hours = []
day_list = []


contents.each do |row|
  id = row[0]
  name = row[:first_name]
  number = clean_phone_number(row[:homephone])
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)
  hour = get_hour(row[:regdate])
  day = get_day(row[:regdate])
  hours << hour
  day_list << day
  form_letter = erb_template.result(binding)
  save_thank_you_letter(id,form_letter)
end

number_to_day = days["#{frequency(day_list)}"]
puts "Most common registration time/day: #{frequency(hours)}:00 hrs / #{number_to_day}."