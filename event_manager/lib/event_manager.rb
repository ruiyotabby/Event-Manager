require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'

puts 'Event manager initialized'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone_number(phone)
  phone = phone.split(/\D/).join
  if phone.length == 10
    phone
  elsif phone.length == 11 && phone[0] == '1'
    phone[1..]
  else
    'bad number'
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

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def get_highest_reg_hour(hours)
  count = hours.reduce(Hash.new(0)) do |count, hour|
    count[hour] += 1
    count
  end
  count.sort_by { |_key, value| -value }.to_h
end

def get_day_of_week(days)
  total = days.reduce(Hash.new(0)) do |total, day|
    total[day] += 1
    total
  end
  total.sort_by{|_k,v| -v}.to_h
end

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter
hours = []
days = []

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  phone = row[:homephone]
  time = row[:regdate]

  zipcode = clean_zipcode(row[:zipcode])

  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  clean_phone_number(phone)

  time = Time.strptime(time, '%m/%d/%y %H:%M')
  hours << time.hour
  days << time.wday

  save_thank_you_letter(id, form_letter)
end
puts "The hours with most registratons are #{get_highest_reg_hour(hours).keys[0]}00 and #{get_highest_reg_hour(hours).keys[1]}00."
print "The days in which most people registered were on the #{get_day_of_week(days).keys[0]}rd and #{get_day_of_week(days).keys[1]}"
puts 'th days of the week'
