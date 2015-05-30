# coding: utf-8
require "npbs/version"

require "open-uri"
require "date"

require "nokogiri"

module Npbs
  # Your code goes here...
  class NPB
    attr_reader :base_url, :path
    def initialize
      @base_url = "http://bis.npb.or.jp";
      @path = "";
      # http://bis.npb.or.jpだけを対象にするので、文字コードは決め打ち
      @charset = "Shift-jis"
    end

    def fetch_doc(ext_path=nil)
      Nokogiri::HTML(fetch_html(ext_path), nil, @charset)
    end

    def fetch_html(ext_path=nil)
      path = ext_path.nil? ? @path : ext_path
      URI.parse(@base_url + path).read
    end

  end

  class Player < NPB
    attr_reader :name, :path, :first_name, :last_name, :first_name_kana, :last_name_kana,
                :number, :birthday, :height, :weight, :high_school, :college, :company
    def initialize(name, path)
      super()
      @name = name
      @path = path
    end
    def fetch
      doc = fetch_doc
      name = @name.split(' ')
      @first_name = name[0]
      @last_name = name[1]
      @number = doc.css('#registerdivtitle .registerNo').inner_text
      doc.css('#registerdivCareer').each do |prof|
        name_kana = prof.css("tr:first-child td").inner_text.split('・')
        @first_name_kana = name_kana[0]
        @last_name_kana = name_kana[1]
        data = prof.css('tr:nth-child(2) td').inner_text.split('　')
        data.delete('')
        @birthday = Date.strptime(data[0],'%Y年%m月%d日生')
        @height = data[1].match(/[0-9]{3,}/).to_s
        @weight = data[2].match(/[0-9]{2,3}/).to_s
        history = prof.css('tr:nth-child(3) td').inner_text.split(' - ')
        history.delete('')
        @high_school =  history[0]
        if history.length == 2 && /大$/ === history[1] then
          @college = history[1]
        elsif history.legth == 2 then
          @company = history[1]
        end
      end
    end
  end

  class TeamsPlayers < NPB
    attr_reader :teams
    def initialize
      super
      @path = "/players/"
      @teams = []
    end
    def fetch
      fetch_doc.css(".playerTeamsub").each do |node|
        node.css("tr:not(:first-child)").each do |team|
          name =  team.css('a').inner_text
          path =  team.css('a').first.attributes.first[1].value
          @teams << TeamPlayers.new(name, path)
        end
      end
      @teams
    end
  end

  class TeamPlayers < NPB
    attr_reader :name, :path, :players
    def initialize(name, path)
      super()
      @name = name
      @path = path
      @players = []
    end
    def fetch
      fetch_doc.css('.rosterPlayer').each do |node|
        node.css('a').each do |p|
          name = p.inner_text.gsub(/　/,' ')
          next if name =~ /※/
          path = p.attributes.first[1].value
          @players << Player.new(name,path)
        end
      end
      @players
    end
  end

  class Matches < NPB
    def initialize
      super
      @path = "/#{Date.today.year}/games/"
    end
    def today
      result = []
      fetch_doc.css(".contentsgame").each do |node|
        node.css("tr:nth-child(odd)").each do |game|

          h_team = game.css("td:nth-child(2)").inner_text.gsub(/(\s|　)+/, '')
          h_score = game.css("td:nth-child(3)").inner_text.gsub(/(\s|　)+/, '')

          v_score = game.css("td:nth-child(5)").inner_text.gsub(/(\s|　)+/, '')
          v_team = game.css("td:nth-child(6)").inner_text.gsub(/(\s|　)+/,'')

          result << Match.new(TeamResult.new(h_team, h_score),
                              TeamResult.new(v_team, v_score))
        end
      end
      result
    end
  end

  class Match
    attr_reader :home_team, :visitor_team
    def initialize(home, visitor)
      @home = home
      @visitor = visitor
    end
    def winner
      winner = [@home, @visitor].max_by{ |team| team.score}
      winner.name
    end
    def losseer
      losser = [@home, @visitor].min_by{ |team| team.score}
      losser.name
    end
  end

  class TeamResult
    attr_reader :name, :score
    def initialize(name, score)
      @name = name
      @score = score
    end
  end
end
