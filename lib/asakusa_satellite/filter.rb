require 'pathname'
require 'cgi'
require 'rexml/document'

module AsakusaSatellite
  module Filter
    class Base
      attr_reader :config
      protected :config

      def initialize(config)
        @config = config
      end

      def process(text, opts={})
        text
      end

      def self.inherited(klass)
        filter_config = AsakusaSatellite::Filter[klass.name.underscore.split('/')[-1]]
        AsakusaSatellite::Filter.add_filter(klass, OpenStruct.new(filter_config)) if filter_config
      end
    end

    def initialize!(config)
      @plugins = []
      @config = config
    end

    def children(doc, &f)
      doc.root.elements['/as'].to_a
    end
    private :children

    def process(message, room)
      @process ||= @config.map{|c|
        @plugins.find{|p|
          p.class.name.underscore.split('/')[-1] == c['name']
        }
      }

      text = CGI.escapeHTML(message.body).gsub("\n", "<br />")

      @process.reduce(text) do|text, process|
        if process.respond_to? :process_all
          process.process_all(message.body.split("\n"), :message => message, :room => room)
        else
          doc = REXML::Document.new "<as>#{text}</as>"

          if process.respond_to? :process
            doc.each_element('/as/text()').each do|node|
              s = process.process(node.to_s, :message => message, :room => room)

              children(REXML::Document.new("<as>#{s}</as>")).each do|x|
                node.parent.insert_before node, x
              end
              node.remove
            end

            children(doc).join
          end
        end
      end
    end

    def add_filter(klass, config)
      @plugins << klass.new(config)
    end

    def [](name)
      @config.each do |c|
        return c if c['name'] == name
      end
      nil
    end

    module_function :initialize!, :process, :add_filter, :[], :children
  end
end
