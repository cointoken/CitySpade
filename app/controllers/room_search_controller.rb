class RoomSearchController < ApplicationController
  def index
    collection = Room.active
    Roommate.active.each{|r| collection << r}
    all_posts = collection.sort_by(&:created_at).reverse
    posts = Kaminari.paginate_array(all_posts).page(params[:page]).per(24)

    link_hash = {
      "Roommates" => roommates_path,
      "Room Offers" => rooms_path
    }

    render "room_search/_index_layout",
      locals:{
        total_post_count: all_posts.count,
        posts: posts,
        heading: "ALL POSTS",
        new_path: new_room_path,
        link_hash: link_hash
      }
  end
end
