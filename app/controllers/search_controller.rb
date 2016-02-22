class SearchController < ApplicationController
  def search_results
    username = params[:username] || ""
    title = params[:title] || ""
    body = params[:body] || ""
    why = params[:why] || ""
    user_reputation = params[:user_reputation].to_i || 0

    case params[:feedback]
      when /true/
        feedback = "t"
      when /false/
        feedback = "f"
    end

    @results = Post.where("IFNULL(username, '') LIKE :username AND IFNULL(title, '') LIKE :title AND IFNULL(body, '') LIKE :body AND IFNULL(why, '') LIKE :why", username: "%" + username + "%", title: "%" + title + "%", body: "%" + body + "%", why: "%" + why + "%")
                   .paginate(:page => params[:page], :per_page => 100)
                   .order("created_at DESC")
                   .includes(:reasons)
                   .includes(:feedbacks)

    if feedback.present?
      @results = @results.joins(:feedbacks).where("feedbacks.feedback_type LIKE :feedback", feedback: "%" + feedback + "%")
    end

    @results = case params[:user_rep_direction]
      when ">="
        @results.where("ifnull(user_reputation, 0) >= :rep", rep: user_reputation)
      when "=="
        @results.where("ifnull(user_reputation, 0) = :rep", rep: user_reputation)
      when "<="
        @results.where("ifnull(user_reputation, 0) <= :rep", rep: user_reputation)
      else
        @results
    end

    if params[:site].present?
      site_id = Site.find_by_site_name(params[:site])
      @results = @results.where(:site_id => site_id)
    end

    @sites = Site.where(:id => @results.map(&:site_id))

    render :search
  end
end