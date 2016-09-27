class SearchController < ApplicationController
  def index
  end

  def bento
  end

  def search
    unless strip_q.present?
      flash[:error] = 'A search term is required.'
      return redirect_to search_url
    end

    @results = search_results
    return redirect_to search_url unless @results
    render layout: false
  end

  private

  # Requests results from requested target
  def search_results
    return unless valid_target?
    search_target
  end

  # Boolean check of whether param passed in is a valid search endpoint
  def valid_target?
    valid_targets.include?(params[:target])
  end

  # Array of search endpoints that are supported
  def valid_targets
    %w(articles books google)
  end

  # Formatted date used in creating cache keys
  def today
    Time.zone.today.strftime('%Y%m%d')
  end

  # NOTE: The cache keys used below use a combination of the api endpoint
  # name, the search parameter, and today's date to allow us to cache calls
  # for the current date without ever worrying about expiring caches.
  # Instead, we'll rely on the cache itself to expire the oldest cached
  # items when necessary.
  def search_target
    Rails.cache.fetch("#{params[:target]}_#{strip_q}_#{today}") do
      if params[:target] == 'google'
        search_google
      else
        search_eds
      end
    end
  end

  # Seaches EDS
  def search_eds
    SearchEds.new.search(strip_q, eds_profile)
  end

  # Determines appropriate EDS profile
  def eds_profile
    if params[:target] == 'articles'
      ENV['EDS_NO_ALEPH_PROFILE']
    else
      ENV['EDS_ALEPH_PROFILE']
    end
  end

  # Searches Google Custom Search
  def search_google
    SearchGoogle.new.search(strip_q)
  end

  # Strips trailing and leading white space in search term
  # Individual search engine models do additional cleaning as appropriate.
  def strip_q
    params[:q].strip
  end
end
