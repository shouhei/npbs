# coding: utf-8
require "npbs/version"

require "open-uri"
require "date"

require "nokogiri"

module Npbs
  # Your code goes here...
  class NPB
    attr_reader :base_url
    attr_reader :page_path
    def initialize
      @base_url = "http://bis.npb.or.jp";
      @page_path = "";
      # http://bis.npb.or.jpだけを対象にするので、文字コードは決め打ち
      @charset = "Shift-jis"
    end

    def get_html
      URI.parse(@base_url+@page_path).read
    end

  end

  class Game < NPB
    def initialize
      super
      @page_path = "/#{Date.today.year}/games/"
    end
    def today
      doc = Nokogiri::HTML.parse(get_html, nil, @charset)
      result = []
      doc.css(".contentsgame").each do |node|
        node.css("tr:nth-child(odd)").each do |game|

          h_team = game.css("td:nth-child(2)").inner_text.gsub(/(\s|　)+/, '')
          h_score = game.css("td:nth-child(3)").inner_text.gsub(/(\s|　)+/, '')

          v_score = game.css("td:nth-child(5)").inner_text.gsub(/(\s|　)+/, '')
          v_team = game.css("td:nth-child(6)").inner_text.gsub(/(\s|　)+/,'')

          result << Match.new(Team.new(h_team, h_score),
                              Team.new(v_team, v_score))
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

  class Team
    attr_reader :name, :score
    def initialize(name, score)
      @name = name
      @score = score
    end
  end
end
