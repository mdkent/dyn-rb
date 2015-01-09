#
# Author:: Sunny Gleason (<sunny@thesunnycloud.com>)
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Evan (<evan@pagerduty.com>)
# Author:: Matthew Kent <mkent@magoazul.com>)
# Copyright:: Copyright (c) 2013 Dyn, Inc.
# Copyright:: Copyright (c) 2010 Opscode, Inc.
# Copyright:: Copyright (c) 2013 PagerDuty, Inc.
# Copyright:: Copyright (c) 2015 Basecamp LLC
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

module Dyn
  module Traffic
    class Failover < Base
      def initialize(dyn, zone, options)
        @dyn           = dyn
        @zone          = zone
        @resource_path = "Failover/#{@zone}"

        # state
        @active = options[:active]
        @status = options[:status]

        @address       = options[:address]
        @failover_mode = options[:failover_mode] || 'ip'
        @failover_data = options[:failover_data]
        @auto_recover  = options[:auto_recover] || 'N'
        @notify_events = options[:notify_events]

        @syslog_server   = options[:syslog_server]
        @syslog_port     = options[:syslog_port] || 514
        @syslog_ident    = options[:syslog_ident] || 'dynect'
        @syslog_facility = options[:syslog_facility] || 'daemon'

        @monitor = options[:monitor] || {:protocol => "HTTP", :interval => 10}

        @contact_nickname = options[:contact_nickname] || 'owner'
        @fqdn             = options[:fqdn]
        @ttl              = options[:ttl] || 30
      end

      attr_reader :active, :status

      def address(value=nil)
        value ? (@address = value; self) : @address
      end

      def failover_mode(value=nil)
        value ? (@failover_mode = value; self) : @failover_mode
      end

      def failover_data(value=nil)
        value ? (@failover_data = value; self) : @failover_data
      end

      def auto_recover(value=nil)
        value ? (@auto_recover = value; self) : @auto_recover
      end

      def notify_events(value=nil)
        value ? (@notify_events = value; self) : @notify_events
      end

      def syslog_server(value=nil)
        value ? (@syslog_server = value; self) : @syslog_server
      end

      def syslog_port(value=nil)
        value ? (@syslog_port = value; self) : @syslog_port
      end

      def syslog_ident(value=nil)
        value ? (@syslog_ident = value; self) : @syslog_ident
      end

      def syslog_facility(value=nil)
        value ? (@syslog_facility = value; self) : @syslog_facility
      end

      def monitor(value=nil)
        # :protocol => 'HTTP', :interval => 1, :retries => 2, :timeout => 10, :port => 8000,
        # :path => '/healthcheck', :host => 'example.com', :header => 'X-User-Agent: DynECT Health\n', :expected => 'passed'
        if value
          @monitor = {}
          value.each do |k,v|
            @monitor[k] = v
          end
        end
        @monitor
      end

      def contact_nickname(value=nil)
        value ? (@contact_nickname = value; self) : @contact_nickname
      end

      def fqdn(value=nil)
        value ? (@fqdn = value; self) : @fqdn
      end

      def ttl(value=nil)
        value ? (@ttl = value; self) : @ttl
      end

      def resource_path
        "Failover/#{@zone}"
      end

      def get(fqdn=nil)
        if fqdn
          results = @dyn.get("#{@resource_path}/#{fqdn}")

          # Default monitor timeout is 0, but specifying timeout 0 on a put or post results in an exception
          results["monitor"].delete("timeout") if results["monitor"]["timeout"] == 0

          Dyn::Traffic::Failover.new(@dyn, results["zone"], {
                                       :active => results["active"],
                                       :status => results["status"],

                                       :address       => results["address"],
                                       :failover_mode => results["failover_mode"],
                                       :failover_data => results["failover_data"],
                                       :auto_recover  => results["auto_recover"],
                                       :notify_events => results["notify_events"],

                                       :syslog_server   => results["syslog_server"],
                                       :syslog_port     => results["syslog_port"],
                                       :syslog_ident    => results["syslog_ident"],
                                       :syslog_facility => results["syslog_facility"],

                                       :monitor => results["monitor"],

                                       :contact_nickname => results["contact_nickname"],
                                       :fqdn             => results["fqdn"],
                                       :ttl              => results["ttl"],
                                       })
        else
          @dyn.get(resource_path)
        end
      end

      def find(fqdn, query_hash)
        results = []
        get(fqdn).each do |rr|
          query_hash.each do |key, value|
            results << rr if rr[key.to_s] == value
          end
        end
        results
      end

      def save(replace=false)
        if replace == true || replace == :replace
          @dyn.put("#{@resource_path}/#{@fqdn}", self)
        else
          @dyn.post("#{@resource_path}/#{@fqdn}", self)
        end
        self
      end

      def delete
        @dyn.delete("#{@resource_path}/#{fqdn}")
      end

      def to_json
        # have to drop active/status, api fails with 'unnecessary field passed in'
        {
          "address"       => @address,
          "failover_mode" => @failover_mode,
          "failover_data" => @failover_data,
          "auto_recover"  => @auto_recover,
          "notify_events" => @notify_events,

          "syslog_server"   => @syslog_server,
          "syslog_port"     => @syslog_port,
          "syslog_ident"    => @syslog_ident,
          "syslog_facility" => @syslog_facility,

          "monitor" => @monitor,

          "contact_nickname" => @contact_nickname,
          "fqdn"             => @fqdn,
          "ttl"              => @ttl
        }.to_json
      end
    end
  end
end
