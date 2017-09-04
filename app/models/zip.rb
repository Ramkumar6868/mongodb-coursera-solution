class Zip

	include ActiveModel::Model

	attr_accessor :id, :city, :state, :population

	def to_s
    	"#{@id}: #{@city}, #{@state}, pop=#{@population}"
 	end

  	# initialize from both a Mongo and Web hash
  	def initialize(params={})
    #switch between both internal and external views of id and population
    	@id=params[:_id].nil? ? params[:id] : params[:_id]
    	@city=params[:city]
    	@state=params[:state]
    	@population=params[:pop].nil? ? params[:population] : params[:pop]
  	end

	def persisted?
		!@id.nil?
	end

	def created_at
		nil
	end

	def updated_at
		nil
	end

	def self.all(prototype = {}, sort = {:population => 1}, offset = 0, limit = 100)
		tmp = {}
		sort.each do |k, v|
			k = k.to_sym == :population ? :pop : k.to_sym
			tmp[k] = v if [:city, :state, :pop].include?(k)
		end
		sort = tmp
		tmp = {}
		prototype.each do |k, v|
			k = k.to_sym == :population ? :pop : k.to_sym
			tmp[k] = v if [:_id, :city, :loc, :pop, :state].include?(k)
		end
		collection.find(tmp).sort(sort).skip(offset).limit(limit)
	end

	def self.find id
		doc = collection.find(:_id => id).projection({_id:true, city:true, state:true, pop:true}).first
		return doc.nil? ? nil : Zip.new(doc)
	end

	def save
		self.class.collection.insert_one(_id:@id, city:@city, state:@state, pop:@population)
	end

	def update(updates)
		updates[:pop] = updates[:population] if !updates[:population].nil?
		updates.slice!(:city, :state, :pop) if !updates.nil?
		self.class.collection.find(_id:@id).update_one(updates)
	end
	
	def destroy
		self.class.collection.find(_id:@id).delete_one
	end

	def self.paginate(params)
	    page=(params[:page] ||= 1).to_i
	    limit=(params[:per_page] ||= 30).to_i
	    offset=(page-1)*limit
	    sort=params[:sort] ||= {}

	    #get the associated page of Zips -- eagerly convert doc to Zip
	    zips=[]
	    all(params, sort, offset, limit).each do |doc|
	      zips << Zip.new(doc)
	    end

	    #get a count of all documents in the collection
	    total=all(params, sort, 0, 1).count
	    
	    WillPaginate::Collection.create(page, limit, total) do |pager|
	      pager.replace(zips)
	    end    
	end

	def self.mongo_client
		Mongoid::Clients.default
	end

	def self.collection
		self.mongo_client[:zips]
	end

end