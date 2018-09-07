require 'spec_helper'
describe Spider::Improve::Agent do
  context "improve agent detail" do
    it 'Spider::Improve::Agent#corcoran' do
      agent = Agent.where("email like ? and website is not null and website != ?", "%@corcoran.com%", "").first
      doc = Nokogiri::HTML RestClient.get(agent.try(:website) || 'http://www.corcoran.com/nyc/Agents/Display/1513?tIndividualOnly=True')
      obj = {}
      Spider::Improve::Agent.corcoran doc, obj
      p obj
      obj[:name].present?.should == true
      obj[:email].include?("@").should == true
      obj[:introduction].present?.should == true
      [:office_tel, :fax_tel].each do |attr|
        if obj[attr]
          (!!(obj[attr] =~ /^\d/) && (obj[attr].size >= 9 && obj[attr].size < 12)).should == true
        end
      end
    end

    it 'Spider::Improve::Agent#aptsandlofts' do
      agent = Agent.where("email like ? and website is not null and website != ?", "%@aptsandlofts.com%", "").first
      doc = Nokogiri::HTML RestClient.get(agent.try(:website) ||
                                          'http://www.aptsandlofts.com/about-us/brooklyn-real-estate-agents/christopher-w-havens-licensed-associate-broker-commercial-division')
      obj = {}
      Spider::Improve::Agent.aptsandlofts doc, obj
      p obj
      obj[:name].present?.should == true
      obj[:email].include?("@").should == true
      obj[:introduction].present?.should == true
      [:office_tel, :fax_tel].each do |attr|
        if obj[attr]
          (!!(obj[attr] =~ /^\d/) && (obj[attr].size >= 9 && obj[attr].size < 12)).should == true
        end
      end
    end

    it 'Spider::Improve::Agent#elliman' do
      agent = Agent.where("email like ? and website is not null and website != ?", "%@elliman.com%", "").first
      doc = Nokogiri::HTML RestClient.get(agent.try(:website) ||
                                          'http://www.elliman.com/real-estate-agent/edilyn-abeleda/4224'
                                          )
      obj = {}
      Spider::Improve::Agent.elliman doc, obj
      p obj
      obj[:name].present?.should == true if obj[:name].present?
      obj[:email].include?("@").should == true if obj[:email].present?
      obj[:introduction].present?.should == true if agent.try(:website) and agent.website.include?("theeklundgomesteam.elliman.com")
      [:office_tel, :fax_tel].each do |attr|
        if obj[attr]
          (!!(obj[attr] =~ /^\d/) && (obj[attr].size >= 9 && obj[attr].size < 12)).should == true
        end
      end
    end

    it 'Spider::Improve::Agent#kwnyc' do
      agent = Agent.where("email like ? and website is not null and website != ?", "%@kwnyc.com%", "").first
      doc = Nokogiri::HTML RestClient.get(agent.try(:website) ||
                                          'http://kwnyc.com/avi-malul' )
      obj = {}
      Spider::Improve::Agent.kwnyc doc, obj
      p obj
      obj[:name].present?.should == true
      obj[:email].include?("@").should == true
      obj[:introduction].present?.should == true
      [:office_tel, :fax_tel].each do |attr|
        if obj[attr]
          (!!(obj[attr] =~ /^\d/) && (obj[attr].size >= 9 && obj[attr].size < 12)).should == true
        end
      end
    end

    it 'Spider::Improve::Agent#halstead' do
      agent = Agent.where("email like ? and website is not null and website != ?", "%@halstead.com%", "").first
      doc = Nokogiri::HTML RestClient.get(agent.try(:website) ||
                                          'http://www.halstead.com/real-estate-agent/rachelle-nacht-carmack'
                                         )
      obj = {}
      Spider::Improve::Agent.halstead doc, obj
      obj[:name].present?.should == true
      obj[:email].include?("@").should == true
      obj[:introduction].present?.should == true
      [:office_tel, :fax_tel].each do |attr|
        if obj[attr]
          (!!(obj[attr] =~ /^\d/) && (obj[attr].size >= 9 && obj[attr].size < 12)).should == true
        end
      end
    end

    it 'Spider::Improve::Agent#citihabitats' do
      agent = Agent.where("email like ? and website is not null and website != ?", "%@citihabitats.com%", "").first
      doc = Nokogiri::HTML RestClient.get(agent.try(:website) ||
                                          'http://www.citi-habitats.com/real-estate-agents/profiles/Jeandy-Cabral-309531'
                                         )
      obj = {}
      Spider::Improve::Agent.citihabitats doc, obj
      obj[:name].present?.should == true
      obj[:email].include?("@").should == true if agent[:email].blank?
      obj[:introduction].present?.should == true
      [:office_tel, :fax_tel].each do |attr|
        if obj[attr]
          (!!(obj[attr] =~ /^\d/) && (obj[attr].size >= 9 && obj[attr].size < 12)).should == true
        end
      end
    end

    it 'Spider::Improve::Agent#mns' do
      agent = Agent.where("email like ? and website is not null and website != ?", "%@mns.com%", "").first
      doc = Nokogiri::HTML RestClient.get(agent.try(:website) ||
                                          'http://www.mns.com/agents/mbebenek'
                                         )
      obj = {}
      Spider::Improve::Agent.mns doc, obj
      obj[:name].present?.should == true
      obj[:email].include?("@").should == true
      obj[:introduction].present?.should == true
      [:office_tel, :fax_tel].each do |attr|
        if obj[attr]
          (!!(obj[attr] =~ /^\d/) && (obj[attr].size >= 9 && obj[attr].size < 12)).should == true
        end
      end
    end

    it 'Spider::Improve::Agent#bhsus' do
      agent = Agent.where("email like ? and website is not null and website != ?", "%@bhsuss.com%", "").first
      doc = Nokogiri::HTML RestClient.get(agent.try(:website) ||
                                          'http://www.bhsusa.com/real-estate-agent/diane-abrams')
      obj = {}
      if doc
        Spider::Improve::Agent.bhsusa doc, obj
        obj[:name].present?.should == true if agent && agent[:name].blank?
        obj[:email].include?("@").should == true if agent && agent[:email].blank?
        obj[:introduction].present?.should == true
        [:office_tel, :fax_tel].each do |attr|
          if obj[attr]
            (!!(obj[attr] =~ /^\d/) && (obj[attr].size >= 9 && obj[attr].size < 12)).should == true
          end
        end
      end
    end

    it 'Spider::Improve::Agent#nestseekers' do
      agent = Agent.where("email like ? and website is not null and website != ?", "%@nestseekers.com%", "").first
      doc = Nokogiri::HTML RestClient.get(agent.try(:website) ||
                                          'https://www.nestseekers.com/agent/marija-petrovic'
                                         )
      obj = {}
      Spider::Improve::Agent.nestseekers doc, obj
      obj[:name].present?.should == true
      obj[:email].include?("@").should == true if agent[:email].blank?
      obj[:introduction].present?.should == true
      [:office_tel, :fax_tel].each do |attr|
        if obj[attr]
          (!!(obj[attr] =~ /^\d/) && (obj[attr].size >= 9 && obj[attr].size < 12)).should == true
        end
      end
    end

    it 'Spider::Improve::Agent#townrealestate' do
      agent = Agent.where("email like ? and website is not null and website != ?", "%@townrealestate.com%", "").first
      doc = Nokogiri::HTML RestClient.get(agent.try(:website) ||
                                          'http://www.townrealestate.com/representatives/steven-gold-804/'
                                         )
      obj = {}
      Spider::Improve::Agent.townrealestate doc, obj
      p obj
      obj[:name].present?.should == true
      obj[:email].include?("@").should == true
      obj[:introduction].present?.should == true
      [:office_tel, :fax_tel].each do |attr|
        if obj[attr]
          (!!(obj[attr] =~ /^\d/) && (obj[attr].size >= 9 && obj[attr].size < 12)).should == true
        end
      end
    end
  end
end
