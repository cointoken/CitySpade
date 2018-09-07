# sitemap rake task
#every 1.day, at: "6:00 am", :roles => :app do
  #rake "sitemap:generate"
#end
set :output, "#{path}/log/cron.log"

every 1.day, at: "0:20 am", :roles => :app do
  rake "db:sessions:clean_expired"
end

#every 2.hours, at: "6:15 pm", :roles => :app do
#  rake "douban:posting"
#end
#every 2.day, at: '1:00 am', :roles => :app do
#  runner "Broker.reset_listing_num"
#end

#RUN FLASH SALE EVERY 4 HOURS
#every 4.hour, at: "4:30 am", :roles => :doapp do
#  rake "set:flash_sale"
#  rake "set:set_TFC_featured"
#  rake "set:newport_description"
#end

#Run guarantor rake task every 6 hrs
#every 6.hour, at: "7:30 am", :roles => :app do
#  rake "set:guarantor"
#end

#Run SearchForMe email check everyday
every 1.day, at: "1:20 am", :roles => :app do
  rake "set:email_check"
end

#every 45.minutes, at: "5:30 pm", :roles => :app do
#  rake "cssa:posting"
#end

#every 1.day, at: '7:00 am', :roles => :app do
  #runner "Spider.mls_setup \"Aptsandlofts\""
#end

#every 3.hour, at: '4:15 am', :roles => :app do
#  runner "Spider.feeds_setup \"RealtyMx\""
#end
#
#every 12.hour, at: '10:00 am', :roles => :app do
#  runner "Spider.feeds_setup \"Rentlinx\""
#end
#
#every 5.hour, at: '2:00 am', :roles => :app do
#  runner "Spider.feeds_setup \"Messagekast\""
#end
#
#every 5.hour, at: '2:00 am', :roles => :app do
#  runner "Spider.feeds_setup \"Messagekast\""
#end

#every 4.hour, at: '6:00 am', :roles => :app do
#  runner "Spider.feeds_setup \"Stellarmanagement,Hlresidential,Realtywarp,Anchornyc,Rentrose,
#  AToZ,BrickAndMortar,Olshan,RoyalLivingNYC,WindsorMariners,KeyWorthyLLC,NYVirtualRealtyCorp,Chapin,FurnishedDwellings,NelsonAybar,CitadelProperty,Lalezarian,Dermot,TheCorner,DouglasElliman,KartenLowe,Fiddler,OneAndOnly,Swythe,Galleria,NewYorkHomes,SkyRealEstate,GPSRealty,JackResnick,Parkstone,Nectar,PrimeHome,ArdmoreWinthrop,Gama,AAManagement,Westminster,Rosenyc.LuxuryChicago,Akelius,Estilo,Bedford,FiveStar,KellerWilliams,Fetner,Realtyka,Elanrealty,Buzzer,PerlGroup,HmrProperties,AllAmericanRltyMgt,DansarGroup,ClipperEquities,HomedaxRealestate,KellerWilliamsMidtown,MetropolitanRealty,JpAssociates,Horowitz,DwellChicago,CrumlishRealEstate,DevCoGroup,CarnegieHillProperties,TheMonterey,BohemiaRealty,RenegadeNY,AventanaRealEstate,ArmCapital,InHausLlc,ShorecrestTowers,PerryAssociates,OakTree,Waterton,Resis,GlaProperty,AptAmigo,JcaProperty,VoyeurRealEstate,NovoProperties,IndependentProp,AkeliusRealestate,WingateCompanies,TheRealEstate,SimplyBrooklyn,FifthForever,DrennenRealty,MQPropertyMgmt,LifestyleRealty,GioiaRealty,SpyRLT,IqRealtors,SolarManagement,BlantonTurner,DJKResidential,GothamOrganization,BrennanRealty,CicadaInternational,ExcelsiorRealty,BuchbinderWarren,LoftsAndFlats,Tryax,Caprijetrealty,U2apartment,Hotspot,Promisereal,Glasserreal,Fetnerpropinc,Fountainreal,Pistillireal,Atkinson,Brookblocreal,Peterkinang,Thesuitliber,ListingMule,SJPModern,LaMatto,IstayNY,Pinnacle,UrbanRealEstate,Absolute,WorkLive,AdvantaService,Univreallc,LanReal,Marvereal,Omniman,Voronyc,Davidass,TheWilliams,ExtellMarketing,MontSky,BryanLRRealty,CityWideApts,UESMgmt,SFRent,Relocation,KARealty,Manmiareal,Myhomead,Triview,RYManagement,Kushner,Stonehenge,CityDigs,Dermoteast,Moinian,Azure,Extell,Lovefirstreal,Aveagency,Eliteconn,RealCollect\""
#end

#every 4.hour, at: '7:42 am', :roles => :app do
#  runner "Spider.feeds_setup \"Related,UDR,Siderow,AltasRealty,BoldNewYork,DBaum,ModaRealty,PhillpSalamon,\
#  ResNewYork,DwellResidential,NyCasaGroup,OffsiteLeasing,AviRealty,\
#  Compassrock,Cbreliable,Urbanrealtynyc,Winzonerealty,Lucienperry,\
#  Instratany,FirstServiceResidential,GarfieldRealty,Skylinedevelopers,WorldWideHomes,Pistilli,Benjaminrg,HechtGroup,RosemarkGroup,\
#  Rudin,ExitRealtyKingdom,SkyManagement,UptownFlats,WoodsAssociates,JosephGiordano,YucoManagement,DirectProperties,IanShapolsky,InHouseGroup,EmpireStateProperties,AJM,AlchemyVentures,MetroPlus,AltasRealty,AJClarke,RoomConnect,JackParker,TradeNYC,Concept,BohbotSteven,RedSparrow,Silverstein,WaveRealEstate,AbleRealty,ThorEquities,Albanese,Simone,Jameson,DwellPost,Citinest,Azulay,VillageAcquisition,UrbanApartment,Northwind,Loftey,Fenway,CityView,DeanJacob,JeromeMeyer,IntPropFinder,IanKKatz,HudsonRealEstate,BigSquare,RGC,BetterLiving,DefiantRealty,JRProperties\""
#end

