namespace :douban do
  desc "Bot for posting to Douban"
  task :posting => :environment do
    begin
      require 'rubygems'
      require 'nokogiri'
      require 'open-uri'
      require 'phantomjs'
      require 'capybara/poltergeist'
      require 'watir'
      require 'deathbycaptcha'
      require 'webdrivers'
      Selenium::WebDriver::PhantomJS.path = Phantomjs.path

      client = DeathByCaptcha.new('vsubbaraya033', 'vinny123', :http)
      notifier = Slack::Notifier.new "https://hooks.slack.com/services/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", channel: "#douban"
      #browser = Watir::Browser.new :chrome
      browser = Watir::Browser.new(:phantomjs)
      DoubanPage = "http://www.douban.com"
      LoginPage = "https://www.douban.com/login"
      browser.goto(LoginPage)
      sleep(5)
      browser.element(id: "email").send_keys 'pr@cityspade.com'
      browser.element(id: "password").send_keys 'doubandouban'
      puts browser.element(id: "captcha_image").present?

      if !(browser.element(id: "captcha_image").present?)
        browser.button(class: "btn-submit").click
      end

      while browser.element(id: "captcha_image").present? do
        doc = Nokogiri::HTML(browser.html)
        doc = doc.css("#captcha_image")
        captchaLink = doc.attr('src')
        puts captchaLink
        captcha = client.decode(url: captchaLink)
        puts captcha.text
        #puts browser.element(id: "captcha_image")
        #captcha = client.decode(url: 'http://bit.ly/1xXZcKo')
        browser.element(id: "password").send_keys ''
        browser.element(id: "password").send_keys 'doubandouban'
        browser.element(id: "captcha_field").send_keys(captcha.text)
        browser.button(tabindex: "5").click
        #browser.refresh
        puts browser.element(id: "captcha_image").present?
      end
      puts "SUCCESS!"
      sleep(15)

      PublishList = "https://www.douban.com/group/people/cityspade/publish?start=0"
      browser.goto(PublishList)
      sleep(15)

      GroupListAll = []

      if (browser.element(class: "title").present?)
        browser.tds(class: 'title').each do |item|
          GroupListAll << item.a.href
        end
      end
      puts GroupListAll
      notifier.ping "Length of List - #{GroupListAll.length}"

      ##GroupList1 大纽约房屋出租/求租/合租
      #GroupList5 = ["https://www.douban.com/group/topic/109388079/", "https://www.douban.com/group/topic/109388051/"]

      ##GroupList2 纽约房屋信息站
      #GroupList4 = ["https://www.douban.com/group/topic/109388076/", "https://www.douban.com/group/topic/109388058/"]

      ##GroupList3 NYU纽约大学
      #GroupList1 = ["https://www.douban.com/group/topic/109388101/", "https://www.douban.com/group/topic/109388041/"]

      ##Group4 同是纽约客
      #GroupList3 = ["https://www.douban.com/group/topic/109388081/", "https://www.douban.com/group/topic/109388047/", "https://www.douban.com/group/topic/109387765/"]

      ##Group5 我在纽约租房住
      #GroupList2 = ["https://www.douban.com/group/topic/109388086/", "https://www.douban.com/group/topic/109388043/", "https://www.douban.com/group/topic/109387770/"]




      GroupListAll[0..25].each do |postAutomatic|
        browser.goto(postAutomatic)
        browser.textarea(id: "last").set "顶起来zzzf"
        puts browser.element(id: "captcha_image").present?
        sleep(5)

        if !(browser.element(id: "captcha_image").present?)
          browser.button(name: "submit_btn").click
        end

        while browser.element(id: "captcha_image").present? do
          doc = Nokogiri::HTML(browser.html)
          doc = doc.css("#captcha_image")
          captchaLink = doc.attr('src')
          puts captchaLink
          captcha = client.decode(url: captchaLink)
          puts captcha.text
          browser.element(id: "captcha_field").send_keys(captcha.text)
          browser.button(name: "submit_btn").click
        end
        #browser.button(name: "submit_btn").click
        puts "Successfully posted"
        sleep(180)
      end

      notifier.ping "Finished posting to Douban forums.."

      browser.close
    rescue => err
      notifier = Slack::Notifier.new "https://hooks.slack.com/services/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", channel: "#douban"
      notifier.ping err.inspect
    end
  end
end
