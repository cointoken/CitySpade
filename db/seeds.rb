# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
#Account.create({email: 'admin@example.com', password: 'password', role: 'admin'})
#ShowingTimeSlot.find_or_create_by(start_time: Time.parse("10:00").strftime("%I:%M %p"), end_time: Time.parse("12:00").strftime("%I:%M %p"))
#ShowingTimeSlot.find_or_create_by(start_time: Time.parse("12:00").strftime("%I:%M %p"), end_time: Time.parse("14:00").strftime("%I:%M %p"))
#ShowingTimeSlot.find_or_create_by(start_time: Time.parse("14:00").strftime("%I:%M %p"), end_time: Time.parse("17:00").strftime("%I:%M %p"))

#Language.find_or_create_by(name: "English")
#Language.find_or_create_by(name: "Chinese Mandarin")
#Language.find_or_create_by(name: "Korean")

ny_univ = "Fordham University,Pace University, New York Institute of Technology,Baruch College,Adelphi University,Stoneybrook Unversity,Stevens Institue of Technology, Rutgers University,Cornell University,The city university of New York,Fashion Institute of Technology,School of Visual Arts, Hofstra University, Juilliard School, Parsons School of Design, Hunter College, Brooklyn College"
ny_arr = ny_univ.split(",")

ny_arr.each do |univ|
  univ = univ.strip
  TransportPlace.find_or_create_by(name: univ, formatted_address: univ, place_type: "College")
end

il_univs = "University of Illinois Urbana-Champaign, Chicago State University,  University of Illinois at Chicago,Roosevlet University,Illinois Institute of Technology,Depaul University,Loyola University,Nothwestern University"
il_arr = il_univs.split(",")

il_arr.each do |univ|
  univ = univ.strip
  TransportPlace.find_or_create_by(name: univ, formatted_address: "#{univ}, illinois", place_type: "College")
end

pa_univs = "Temple University, Philadelphia University"
pa_arr = pa_univs.split(",")

pa_arr.each do |univ|
  univ = univ.strip
  TransportPlace.find_or_create_by(name: univ, formatted_address: "#{univ}, pennsylvania", place_type: "College")
end

tx_univs = "Rice University,University of Houston,Baylor College of Medicine,Texas Southern University,The University of Texas at Dallas"
tx_arr = tx_univs.split(",")

tx_arr.each do |univ|
  univ = univ.strip
  TransportPlace.find_or_create_by(name: univ, formatted_address: "#{univ}, texas", place_type: "College")
end

dc_univs = "American University,George Washington University,Johns Hopkins University,University of Maryland,Georgetown University,University of Pittsburgh, George Mason University"
dc_arr = dc_univs.split(",")

dc_arr.each do |univ|
  univ = univ.strip
  TransportPlace.find_or_create_by(name: univ, formatted_address: "#{univ}", place_type: "College")
end

ca_univs = "University of Southern California,Univeristy of California-Los Angeles,Santa Monica College,University of California-Irvine, University of California-San Diego, University of California-Santa Barbara,Loyola Marymount University,Passadena City College,Pepperdine University,Orange Coast College,Irvine Valley College,San Diego State University,Standford University, San Jose State University,University of California-Berkeley,San Francisco State University, University of California-Riverside"

ca_arr = ca_univs.split(",")

ca_arr.each do |univ|
  univ = univ.strip
  TransportPlace.find_or_create_by(name: univ, formatted_address: "#{univ}", place_type: "College")
end

ma_univs = "Boston University, Boston College, Suffolk University, Tufts University, University of Massachusetts Boston, Berkely College of Music, Brandeis University, Bentley University, Babson University"

ma_arr = ma_univs.split(",")

ma_arr.each do |univ|
  univ = univ.strip
  TransportPlace.find_or_create_by(name: univ, formatted_address: "#{univ}", place_type: "College")
end

wo_univs = "Clark University, Holy Cross College, Worcester Polytechnic Institute"

wo_arr = wo_univs.split(",")

wo_arr.each do |univ|
  univ = univ.strip
  TransportPlace.find_or_create_by(name: univ, formatted_address: "#{univ} Worcester", place_type: "College")
end
