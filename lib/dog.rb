require 'pry'

class Dog
    attr_accessor :name, :breed
    attr_reader :id

    def initialize(id: nil, name:, breed:)
        # has a name and a breed
        # has an id that defaults to `nil` on initialization
        # accepts key value pairs as arguments to initialize
        @id = id
        @name = name
        @breed = breed
    end


    def self.create_table
        # creates the dogs table in the database
        sql = <<-SQL
            CREATE TABLE dogs (
                id INTEGER PRIMARY KEY,
                name TEXT,
                breed TEXT
            )
        SQL
        DB[:conn].execute(sql)
    end


    def self.drop_table
        # drops the dogs table from the database
        sql = "DROP TABLE IF EXISTS dogs"
        DB[:conn].execute(sql)
    end


    def save
        # returns an instance of the dog class
        # saves an instance of the dog class to the database and then sets the given dogs `id` attribute
        if self.id
            self
        else
            sql = <<-SQL
                INSERT INTO dogs (name, breed)
                VALUES (?, ?)
            SQL
            DB[:conn].execute(sql, self.name, self.breed)
            @id = DB[:conn].execute("SELECT last_insert_rowid() FROM dogs")[0][0]
            self
        end 
    end


    def self.create(hash)
        # takes in a hash of attributes and uses metaprogramming to create a new dog object. Then it uses the #save method to save that dog to the database
        # returns a new dog object
        dog = Dog.new(hash)
        dog.save
        dog
    end


    def self.new_from_db(row)
        # creates an instance with corresponding attribute values
        id = row[0]
        name = row[1]
        breed = row[2]
        Dog.new(id: id, name: name, breed: breed)
    end


    def self.find_by_id(id)
        # returns a new dog object by id
        sql = <<-SQL
            SELECT *
            FROM dogs
            WHERE id = ?
            LIMIT 1
        SQL
        DB[:conn].execute(sql, id).map do |row|
            # binding.pry
            self.new_from_db(row)
        end.first
    end


    def self.find_or_create_by(name:, breed:)
        dog = DB[:conn].execute("SELECT * FROM dogs WHERE name = ? AND breed = ?", name, breed)
        if !dog.empty?
            dog_data = dog[0]
            dog = Dog.new(dog_data[0], dog_data[1], dog_data[2])
            # binding.pry
        else
            dog = self.create(name: name, breed: breed)
        end
        dog
    end

end
