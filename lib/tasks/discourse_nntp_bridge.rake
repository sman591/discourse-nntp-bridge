namespace :discourse_nntp_bridge do
  desc "Utility to assign NNTP newsgroups to categories"
  task assign_newsgroups: :environment do
    assigned_categories = CategoryCustomField.where(name: "nntp_bridge_newsgroup").pluck(:category_id)
    categories_to_assign = Category.pluck(:id) - assigned_categories
    newsgroups = DiscourseNntpBridge::Server.new.newsgroups.map(&:name)

    puts "#{categories_to_assign.count} categories without newsgroup associations!"
    puts "#{newsgroups.count} NNTP newsgroups exist"

    categories_to_assign.each do |category_id|
      category = Category.find(category_id)
      begin
        print "Assign #{category.full_slug} a newsgroup? (y/n): "
        input = STDIN.gets.strip.downcase
      end until %w(y n).include?(input)

      next if input == "n"

      begin
        print "Newsgroup: "
        input = STDIN.gets.strip.downcase
        duplicates = CategoryCustomField.where(name: "nntp_bridge_newsgroup", value: input)
        if duplicates.count > 0
          duplicate_names = "'" + duplicates.map(&:category).map(&:full_slug).join("' and '") + "'"
          puts "#{input} is already assigned to #{duplicate_names}"
          redo
        end
      end until newsgroups.include?(input)

      CategoryCustomField.create!(
        category_id: category_id,
        name: "nntp_bridge_newsgroup",
        value: input
      )
    end
  end
end