#every 8.hour, at: '8:40 am', :roles => :app do
#  runner "Spider.feeds_setup \"Tfc,Suitely,Spire,RoseAssociates\""
#end

#every 12.hour, at: '7:44 am', :roles => :app do
#  runner "Spider.run \"EquityResidential\""
#end

#every 12.hour, at: '7:33 am', :roles => :app do
#  runner "Spider.run \"AvalonCove\""
#end

#every 12.hour, at: '7:35 am', :roles => :app do
#  runner "Spider.run \"AvalonBay\""
#end

#every 6.hour, at: '8:42 am', :roles => :app do
#  runner "Spider.run \"Glenwood\""
#end

#every 1.hour, at: '8:54 am', :roles => :app do
#  runner "Spider.run \"TwoTree\""
#end

#every 1.hour, at: '8:15 am', :roles => :app do
#  runner "Spider.run \"ForestCity\""
#end

#every 3.hour, at: '8:15 am', :roles => :app do
#  runner "Spider.run \"ManhattanPark\""
#end

#every 6.hour, at: '8:42 am', :roles => :app do
#  runner "Spider.run \"PropertyLink\""
#end

#every 6.hour, at: '8:42 am', :roles => :app do
#  runner "Spider.run \"Securecafe\""
#end

#every 12.hour, at: '8:59 am', :roles => :app do
#  runner "Spider.run \"PhillyBozzuto\""
#end

#every 12.hour, at: '8:56 am', :roles => :app do
#  runner "Spider.run \"BostonBozzuto\""
#end

#every 12.hour, at: '8:58 am', :roles => :app do
#  runner "Spider.run \"AvalonBayBoston\""
#end

#every 23.hour, at: '5:40 am', :roles => :app do
#  runner "Spider.run \"EquityResidentialBoston\""
#end

#every 12.hour, at: '5:59 am', :roles => :app do
#  runner "Spider.run \"ChicagoBozzuto\""
#end

#every 12.hour, at: '5:30 am', :roles => :app do
#  runner "Spider.run \"NestSeekers\""
#end

#every 12.hour, at: '2:59 am', :roles => :app do
#  runner "Spider.run \"ExchangePlace\""
#end

classes = %w{
      CitiHabitats Aptsandlofts Rutenbergrealtyny
      Halstead Corcoran
      Elliman Kwnyc Stribling
      Mns  Townrealestate
      Allandomb Maxwellrealty Phillyapartmentco
      Campionre
      Fenwickkeats NestioGuidancenyc
      Guidancernyc
      Thechicagomls
}
# Sfcommodern Sfrealtors
# Speedhatch
classes.each_with_index do |cls, index|
  am_or_pm = 'am'
  hour = 1  + index
  hour = hour % 24
  if hour >= 12
    hour = hour - 12
    am_or_pm = 'pm'
  end
  every :day, :at => "#{hour}:20 #{am_or_pm}", :roles => :app do
    runner "Spider.run \"#{cls}\""
  end
end
every :hour, at: '1:10 pm' do
  runner "Spider.transit"
end
every :hour, at: '2:20 pm' do
  runner "Spider.cal_transit_score limit: nil"
end
every :day, at: "6:00 am" do
  runner "BrokerLlsStatus.update_datas Day.today - 1.day"
#  runner "Spider.improve_listings"
end
every :day, at: '8:00 am' do
  runner "BrokerLlsStatus.update_datas Date.today - 1.day"
end
every :day, at: '10:00 am' do
  runner "BrokerLlsStatus.update_datas Date.today"
end

#every 1.hours do
#  runner 'Disqus.update'
#end

every :day, at: '0:30' do
  runner "PoliticalArea.fix_nil_political_areas"
end

every :day, at: '23:30' do
  runner "Listing.recal_score_price_for_except_nyc"
end

every :day, at: '2:00 am' do
  runner "ListingImage.reupload_if(s3_url: nil)"
end

every 2.hours do
  runner "MlsInfo.fix_mls_listing_address"
  runner "MapsServices::TransportScore.fix_score_glt_nine"
end

every 12.hours do
  runner "Venue.binding_listings"
end

every 1.day, at: '02:30 am' do
  runner "Listing.fix_status_for_20"
end

every 1.day, at: '7:47 am' do
  runner "Spider.setup_nyc_no_fee"
end

every 1.day, at: '2:00 pm' do
  runner "BuildingListing.update_same_formatted_address"
end
every 1.day, at: '11:25 am' do
  runner "Spider.sync_expired_for_old_listings"
end

# Update expired listings for Citi Habitats broker id 4820
#every 5.day, at: '10:25 am' do
#  runner "Spider.sync_expired_for_old_listings({broker_id: 4820})"
#end

every 15.minute do
  runner "Listing.clear_building_venue_for_short_address"
end

#every :day, at: '3:55 am' do
#  runner "ListingImage.fix_images_size"
#end

#every :day, at: '1:11 am' do
#  runner "Listing.destroy_expired_before_of(1.month)"
#end

every :day, at: '0:00 am' do
  rake 'log:clear'
  command 'sudo rm /var/mail/ec2-user'
end

every :day, at: '0: 10 am' do
  runner 'Listing.expired_after_7day_custom_listings'
end
