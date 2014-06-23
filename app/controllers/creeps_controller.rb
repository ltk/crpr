require 'piplapis/search'

class CreepsController < ApplicationController
  def new
  end

  def create
    email = params.fetch(:email)
    person_request = PiplApi::SearchAPIRequest.new({ :email => email })

    begin
      response = person_request.send
      person = response.person
      records = response.records

      if person
        @name = person.names.first.show

        @websites = person.related_urls.map(&:content)

        @image_urls = person.images.map(&:url)

        bad_image_urls = []

        # Image Checks

        hydra = Typhoeus::Hydra.hydra

        @image_urls.each_with_index do |image_url, index|
          image_check = Typhoeus::Request.new(image_url)
          image_check.on_complete do |response|
            unless response.response_code == 200 || response.response_code == 302
              @image_urls.delete image_url
            end
          end
          hydra.queue image_check
        end

        hydra.run
      elsif records.any?
        names = []
        records.each do |record|
          if record.names.any?
            record.names.each do |name|
              names << name.show
            end
          end
        end

        @name = names.group_by {|n| n}.values.max_by(&:size).first
        @websites = []
        @image_urls = []
      else
        @error = "Darn, we couldn't find anybody with that email address."
      end
    rescue PiplApi::SearchAPIError => e
      @error = "Whoopsy, we can't get data right now."
    end
  end
end
