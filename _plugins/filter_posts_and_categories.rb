
module Jekyll
module PostAndCategoryFilter
RESTRICTED_CATEGORIES = ['blog', 'bike_build']
# Returns back all categories related to a primary category
# e.g. "blog" or "bike_build"
def filter_categories_by_primary_category(posts)
      filtered = []
for post in posts
for post_category in post.categories
          filtered.push(post_category) unless RESTRICTED_CATEGORIES.include? post_category
end
end
      filtered.sort.uniq
end
end
end
Liquid::Template.register_filter(Jekyll::PostAndCategoryFilter)
