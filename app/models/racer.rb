class Racer

  include ActiveModel::Model

  attr_accessor :id, :number, :first_name, :last_name, :gender, :group, :secs

  def persisted?
    !@id.nil?
  end

  def created_at
    nil
  end


  def updated_at
    nil
  end

  def update(params)
    @number = params[:number].to_i
    @first_name = params[:first_name]
    @last_name = params[:last_name]
    @gender = params[:gender]
    @group = params[:group]
    @secs = params[:secs].to_i
    result = self.class.collection.find(:_id => BSON.ObjectId(@id)).update_one(number:@number, first_name:@first_name, last_name:@last_name, gender:@gender, group:@group, secs:@secs)
  end


  def destroy
    record = self.class.collection.find(:number => @number).delete_one
  end



  def initialize(params={})
    @id = params[:_id].nil? ? params[:id] : params[:_id].to_s
    @number = params[:number].to_i
    @first_name = params[:first_name]
    @last_name = params[:last_name]
    @gender = params[:gender]
    @group = params[:group]
    @secs = params[:secs].to_i
  end

  def self.mongo_client
    Mongoid::Clients.default
  end


  def self.collection
    self.mongo_client[:racers]
  end


  def self.all(prototype={}, sort={}, skip=0, limit=nil)
    result = collection.find(prototype).sort(sort).skip(skip)
    result = limit.nil? ? result : result.limit(limit)
  end


  def self.find id
    result = self.collection.find(:_id=>BSON.ObjectId(id)).projection({_id:true, number:true, first_name:true, last_name:true, gender:true, group:true, secs:true }).first
    return result.nil? ? nil : Racer.new(result)
  end


  def save
     record ={number:@number, first_name:@first_name, last_name:@last_name, gender:@gender, group:@group, secs:@secs}
    record[:_id] = @id if @id
    r = self.class.collection.insert_one(_id:@id, number:@number, first_name:@first_name, last_name:@last_name, gender:@gender, group:@group, secs:@secs)

    @id = r.inserted_id if r.successful?
  end

  def self.paginate(params)
    page=(params[:page] || 1).to_i
    limit=(params[:per_page] || 30).to_i
    skip=(page-1)*limit
    sort={:number => 1}
    racers=[]
    params[:page] = nil
    params[:per_page] =nil
    all(params, sort, skip, limit).each do |doc|
      racers << Racer.new(doc)
    end
    total=all.count
    WillPaginate::Collection.create(page, limit, total) do |pager|
      pager.replace(racers)
    end
  end
end