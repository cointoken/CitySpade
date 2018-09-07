namespace :cssa do
  desc "Bot for posting to nyu cssa"
  task :posting => :environment do
    require 'rubygems'
    require 'nokogiri'
    require 'open-uri'
    require 'phantomjs'
    require 'capybara/poltergeist'
    require 'watir'
    #require 'watir-webdriver'
    require 'watir/extensions/element/screenshot'
    require 'deathbycaptcha'
    require 'webdrivers'
    Selenium::WebDriver::PhantomJS.path = Phantomjs.path

    def do_posting(usrname, thrd, paswd)
      client = DeathByCaptcha.new('vsubbaraya033', 'vinny123', :http)
      login_ct = 0
      post_ct = 0
      browser = Watir::Browser.new(:chrome)
      puts "Ready to work"
      cssanyu_homepage = "http://www.cssanyu.org/bbs2/forum.php?mod=forumdisplay&fid=41"
      browser.goto(cssanyu_homepage)
      browser.screenshot.save("#{Rails.root}/public/logincssa.png")
      sleep(7)

      browser.element(id: "ls_username").send_keys usrname
      browser.element(id: "ls_password").send_keys paswd
      browser.element(css: ".pn.vm").click
      #to allow sometime for this captcha to read
      sleep(7)

      doc = Nokogiri::HTML(browser.html)
      elemnts = doc.css('.rfm table .vm')
      elem_id = elemnts.last.parent.attr("id")
      #puts browser.element(id: "#vseccode_cSAP2ZHR6").present?
      # puts doc.css("#vseccode_cSAP2ZHR6").present?
      if browser.element(id: elem_id).present?
        begin
          puts "doing it"
          login_ct = login_ct + 1
          browser.text_field(name: "seccodeverify").parent.element(class: 'xi2').click
          sleep(5)
          browser.element(id: elem_id).image.screenshot("#{Rails.root}/public/readme.png")
          sleep(5)
          captcha = client.decode!(path: "#{Rails.root}/public/readme.png")
          browser.text_field(name: "seccodeverify").set captcha.text
          browser.screenshot.save("#{Rails.root}/public/abc.png")
          temp = elem_id.match(/\_(.*)/)
          span_id = "checkseccodeverify_"+temp[1]
          browser.element(id: span_id).click
          sleep(5)
          doc = Nokogiri::HTML(browser.html)
          verify =  'span#'+span_id+" img"
          val = doc.css(verify).attr('src').value
          val = val.split("/").last
          puts val
          puts val.include?("check_right")
        end until (val.include?("check_right") || login_ct == 5)
        browser.button(name: 'loginsubmit').click
        sleep(7)
        browser.screenshot.save("#{Rails.root}/public/done.png")
        puts "Done!!!"
      end
      browser.goto(thrd)
      browser.element(id: "fastpostmessage").send_keys 'dddddddddddddd'
      begin
        puts "doing it again"
        post_ct = post_ct + 1
        browser.text_field(name: "seccodeverify").parent.element(class: 'xi2').click
        browser.text_field(name: "seccodeverify").click
        sleep(5)
        sec_id = browser.text_field(name: "seccodeverify").id
        sec_id = sec_id.sub('seccodeverify', 'vseccode')
        browser.element(id: sec_id).image.screenshot("#{Rails.root}/public/readme.png")
        sleep(5)
        captcha = client.decode!(path: "#{Rails.root}/public/readme.png")
        puts captcha.text
        browser.text_field(name: "seccodeverify").set captcha.text
        browser.element(id: "fastpostmessage").click
        span_id = sec_id.sub('vseccode', 'checkseccodeverify')
        #browser.element(id: span_id).click
        sleep(5)
        doc = Nokogiri::HTML(browser.html)
        verify =  'span#'+span_id+" img"
        val = doc.css(verify).attr('src').value
        val = val.split("/").last
        puts val
        puts val.include?("check_right")
        browser.screenshot.save("#{Rails.root}/public/abc.png")
      end until (val.include?("check_right") || post_ct == 5)
      browser.button(name: 'replysubmit').click
      sleep(3)
      browser.screenshot.save("#{Rails.root}/public/done.png")
      browser.element(:xpath => '//*[@id="um"]/p[1]/a[5]').click
      sleep(3)
      puts "Done Done!!!"
    end

    begin
      usr_login = {"taylor@cityspade.com" => "Fable1992", "sherry@cityspade.com" => "sherry2333", "kelvy@cityspade.com" => "Fable1992", "Jiarui@cityspade.com" => "JiaruiHAN123", "alina@cityspade.com" => "Alina6666"}
      thread_arr =  ['http://www.cssanyu.org/bbs2/forum.php?mod=viewthread&tid=228010&extra=page%3D1', 'http://www.cssanyu.org/bbs2/forum.php?mod=viewthread&tid=165116']

      #(0..1).each do |i|
      do_posting(usr_arr[0], thread_arr[0], pass_arr[0])
      #end
      WelcomeMailer.test_mail("Finished!!!").deliver
      #do_posting("abc", "xyz")
    rescue => err
      WelcomeMailer.test_mail(err.inspect).deliver
    end



  end
end
